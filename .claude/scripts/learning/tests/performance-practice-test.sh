#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_LEARNING_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TEST_ROOT=$(mktemp -d)
trap 'rm -rf "$TEST_ROOT"' EXIT

mkdir -p "$TEST_ROOT/.claude/scripts"
cp -R "$SOURCE_LEARNING_DIR" "$TEST_ROOT/.claude/scripts/learning"

cat > "$TEST_ROOT/roadmap.json" <<'JSON'
{
  "topics": {
    "topic-a": {
      "name": "Topic A",
      "sequence": 1,
      "status": "ready",
      "practice_activities": [
        {
          "type": "performance",
          "scenario": "Perform A",
          "mode": "single-response",
          "timebox_minutes": 20,
          "success_criteria": ["Produce A"],
          "rubric": [{"criterion": "A behavior", "description": "Observable A"}]
        }
      ]
    },
    "topic-b": {
      "name": "Topic B",
      "sequence": 2,
      "status": "ready",
      "practice_activities": [
        {
          "type": "performance",
          "scenario": "Perform B",
          "mode": "live-role-play",
          "timebox_minutes": 30,
          "success_criteria": ["Produce B"],
          "rubric": [{"criterion": "B behavior", "description": "Observable B"}]
        }
      ]
    }
  },
  "metadata": {"last_updated": "2026-07-12"}
}
JSON

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

INFER="$TEST_ROOT/.claude/scripts/learning/infer-next.sh"
DETERMINE="$TEST_ROOT/.claude/scripts/learning/determine-topic.sh"
SAVE="$TEST_ROOT/.claude/scripts/learning/save-state.sh"
TRACK="$TEST_ROOT/.claude/scripts/learning/session-track.sh"

selected=$(bash "$INFER" performance-practice)
assert_equal "topic-a" "$selected" "unpracticed roadmap topics should follow sequence"

cat > "$TEST_ROOT/learning-log.jsonl" <<'JSONL'
{"timestamp":"2026-07-10T10:00:00Z","type":"performance-practice","practice_type":"performance","topic":"topic-a","final_score":8,"duration_minutes":20}
JSONL

selected=$(bash "$INFER" performance-practice)
assert_equal "topic-b" "$selected" "an unpracticed performance topic should come before a successful repeat"

cat >> "$TEST_ROOT/learning-log.jsonl" <<'JSONL'
{"timestamp":"2026-07-11T10:00:00Z","type":"performance-practice","practice_type":"performance","topic":"topic-b","final_score":5,"duration_minutes":30}
JSONL

selected=$(bash "$INFER" performance-practice)
assert_equal "topic-b" "$selected" "a weak performance attempt should be prioritized"

activity_output=$(bash "$DETERMINE" performance-practice topic-a)
if [[ "$activity_output" != *'PERFORMANCE_ACTIVITY_JSON={"type":"performance","scenario":"Perform A"'* ]]; then
    echo "FAIL: roadmap performance activity was not exposed to the skill" >&2
    exit 1
fi

bash "$SAVE" log '{"type":"apply-to-work","topics_applied":["topic-a"],"duration_minutes":10}' >/dev/null
practice_type=$(tail -1 "$TEST_ROOT/learning-log.jsonl" | jq -r '.practice_type')
assert_equal "application" "$practice_type" "save-state should classify legacy skill log entries"

bash "$SAVE" log '{"type":"performance-practice","practice_type":"performance","topic":"topic-a","duration_minutes":5}' >/dev/null
practice_type=$(tail -1 "$TEST_ROOT/learning-log.jsonl" | jq -r '.practice_type')
assert_equal "performance" "$practice_type" "save-state should preserve an explicit valid practice type"

if bash "$SAVE" log '{"type":"performance-practice","practice_type":"typo","topic":"topic-a"}' >/dev/null 2>&1; then
    echo "FAIL: save-state accepted an invalid practice type" >&2
    exit 1
fi

stats=$(bash "$TRACK" stats)
performance_minutes=$(jq -r '.by_practice_type.performance' <<< "$stats")
application_minutes=$(jq -r '.by_practice_type.application' <<< "$stats")
assert_equal "55" "$performance_minutes" "performance time should aggregate by practice type"
assert_equal "10" "$application_minutes" "application time should aggregate by practice type"

echo "PASS: performance practice helpers"
