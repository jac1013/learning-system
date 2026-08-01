#!/bin/bash
# Tests for automatic roadmap status transitions.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_LEARNING_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TEST_ROOT=$(mktemp -d)
trap 'rm -rf "$TEST_ROOT"' EXIT

mkdir -p "$TEST_ROOT/.claude/scripts"
cp -R "$SOURCE_LEARNING_DIR" "$TEST_ROOT/.claude/scripts/learning"

RS="$TEST_ROOT/.claude/scripts/learning/roadmap-status.sh"
ROADMAP="$TEST_ROOT/roadmap.json"

assert_equal() {
    local expected="$1" actual="$2" message="$3"
    if [[ "$actual" != "$expected" ]]; then
        echo "FAIL: $message" >&2
        echo "  expected: $expected" >&2
        echo "  actual:   $actual" >&2
        exit 1
    fi
}

status_of() { jq -r --arg t "$1" '.topics[$t].status' "$ROADMAP"; }

# --- No roadmap: every operation must be a silent no-op ------------------
bash "$RS" enter topic-a >/dev/null
bash "$RS" resolve topic-a 9 0 >/dev/null
bash "$RS" unlock >/dev/null
assert_equal "ROADMAP=absent" "$(bash "$RS" status)" "status should report an absent roadmap"
if [[ -f "$ROADMAP" ]]; then
    echo "FAIL: operations created a roadmap where none existed" >&2
    exit 1
fi

# --- Fixture: explicit prerequisites -------------------------------------
cat > "$ROADMAP" <<'JSON'
{
  "topics": {
    "topic-a": {"name": "A", "phase": 1, "sequence": 1, "status": "ready",   "prerequisites": []},
    "topic-b": {"name": "B", "phase": 1, "sequence": 2, "status": "blocked", "prerequisites": ["topic-a"]},
    "topic-c": {"name": "C", "phase": 2, "sequence": 3, "status": "blocked", "prerequisites": ["topic-a", "topic-b"]}
  },
  "metadata": {"last_updated": "2026-07-01"}
}
JSON

# --- enter marks in-progress, does not complete anything -----------------
out=$(bash "$RS" enter topic-a)
assert_equal "in-progress" "$(status_of topic-a)" "entering a topic should mark it in-progress"
assert_equal "blocked" "$(status_of topic-b)" "entering a topic must not unlock its dependents"
if grep -q "COMPLETED=" <<< "$out"; then
    echo "FAIL: first exposure to a topic reported a completion" >&2
    exit 1
fi

started=$(jq -r '.topics["topic-a"].started_at' "$ROADMAP")
if [[ "$started" == "null" ]]; then
    echo "FAIL: enter did not stamp started_at" >&2
    exit 1
fi

# --- resolve with open gaps must NOT complete ---------------------------
# This is the reported bug: a topic was completed on first exposure while
# work remained outstanding.
out=$(bash "$RS" resolve topic-a 9 2)
assert_equal "in-progress" "$(status_of topic-a)" "a high score with open gaps must not complete a topic"
if grep -q "TOPIC_STATUS=completed" <<< "$out"; then
    echo "FAIL: resolve completed a topic that still had open gaps" >&2
    exit 1
fi

out=$(bash "$RS" resolve topic-a 5 0)
assert_equal "in-progress" "$(status_of topic-a)" "a low score must not complete a topic even with no gaps"

# --- Moving on to a new topic completes the previous one ----------------
out=$(bash "$RS" enter topic-b)
assert_equal "completed" "$(status_of topic-a)" "moving on should complete the previously in-progress topic"
assert_equal "moved-on" "$(jq -r '.topics["topic-a"].completion_reason' "$ROADMAP")" "the completion reason should record why"
if ! grep -q "COMPLETED=topic-a" <<< "$out"; then
    echo "FAIL: enter did not report the auto-completion" >&2
    exit 1
fi

# --- Completion unlocks dependents ---------------------------------------
assert_equal "in-progress" "$(status_of topic-b)" "the newly entered topic should be in-progress"
assert_equal "blocked" "$(status_of topic-c)" "topic-c needs BOTH prerequisites before unlocking"

out=$(bash "$RS" resolve topic-b 9 0)
assert_equal "completed" "$(status_of topic-b)" "a clean score with no gaps should complete the topic"
assert_equal "met-bar" "$(jq -r '.topics["topic-b"].completion_reason' "$ROADMAP")" "an earned completion should be labelled met-bar"
assert_equal "ready" "$(status_of topic-c)" "topic-c should unlock once all prerequisites are done"
if ! grep -q "UNLOCKED=topic-c" <<< "$out"; then
    echo "FAIL: unlock was not reported to the caller" >&2
    exit 1
fi

# --- Revisiting a completed topic must not demote it --------------------
out=$(bash "$RS" enter topic-a)
assert_equal "completed" "$(status_of topic-a)" "revisiting a completed topic must not demote it to in-progress"

# --- master --------------------------------------------------------------
bash "$RS" master topic-a >/dev/null
assert_equal "mastered" "$(status_of topic-a)" "master should set the mastered status"
bash "$RS" enter topic-c >/dev/null
assert_equal "mastered" "$(status_of topic-a)" "a mastered topic must never be downgraded to completed"

# --- Untracked topics are reported, not created --------------------------
out=$(bash "$RS" enter "some-ad-hoc-topic")
assert_equal "TOPIC_STATUS=untracked" "$(grep 'TOPIC_STATUS' <<< "$out")" "an off-roadmap topic should report untracked"
assert_equal "3" "$(jq -r '.topics | length' "$ROADMAP")" "an off-roadmap topic must not be added to the roadmap"

# --- Topics given by display name resolve to their key -------------------
# infer-next.sh returns keys, but a hand-typed topic is the display name.
# Without resolution every manual `/learning-weekly-dive "Some Topic"` would
# report untracked and silently skip its status transition.
cat > "$ROADMAP" <<'JSON'
{
  "topics": {
    "topic-x": {"name": "Circuit Breaker Pattern", "sequence": 1, "status": "ready", "prerequisites": []},
    "topic-y": {"name": "Bulkhead Isolation",      "sequence": 2, "status": "ready", "prerequisites": []}
  },
  "metadata": {}
}
JSON

bash "$RS" enter "Circuit Breaker Pattern" >/dev/null
assert_equal "in-progress" "$(status_of topic-x)" "a topic named by its display name should resolve to its key"

out=$(bash "$RS" enter "bulkhead isolation")
assert_equal "in-progress" "$(status_of topic-y)" "display-name matching should be case-insensitive"
assert_equal "completed" "$(status_of topic-x)" "moving on by display name should still complete the previous topic"
if ! grep -q "COMPLETED=topic-x" <<< "$out"; then
    echo "FAIL: the auto-completion should be reported by roadmap key, not display name" >&2
    exit 1
fi

bash "$RS" resolve "Bulkhead Isolation" 9 0 >/dev/null
assert_equal "completed" "$(status_of topic-y)" "resolve should accept a display name too"

bash "$RS" master "circuit breaker pattern" >/dev/null
assert_equal "mastered" "$(status_of topic-x)" "master should accept a display name too"

assert_equal "TOPIC_STATUS=mastered" "$(bash "$RS" status "Circuit Breaker Pattern" | grep TOPIC_STATUS)" "status should accept a display name too"

# --- Sequential fallback for roadmaps with empty prerequisites -----------
# Roadmaps generated with `prerequisites: []` on blocked topics would
# otherwise stay blocked forever, since `all` over an empty array is true
# and would unlock everything at once.
cat > "$ROADMAP" <<'JSON'
{
  "topics": {
    "topic-1": {"name": "1", "sequence": 1, "status": "ready",   "prerequisites": []},
    "topic-2": {"name": "2", "sequence": 2, "status": "blocked", "prerequisites": []},
    "topic-3": {"name": "3", "sequence": 3, "status": "blocked", "prerequisites": []}
  },
  "metadata": {}
}
JSON

bash "$RS" unlock >/dev/null
assert_equal "blocked" "$(status_of topic-2)" "a blocked topic must not unlock while an earlier topic is unfinished"
assert_equal "blocked" "$(status_of topic-3)" "unlocking must not cascade past the next topic"

bash "$RS" enter topic-1 >/dev/null
bash "$RS" resolve topic-1 8 0 >/dev/null
assert_equal "ready" "$(status_of topic-2)" "the next sequential topic should unlock after its predecessor completes"
assert_equal "blocked" "$(status_of topic-3)" "only the next topic should unlock, not the whole roadmap"

# --- Input validation ----------------------------------------------------
if bash "$RS" resolve topic-2 "high" 0 >/dev/null 2>&1; then
    echo "FAIL: resolve accepted a non-numeric score" >&2
    exit 1
fi
if bash "$RS" resolve topic-2 8 "several" >/dev/null 2>&1; then
    echo "FAIL: resolve accepted a non-numeric gap count" >&2
    exit 1
fi
if bash "$RS" bogus-op >/dev/null 2>&1; then
    echo "FAIL: an unknown operation should exit non-zero" >&2
    exit 1
fi

jq -e . "$ROADMAP" >/dev/null || { echo "FAIL: roadmap is no longer valid JSON" >&2; exit 1; }

# --- Aggregate status ----------------------------------------------------
summary=$(bash "$RS" status)
assert_equal "ROADMAP_TOTAL=3" "$(grep ROADMAP_TOTAL <<< "$summary")" "status should count all topics"
assert_equal "ROADMAP_COMPLETED=1" "$(grep ROADMAP_COMPLETED <<< "$summary")" "status should count completed topics"

echo "PASS: roadmap status transitions"
