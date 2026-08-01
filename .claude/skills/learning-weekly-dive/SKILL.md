---
name: learning-weekly-dive
description: 30-60 minute deep dive using Socratic questioning and teach-back. System suggests next roadmap topic or specify your own. Builds deep understanding through challenge.
disable-model-invocation: false
argument-hint: "[optional-topic]"
context: fork
---

# Weekly Dive - Deep Socratic Learning

Deep exploration session (30-60 minutes) using Socratic method and teach-back.

**Topic**: $ARGUMENTS

---

## Phase 1: Determine Topic

!`bash ./.claude/scripts/learning/session-track.sh start learning-weekly-dive "$ARGUMENTS"`

!`bash ./.claude/scripts/learning/determine-topic.sh weekly-dive "$ARGUMENTS"`

Once the topic is settled, mark it started. **Do not ask permission for this** — roadmap status is framework-managed, not a decision the learner makes:

```bash
bash ./.claude/scripts/learning/roadmap-status.sh enter "$TOPIC"
```

Report any `COMPLETED=` or `UNLOCKED=` lines it prints in one sentence, then move on. A `COMPLETED=` line means the learner moved on from a topic they had left in progress; an `UNLOCKED=` line means a previously blocked topic just became available.

---

## Phase 2: Prior Knowledge Check

Before diving in, ask the user:

**"What do you already know about [topic]? Even rough impressions count — give me your best current understanding."**

Wait for their response. Then assess:

- **If they demonstrate solid prior knowledge** → proceed to Socratic Interrogation (Phase 3)
- **If they have partial/fragmented knowledge** → briefly note what they got right, then proceed to Initial Instruction (Phase 2b) to fill foundational gaps before Socratic work
- **If they know little or nothing** → say so honestly and proceed to Initial Instruction (Phase 2b) first

---

## Phase 2b: Initial Instruction (only if needed — skip if prior knowledge is solid)

Teach the topic clearly and concisely. Cover:

1. **What it is** — one-sentence definition, then expand
2. **Why it exists** — the problem it solves
3. **Core components/pillars** — the main building blocks
4. **How it's used in practice** — concrete examples or scenarios
5. **Key trade-offs or gotchas** — what trips people up

Keep it to the essential concepts needed to engage with Socratic questioning. Don't dump everything — leave room for discovery.

After teaching, ask: **"Does that make sense so far? Any questions before we go deeper?"**

---

## Phase 3: Socratic Interrogation (15-20 min)

### Teach Me Back: [Topic Name]

Now that you have a foundation, let's test and deepen it. Explain [topic] back to me in your own words.

**Your task**: Explain [topic] as if teaching someone new to it. Use your own words — not mine.

---

### Socratic Ladder (I'll challenge you)

After your explanation, probe deeper:

**Level 1 - Surface**: "Why does it work that way?"

**Level 2 - Mechanism**: "What's the alternative approach?"

**Level 3 - Trade-offs**: "When would you choose one over the other?"

**Level 4 - Boundaries**: "When would you NOT use this?"

**Level 5 - Integration**: "How does this relate to [related concept]?"

---

### Challenge Assumptions

As they explain, challenge with:
- "Are you sure it's ONLY for [reason]?"
- "What if [edge case]?"
- "Could there be another explanation?"
- "What are you assuming that might not be true?"

---

## Phase 4: Gap Identification & Targeted Learning (15-25 min)

### 🔍 Socratic Assessment Complete

Based on your teaching, I've identified:

**Strong Understanding** (you explained well):
- [Aspect 1]: Clear explanation with examples
- [Aspect 2]: Identified trade-offs accurately

**Gaps to Fill** (areas needing more depth):
1. **[Gap 1]** (Priority: High)
   - What's missing: [Specific concept/detail]
   - Why it matters: [Importance]
   - Where to learn: [Specific resource/section]

2. **[Gap 2]** (Priority: Medium)
   - What's missing: [Description]
   - Where to learn: [Resource]

---

### Targeted Study (Fill the Gaps)

For each high-priority gap:

**Read/Study**: [Specific section of documentation/article]

After reading, apply the new knowledge:
- **Summarize** in your own words
- **Give examples** (code/scenarios)
- **Contrast** with what you thought before
- **Predict** when you'd use it

---

## Phase 5: Teach-Back Verification (10-15 min)

### 🎯 Teach-Back Challenge

Now teach me [topic] again, incorporating what you just learned.

**Important**: Do this WITHOUT looking at notes or references!

I'm a [junior developer / new learner / mid-level engineer - adjust based on profile].

**I'll ask clarifying questions**:
- "I don't understand [aspect]. Can you explain differently?"
- "Why do we need [component]? Can't we just [naive alternative]?"
- "When would I use this in real work?"
- "How is this different from [similar concept]?"

---

### Teach-Back Evaluation

**Scoring (0-10 on each dimension)**:

**Clarity** (Can a beginner understand?):
- 10: Could teach complete beginner
- 7-8: Mostly clear
- 5-6: Requires prior knowledge
- 0-4: Hard to follow

**Accuracy** (Is it correct?):
- 10: Completely correct
- 7-8: Mostly correct, minor inaccuracies
- 5-6: Some errors
- 0-4: Many errors

**Depth** (Do you explain "why"?):
- 10: Explains why, trade-offs, alternatives
- 7-8: Explains some reasoning
- 5-6: Mostly "what" not "why"
- 0-4: Surface-level only

**Completeness** (Do you cover key aspects?):
- 10: Covers all major components
- 7-8: Minor omissions
- 5-6: Missing important aspects
- 0-4: Major gaps

**Overall Score**: Average of 4 dimensions

---

## Phase 5b: Module Quiz (5-10 min)

**This phase is required. Run it every time — do not offer to skip it, and do not ask whether the learner wants it.** Announce it and start. Teach-back tests whether you can *produce* an explanation; this tests whether you can *discriminate* between answers that look alike, which is a different failure mode and the one that shows up on real exams and in real decisions.

Author **5 questions on what this session actually covered** — especially the gaps identified in Phase 4, since those are where confusions are known to exist. Follow the authoring rubric in `.claude/skills/learning-quiz/SKILL.md` (Phase 2): scenario stems, defensible distractors, at least half at `application` or `analysis` difficulty, `distractor_rationale` required for every wrong option.

Deposit them before serving, so each has an id to record against:

```bash
bash ./.claude/scripts/learning/quiz.sh add-questions '$QUESTIONS_JSON'
```

Use `source_session: "weekly-dive"`. Over a 12-week roadmap this is what grows the bank into something `/learning-quiz exam` can actually draw on.

**Run them exam-style.** Present the stem and options, state single- or multi-answer, and take the learner's pick. Ask for nothing else — no reasoning, no justification, no "why did you pick that". Then:

- **Correct** → say so, full credit, and add one or two sentences on *why* it is right and what makes the nearest distractor tempting. Keep it short.
- **Wrong** → say plainly that it was wrong, give the correct answer with its explanation, and give the `distractor_rationale` for what they picked. No interrogation. The miss becomes a card in the next phase.

Record each answer:

```bash
bash ./.claude/scripts/learning/quiz.sh record "$QID" "$CORRECT" "$PICKED"
```

**Do not write a separate score.** The quiz result is evidence for the **Accuracy** dimension of the teach-back rubric above — a learner who explained clearly but missed 3 of 5 discrimination items did not score 9 on Accuracy. Adjust that dimension before Phase 6 and say why.

Carry every miss forward into the next phase as a card.

---

## Phase 5c: Flashcard Generation

Based on this session, generate flashcards for the key facts from [topic].

**Include one card per quiz miss from Phase 5b**, built from the *confusion* (the concept the chosen distractor represents), not from the question text. A card that reproduces the stem teaches recognition of that one question; a card built from the confusion teaches the distinction.

**Only generate cards for concrete, testable knowledge — not vague concepts.**

Generate 3-8 cards based on session content, mixing types:
- **basic** cards for definitions, lists, numbers, acronyms discovered during the session
- **cloze** cards using `{{c1::answer}}` syntax for key terms and definitions
- **scenario** cards based on Socratic questions where the user struggled

**Save them directly — do not ask the learner to review or approve the cards.** Review happens when the card comes up for study; asking for sign-off here makes the session tedious and adds nothing the first review won't catch.

```bash
bash ./.claude/scripts/learning/flashcards.sh add-cards '$CARDS_JSON'
```

*Where $CARDS_JSON is a JSON array of card objects with fields: front, back, type, tags, source_topic, source_session ("weekly-dive").*

Then report what was saved in a compact list — type, front, back — so the learner knows what is now in the deck and can say if something is wrong. Mention that `/learning-flashcards` is where they'll see them again.

---

## Phase 6: Document & Schedule (5 min)

### 📊 Teach-Back Results

**Overall Score**: [X/10] - [Mastery/Strong/Good/Moderate/Weak]

**Dimensional Scores**:
- Clarity: [X/10] - [Comment]
- Accuracy: [X/10] - [Comment]
- Depth: [X/10] - [Comment]
- Completeness: [X/10] - [Comment]

**What You Explained Well**:
- [Specific strength with example]
- [Another strength]

**What to Improve**:
1. **[Dimension]**: [Specific issue]
   - Example: [From their teaching]
   - Better: [How to improve]

2. **[Dimension]**: [Issue]
   ...

---

### Save Results

*Calculate overall score as average of the 4 dimension scores, then execute:*

```bash
bash ./.claude/scripts/learning/save-state.sh spaced-rep "$TOPIC" "$OVERALL_SCORE" "Teach-back: C:$CLARITY A:$ACCURACY D:$DEPTH Cm:$COMPLETENESS"
```

*Then resolve the roadmap status. `$OPEN_GAP_COUNT` is the number of Phase 4 gaps still unresolved at the end of the session — count them honestly, including any the learner acknowledged but did not close.*

```bash
bash ./.claude/scripts/learning/roadmap-status.sh resolve "$TOPIC" "$OVERALL_SCORE" "$OPEN_GAP_COUNT"
```

**Do not ask the learner to confirm the status change, and do not mark a topic completed yourself.** The script decides: a topic completes only when it was earned (score ≥ 7 with zero open gaps). Otherwise it stays `in-progress` and completes automatically the next time the learner starts a different topic — moving on is the signal that a topic is done. Report the `TOPIC_STATUS=` and `REASON=` lines in one sentence, plus any `UNLOCKED=` line.

```bash
bash ./.claude/scripts/learning/save-state.sh log "$LOG_ENTRY"
```

*Where `$LOG_ENTRY` is a JSON object with: timestamp, type "weekly-dive", practice_type "knowledge", topic, overall_score, scores (clarity/accuracy/depth/completeness), duration_minutes, strengths array, gaps array, next_review date.*

*Include a `quiz` sub-object from Phase 5b — `{"questions_total": 5, "questions_correct": 3, "score_percent": 60}`. Phase 5b always runs, so this is always present.*

---

## Summary

### ✅ Weekly Dive Complete

**Topic**: [topic name]
**Duration**: [X minutes]
**Teach-Back Score**: [X/10]

**Key Insights Gained**:
- [Insight 1 - connection or realization]
- [Insight 2]

**Strong Areas**:
- [What you mastered]

**Still Unclear**:
- [What needs more work]

**Next Actions**:
- **Next Review**: [next review date from save-state output] ([N] days)
- **Recommended**: [Specific next step based on score]

---

### Recommended Follow-Up

**If score < 6**:
📚 Schedule another weekly dive: `/learning-weekly-dive "[topic]"`
Consider breaking into smaller sub-topics

**If score 7-8**:
✅ Good understanding! Reinforce with:
- Daily recall in a few days
- Application opportunity when available

**If score 9-10**:
🎉 Excellent mastery! Next steps:
- Apply to real work: `/learning-apply-to-work`
- Move to next topic: `/learning-weekly-dive`
- Consider monthly synthesis when ready

---

**What would you like to do next?**
1. Next topic: `/learning-weekly-dive`
2. Apply this: `/learning-apply-to-work`
3. That's enough for today!
