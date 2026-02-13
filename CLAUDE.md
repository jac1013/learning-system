# Learning Framework — Agent Instructions

This project is a **learning system**, not a software application. It consists of Claude Code skills, hooks, and helper scripts that facilitate spaced-repetition learning for any domain. Understanding this context is critical — the code here is the learning infrastructure, not a product being built.

## Architecture

### Skills (`.claude/skills/learning-*/`)

Each `SKILL.md` file defines a learning command (e.g., `/learning-daily-recall`). Skills are auto-discovered by Claude Code from flat directories — no plugin registration needed. Skills:
- Are invoked by users via slash commands (e.g., `/learning-init`, `/learning-daily-recall`)
- Call helper scripts via `bash ./.claude/scripts/<script>.sh` (matches `Bash(bash:*)` permission pattern)
- Read/write user state files in the project root
- Should use Socratic questioning — ask before explaining

### Scripts (`.claude/scripts/`)

Bash scripts that manage state. Called via `bash ./.claude/scripts/<name>.sh` from skill `!` backtick blocks:
- `load-state.sh` — loads profile, roadmap, spaced repetition data. Derives project root dynamically from `${BASH_SOURCE[0]}`.
- `save-state.sh` — updates spaced repetition scores and review schedule
- `infer-next.sh` — determines next topic based on profile, roadmap, and review state
- `check-state.sh` — consolidated state checker for skill initialization (contexts: init, profile, roadmap, project, profile-exists)
- `determine-topic.sh` — topic resolution for daily-recall, weekly-dive, monthly-synthesis
- `parse-apply-args.sh` — argument parser for apply-to-work skill
- `display-state.sh` — state display helper (profile-summary, profile-analysis, roadmap-summary, pacing)

All paths are resolved dynamically. Never introduce hardcoded absolute paths.

### Hooks (`.claude/hooks/`)

- `session-start.sh` — checks for overdue reviews and shows welcome message. Registered in `.claude/settings.json` as a `SessionStart` hook.

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
| `synthesis/` | Monthly synthesis documents |

## Rules for Modifying This System

### Do

- Keep all paths relative or dynamically resolved (see `PORTABILITY.md`)
- Follow the existing skill pattern: load state, check context, interact with user, save state
- Use `load-state.sh` functions (`has_profile`, `has_roadmap`, `get_profile_field`) rather than reading files directly
- Append to `learning-log.jsonl` — never overwrite it
- Update `.spaced-repetition.json` scores through `save-state.sh`
- Keep skills domain-agnostic — they should work for any topic, not just programming

### Do Not

- Add hardcoded absolute paths (breaks portability)
- Modify user state files (`profile.json`, `roadmap.json`) without explicit user request
- Delete or overwrite `learning-log.jsonl` (it's an append-only log)
- Add `settings.local.json` to version control (it contains machine-specific permissions)
- Commit user state files (they are personal data, gitignored for a reason)
- Break the Socratic pattern — skills should ask the user to recall/explain before revealing answers

## Learning Science Principles

When creating or modifying skills, maintain these principles:

1. **Retrieval before revelation** — always ask the user what they think/remember before showing the answer
2. **Productive struggle** — difficulty is a feature, not a bug. Don't make it too easy
3. **Spaced repetition** — scores drive review intervals (high score = longer interval)
4. **Teach-back** — having the user explain to the AI is more effective than the AI explaining to the user
5. **Application anchoring** — connect learning to the user's real work context (from `profile.json`)

## Extending the System

To add a new skill:
1. Create `.claude/skills/learning-<name>/SKILL.md`
2. Follow the frontmatter pattern from existing skills (name field should be `learning-<name>`)
3. Use `bash ./.claude/scripts/<helper>.sh` for state access (not `source`)
4. Add to the commands table in `README.md`

To add a new helper function:
1. Add it to `load-state.sh` (for read operations) or `save-state.sh` (for write operations), or create a new script in `.claude/scripts/`
2. Use `$LEARNING_ROOT` for file paths — it's set dynamically by `load-state.sh`
3. All scripts must be callable via `bash ./.claude/scripts/<name>.sh` to match the `Bash(bash:*)` permission pattern
