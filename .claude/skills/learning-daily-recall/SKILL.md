---
name: learning-daily-recall
description: 5-15 minute daily retrieval stress session. System suggests overdue topics or specify your own. Forces recall before showing information.
disable-model-invocation: false
argument-hint: "[optional-topic]"
---

# Daily Recall - Retrieval Practice

Quick retrieval stress session (5-15 minutes).

**Topic**: ${1:-auto}

---

## Phase 1: Determine Topic

!`bash ./.claude/scripts/determine-topic.sh daily-recall "$1"`

---

## Phase 2: Retrieval Stress Test

### 🎯 Retrieval Challenge: [Topic Name]

**IMPORTANT**: Do NOT look at any references, code, notes, or documentation!

I'm going to test your recall of **[topic]** from memory.

### Questions (Adapt based on domain):

**For Code/Technical Topics**:
1. Without looking at the code, explain what [topic] does
2. Walk me through the key components/functions
3. What are the edge cases or gotchas?
4. How does it integrate with other parts of the system?

**For QA/Testing Topics**:
1. Explain [concept] without looking at notes
2. What are the key components/strategies?
3. When would you use this vs alternatives?
4. What are the trade-offs?

**For Writing Topics**:
1. Describe [technique] and when to use it
2. Give me examples (without looking them up)
3. Why is this effective?
4. What are common mistakes?

**For Architecture Topics**:
1. Explain [pattern] like I've never heard of it
2. What problems does it solve?
3. What are the trade-offs?
4. When would you NOT use this?

**For Security Topics**:
1. What are the components of [framework/threat]?
2. How would you apply it to [scenario]?
3. What does it protect against?
4. What are its limitations?

---

### Probe Deeper

After initial explanation, challenge with:
- "Why do you think that?"
- "Are you sure?"
- "What about [edge case]?"
- "How is this different from [related concept]?"

---

## Phase 3: Revelation & Comparison

### 📖 Ground Truth

*Now show the actual information:*

**For code**: Display the actual file/documentation
**For concepts**: Show the authoritative reference

### Compare Mental Model to Reality

- What did you get right?
- What was different from your explanation?
- What surprised you?
- What did you completely miss?

---

## Phase 4: Evaluation & Scheduling

### Score Recall (0-10)

Based on accuracy and completeness:
- **9-10**: Complete and accurate recall
- **7-8**: Mostly correct, minor gaps
- **5-6**: Partial recall, some gaps
- **3-4**: Significant gaps
- **0-2**: Couldn't recall much

**Your Score**: [X/10]

### Gaps Identified

1. **[Specific gap]**: [What was missing]
   - Priority: High/Medium/Low
   - How to fill: [Specific action]

2. **[Another gap]**: [Description]
   ...

### Next Steps

!`# Save to spaced repetition
SCORE=[score from evaluation]
NOTES="[brief summary of gaps]"

bash ./.claude/scripts/save-state.sh spaced-rep "$TOPIC" "$SCORE" "$NOTES"

# Append to learning log
LOG_ENTRY=$(cat <<EOF
{
  "timestamp": "$(date -Iseconds)",
  "type": "daily-recall",
  "topic": "$TOPIC",
  "score": $SCORE,
  "duration_minutes": [estimated],
  "strengths": ["[what you got right]"],
  "gaps": ["[what was missing]"],
  "next_review": "$(date -I -d "+$(jq -r --arg topic "$TOPIC" '.topics[$topic].intervals[-1] // 1' ./.spaced-repetition.json) days")"
}
EOF
)

bash ./.claude/scripts/save-state.sh log "$LOG_ENTRY"
`

---

## Summary

### ✅ Daily Recall Complete

**Topic**: [topic name]
**Score**: [X/10] - [Category: Mastery/Strong/Good/Moderate/Weak]

**Key Strengths**:
- [Specific strength]
- [Another strength]

**Focus Areas**:
1. [Gap with specific action]
2. [Another gap]

**Next Review**: !`bash -c 'jq -r --arg topic "$TOPIC" ".topics[\$topic].next_review" ./.spaced-repetition.json'` ([N] days)

---

### Recommended Actions

**If score < 6**:
💡 **Quick Win**: [Specific 5-minute action to address biggest gap]
Consider: `/learning-weekly-dive "[topic]"` for deeper understanding

**If score 7-8**:
✅ Solid recall! Keep up the daily practice.

**If score 9-10**:
🎉 Excellent! Consider applying to real work: `/learning-apply-to-work`

---

**What would you like to do next?**
1. Another recall: `/learning-daily-recall`
2. Deep dive: `/learning-weekly-dive`
3. That's it for today!
