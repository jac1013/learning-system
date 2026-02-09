#!/bin/bash
# Learning System - Infer Next Topic Helper
# Analyzes state to determine what to work on next

set -euo pipefail

# Source state loader
source "$(dirname "$0")/load-state.sh"

# Get command type from argument
COMMAND_TYPE="${1:-daily-recall}"

TODAY=$(date -I)

# Function to get overdue topics from spaced repetition
get_overdue_topics() {
    if [[ -f "$SPACED_REP_FILE" ]]; then
        jq -r --arg today "$TODAY" '
            .topics
            | to_entries
            | map(select(.value.next_review <= $today))
            | sort_by(.value.priority, .value.next_review)
            | .[].key
        ' "$SPACED_REP_FILE"
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
        ' "$ROADMAP_FILE"
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
        ' "$SPACED_REP_FILE"
    fi
}

# Function to get recently learned topics for application
get_recent_topics() {
    if [[ -f "$SPACED_REP_FILE" ]]; then
        local days_ago=$(date -I -d "14 days ago")
        jq -r --arg date "$days_ago" '
            .topics
            | to_entries
            | map(select(.value.last_reviewed >= $date and .value.recall_score >= 7))
            | sort_by(-.value.last_reviewed)
            | .[].key
        ' "$SPACED_REP_FILE"
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
        ' "$SPACED_REP_FILE" 2>/dev/null)

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

    *)
        echo "Unknown command type: $COMMAND_TYPE" >&2
        exit 1
        ;;
esac
