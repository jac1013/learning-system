# Learning Framework — Executive Summary

A Claude Code–powered learning system that turns your terminal into a personal coach. It works for **any domain** (engineering, security, writing, architecture, QA) because the framework is content-agnostic — you bring the goal, it runs the learning loop.

## The core idea

Most "AI tutoring" inverts the classroom: the AI explains, you nod. This framework inverts that inversion. **You recall first; the AI questions, challenges, and only then fills gaps.** It's built on three research-backed pillars:

| Principle | What the system does |
|---|---|
| **Retrieval practice** | Forces you to answer before revealing — testing strengthens memory more than re-reading. |
| **Spaced repetition** | Schedules reviews automatically (SM-2 algorithm). Strong recall pushes intervals out; weak recall pulls them in. |
| **Socratic role inversion** | The AI asks questions and makes you teach concepts back, instead of lecturing. |

## How a learner uses it

**One-time setup (~20 min):** `/learning-init` interviews you about your goals, background, and learning style, then generates a personalized 12-week roadmap.

**Then a recurring rhythm:**

- **Daily (5–15 min)** — `/learning-daily-recall` quick-fire questions on overdue topics
- **Daily (5–15 min)** — `/learning-flashcards` Anki-style card review (cloze + scenarios)
- **Weekly (30–60 min)** — `/learning-weekly-dive` deep Socratic exploration of next roadmap topic
- **Weekly (10–15 min)** — `/learning-quiz` certification-style multiple choice; pick an answer, get the reasoning back, and every miss becomes a flashcard
- **Weekly (20–60 min)** — `/learning-performance-practice` perform the skill under constraints, scored against a precommitted rubric
- **Monthly (1–2 hr)** — `/learning-monthly-synthesis` mastery verification + written synthesis doc
- **Monthly (30–45 min)** — `/learning-quiz exam` timed mock exam across every topic studied so far
- **As needed** — `/learning-apply-to-work` ties learning to real tasks (PR reviews, designs, writing)

Every session is **context-aware**: it reads your profile, roadmap, and recall history to pick what's most valuable next. You can always override with a topic.

## What's tracked automatically

- **Per-topic recall scores** drive future review intervals (spaced repetition state)
- **Study time** auto-measured per session and aggregated by topic/type — `/learning-hours` gives grand total + recent windows + breakdowns
- **Flashcard SM-2 state** at the card level (not just per-deck), with Anki export available
- **Monthly synthesis docs** accumulate as evidence of mastery

## Why it's interesting beyond just "AI tutoring"

1. **Domain-agnostic** — same system handles distributed systems theory, security review skills, or creative writing
2. **Project mode** — `/learning-init-project` analyzes a codebase and builds a learning path *for that specific repo* (great for onboarding)
3. **Application anchoring** — every session is connected to your real work context, not abstract exercises
4. **Portable & local** — runs entirely from a git repo of skills + bash scripts; your data (profile, scores, sessions) stays on your machine and is gitignored
5. **Composable with Claude Code** — skills are auto-discovered slash commands; no plugin install, no separate app

## Architecture (one paragraph for the curious)

It's just markdown skill definitions (`.claude/skills/learning-*/SKILL.md`) and bash helper scripts (`.claude/scripts/learning/*.sh`). State lives in JSON/JSONL files in your project root. Each skill starts a session timer on entry so study time is measured rather than estimated; the SM-2 algorithm handles scheduling math. No backend, no SaaS, no telemetry — your learning data is yours.

---

**Bottom line:** Instead of "ask AI a question, get an explanation, forget it next week," you get a system that builds durable knowledge through the same techniques medical students and language learners have used for decades — but driven by an AI that actually adapts to you.
