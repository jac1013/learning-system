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

!`source ./.claude/plugins/local/learning-science/helpers/load-state.sh`

!`if ! has_profile; then
    echo "❌ **Profile Required**"
    echo ""
    echo "I need your learning profile to generate a roadmap."
    echo ""
    echo "Create profile first: /learning-create-profile"
    echo ""
    exit 1
fi

if has_roadmap; then
    echo "🗺️ **Existing Roadmap Found**"
    echo ""
    echo "Roadmap: $ROADMAP_FILE"
    echo "Created: $(jq -r '.created_at' "$ROADMAP_FILE")"
    echo "Goal: $(jq -r '.primary_goal' "$ROADMAP_FILE")"
    echo "Current phase: $(jq -r '.current_phase' "$ROADMAP_FILE")"
    echo ""
    echo "What would you like to do?"
    echo "1. Update roadmap (adjust pacing, add/remove topics)"
    echo "2. Fresh roadmap (delete and recreate)"
    echo "3. Cancel"
    echo ""
fi`

---

## Analyze Profile

!`echo "🔍 **Analyzing Your Profile...**"
echo ""
echo "**Your 3-Month Goal**: $(get_profile_field 'goals.three_month[0].topic')"
echo "**Success Criteria**: $(get_profile_field 'goals.three_month[0].success_criteria')"
echo ""
echo "**Time Available**:"
echo "- Daily: $(get_profile_field 'time_commitment.daily_minutes') min/day"
echo "- Weekly: $(get_profile_field 'time_commitment.weekly_hours') hours/week"
echo ""
echo "**Learning Style**: $(get_profile_field 'learning_style.mode')"
echo ""
echo "Generating roadmap..."
`

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

!`# Generate roadmap JSON
cat > ./roadmap.json <<'ROADMAP'
{
  "primary_goal": "$(get_profile_field 'goals.three_month[0].topic')",
  "success_criteria": "$(get_profile_field 'goals.three_month[0].success_criteria')",
  "timeline_weeks": 12,
  "current_phase": "Phase 1",
  "topics": {
    "topic-1-1": {
      "name": "[Topic name]",
      "phase": 1,
      "week": "1-2",
      "sequence": 1,
      "status": "ready",
      "prerequisites": [],
      "estimated_hours": 3,
      "type": "foundational"
    },
    "topic-1-2": {
      "name": "[Topic name]",
      "phase": 1,
      "week": "3-4",
      "sequence": 2,
      "status": "blocked",
      "prerequisites": ["topic-1-1"],
      "estimated_hours": 4,
      "type": "building"
    },
    "topic-1-3": {
      "name": "[Topic name]",
      "phase": 1,
      "week": "4-5",
      "sequence": 3,
      "status": "blocked",
      "prerequisites": ["topic-1-1", "topic-1-2"],
      "estimated_hours": 4,
      "type": "core",
      "application": "[work context]"
    }
  },
  "phases": {
    "1": {
      "name": "Fundamentals",
      "weeks": "1-4",
      "focus": "Build foundation",
      "topics": ["topic-1-1", "topic-1-2", "topic-1-3"]
    },
    "2": {
      "name": "Intermediate",
      "weeks": "5-8",
      "focus": "Build capability",
      "topics": ["topic-2-1", "topic-2-2"]
    },
    "3": {
      "name": "Advanced",
      "weeks": "9-12",
      "focus": "Achieve mastery",
      "topics": ["topic-3-1", "topic-3-2"]
    }
  },
  "milestones": {
    "week-4": "Phase 1 complete, first application",
    "week-8": "Phase 2 complete, confident application",
    "week-12": "Goal achieved, mastery demonstrated"
  },
  "created_at": "$(date -I)",
  "updated_at": "$(date -I)",
  "metadata": {
    "last_updated": "$(date -I)",
    "pacing": "balanced",
    "total_hours_estimated": 40
  }
}
ROADMAP

echo ""
echo "✅ **Roadmap Generated!**"
echo ""
echo "Saved to: ./roadmap.json"
`

---

## Roadmap Summary

!`echo "📋 **Your Learning Path**"
echo ""
echo "**Goal**: $(jq -r '.primary_goal' ./roadmap.json)"
echo "**Timeline**: 12 weeks"
echo "**Total Estimated Effort**: $(jq -r '.metadata.total_hours_estimated' ./roadmap.json) hours"
echo ""
echo "**Phase Breakdown**:"
jq -r '.phases | to_entries[] | "Phase \(.key): \(.value.name) (Weeks \(.value.weeks)) - \(.value.focus)"' ./roadmap.json
echo ""
echo "**First Topic**: $(jq -r '.topics["topic-1-1"].name' ./roadmap.json)"
echo "**Ready to start!**"
`

---

## Pacing Assessment

Based on your time commitment:

**Your capacity**:
- Daily: !`get_profile_field "time_commitment.daily_minutes"` min/day = !`echo "$(get_profile_field 'time_commitment.daily_minutes') * 7 / 60" | bc` hours/week minimum
- Weekly deep dives: !`get_profile_field "time_commitment.weekly_hours"` hours/week

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
