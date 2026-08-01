#!/bin/bash
# Learning System - Automatic Roadmap Status Transitions
#
# Roadmap status is framework-managed. Skills never ask the learner to confirm
# a status change; they call this script and report what it did.
#
# Status model:
#   blocked     prerequisites not yet met (set by /learning-create-roadmap)
#   ready       available to study
#   in-progress currently being learned; gaps may still be open
#   completed   the dive phase is done for this topic
#   mastered    verified by /learning-monthly-synthesis
#
# Operations:
#   enter <topic>                  Start studying a topic. Any OTHER topic left
#                                  in-progress is completed — moving on is the
#                                  signal that the previous topic is done.
#   resolve <topic> <score> <gaps> End of a dive. Completes the topic only when
#                                  it was earned (score >= 7 and no open gaps);
#                                  otherwise it stays in-progress and will be
#                                  completed later by `enter` on another topic.
#   master <topic>                 Mark verified mastery.
#   unlock                         Promote blocked topics whose prerequisites
#                                  are now satisfied. Called automatically by
#                                  every operation above.
#   status [topic]                 Report current statuses as KEY=VALUE lines.
#
# All operations are no-ops (exit 0) when roadmap.json is absent.

set -euo pipefail

source "$(dirname "$0")/load-state.sh"

COMPLETE_SCORE_THRESHOLD=7

# Resolve a caller-supplied topic to its roadmap key.
#
# infer-next.sh returns keys, but a learner who types a topic by hand gives the
# display name ("Circuit Breaker Pattern", not "topic-2-1"). Without this every
# hand-specified topic would report untracked and silently skip its status
# transition. Key match wins; name match is case-insensitive; unmatched input is
# echoed back unchanged so callers still get an `untracked` report.
resolve_topic_key() {
    local input="$1"

    [[ -f "$ROADMAP_FILE" ]] || { echo "$input"; return 0; }

    jq -r --arg in "$input" '
        .topics as $t
        | if ($t | has($in)) then $in
          else
            ($in | ascii_downcase) as $needle
            | ([$t | to_entries[]
                | select(((.value.name // "") | ascii_downcase) == $needle)
                | .key] | first) // $in
          end
    ' "$ROADMAP_FILE" 2>/dev/null || echo "$input"
}

# Write a jq transform back to the roadmap atomically.
apply_to_roadmap() {
    local temp_file
    temp_file=$(mktemp)
    trap "rm -f '$temp_file'" RETURN

    if jq "$@" "$ROADMAP_FILE" > "$temp_file"; then
        mv "$temp_file" "$ROADMAP_FILE"
    else
        echo "ERROR: roadmap update failed; roadmap.json left unchanged" >&2
        return 1
    fi
}

# Promote blocked topics that are now available.
#
# Two roadmap shapes exist in the wild, so both are handled:
#   - explicit prerequisites  -> unlock when every prerequisite is done
#   - empty prerequisites     -> unlock when every lower-sequence topic is done
# Without the second rule, roadmaps generated with `prerequisites: []` would
# stay blocked forever.
op_unlock() {
    [[ -f "$ROADMAP_FILE" ]] || return 0

    local today unlocked
    today=$(portable_date_iso)

    unlocked=$(jq -r --arg today "$today" '
        def done: . == "completed" or . == "mastered";
        .topics as $t
        | [ $t
            | to_entries[]
            | select(.value.status == "blocked")
            | select(
                if ((.value.prerequisites // []) | length) > 0
                then all((.value.prerequisites // [])[]; ($t[.].status // "") | done)
                else
                  ((.value.sequence // 0) as $seq
                   | all($t | to_entries[];
                         (.value.sequence // 0) >= $seq or ((.value.status // "") | done)))
                end
              )
            | .key ]
        | .[]
    ' "$ROADMAP_FILE" 2>/dev/null || true)

    [[ -n "$unlocked" ]] || return 0

    local keys_json
    keys_json=$(printf '%s\n' "$unlocked" | jq -R . | jq -sc .)

    apply_to_roadmap --argjson keys "$keys_json" --arg today "$today" '
        reduce $keys[] as $k (.;
            .topics[$k].status = "ready"
          | .topics[$k].updated_at = $today)
        | .metadata.last_updated = $today
    '

    local key
    while IFS= read -r key; do
        [[ -n "$key" ]] && echo "UNLOCKED=$key"
    done <<< "$unlocked"
}

op_enter() {
    local topic="${1:-}"
    if [[ -z "$topic" ]]; then
        echo "Usage: roadmap-status.sh enter <topic>" >&2
        return 1
    fi
    [[ -f "$ROADMAP_FILE" ]] || return 0
    topic=$(resolve_topic_key "$topic")

    local today
    today=$(portable_date_iso)

    # Moving on to a different topic completes whatever was left in-progress.
    local moved_on
    moved_on=$(jq -r --arg topic "$topic" '
        .topics | to_entries
        | map(select(.value.status == "in-progress" and .key != $topic))
        | .[].key
    ' "$ROADMAP_FILE" 2>/dev/null || true)

    if [[ -n "$moved_on" ]]; then
        local keys_json
        keys_json=$(printf '%s\n' "$moved_on" | jq -R . | jq -sc .)
        apply_to_roadmap --argjson keys "$keys_json" --arg today "$today" '
            reduce $keys[] as $k (.;
                .topics[$k].status = "completed"
              | .topics[$k].completed_at = $today
              | .topics[$k].updated_at = $today
              | .topics[$k].completion_reason = "moved-on")
            | .metadata.last_updated = $today
        '
        local key
        while IFS= read -r key; do
            [[ -n "$key" ]] && echo "COMPLETED=$key (moved on to another topic)"
        done <<< "$moved_on"
    fi

    # A revisit of an already-completed or mastered topic must not demote it.
    local current
    current=$(jq -r --arg topic "$topic" '.topics[$topic].status // "absent"' "$ROADMAP_FILE" 2>/dev/null || echo "absent")

    case "$current" in
        absent)
            echo "TOPIC_STATUS=untracked"
            ;;
        completed|mastered)
            echo "TOPIC_STATUS=$current (revisit — not demoted)"
            ;;
        *)
            apply_to_roadmap --arg topic "$topic" --arg today "$today" '
                .topics[$topic].status = "in-progress"
              | .topics[$topic].started_at = (.topics[$topic].started_at // $today)
              | .topics[$topic].updated_at = $today
              | .metadata.last_updated = $today
            '
            echo "TOPIC_STATUS=in-progress"
            ;;
    esac

    op_unlock
}

op_resolve() {
    local topic="${1:-}"
    local score="${2:-0}"
    local gaps="${3:-0}"

    if [[ -z "$topic" ]]; then
        echo "Usage: roadmap-status.sh resolve <topic> <score> <open-gap-count>" >&2
        return 1
    fi
    [[ -f "$ROADMAP_FILE" ]] || return 0

    if ! [[ "$score" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
        echo "Usage: score must be a number 0-10 (got: $score)" >&2
        return 1
    fi
    if ! [[ "$gaps" =~ ^[0-9]+$ ]]; then
        echo "Usage: open-gap-count must be a non-negative integer (got: $gaps)" >&2
        return 1
    fi

    topic=$(resolve_topic_key "$topic")

    local exists
    exists=$(jq -r --arg topic "$topic" 'if .topics[$topic] then "yes" else "no" end' "$ROADMAP_FILE" 2>/dev/null || echo "no")
    if [[ "$exists" != "yes" ]]; then
        echo "TOPIC_STATUS=untracked"
        return 0
    fi

    local today earned
    today=$(portable_date_iso)
    earned=$(awk -v s="$score" -v t="$COMPLETE_SCORE_THRESHOLD" -v g="$gaps" \
        'BEGIN { print (s >= t && g == 0) ? "yes" : "no" }')

    if [[ "$earned" == "yes" ]]; then
        apply_to_roadmap --arg topic "$topic" --arg today "$today" '
            .topics[$topic].status = "completed"
          | .topics[$topic].completed_at = $today
          | .topics[$topic].updated_at = $today
          | .topics[$topic].completion_reason = "met-bar"
          | .metadata.last_updated = $today
        '
        echo "TOPIC_STATUS=completed"
        echo "REASON=score $score >= $COMPLETE_SCORE_THRESHOLD with no open gaps"
    else
        apply_to_roadmap --arg topic "$topic" --arg today "$today" '
            .topics[$topic].status = "in-progress"
          | .topics[$topic].updated_at = $today
          | .metadata.last_updated = $today
        '
        echo "TOPIC_STATUS=in-progress"
        echo "REASON=score $score with $gaps open gap(s) — stays in-progress until you move on"
    fi

    op_unlock
}

op_master() {
    local topic="${1:-}"
    if [[ -z "$topic" ]]; then
        echo "Usage: roadmap-status.sh master <topic>" >&2
        return 1
    fi
    [[ -f "$ROADMAP_FILE" ]] || return 0
    topic=$(resolve_topic_key "$topic")

    local exists
    exists=$(jq -r --arg topic "$topic" 'if .topics[$topic] then "yes" else "no" end' "$ROADMAP_FILE" 2>/dev/null || echo "no")
    if [[ "$exists" != "yes" ]]; then
        echo "TOPIC_STATUS=untracked"
        return 0
    fi

    local today
    today=$(portable_date_iso)
    apply_to_roadmap --arg topic "$topic" --arg today "$today" '
        .topics[$topic].status = "mastered"
      | .topics[$topic].mastered_at = $today
      | .topics[$topic].updated_at = $today
      | .metadata.last_updated = $today
    '
    echo "TOPIC_STATUS=mastered"

    op_unlock
}

op_status() {
    local topic="${1:-}"

    if [[ ! -f "$ROADMAP_FILE" ]]; then
        echo "ROADMAP=absent"
        return 0
    fi

    if [[ -n "$topic" ]]; then
        topic=$(resolve_topic_key "$topic")
        jq -r --arg topic "$topic" '
            .topics[$topic] as $t
            | if $t == null then "TOPIC_STATUS=untracked"
              else
                "TOPIC_STATUS=\($t.status // "unknown")",
                "TOPIC_STARTED=\($t.started_at // "never")",
                "TOPIC_COMPLETED=\($t.completed_at // "never")"
              end
        ' "$ROADMAP_FILE" 2>/dev/null || echo "TOPIC_STATUS=unknown"
        return 0
    fi

    jq -r '
        (.topics // {}) as $t
        | "ROADMAP_TOTAL=\($t | length)",
          "ROADMAP_BLOCKED=\([$t[] | select(.status == "blocked")] | length)",
          "ROADMAP_READY=\([$t[] | select(.status == "ready")] | length)",
          "ROADMAP_IN_PROGRESS=\([$t[] | select(.status == "in-progress")] | length)",
          "ROADMAP_COMPLETED=\([$t[] | select(.status == "completed")] | length)",
          "ROADMAP_MASTERED=\([$t[] | select(.status == "mastered")] | length)",
          "IN_PROGRESS_TOPIC=\(([$t | to_entries[] | select(.value.status == "in-progress") | .key] | first) // "none")"
    ' "$ROADMAP_FILE" 2>/dev/null || echo "ROADMAP=unreadable"
}

OP="${1:-}"
shift || true

case "$OP" in
    enter)   op_enter "${1:-}" ;;
    resolve) op_resolve "${1:-}" "${2:-0}" "${3:-0}" ;;
    master)  op_master "${1:-}" ;;
    unlock)  op_unlock ;;
    status)  op_status "${1:-}" ;;
    *)
        echo "Unknown operation: $OP" >&2
        echo "Usage: roadmap-status.sh {enter <topic>|resolve <topic> <score> <gaps>|master <topic>|unlock|status [topic]}" >&2
        exit 1
        ;;
esac
