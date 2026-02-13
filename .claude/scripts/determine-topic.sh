#!/bin/bash
# Learning System - Determine Topic Helper
# Topic resolution for daily-recall, weekly-dive, monthly-synthesis
# Usage: bash ./.claude/scripts/determine-topic.sh <skill-type> [optional-topic]

set -uo pipefail

source "$(dirname "$0")/load-state.sh"

SKILL_TYPE="${1:-daily-recall}"
USER_TOPIC="${2:-}"

if [[ -n "$USER_TOPIC" ]]; then
    case "$SKILL_TYPE" in
        daily-recall)    echo "Topic specified: $USER_TOPIC" ;;
        weekly-dive)     echo "Topic specified: $USER_TOPIC" ;;
        monthly-synthesis) echo "Topic specified: $USER_TOPIC" ;;
    esac
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
esac
