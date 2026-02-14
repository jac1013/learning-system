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

!`bash ./.claude/scripts/learning/determine-topic.sh monthly-synthesis "$1"`

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

*Create a synthesis document at `./synthesis/[topic]-[date].md` using the Write tool. The document should contain:*

- Core Concepts, Key Components, Trade-offs & Alternatives, Real-World Application
- Mental Model (before/after synthesis, key insights)
- Gaps Identified (what was missed, what was wrong)
- Scenario Analysis (each scenario with analysis, outcome, learning)
- Application to Real Work (where, how, success criteria)
- Connections to Other Knowledge (related topics, builds foundation for)
- Mastery Evidence checklist
- Next Steps (maintenance review date, real-world application, related topics)

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

*Execute the following, replacing placeholders with actual values from the session:*

```bash
bash ./.claude/scripts/learning/save-state.sh spaced-rep "$TOPIC" "$MASTERY_SCORE" "$NOTES"
```

*Mark as synthesized in `.spaced-repetition.json` (set `synthesized: true` and `synthesis_date` for the topic).*

```bash
bash ./.claude/scripts/learning/save-state.sh roadmap "$TOPIC" "mastered"
```

```bash
bash ./.claude/scripts/learning/save-state.sh log "$LOG_ENTRY"
```

*Where `$LOG_ENTRY` is a JSON object with: timestamp, type "monthly-synthesis", topic, mastery_score, reconstruction_accuracy, duration_minutes, synthesis_document path, status "mastered", next_review (30 days from today).*

---

## Summary

### 🎓 Monthly Synthesis Complete

**Topic**: [topic name]
**Mastery Score**: [X/10]
**Status**: [Mastered / Near Mastery / Needs Work]

**Reconstruction**: [X%] accurate
**Scenarios**: [Strong/Moderate/Weak] analysis
**Teaching**: [X/10] advanced explanation

**Synthesis Document**: [path from synthesis creation output]

**Key Achievement**:
[What you can now do that you couldn't before]

**Next Steps**:
- **Maintenance Review**: 30 days from today
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
