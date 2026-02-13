---
name: learning-init
description: Complete guided setup for learning system. Creates profile, generates roadmap, and explains how to use the system. Run this first!
disable-model-invocation: false
---

# Learning System Initialization

Welcome to your personalized learning system! 🎓

This complete setup takes 15-25 minutes and includes:
1. **Profile Creation** (10-15 min) - Understand your goals and learning style
2. **Roadmap Generation** (5-10 min) - Create your personalized learning path
3. **System Tour** (2-3 min) - Learn how to use the system

Let's begin!

---

## Step 1: Check Existing State

!`source ./.claude/plugins/local/learning-science/helpers/load-state.sh`

!`if has_profile && has_roadmap; then
    echo "🔄 **Existing Setup Detected**"
    echo ""
    echo "Profile: $PROFILE_FILE (created $(stat -c %y "$PROFILE_FILE" | cut -d' ' -f1))"
    echo "Roadmap: $ROADMAP_FILE (created $(stat -c %y "$ROADMAP_FILE" | cut -d' ' -f1))"
    echo ""
    echo "What would you like to do?"
    echo "1. Fresh start (delete and recreate both)"
    echo "2. Update profile only → /learning-create-profile"
    echo "3. Update roadmap only → /learning-create-roadmap"
    echo "4. Skip to system tour"
    echo "5. Cancel"
fi`

---

## Step 2: Create Profile

*If no existing profile or user chose fresh start/update profile:*

**Delegate to `/learning-create-profile`** — this runs the full profile interview (10-15 min) and saves `profile.json`.

*Wait for profile creation to complete before proceeding.*

---

## Step 3: Generate Roadmap

*If no existing roadmap or user chose fresh start/update roadmap:*

**Delegate to `/learning-create-roadmap`** — this analyzes your profile, generates a 12-week learning path, and saves `roadmap.json`.

*Wait for roadmap generation to complete before proceeding.*

---

## Step 4: System Tour

### 🎉 Setup Complete! Here's How to Use Your Learning System

You now have:
✅ Profile (who you are, what you want)
✅ Roadmap (your path to goals)
✅ Context-aware system (guides you automatically)

---

### 📚 Available Commands

#### Daily Practice (5-15 minutes)

**`/learning-daily-recall`**
- Quick retrieval stress on overdue topics
- No params needed—system suggests what to review
- Or specify: `/learning-daily-recall "topic"`

**When**: Daily or every few days
**What happens**: AI asks you to recall without looking, then compares

---

#### Weekly Deep Dives (30-60 minutes)

**`/learning-weekly-dive`**
- Socratic interrogation + teach-back
- System suggests next roadmap topic
- Or specify: `/learning-weekly-dive "topic"`

**When**: Weekly, for new topics
**What happens**: AI questions you, challenges assumptions, you teach back

---

#### Monthly Mastery (1-2 hours)

**`/learning-monthly-synthesis`**
- Complete reconstruction + scenario analysis
- System suggests mastery-ready topics
- Or specify: `/learning-monthly-synthesis "topic"`

**When**: Monthly, for core topics
**What happens**: Reconstruct from memory, apply to scenarios, create synthesis doc

---

#### Apply to Real Work (Varies)

**`/learning-apply-to-work`**
- Use learned concepts in actual work
- System infers type + suggests topics
- Or specify: `/learning-apply-to-work --type=code-pr --target=123`

**Types**: `code-pr`, `writing`, `qa`, `architecture`, `security`

**When**: Before PRs, writing, testing, design decisions
**What happens**: Recall test first, apply, then review outcome

---

### 🛠️ How It Works

**Context-Aware (No Manual Specification)**:

```bash
/learning-daily-recall
# → System: "Test pyramid overdue 2 days (score: 6)"
```

The system knows:
- What you've learned (from learning log)
- What's due (from spaced repetition)
- What's next (from roadmap)
- What you can apply (from profile work context)

**Manual override always works**:
```bash
/learning-daily-recall "specific topic"
```

---

### 📖 Key Files

- **Profile**: `./profile.json`
- **Roadmap**: `./roadmap.json`
- **Learning Log**: `./learning-log.jsonl`
- **Spaced Repetition**: `./.spaced-repetition.json`

---

### 🚀 Your Next Steps

**Option 1: Start First Topic** (Recommended)
```bash
/learning-weekly-dive
```
System will suggest your first roadmap topic!

**Option 2: Quick Practice**
```bash
/learning-daily-recall
```
Start with a quick 5-10 min session.

**Option 3: Review Roadmap**
```bash
cat ./roadmap.json | jq
```

---

### 🔧 Customization

Edit `./profile.json` to update:
- Goals, time commitment, preferences
- Learning style, feedback preferences

The system adapts automatically!

---

**You're all set! What would you like to do?**

1. `/learning-weekly-dive` - Start first topic
2. `/learning-daily-recall` - Quick practice
3. Review files - Explore what was created
4. Ask me anything!
