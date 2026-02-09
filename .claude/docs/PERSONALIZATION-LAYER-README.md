# Personalization Layer - Complete Implementation

## Overview

The learning framework now includes a **complete personalization layer** that makes it truly adaptive to each learner. You don't need to specify topics manually—the system infers what to work on based on your profile, roadmap, and learning history.

## What's New

### 🆕 Phase 0: Profiling & Roadmap Generation

**Before any learning begins**, the system now:
1. **Creates your profile** - Understands your background, goals, learning style
2. **Generates your roadmap** - Personalized learning path from current state to goals
3. **Structures learning log** - Tracks history to prevent duplicate learning
4. **Enables context-aware commands** - No more manual topic specification!

### New Agents (3)

1. **`learning-profiler.md`** - Creates personalized learner profiles
   - Discovers background, goals, learning style
   - Assesses expertise levels by domain
   - Configures system preferences

2. **`roadmap-generator.md`** - Generates adaptive learning roadmaps
   - Decomposes goals into learnable topics
   - Sequences based on dependencies
   - Adapts to expertise level and time constraints

3. **`learning-context-analyzer.md`** - Intelligently infers what to work on
   - Reads profile, roadmap, log, spaced repetition state
   - Decides next topic for each command
   - Explains reasoning for selections

### New Commands (2)

1. **`/learning:create-profile`** - 10-15 min guided profiling session
   - Run this FIRST (before anything else)
   - Creates `./profile.md`
   - Configures system preferences

2. **`/learning:create-roadmap`** - 5-10 min roadmap generation
   - Run AFTER creating profile
   - Creates `./roadmap.md`
   - Maps path to your goals

### Structured Learning Log

**`learning-log-structure.md`** defines standardized format:
- Consistent entry structure (parseable by automation)
- Statistics tracking (hours, scores, domains)
- Tags for filtering (`#domain`, `#type`, `#score`, `#status`)
- Prevents duplicate learning (system checks history)

### Context-Aware Commands (Enhanced)

All existing commands now work **without parameters**:

#### Before (Manual)
```bash
/learning:daily-recall "test pyramid"
/learning:weekly-dive "event sourcing"
/learning:monthly-synthesis "microservices"
```

#### After (Context-Aware)
```bash
/learning:daily-recall
# → System infers: "Test pyramid is overdue (last reviewed 5 days ago)"

/learning:weekly-dive
# → System infers: "Event sourcing is next in roadmap (Phase 2, Week 5)"

/learning:monthly-synthesis
# → System infers: "Microservices ready for mastery (score 8+ consistently)"
```

**You can still specify topics manually if you want!**

## How It Works

### Step 1: Create Profile (First Time Only)

```bash
/learning:create-profile
```

**What happens**:
- 10-15 minute guided interview
- Asks about:
  - Your role, experience, expertise
  - What you want to learn and why
  - How you learn best
  - Time you can commit
  - Work context for tailored examples
- Creates `./profile.md`
- Configures `.learning-preferences.json`

**Example Profile Output**:
```markdown
# Learning Profile

**Role**: Senior Backend Engineer
**Experience**: 7 years

## Primary Goals (3 months)
1. **Domain-Driven Design** - Design aggregates for order service
   - Current: 20% (Beginner)
   - Target: 60% (Intermediate)

2. **Microservices Resilience** - Implement circuit breakers, bulkheads
   - Current: 30% (Beginner)
   - Target: 70% (Advanced)

## Learning Style
- **Mode**: Example-driven (learn from real code)
- **Stress Tolerance**: High (bring on the challenge!)
- **Feedback**: Direct (tell me what's wrong)

## Time Commitment
- Daily: 15 min/day
- Weekly: 2 hours/week
- Best time: Morning before work

## Work Context
- Building: Payment processing microservices
- Stack: Node.js, PostgreSQL, Docker, Kubernetes
- Problems: Service reliability, data consistency

[Full profile structure defined in profile.md]
```

### Step 2: Generate Roadmap (After Profile)

```bash
/learning:create-roadmap
```

**What happens**:
- Analyzes your profile
- Breaks down goals into topics
- Sequences by dependencies
- Estimates effort and timeline
- Identifies application opportunities
- Creates `./roadmap.md`

**Example Roadmap Output**:
```markdown
# Learning Roadmap

**Goal**: Design aggregates for order service (3 months)

## Phase 1: DDD Fundamentals (Weeks 1-4)

### Topic 1.1: DDD Strategic Design
- Priority: High
- Prerequisites: None
- Estimated: 3 hours over 2 weeks
- Application: Map bounded contexts in payment service

### Topic 1.2: Aggregates & Boundaries
- Priority: High
- Prerequisites: 1.1
- Estimated: 4 hours over 2 weeks
- Application: Design order aggregate

[Full roadmap with all phases, topics, timelines]
```

### Step 3: Start Learning (Context-Aware)

Now when you run learning commands **without parameters**, the system decides what to work on:

```bash
# Daily recall (5-15 min)
/learning:daily-recall
```

**System thinks**:
1. Check `.spaced-repetition.json` → What's overdue?
2. Check `roadmap.md` → What's in progress?
3. Check `profile.md` → What are priorities?
4. Check `learning-log.md` → What was recent?

**System decides**:
```
🎯 **Daily Recall: Test Pyramid**

**Why this topic?**
Overdue for review by 2 days (last reviewed 2026-01-24).
Last score was 6 (moderate recall).
High priority in your profile (QA fundamentals).

Ready to start?
```

**You confirm or override**:
- "yes" → Start recall test
- "/learning:daily-recall 'different topic'" → Override

### Step 4: Apply to Work (Inferred Type)

```bash
/learning:apply-to-work
```

**System thinks**:
1. Check `profile.md` → Work context: "Building payment service, weekly PR reviews"
2. Check recent learning → "Circuit breakers learned last week (score: 8)"
3. Infer work type → Code PR review (from profile)
4. Match topics to work → Circuit breakers relevant to service calls

**System decides**:
```
💼 **Apply to Work: Code PR Review**

**Topics to apply**:
- Circuit breakers (learned 2026-01-22, score: 8)
- Error handling patterns (learned 2026-01-19, score: 7)

**Why?**
Your profile mentions weekly PR reviews. Recent PRs likely involve
service-to-service calls—perfect opportunity to apply resilience patterns.

**Focus areas**:
- Look for service calls without circuit breakers
- Check error handling in API calls
- Verify timeout configurations

Ready to review PRs with this lens?
```

## Complete User Journey

### First-Time User

```bash
# Step 1: Create profile (10-15 min, one-time)
/learning:create-profile
# → Guided interview, creates profile.md

# Step 2: Generate roadmap (5-10 min, one-time)
/learning:create-roadmap
# → Creates personalized roadmap.md

# Step 3: Start learning (daily/weekly)
/learning:weekly-dive
# → System suggests first topic from roadmap

/learning:daily-recall
# → System suggests reviews based on spaced repetition

# Step 4: Apply to work (ongoing)
/learning:apply-to-work
# → System matches learning to real work
```

### Ongoing User (After Setup)

```bash
# Daily (5-15 min)
/learning:daily-recall
# → System: "Test pyramid overdue, let's review"

# Weekly (30-60 min)
/learning:weekly-dive
# → System: "Event sourcing is next in roadmap"

# Monthly (1-2 hours)
/learning:monthly-synthesis
# → System: "Microservices ready for mastery verification"

# As needed
/learning:apply-to-work
# → System: "Apply circuit breakers to payment service PR"
```

**No manual topic specification needed!**

## Key Files Created

### Profile & Roadmap
- `./profile.md` - Your personalized profile
- `./roadmap.md` - Your learning path
- `./learning-log-structure.md` - Log format guide

### Agents
- `learning-profiler.md` - Profile creation
- `roadmap-generator.md` - Roadmap generation
- `learning-context-analyzer.md` - Topic inference

### Commands
- `create-profile.md` - Profile creation command
- `create-roadmap.md` - Roadmap generation command

## Benefits of Personalization

### 1. No Manual Topic Specification
**Before**: "What should I learn today? Let me check my notes..."
**After**: System tells you what's due, what's next, what to apply

### 2. Adaptive to Expertise
**Novice**: Starts with fundamentals, provides scaffolding
**Advanced**: Focuses on nuance, trade-offs, mastery

### 3. Realistic Pacing
**Before**: Overcommit → Fail → Give up
**After**: Honest time assessment → Sustainable progress

### 4. Application-Focused
**Before**: Learn theory, forget quickly
**After**: Learn → Apply to real work → Retain

### 5. Prevents Duplicate Learning
**Before**: "Did I learn this already? Let me search..."
**After**: System checks log, avoids repeats (unless spaced repetition)

### 6. Explains Decisions
System always explains **why** it selected a topic:
- "Overdue by 2 days" (spaced repetition)
- "Next in roadmap sequence" (dependencies)
- "High priority in profile" (goals)
- "Application opportunity this week" (real work)

## Context Analysis Logic

### Daily Recall Selection
```
Priority 1: Overdue reviews (spaced repetition)
Priority 2: High-priority topics from profile
Priority 3: Recently learned (freshen up)
Priority 4: Next in roadmap sequence

Filters:
- Must be due today or earlier
- Prefer topics with score <7 (weak recall)
- Respect profile priorities
```

### Weekly Dive Selection
```
Priority 1: Next in roadmap (prerequisites met)
Priority 2: Struggling topics (score <6 consistently)
Priority 3: High-priority from profile
Priority 4: Application opportunities this week

Filters:
- Prerequisites must be met
- Not already mastered (score 9+)
- Aligns with 3-month goals
```

### Monthly Synthesis Selection
```
Priority 1: Completed topics marked for synthesis
Priority 2: Strong topics (score 8+ consistently)
Priority 3: Phase completion milestones
Priority 4: Core topics blocking others

Filters:
- Must have 3+ reviews
- Not already synthesized
- Foundational (blocks other learning)
```

### Apply-to-Work Selection
```
Priority 1: Recent learning (last 1-2 weeks)
Priority 2: Score 7+ (ready to apply)
Priority 3: Matches work context from profile
Priority 4: Scheduled application in roadmap

Work type inferred from:
- Profile work context (PR reviews → code-pr)
- Recent work activities
- Tech stack mentioned
```

## Fallback Behavior

### No Profile
```
📋 **Profile Needed**

I can't suggest topics without knowing your goals and context.

Create your profile first: `/learning:create-profile` (10-15 min)

Or specify a topic manually: `/learning:daily-recall "topic"`
```

### No Roadmap
```
🗺️ **Roadmap Recommended**

I can help you learn specific topics, but a roadmap ensures you:
- Learn in the right sequence
- Don't miss prerequisites
- Apply learning to real work

Create roadmap: `/learning:create-roadmap` (5-10 min)

Or continue with: `/learning:weekly-dive "topic"`
```

### Multiple Equal Candidates
```
🤔 **Multiple Options**

I found 3 topics ready for review:
1. Test pyramid (QA) - Overdue 2 days
2. Circuit breakers (Architecture) - Due today
3. Active voice (Writing) - Due today

Which would you like? (1/2/3)
Or I'll pick #1 (highest priority)
```

## Roadmap Adaptation

Roadmaps aren't static—they evolve:

### Quarterly Reviews
Every 3 months:
- Review goals (achieved? new ones?)
- Update expertise levels
- Adjust pacing (too fast? too slow?)
- Rebalance priorities

### Mid-Roadmap Adjustments
```bash
/learning:update-roadmap
```
- Add/remove topics
- Reorder sequence
- Change pacing
- Update application opportunities

### Automatic Adjustments
System adjusts based on:
- Topics taking 2x longer → Slow down
- Topics taking 0.5x time → Speed up
- Consistently weak areas → Add scaffolding
- Work context changes → Update applications

## Integration Summary

### Profile Informs:
- Roadmap generation (goals → topics)
- System configuration (learning style → preferences)
- Example customization (work context → tailored examples)
- Context analysis (priorities → topic selection)

### Roadmap Informs:
- Context analysis (sequence → next topic)
- Progress tracking (completed vs planned)
- Application timing (when to apply what)
- Prerequisite checking (readiness gates)

### Learning Log Informs:
- Context analysis (recent history → avoid duplicates)
- Roadmap adjustment (actual pace → timeline)
- Pattern identification (strengths/struggles → adapt)
- Spaced repetition (last reviewed → next review)

### Spaced Repetition Informs:
- Daily recall selection (overdue → priority)
- Context analysis (scores → difficulty)
- Roadmap pacing (retention → speed)

**Everything is connected!**

## Migration Path

### For New Users
1. `/learning:create-profile` (required)
2. `/learning:create-roadmap` (recommended)
3. Start learning (context-aware)

### For Existing Users
You can:
- **Keep using manual commands**: Still works!
  - `/learning:daily-recall "topic"` (specify manually)

- **Adopt gradually**:
  1. Create profile (enables personalization)
  2. Try context-aware commands
  3. Create roadmap when ready

- **Full adoption**:
  1. Create profile
  2. Create roadmap
  3. Use context-aware commands
  4. Let system guide you

**Backward compatible—no breaking changes!**

## Success Metrics

After personalization:
- ✅ Topics selected automatically (no manual specification)
- ✅ Pacing sustainable (realistic time commitments)
- ✅ Application opportunities captured (learning sticks)
- ✅ No duplicate learning (system checks history)
- ✅ Progress visible (roadmap tracks completion)
- ✅ Adaptive (adjusts to your pace and context)

---

**The system now knows WHO you are, WHAT you want to learn, and HOW to guide you there.** 🚀
