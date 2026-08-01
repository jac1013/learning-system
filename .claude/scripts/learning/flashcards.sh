#!/bin/bash
# Learning System - Flashcard Engine
# Card-level spaced repetition with SM-2 algorithm, plus an in-session lapse queue
# Operations: init, stats, list-due, add-card, add-cards, update-sm2, get-card, search, export-anki,
#             queue-init, queue-next, queue-rate, queue-status, queue-end

set -euo pipefail

# Source state loader
source "$(dirname "$0")/load-state.sh"

# --- Helpers ---

# Generate a unique card ID
generate_card_id() {
    echo "card-$(date +%s)-$RANDOM"
}

# Ensure flashcards file exists
ensure_flashcards_file() {
    if [[ ! -f "$FLASHCARDS_FILE" ]]; then
        local today=$(portable_date_iso)
        echo "{\"version\":1,\"cards\":{},\"metadata\":{\"total_cards\":0,\"last_updated\":\"$today\",\"last_review_session\":null}}" | jq '.' > "$FLASHCARDS_FILE"
    fi
}

# Normalize text for dedup comparison (lowercase, strip punctuation, collapse whitespace)
normalize_text() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 ]/ /g' | tr -s ' ' | sed 's/^ //;s/ $//'
}

# --- SM-2 Algorithm ---

# SM-2 spaced repetition algorithm
# Quality mapping: Again=0, Hard=3, Good=4, Easy=5
calculate_sm2() {
    local interval="$1"
    local ease_factor="$2"
    local repetitions="$3"
    local quality="$4"

    awk -v iv="$interval" -v ef="$ease_factor" -v reps="$repetitions" -v q="$quality" '
    BEGIN {
        # Calculate new ease factor (always applies)
        new_ef = ef + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
        if (new_ef < 1.3) new_ef = 1.3

        if (q >= 3) {
            # Passed: increment repetitions, calculate interval
            new_reps = reps + 1
            if (reps == 0) new_iv = 1
            else if (reps == 1) new_iv = 6
            else { new_iv = int(iv * ef + 0.5) }  # round
        } else {
            # Failed: reset
            new_reps = 0
            new_iv = 1
        }

        printf "{\"interval\": %d, \"ease_factor\": %.2f, \"repetitions\": %d}\n", new_iv, new_ef, new_reps
    }'
}

# --- Operations ---

# Initialize flashcards file
op_init() {
    ensure_flashcards_file
    echo "Flashcards file initialized at $FLASHCARDS_FILE"
}

# Show stats, optionally filtered by topic
op_stats() {
    local topic="${1:-}"
    ensure_flashcards_file

    local today=$(portable_date_iso)

    if [[ -n "$topic" ]]; then
        jq -r --arg today "$today" --arg topic "$topic" '
            .cards | to_entries | map(select(.value.source_topic == $topic)) |
            "TOPIC_CARDS=\(length)",
            "DUE=\([.[] | select(.value.sm2.next_review <= $today)] | length)",
            "AVG_EASE=\(if length > 0 then ([.[].value.sm2.ease_factor] | add / length * 100 | floor / 100) else 0 end)"
        ' "$FLASHCARDS_FILE"
    else
        jq -r --arg today "$today" '
            "TOTAL_CARDS=\(.metadata.total_cards // (.cards | length))",
            "DUE_TODAY=\([.cards | to_entries[] | select(.value.sm2.next_review <= $today)] | length)",
            "LAST_SESSION=\(.metadata.last_review_session // "never")",
            "TOPICS=\([.cards | to_entries[].value.source_topic] | unique | join(", "))",
            "BY_TOPIC=\([.cards | to_entries | group_by(.value.source_topic)[] | {topic: .[0].value.source_topic, total: length, due: [.[] | select(.value.sm2.next_review <= $today)] | length}] | map("\(.topic): \(.total) cards (\(.due) due)") | join("; "))"
        ' "$FLASHCARDS_FILE"
    fi
}

# List due cards as JSON, optionally filtered by topic and limited
op_list_due() {
    local topic="${1:-}"
    local limit="${2:-10}"
    ensure_flashcards_file

    local today=$(portable_date_iso)

    if [[ -n "$topic" ]]; then
        jq -r --arg today "$today" --arg topic "$topic" --argjson limit "$limit" '
            [.cards | to_entries[]
             | select(.value.sm2.next_review <= $today and .value.source_topic == $topic)]
            | sort_by(.value.sm2.next_review)
            | .[:$limit]
            | map({id: .key} + .value)
        ' "$FLASHCARDS_FILE"
    else
        jq -r --arg today "$today" --argjson limit "$limit" '
            [.cards | to_entries[]
             | select(.value.sm2.next_review <= $today)]
            | sort_by(.value.sm2.next_review)
            | .[:$limit]
            | map({id: .key} + .value)
        ' "$FLASHCARDS_FILE"
    fi
}

# Add a single card (JSON argument)
op_add_card() {
    local card_json="$1"
    ensure_flashcards_file

    local today=$(portable_date_iso)
    local tomorrow=$(portable_date_add 1)
    local card_id=$(generate_card_id)

    # Check for dedup: same source_topic and similar front text
    local front=$(echo "$card_json" | jq -r '.front')
    local source_topic=$(echo "$card_json" | jq -r '.source_topic // ""')
    local normalized=$(normalize_text "$front")

    if [[ -n "$source_topic" ]]; then
        local existing=$(jq -r --arg topic "$source_topic" '
            .cards | to_entries[]
            | select(.value.source_topic == $topic)
            | .value.front
        ' "$FLASHCARDS_FILE" 2>/dev/null || true)

        while IFS= read -r existing_front; do
            [[ -z "$existing_front" ]] && continue
            local existing_norm=$(normalize_text "$existing_front")
            if [[ "$normalized" == "$existing_norm" ]]; then
                echo "DUPLICATE: Card with similar front already exists for topic '$source_topic'. Skipping." >&2
                return 0
            fi
        done <<< "$existing"
    fi

    local temp_file=$(mktemp)
    trap "rm -f '$temp_file'" RETURN

    jq --arg id "$card_id" \
       --arg today "$today" \
       --arg tomorrow "$tomorrow" \
       --argjson card "$card_json" '
        .cards[$id] = ($card + {
            created_at: $today,
            sm2: {
                interval: 1,
                ease_factor: 2.5,
                repetitions: 0,
                next_review: $tomorrow,
                last_reviewed: null,
                quality_history: []
            }
        }) |
        .metadata.total_cards = (.cards | length) |
        .metadata.last_updated = $today
    ' "$FLASHCARDS_FILE" > "$temp_file" && mv "$temp_file" "$FLASHCARDS_FILE"

    echo "Added card: $card_id"
}

# Batch add cards (JSON array argument)
op_add_cards() {
    local cards_json="$1"
    local count=$(echo "$cards_json" | jq 'length')
    local added=0

    for i in $(seq 0 $(( count - 1 ))); do
        local card=$(echo "$cards_json" | jq ".[$i]")
        local result=$(op_add_card "$card" 2>&1)
        if [[ "$result" != DUPLICATE* ]]; then
            added=$((added + 1))
        fi
        echo "$result"
    done

    echo "Added $added of $count cards"
}

# Update SM-2 state for a card after review
op_update_sm2() {
    local card_id="$1"
    local quality="$2"
    ensure_flashcards_file

    local today=$(portable_date_iso)

    # Get current SM-2 state
    local current=$(jq -r --arg id "$card_id" '
        .cards[$id].sm2 | "\(.interval) \(.ease_factor) \(.repetitions)"
    ' "$FLASHCARDS_FILE")

    local cur_interval=$(echo "$current" | awk '{print $1}')
    local cur_ease=$(echo "$current" | awk '{print $2}')
    local cur_reps=$(echo "$current" | awk '{print $3}')

    # Calculate new SM-2 state
    local sm2_result=$(calculate_sm2 "$cur_interval" "$cur_ease" "$cur_reps" "$quality")
    local new_interval=$(echo "$sm2_result" | jq -r '.interval')
    local new_ease=$(echo "$sm2_result" | jq -r '.ease_factor')
    local new_reps=$(echo "$sm2_result" | jq -r '.repetitions')
    local next_review=$(portable_date_add "$new_interval")

    local temp_file=$(mktemp)
    trap "rm -f '$temp_file'" RETURN

    jq --arg id "$card_id" \
       --arg today "$today" \
       --arg next_review "$next_review" \
       --argjson interval "$new_interval" \
       --argjson ease "$new_ease" \
       --argjson reps "$new_reps" \
       --argjson quality "$quality" '
        .cards[$id].sm2.interval = $interval |
        .cards[$id].sm2.ease_factor = $ease |
        .cards[$id].sm2.repetitions = $reps |
        .cards[$id].sm2.next_review = $next_review |
        .cards[$id].sm2.last_reviewed = $today |
        .cards[$id].sm2.quality_history += [$quality] |
        .metadata.last_updated = $today |
        .metadata.last_review_session = $today
    ' "$FLASHCARDS_FILE" > "$temp_file" && mv "$temp_file" "$FLASHCARDS_FILE"

    echo "Updated card $card_id: quality=$quality interval=$new_interval ease=$new_ease next=$next_review"
}

# --- In-session lapse queue ---
#
# SM-2 schedules the *next* session. It does nothing for a card you just blanked
# on right now: "Again" resets the interval to 1 day and the card walks away.
# The learner ends the session having never once produced the answer, which is
# the one thing that would have encoded it.
#
# Anki solves this with relearning steps — a lapsed card returns within the same
# session until you get it. This is that mechanic: a lapse puts the card back
# REQUEUE_GAP positions later, so a couple of other cards intervene (long enough
# that it is recall and not echo, short enough to still be the same session).
#
# Two rules make it honest:
#
#   1. Only the FIRST rating of a card in a session drives SM-2. Retries are
#      practice, never measurement. Otherwise blanking a card and then passing
#      it on the retry would schedule it out as if it had been recalled cleanly,
#      which inverts the whole point of the lapse.
#   2. A retry cap stops one unknown card from eating the session. At the cap
#      the card is left for tomorrow — the first "Again" already scheduled it.

QUEUE_RETRY_CAP=3     # attempts per card per session before it is left for tomorrow
QUEUE_REQUEUE_GAP=2   # how many other cards appear before a lapsed card returns

has_flashcard_session() {
    [[ -f "$FLASHCARD_SESSION_FILE" ]]
}

# Build the session queue from due cards.
op_queue_init() {
    local topic="${1:-}"
    local limit="${2:-10}"
    ensure_flashcards_file

    local today due count
    today=$(portable_date_iso)
    due=$(op_list_due "$topic" "$limit")
    count=$(echo "$due" | jq 'length')

    if [[ "$count" -eq 0 ]]; then
        rm -f "$FLASHCARD_SESSION_FILE"
        echo "QUEUE_SIZE=0"
        echo "NO_CARDS_DUE=1"
        return 0
    fi

    # An abandoned session is replaced rather than merged: its cards are still
    # due, so they come back through list-due here anyway.
    local temp_file
    temp_file=$(mktemp)
    trap "rm -f '$temp_file'" RETURN

    echo "$due" | jq \
        --arg today "$today" \
        --arg topic "${topic:-all}" \
        --argjson cap "$QUEUE_RETRY_CAP" \
        --argjson gap "$QUEUE_REQUEUE_GAP" '
        {
            version: 1,
            started_at: $today,
            topic: $topic,
            retry_cap: $cap,
            requeue_gap: $gap,
            queue: [.[].id],
            served: {}
        }
    ' > "$temp_file" && mv "$temp_file" "$FLASHCARD_SESSION_FILE"

    echo "QUEUE_SIZE=$count"
    echo "RETRY_CAP=$QUEUE_RETRY_CAP"
    echo "REQUEUE_GAP=$QUEUE_REQUEUE_GAP"
}

# Peek at the next card. Deliberately does NOT pop — queue-rate removes it.
# Calling this twice in a row returns the same card, so a skill that loses its
# place cannot silently drop a card off the queue.
op_queue_next() {
    if ! has_flashcard_session; then
        echo "SESSION=absent"
        return 0
    fi

    local card_id
    card_id=$(jq -r '.queue[0] // empty' "$FLASHCARD_SESSION_FILE")

    if [[ -z "$card_id" ]]; then
        echo "QUEUE_EMPTY=1"
        return 0
    fi

    jq --arg id "$card_id" --slurpfile session "$FLASHCARD_SESSION_FILE" '
        ($session[0]) as $s
        | (.cards[$id] // {}) as $card
        | {
            id: $id,
            attempt: (($s.served[$id].attempts // 0) + 1),
            remaining: ($s.queue | length),
            retry_cap: $s.retry_cap
          } + $card
    ' "$FLASHCARDS_FILE"
}

# Record a rating. The single entry point after the learner answers — it decides
# whether SM-2 applies and whether the card comes back, so the skill cannot get
# the measurement/practice split wrong.
op_queue_rate() {
    local card_id="${1:-}"
    local quality="${2:-}"

    if [[ -z "$card_id" || -z "$quality" ]]; then
        echo "Usage: flashcards.sh queue-rate <card-id> <quality 0|3|4|5>" >&2
        return 1
    fi
    if ! [[ "$quality" =~ ^[0-5]$ ]]; then
        echo "ERROR: quality must be 0-5 (Again=0, Hard=3, Good=4, Easy=5); got '$quality'" >&2
        return 1
    fi
    if ! has_flashcard_session; then
        echo "ERROR: no active flashcard session; run queue-init first" >&2
        return 1
    fi

    ensure_flashcards_file

    # Unknown ids must not be written. op_update_sm2 would happily create a junk
    # subtree under .cards for a typo'd id, and the queue would then diverge
    # from the deck with no error anywhere.
    local known
    known=$(jq -r --arg id "$card_id" 'if .cards[$id] then "yes" else "no" end' "$FLASHCARDS_FILE")
    if [[ "$known" != "yes" ]]; then
        echo "ERROR: unknown card id '$card_id'" >&2
        return 1
    fi

    local attempts cap gap
    attempts=$(jq -r --arg id "$card_id" '.served[$id].attempts // 0' "$FLASHCARD_SESSION_FILE")
    cap=$(jq -r '.retry_cap // 3' "$FLASHCARD_SESSION_FILE")
    gap=$(jq -r '.requeue_gap // 2' "$FLASHCARD_SESSION_FILE")

    if [[ "$attempts" -eq 0 ]]; then
        op_update_sm2 "$card_id" "$quality" >/dev/null
        echo "SM2_APPLIED=1"
    else
        echo "SM2_APPLIED=0"
        echo "SM2_NOTE=retry rep — the schedule was set by this card's first attempt"
    fi

    local new_attempts=$((attempts + 1))
    local outcome
    if [[ "$quality" -ne 0 ]]; then
        outcome="resolved"
    elif [[ "$new_attempts" -lt "$cap" ]]; then
        outcome="requeued"
    else
        outcome="capped"
    fi

    local temp_file
    temp_file=$(mktemp)
    trap "rm -f '$temp_file'" RETURN

    jq --arg id "$card_id" \
       --argjson quality "$quality" \
       --argjson attempts "$new_attempts" \
       --arg outcome "$outcome" \
       --argjson gap "$gap" '
        def remove_first($x): (index($x)) as $p
            | if $p == null then . else (.[:$p] + .[$p+1:]) end;

        .served[$id] = ((.served[$id] // {attempts: 0, qualities: []})
            | .attempts = $attempts
            | .qualities += [$quality]
            | .outcome = $outcome
            | if $attempts == 1 then .first_quality = $quality else . end)
        | .queue = (.queue | remove_first($id))
        | .queue = (if $outcome == "requeued"
                    then (if $gap >= (.queue | length)
                          then (.queue + [$id])
                          else (.queue[:$gap] + [$id] + .queue[$gap:]) end)
                    else .queue end)
    ' "$FLASHCARD_SESSION_FILE" > "$temp_file" && mv "$temp_file" "$FLASHCARD_SESSION_FILE"

    echo "OUTCOME=$outcome"
    echo "ATTEMPT=$new_attempts/$cap"

    case "$outcome" in
        requeued)
            local pos
            pos=$(jq -r --arg id "$card_id" '(.queue | index($id)) // 0' "$FLASHCARD_SESSION_FILE")
            echo "REQUEUED_AFTER=$pos"
            ;;
        capped)
            echo "CAP_REACHED=$cap"
            echo "CAP_NOTE=left for tomorrow — the first Again already scheduled it"
            ;;
    esac

    echo "QUEUE_REMAINING=$(jq -r '.queue | length' "$FLASHCARD_SESSION_FILE")"
}

op_queue_status() {
    if ! has_flashcard_session; then
        echo "SESSION=absent"
        return 0
    fi

    jq -r '
        (.served | to_entries) as $s
        | "SESSION=active",
          "TOPIC=\(.topic)",
          "QUEUE_REMAINING=\(.queue | length)",
          "CARDS_SEEN=\($s | length)",
          "TOTAL_REPS=\([$s[].value.attempts] | add // 0)",
          "LAPSED=\([$s[] | select((.value.qualities // []) | any(. == 0))] | length)",
          "CAPPED=\([$s[] | select(.value.outcome == "capped")] | length)",
          "RETRY_CAP=\(.retry_cap)",
          "REQUEUE_GAP=\(.requeue_gap)"
    ' "$FLASHCARD_SESSION_FILE"
}

# Report and clear. Safe to call on an already-ended session.
op_queue_end() {
    if ! has_flashcard_session; then
        echo "SESSION=absent"
        return 0
    fi

    op_queue_status

    jq -r '
        (.served | to_entries) as $s
        | "RECOVERED=\([$s[] | select(((.value.qualities // []) | any(. == 0)) and .value.outcome == "resolved")] | length)",
          "UNFINISHED=\(.queue | length)",
          "AVG_FIRST_QUALITY=\([$s[].value.first_quality // empty] | if length > 0 then (add / length * 100 | floor / 100) else 0 end)"
    ' "$FLASHCARD_SESSION_FILE"

    rm -f "$FLASHCARD_SESSION_FILE"
}

# Get a single card by ID
op_get_card() {
    local card_id="$1"
    ensure_flashcards_file

    jq --arg id "$card_id" '.cards[$id] // empty | {id: $id} + .' "$FLASHCARDS_FILE"
}

# Search cards by text or tag
op_search() {
    local query="$1"
    ensure_flashcards_file

    local query_lower=$(echo "$query" | tr '[:upper:]' '[:lower:]')

    jq -r --arg q "$query_lower" '
        [.cards | to_entries[]
         | select(
            (.value.front | ascii_downcase | contains($q)) or
            (.value.back | ascii_downcase | contains($q)) or
            (.value.tags | map(ascii_downcase) | any(contains($q))) or
            (.value.source_topic | ascii_downcase | contains($q))
         )]
        | map({id: .key, type: .value.type, front: .value.front, topic: .value.source_topic, tags: .value.tags})
    ' "$FLASHCARDS_FILE"
}

# Export cards in Anki-importable tab-separated format
op_export_anki() {
    local topic="${1:-}"
    ensure_flashcards_file

    if [[ -n "$topic" ]]; then
        jq -r --arg topic "$topic" '
            .cards | to_entries[]
            | select(.value.source_topic == $topic)
            | [.value.front, .value.back, (.value.tags | join(" "))]
            | @tsv
        ' "$FLASHCARDS_FILE"
    else
        jq -r '
            .cards | to_entries[]
            | [.value.front, .value.back, (.value.tags | join(" "))]
            | @tsv
        ' "$FLASHCARDS_FILE"
    fi
}

# --- Dispatch ---

if [[ $# -eq 0 ]]; then
    echo "Usage: flashcards.sh <operation> [args...]" >&2
    echo "Operations: init, stats, list-due, add-card, add-cards, update-sm2, get-card, search, export-anki," >&2
    echo "            queue-init, queue-next, queue-rate, queue-status, queue-end" >&2
    exit 1
fi

operation="$1"
shift

case "$operation" in
    init)
        op_init
        ;;
    stats)
        op_stats "${1:-}"
        ;;
    list-due)
        op_list_due "${1:-}" "${2:-10}"
        ;;
    add-card)
        op_add_card "$1"
        ;;
    add-cards)
        op_add_cards "$1"
        ;;
    update-sm2)
        op_update_sm2 "$1" "$2"
        ;;
    get-card)
        op_get_card "$1"
        ;;
    search)
        op_search "$1"
        ;;
    export-anki)
        op_export_anki "${1:-}"
        ;;
    queue-init)
        op_queue_init "${1:-}" "${2:-10}"
        ;;
    queue-next)
        op_queue_next
        ;;
    queue-rate)
        op_queue_rate "${1:-}" "${2:-}"
        ;;
    queue-status)
        op_queue_status
        ;;
    queue-end)
        op_queue_end
        ;;
    *)
        echo "Unknown operation: $operation" >&2
        exit 1
        ;;
esac
