#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_LEARNING_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TEST_ROOT=$(mktemp -d)
trap 'rm -rf "$TEST_ROOT"' EXIT

mkdir -p "$TEST_ROOT/.claude/scripts"
cp -R "$SOURCE_LEARNING_DIR" "$TEST_ROOT/.claude/scripts/learning"

assert_equal() {
    local expected="$1"
    local actual="$2"
    local message="$3"
    if [[ "$actual" != "$expected" ]]; then
        echo "FAIL: $message" >&2
        echo "  expected: $expected" >&2
        echo "  actual:   $actual" >&2
        exit 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="$3"
    if [[ "$haystack" != *"$needle"* ]]; then
        echo "FAIL: $message" >&2
        echo "  expected to contain: $needle" >&2
        echo "  actual:              $haystack" >&2
        exit 1
    fi
}

QUIZ="$TEST_ROOT/.claude/scripts/learning/quiz.sh"
SAVE="$TEST_ROOT/.claude/scripts/learning/save-state.sh"
TRACK="$TEST_ROOT/.claude/scripts/learning/session-track.sh"
BANK="$TEST_ROOT/.quiz-bank.json"

# --- Eager-!-block safety: every state file absent ------------------------
# This is the failure mode that broke skills in cef920f / 6dac758. session-init
# runs at skill-load time, so it must never error on a virgin checkout.
init_output=$(bash "$QUIZ" session-init "" 2>&1)
assert_contains "$init_output" "QUIZ_MODE=practice" "session-init should default to practice mode"
assert_contains "$init_output" "TOPIC=none" "session-init with no state should report no inferable topic"

exam_output=$(bash "$QUIZ" session-init "exam" 2>&1)
assert_contains "$exam_output" "QUIZ_MODE=exam" "a leading 'exam' token should select exam mode"
assert_contains "$exam_output" "TOPIC=all" "a bare exam should draw across all topics"
assert_contains "$exam_output" "SUGGESTED_COUNT=20" "exam mode should suggest the exam question count"

topic_output=$(bash "$QUIZ" session-init "exam topic-a" 2>&1)
assert_contains "$topic_output" "QUIZ_MODE=exam" "exam mode should survive a trailing topic"
assert_contains "$topic_output" "TOPIC=topic-a" "an explicit topic should override inference"

# --- Bank bootstrap -------------------------------------------------------
jq -e . "$BANK" >/dev/null 2>&1 || { echo "FAIL: bank was not bootstrapped" >&2; exit 1; }
total=$(jq -r '.metadata.total_questions' "$BANK")
assert_equal "0" "$total" "a fresh bank should hold no questions"

# --- add-questions --------------------------------------------------------
bash "$QUIZ" add-questions '[
  {
    "stem": "A service must reach the internet for updates but stay unreachable from it. Which approach works?",
    "format": "single",
    "options": [
      {"key": "a", "text": "Public route via internet gateway"},
      {"key": "b", "text": "Default route to a NAT gateway"},
      {"key": "c", "text": "Service-specific private endpoint"},
      {"key": "d", "text": "Assign a public IP"}
    ],
    "correct": ["b"],
    "explanation": "Egress-only, stateful return traffic.",
    "distractor_rationale": {
      "a": "Makes the subnet publicly reachable.",
      "c": "Only covers supported services.",
      "d": "Still requires an inbound-capable route."
    },
    "difficulty": "application",
    "source_topic": "topic-a",
    "source_session": "quiz",
    "tags": ["networking"]
  },
  {
    "stem": "Which two statements describe the mechanism?",
    "format": "multi",
    "options": [
      {"key": "a", "text": "First true statement"},
      {"key": "b", "text": "Second true statement"},
      {"key": "c", "text": "Adjacent-concept confusion"},
      {"key": "d", "text": "True but irrelevant fact"},
      {"key": "e", "text": "Common misreading"}
    ],
    "correct": ["a", "b"],
    "explanation": "Both describe it.",
    "distractor_rationale": {
      "c": "Describes a different mechanism.",
      "d": "True, but does not answer the question.",
      "e": "A frequent misreading of the definition."
    },
    "difficulty": "recall",
    "source_topic": "topic-a",
    "source_session": "quiz",
    "tags": ["definitions"]
  },
  {
    "stem": "Given the failure described, what is the most likely root cause?",
    "format": "single",
    "options": [
      {"key": "a", "text": "Cause one"},
      {"key": "b", "text": "Cause two"},
      {"key": "c", "text": "Cause three"},
      {"key": "d", "text": "Cause four"}
    ],
    "correct": ["c"],
    "explanation": "Only c matches every observed symptom.",
    "distractor_rationale": {
      "a": "Contradicts one symptom.",
      "b": "Would produce a different error.",
      "d": "Is a consequence, not a cause."
    },
    "difficulty": "analysis",
    "source_topic": "topic-b",
    "source_session": "quiz",
    "tags": ["debugging"]
  }
]' >/dev/null 2>&1

total=$(jq -r '.questions | length' "$BANK")
assert_equal "3" "$total" "all three valid questions should be banked"

metadata_total=$(jq -r '.metadata.total_questions' "$BANK")
assert_equal "3" "$metadata_total" "metadata total should track the question count"

stats_zero=$(jq -r '[.questions[] | select(.stats.times_seen == 0)] | length' "$BANK")
assert_equal "3" "$stats_zero" "the script should inject zeroed stats"

created=$(jq -r '[.questions[] | select(.created_at != null)] | length' "$BANK")
assert_equal "3" "$created" "the script should inject created_at"

# --- Dedup on normalized stem within a topic ------------------------------
dup_output=$(bash "$QUIZ" add-questions '[
  {
    "stem": "  a SERVICE must reach the internet for updates but stay unreachable from it. which approach works???  ",
    "format": "single",
    "options": [
      {"key": "a", "text": "One"},
      {"key": "b", "text": "Two"},
      {"key": "c", "text": "Three"},
      {"key": "d", "text": "Four"}
    ],
    "correct": ["b"],
    "explanation": "Same question, different casing and punctuation.",
    "distractor_rationale": {"a": "no", "c": "no", "d": "no"},
    "difficulty": "application",
    "source_topic": "topic-a",
    "source_session": "quiz",
    "tags": []
  }
]' 2>&1 || true)
assert_contains "$dup_output" "DUPLICATE" "a case- and punctuation-varied stem should be caught as a duplicate"
assert_equal "3" "$(jq -r '.questions | length' "$BANK")" "a duplicate must not grow the bank"

# The same stem under a different topic is a legitimate question, not a dupe.
bash "$QUIZ" add-questions '[
  {
    "stem": "A service must reach the internet for updates but stay unreachable from it. Which approach works?",
    "format": "single",
    "options": [
      {"key": "a", "text": "One"},
      {"key": "b", "text": "Two"},
      {"key": "c", "text": "Three"},
      {"key": "d", "text": "Four"}
    ],
    "correct": ["b"],
    "explanation": "Same stem, different topic.",
    "distractor_rationale": {"a": "no", "c": "no", "d": "no"},
    "difficulty": "application",
    "source_topic": "topic-c",
    "source_session": "quiz",
    "tags": []
  }
]' >/dev/null 2>&1
assert_equal "4" "$(jq -r '.questions | length' "$BANK")" "dedup should be scoped to source_topic"

# --- Validation rejects malformed questions -------------------------------
bad_output=$(bash "$QUIZ" add-questions '[
  {
    "stem": "Correct key is not among the options.",
    "format": "single",
    "options": [{"key": "a", "text": "One"}, {"key": "b", "text": "Two"}],
    "correct": ["z"],
    "explanation": "x",
    "difficulty": "recall",
    "source_topic": "topic-a"
  },
  {
    "stem": "Multi-select claiming only one correct answer, with a bad difficulty.",
    "format": "multi",
    "options": [{"key": "a", "text": "One"}, {"key": "b", "text": "Two"}],
    "correct": ["a"],
    "explanation": "x",
    "difficulty": "trivia",
    "source_topic": "topic-a"
  }
]' 2>&1 || true)
assert_contains "$bad_output" "INVALID" "malformed questions should be rejected"
assert_equal "4" "$(jq -r '.questions | length' "$BANK")" "invalid questions must not be banked"

# --- sample ---------------------------------------------------------------
sample=$(bash "$QUIZ" sample topic-a 2 2>/dev/null)
assert_equal "2" "$(jq -r 'length' <<< "$sample")" "sample should honor the requested count"
assert_equal "topic-a" "$(jq -r '[.[].source_topic] | unique | join(",")' <<< "$sample")" "a topic-scoped sample should not leak other topics"
assert_equal "true" "$(jq -r '[.[] | has("id")] | all' <<< "$sample")" "sampled questions must expose an id for record"
assert_equal "true" "$(jq -r '[.[] | has("_prio") or has("_tie")] | any | not' <<< "$sample")" "internal sort keys must not leak to callers"

short_warn=$(bash "$QUIZ" sample topic-b 5 2>&1 >/dev/null || true)
assert_contains "$short_warn" "COVERAGE_WARNING" "an under-stocked bank should warn rather than silently return fewer"

exam_sample=$(bash "$QUIZ" sample all 3 --mode=exam 2>/dev/null)
assert_equal "3" "$(jq -r 'length' <<< "$exam_sample")" "exam sampling should honor the requested count"
assert_equal "3" "$(jq -r '[.[].source_topic] | unique | length' <<< "$exam_sample")" "exam mode should spread across topics"

if bash "$QUIZ" sample all 2 --mode=bogus >/dev/null 2>&1; then
    echo "FAIL: sample accepted an unknown mode flag" >&2
    exit 1
fi

# --- record ---------------------------------------------------------------
QID=$(jq -r '.questions | to_entries | map(select(.value.source_topic == "topic-b")) | .[0].key' "$BANK")

bash "$QUIZ" record "$QID" 0 "a" >/dev/null
assert_equal "1" "$(jq -r --arg q "$QID" '.questions[$q].stats.times_seen' "$BANK")" "record should increment times_seen"
assert_equal "1" "$(jq -r --arg q "$QID" '.questions[$q].stats.times_missed' "$BANK")" "a wrong answer should increment times_missed"
assert_equal '["a"]' "$(jq -c --arg q "$QID" '.questions[$q].stats.history[0].picked' "$BANK")" "record should store the picked keys as an array"

bash "$QUIZ" record "$QID" 1 "c" >/dev/null
assert_equal "2" "$(jq -r --arg q "$QID" '.questions[$q].stats.times_seen' "$BANK")" "a correct answer should still increment times_seen"
assert_equal "1" "$(jq -r --arg q "$QID" '.questions[$q].stats.times_missed' "$BANK")" "a correct answer must not increment times_missed"
assert_equal "2" "$(jq -r --arg q "$QID" '.questions[$q].stats.history | length' "$BANK")" "every attempt should append to history"

# Unknown ids must fail loudly. flashcards.sh op_update_sm2 silently creates a
# junk subtree for a bad id; that bug is deliberately not replicated here.
if bash "$QUIZ" record "q-does-not-exist" 1 "a" >/dev/null 2>&1; then
    echo "FAIL: record accepted an unknown question id" >&2
    exit 1
fi
if bash "$QUIZ" record "$QID" 7 "a" >/dev/null 2>&1; then
    echo "FAIL: record accepted a non-boolean correctness flag" >&2
    exit 1
fi

# --- Same-day deprioritization -------------------------------------------
# A question answered today should sort below an unseen one, so a single
# session does not serve the same item twice. Recorded as correct so this does
# not disturb the weak-question assertions below.
SEEN_A=$(jq -r '.questions | to_entries | map(select(.value.source_topic == "topic-a")) | .[0].key' "$BANK")
UNSEEN_A=$(jq -r '.questions | to_entries | map(select(.value.source_topic == "topic-a")) | .[1].key' "$BANK")
bash "$QUIZ" record "$SEEN_A" 1 "b" >/dev/null

first_id=$(bash "$QUIZ" sample topic-a 2 2>/dev/null | jq -r '.[0].id')
assert_equal "$UNSEEN_A" "$first_id" "an unseen question should outrank one already served today"

# --- list-weak ------------------------------------------------------------
weak=$(bash "$QUIZ" list-weak 2>/dev/null)
assert_equal "0" "$(jq -r 'length' <<< "$weak")" "one miss should not qualify as weak"

bash "$QUIZ" record "$QID" 0 "b" >/dev/null
weak=$(bash "$QUIZ" list-weak 2>/dev/null)
assert_equal "1" "$(jq -r 'length' <<< "$weak")" "two misses should cross the weak threshold"
assert_equal "$QID" "$(jq -r '.[0].id' <<< "$weak")" "list-weak should report the repeatedly missed question"

# --- stats ----------------------------------------------------------------
stats=$(bash "$QUIZ" stats)
assert_contains "$stats" "BANK_TOTAL=4" "stats should report the bank size"
assert_contains "$stats" "BANK_WEAK=1" "stats should report the weak-question count"

topic_stats=$(bash "$QUIZ" stats topic-b)
assert_contains "$topic_stats" "TOPIC_QUESTIONS=1" "topic-scoped stats should count only that topic"

# --- Bank stays valid JSON throughout ------------------------------------
jq -e . "$BANK" >/dev/null || { echo "FAIL: bank is no longer valid JSON" >&2; exit 1; }

# --- practice_type classification in BOTH classifiers ---------------------
# save-state.sh and session-track.sh duplicate this jq verbatim. Editing only
# one makes /learning-hours disagree with the stored log.
bash "$SAVE" log '{"type":"quiz","topic":"topic-a","mode":"practice","questions_total":4,"questions_correct":3,"duration_minutes":12}' >/dev/null
practice_type=$(tail -1 "$TEST_ROOT/learning-log.jsonl" | jq -r '.practice_type')
assert_equal "knowledge" "$practice_type" "save-state should classify a quiz entry as knowledge practice"

bash "$SAVE" log '{"type":"quiz","practice_type":"knowledge","topic":"all","mode":"exam","questions_total":10,"questions_correct":8,"passed":true,"duration_minutes":18}' >/dev/null
practice_type=$(tail -1 "$TEST_ROOT/learning-log.jsonl" | jq -r '.practice_type')
assert_equal "knowledge" "$practice_type" "an explicit knowledge practice_type should be preserved"

track_stats=$(bash "$TRACK" stats)
knowledge_minutes=$(jq -r '.by_practice_type.knowledge' <<< "$track_stats")
assert_equal "30" "$knowledge_minutes" "session-track should aggregate quiz time under knowledge, not unclassified"
unclassified=$(jq -r '.by_practice_type.unclassified // 0' <<< "$track_stats")
assert_equal "0" "$unclassified" "no quiz time should land in unclassified"
quiz_minutes=$(jq -r '.by_type.quiz' <<< "$track_stats")
assert_equal "30" "$quiz_minutes" "quiz time should be attributable by workflow type"

# --- The non-writes -------------------------------------------------------
# A quiz must not touch topic scheduling or roadmap status.
if [[ -f "$TEST_ROOT/.spaced-repetition.json" ]]; then
    echo "FAIL: quiz workflow created .spaced-repetition.json" >&2
    exit 1
fi
if [[ -f "$TEST_ROOT/roadmap.json" ]]; then
    echo "FAIL: quiz workflow created roadmap.json" >&2
    exit 1
fi

# --- infer-next quiz arm --------------------------------------------------
# Priority 1 is the topic with the most repeat-missed banked questions.
inferred=$(bash "$TEST_ROOT/.claude/scripts/learning/infer-next.sh" quiz)
assert_equal "topic-b" "$inferred" "quiz inference should prefer the most-missed topic"

# With no weak questions, fall back to the most recently studied topic.
cat > "$TEST_ROOT/.spaced-repetition.json" <<'JSON'
{
  "topics": {
    "topic-a": {"last_reviewed": "2026-07-01", "recall_score": 8, "next_review": "2026-08-01"},
    "topic-c": {"last_reviewed": "2026-07-20", "recall_score": 6, "next_review": "2026-08-05"}
  },
  "metadata": {}
}
JSON
jq '.questions |= map_values(.stats.times_missed = 0)' "$BANK" > "$BANK.tmp" && mv "$BANK.tmp" "$BANK"
inferred=$(bash "$TEST_ROOT/.claude/scripts/learning/infer-next.sh" quiz)
assert_equal "topic-c" "$inferred" "with no weak questions, quiz should fall back to the last studied topic"

rm -f "$TEST_ROOT/.spaced-repetition.json"

echo "PASS: quiz helpers"
