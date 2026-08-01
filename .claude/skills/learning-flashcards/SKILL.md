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

Build the session queue. This is the only place cards are selected — do not call `list-due` directly, or lapsed cards will never come back around:

```bash
bash ./.claude/scripts/learning/flashcards.sh queue-init "$TOPIC" 10
```

If it reports `NO_CARDS_DUE=1`, say so and skip to Phase 4 (Add New Cards).

### The review loop

Repeat until the queue is empty. **Every iteration is exactly two calls** — pull a card, serve it, record the rating:

```bash
bash ./.claude/scripts/learning/flashcards.sh queue-next
```

Returns the full card plus `attempt` (which pass this is) and `remaining`. `QUEUE_EMPTY=1` means the session is done — go to Phase 3.

It **peeks rather than pops**, so calling it twice returns the same card. The card only leaves the queue when you rate it. That is deliberate: a dropped turn should stall the loop, not silently lose a card.

If `attempt` is greater than 1, this card is a return visit from a lapse. Say so — *"Back to this one — second look."* — and serve it exactly as before. Do not shorten it, hint, or reveal early because they saw it minutes ago; that is the repetition doing its work.

After the learner answers and rates, record it with the single entry point:

```bash
bash ./.claude/scripts/learning/flashcards.sh queue-rate "$CARD_ID" "$QUALITY"
```

Never call `update-sm2` yourself during a queued session — `queue-rate` decides whether the rating counts as measurement or practice, and calling both double-counts the review.

For each card served, adapt the review flow based on card type:

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

Map the user's choice to SM-2 quality: **Again=0, Hard=3, Good=4, Easy=5**, then pass it to `queue-rate` (above). Read the `OUTCOME=` line it returns and report accordingly:

- `OUTCOME=requeued` — the card lapsed and is coming back **this session**, after the number of cards in `REQUEUED_AFTER`. Say it concretely: *"Coming back in 2 cards."* Do not say "tomorrow" — the whole point is that they get another attempt before they leave.
- `OUTCOME=capped` — third strike. *"Leaving this one for tomorrow — it's already scheduled."* Do not keep serving it; that is what the cap is for.
- `OUTCOME=resolved` on attempt 1 — normal pass. Report the new interval: *"Next review in [N] days."*
- `OUTCOME=resolved` on attempt 2+ — they recovered a lapsed card within the session. Say so, and be clear the schedule did **not** move: *"Got it on the second pass. Still due tomorrow — recovering in-session is practice, not proof."*

That last distinction matters and is worth stating plainly if the learner asks: only the **first** attempt at a card each session sets its schedule. Retries build the memory; they don't buy a longer interval. `queue-rate` enforces this — `SM2_APPLIED=0` on the response means the rating was practice.

Then loop back to `queue-next`.

---

## Phase 3: Session Summary

Close the queue. This both reports and clears the session — call it exactly once, at the end:

```bash
bash ./.claude/scripts/learning/flashcards.sh queue-end
```

### Session Results

Build the summary from what it returns:

**Cards Reviewed**: `CARDS_SEEN` (in `TOTAL_REPS` passes — mention the gap only if there were retries)
**Average Quality**: `AVG_FIRST_QUALITY` ([description]) — first attempts only, which is the honest number
**Lapsed**: `LAPSED`, of which `RECOVERED` came back and stuck within the session
**Left for tomorrow**: `CAPPED` (hit the retry cap) + `UNFINISHED` (queue not emptied)

If `RECOVERED` is greater than zero, name it as the win it is — those are cards that would have been forgotten under a plain "see you tomorrow" model.

If `CAPPED` is greater than zero, those cards are the real signal in the session. Three failed attempts in ten minutes is not a scheduling problem, it's a knowledge problem — point at `/learning-weekly-dive "[topic]"` rather than more card review.

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

*Where `$LOG_ENTRY` is a JSON object with: timestamp, type "flashcard-review", practice_type "knowledge", topic (or "mixed" if multiple topics), cards_reviewed (`CARDS_SEEN`), average_quality (`AVG_FIRST_QUALITY`), cards_lapsed (`LAPSED`), cards_recovered (`RECOVERED`), cards_capped (`CAPPED`).*

Omit `duration_minutes` — `save-state.sh log` overwrites it with the measured session time.

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
