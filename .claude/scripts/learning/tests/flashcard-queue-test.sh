#!/bin/bash
# Tests for the in-session flashcard lapse queue.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_LEARNING_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TEST_ROOT=$(mktemp -d)
trap 'rm -rf "$TEST_ROOT"' EXIT

mkdir -p "$TEST_ROOT/.claude/scripts"
cp -R "$SOURCE_LEARNING_DIR" "$TEST_ROOT/.claude/scripts/learning"

FC="$TEST_ROOT/.claude/scripts/learning/flashcards.sh"
DECK="$TEST_ROOT/.flashcards.json"
SESSION="$TEST_ROOT/.flashcard-session.json"

assert_equal() {
    local expected="$1" actual="$2" message="$3"
    if [[ "$actual" != "$expected" ]]; then
        echo "FAIL: $message" >&2
        echo "  expected: $expected" >&2
        echo "  actual:   $actual" >&2
        exit 1
    fi
}

kv() { grep "^$1=" <<< "$2" | head -1 | cut -d= -f2-; }

# --- No session: every read operation must be a safe no-op ---------------
assert_equal "SESSION=absent" "$(bash "$FC" queue-next)" "queue-next without a session should report absent"
assert_equal "SESSION=absent" "$(bash "$FC" queue-status)" "queue-status without a session should report absent"
assert_equal "SESSION=absent" "$(bash "$FC" queue-end)" "queue-end without a session should report absent"

if bash "$FC" queue-rate "card-x" 4 >/dev/null 2>&1; then
    echo "FAIL: queue-rate without a session should exit non-zero" >&2
    exit 1
fi

# --- Empty deck ----------------------------------------------------------
out=$(bash "$FC" queue-init "" 10)
assert_equal "0" "$(kv QUEUE_SIZE "$out")" "an empty deck should produce an empty queue"
if [[ -f "$SESSION" ]]; then
    echo "FAIL: queue-init wrote a session file with no cards due" >&2
    exit 1
fi

# --- Fixture: four due cards --------------------------------------------
bash "$FC" add-cards '[
  {"front":"Card one","back":"A","type":"basic","tags":[],"source_topic":"topic-a","source_session":"test"},
  {"front":"Card two","back":"B","type":"basic","tags":[],"source_topic":"topic-a","source_session":"test"},
  {"front":"Card three","back":"C","type":"basic","tags":[],"source_topic":"topic-a","source_session":"test"},
  {"front":"Card four","back":"D","type":"basic","tags":[],"source_topic":"topic-b","source_session":"test"}
]' >/dev/null

# Cards are created due tomorrow, and reviewing one pushes it further out.
# Re-arm the whole deck before each fresh queue so every section starts from a
# known 4-cards-due state rather than inheriting the previous section's schedule.
yesterday=$(bash -c "source '$TEST_ROOT/.claude/scripts/learning/load-state.sh'; portable_date_ago 1")
make_all_due() {
    local t
    t=$(mktemp)
    jq --arg d "$yesterday" '.cards |= with_entries(.value.sm2.next_review = $d)' "$DECK" > "$t"
    mv "$t" "$DECK"
}
make_all_due

id_of() { jq -r --arg f "$1" '.cards | to_entries[] | select(.value.front == $f) | .key' "$DECK"; }
C1=$(id_of "Card one"); C2=$(id_of "Card two"); C3=$(id_of "Card three"); C4=$(id_of "Card four")

# --- queue-init ----------------------------------------------------------
out=$(bash "$FC" queue-init "" 10)
assert_equal "4" "$(kv QUEUE_SIZE "$out")" "all four due cards should enter the queue"
assert_equal "3" "$(kv RETRY_CAP "$out")" "the retry cap should be reported at init"
assert_equal "2" "$(kv REQUEUE_GAP "$out")" "the requeue gap should be reported at init"

jq -e . "$SESSION" >/dev/null || { echo "FAIL: session file is not valid JSON" >&2; exit 1; }

# --- Topic scoping -------------------------------------------------------
make_all_due
out=$(bash "$FC" queue-init "topic-b" 10)
assert_equal "1" "$(kv QUEUE_SIZE "$out")" "a topic-scoped queue should only hold that topic's cards"

# Back to the full queue for the rest of the tests.
make_all_due
bash "$FC" queue-init "" 10 >/dev/null
queue_order() { jq -r '.queue | join(",")' "$SESSION"; }
FIRST=$(jq -r '.queue[0]' "$SESSION")

# --- queue-next peeks, it does not pop ----------------------------------
a=$(bash "$FC" queue-next | jq -r '.id')
b=$(bash "$FC" queue-next | jq -r '.id')
assert_equal "$a" "$b" "queue-next must not consume the card — a lost skill turn would silently drop it"
assert_equal "$FIRST" "$a" "queue-next should serve the head of the queue"
assert_equal "1" "$(bash "$FC" queue-next | jq -r '.attempt')" "an unseen card should report attempt 1"
assert_equal "Card one" "$(bash "$FC" queue-next | jq -r '.front')" "queue-next should return the full card, not just an id"

# --- A lapse re-queues behind exactly REQUEUE_GAP cards ------------------
# Done on a FULL queue on purpose. With only `gap` cards left the insert
# degenerates into an append, and an implementation that re-queued at the head
# would pass anyway — that is the whole mechanic going untested.
head="$FIRST"
before=$(jq -r '.queue | join(",")' "$SESSION")
out=$(bash "$FC" queue-rate "$head" 0)
assert_equal "requeued" "$(kv OUTCOME "$out")" "an Again rating should re-queue the card"
assert_equal "1" "$(kv SM2_APPLIED "$out")" "the first Again is still the measurement and must drive SM-2"
assert_equal "2" "$(kv REQUEUED_AFTER "$out")" "a lapsed card should return after exactly 2 other cards"
assert_equal "4" "$(kv QUEUE_REMAINING "$out")" "a re-queued card stays in the session — the queue does not shrink"
assert_equal "2" "$(jq -r --arg id "$head" '.queue | index($id)' "$SESSION")" "the lapsed card should sit at index 2, not back at the head"

# Spelled out, because index arithmetic is where an off-by-one hides:
# [C1,C2,C3,C4] with C1 lapsing must become [C2,C3,C1,C4].
expected="$(cut -d, -f2,3 <<< "$before"),$head,$(cut -d, -f4 <<< "$before")"
assert_equal "$expected" "$(jq -r '.queue | join(",")' "$SESSION")" "the lapsed card should be spliced in, leaving the rest of the order intact"

# The lapse must have reset the schedule to tomorrow via SM-2.
assert_equal "1" "$(jq -r --arg id "$head" '.cards[$id].sm2.interval' "$DECK")" "an Again should reset the SM-2 interval to 1"

# --- A pass resolves and removes ----------------------------------------
nxt=$(bash "$FC" queue-next | jq -r '.id')
out=$(bash "$FC" queue-rate "$nxt" 4)
assert_equal "resolved" "$(kv OUTCOME "$out")" "a passing rating should resolve the card"
assert_equal "1" "$(kv SM2_APPLIED "$out")" "the first rating of a card must drive SM-2"
assert_equal "3" "$(kv QUEUE_REMAINING "$out")" "a resolved card should leave the queue"

# --- Retries are practice: they must not rewrite the schedule ------------
ease_before=$(jq -r --arg id "$head" '.cards[$id].sm2.ease_factor' "$DECK")
reps_before=$(jq -r --arg id "$head" '.cards[$id].sm2.repetitions' "$DECK")
next_before=$(jq -r --arg id "$head" '.cards[$id].sm2.next_review' "$DECK")

# Clear the one remaining intervening card, then the lapsed card comes back up.
bash "$FC" queue-rate "$(bash "$FC" queue-next | jq -r '.id')" 4 >/dev/null

again=$(bash "$FC" queue-next)
assert_equal "$head" "$(jq -r '.id' <<< "$again")" "the lapsed card should come back around"
assert_equal "2" "$(jq -r '.attempt' <<< "$again")" "the returning card should report attempt 2"

out=$(bash "$FC" queue-rate "$head" 5)
assert_equal "0" "$(kv SM2_APPLIED "$out")" "a retry must NOT drive SM-2 — passing on retry would schedule it out as if recalled cleanly"
assert_equal "resolved" "$(kv OUTCOME "$out")" "a retry that passes should resolve the card"

assert_equal "$ease_before" "$(jq -r --arg id "$head" '.cards[$id].sm2.ease_factor' "$DECK")" "a retry must not change the ease factor"
assert_equal "$reps_before" "$(jq -r --arg id "$head" '.cards[$id].sm2.repetitions' "$DECK")" "a retry must not change the repetition count"
assert_equal "$next_before" "$(jq -r --arg id "$head" '.cards[$id].sm2.next_review' "$DECK")" "a retry must not push the next review out"

# --- The retry cap stops one card eating the session ---------------------
make_all_due
bash "$FC" queue-init "" 10 >/dev/null
target=$(bash "$FC" queue-next | jq -r '.id')

out=$(bash "$FC" queue-rate "$target" 0)
assert_equal "requeued" "$(kv OUTCOME "$out")" "attempt 1 should re-queue"
assert_equal "1/3" "$(kv ATTEMPT "$out")" "the attempt counter should be reported against the cap"

out=$(bash "$FC" queue-rate "$target" 0)
assert_equal "requeued" "$(kv OUTCOME "$out")" "attempt 2 should still re-queue"

out=$(bash "$FC" queue-rate "$target" 0)
assert_equal "capped" "$(kv OUTCOME "$out")" "attempt 3 should hit the cap"
assert_equal "3" "$(kv CAP_REACHED "$out")" "the cap should be reported when reached"
if grep -q "^REQUEUED_AFTER=" <<< "$out"; then
    echo "FAIL: a capped card was re-queued anyway" >&2
    exit 1
fi
if jq -e --arg id "$target" '.queue | index($id)' "$SESSION" >/dev/null 2>&1; then
    echo "FAIL: a capped card is still in the queue and will loop forever" >&2
    exit 1
fi

# --- Short queue: a lapse with fewer than GAP cards left goes to the end --
make_all_due
bash "$FC" queue-init "topic-b" 10 >/dev/null
lone=$(bash "$FC" queue-next | jq -r '.id')
out=$(bash "$FC" queue-rate "$lone" 0)
assert_equal "requeued" "$(kv OUTCOME "$out")" "a lone card should still re-queue"
assert_equal "0" "$(kv REQUEUED_AFTER "$out")" "with nothing else left, the card returns immediately"
assert_equal "1" "$(kv QUEUE_REMAINING "$out")" "the lone card should still be in the queue"

# --- Validation ----------------------------------------------------------
make_all_due
bash "$FC" queue-init "" 10 >/dev/null
if bash "$FC" queue-rate "card-does-not-exist" 4 >/dev/null 2>&1; then
    echo "FAIL: queue-rate accepted an unknown card id" >&2
    exit 1
fi
if jq -e '.cards["card-does-not-exist"]' "$DECK" >/dev/null 2>&1; then
    echo "FAIL: a bad card id created a junk subtree in the deck" >&2
    exit 1
fi
if bash "$FC" queue-rate "$C1" 9 >/dev/null 2>&1; then
    echo "FAIL: queue-rate accepted an out-of-range quality" >&2
    exit 1
fi
if bash "$FC" queue-rate "$C1" "good" >/dev/null 2>&1; then
    echo "FAIL: queue-rate accepted a non-numeric quality" >&2
    exit 1
fi

# --- Session summary and teardown ---------------------------------------
make_all_due
bash "$FC" queue-init "" 10 >/dev/null
x=$(bash "$FC" queue-next | jq -r '.id')
bash "$FC" queue-rate "$x" 0 >/dev/null   # lapse...
bash "$FC" queue-rate "$x" 4 >/dev/null   # ...then recover
y=$(bash "$FC" queue-next | jq -r '.id')
bash "$FC" queue-rate "$y" 4 >/dev/null

status=$(bash "$FC" queue-status)
assert_equal "2" "$(kv CARDS_SEEN "$status")" "status should count distinct cards seen, not reps"
assert_equal "3" "$(kv TOTAL_REPS "$status")" "status should count reps including retries"
assert_equal "1" "$(kv LAPSED "$status")" "status should count the lapsed card"

out=$(bash "$FC" queue-end)
assert_equal "1" "$(kv RECOVERED "$out")" "a card lapsed then passed in-session counts as recovered"
assert_equal "2" "$(kv UNFINISHED "$out")" "cards never reached should be reported as unfinished"

if [[ -f "$SESSION" ]]; then
    echo "FAIL: queue-end did not clear the session file" >&2
    exit 1
fi
assert_equal "SESSION=absent" "$(bash "$FC" queue-end)" "queue-end should be safe to call twice"

# --- The queue must not touch unrelated state ----------------------------
for f in .spaced-repetition.json roadmap.json .quiz-bank.json; do
    if [[ -f "$TEST_ROOT/$f" ]]; then
        echo "FAIL: the flashcard queue created $f" >&2
        exit 1
    fi
done
jq -e . "$DECK" >/dev/null || { echo "FAIL: deck is no longer valid JSON" >&2; exit 1; }

echo "PASS: flashcard lapse queue"
