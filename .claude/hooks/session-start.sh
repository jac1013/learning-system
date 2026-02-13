#!/bin/bash
# SessionStart Hook for Learning Framework
# Checks for overdue reviews and injects retrieval stress patterns

set -euo pipefail

# Derive paths from script location (portable across systems)
# This script is at: .claude/hooks/session-start.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LEARNING_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

PREFERENCES_FILE="$LEARNING_ROOT/.learning-preferences.json"
SPACED_REP_FILE="$LEARNING_ROOT/.spaced-repetition.json"
TODAY=$(date -I)

# Source the state loader
source "$LEARNING_ROOT/.claude/scripts/load-state.sh" 2>/dev/null || true

# Check if profile exists
if [[ ! -f "$LEARNING_ROOT/profile.json" ]]; then
    if is_project_mode; then
        PROJECT_DISPLAY=$(get_project_field "project_name")
        cat <<WELCOME
🎓 **Welcome to the Learning System!**

📂 **Project detected**: $PROJECT_DISPLAY

Get started with: \`/learning-init-project\` to set up codebase learning,
or \`/learning-init\` for general topic learning.

---

WELCOME
    else
        cat <<'WELCOME'
🎓 **Welcome to the Learning System!**

Get started with: `/learning-init`

This will:
- Create your personalized profile (10-15 min)
- Generate your learning roadmap (5-10 min)
- Show you how to use the system

Or use `/learning-init-project` to learn about a specific codebase.

---

WELCOME
    fi
    exit 0
fi

# Show learning mode indicator
if is_project_mode; then
    PROJECT_DISPLAY=$(get_project_field "project_name")
    echo "📂 **Learning Mode**: Project ($PROJECT_DISPLAY)"
    echo ""
fi

# Check for overdue daily reviews
if [[ -f "$SPACED_REP_FILE" ]]; then
    overdue_count=$(jq --arg today "$TODAY" '
        .topics
        | to_entries
        | map(select(.value.next_review <= $today))
        | length
    ' "$SPACED_REP_FILE" 2>/dev/null || echo "0")

    if [[ "$overdue_count" -gt 0 ]]; then
        cat <<REMINDER
📅 **Learning Reminder**

You have $overdue_count topic(s) due for review.

Quick practice: \`/learning-daily-recall\` (5-15 min)

---

REMINDER
    fi
fi

# Check if retrieval stress is enabled
if [[ -f "$PREFERENCES_FILE" ]]; then
    enabled=$(jq -r '.retrieval_stress.enabled // true' "$PREFERENCES_FILE")

    if [[ "$enabled" == "true" ]]; then
        intensity=$(jq -r '.retrieval_stress.intensity // "medium"' "$PREFERENCES_FILE")

        cat <<'ENHANCEMENT'
🧠 **Enhanced Learning Mode Active**

Retrieval stress patterns enabled to strengthen learning:
- I may ask you to predict before revealing
- I may ask you to explain without looking at references
- I may ask you to predict impacts before changes

Say "Just show me" anytime to skip retrieval stress for that interaction.

---

ENHANCEMENT
    fi
fi

exit 0
