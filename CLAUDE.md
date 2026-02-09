# Learning Framework — Agent Instructions

This project is a **learning system**, not a software application. It consists of Claude Code skills, plugins, and helper scripts that facilitate spaced-repetition learning for any domain. Understanding this context is critical — the code here is the learning infrastructure, not a product being built.

## Architecture

### Skills (`.claude/skills/learning/`)

Each `SKILL.md` file defines a learning command (e.g., `/learning:daily-recall`). Skills:
- Are invoked by users via slash commands
- Source helper scripts using relative paths: `./.claude/plugins/local/learning-science/helpers/`
- Read/write user state files in the project root
- Should use Socratic questioning — ask before explaining

### Helpers (`.claude/plugins/local/learning-science/helpers/`)

Bash scripts that manage state:
- `load-state.sh` — loads profile, roadmap, spaced repetition data. Derives project root dynamically from `${BASH_SOURCE[0]}`.
- `save-state.sh` — updates spaced repetition scores and review schedule
- `infer-next.sh` — determines next topic based on profile, roadmap, and review state

All paths are resolved dynamically. Never introduce hardcoded absolute paths.

### Plugin (`.claude/plugins/local/learning-science/.claude-plugin/plugin.json`)

Registers skills and hooks with Claude Code. The `session-start` hook checks for overdue reviews.

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
1. Create `.claude/skills/learning/<name>/SKILL.md`
2. Follow the frontmatter pattern from existing skills
3. Source `load-state.sh` for state access
4. Register in `plugin.json`
5. Add to the commands table in `README.md`

To add a new helper function:
1. Add it to `load-state.sh` (for read operations) or `save-state.sh` (for write operations)
2. Use `$LEARNING_ROOT` for file paths — it's set dynamically by `load-state.sh`
