---
name: learning-weekly-dive
description: 30-60 minute deep dive using Socratic questioning and teach-back. System suggests next roadmap topic or specify your own. Builds deep understanding through challenge.
disable-model-invocation: false
argument-hint: "[optional-topic]"
context: fork
---

# Weekly Dive - Deep Socratic Learning

Deep exploration session (30-60 minutes) using Socratic method and teach-back.

**Topic**: ${1:-auto}

---

## Phase 1: Determine Topic

!`source ./.claude/plugins/local/learning-science/helpers/load-state.sh`

!`if [[ -n "$1" ]]; then
    echo "📚 Topic specified: $1"
    TOPIC="$1"
else
    echo "🔍 Analyzing roadmap and learning state..."
    TOPIC=$(source ./.claude/plugins/local/learning-science/helpers/infer-next.sh weekly-dive)

    if [[ "$TOPIC" == "none" ]]; then
        echo "📋 No topics ready in roadmap."
        echo ""
        echo "Options:"
        echo "1. Specify a topic: /learning-weekly-dive \"topic name\""
        echo "2. Update roadmap: Edit ./roadmap.json"
        echo "3. Review a weak topic from past sessions"
        exit 0
    fi

    echo "📖 **Suggested Topic**: $TOPIC"
    echo ""
    echo "**Why this topic?**"
    echo "Next in your roadmap sequence (prerequisites met)"
    echo ""
    echo "Ready for a deep dive? (yes/no, or specify different topic)"
fi`

---

## Phase 2: Socratic Interrogation (15-20 min)

### 🎓 Teach Me: [Topic Name]

I'm going to learn about **[topic]** from YOU. You're the teacher, I'm the student.

**Your task**: Explain [topic] to me like I'm completely new to it.

Take your time. Be thorough. Teach me everything you know.

---

### Socratic Ladder (I'll challenge you)

After your explanation, I'll probe deeper with questions:

**Level 1 - Surface**: "Why does it work that way?"

**Level 2 - Mechanism**: "What's the alternative approach?"

**Level 3 - Trade-offs**: "When would you choose one over the other?"

**Level 4 - Boundaries**: "When would you NOT use this?"

**Level 5 - Integration**: "How does this relate to [related concept]?"

---

### Challenge Assumptions

As you teach, I'll challenge with:
- "Are you sure it's ONLY for [reason]?"
- "What if [edge case]?"
- "Could there be another explanation?"
- "What are you assuming that might not be true?"

---

## Phase 3: Gap Identification & Targeted Learning (15-25 min)

### 🔍 Socratic Assessment Complete

Based on your teaching, I've identified:

**Strong Understanding** (you explained well):
- [Aspect 1]: Clear explanation with examples
- [Aspect 2]: Identified trade-offs accurately

**Gaps to Fill** (areas needing more depth):
1. **[Gap 1]** (Priority: High)
   - What's missing: [Specific concept/detail]
   - Why it matters: [Importance]
   - Where to learn: [Specific resource/section]

2. **[Gap 2]** (Priority: Medium)
   - What's missing: [Description]
   - Where to learn: [Resource]

---

### Targeted Study (Fill the Gaps)

For each high-priority gap:

**Read/Study**: [Specific section of documentation/article]

After reading, apply the new knowledge:
- **Summarize** in your own words
- **Give examples** (code/scenarios)
- **Contrast** with what you thought before
- **Predict** when you'd use it

---

## Phase 4: Teach-Back Verification (10-15 min)

### 🎯 Teach-Back Challenge

Now teach me [topic] again, incorporating what you just learned.

**Important**: Do this WITHOUT looking at notes or references!

I'm a [junior developer / new learner / mid-level engineer - adjust based on profile].

**I'll ask clarifying questions**:
- "I don't understand [aspect]. Can you explain differently?"
- "Why do we need [component]? Can't we just [naive alternative]?"
- "When would I use this in real work?"
- "How is this different from [similar concept]?"

---

### Teach-Back Evaluation

**Scoring (0-10 on each dimension)**:

**Clarity** (Can a beginner understand?):
- 10: Could teach complete beginner
- 7-8: Mostly clear
- 5-6: Requires prior knowledge
- 0-4: Hard to follow

**Accuracy** (Is it correct?):
- 10: Completely correct
- 7-8: Mostly correct, minor inaccuracies
- 5-6: Some errors
- 0-4: Many errors

**Depth** (Do you explain "why"?):
- 10: Explains why, trade-offs, alternatives
- 7-8: Explains some reasoning
- 5-6: Mostly "what" not "why"
- 0-4: Surface-level only

**Completeness** (Do you cover key aspects?):
- 10: Covers all major components
- 7-8: Minor omissions
- 5-6: Missing important aspects
- 0-4: Major gaps

**Overall Score**: Average of 4 dimensions

---

## Phase 5: Document & Schedule (5 min)

### 📊 Teach-Back Results

**Overall Score**: [X/10] - [Mastery/Strong/Good/Moderate/Weak]

**Dimensional Scores**:
- Clarity: [X/10] - [Comment]
- Accuracy: [X/10] - [Comment]
- Depth: [X/10] - [Comment]
- Completeness: [X/10] - [Comment]

**What You Explained Well**:
- [Specific strength with example]
- [Another strength]

**What to Improve**:
1. **[Dimension]**: [Specific issue]
   - Example: [From their teaching]
   - Better: [How to improve]

2. **[Dimension]**: [Issue]
   ...

---

### Save Results

!`# Calculate overall score
CLARITY_SCORE=[score]
ACCURACY_SCORE=[score]
DEPTH_SCORE=[score]
COMPLETENESS_SCORE=[score]
OVERALL_SCORE=$(echo "scale=0; ($CLARITY_SCORE + $ACCURACY_SCORE + $DEPTH_SCORE + $COMPLETENESS_SCORE) / 4" | bc)

# Save to spaced repetition
NOTES="Teach-back: C:$CLARITY_SCORE A:$ACCURACY_SCORE D:$DEPTH_SCORE Cm:$COMPLETENESS_SCORE"
source ./.claude/plugins/local/learning-science/helpers/save-state.sh spaced-rep "$TOPIC" "$OVERALL_SCORE" "$NOTES"

# Update roadmap status
source ./.claude/plugins/local/learning-science/helpers/save-state.sh roadmap "$TOPIC" "completed"

# Append to learning log
LOG_ENTRY=$(cat <<EOF
{
  "timestamp": "$(date -Iseconds)",
  "type": "weekly-dive",
  "topic": "$TOPIC",
  "overall_score": $OVERALL_SCORE,
  "scores": {
    "clarity": $CLARITY_SCORE,
    "accuracy": $ACCURACY_SCORE,
    "depth": $DEPTH_SCORE,
    "completeness": $COMPLETENESS_SCORE
  },
  "duration_minutes": [estimated],
  "strengths": ["[what explained well]"],
  "gaps": ["[what to improve]"],
  "next_review": "$(date -I -d "+$(jq -r --arg topic "$TOPIC" '.topics[$topic].intervals[-1] // 3' ./.spaced-repetition.json) days")"
}
EOF
)
source ./.claude/plugins/local/learning-science/helpers/save-state.sh log "$LOG_ENTRY"
`

---

## Summary

### ✅ Weekly Dive Complete

**Topic**: [topic name]
**Duration**: [X minutes]
**Teach-Back Score**: [X/10]

**Key Insights Gained**:
- [Insight 1 - connection or realization]
- [Insight 2]

**Strong Areas**:
- [What you mastered]

**Still Unclear**:
- [What needs more work]

**Next Actions**:
- **Next Review**: !`jq -r --arg topic "$TOPIC" '.topics[$topic].next_review' ./.spaced-repetition.json` ([N] days)
- **Recommended**: [Specific next step based on score]

---

### Recommended Follow-Up

**If score < 6**:
📚 Schedule another weekly dive: `/learning-weekly-dive "[topic]"`
Consider breaking into smaller sub-topics

**If score 7-8**:
✅ Good understanding! Reinforce with:
- Daily recall in a few days
- Application opportunity when available

**If score 9-10**:
🎉 Excellent mastery! Next steps:
- Apply to real work: `/learning-apply-to-work`
- Move to next topic: `/learning-weekly-dive`
- Consider monthly synthesis when ready

---

**What would you like to do next?**
1. Next topic: `/learning-weekly-dive`
2. Apply this: `/learning-apply-to-work`
3. That's enough for today!
