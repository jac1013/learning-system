---
name: learning-quiz
description: Multiple-choice quiz on a topic. Practice mode reveals answers only after you justify your pick; exam mode runs timed and silent until scored. Use "exam" for mock-exam mode.
disable-model-invocation: false
argument-hint: "[topic|exam|exam <topic>]"
context: fork
---

# Quiz - Discrimination Practice

Free recall tests whether you can *produce* an answer. Multiple choice tests whether you can *discriminate* between answers that look alike. They fail differently, so both are needed — you can recite a definition perfectly and still pick the wrong option under a scenario stem.

Because recognition is a weaker encoder than recall, this skill never lets the learner pick and move on. In practice mode they must commit reasoning first, which converts the recognition task back into a generation task. That step is where the retention benefit lives — do not skip it, shorten it, or accept a bare letter.

**Arguments**: $ARGUMENTS

---

## Phase 1: Session Init

!`bash ./.claude/scripts/learning/session-track.sh start learning-quiz "$ARGUMENTS"`

!`bash ./.claude/scripts/learning/quiz.sh session-init "$ARGUMENTS"`

The helper emits `QUIZ_MODE`, `TOPIC`, bank statistics, and `SUGGESTED_COUNT`.

If it returns `TOPIC=none`, stop the workflow after presenting its options. End the timer with `bash ./.claude/scripts/learning/session-track.sh end`. Do not invent questions or log a session.

`QUIZ_MODE=exam` means mock-exam mode — use Phase 4 instead of Phase 3. `TOPIC=all` means a mixed exam drawing across every studied topic.

---

## Phase 2: Assemble the Question Set

Confirm the question count with the learner (`SUGGESTED_COUNT` is the default: 8 practice, 20 exam), then pull from the bank:

```bash
bash ./.claude/scripts/learning/quiz.sh sample "$TOPIC" "$COUNT" --mode=practice
```

Use `--mode=exam` in exam mode — it balances questions across topics instead of letting the best-stocked topic dominate.

If the helper prints a `COVERAGE_WARNING` (the bank holds fewer questions than requested), author the remainder yourself and **deposit them before serving**, so every question has an id that `record` can write against:

```bash
bash ./.claude/scripts/learning/quiz.sh add-questions '$QUESTIONS_JSON'
```

Then re-run `sample` to get the full set with ids.

### Authoring rubric

A bad distractor teaches nothing. A good one is a real confusion the learner might actually hold.

- **Stem is a scenario or a precise question.** Never "Which of the following is true?" — that tests reading, not knowledge.
- **4 options for `single`, 5 for `multi`.** State "Select TWO" / "Select THREE" in the stem itself for multi.
- **Every distractor must be defensible**: a genuinely adjacent concept, a documented common confusion, or a true-but-irrelevant fact. No filler, no joke options, no obviously-wrong lengths.
- **At least half at `application` or `analysis` difficulty.** A pure-`recall` bank makes a useless mock exam.
- **`distractor_rationale` is required for every wrong option.** It is what makes "explain why the others are wrong" cheap and consistent every time the question is re-served.

`$QUESTIONS_JSON` is a JSON array of objects with fields: `stem`, `format` (`single`|`multi`), `options` (array of `{key, text}`), `correct` (array of option keys), `explanation`, `distractor_rationale` (object keyed by wrong option key), `difficulty` (`recall`|`application`|`analysis`), `source_topic`, `source_session` (`"quiz"`), `tags`.

Do not supply `created_at` or `stats` — the script injects those. Duplicate stems within a topic are rejected automatically with `DUPLICATE:` on stderr; that is expected, not an error.

---

## Phase 3: Practice Run

Skip to Phase 4 if `QUIZ_MODE=exam`.

For each question, in order:

**1. Present.** Stem, then the options. State explicitly whether it is single-answer or multi-answer. Do not hint, do not narrow the field, do not react to the question's difficulty.

**2. Collect the answer *and* the reasoning.** The learner must give three things:
   - their pick(s)
   - why their pick is right
   - why at least one other specific option is wrong

Reveal nothing until all three land. If they answer with just a letter, ask for the reasoning before continuing — do not confirm or deny the letter first, since that destroys the retrieval attempt. If they say they don't know, ask for their best guess plus what makes it hard; a committed wrong guess encodes better than a skipped question.

**3. Reveal.** Give the correct answer, the explanation, and the `distractor_rationale` for whatever they picked or named. Then explicitly grade their *reasoning*, not just their letter:
   - Right answer, right reasoning → confirmed knowledge
   - Right answer, wrong or absent reasoning → **counts as a miss** for Phase 6. They got there by elimination or luck, and it will not survive a reworded stem.
   - Wrong answer → name the concept the chosen distractor represents. This is the single most useful sentence in the whole session.

**4. Record.**

```bash
bash ./.claude/scripts/learning/quiz.sh record "$QID" "$CORRECT" "$PICKED"
```

`$CORRECT` is `1` or `0`; `$PICKED` is a comma-separated list of the keys they chose.

---

## Phase 4: Exam Run

Replaces Phase 3 when `QUIZ_MODE=exam`.

**State the contract up front**, before the first question:
- Question count
- Timebox (default: 2 minutes × question count)
- Pass threshold (default **72%**, matching AWS certification convention)
- That there will be no feedback of any kind until submission

**During the exam**, present questions consecutively. Acknowledge each answer with **"Recorded. Next."** and nothing else. No hints, no reactions, no corrections, no reasoning prompts, no tone shifts that signal correctness. Silence is the point — it is what makes the score a real measurement instead of a guided walkthrough.

Support two commands:
- `flag` — mark the current question for review
- `review` — before submitting, revisit flagged questions and allow changes

**On submit**: score first, then pass/fail against the threshold, then a full per-question walkthrough with explanations and distractor rationales. Record each question as in Phase 3 step 4, then:

```bash
bash ./.claude/scripts/learning/quiz.sh record-exam
```

---

## Phase 5: Score & Analysis

Both modes.

**Score** = correct / total. Multi-select is **all-or-nothing** — the certification convention, and it prevents credit for partial understanding of a "select two" item. Report partial correctness in the walkthrough, but do not score it.

Report:

- **Overall**: `[X]/[N]` = `[P]%` (plus pass/fail in exam mode)
- **By difficulty**: recall / application / analysis, each as `correct/total`. A high recall score with a low application score is the signature of memorized-but-not-transferable knowledge, and worth naming out loud.
- **By topic** (exam mode only)
- **Concepts you confused** — for every miss, name the distractor chosen and the concept it represents:
  > You picked *"Attach an internet gateway"* — that's **inbound reachability**, not **egress-only access**. The constraint you dropped was "must not be reachable from the internet."

  This is the highest-value output of the skill. Do not compress it into a table.
- **Repeat offenders**:

```bash
bash ./.claude/scripts/learning/quiz.sh list-weak "$TOPIC"
```

Questions missed twice or more are confirmed confusions, not bad luck. Call them out by name.

---

## Phase 6: Flashcards from Misses

Generate one card per miss — including right-answer-wrong-reasoning misses from Phase 3.

**Build the card from the confusion, not from the question text.** A card that reproduces the stem and options teaches the learner to recognize that specific question. A card built from the confusion teaches the distinction.

- `basic` for `recall` misses
- `scenario` for `application` and `analysis` misses

For each proposed card show **Type**, **Front**, **Back**, **Tags**.

**Options:**
1. Accept all cards
2. Accept with edits (specify which to change)
3. Skip card generation
4. Add your own cards too

*After user confirms, save via:*

```bash
bash ./.claude/scripts/learning/flashcards.sh add-cards '$CARDS_JSON'
```

*Where `$CARDS_JSON` is a JSON array of card objects with fields: front, back, type, tags, source_topic, source_session (`"quiz"`).* Deduplication is handled by `add-cards`.

---

## Phase 7: Save

A quiz result is not a recall score. **Do not call `save-state.sh spaced-rep` or `save-state.sh roadmap` from this skill** — topic scheduling stays owned by the teach-back and recall workflows, so a quiz cannot inflate or deflate a topic's review interval.

One call only:

```bash
bash ./.claude/scripts/learning/save-state.sh log "$LOG_ENTRY"
```

`$LOG_ENTRY` must be a JSON object with:

```json
{
  "type": "quiz",
  "practice_type": "knowledge",
  "topic": "topic-key-or-name-or-all",
  "mode": "practice|exam",
  "questions_total": 8,
  "questions_correct": 6,
  "score": 8,
  "score_percent": 75,
  "passed": true,
  "threshold": 72,
  "timebox_minutes": 40,
  "by_difficulty": {
    "recall": { "correct": 3, "total": 3 },
    "application": { "correct": 2, "total": 3 },
    "analysis": { "correct": 1, "total": 2 }
  },
  "missed": [
    {
      "question_id": "q-1770000000-4821",
      "picked": ["a"],
      "correct": ["b"],
      "concept": "confused inbound reachability with egress-only access"
    }
  ],
  "cards_created": 2
}
```

`score` is the 0-10 integer form of `score_percent`, kept for consistency with every other workflow's score field. `passed`, `threshold`, and `timebox_minutes` are exam-mode only — omit them in practice mode. Omit `duration_minutes` entirely; `save-state.sh` overwrites it with the measured session time and adds the timestamp.

---

## Summary

Present a compact completion summary:

- Topic and mode
- Score, and pass/fail in exam mode
- Strongest and weakest difficulty band
- The one confusion most worth fixing
- Cards created
- Bank size after this session

### Next Actions

1. **Review the confusions** — `/learning-flashcards` to drill the cards just created
2. **Rebuild the weak concept** — `/learning-daily-recall "[topic]"` if misses came from missing knowledge rather than misreading
3. **Go deeper** — `/learning-weekly-dive "[topic]"` if a whole difficulty band collapsed
4. **Re-test** — `/learning-quiz "[topic]"` in 2-3 days; the sampler prioritizes what you missed
5. **Full mock exam** — `/learning-quiz exam` once the bank covers several topics

Recommend the next session based on the score:

- **Below 60%**: the topic needs rebuilding, not re-testing. Weekly dive first.
- **60-71%**: drill the cards, then re-quiz the same topic within 2-3 days.
- **72-89%**: solid. Re-quiz in a week, or move to a mixed exam.
- **90% or above**: this topic is a poor use of quiz time. Add a new topic or raise the difficulty mix.
