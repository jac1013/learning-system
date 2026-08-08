# Learning Framework — Agent Instructions

This project is a **learning system**, not a software application. It consists of Claude Code skills, hooks, and helper scripts that facilitate spaced-repetition learning for any domain. Understanding this context is critical — the code here is the learning infrastructure, not a product being built.

## Architecture

### Skills (`.claude/skills/learning-*/`)

Each `SKILL.md` file defines a learning command (e.g., `/learning-daily-recall`). Skills are auto-discovered by Claude Code from flat directories — no plugin registration needed. Skills:
- Are invoked by users via slash commands (e.g., `/learning-init`, `/learning-daily-recall`)
- Call helper scripts via `bash ./.claude/scripts/learning/<script>.sh` (matches `Bash(bash:*)` permission pattern)
- Read/write user state files in the project root
- Should use Socratic questioning — ask before explaining

### Scripts (`.claude/scripts/learning/`)

Bash scripts that manage state. Called via `bash ./.claude/scripts/learning/<name>.sh` from skill `!` backtick blocks:
- `load-state.sh` — loads profile, roadmap, spaced repetition data. Derives project root dynamically from `${BASH_SOURCE[0]}`.
- `save-state.sh` — updates spaced repetition scores and review schedule
- `infer-next.sh` — determines next topic based on profile, roadmap, and review state
- `check-state.sh` — consolidated state checker for skill initialization (contexts: init, profile, roadmap, project, profile-exists)
- `determine-topic.sh` — topic resolution for daily-recall, weekly-dive, monthly-synthesis, and performance-practice
- `parse-apply-args.sh` — argument parser for apply-to-work skill
- `display-state.sh` — state display helper (profile-summary, profile-analysis, roadmap-summary, pacing)
- `flashcards.sh` — flashcard CRUD, SM-2 algorithm, stats, Anki export (operations: init, stats, list-due, add-card, add-cards, update-sm2, get-card, search, export-anki), plus the in-session lapse queue (operations: queue-init, queue-next, queue-rate, queue-regrade, queue-status, queue-end). SM-2 only schedules the *next* session; the queue is what gives a blanked card another attempt *today*. `queue-init` snapshots the due cards into `.flashcard-session.json`; `queue-next` **peeks without popping** (a card leaves the queue only when rated, so a dropped skill turn stalls rather than silently losing a card); `queue-rate <id> <quality>` is the single entry point during a queued session. Rating 0 re-inserts the card `QUEUE_REQUEUE_GAP` (2) positions later, up to `QUEUE_RETRY_CAP` (3) attempts, then leaves it for tomorrow. **Only the first rating of a card in a session drives SM-2** — retries are practice, never measurement, or blanking then passing would schedule the card out as if it had been recalled cleanly. Skills must not call `update-sm2` during a queued session. `queue-regrade <id> <quality>` corrects an auto-assigned rating on a card's *first* attempt: it restores the SM-2 snapshot taken before that rating and re-applies, so an override **replaces** the review instead of stacking a second one. It is rejected on attempt 2+ (retries set no schedule, so there is nothing to correct).
- `quiz.sh` — multiple-choice question bank and sampler (operations: init, session-init, stats, sample, add-questions, record, record-exam, list-weak, get-question, search). `session-init "$ARGUMENTS"` is the single eager `!`-block entry point for the quiz skill: it parses mode (`exam` prefix) and topic, delegates topic resolution to `determine-topic.sh quiz`, and prints bank stats. `sample` scores questions by never-seen > miss-rate, deprioritizes anything already served today, and balances across topics in `--mode=exam`. Questions are deduplicated on normalized stem within a `source_topic`. The bank is separate from `.flashcards.json` — quiz stats drive sampling only, never SM-2 or topic scheduling.
- `session-track.sh` — automatic study-time tracker (operations: start, duration, end, status, stats). Session skills call `start <skill> [topic]` at entry; `save-state.sh log` auto-enriches log entries with the measured duration and clears the active session on log. `stats` aggregates hours from `learning-log.jsonl`. Orphan sessions (never ended) are auto-closed on next `start`: discarded if <2min, capped at 60min and flagged `"type":"orphan-session"` otherwise.
- `roadmap-status.sh` — automatic roadmap status transitions (operations: enter, resolve, master, unlock, status). Owns the `blocked → ready → in-progress → completed → mastered` lifecycle; skills call it and report what it did rather than asking the learner. `enter <topic>` marks a topic in-progress and completes any *other* in-progress topic (`completion_reason: "moved-on"`) — moving on is the signal that the previous topic is done. `resolve <topic> <score> <gaps>` completes only when earned (score ≥ 7 **and** zero open gaps, `completion_reason: "met-bar"`); otherwise the topic stays in-progress. Completed/mastered topics are never demoted by a revisit. Every operation then runs `unlock`, which promotes blocked topics whose prerequisites are satisfied — by explicit `prerequisites` where present, else by `sequence`. All operations are silent no-ops when `roadmap.json` is absent, and never create it.

All paths are resolved dynamically. Never introduce hardcoded absolute paths.

### Docs (`.claude/docs/`)

Extended documentation. These are reference material — not loaded automatically.

## User State Files

These files are created at runtime in the project root and are **gitignored**:

| File | Purpose |
|---|---|
| `profile.json` | Learner profile (goals, style, background) |
| `roadmap.json` | Personalized 12-week learning plan |
| `learning-log.jsonl` | Append-only session history |
| `.spaced-repetition.json` | Per-topic review scheduling state |
| `.review-schedule.json` | Queue of due reviews |
| `.flashcards.json` | Per-card flashcard content and SM-2 scheduling state |
| `.quiz-bank.json` | Multiple-choice question bank with per-question seen/missed stats |
| `.current-session.json` | Active study session state (skill, topic, started_at). Auto-cleared on log; orphans auto-closed on next `start`. |
| `.flashcard-session.json` | In-session flashcard queue and per-card attempt record. Created by `queue-init`, cleared by `queue-end`. |
| `synthesis/` | Monthly synthesis documents |

## Rules for Modifying This System

### Do

- Keep all paths relative or dynamically resolved (see `PORTABILITY.md`)
- Follow the existing skill pattern: load state, check context, interact with user, save state
- Use `load-state.sh` functions (`has_profile`, `has_roadmap`, `get_profile_field`) rather than reading files directly
- Append to `learning-log.jsonl` — never overwrite it
- Update `.spaced-repetition.json` scores through `save-state.sh`
- Update roadmap *status* through `roadmap-status.sh`, silently — status is framework-managed, and skills report the transition rather than asking the learner to approve it
- Keep skills domain-agnostic — they should work for any topic, not just programming
- Save generated flashcards directly, then show what was saved. Card review happens at study time; an approval step before saving is friction that stops sessions from being run

### Do Not

- Add hardcoded absolute paths (breaks portability)
- Modify roadmap *content* (topics, sequence, prerequisites) or `profile.json` without explicit user request — status fields are the exception, see above
- Delete or overwrite `learning-log.jsonl` (it's an append-only log)
- Add `settings.local.json` to version control (it contains machine-specific permissions)
- Commit user state files (they are personal data, gitignored for a reason)
- Break the Socratic pattern — skills should ask the user to recall/explain before revealing answers

## Learning Science Principles

When creating or modifying skills, maintain these principles:

1. **Retrieval before revelation** — always ask the user what they think/remember before showing the answer. In multiple-choice formats the *pick itself* is the retrieval attempt; do not additionally demand written reasoning before revealing (see `learning-quiz`)
2. **Productive struggle** — difficulty is a feature, not a bug. Don't make it too easy
3. **Spaced repetition** — scores drive review intervals (high score = longer interval)
4. **Teach-back** — having the user explain to the AI is more effective than the AI explaining to the user
5. **Vary the generative mode** — a second pass over the same material after feedback is well supported; making that second pass the *same activity* is not. Repeating a task within one session mostly re-retrieves the first performance rather than the knowledge, which reads as fluency and measures little. Explaining, repairing a broken case, discriminating under multiple choice, and predicting are different tests of the same knowledge — a session should use different ones rather than the same one twice (see `learning-weekly-dive` Phases 3 / 5 / 5b)
6. **Application anchoring** — connect learning to the user's real work context (from `profile.json`)
7. **Observable performance** — freeze scenarios and rubrics before an unassisted attempt; score behavior and artifacts, not inferred traits
8. **Grade the claim, not the wording** — a reference answer is not a script to reproduce. Credit the load-bearing idea in whatever words the learner used, and treat missing secondary detail as a footnote on reveal rather than a failure. Under-crediting is the worse error: it resets a card the learner knows and teaches them the session is about phrasing
9. **Protect the pace of drill loops** — in high-repetition formats (flashcards, quiz) every question, confirmation, or teaching detour is paid once per item and is what makes learners stop running sessions. The system grades and rates on the learner's behalf and serves the next item in the same message; a self-report question whose answer is already visible in what they wrote is friction, not rigor. Depth belongs in `/learning-weekly-dive`

## Extending the System

To add a new skill:
1. Create `.claude/skills/learning-<name>/SKILL.md`
2. Follow the frontmatter pattern from existing skills (name field should be `learning-<name>`)
3. Use `bash ./.claude/scripts/learning/<helper>.sh` for state access (not `source`)
4. Add to the commands table in `README.md`

To add a new helper function:
1. Add it to `load-state.sh` (for read operations) or `save-state.sh` (for write operations), or create a new script in `.claude/scripts/learning/`
2. Use `$LEARNING_ROOT` for file paths — it's set dynamically by `load-state.sh`
3. All scripts must be callable via `bash ./.claude/scripts/learning/<name>.sh` to match the `Bash(bash:*)` permission pattern
