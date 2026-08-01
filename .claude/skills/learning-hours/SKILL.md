---
name: learning-hours
description: Show total study time committed — grand total, recent activity windows, and per-topic / per-session-type breakdown. Aggregates from learning-log.jsonl. Accepts --since=YYYY-MM-DD.
disable-model-invocation: false
argument-hint: "[--since=YYYY-MM-DD]"
---

# Study Time — Hours Committed

Show how much time you've actually invested in learning.

**Argument**: $ARGUMENTS

---

## Phase 1: Active Session Check

!`bash ./.claude/scripts/learning/session-track.sh status`

*If a session is active, note that it's **not yet** included in the aggregated totals below — it will be counted once the session's skill finishes and logs.*

---

## Phase 2: Aggregate Stats

!`bash ./.claude/scripts/learning/session-track.sh stats $ARGUMENTS`

---

## Phase 3: Retrieval Before Revelation

**Before reading the numbers above, answer from your gut:**

1. **Total hours** — what's your rough estimate of how many hours you've committed to this learning practice so far?
2. **Biggest topic** — which topic do you think you've spent the most time on?
3. **Recent pace** — how many hours would you guess in the last 7 days?

*Wait for the user's answers.*

---

## Phase 4: Compare Estimate to Reality

Now interpret the JSON from Phase 2 and present it clearly:

### ⏱️ Study Time Committed

- **Total**: `total_hours` hours (`total_minutes` minutes across `session_count` sessions)
- **First session**: `earliest`
- **Latest session**: `latest`

### Recent Windows

- **Last 7 days**: `last_7_days_minutes / 60` hours
- **Last 30 days**: `last_30_days_minutes / 60` hours

### By Topic

Sort `by_topic` descending by minutes, show top 5-8 with both minutes and hours-rounded:
- `topic-name` — Xh Ym
- ...

If the bucket `"multi-topic"` appears, it comes from `apply-to-work` sessions that span multiple topics — call this out so the user understands why it's not attributed to a single topic.

### By Session Type

Format `by_type` as a list:
- `daily-recall` — Xh Ym
- `weekly-dive` — Xh Ym
- `monthly-synthesis` — Xh Ym
- `flashcard-review` — Xh Ym
- `performance-practice` — Xh Ym
- `apply-to-work` — Xh Ym
- `orphan-session` — Xh Ym *(auto-closed sessions; capped entries are estimates, not measurements)*

### By Practice Type

Format `by_practice_type` as a list:
- `knowledge` — Xh Ym
- `performance` — Xh Ym
- `application` — Xh Ym
- `unclassified` — Xh Ym *(legacy or orphan entries that cannot be classified)*

---

## Phase 5: Reflection

Compare the user's Phase 3 estimates to the actual numbers:

- **Total estimate vs actual** — were they off? By how much and in which direction?
- **Topic estimate vs actual** — did they correctly identify where time is going?
- **Pace estimate vs actual** — is recent momentum what they thought?

Then ask one interpretive question, choose whichever is most useful given their data:

- *"The roadmap says you're targeting [X], but the biggest time bucket is [Y]. Is that intentional or drift?"*
- *"Your last 7 days is [Nh]. Your daily target is [profile.time_commitment.daily_minutes] minutes — is the pace matching the plan?"*
- *"The `apply-to-work` bucket is [small/large]. Is real-world application happening at the rate you want?"*

---

## Next Actions

1. Filter to a window: `/learning-hours --since=2026-01-01`
2. Continue the practice: `/learning-daily-recall`
3. Adjust the roadmap if time allocation doesn't match priorities: `/learning-create-roadmap`
