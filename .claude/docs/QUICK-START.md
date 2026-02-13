# Quick Start Guide - Learning System

## 🚀 First Time? Start Here!

### Single Command Setup (15-25 minutes)

```bash
/learning-init
```

This **one command** does everything:
1. ✅ Creates your personalized profile (10-15 min)
2. ✅ Generates your learning roadmap (5-10 min)
3. ✅ Shows you how to use the system (2-3 min)
4. ✅ Gets you started on your first topic

**That's it! After this, the system guides you.**

---

## 📚 All Available Commands

### Setup (One-Time)

**`/learning-init`** 🚀 **START HERE!**
- Complete guided setup
- Profile + Roadmap + System tour
- 15-25 minutes
- Run this first!

---

### Daily Learning (After Setup)

**`/learning-daily-recall`** ⚡ (5-15 min)
- Quick retrieval stress
- System suggests overdue topics
- Or specify: `/learning-daily-recall "topic"`
- **Use**: Daily or every few days

**`/learning-weekly-dive`** 📖 (30-60 min)
- Deep dive with Socratic questioning
- System suggests next roadmap topic
- Or specify: `/learning-weekly-dive "topic"`
- **Use**: Weekly, for new topics

**`/learning-monthly-synthesis`** 🎓 (1-2 hours)
- Mastery verification + synthesis
- System suggests ready topics
- Or specify: `/learning-monthly-synthesis "topic"`
- **Use**: Monthly, for core topics

**`/learning-apply-to-work`** 💼 (Varies)
- Apply learning to real work
- System infers type + suggests topics
- Or specify: `/learning-apply-to-work --type=code-pr --target=123`
- **Use**: Before PRs, writing, testing, design decisions
- **Types**: `code-pr`, `writing`, `qa`, `architecture`, `security`

---

### Maintenance (As Needed)

**`/learning-create-profile`** (10-15 min)
- Create or update your learner profile
- Run quarterly or when things change

**`/learning-create-roadmap`** (5-10 min)
- Generate or regenerate your learning roadmap
- Run when roadmap needs changes

---

## 🎯 Recommended Workflow

### Week 1: Setup + First Topic
```bash
# Day 1: Complete setup (15-25 min)
/learning-init

# Day 1 (continued): Start first topic (30-60 min)
/learning-weekly-dive
# → System suggests first roadmap topic
```

### Ongoing: Daily + Weekly Rhythm
```bash
# Daily (5-15 min, 3-5 days/week)
/learning-daily-recall
# → System: "Test pyramid overdue 2 days"

# Weekly (30-60 min, once per week)
/learning-weekly-dive
# → System: "Event sourcing next in roadmap"

# As needed (before real work)
/learning-apply-to-work
# → System: "Apply circuit breakers to payment service PR"
```

### Monthly: Mastery Verification
```bash
# Monthly (1-2 hours)
/learning-monthly-synthesis
# → System: "Microservices ready for mastery verification"
```

---

## 🛠️ Skills (Used Automatically)

You don't call these directly—commands use them:

- **recall-test** - Predict before seeing
- **teach-back** - Learn by teaching
- **predict-impact** - Consequence prediction
- **concept-mapping** - Mental model visualization
- **contrast-alternatives** - Compare approaches
- **reasoning-trace** - Trace logic without looking
- **time-travel-review** - Reconstruct past learning

---

## 📁 Key Files

**Your Profile**:
`./profile.md`
- Who you are, what you want, how you learn
- Edit anytime

**Your Roadmap**:
`./roadmap.md`
- Your learning path (🔲 → 🔄 → ✅ → 🎓)
- Tracks progress

**Learning Log**:
`./learning-log.md`
- Auto-updated after each session
- Tracks history, scores, insights

**Preferences**:
`./.learning-preferences.json`
- System configuration
- Adjust retrieval intensity, feedback style

---

## 💡 How Context-Aware Works

**You**: `/learning-daily-recall`

**System thinks**:
1. Check `.spaced-repetition.json` → What's overdue?
2. Check `roadmap.md` → What's in progress?
3. Check `profile.md` → What are priorities?
4. Check `learning-log.md` → What was recent?

**System decides**:
```
🎯 Daily Recall: Test Pyramid

Why this topic?
Overdue by 2 days (last reviewed 2026-01-24).
Last score: 6 (moderate recall).
High priority in your profile (QA fundamentals).

Ready to start?
```

**You can override**: `/learning-daily-recall "different topic"`

---

## 🎓 Learning Modes Explained

### Daily Recall (Retrieval Stress)
**What**: Quick test without references
**How**: AI asks, you recall, AI reveals, compare
**Why**: Retrieval strengthens memory 10x more than re-reading
**Time**: 5-15 minutes

### Weekly Dive (Socratic + Teach-Back)
**What**: Deep exploration of new topic
**How**: AI questions you, you teach AI, AI evaluates
**Why**: Challenge builds understanding
**Time**: 30-60 minutes

### Monthly Synthesis (Mastery Verification)
**What**: Complete reconstruction from memory
**How**: Reconstruct system, analyze scenarios, teach mastery
**Why**: Integration creates lasting expertise
**Time**: 1-2 hours

### Apply to Work (Real-World Anchoring)
**What**: Use learning in actual work
**How**: Recall first, apply to task, review outcome
**Why**: Application makes learning stick
**Time**: Varies by task

---

## 🔧 Customization

### Change Retrieval Intensity
Edit `./.learning-preferences.json`:
```json
{
  "retrieval_stress": {
    "enabled": true,
    "intensity": "low"  // or "medium", "high"
  }
}
```

### Change Feedback Style
```json
{
  "feedback_style": "direct"  // or "balanced", "gentle"
}
```

### Disable Retrieval Stress
```json
{
  "retrieval_stress": {
    "enabled": false
  }
}
```

### Or Just Say "Just Show Me"
During any session, say "Just show me" to skip retrieval stress for that interaction.

---

## 📖 Full Documentation

- **PERSONALIZATION-LAYER-README.md** - How personalization works
- **LEARNING-FRAMEWORK-README.md** - Complete system guide
- **learning-log-structure.md** - Log format reference
- **IMPLEMENTATION-SUMMARY.md** - All files and features

---

## ❓ FAQ

**Q: Do I have to specify topics manually?**
A: No! After `/learning-init`, commands suggest topics automatically. Manual specification is optional.

**Q: What if I disagree with the suggestion?**
A: Just specify the topic you want: `/learning-daily-recall "your topic"`

**Q: Can I skip the retrieval stress?**
A: Yes! Say "Just show me" or disable in `.learning-preferences.json`

**Q: How much time do I need?**
A: Minimum: 5-10 min/day. Recommended: 15 min/day + 1 hour/week

**Q: Does this work for non-coding topics?**
A: Yes! Works for QA, writing, architecture, security, anything.

**Q: What if I miss a day?**
A: No problem! System reschedules. Overdue topics get higher priority.

**Q: Can I change my goals?**
A: Yes! Update profile or roadmap anytime.

---

## 🚀 Ready?

```bash
/learning-init
```

That's all you need to start! The system guides you from there.

---

**Version**: 2.0.0
**Last Updated**: 2026-01-29
**Questions?** Check the full documentation or ask me!
