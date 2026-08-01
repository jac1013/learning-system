#!/bin/bash
# Learning System - Quiz Engine
# Persistent multiple-choice question bank for practice quizzes and mock exams.
# Operations: init, session-init, stats, sample, add-questions, record,
#             list-weak, get-question, search
#
# Questions are NOT individually scheduled (no per-question SM-2). Selection is
# priority-based: unseen questions and repeatedly-missed questions surface first.
# Misses feed the flashcard system instead of a second scheduler.

set -euo pipefail

# Source state loader
source "$(dirname "$0")/load-state.sh"

# Defaults
PRACTICE_COUNT_DEFAULT=8
EXAM_COUNT_DEFAULT=20
WEAK_MISS_THRESHOLD=2

# --- Helpers ---

# Ensure the question bank exists
ensure_quiz_bank_file() {
    if [[ ! -f "$QUIZ_BANK_FILE" ]]; then
        local today
        today=$(portable_date_iso)
        echo "{\"version\":1,\"questions\":{},\"metadata\":{\"total_questions\":0,\"last_updated\":\"$today\",\"last_quiz_session\":null,\"exams_taken\":0}}" | jq '.' > "$QUIZ_BANK_FILE"
    fi
}

# Generate a question ID that is not already in the bank.
# flashcards.sh derives IDs from epoch seconds alone, so a batch add can collide;
# this retries until the ID is free.
generate_question_id() {
    local id
    while :; do
        id="q-$(date +%s)-$RANDOM"
        if ! jq -e --arg id "$id" '.questions | has($id)' "$QUIZ_BANK_FILE" >/dev/null 2>&1; then
            echo "$id"
            return 0
        fi
    done
}

# Normalize text for dedup comparison (lowercase, strip punctuation, collapse whitespace)
normalize_text() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 ]/ /g' | tr -s ' ' | sed 's/^ //;s/ $//'
}

# Structural validation. Returns a semicolon-joined error string, empty if valid.
# Structure is enforced hard because a malformed question in the bank is permanent;
# quality concerns (missing rationale) are warned about separately.
validate_question() {
    local q="$1"
    echo "$q" | jq -r '
        [
          (if (.stem // "") == "" then "missing stem" else empty end),
          (if ((.format // "") | IN("single", "multi")) | not
             then "format must be \"single\" or \"multi\"" else empty end),
          (if ((.options // []) | length) < 2
             then "need at least 2 options" else empty end),
          (if ((.options // []) | map(has("key") and has("text")) | all) | not
             then "every option needs a key and text" else empty end),
          (if ((.correct // []) | length) < 1
             then "correct must list at least one option key" else empty end),
          (if (((.correct // []) - ((.options // []) | map(.key))) | length) > 0
             then "correct references an option key that does not exist" else empty end),
          (if ((.difficulty // "") | IN("recall", "application", "analysis")) | not
             then "difficulty must be recall, application or analysis" else empty end),
          (if (.source_topic // "") == ""
             then "missing source_topic" else empty end),
          (if (.format == "single" and ((.correct // []) | length) != 1)
             then "single-format question must have exactly one correct key" else empty end),
          (if (.format == "multi" and ((.correct // []) | length) < 2)
             then "multi-format question must have at least two correct keys" else empty end)
        ] | join("; ")
    '
}

# Warn (do not fail) when distractors have no stated rationale. The rationale is
# what makes "explain why the others are wrong" possible without re-deriving it.
warn_missing_rationale() {
    local q="$1"
    local missing
    missing=$(echo "$q" | jq -r '
        ((.options // []) | map(.key)) - (.correct // []) as $wrong
        | ($wrong - ((.distractor_rationale // {}) | keys))
        | join(", ")
    ')
    if [[ -n "$missing" ]]; then
        echo "WARNING: no distractor_rationale for option(s): $missing" >&2
    fi
}

# --- Operations ---

op_init() {
    ensure_quiz_bank_file
    echo "Quiz bank initialized at $QUIZ_BANK_FILE"
}

# Entry point for the skill's eager `!` block. Parses mode + topic from raw
# $ARGUMENTS, resolves the topic, and reports bank coverage. Must tolerate every
# state file being absent and must always exit 0.
op_session_init() {
    local raw="${1:-}"
    ensure_quiz_bank_file

    # Trim surrounding whitespace
    raw="$(echo "$raw" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

    local mode="practice"
    local topic="$raw"

    # Leading "exam" (optionally followed by a topic) selects mock-exam mode
    local first_word
    first_word="$(echo "$raw" | awk '{print tolower($1)}')"
    if [[ "$first_word" == "exam" ]]; then
        mode="exam"
        topic="$(echo "$raw" | sed 's/^[[:space:]]*[Ee][Xx][Aa][Mm][[:space:]]*//')"
    fi

    echo "QUIZ_MODE=$mode"

    if [[ "$mode" == "exam" && -z "$topic" ]]; then
        # A mixed exam deliberately spans every topic — no inference needed.
        echo "**Mock exam**: mixed, drawing across all studied topics."
        echo "TOPIC=all"
    else
        bash "$(dirname "${BASH_SOURCE[0]}")/determine-topic.sh" quiz "$topic" || true
    fi

    echo ""
    op_stats
    if [[ "$mode" == "exam" ]]; then
        echo "SUGGESTED_COUNT=$EXAM_COUNT_DEFAULT"
    else
        echo "SUGGESTED_COUNT=$PRACTICE_COUNT_DEFAULT"
    fi
}

# Stats as KEY=VALUE lines for consumption from a `!` block
op_stats() {
    local topic="${1:-}"
    ensure_quiz_bank_file

    if [[ -n "$topic" && "$topic" != "all" ]]; then
        jq -r --arg topic "$topic" --argjson weak "$WEAK_MISS_THRESHOLD" '
            [.questions | to_entries[] | select(.value.source_topic == $topic)] as $q
            | ($q | map(.value.stats.times_seen // 0) | add // 0) as $seen
            | ($q | map(.value.stats.times_missed // 0) | add // 0) as $missed
            | "TOPIC_QUESTIONS=\($q | length)",
              "TOPIC_UNSEEN=\([$q[] | select((.value.stats.times_seen // 0) == 0)] | length)",
              "TOPIC_WEAK=\([$q[] | select((.value.stats.times_missed // 0) >= $weak)] | length)",
              "TOPIC_ACCURACY=\(if $seen > 0 then (($seen - $missed) / $seen * 100 | floor) else "n/a" end)"
        ' "$QUIZ_BANK_FILE"
    else
        jq -r --argjson weak "$WEAK_MISS_THRESHOLD" '
            "BANK_TOTAL=\(.metadata.total_questions // (.questions | length))",
            "BANK_TOPICS=\([.questions | to_entries[].value.source_topic] | unique | join(", "))",
            "BANK_WEAK=\([.questions | to_entries[] | select((.value.stats.times_missed // 0) >= $weak)] | length)",
            "BANK_UNSEEN=\([.questions | to_entries[] | select((.value.stats.times_seen // 0) == 0)] | length)",
            "EXAMS_TAKEN=\(.metadata.exams_taken // 0)",
            "LAST_SESSION=\(.metadata.last_quiz_session // "never")",
            "BY_TOPIC=\([.questions | to_entries | group_by(.value.source_topic)[]
                         | {topic: .[0].value.source_topic,
                            total: length,
                            weak: ([.[] | select((.value.stats.times_missed // 0) >= $weak)] | length)}]
                        | map("\(.topic): \(.total) questions (\(.weak) weak)") | join("; "))"
        ' "$QUIZ_BANK_FILE"
    fi
}

# Select questions to serve.
# Priority favours never-seen questions and repeat misses, and pushes down
# anything already served today so a single session does not repeat itself.
op_sample() {
    local topic="${1:-all}"
    local count="${2:-$PRACTICE_COUNT_DEFAULT}"
    local mode_arg="${3:---mode=practice}"
    ensure_quiz_bank_file

    local mode="practice"
    case "$mode_arg" in
        --mode=exam) mode="exam" ;;
        --mode=practice) mode="practice" ;;
        *) echo "Unknown sample flag: $mode_arg (expected --mode=practice|exam)" >&2; return 1 ;;
    esac

    local today
    today=$(portable_date_iso)

    # Shared scoring pass: filter by topic, attach priority and a seeded tiebreak
    # so repeated calls do not return the same ordering.
    local scored
    scored=$(jq -c --arg topic "$topic" --arg today "$today" --argjson seed "$RANDOM" '
        [.questions | to_entries[]
         | select($topic == "all" or $topic == "" or .value.source_topic == $topic)]
        | map(. + {
            _prio: (
                (if (.value.stats.times_seen // 0) == 0 then 3 else 0 end)
              + (2 * ((.value.stats.times_missed // 0)
                      / ([(.value.stats.times_seen // 0), 1] | max)))
              + (if (.value.stats.last_seen // "") == $today then -4 else 0 end)
            ),
            _tie: (((([.key | explode[]] | add) // 0) + $seed) % 997)
          })
        | sort_by(-._prio, ._tie)
    ' "$QUIZ_BANK_FILE")

    local available
    available=$(echo "$scored" | jq 'length')

    if [[ "$available" -lt "$count" ]]; then
        echo "COVERAGE_WARNING: bank holds $available matching question(s), $count requested. Author the remaining $(( count - available )) and deposit them with add-questions before serving." >&2
    fi

    local selected
    if [[ "$mode" == "exam" ]]; then
        # Balance coverage across topics so an exam is representative rather than
        # dominated by whichever topic has the most banked questions.
        selected=$(echo "$scored" | jq -c --argjson limit "$count" '
            (group_by(.value.source_topic)) as $groups
            | (if ($groups | length) > 0
               then (($limit / ($groups | length)) | ceil)
               else $limit end) as $quota
            | [$groups[] | .[:$quota]]
            | flatten
            | sort_by(-._prio, ._tie)
            | .[:$limit]
        ')

        # Report the difficulty mix; a bank that is all recall makes a poor exam.
        # Counted directly rather than via from_entries: jq 1.8 dropped the
        # {k,v} shorthand that older versions accepted, and this diagnostic must
        # never be the thing that takes down a sample. `|| true` for the same
        # reason — set -e would otherwise abort before the questions are emitted.
        echo "$selected" | jq -r '
            (length) as $n
            | if $n == 0 then empty
              else
                ([.[] | select(.value.difficulty == "recall")] | length) as $recall
                | if ($recall / $n) > 0.5
                  then "COVERAGE_WARNING: \($recall)/\($n) selected questions are pure recall. A mock exam should lean on application and analysis items."
                  else empty end
              end
        ' >&2 || true
    else
        selected=$(echo "$scored" | jq -c --argjson limit "$count" '.[:$limit]')
    fi

    echo "$selected" | jq 'map({id: .key} + .value | del(._prio, ._tie))'
}

# Add one question. Internal — callers use add-questions.
add_one_question() {
    local q_json="$1"
    ensure_quiz_bank_file

    local errors
    errors=$(validate_question "$q_json")
    if [[ -n "$errors" ]]; then
        echo "INVALID: $errors" >&2
        return 0
    fi

    warn_missing_rationale "$q_json"

    local today
    today=$(portable_date_iso)

    # Dedup: same normalized stem within the same topic
    local stem source_topic normalized
    stem=$(echo "$q_json" | jq -r '.stem')
    source_topic=$(echo "$q_json" | jq -r '.source_topic')
    normalized=$(normalize_text "$stem")

    local existing
    existing=$(jq -r --arg topic "$source_topic" '
        .questions | to_entries[]
        | select(.value.source_topic == $topic)
        | .value.stem
    ' "$QUIZ_BANK_FILE" 2>/dev/null || true)

    while IFS= read -r existing_stem; do
        [[ -z "$existing_stem" ]] && continue
        if [[ "$normalized" == "$(normalize_text "$existing_stem")" ]]; then
            echo "DUPLICATE: a question with this stem already exists for topic '$source_topic'. Skipping." >&2
            return 0
        fi
    done <<< "$existing"

    local q_id
    q_id=$(generate_question_id)

    local temp_file
    temp_file=$(mktemp)
    trap "rm -f '$temp_file'" RETURN

    jq --arg id "$q_id" \
       --arg today "$today" \
       --argjson q "$q_json" '
        .questions[$id] = ($q + {
            created_at: $today,
            stats: {
                times_seen: 0,
                times_missed: 0,
                last_seen: null,
                history: []
            }
        }) |
        .metadata.total_questions = (.questions | length) |
        .metadata.last_updated = $today
    ' "$QUIZ_BANK_FILE" > "$temp_file" && mv "$temp_file" "$QUIZ_BANK_FILE"

    echo "Added question: $q_id"
}

# Batch add (JSON array argument)
op_add_questions() {
    local questions_json="$1"

    if ! echo "$questions_json" | jq -e 'type == "array"' >/dev/null 2>&1; then
        echo "ERROR: add-questions expects a JSON array" >&2
        return 1
    fi

    local count added
    count=$(echo "$questions_json" | jq 'length')
    added=0

    local i
    for i in $(seq 0 $(( count - 1 ))); do
        local q result
        q=$(echo "$questions_json" | jq -c ".[$i]")
        result=$(add_one_question "$q" 2>&1)
        if [[ "$result" != *DUPLICATE* && "$result" != *INVALID* ]]; then
            added=$((added + 1))
        fi
        echo "$result"
    done

    echo "Added $added of $count questions"
}

# Record an attempt. Unlike flashcards.sh update-sm2, this refuses unknown IDs
# rather than silently creating an orphan entry.
op_record() {
    local q_id="$1"
    local correct="$2"
    local picked="${3:-}"
    ensure_quiz_bank_file

    if [[ "$correct" != "0" && "$correct" != "1" ]]; then
        echo "ERROR: correct must be 0 or 1, got '$correct'" >&2
        return 1
    fi

    if ! jq -e --arg id "$q_id" '.questions | has($id)' "$QUIZ_BANK_FILE" >/dev/null 2>&1; then
        echo "ERROR: no question with id '$q_id' in the bank" >&2
        return 1
    fi

    local picked_json='[]'
    if [[ -n "$picked" ]]; then
        picked_json=$(printf '%s' "$picked" | jq -R -c '
            split(",")
            | map(sub("^[[:space:]]+"; "") | sub("[[:space:]]+$"; ""))
            | map(select(length > 0))
        ')
    fi

    local today
    today=$(portable_date_iso)

    local temp_file
    temp_file=$(mktemp)
    trap "rm -f '$temp_file'" RETURN

    jq --arg id "$q_id" \
       --arg today "$today" \
       --argjson correct "$correct" \
       --argjson picked "$picked_json" '
        .questions[$id].stats.times_seen += 1 |
        (if $correct == 0
         then .questions[$id].stats.times_missed += 1
         else . end) |
        .questions[$id].stats.last_seen = $today |
        .questions[$id].stats.history += [{
            date: $today,
            correct: ($correct == 1),
            picked: $picked
        }] |
        .metadata.last_updated = $today |
        .metadata.last_quiz_session = $today
    ' "$QUIZ_BANK_FILE" > "$temp_file" && mv "$temp_file" "$QUIZ_BANK_FILE"

    local verdict="missed"
    [[ "$correct" == "1" ]] && verdict="correct"
    echo "Recorded $q_id: $verdict"
}

# Mark that a mock exam was completed (drives the exams_taken counter)
op_record_exam() {
    ensure_quiz_bank_file
    local today
    today=$(portable_date_iso)

    local temp_file
    temp_file=$(mktemp)
    trap "rm -f '$temp_file'" RETURN

    jq --arg today "$today" '
        .metadata.exams_taken = ((.metadata.exams_taken // 0) + 1) |
        .metadata.last_updated = $today |
        .metadata.last_quiz_session = $today
    ' "$QUIZ_BANK_FILE" > "$temp_file" && mv "$temp_file" "$QUIZ_BANK_FILE"

    echo "Exam recorded (total: $(jq -r '.metadata.exams_taken' "$QUIZ_BANK_FILE"))"
}

# Questions missed repeatedly — the confirmed confusions
op_list_weak() {
    local topic="${1:-}"
    local limit="${2:-10}"
    ensure_quiz_bank_file

    jq --arg topic "$topic" --argjson limit "$limit" --argjson weak "$WEAK_MISS_THRESHOLD" '
        [.questions | to_entries[]
         | select($topic == "" or $topic == "all" or .value.source_topic == $topic)
         | select((.value.stats.times_missed // 0) >= $weak)]
        | map({id: .key} + .value
              + {miss_rate: ((.value.stats.times_missed // 0)
                             / ([(.value.stats.times_seen // 0), 1] | max))})
        | sort_by(.miss_rate) | reverse
        | .[:$limit]
    ' "$QUIZ_BANK_FILE"
}

op_get_question() {
    local q_id="$1"
    ensure_quiz_bank_file

    jq --arg id "$q_id" '.questions[$id] // empty | {id: $id} + .' "$QUIZ_BANK_FILE"
}

op_search() {
    local query="$1"
    ensure_quiz_bank_file

    local query_lower
    query_lower=$(echo "$query" | tr '[:upper:]' '[:lower:]')

    jq --arg q "$query_lower" '
        [.questions | to_entries[]
         | select(
            (.value.stem | ascii_downcase | contains($q)) or
            ((.value.options // []) | map(.text | ascii_downcase) | any(contains($q))) or
            ((.value.tags // []) | map(ascii_downcase) | any(contains($q))) or
            (.value.source_topic | ascii_downcase | contains($q))
         )]
        | map({id: .key,
               stem: .value.stem,
               topic: .value.source_topic,
               difficulty: .value.difficulty,
               times_seen: (.value.stats.times_seen // 0),
               times_missed: (.value.stats.times_missed // 0)})
    ' "$QUIZ_BANK_FILE"
}

# --- Dispatch ---

if [[ $# -eq 0 ]]; then
    echo "Usage: quiz.sh <operation> [args...]" >&2
    echo "Operations: init, session-init, stats, sample, add-questions, record," >&2
    echo "            record-exam, list-weak, get-question, search" >&2
    exit 1
fi

operation="$1"
shift

case "$operation" in
    init)
        op_init
        ;;
    session-init)
        op_session_init "${1:-}"
        ;;
    stats)
        op_stats "${1:-}"
        ;;
    sample)
        op_sample "${1:-all}" "${2:-$PRACTICE_COUNT_DEFAULT}" "${3:---mode=practice}"
        ;;
    add-questions)
        if [[ $# -lt 1 ]]; then
            echo "Usage: quiz.sh add-questions '<json-array>'" >&2
            exit 1
        fi
        op_add_questions "$1"
        ;;
    record)
        if [[ $# -lt 2 ]]; then
            echo "Usage: quiz.sh record <question-id> <0|1> [picked-keys]" >&2
            exit 1
        fi
        op_record "$1" "$2" "${3:-}"
        ;;
    record-exam)
        op_record_exam
        ;;
    list-weak)
        op_list_weak "${1:-}" "${2:-10}"
        ;;
    get-question)
        if [[ $# -lt 1 ]]; then
            echo "Usage: quiz.sh get-question <question-id>" >&2
            exit 1
        fi
        op_get_question "$1"
        ;;
    search)
        if [[ $# -lt 1 ]]; then
            echo "Usage: quiz.sh search <query>" >&2
            exit 1
        fi
        op_search "$1"
        ;;
    *)
        echo "Unknown operation: $operation" >&2
        exit 1
        ;;
esac
