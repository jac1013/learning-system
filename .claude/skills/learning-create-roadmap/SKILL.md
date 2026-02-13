---
name: learning-create-roadmap
description: Generate personalized learning roadmap based on your profile. Breaks down goals into topics, sequences by dependencies, estimates timeline. Usually done via /learning-init but can be run standalone.
disable-model-invocation: false
---

# Create Learning Roadmap

Generate your personalized learning roadmap (5-10 minutes).

**Note**: This is included in `/learning-init`. Use this command to regenerate your roadmap or create one standalone.

---

## Prerequisites Check

!`bash ./.claude/scripts/check-state.sh roadmap`

---

## Analyze Profile

!`bash ./.claude/scripts/display-state.sh profile-analysis`

---

## Roadmap Structure

Based on your goal "**[goal from profile]**", here's your 12-week learning path:

### Phase 1: Fundamentals (Weeks 1-4)

*Topics that build the foundation*:

**Topic 1.1**: [Foundational topic]
- **Prerequisites**: None
- **Estimated effort**: 2-3 hours over 2 weeks
- **Why first**: Builds essential understanding

**Topic 1.2**: [Building on 1.1]
- **Prerequisites**: Topic 1.1
- **Estimated effort**: 3-4 hours over 2 weeks
- **Why next**: Applies fundamental concepts

**Topic 1.3**: [Core concept]
- **Prerequisites**: Topic 1.1, 1.2
- **Estimated effort**: 3-4 hours over 2 weeks
- **Application**: [Real work opportunity from profile]

---

### Phase 2: Intermediate (Weeks 5-8)

*Topics that build capability*:

**Topic 2.1**: [Application pattern]
- **Prerequisites**: Phase 1 complete
- **Estimated effort**: 4-5 hours over 2 weeks
- **Builds toward**: Your 3-month goal

**Topic 2.2**: [Advanced concept]
- **Prerequisites**: Topic 2.1
- **Estimated effort**: 4-5 hours over 2 weeks
- **Application**: [Real work opportunity]

---

### Phase 3: Advanced (Weeks 9-12)

*Topics that achieve mastery*:

**Topic 3.1**: [Complex scenario]
- **Prerequisites**: Phase 2 complete
- **Estimated effort**: 5-6 hours over 2 weeks
- **Synthesis**: Combines everything learned

**Topic 3.2**: [Real-world application]
- **Prerequisites**: Topic 3.1
- **Estimated effort**: 5-6 hours over 2 weeks
- **Milestone**: Achieves your 3-month goal

---

### Application Opportunities

Based on your work context (**[from profile]**):

- **Week 4**: After Phase 1 → Apply to [specific work context]
- **Week 8**: After Phase 2 → Apply to [specific work context]
- **Week 12**: After Phase 3 → [Goal achievement application]

---

## Save Roadmap

*Write `./roadmap.json` using the Write tool based on the profile analysis. Structure:*

```json
{
  "primary_goal": "[from profile]",
  "success_criteria": "[from profile]",
  "timeline_weeks": 12,
  "current_phase": "Phase 1",
  "topics": {
    "topic-key": {
      "name": "", "phase": 1, "week": "1-2", "sequence": 1,
      "status": "ready|blocked", "prerequisites": [],
      "estimated_hours": 3, "type": "foundational|building|core"
    }
  },
  "phases": {
    "1": { "name": "Fundamentals", "weeks": "1-4", "focus": "", "topics": [] },
    "2": { "name": "Intermediate", "weeks": "5-8", "focus": "", "topics": [] },
    "3": { "name": "Advanced", "weeks": "9-12", "focus": "", "topics": [] }
  },
  "milestones": { "week-4": "", "week-8": "", "week-12": "" },
  "created_at": "YYYY-MM-DD",
  "updated_at": "YYYY-MM-DD",
  "metadata": { "last_updated": "YYYY-MM-DD", "pacing": "balanced", "total_hours_estimated": 40 }
}
```

---

## Roadmap Summary

!`bash ./.claude/scripts/display-state.sh roadmap-summary`

---

## Pacing Assessment

Based on your time commitment:

**Your capacity**:
!`bash ./.claude/scripts/display-state.sh pacing`

**Roadmap requires**:
- ~3-5 hours/week average
- 1-2 weekly deep dives
- Daily practice (5-15 min)

**Assessment**: [On track / Aggressive / Conservative]

---

## Next Steps

✅ **Roadmap created successfully!**

**Recommended next steps**:

1. **Start first topic**: `/learning-weekly-dive`
   - System will suggest: Topic 1.1
   - ~30-60 minutes
   - Gets you started on your journey!

2. **Review roadmap**: `cat ./roadmap.json | jq`
   - See complete path

3. **Adjust if needed**: Edit `./roadmap.json`
   - Add/remove topics
   - Change pacing
   - Update estimates

**Track progress**:
- Topics move: ready → in-progress → completed → mastered
- System tracks completion automatically

---

## Roadmap Flexibility

**Your roadmap is adaptive**:

- ✅ Topics can be added/removed
- ✅ Pacing can be adjusted
- ✅ Sequence can be reordered (if prerequisites met)
- ✅ Application opportunities can be updated

**Update anytime**: Edit the JSON file or run `/learning-create-roadmap` again

---

**What would you like to do?**
1. `/learning-weekly-dive` - Start first topic now!
2. Review roadmap - `cat ./roadmap.json | jq`
3. Adjust roadmap - Edit the file manually
4. Daily practice - `/learning-daily-recall`
