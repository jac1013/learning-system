# Learning Framework for Claude Code

A portable, domain-agnostic learning system built on modern learning science. It runs as a set of [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skills and plugins, turning your terminal into a personalized learning environment with spaced repetition, retrieval practice, and Socratic questioning.

Works for **any topic**: software engineering, QA, writing, architecture, security, and more.

## How It Works

The framework applies three research-backed principles:

- **Retrieval stress** — the system asks you to recall before showing answers. Testing yourself strengthens memory far more than re-reading.
- **Spaced repetition** — reviews are scheduled automatically based on how well you recalled. Strong recall pushes the next review further out; weak recall brings it closer.
- **AI role inversion** — instead of explaining, the AI asks questions, challenges assumptions, and makes you teach it back.

## Getting Started

### Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed and configured

### Install

```bash
git clone <repo-url> my-learning
cd my-learning
```

### Setup (15-25 minutes, one time)

```bash
/learning:init
```

This single command walks you through:
1. Creating your learner profile (background, goals, learning style)
2. Generating a personalized 12-week roadmap
3. A quick tour of available commands

After setup, the system guides you — no manual topic selection needed.

## Commands

| Command | Time | Purpose |
|---|---|---|
| `/learning:init` | 15-25 min | First-time setup (profile + roadmap + tour) |
| `/learning:daily-recall` | 5-15 min | Quick retrieval practice on overdue topics |
| `/learning:weekly-dive` | 30-60 min | Deep Socratic exploration of a topic |
| `/learning:monthly-synthesis` | 1-2 hours | Mastery verification with full reconstruction |
| `/learning:apply-to-work` | varies | Apply learning to real tasks (PRs, design, writing) |
| `/learning:create-profile` | 10-15 min | Create or update your learner profile |
| `/learning:create-roadmap` | 5-10 min | Generate or regenerate your learning roadmap |

All commands are **context-aware** — they read your profile, roadmap, and review history to suggest what to work on. You can always override with a specific topic:

```bash
/learning:daily-recall "circuit breaker pattern"
```

## Recommended Rhythm

- **Daily** (5-15 min): `/learning:daily-recall` — quick retrieval on due topics
- **Weekly** (30-60 min): `/learning:weekly-dive` — deep dive on next roadmap topic
- **Monthly** (1-2 hours): `/learning:monthly-synthesis` — verify mastery, create synthesis doc
- **As needed**: `/learning:apply-to-work` — before PRs, architecture decisions, writing

## Project Structure

```
.claude/                          # Framework code (versioned)
├── skills/learning/              # Skill definitions (7 commands)
│   ├── init/SKILL.md
│   ├── daily-recall/SKILL.md
│   ├── weekly-dive/SKILL.md
│   ├── monthly-synthesis/SKILL.md
│   ├── apply-to-work/SKILL.md
│   ├── create-profile/SKILL.md
│   └── create-roadmap/SKILL.md
├── plugins/local/learning-science/
│   ├── helpers/                  # Bash helpers (state management)
│   ├── hooks-handlers/           # Session start hook
│   └── .claude-plugin/           # Plugin registration
└── docs/                         # Extended documentation

# User state (created at runtime, gitignored)
profile.json                      # Your learner profile
roadmap.json                      # Your personalized roadmap
learning-log.jsonl                # Session history
.spaced-repetition.json           # Review scheduling state
.review-schedule.json             # Due review queue
synthesis/                        # Monthly synthesis documents
```

## Portability

The entire system uses relative paths and dynamic path resolution — no hardcoded absolute paths anywhere. You can:

- Copy the directory to another location
- Share the `.claude/` folder as a template
- Run independent instances for different learning topics

See `.claude/docs/PORTABILITY.md` for details.

## Customization

After setup, edit `profile.json` to change goals, time commitment, or learning style. The system adapts automatically.

To adjust retrieval intensity or disable features, create a `.learning-preferences.json`:

```json
{
  "retrieval_stress": {
    "enabled": true,
    "intensity": "low"
  }
}
```

Or say **"just show me"** during any session to skip retrieval stress for that interaction.

## Documentation

Detailed docs live in `.claude/docs/`:

- `QUICK-START.md` — command reference and workflows
- `LEARNING-FRAMEWORK-README.md` — complete system guide
- `PERSONALIZATION-LAYER-README.md` — how context-aware suggestions work
- `learning-log-structure.md` — log format reference
- `PORTABILITY.md` — moving and sharing the system

## Based On

- Spaced repetition research (SuperMemo-inspired intervals)
- Retrieval practice studies (testing effect, 2020-2026)
- Socratic method for deep learning
- Justin Sung's conceptual compression research
- AI role inversion patterns (coaching-first)

## License

Use freely.
