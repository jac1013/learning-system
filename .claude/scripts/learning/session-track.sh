#!/bin/bash
# Learning System - Session Time Tracker
# Tracks active study sessions and aggregates study time from learning-log.jsonl.
#
# Operations:
#   start <skill> [topic]       Begin session; auto-closes any orphan from prior run
#   duration                    Print elapsed whole minutes of active session (0 if none)
#   end                         Clear active session without logging
#   status                      Show current active session (human-readable)
#   stats [--since=YYYY-MM-DD]  Aggregate hours from learning-log.jsonl as JSON
#
# Orphan policy (when a session was never ended cleanly):
#   - Elapsed < 2 min   : discarded silently (opened-and-closed browsing)
#   - Elapsed > 60 min  : capped at 60 min, logged with capped:true flag
#   - Otherwise         : logged verbatim as type "orphan-session"
#
# set -e omitted: jq calls use fallbacks for missing/malformed state files.

set -uo pipefail

source "$(dirname "$0")/load-state.sh"

ORPHAN_CAP_MINUTES=60
ORPHAN_MIN_MINUTES=2

now_iso_utc() { date -u +%Y-%m-%dT%H:%M:%SZ; }
now_epoch() { date +%s; }

# If .current-session.json exists, decide what to do with it.
# - Discard if < ORPHAN_MIN_MINUTES (user just browsed the skill)
# - Cap at ORPHAN_CAP_MINUTES and append an orphan-session log entry otherwise
close_orphan_if_present() {
    [[ -f "$CURRENT_SESSION_FILE" ]] || return 0

    local prior_skill prior_topic started_epoch started_iso elapsed_min capped
    prior_skill=$(jq -r '.skill // ""' "$CURRENT_SESSION_FILE" 2>/dev/null || echo "")
    prior_topic=$(jq -r '.topic // ""' "$CURRENT_SESSION_FILE" 2>/dev/null || echo "")
    started_epoch=$(jq -r '.started_at_epoch // 0' "$CURRENT_SESSION_FILE" 2>/dev/null || echo "0")
    started_iso=$(jq -r '.started_at_iso // ""' "$CURRENT_SESSION_FILE" 2>/dev/null || echo "")

    if [[ -z "$prior_skill" || "$started_epoch" == "0" ]]; then
        rm -f "$CURRENT_SESSION_FILE"
        return 0
    fi

    elapsed_min=$(( ( $(now_epoch) - started_epoch ) / 60 ))
    (( elapsed_min < 0 )) && elapsed_min=0

    if (( elapsed_min < ORPHAN_MIN_MINUTES )); then
        rm -f "$CURRENT_SESSION_FILE"
        return 0
    fi

    capped=false
    if (( elapsed_min > ORPHAN_CAP_MINUTES )); then
        elapsed_min=$ORPHAN_CAP_MINUTES
        capped=true
    fi

    local entry
    entry=$(jq -nc \
        --arg timestamp "$started_iso" \
        --arg skill "$prior_skill" \
        --arg topic "$prior_topic" \
        --argjson duration "$elapsed_min" \
        --argjson capped "$capped" \
        '{timestamp: $timestamp,
          type: "orphan-session",
          skill: $skill,
          topic: (if $topic == "" then null else $topic end),
          duration_minutes: $duration,
          capped: $capped,
          notes: "auto-closed orphan session"}')

    touch "$LEARNING_LOG"
    echo "$entry" >> "$LEARNING_LOG"
    rm -f "$CURRENT_SESSION_FILE"
    echo "Auto-closed orphan session: $prior_skill (${elapsed_min}m, capped=$capped)"
}

op_start() {
    local skill="${1:-}"
    local topic="${2:-}"
    if [[ -z "$skill" ]]; then
        echo "Usage: session-track.sh start <skill> [topic]" >&2
        return 1
    fi

    close_orphan_if_present

    jq -nc \
        --arg skill "$skill" \
        --arg topic "$topic" \
        --arg iso "$(now_iso_utc)" \
        --argjson epoch "$(now_epoch)" \
        '{skill: $skill,
          topic: (if $topic == "" then null else $topic end),
          started_at_iso: $iso,
          started_at_epoch: $epoch}' > "$CURRENT_SESSION_FILE"

    echo "Session started: $skill${topic:+ ($topic)}"
}

op_duration() {
    if [[ ! -f "$CURRENT_SESSION_FILE" ]]; then
        echo 0
        return 0
    fi
    local started_epoch elapsed_min
    started_epoch=$(jq -r '.started_at_epoch // 0' "$CURRENT_SESSION_FILE" 2>/dev/null || echo "0")
    if [[ "$started_epoch" == "0" ]]; then
        echo 0
        return 0
    fi
    elapsed_min=$(( ( $(now_epoch) - started_epoch ) / 60 ))
    (( elapsed_min < 0 )) && elapsed_min=0
    echo "$elapsed_min"
}

op_end() {
    rm -f "$CURRENT_SESSION_FILE"
}

op_status() {
    if [[ ! -f "$CURRENT_SESSION_FILE" ]]; then
        echo "No active session."
        return 0
    fi
    local skill topic started elapsed
    skill=$(jq -r '.skill // "?"' "$CURRENT_SESSION_FILE" 2>/dev/null || echo "?")
    topic=$(jq -r '.topic // ""' "$CURRENT_SESSION_FILE" 2>/dev/null || echo "")
    started=$(jq -r '.started_at_iso // "?"' "$CURRENT_SESSION_FILE" 2>/dev/null || echo "?")
    elapsed=$(op_duration)
    echo "Active session: $skill"
    [[ -n "$topic" && "$topic" != "null" ]] && echo "Topic: $topic"
    echo "Started: $started"
    echo "Elapsed: ${elapsed}m"
}

op_stats() {
    local since=""
    for arg in "$@"; do
        case "$arg" in
            --since=*) since="${arg#--since=}" ;;
        esac
    done

    if [[ ! -f "$LEARNING_LOG" || ! -s "$LEARNING_LOG" ]]; then
        echo '{"total_minutes":0,"total_hours":0,"session_count":0,"last_7_days_minutes":0,"last_30_days_minutes":0,"by_topic":{},"by_type":{},"earliest":null,"latest":null}'
        return 0
    fi

    local d7 d30
    d7=$(portable_date_ago 7)
    d30=$(portable_date_ago 30)

    jq -s --arg d7 "$d7" --arg d30 "$d30" --arg since "$since" '
        (if $since == "" then
            map(select(.duration_minutes != null))
         else
            map(select(.duration_minutes != null and ((.timestamp // "")[0:10]) >= $since))
         end) as $all
        | (($all | map(.duration_minutes) | add) // 0) as $total
        | {
            total_minutes: $total,
            total_hours: ((($total * 10 / 60) | floor) / 10),
            session_count: ($all | length),
            last_7_days_minutes:  (($all | map(select((.timestamp // "")[0:10] >= $d7))  | map(.duration_minutes) | add) // 0),
            last_30_days_minutes: (($all | map(select((.timestamp // "")[0:10] >= $d30)) | map(.duration_minutes) | add) // 0),
            by_topic: ($all | group_by(.topic // "multi-topic")
                            | map({key: (.[0].topic // "multi-topic"), value: (map(.duration_minutes) | add)})
                            | from_entries),
            by_type:  ($all | group_by(.type // "unknown")
                            | map({key: (.[0].type // "unknown"), value: (map(.duration_minutes) | add)})
                            | from_entries),
            earliest: ($all | map(.timestamp) | min),
            latest:   ($all | map(.timestamp) | max)
          }
    ' "$LEARNING_LOG"
}

OP="${1:-}"
shift || true

case "$OP" in
    start)    op_start "$@" ;;
    duration) op_duration ;;
    end)      op_end ;;
    status)   op_status ;;
    stats)    op_stats "$@" ;;
    *)
        echo "Unknown operation: $OP" >&2
        echo "Usage: session-track.sh {start <skill> [topic]|duration|end|status|stats [--since=YYYY-MM-DD]}" >&2
        exit 1
        ;;
esac
