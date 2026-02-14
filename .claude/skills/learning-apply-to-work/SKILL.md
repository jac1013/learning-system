---
name: learning-apply-to-work
description: Apply learned concepts to real work (code PRs, writing, QA, architecture, security). Pre-application recall test + post-application review. System infers work type or specify with --type=<type> --target=<target>.
disable-model-invocation: false
argument-hint: "[--type=code-pr|writing|qa|architecture|security] [--target=<identifier>]"
---

# Apply to Work - Real-World Learning Anchoring

Apply learned concepts to actual work tasks.

**Arguments**: ${@:-auto}

---

## Phase 1: Determine Work Type & Topics

!`bash ./.claude/scripts/learning/parse-apply-args.sh "$@"`

---

## Phase 2: Pre-Application Recall Test (5-10 min)

### 🎯 Pre-Application Recall

**Before you start working, test your recall of relevant concepts.**

For each applicable topic, quickly recall:

**Without looking at references**:
1. What is [concept]?
2. When do you use it?
3. How do you apply it?
4. What are common mistakes?

**Quick scoring** (for each topic):
- 7-10: Strong recall, ready to apply
- 4-6: Shaky, quick refresh recommended
- 0-3: Weak, study before applying

---

### Refresh if Needed

**If any topic scores < 7**:

Quick 5-minute refresh:
- Re-read key documentation
- Review your learning log entry
- Check synthesis doc if exists

Then re-test recall before proceeding.

---

## Phase 3: Predict Application (3-5 min)

### 🔮 Prediction Challenge

**Before starting work, predict:**

1. **Where will you apply [concepts]?**
   - Specific locations/scenarios
   - What patterns to look for

2. **What challenges do you anticipate?**
   - What might be difficult
   - What you're uncertain about

3. **What will success look like?**
   - Measurable outcomes
   - How you'll know you applied it correctly

---

## Phase 4: Execute Work (Varies by Type)

### Work-Specific Guidance

#### For `--type=code-pr`:

**As you review the PR**:
- [ ] Check for patterns you've learned
- [ ] Look for opportunities to apply concepts
- [ ] Note where concepts were already applied
- [ ] Identify where concepts should be applied but aren't

**Track**:
- Which concepts you recognized
- Which issues you identified using learned knowledge
- What you missed that you should have caught

---

#### For `--type=writing`:

**As you write/edit**:
- [ ] Apply writing techniques learned
- [ ] Check for patterns (active voice, parallel structure, etc.)
- [ ] Use frameworks/structures learned
- [ ] Apply clarity principles

**Track**:
- Which techniques you successfully applied
- Where you applied them
- Before/after examples
- What was difficult

---

#### For `--type=qa`:

**As you test**:
- [ ] Apply testing strategies learned
- [ ] Use test design techniques
- [ ] Follow frameworks (test pyramid, etc.)
- [ ] Apply edge case identification

**Track**:
- Which strategies you used
- How effective they were
- Edge cases you identified
- What you missed

---

#### For `--type=architecture`:

**As you make decisions**:
- [ ] Compare patterns learned
- [ ] Analyze trade-offs explicitly
- [ ] Use decision frameworks
- [ ] Consider alternatives

**Track**:
- Which patterns you considered
- How you chose between alternatives
- Trade-offs you identified
- Decision rationale

---

#### For `--type=security`:

**As you review**:
- [ ] Apply threat modeling frameworks (STRIDE, etc.)
- [ ] Check for vulnerabilities learned
- [ ] Verify mitigations
- [ ] Assess risks

**Track**:
- Which threats you identified
- Which frameworks you used
- Vulnerabilities found
- What you missed

---

## Phase 5: Post-Application Review (5-10 min)

### 🔍 Reality Check: Prediction vs Actual

**What You Predicted**:
[Your predictions from Phase 3]

**What Actually Happened**:
[Actual experience during work]

**Surprises**:
[What you didn't expect]

**Challenges Encountered**:
[Difficulties you faced]

---

### Successfully Applied

For each concept you applied:

**Concept**: [Name]
**Applied at**: [Specific location/context]
**How**: [What you did]
**Outcome**: [Result]
**Confidence**: High / Medium / Low

---

### Struggled With

For each concept you struggled to apply:

**Concept**: [Name]
**Difficulty**: [What went wrong]
**Why hard**: [Reason]
**What you need**: [To improve]

---

## Phase 6: Update State & Schedule

### 📊 Application Scores

*For each applied topic, ask the user for a score (0-10), then execute:*

```bash
bash ./.claude/scripts/learning/save-state.sh spaced-rep "$TOPIC" "$SCORE" "Applied to $WORK_TYPE: $TARGET"
```

*After scoring all topics, log the session:*

```bash
bash ./.claude/scripts/learning/save-state.sh log "$LOG_ENTRY"
```

*Where `$LOG_ENTRY` is a JSON object with: timestamp, type "apply-to-work", work_type, target, topics_applied array, duration_minutes, successes array, struggles array, insights array.*

---

## Summary

### ✅ Application Complete

**Work Type**: [code-pr / writing / qa / architecture / security]
**Target**: [identifier]
**Duration**: [X minutes]

**Topics Applied**:
1. **[Topic 1]**: Score [X/10] - [Successfully applied / Struggled]
2. **[Topic 2]**: Score [X/10] - [Result]

**Successes** (7+ scores):
- [Concept successfully applied with outcome]

**Needs Reinforcement** (<7 scores):
- [Concept that needs more practice]

**Key Insights from Application**:
- [What you learned by applying in real context]
- [How real-world differs from theory]

---

### Next Steps

**For successful applications (7+)**:
✅ Knowledge is sticking! Keep applying.
- Next review extended based on success

**For struggles (<7)**:
📚 Consider deeper learning:
- `/learning-weekly-dive "[topic]"` for deeper understanding
- Daily recalls to reinforce

**For strong applications (9+)**:
🎉 Mastery through application!
- Knowledge truly internalized
- Can teach others from real experience

---

### Real-World Learning Evidence

**This is the most powerful form of learning.**

You've proven you can:
✅ Recall concepts in real context
✅ Apply knowledge to actual problems
✅ Make decisions using learned frameworks
✅ Recognize patterns in real code/writing/systems

**Keep applying!** This is how expertise builds.

---

**What would you like to do next?**
1. Apply more: `/learning-apply-to-work --type=<type>`
2. Reinforce weak areas: `/learning-weekly-dive "<topic>"`
3. Continue daily practice: `/learning-daily-recall`
