#!/bin/bash
# Learning System - Infer Next Topic Helper
# Analyzes state to determine what to work on next
#
# set -e omitted: jq calls use `|| true` for graceful degradation
# when state files are missing or empty.

set -uo pipefail

# Source state loader
source "$(dirname "$0")/load-state.sh"

# Get command type from argument
COMMAND_TYPE="${1:-daily-recall}"

TODAY=$(portable_date_iso)

# Function to get overdue topics from spaced repetition
get_overdue_topics() {
    if [[ -f "$SPACED_REP_FILE" ]]; then
        jq -r --arg today "$TODAY" '
            .topics
            | to_entries
            | map(select(.value.next_review <= $today))
            | sort_by(.value.priority, .value.next_review)
            | .[].key
        ' "$SPACED_REP_FILE" 2>/dev/null || true
    fi
}

# Function to get next roadmap topic
get_next_roadmap_topic() {
    if [[ -f "$ROADMAP_FILE" ]]; then
        jq -r '
            .topics
            | to_entries
            | map(select(.value.status == "ready"))
            | sort_by(.value.sequence)
            | .[0].key // empty
        ' "$ROADMAP_FILE" 2>/dev/null || true
    fi
}

# Function to get topics ready for synthesis
get_synthesis_ready_topics() {
    if [[ -f "$SPACED_REP_FILE" ]]; then
        jq -r '
            .topics
            | to_entries
            | map(select(.value.recall_score >= 8 and .value.review_count >= 3 and .value.synthesized != true))
            | sort_by(-.value.recall_score)
            | .[].key
        ' "$SPACED_REP_FILE" 2>/dev/null || true
    fi
}

# Function to get next roadmap topic, preferring ones in the same phase as recent learning
get_related_roadmap_topic() {
    if [[ ! -f "$ROADMAP_FILE" ]]; then
        return
    fi

    # Determine the phase of the most recently learned topic
    local recent_phase=""
    if [[ -f "$SPACED_REP_FILE" ]]; then
        local last_topic
        last_topic=$(jq -r '
            .topics | to_entries
            | sort_by(.value.last_reviewed) | reverse
            | .[0].key // empty
        ' "$SPACED_REP_FILE" 2>/dev/null)
        if [[ -n "$last_topic" ]]; then
            # Extract phase number from topic ID (e.g., "topic-2-1" → "2")
            recent_phase=$(echo "$last_topic" | sed -n 's/^topic-\([0-9]*\)-.*/\1/p')
        fi
    fi

    # Try same-phase first, then fall back to next sequential ready topic
    if [[ -n "$recent_phase" ]]; then
        local same_phase
        same_phase=$(jq -r --arg phase "$recent_phase" '
            .topics | to_entries
            | map(select(.value.status == "ready" and (.key | startswith("topic-" + $phase + "-"))))
            | sort_by(.value.sequence)
            | .[0].key // empty
        ' "$ROADMAP_FILE" 2>/dev/null)
        if [[ -n "$same_phase" ]]; then
            echo "$same_phase"
            return
        fi
    fi

    # Fallback: next ready topic by sequence
    jq -r '
        .topics | to_entries
        | map(select(.value.status == "ready"))
        | sort_by(.value.sequence)
        | .[0].key // empty
    ' "$ROADMAP_FILE" 2>/dev/null || true
}

# Function to get recently learned topics for application
get_recent_topics() {
    if [[ -f "$SPACED_REP_FILE" ]]; then
        local days_ago=$(portable_date_ago 14)
        jq -r --arg date "$days_ago" '
            .topics
            | to_entries
            | map(select(.value.last_reviewed >= $date and .value.recall_score >= 7))
            | sort_by(.value.last_reviewed) | reverse
            | .[].key
        ' "$SPACED_REP_FILE" 2>/dev/null || true
    fi
}

# Prefer roadmap topics with an explicit performance activity. Topics that have
# never been practiced come first, followed by weak attempts, then the oldest
# successful attempt. This keeps performance practice repeatable without adding
# a second progress database.
get_next_performance_topic() {
    if [[ ! -f "$ROADMAP_FILE" ]]; then
        return
    fi

    local performance_logs="[]"
    if [[ -f "$LEARNING_LOG" && -s "$LEARNING_LOG" ]]; then
        performance_logs=$(jq -s 'map(select(.type == "performance-practice"))' "$LEARNING_LOG" 2>/dev/null || echo "[]")
    fi

    jq -r --argjson logs "$performance_logs" '
        .topics
        | to_entries
        | map(
            . as $topic
            | select(.value.status != "blocked")
            | select(any(.value.practice_activities[]?; .type == "performance"))
            | . + {
                performance_count: (
                    $logs | map(select(.topic == $topic.key)) | length
                ),
                last_performance: (
                    ($logs
                     | map(select(.topic == $topic.key))
                     | map(.timestamp)
                     | max) // ""
                ),
                last_score: (
                    ($logs
                     | map(select(.topic == $topic.key))
                     | sort_by(.timestamp)
                     | last
                     | .final_score // .overall_score) // 0
                )
            }
        )
        | sort_by(
            (if .performance_count == 0 then 0
             elif .last_score < 7 then 1
             else 2 end),
            .last_performance,
            .value.sequence
        )
        | .[0].key // empty
    ' "$ROADMAP_FILE" 2>/dev/null || true
}

# Prefer the topic whose banked questions are being missed most. A repeatedly
# missed question is a confirmed discrimination gap, which is exactly what a
# quiz remediates — stronger evidence than a low recall score alone.
get_most_missed_quiz_topic() {
    if [[ -f "$QUIZ_BANK_FILE" ]]; then
        jq -r '
            .questions
            | to_entries
            | map(select((.value.stats.times_missed // 0) >= 2))
            | group_by(.value.source_topic)
            | map({
                topic: .[0].value.source_topic,
                missed: (map(.value.stats.times_missed) | add)
              })
            | sort_by(.missed) | reverse
            | .[0].topic // empty
        ' "$QUIZ_BANK_FILE" 2>/dev/null || true
    fi
}

# Most recently studied topic — quizzing right after learning consolidates it.
get_last_studied_topic() {
    if [[ -f "$SPACED_REP_FILE" ]]; then
        jq -r '
            .topics | to_entries
            | sort_by(.value.last_reviewed) | reverse
            | .[0].key // empty
        ' "$SPACED_REP_FILE" 2>/dev/null || true
    fi
}

# Main logic based on command type
case "$COMMAND_TYPE" in
    daily-recall)
        # Priority 1: Overdue topics
        overdue=$(get_overdue_topics | head -1)
        if [[ -n "$overdue" ]]; then
            echo "$overdue"
            exit 0
        fi

        # Priority 2: Recent topics (review within a week)
        recent=$(get_recent_topics | head -1)
        if [[ -n "$recent" ]]; then
            echo "$recent"
            exit 0
        fi

        # Priority 3: Suggest roadmap topic (prefer same phase as recent learning)
        roadmap_topic=$(get_related_roadmap_topic)
        if [[ -n "$roadmap_topic" ]]; then
            echo "$roadmap_topic"
            exit 0
        fi

        # No topics found
        echo "none"
        ;;

    weekly-dive)
        # Priority 1: Next roadmap topic
        next_topic=$(get_next_roadmap_topic)
        if [[ -n "$next_topic" ]]; then
            echo "$next_topic"
            exit 0
        fi

        # Priority 2: Topics with weak scores
        weak=$(jq -r '
            .topics
            | to_entries
            | map(select(.value.recall_score < 6 and .value.review_count >= 2))
            | sort_by(.value.recall_score)
            | .[0].key // empty
        ' "$SPACED_REP_FILE" 2>/dev/null || true)

        if [[ -n "$weak" ]]; then
            echo "$weak"
            exit 0
        fi

        echo "none"
        ;;

    monthly-synthesis)
        # Topics ready for mastery verification
        ready=$(get_synthesis_ready_topics | head -1)
        if [[ -n "$ready" ]]; then
            echo "$ready"
            exit 0
        fi

        echo "none"
        ;;

    apply-to-work)
        # Recent high-scoring topics
        applicable=$(get_recent_topics | head -3)
        if [[ -n "$applicable" ]]; then
            echo "$applicable"
            exit 0
        fi

        echo "none"
        ;;

    performance-practice)
        # Priority 1: Roadmap topics with an explicit performance activity.
        performance_topic=$(get_next_performance_topic)
        if [[ -n "$performance_topic" ]]; then
            echo "$performance_topic"
            exit 0
        fi

        # Priority 2: Recently learned topics with solid recall are good
        # candidates for transfer into constrained performance.
        recent=$(get_recent_topics | head -1)
        if [[ -n "$recent" ]]; then
            echo "$recent"
            exit 0
        fi

        # Priority 3: Legacy roadmaps may not have practice metadata yet.
        roadmap_topic=$(get_next_roadmap_topic)
        if [[ -n "$roadmap_topic" ]]; then
            echo "$roadmap_topic"
            exit 0
        fi

        echo "none"
        ;;

    quiz)
        # Priority 1: banked questions with a repeat-miss history. These are
        # confirmed confusions, not guesses.
        missed_topic=$(get_most_missed_quiz_topic)
        if [[ -n "$missed_topic" ]]; then
            echo "$missed_topic"
            exit 0
        fi

        # Priority 2: whatever was studied most recently — quiz it while it is
        # still fresh enough to consolidate rather than relearn.
        last_studied=$(get_last_studied_topic)
        if [[ -n "$last_studied" ]]; then
            echo "$last_studied"
            exit 0
        fi

        # Priority 3: nothing studied yet, so fall back to the roadmap.
        roadmap_topic=$(get_next_roadmap_topic)
        if [[ -n "$roadmap_topic" ]]; then
            echo "$roadmap_topic"
            exit 0
        fi

        echo "none"
        ;;

    *)
        echo "Unknown command type: $COMMAND_TYPE" >&2
        exit 1
        ;;
esac
