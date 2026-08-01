#!/bin/bash
# Learning System - Save State Helper
# Updates state files after learning sessions

set -euo pipefail

# Source state loader
source "$(dirname "$0")/load-state.sh"

# Function to update spaced repetition state
update_spaced_repetition() {
    local topic="$1"
    local score="$2"
    local notes="${3:-}"

    local today=$(portable_date_iso)

    # Calculate next interval based on score
    local last_interval=1
    if [[ -f "$SPACED_REP_FILE" ]]; then
        last_interval=$(jq -r --arg topic "$topic" '.topics[$topic].intervals[-1] // 1' "$SPACED_REP_FILE")
    fi

    local next_interval
    if (( score >= 9 )); then
        next_interval=$(awk "BEGIN {printf \"%d\", $last_interval * 2.5}")
        [[ $next_interval -gt 30 ]] && next_interval=30
    elif (( score >= 7 )); then
        next_interval=$(awk "BEGIN {printf \"%d\", $last_interval * 1.5}")
    elif (( score >= 5 )); then
        next_interval=$last_interval
    else
        next_interval=1
    fi

    local next_review=$(portable_date_add "$next_interval")

    # Create or update topic entry
    local temp_file=$(mktemp)
    trap "rm -f '$temp_file'" RETURN

    if [[ ! -f "$SPACED_REP_FILE" ]]; then
        echo '{"topics": {}, "metadata": {}}' > "$SPACED_REP_FILE"
    fi

    jq --arg topic "$topic" \
       --arg today "$today" \
       --arg next_review "$next_review" \
       --argjson score "$score" \
       --argjson interval "$next_interval" \
       --arg notes "$notes" '
        .topics[$topic] = {
            last_reviewed: $today,
            next_review: $next_review,
            recall_score: $score,
            review_count: ((.topics[$topic].review_count // 0) + 1),
            intervals: ((.topics[$topic].intervals // []) + [$interval]),
            score_history: ((.topics[$topic].score_history // []) + [$score]),
            notes: $notes,
            updated_at: $today
        } |
        .metadata.last_updated = $today
    ' "$SPACED_REP_FILE" > "$temp_file" && mv "$temp_file" "$SPACED_REP_FILE"

    echo "Updated spaced repetition: $topic (score: $score, next: $next_review)"
}

# Function to append to learning log.
# If an active session exists (.current-session.json), the measured duration
# overrides any duration_minutes supplied in the entry, and the session is
# cleared. This makes study time automatic — skills can omit duration_minutes
# entirely and get a real measurement instead of an estimate.
append_to_log() {
    local entry="$1"

    # Auto-add timestamp if missing
    if ! echo "$entry" | jq -e 'has("timestamp")' >/dev/null 2>&1; then
        local now_iso
        now_iso=$(date -u +%Y-%m-%dT%H:%M:%SZ)
        entry=$(echo "$entry" | jq -c --arg ts "$now_iso" '. + {timestamp: $ts}')
    fi

    # Normalize the generic practice category for reporting. Explicit values
    # win; legacy skill callers are classified from their workflow type.
    entry=$(echo "$entry" | jq -c '
        . as $entry
        | if has("practice_type") and (["knowledge", "performance", "application", "unclassified"] | index($entry.practice_type)) then .
        elif has("practice_type") then error("invalid practice_type: " + (.practice_type | tostring))
        else . + {
            practice_type:
                (if .type == "performance-practice" then "performance"
                 elif .type == "apply-to-work" then "application"
                 elif (.type == "daily-recall"
                       or .type == "weekly-dive"
                       or .type == "monthly-synthesis"
                       or .type == "flashcard-review"
                       or .type == "quiz") then "knowledge"
                 else "unclassified"
                 end)
        }
        end
    ')

    # Auto-enrich with measured session duration (overrides any estimate)
    if [[ -f "$CURRENT_SESSION_FILE" ]]; then
        local duration
        duration=$(bash "$(dirname "${BASH_SOURCE[0]}")/session-track.sh" duration)
        entry=$(echo "$entry" | jq -c --argjson dur "$duration" '. + {duration_minutes: $dur}')
        rm -f "$CURRENT_SESSION_FILE"
    fi

    # Ensure learning log exists
    touch "$LEARNING_LOG"

    # Append JSONL entry
    echo "$entry" >> "$LEARNING_LOG"

    echo "Appended to learning log"
}

# Function to update roadmap topic status
#
# DEPRECATED for skill use — call roadmap-status.sh instead. This is a raw
# setter: it takes whatever status you hand it, does not resolve display names
# to roadmap keys, does not guard against demoting a mastered topic, and does
# not unlock dependents afterwards. roadmap-status.sh owns the lifecycle.
# Kept only as a manual escape hatch for repairing a roadmap by hand.
update_roadmap_status() {
    local topic="$1"
    local status="$2"  # ready, in-progress, completed, mastered

    if [[ ! -f "$ROADMAP_FILE" ]]; then
        echo "Roadmap file not found" >&2
        return 1
    fi

    local temp_file=$(mktemp)
    trap "rm -f '$temp_file'" RETURN
    local today=$(portable_date_iso)

    jq --arg topic "$topic" \
       --arg status "$status" \
       --arg today "$today" '
        if .topics[$topic] then
            .topics[$topic].status = $status |
            .topics[$topic].updated_at = $today
        else
            .
        end |
        .metadata.last_updated = $today
    ' "$ROADMAP_FILE" > "$temp_file" && mv "$temp_file" "$ROADMAP_FILE"

    echo "Updated roadmap: $topic → $status"
}

# Export functions
export -f update_spaced_repetition
export -f append_to_log
export -f update_roadmap_status

# If called with arguments, execute the requested operation
if [[ $# -gt 0 ]]; then
    operation="$1"
    shift

    case "$operation" in
        spaced-rep)
            update_spaced_repetition "$@"
            ;;
        log)
            append_to_log "$@"
            ;;
        roadmap)
            update_roadmap_status "$@"
            ;;
        *)
            echo "Unknown operation: $operation" >&2
            exit 1
            ;;
    esac
fi
