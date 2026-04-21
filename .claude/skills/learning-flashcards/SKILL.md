---
name: learning-flashcards
description: Review flashcards with Anki-style spaced repetition. Supports topic-scoped decks, cloze deletions, and scenario cards. Use "export" argument to generate Anki-importable file.
disable-model-invocation: false
argument-hint: "[topic|export]"
---

# Flashcard Review - Spaced Repetition

Review your flashcard decks with Anki-style spaced repetition (SM-2 algorithm).

**Argument**: $ARGUMENTS

---

## Phase 1: Load State & Deck Selection

!`bash ./.claude/scripts/learning/session-track.sh start learning-flashcards "$ARGUMENTS"`

!`bash ./.claude/scripts/learning/flashcards.sh stats`

### If argument is "export":

Jump to **Phase 6: Anki Export** below.

### If argument is a topic name:

Filter to that topic's deck. Show topic-specific stats.

### If argument is "all" or empty:

Show the by-topic breakdown from stats output. Ask the user:

**Which deck would you like to review?**
1. **All due cards** (across all topics)
2. **[Topic A]** — X cards (Y due)
3. **[Topic B]** — X cards (Y due)
4. Pick a specific topic

Wait for their choice before proceeding.

---

## Phase 2: Review Due Cards

!`bash ./.claude/scripts/learning/flashcards.sh list-due "$TOPIC" 10`

*Review up to 10 cards per session, most overdue first.*

If no cards are due, say so and skip to Phase 4 (Add New Cards).

For each due card, adapt the review flow based on card type:

---

### For `basic` cards:

1. **Show the question** (front only)
2. **Ask the user to answer from memory** — do NOT reveal the answer yet
3. Wait for their response
4. **Reveal the answer** (back)
5. Ask: **How did you do?**
   - **Again** — Complete blackout or wrong
   - **Hard** — Correct but required significant effort
   - **Good** — Correct with moderate effort
   - **Easy** — Instant, effortless recall

---

### For `cloze` cards:

1. **Show the text with blanks** — replace `{{c1::answer}}` patterns with `[___]`
2. **Ask the user to fill in the blank(s)** from memory
3. Wait for their response
4. **Reveal the full text** with answers highlighted
5. Ask: **How did you do?** (Again / Hard / Good / Easy)

---

### For `scenario` cards:

1. **Show the scenario** (front)
2. **Ask the user to reason through their answer**
3. Wait for their response
4. **One Socratic follow-up**: challenge their reasoning
   - "Why that approach over [alternative]?"
   - "What would change if [constraint]?"
   - "What's the trade-off you're accepting?"
5. Wait for their response
6. **Reveal the answer** (back)
7. Ask: **How did you do?** (Again / Hard / Good / Easy)

---

### After each rating:

Map the user's choice to SM-2 quality: Again=0, Hard=3, Good=4, Easy=5

*Execute:*

```bash
bash ./.claude/scripts/learning/flashcards.sh update-sm2 "$CARD_ID" "$QUALITY"
```

Show brief feedback after update:
- **Again**: "This card will come back today. You'll get it."
- **Hard**: "Scheduled for tomorrow. The struggle helps."
- **Good**: "Next review in [N] days."
- **Easy**: "Next review in [N] days. Solid recall."

Then proceed to the next card.

---

## Phase 3: Session Summary

After reviewing all cards (or the batch of 10):

### Session Results

**Cards Reviewed**: [N]
**Average Quality**: [X] ([description])
**Cards Still Due**: [N remaining]

**Struggling Cards** (ease factor < 1.5):
- [Card front snippet] — consider a deeper review via `/learning-weekly-dive "[topic]"`

**Graduating Cards** (interval > 21 days):
- [Card front snippet] — this one is sticking!

---

## Phase 4: Add New Cards (Optional)

**Would you like to add new cards?**
1. Yes — add cards manually
2. No — finish session

If yes:
- Ask for: front, back, type (basic/cloze/scenario), tags, source topic
- For cloze cards, remind user to use `{{c1::answer}}` syntax
- Check for duplicates before saving:

```bash
bash ./.claude/scripts/learning/flashcards.sh search "$FRONT_TEXT"
```

*After confirming no duplicate, save:*

```bash
bash ./.claude/scripts/learning/flashcards.sh add-card '$CARD_JSON'
```

*Where $CARD_JSON is: {"front": "...", "back": "...", "type": "basic|cloze|scenario", "tags": [...], "source_topic": "...", "source_session": "manual"}*

Repeat until the user is done adding cards.

---

## Phase 5: Log Session

```bash
bash ./.claude/scripts/learning/save-state.sh log "$LOG_ENTRY"
```

*Where `$LOG_ENTRY` is a JSON object with: timestamp, type "flashcard-review", topic (or "mixed" if multiple topics), cards_reviewed, average_quality, duration_minutes.*

---

## Phase 6: Anki Export

*Only reached if argument was "export".*

Ask the user which topic to export (or all):

```bash
bash ./.claude/scripts/learning/flashcards.sh export-anki "$TOPIC"
```

Present the output and explain:
- Save as a `.txt` file
- Import into Anki: File > Import > select the `.txt` file
- Set separator to "Tab"
- Cloze cards with `{{c1::}}` syntax will be recognized automatically if the Anki note type is set to "Cloze"

---

## Next Actions

**What would you like to do next?**
1. Review more cards: `/learning-flashcards`
2. Review a specific deck: `/learning-flashcards "[topic]"`
3. Export to Anki: `/learning-flashcards export`
4. Deep dive on a struggling topic: `/learning-weekly-dive "[topic]"`
5. That's enough for today!
