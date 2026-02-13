---
name: learning-monthly-synthesis
description: 1-2 hour mastery verification session. Reconstruct complete understanding from memory, analyze scenarios, and create synthesis document. For topics with consistent high scores.
disable-model-invocation: false
argument-hint: "[optional-topic]"
context: fork
---

# Monthly Synthesis - Mastery Verification

Complete reconstruction and mastery verification (1-2 hours).

**Topic**: ${1:-auto}

---

## Phase 1: Determine Topic

!`bash ./.claude/scripts/determine-topic.sh monthly-synthesis "$1"`

---

## Phase 2: Reconstruction Challenge (30-45 min)

### 🧠 Reconstruct from Memory

**IMPORTANT**: Close all references, documentation, code, notes!

### Complete Reconstruction

Reconstruct your complete understanding of **[topic]** from memory.

**Depending on domain, reconstruct**:

**For Code/Systems**:
- Complete architecture/design
- Key components and their interactions
- Data flow and control flow
- Edge cases and error handling
- Integration points

**For Frameworks/Concepts**:
- Complete framework structure
- All components and relationships
- When to use each component
- Trade-offs and alternatives
- Real-world application patterns

**For Processes/Methodologies**:
- Complete process flow
- Decision points and criteria
- Tools and techniques
- Common pitfalls
- Success criteria

---

### Probe for Completeness

As you reconstruct, I'll probe:
- "What about [aspect you didn't mention]?"
- "How does [component A] interact with [component B]?"
- "What happens when [edge case]?"
- "Why is [design decision] made this way?"

---

### Compare to Reality

**ONLY AFTER complete reconstruction attempt**, reveal the actual:
- Documentation
- Code
- Framework reference
- Process documentation

### Gap Analysis

- What you reconstructed correctly: [%]
- What you missed: [List]
- What you got wrong: [List]
- What surprised you: [Insights]

---

## Phase 3: Scenario-Based Analysis (20-30 min)

### 🔬 Apply to Real Scenarios

I'll present real-world scenarios. Apply your understanding to analyze them.

**Scenario Types by Domain**:

**Code/Architecture**:
- Production incident: "The system is experiencing [issue]. Explain what's happening and how to fix it."
- Design alternative: "Compare [approach A] vs [approach B] for this use case."
- Performance problem: "This is slow. Analyze why and propose solutions."

**QA/Testing**:
- Bug triage: "Prioritize these 10 bugs. Explain your rationale."
- Test strategy: "Design a testing approach for [feature]."
- Coverage analysis: "What tests are we missing?"

**Writing**:
- Critique: "Analyze this piece. What works? What doesn't?"
- Rewrite: "Improve this paragraph using [technique]."
- Style choice: "Should this be [style A] or [style B]? Why?"

**Security**:
- Threat modeling: "Identify threats for [system]."
- Incident response: "This breach occurred. Explain how and how to prevent."
- Risk assessment: "Prioritize these vulnerabilities."

---

### Scenario Responses

For each scenario:
1. **Analyze** from memory (no references!)
2. **Explain** your reasoning
3. **Predict** outcomes
4. **Compare** alternatives

Then verify against best practices/expert analysis.

---

## Phase 4: Master Teaching (15-20 min)

### 👨‍🏫 Teach to Advanced Learner

Now teach [topic] to me as if I'm an **experienced professional** who wants to learn it properly.

**This is different from weekly teach-back**:
- Assume I know fundamentals
- Focus on nuance and trade-offs
- Explain "why" behind decisions
- Include edge cases and gotchas
- Connect to broader context

I'll ask **challenging questions**:
- "How does this compare to [advanced alternative]?"
- "What are the performance implications?"
- "When have you seen this go wrong?"
- "What's the cutting edge in this area?"

---

## Phase 5: Synthesis Document (10-15 min)

### 📄 Create Synthesis Document

Create a permanent artifact of your understanding:

!`SYNTHESIS_FILE="./synthesis/${TOPIC//\//-}-$(date -I).md"
mkdir -p ./synthesis

cat > "$SYNTHESIS_FILE" <<'SYNTHESIS'
# Synthesis: [Topic Name]

**Date**: $(date -I)
**Mastery Score**: [X/10]
**Review Count**: [N]

---

## Complete Understanding

### Core Concepts
[Your complete reconstruction - what it is, how it works]

### Key Components
[All major components and their relationships]

### Trade-offs & Alternatives
[When to use this vs alternatives, pros/cons]

### Real-World Application
[How you'd apply this in actual work]

---

## Mental Model

### Before This Synthesis
[What you thought you knew]

### After Reconstruction & Scenarios
[Updated understanding, corrections, insights]

### Key Insights Gained
1. [Insight about how it really works]
2. [Insight about when to apply]
3. [Insight about common misconceptions]

---

## Gaps Identified

### What I Missed in Reconstruction
- [Gap 1]: [What was missing]
- [Gap 2]: [What was missing]

### What I Got Wrong
- [Misconception 1]: [What I thought vs reality]
- [Misconception 2]: [Correction]

---

## Scenario Analysis

### Scenario 1: [Description]
**My Analysis**: [Your reasoning]
**Outcome**: [What actually happened / best practice]
**Learning**: [What this taught you]

### Scenario 2: [Description]
...

---

## Application to Real Work

### Where I Can Apply This
1. [Specific work context 1]
2. [Specific work context 2]

### How I'd Use It
[Concrete plan for application]

### Success Criteria
[How I'll know I've applied it well]

---

## Connections to Other Knowledge

### Related Topics
- [Topic A]: [How they connect]
- [Topic B]: [How they connect]

### Builds Foundation For
[What topics this enables you to learn next]

---

## Mastery Evidence

✅ Can reconstruct complete understanding from memory
✅ Can analyze real scenarios using this knowledge
✅ Can teach at advanced level
✅ Can identify edge cases and trade-offs
✅ Can compare to alternatives intelligently

**Status**: [Mastered / Near Mastery / Needs More Work]

---

## Next Steps

- **Maintenance Review**: [Date] (30-day interval)
- **Real-World Application**: [Planned application]
- **Related Topics to Learn**: [Next in roadmap]

SYNTHESIS

echo "Synthesis document created: $SYNTHESIS_FILE"
`

---

## Phase 6: Final Evaluation & Status Update

### 📊 Mastery Score

**Reconstruction Accuracy**: [X%]
**Scenario Analysis**: [Strong/Moderate/Weak]
**Advanced Teaching**: [Score 0-10]

**Overall Mastery Score**: [0-10]

**Scoring**:
- **9-10**: Complete mastery - Can teach, apply, innovate
- **7-8**: Strong mastery - Can apply confidently
- **5-6**: Partial mastery - Needs more practice
- **0-4**: Not ready - More learning needed

---

### Update State

!`# Save mastery score
MASTERY_SCORE=[score]
NOTES="Synthesis complete. Reconstruction: [X%]. Scenarios: [result]."

bash ./.claude/scripts/save-state.sh spaced-rep "$TOPIC" "$MASTERY_SCORE" "$NOTES"

# Mark as synthesized
jq --arg topic "$TOPIC" '.topics[$topic].synthesized = true | .topics[$topic].synthesis_date = "'$(date -I)'"' \
   ./.spaced-repetition.json > /tmp/sr.json && mv /tmp/sr.json ./.spaced-repetition.json

# Update roadmap to mastered
bash ./.claude/scripts/save-state.sh roadmap "$TOPIC" "mastered"

# Log synthesis session
LOG_ENTRY=$(cat <<EOF
{
  "timestamp": "$(date -Iseconds)",
  "type": "monthly-synthesis",
  "topic": "$TOPIC",
  "mastery_score": $MASTERY_SCORE,
  "reconstruction_accuracy": [percentage],
  "duration_minutes": [estimated],
  "synthesis_document": "$SYNTHESIS_FILE",
  "status": "mastered",
  "next_review": "$(date -I -d "+30 days")"
}
EOF
)
bash ./.claude/scripts/save-state.sh log "$LOG_ENTRY"
`

---

## Summary

### 🎓 Monthly Synthesis Complete

**Topic**: [topic name]
**Mastery Score**: [X/10]
**Status**: [Mastered / Near Mastery / Needs Work]

**Reconstruction**: [X%] accurate
**Scenarios**: [Strong/Moderate/Weak] analysis
**Teaching**: [X/10] advanced explanation

**Synthesis Document**: !`bash -c 'echo $SYNTHESIS_FILE'`

**Key Achievement**:
[What you can now do that you couldn't before]

**Next Steps**:
- **Maintenance Review**: 30 days (!`bash -c 'date -I -d "+30 days"'`)
- **Application**: [Planned real-world use]
- **Next Topic**: [From roadmap]

---

### Celebration! 🎉

**You've achieved mastery of [topic]!**

This means:
✅ You can reconstruct complete understanding
✅ You can analyze real scenarios
✅ You can teach at advanced level
✅ You're ready to apply confidently

**Recommended**:
1. Apply to real work: `/learning-apply-to-work`
2. Help others learn this topic (teaching deepens mastery)
3. Move to next roadmap topic: `/learning-weekly-dive`

---

**What would you like to do next?**
1. Apply to work: `/learning-apply-to-work`
2. Next topic: `/learning-weekly-dive`
3. Celebrate and rest! 🎊
