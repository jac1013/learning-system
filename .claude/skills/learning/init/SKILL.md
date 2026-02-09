---
name: init
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
    echo "1. Fresh start (delete and recreate)"
    echo "2. Update profile only"
    echo "3. Update roadmap only"
    echo "4. Skip to system tour"
    echo "5. Cancel"
fi`

---

## Step 2: Profile Creation

*If no existing profile or user chose fresh start/update:*

### 📋 Create Your Learning Profile

I'll ask you about:
- Your role, experience, and expertise
- What you want to learn and why
- How you learn best
- Time you can commit
- Your work context (for real application)

This takes 10-15 minutes. Let's go!

#### Background & Experience

1. **What's your primary role or focus?**
   (e.g., software engineer, QA lead, technical writer, architect)

2. **How many years of experience in this field?**

3. **What domains are you most experienced in?**
   (e.g., backend development, testing, writing, cloud architecture)

4. **What domains do you want to learn or improve?**

5. **Have you tried learning these topics before? What happened?**

#### Learning Goals

6. **What do you want to learn?** (List 3-5 topics/skills)

7. **Why do you want to learn each one?**
   - Career advancement?
   - Current project needs?
   - Personal interest?
   - Skill gap you've noticed?

8. **What does success look like in 3 months?**
   (Be specific: "Can design microservices independently")

9. **What does success look like in 6 months?**

10. **What's blocking you from learning this now?**

#### Learning Style

11. **When learning something new, do you prefer to:**
    - a) Jump in and experiment? (Exploratory)
    - b) Read/study first, then apply? (Methodical)
    - c) Learn from examples and adapt? (Example-driven)

12. **How do you handle challenge/frustration when learning?**
    - a) Energized by difficulty (High stress tolerance)
    - b) Balanced approach (Medium tolerance)
    - c) Prefer gradual increase (Low stress, need support)

13. **Feedback style preference:**
    - a) Direct and blunt
    - b) Balanced and constructive
    - c) Gentle and supportive

14. **Do you learn better by:**
    - a) Teaching others?
    - b) Solving problems?
    - c) Understanding theory?
    - d) Building things?

#### Time & Context

15. **How much time can you commit per week?**
    - Daily practice: ___ minutes/day
    - Deep dives: ___ hours/week

16. **What's your work context?**
    - What are you building/working on?
    - What technologies/frameworks?
    - What problems are you solving?

17. **Best time for learning?**
    - Morning / During work / Evening / Weekends

---

### Save Profile

!`cat > ./profile.json <<'PROFILE'
{
  "name": "[from answers]",
  "role": "[from answer 1]",
  "experience_years": [from answer 2],
  "domains": {
    "experienced": ["[from answer 3]"],
    "learning": ["[from answer 4]"]
  },
  "goals": {
    "three_month": [
      {
        "topic": "[from answer 6]",
        "motivation": "[from answer 7]",
        "success_criteria": "[from answer 8]"
      }
    ],
    "six_month": "[from answer 9]"
  },
  "learning_style": {
    "mode": "[exploratory|methodical|example-driven from answer 11]",
    "stress_tolerance": "[high|medium|low from answer 12]",
    "feedback_style": "[direct|balanced|gentle from answer 13]",
    "learning_type": "[social|applied|conceptual|hands-on from answer 14]"
  },
  "time_commitment": {
    "daily_minutes": [from answer 15],
    "weekly_hours": [from answer 15]
  },
  "work_context": {
    "focus": "[from answer 16]",
    "technologies": ["[from answer 16]"],
    "problems": ["[from answer 16]"]
  },
  "created_at": "$(date -I)",
  "updated_at": "$(date -I)"
}
PROFILE`

✅ **Profile Created!**

Your profile: `./profile.json`

---

## Step 3: Roadmap Generation

### 🗺️ Generate Your Learning Roadmap

Based on your profile, I'll create a personalized learning path.

!`source ./.claude/plugins/local/learning-science/helpers/load-state.sh`

**Your Goals**:
!`get_profile_field "goals.three_month[0].topic"`

**Time Available**:
- Daily: !`get_profile_field "time_commitment.daily_minutes"` min/day
- Weekly: !`get_profile_field "time_commitment.weekly_hours"` hours/week

Generating roadmap...

### Roadmap Structure

Based on your goal "[goal from profile]", here's your 12-week learning path:

**Phase 1: Fundamentals** (Weeks 1-4)
- Topic 1.1: [Foundational topic]
- Topic 1.2: [Building on 1.1]
- Topic 1.3: [Core concepts]

**Phase 2: Intermediate** (Weeks 5-8)
- Topic 2.1: [Application patterns]
- Topic 2.2: [Advanced concepts]

**Phase 3: Advanced** (Weeks 9-12)
- Topic 3.1: [Complex scenarios]
- Topic 3.2: [Real-world application]

### Save Roadmap

!`cat > ./roadmap.json <<'ROADMAP'
{
  "primary_goal": "[from profile]",
  "timeline_weeks": 12,
  "current_phase": "Phase 1",
  "topics": {
    "topic-1-1": {
      "name": "[Topic name]",
      "phase": 1,
      "sequence": 1,
      "status": "ready",
      "prerequisites": [],
      "estimated_hours": 3
    }
    // ... more topics
  },
  "phases": {
    "1": {"name": "Fundamentals", "weeks": "1-4"},
    "2": {"name": "Intermediate", "weeks": "5-8"},
    "3": {"name": "Advanced", "weeks": "9-12"}
  },
  "created_at": "$(date -I)",
  "updated_at": "$(date -I)",
  "metadata": {
    "last_updated": "$(date -I)"
  }
}
ROADMAP`

✅ **Roadmap Generated!**

Your roadmap: `./roadmap.json`

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

**`/learning:daily-recall`**
- Quick retrieval stress on overdue topics
- No params needed—system suggests what to review
- Or specify: `/learning:daily-recall "topic"`

**When**: Daily or every few days
**What happens**: AI asks you to recall without looking, then compares

---

#### Weekly Deep Dives (30-60 minutes)

**`/learning:weekly-dive`**
- Socratic interrogation + teach-back
- System suggests next roadmap topic
- Or specify: `/learning:weekly-dive "topic"`

**When**: Weekly, for new topics
**What happens**: AI questions you, challenges assumptions, you teach back

---

#### Monthly Mastery (1-2 hours)

**`/learning:monthly-synthesis`**
- Complete reconstruction + scenario analysis
- System suggests mastery-ready topics
- Or specify: `/learning:monthly-synthesis "topic"`

**When**: Monthly, for core topics
**What happens**: Reconstruct from memory, apply to scenarios, create synthesis doc

---

#### Apply to Real Work (Varies)

**`/learning:apply-to-work`**
- Use learned concepts in actual work
- System infers type + suggests topics
- Or specify: `/learning:apply-to-work --type=code-pr --target=123`

**Types**: `code-pr`, `writing`, `qa`, `architecture`, `security`

**When**: Before PRs, writing, testing, design decisions
**What happens**: Recall test first, apply, then review outcome

---

### 🛠️ How It Works

**Context-Aware (No Manual Specification)**:

```bash
/learning:daily-recall
# → System: "Test pyramid overdue 2 days (score: 6)"
```

The system knows:
- What you've learned (from learning log)
- What's due (from spaced repetition)
- What's next (from roadmap)
- What you can apply (from profile work context)

**Manual override always works**:
```bash
/learning:daily-recall "specific topic"
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
/learning:weekly-dive
```
System will suggest your first roadmap topic!

**Option 2: Quick Practice**
```bash
/learning:daily-recall
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

1. `/learning:weekly-dive` - Start first topic
2. `/learning:daily-recall` - Quick practice
3. Review files - Explore what was created
4. Ask me anything!
