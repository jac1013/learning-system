#!/bin/bash
# Learning System - Determine Topic Helper
# Topic resolution for daily-recall, weekly-dive, monthly-synthesis,
# performance-practice, and quiz.
# Usage: bash ./.claude/scripts/learning/determine-topic.sh <skill-type> [optional-topic]
#
# set -e omitted: jq calls use fallbacks for missing state files.

set -uo pipefail

source "$(dirname "$0")/load-state.sh"
show_session_status

SKILL_TYPE="${1:-daily-recall}"
USER_TOPIC="${2:-}"

show_performance_activity() {
    local topic="$1"
    [[ -f "$ROADMAP_FILE" ]] || return 0

    local activity
    activity=$(jq -c --arg topic "$topic" '
        .topics[$topic].practice_activities // []
        | map(select(.type == "performance"))
        | .[0] // empty
    ' "$ROADMAP_FILE" 2>/dev/null || true)

    [[ -n "$activity" ]] || return 0

    echo ""
    echo "**Roadmap performance activity**:"
    echo "$activity" | jq -r '
        "- Scenario: " + (.scenario // "Define with the learner"),
        "- Mode: " + (.mode // "Choose with the learner"),
        "- Timebox: " + ((.timebox_minutes // 30) | tostring) + " minutes",
        "- Success criteria: " + ((.success_criteria // []) | join("; "))
    ' 2>/dev/null || true
    echo "PERFORMANCE_ACTIVITY_JSON=$activity"
}

show_quiz_coverage() {
    local topic="$1"
    [[ -f "$QUIZ_BANK_FILE" ]] || return 0

    jq -r --arg topic "$topic" '
        [.questions | to_entries[] | select(.value.source_topic == $topic)] as $q
        | "QUIZ_BANK_FOR_TOPIC=\($q | length)",
          "QUIZ_BANK_WEAK=\([$q[] | select((.value.stats.times_missed // 0) >= 2)] | length)"
    ' "$QUIZ_BANK_FILE" 2>/dev/null || true
}

if [[ -n "$USER_TOPIC" ]]; then
    case "$SKILL_TYPE" in
        daily-recall)    echo "Topic specified: $USER_TOPIC" ;;
        weekly-dive)     echo "Topic specified: $USER_TOPIC" ;;
        monthly-synthesis) echo "Topic specified: $USER_TOPIC" ;;
        performance-practice) echo "Topic specified: $USER_TOPIC" ;;
        quiz)            echo "Topic specified: $USER_TOPIC" ;;
    esac
    if [[ "$SKILL_TYPE" == "performance-practice" ]]; then
        show_performance_activity "$USER_TOPIC"
    fi
    if [[ "$SKILL_TYPE" == "quiz" ]]; then
        show_quiz_coverage "$USER_TOPIC"
    fi
    echo "TOPIC=$USER_TOPIC"
    exit 0
fi

# Auto-determine topic
TOPIC=$(bash "$(dirname "$0")/infer-next.sh" "$SKILL_TYPE" || echo "none")

case "$SKILL_TYPE" in
    daily-recall)
        if [[ "$TOPIC" == "none" ]]; then
            echo "All caught up! No topics due for review."
            echo ""
            echo "Options:"
            echo "1. Start a new topic: /learning-weekly-dive"
            echo "2. Review specific topic: /learning-daily-recall \"topic name\""
            echo "3. Take a break!"
            echo "TOPIC=none"
            exit 0
        fi

        echo "**Suggested Topic**: $TOPIC"
        echo ""

        # Get topic details from spaced repetition
        LAST_SCORE=$(jq -r --arg topic "$TOPIC" '.topics[$topic].recall_score // "unknown"' "$SPACED_REP_FILE" 2>/dev/null || echo "unknown")
        LAST_REVIEWED=$(jq -r --arg topic "$TOPIC" '.topics[$topic].last_reviewed // "never"' "$SPACED_REP_FILE" 2>/dev/null || echo "never")
        NEXT_REVIEW=$(jq -r --arg topic "$TOPIC" '.topics[$topic].next_review // "unknown"' "$SPACED_REP_FILE" 2>/dev/null || echo "unknown")

        echo "**Why this topic?**"
        echo "- Last reviewed: $LAST_REVIEWED"
        echo "- Next review was: $NEXT_REVIEW"
        echo "- Last score: $LAST_SCORE/10"
        echo ""
        echo "Ready to start? (yes/no, or specify different topic)"
        echo "TOPIC=$TOPIC"
        ;;

    weekly-dive)
        if [[ "$TOPIC" == "none" ]]; then
            echo "No topics ready in roadmap."
            echo ""
            echo "Options:"
            echo "1. Specify a topic: /learning-weekly-dive \"topic name\""
            echo "2. Update roadmap: Edit ./roadmap.json"
            echo "3. Review a weak topic from past sessions"
            echo "TOPIC=none"
            exit 0
        fi

        echo "**Suggested Topic**: $TOPIC"
        echo ""
        echo "**Why this topic?**"
        echo "Next in your roadmap sequence (prerequisites met)"
        echo ""
        echo "Ready for a deep dive? (yes/no, or specify different topic)"
        echo "TOPIC=$TOPIC"
        ;;

    monthly-synthesis)
        if [[ "$TOPIC" == "none" ]]; then
            echo "No topics ready for synthesis yet."
            echo ""
            echo "Topics become ready for synthesis when:"
            echo "- Reviewed 3+ times"
            echo "- Score 8+ consistently"
            echo "- Not yet synthesized"
            echo ""
            echo "Keep doing weekly dives and daily recalls!"
            echo "TOPIC=none"
            exit 0
        fi

        echo "**Suggested Topic**: $TOPIC"
        echo ""

        REVIEW_COUNT=$(jq -r --arg topic "$TOPIC" '.topics[$topic].review_count // 0' "$SPACED_REP_FILE" 2>/dev/null || echo "0")
        AVG_SCORE=$(jq -r --arg topic "$TOPIC" '.topics[$topic].score_history | add / length' "$SPACED_REP_FILE" 2>/dev/null || echo "0")

        echo "**Why this topic?**"
        echo "- Reviewed: $REVIEW_COUNT times"
        echo "- Average score: $(printf "%.1f" "$AVG_SCORE")/10"
        echo "- Ready for mastery verification"
        echo ""
        echo "Ready for synthesis? (yes/no, or specify different topic)"
        echo "TOPIC=$TOPIC"
        ;;

    performance-practice)
        if [[ "$TOPIC" == "none" ]]; then
            echo "No performance-practice topic could be inferred."
            echo ""
            echo "Options:"
            echo "1. Specify a topic: /learning-performance-practice \"topic name\""
            echo "2. Add a performance activity to roadmap.json"
            echo "3. Complete a weekly dive, then practice that topic"
            echo "TOPIC=none"
            exit 0
        fi

        echo "**Suggested Topic**: $TOPIC"
        echo ""
        echo "**Why this topic?**"
        echo "It is ready for an observable, constrained performance attempt."
        show_performance_activity "$TOPIC"
        echo ""
        echo "Ready to define the performance contract? (yes/no, or specify a different topic)"
        echo "TOPIC=$TOPIC"
        ;;

    quiz)
        if [[ "$TOPIC" == "none" ]]; then
            echo "No quiz topic could be inferred."
            echo ""
            echo "Options:"
            echo "1. Specify a topic: /learning-quiz \"topic name\""
            echo "2. Complete a weekly dive first — it builds the question bank"
            echo "3. Take a mixed mock exam: /learning-quiz exam"
            echo "TOPIC=none"
            exit 0
        fi

        echo "**Suggested Topic**: $TOPIC"
        echo ""

        LAST_SCORE=$(jq -r --arg topic "$TOPIC" '.topics[$topic].recall_score // "unknown"' "$SPACED_REP_FILE" 2>/dev/null || echo "unknown")
        LAST_REVIEWED=$(jq -r --arg topic "$TOPIC" '.topics[$topic].last_reviewed // "never"' "$SPACED_REP_FILE" 2>/dev/null || echo "never")

        echo "**Why this topic?**"
        echo "- Last studied: $LAST_REVIEWED"
        echo "- Last recall score: $LAST_SCORE/10"
        show_quiz_coverage "$TOPIC"
        echo ""
        echo "Ready to start? (yes/no, or specify a different topic)"
        echo "TOPIC=$TOPIC"
        ;;
esac
