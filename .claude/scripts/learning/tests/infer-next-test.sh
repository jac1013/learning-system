#!/bin/bash
# Regression guard for infer-next.sh topic selectors.
#
# Both call sites that rank by recency once used `sort_by(-.value.last_reviewed)`.
# jq cannot negate a string, so those expressions raised
#   "string (\"2026-07-01\") cannot be negated"
# which the surrounding `2>/dev/null` swallowed. get_recent_topics therefore
# always returned empty, and it is the only topic source for apply-to-work.
# These tests fail loudly if that pattern comes back.

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

INFER="$TEST_ROOT/.claude/scripts/learning/infer-next.sh"

TODAY=$(date +%Y-%m-%d)
RECENT=$(date -d "-3 days" +%Y-%m-%d 2>/dev/null || date -v-3d +%Y-%m-%d)
STALE=$(date -d "-40 days" +%Y-%m-%d 2>/dev/null || date -v-40d +%Y-%m-%d)
FUTURE=$(date -d "+60 days" +%Y-%m-%d 2>/dev/null || date -v+60d +%Y-%m-%d)

cat > "$TEST_ROOT/.spaced-repetition.json" <<JSON
{
  "topics": {
    "topic-older":  {"last_reviewed": "$RECENT", "recall_score": 9, "next_review": "$FUTURE"},
    "topic-newest": {"last_reviewed": "$TODAY",  "recall_score": 8, "next_review": "$FUTURE"},
    "topic-stale":  {"last_reviewed": "$STALE",  "recall_score": 9, "next_review": "$FUTURE"},
    "topic-weak":   {"last_reviewed": "$TODAY",  "recall_score": 4, "next_review": "$FUTURE"}
  },
  "metadata": {}
}
JSON

# --- get_recent_topics, via apply-to-work --------------------------------
applicable=$(bash "$INFER" apply-to-work)

if [[ "$applicable" == "none" ]]; then
    echo "FAIL: apply-to-work returned 'none' despite recent high-scoring topics" >&2
    echo "  (this is the symptom of the sort_by(-string) regression)" >&2
    exit 1
fi

assert_equal "topic-newest" "$(head -1 <<< "$applicable")" \
    "apply-to-work should rank the most recently reviewed topic first"

count=$(wc -l <<< "$applicable" | tr -d ' ')
assert_equal "2" "$count" \
    "apply-to-work should return only topics reviewed within 14 days and scoring >= 7"

if grep -q "topic-stale" <<< "$applicable"; then
    echo "FAIL: apply-to-work included a topic outside the 14-day window" >&2
    exit 1
fi
if grep -q "topic-weak" <<< "$applicable"; then
    echo "FAIL: apply-to-work included a topic scoring below 7" >&2
    exit 1
fi

# --- get_related_roadmap_topic same-phase preference ----------------------
# Reached only when nothing is overdue and nothing is recent, so the fixture
# below deliberately has neither.
cat > "$TEST_ROOT/.spaced-repetition.json" <<JSON
{
  "topics": {
    "topic-1-1": {"last_reviewed": "$STALE", "recall_score": 4, "next_review": "$FUTURE"},
    "topic-3-1": {"last_reviewed": "$RECENT", "recall_score": 4, "next_review": "$FUTURE"}
  },
  "metadata": {}
}
JSON

cat > "$TEST_ROOT/roadmap.json" <<'JSON'
{
  "topics": {
    "topic-2-1": {"name": "Phase 2 topic", "sequence": 1, "status": "ready"},
    "topic-3-2": {"name": "Phase 3 topic", "sequence": 5, "status": "ready"}
  },
  "metadata": {}
}
JSON

selected=$(bash "$INFER" daily-recall)
assert_equal "topic-3-2" "$selected" \
    "daily-recall should prefer a ready topic in the same phase as the most recent study, not the lowest sequence"

echo "PASS: infer-next selectors"
