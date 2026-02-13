#!/bin/bash
# Learning System - Parse Apply-to-Work Arguments
# Usage: bash ./.claude/scripts/parse-apply-args.sh [--type=X] [--target=Y]

set -uo pipefail

source "$(dirname "$0")/load-state.sh"

WORK_TYPE=""
TARGET=""

for arg in "$@"; do
    case $arg in
        --type=*)
            WORK_TYPE="${arg#*=}"
            ;;
        --target=*)
            TARGET="${arg#*=}"
            ;;
    esac
done

if [[ -z "$WORK_TYPE" ]]; then
    echo "**Inferring work type from profile...**"
    echo ""

    WORK_CONTEXT=$(get_profile_field "work_context.focus" || echo "unknown")

    echo "Your work context: $WORK_CONTEXT"
    echo ""
    echo "What type of work are you doing?"
    echo "1. code-pr - Code PR review"
    echo "2. writing - Writing/documentation"
    echo "3. qa - QA/testing"
    echo "4. architecture - Architecture decision"
    echo "5. security - Security review"
    echo ""
    echo "Specify: --type=<type> --target=<identifier>"
    echo "WORK_TYPE=none"
    exit 0
fi

# Get recently learned topics ready for application
APPLICABLE_TOPICS=$(bash "$(dirname "$0")/infer-next.sh" apply-to-work)

if [[ "$APPLICABLE_TOPICS" == "none" ]]; then
    echo "No recent topics ready for application."
    echo ""
    echo "Topics become applicable when:"
    echo "- Learned in last 2 weeks"
    echo "- Score 7+ (confident recall)"
    echo ""
    echo "Keep doing weekly dives!"
    echo "APPLICABLE_TOPICS=none"
    exit 0
fi

echo "**Work Type**: $WORK_TYPE"
if [[ -n "$TARGET" ]]; then
    echo "**Target**: $TARGET"
fi
echo ""
echo "**Applicable Topics**:"
echo "$APPLICABLE_TOPICS" | while read topic; do
    score=$(jq -r --arg topic "$topic" '.topics[$topic].recall_score // 0' "$SPACED_REP_FILE" 2>/dev/null || echo "0")
    echo "- $topic (score: $score/10)"
done
echo ""
echo "WORK_TYPE=$WORK_TYPE"
echo "TARGET=$TARGET"
echo "APPLICABLE_TOPICS=$APPLICABLE_TOPICS"
