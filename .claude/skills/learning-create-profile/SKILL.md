---
name: learning-create-profile
description: Create or update your learning profile. Guided 10-15 minute interview about goals, learning style, and work context. Usually done via /learning-init but can be run standalone.
disable-model-invocation: false
---

# Create Learning Profile

Create or update your personalized learning profile (10-15 minutes).

**Note**: This is included in `/learning-init`. Use this command to update an existing profile or create one standalone.

---

## Check Existing Profile

!`bash ./.claude/scripts/check-state.sh profile`

---

## Profile Creation Interview

### 📋 Learning Profile Questions

I'll ask you about:
- Your role, experience, and expertise
- What you want to learn and why
- How you learn best
- Time you can commit
- Your work context

This takes 10-15 minutes. Let's go!

---

### Background & Experience

1. **What's your primary role or focus?**
   *(e.g., software engineer, QA lead, technical writer, architect)*

2. **How many years of experience in this field?**

3. **What domains are you most experienced in?**
   *(e.g., backend development, testing, writing, cloud architecture)*

4. **What domains do you want to learn or improve?**

5. **Have you tried learning these topics before? What happened?**

---

### Learning Goals

6. **What do you want to learn?** *(List 3-5 topics/skills)*

7. **Why do you want to learn each one?**
   - Career advancement?
   - Current project needs?
   - Personal interest?
   - Skill gap you've noticed?

8. **What does success look like in 3 months?**
   *(Be specific: "Can design microservices independently")*

9. **What does success look like in 6 months?**

10. **What's blocking you from learning this now?**

---

### Learning Style

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

---

### Time & Context

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

## Save Profile

!`# Create profile JSON from answers
cat > ./profile.json <<'PROFILE'
{
  "name": "[optional name]",
  "role": "[from answer 1]",
  "experience_years": [from answer 2],
  "domains": {
    "experienced": [from answer 3],
    "learning": [from answer 4]
  },
  "goals": {
    "three_month": [
      {
        "topic": "[from answer 6]",
        "motivation": "[from answer 7]",
        "success_criteria": "[from answer 8]"
      }
    ],
    "six_month": "[from answer 9]",
    "blockers": "[from answer 10]"
  },
  "learning_style": {
    "mode": "[exploratory|methodical|example-driven]",
    "stress_tolerance": "[high|medium|low]",
    "feedback_style": "[direct|balanced|gentle]",
    "learning_type": "[social|applied|conceptual|hands-on]"
  },
  "time_commitment": {
    "daily_minutes": [from answer 15],
    "weekly_hours": [from answer 15],
    "best_time": "[from answer 17]"
  },
  "work_context": {
    "focus": "[from answer 16]",
    "technologies": [from answer 16],
    "problems": [from answer 16]
  },
  "created_at": "$(date -I)",
  "updated_at": "$(date -I)"
}
PROFILE

echo ""
echo "✅ **Profile Created!**"
echo ""
echo "Saved to: ./profile.json"
`

---

## Profile Summary

!`bash ./.claude/scripts/display-state.sh profile-summary`

---

## Next Steps

✅ **Profile created successfully!**

**Recommended next steps**:

1. **Generate roadmap**: `/learning-create-roadmap`
   - Creates personalized learning path based on this profile

2. **Start learning**: `/learning-weekly-dive`
   - Begin your first topic

3. **Review profile**: `cat ./profile.json | jq`
   - Check what was saved

**Update anytime**: Just run `/learning-create-profile` again!

---

**What would you like to do?**
1. `/learning-create-roadmap` - Generate learning path
2. `/learning-weekly-dive` - Start learning
3. Edit profile manually - `nano ./profile.json`
