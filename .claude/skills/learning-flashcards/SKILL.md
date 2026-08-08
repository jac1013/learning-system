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

Set `$TOPIC` to it and go straight to Phase 2. Show topic-specific stats.

### If argument is "all" or empty:

Leave `$TOPIC` empty and go straight to Phase 2 with everything that's due. Do **not** offer a deck menu — the learner typed `/learning-flashcards` because they want cards, and a menu is a turn spent not reviewing. One line of context is enough:

> 8 due across `[topic-a]` (5) and `[topic-b]` (3). Starting now — say a topic name any time to narrow it.

---

## Phase 2: Review Due Cards

Build the session queue. This is the only place cards are selected — do not call `list-due` directly, or lapsed cards will never come back around:

```bash
bash ./.claude/scripts/learning/flashcards.sh queue-init "$TOPIC" 10
```

If it reports `NO_CARDS_DUE=1`, say so and skip to Phase 4 (Add New Cards).

---

### Pace: one card, one exchange

A card should cost the learner a single message. They read the front, they answer, and the next card is already in front of them. Anything you put between those two points is overhead they pay for on every card in the deck, and it is the reason a 10-card session turns into twenty minutes.

During the loop:

- **Never ask "How did you do?"** You assign the rating from their answer — see *Grading*, below. Their answer already contains the evidence; asking makes them re-report what you just read.
- **Never ask a clarifying question.** Not on scenario cards, not when an answer is ambiguous, not when you want to know where their reasoning came from. If an answer is genuinely unreadable, grade it *Again*, show the back, move on — the card comes back on its own.
- **Never ask permission to continue.** The reveal and the next card go out in the *same message*.
- **Keep the reveal short.** The back of the card, plus at most one line of correction. No expansion, no "nice connection to X", no teaching moment. A card that exposes a real gap gets one line in the session summary and a pointer to `/learning-weekly-dive` — not a detour mid-deck.

The exception is a question the *learner* asks. Answer it, then carry on.

---

### Grading: judge the claim, not the wording

The back of the card is a reference answer, not a script the learner has to reproduce. Grade what they know, not how closely they matched the text.

**Correct** — the load-bearing idea is there, in whatever words:

- Different vocabulary for the same concept ("it saves the result so it doesn't recompute" for *memoizes*)
- Their own example instead of the card's
- The right mechanism stated less precisely than the back states it
- The right answer with a secondary detail missing
- The right answer arrived at out loud, with false starts along the way

**Not correct** — the load-bearing idea is absent or wrong:

- Names the right area but not the mechanism ("something in the scheduler")
- Right pieces, wrong relationship — the parts are all named but the causation or order is inverted
- A guess they flag as a guess ("no idea, maybe X?")
- Blank

The test to apply: **would their answer let them do the thing this card exists for?** If yes, it's correct — even when the back says more. Detail they left out is a footnote you add on reveal, not a failure.

For **cloze** cards the blank has a specific filler, so leniency means *equivalent*, not *adjacent*: a synonym or the same value written differently counts; a different concept does not.

Bias toward credit. Under-crediting a correct answer is the worse error: it resets a card the learner actually knows, wastes tomorrow's review on it, and teaches them the session is about phrasing rather than knowing. Being strict does not make the schedule more accurate — it makes it wrong in the direction that costs the most time.

---

### Rate it yourself

Assign the SM-2 quality from what they wrote:

| What their answer looks like | Rating | Quality |
|---|---|---|
| Blank, wrong, or a guess they flag as a guess | Again | **0** |
| Right idea, but hedged, partial, or visibly reconstructed | Hard | **3** |
| Right idea, stated cleanly and directly | Good | **4** |
| Right, complete, immediate — often with a detail the card didn't ask for | Easy | **5** |

Two tie-breaks, because they pull in opposite directions:

- Torn between **wrong and right** → take the lower one. A lapse has to be a lapse or the queue can't do its job.
- Torn between **Hard and Good** → take the higher one. Hesitation on the way to a right answer is what normal retrieval looks like, not a penalty.

State the rating in the reveal so it is never a hidden judgment — one word is enough: *"→ Good."*

#### When the learner overrides you

You are inferring someone else's retrieval effort from its output. They can feel it and you cannot, so if they say *"that was harder than that"* / *"again"* / *"that was easy"*, take their word without arguing and correct the record:

```bash
bash ./.claude/scripts/learning/flashcards.sh queue-regrade "$CARD_ID" "$QUALITY"
```

This *replaces* the rating rather than adding a second review — it rolls the card back to its pre-rating state and re-applies, so an override costs the card nothing. A downgrade to 0 also puts the card back in the queue for another attempt today. It only works on the card's first rating this session; retries never set a schedule, so there is nothing there to correct.

---

### The review loop

Repeat until the queue is empty. **Every iteration is exactly two calls** — pull a card, serve it, record the rating:

```bash
bash ./.claude/scripts/learning/flashcards.sh queue-next
```

Returns the full card plus `attempt` (which pass this is) and `remaining`. `QUEUE_EMPTY=1` means the session is done — go to Phase 3.

It **peeks rather than pops**, so calling it twice returns the same card. The card only leaves the queue when you rate it. That is deliberate: a dropped turn should stall the loop, not silently lose a card.

If `attempt` is greater than 1, this card is a return visit from a lapse. Say so — *"Back to this one."* — and serve it exactly as before. Do not shorten it, hint, or reveal early because they saw it minutes ago; that is the repetition doing its work.

After the learner answers, grade it and record it with the single entry point:

```bash
bash ./.claude/scripts/learning/flashcards.sh queue-rate "$CARD_ID" "$QUALITY"
```

Never call `update-sm2` yourself during a queued session — `queue-rate` decides whether the rating counts as measurement or practice, and calling both double-counts the review.

---

### Serving each card type

**`basic`** — show the front, nothing else. They answer. Reveal the back.

**`cloze`** — show the text with `{{c1::answer}}` replaced by `[___]`. They fill it in. Reveal the full text with the answers in place.

**`scenario`** — show the scenario. They reason it out. Reveal the back. *No Socratic follow-up.* Deep questioning is what `/learning-weekly-dive` is for; here it doubles the cost of every scenario card in the deck and the card still only gets one rating either way.

In all three cases: front out, answer in, back revealed, rated — four steps, two messages.

---

### The shape of a card turn

Serving:

> **Card 3 of 8** — *[topic]*
>
> [front]

Reveal, rating, and the next card, all in one message:

> ✓ **Good** — [the back]
> *[at most one line: what they missed, only if they missed something]*
> Next review in 6 days.
>
> ---
>
> **Card 4 of 8** — *[topic]*
>
> [front]

---

### Reading the outcome

`queue-rate` returns `OUTCOME=`. Report it in the same breath as the rating, in a few words:

- `OUTCOME=requeued` — the card lapsed and is coming back **this session**, after the number of cards in `REQUEUED_AFTER`. Say it concretely: *"Coming back in 2 cards."* Never say "tomorrow" — the point is that they get another attempt before they leave.
- `OUTCOME=capped` — third strike. *"Leaving this one for tomorrow."* Do not keep serving it; that is what the cap is for.
- `OUTCOME=resolved` on attempt 1 — normal pass. Report the interval from `INTERVAL=`: *"Next review in 6 days."*
- `OUTCOME=resolved` on attempt 2+ — they recovered a lapsed card in-session. *"Got it on the second pass — still due tomorrow."*

Only the **first** attempt at a card each session sets its schedule; retries build the memory but don't buy a longer interval. `queue-rate` enforces this — `SM2_APPLIED=0` means the rating was practice. Worth stating plainly if the learner asks, not otherwise.

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

## Phase 4: Add New Cards

Only if the learner asks, or if `NO_CARDS_DUE=1` left them with nothing to review. Don't prompt for it at the end of a normal session — offer it in **Next Actions** instead and let them take it.

When they do:
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
3. Add new cards
4. Export to Anki: `/learning-flashcards export`
5. Deep dive on a struggling topic: `/learning-weekly-dive "[topic]"`
6. That's enough for today!
