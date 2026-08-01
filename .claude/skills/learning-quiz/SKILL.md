---
name: learning-quiz
description: Multiple-choice quiz on a topic. Practice mode reveals the answer right after each pick; exam mode runs timed and silent until scored. Use "exam" for mock-exam mode.
disable-model-invocation: false
argument-hint: "[topic|exam|exam <topic>]"
context: fork
---

# Quiz - Discrimination Practice

Free recall tests whether you can *produce* an answer. Multiple choice tests whether you can *discriminate* between answers that look alike. They fail differently, so both are needed — you can recite a definition perfectly and still pick the wrong option under a scenario stem.

**This runs like a real certification exam.** The learner picks an answer. That is the entire ask — never demand reasoning, a justification, or an explanation of why the other options are wrong. A correct pick is full credit, full stop. The teaching happens on the reveal, where *you* supply the reasoning the learner didn't have to type.

The retention work is carried by the question design (Phase 2) and by what happens to misses (Phase 6), not by interrogating the learner. A quiz that stops to cross-examine every answer stops getting taken.

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

**2. Take the pick. Nothing else.** A letter, or a set of letters for multi-answer. **Never ask why.** No "what made you choose that", no "which one did you rule out", no request to defend the answer. If the learner volunteers reasoning, fine — read it, but do not require it and do not grade it. If they say they don't know, take a guess or a skip and move on.

**3. Reveal immediately.**

   - **Correct** → say so plainly, full credit. Then give the explanation and, in a sentence, what makes the nearest distractor tempting. This is the elaboration that turns a lucky pick into a real one, and it costs the learner nothing. Two to four sentences — this is a quiz, not a lecture.
   - **Wrong** → say plainly that it was wrong. Give the correct answer with its explanation, then the `distractor_rationale` for what they picked, and name the concept that distractor represents. No follow-up questions, no "what do you think went wrong". The miss becomes a flashcard in Phase 6 — that is where it gets worked, not here.

A right answer is scored right. There is no such thing as a right-answer-wrong-reasoning miss in this skill; the learner was never asked for reasoning.

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

**During the exam**, present questions consecutively. Acknowledge each answer with **"Recorded. Next."** and nothing else. No hints, no reactions, no corrections, no tone shifts that signal correctness. Silence is the point — it is what makes the score a real measurement instead of a guided walkthrough. As in practice mode, take the pick and never ask why.

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

Generate one card per wrong answer.

**Build the card from the confusion, not from the question text.** A card that reproduces the stem and options teaches the learner to recognize that specific question. A card built from the confusion teaches the distinction.

- `basic` for `recall` misses
- `scenario` for `application` and `analysis` misses

**Save them directly — do not ask the learner to review or approve the cards.** Review happens when the card comes up for study; asking for sign-off here makes the session tedious and adds nothing the first review won't catch.

```bash
bash ./.claude/scripts/learning/flashcards.sh add-cards '$CARDS_JSON'
```

*Where `$CARDS_JSON` is a JSON array of card objects with fields: front, back, type, tags, source_topic, source_session (`"quiz"`).* Deduplication is handled by `add-cards`.

Then report what was saved as a compact list — type, front, back — so the learner can see the deck grew and flag anything wrong.

---

## Phase 7: Save

A quiz result is not a recall score. **Do not call `save-state.sh spaced-rep`, `save-state.sh roadmap`, or `roadmap-status.sh` from this skill** — topic scheduling and roadmap progress stay owned by the teach-back, recall, and synthesis workflows, so a quiz can neither inflate a topic's review interval nor advance it on the roadmap.

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
