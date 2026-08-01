---
name: learning-performance-practice
description: Practice performing a learned skill under realistic constraints. Runs an unassisted baseline, scores observable behavior against a precommitted rubric, and repeats one focused improvement. Suitable for interviews, presentations, role-play, design exercises, demonstrations, and other executable skills.
disable-model-invocation: false
argument-hint: "[optional-topic]"
context: fork
---

# Performance Practice - Deliberate Practice Under Constraints

Practice doing a skill, not merely explaining what you know about it. The session produces observable evidence, rubric scores, and a focused retry.

**Topic**: $ARGUMENTS

---

## Phase 1: Determine Topic

!`bash ./.claude/scripts/learning/session-track.sh start learning-performance-practice "$ARGUMENTS"`

!`bash ./.claude/scripts/learning/determine-topic.sh performance-practice "$ARGUMENTS"`

If the helper returns `TOPIC=none`, stop the workflow after presenting its options. End the timer with `bash ./.claude/scripts/learning/session-track.sh end`. Do not invent progress or log a completed practice session.

If `PERFORMANCE_ACTIVITY_JSON` is present, treat it as the roadmap's proposed contract. The learner may adjust it before the first attempt.

---

## Phase 2: Freeze the Performance Contract

Before any coaching or attempt, propose a compact performance contract and ask the learner to confirm or edit it. Derive it from the roadmap activity when available; otherwise derive it from the topic, learner profile, and goal.

The contract must contain:

1. **Scenario** - a concrete situation with a clear starting state
2. **Observable output** - what the learner must say, write, decide, draw, demonstrate, or deliver
3. **Mode** - choose one:
   - `live-role-play`: Claude acts as the interviewer, customer, stakeholder, examiner, or other counterpart
   - `single-response`: the learner completes the performance in one uninterrupted response
   - `external`: the learner performs outside the chat and returns with an artifact or concise evidence summary
4. **Constraints** - time, information, tools, audience, format, and any prohibited assistance
5. **Timebox** - normally 5-60 minutes; use the roadmap value when provided
6. **Success threshold** - the minimum overall score or required criteria
7. **Rubric** - 3-5 observable criteria, each scored 0-10

Use domain-relevant criteria. Do not default to vague traits such as "confidence" or "quality." Every criterion must describe behavior or an inspectable result.

For each criterion, define four anchors before the attempt:

- **0-3**: ineffective or missing behavior
- **4-6**: partial behavior with material gaps
- **7-8**: effective behavior with minor gaps
- **9-10**: precise, adaptive, and complete behavior

Do not change the rubric after seeing the attempt. If the contract itself proves invalid, record that separately and use the corrected contract only for a new attempt.

Wait for confirmation before continuing.

If the learner declines or cancels before making an attempt, end the timer with `bash ./.claude/scripts/learning/session-track.sh end` and do not log a completed practice session.

---

## Phase 3: Pre-Performance Retrieval

Ask the learner, without showing a model answer:

1. What approach will you use?
2. What are the two or three principles you must remember?
3. Where are you most likely to fail under these constraints?
4. What will you do if the scenario changes?

Keep this brief. It activates useful knowledge but is not the scored performance.

Do not correct the learner yet unless proceeding would be unsafe. Record misconceptions for feedback after the baseline.

---

## Phase 4: Baseline Attempt

Run one unassisted attempt under the frozen contract.

### `live-role-play`

- State the role Claude will play and the opening situation.
- Ask the learner to say `begin` when ready.
- Stay in role until the learner ends the attempt or the scenario reaches its natural conclusion.
- Introduce only realistic reactions or complications. Do not coach, hint, score, or rescue during the attempt.

### `single-response`

- Present the complete prompt and constraints once.
- Ask for one uninterrupted response.
- Do not give hints or partial feedback before the response is complete.

### `external`

- Restate the expected artifact or evidence.
- Ask the learner to perform the task and return with one of: a file path, transcript, notes, recording reference, or concise evidence summary.
- Inspect an accessible artifact when possible. Clearly state when scoring relies only on the learner's summary.

The session timer measures total practice time. Track the contract's attempt timebox separately as `timebox_minutes` in the log.

---

## Phase 5: Self-Assessment Before Feedback

Before revealing Claude's evaluation, ask the learner:

1. What went well?
2. Where did performance break down?
3. Which rubric criterion was strongest and weakest?
4. What would you change on another attempt?

This calibration step is required. Keep the learner's self-assessment distinct from Claude's score.

---

## Phase 6: Evidence-Based Evaluation

Score the baseline against the frozen rubric.

For every criterion, report:

- **Score**: 0-10
- **Evidence**: a specific observed behavior or artifact detail
- **Gap**: what kept the score from the next band

Calculate the overall score as the arithmetic mean unless the roadmap explicitly provides weights. If weights exist, show the weighted calculation.

Then report:

- Baseline overall score
- Whether the success threshold was met
- 1-3 demonstrated strengths
- 1-3 performance gaps
- Calibration difference between self-assessment and observed evidence

Evaluate only what was observable. Do not infer hidden competence, intent, personality, or confidence from style alone.

---

## Phase 7: Focused Deliberate-Practice Loop

Select exactly one improvement target with the highest expected impact. Prefer a narrow behavior that can change in the current session.

1. Explain the target and why it matters.
2. Give concise corrective instruction or one short model.
3. Create a smaller 5-15 minute drill that isolates the target.
4. Add one realistic variation so the learner cannot merely repeat wording.
5. Run the retry without coaching during the attempt.
6. Rescore the relevant criterion and, when comparable, the complete rubric.
7. Show the score delta and the specific behavior that changed.

If the learner declines or cannot complete the retry, preserve the baseline result and log `completed_loops` as `0`.

One focused retry is the default. Run another loop only when the learner requests it or the first retry was invalidated by a misunderstood instruction or broken scenario.

---

## Phase 8: Save Evidence

Performance quality is not a recall score. **Do not call `save-state.sh spaced-rep` from this skill.** Recall scheduling remains owned by knowledge-practice workflows.

Store a reference or concise summary of the artifact by default, not a full sensitive transcript. Ask before persisting extensive raw content.

Log the session:

```bash
bash ./.claude/scripts/learning/save-state.sh log "$LOG_ENTRY"
```

`$LOG_ENTRY` must be a JSON object with:

```json
{
  "type": "performance-practice",
  "practice_type": "performance",
  "topic": "topic-key-or-name",
  "scenario": "concrete scenario",
  "mode": "live-role-play|single-response|external",
  "timebox_minutes": 30,
  "success_threshold": 7,
  "rubric": [
    {
      "criterion": "observable criterion",
      "anchors": {
        "0-3": "ineffective or missing behavior",
        "4-6": "partial behavior with material gaps",
        "7-8": "effective behavior with minor gaps",
        "9-10": "precise, adaptive, and complete behavior"
      }
    }
  ],
  "attempts": [
    {
      "attempt": 1,
      "kind": "baseline",
      "overall_score": 6.5,
      "criterion_scores": [
        {
          "criterion": "observable criterion",
          "score": 6,
          "evidence": "specific observed evidence",
          "gap": "behavior needed to reach the next band"
        }
      ]
    },
    {
      "attempt": 2,
      "kind": "focused-retry",
      "overall_score": 7.5,
      "criterion_scores": [
        {
          "criterion": "observable criterion",
          "score": 8,
          "evidence": "specific changed behavior",
          "gap": "remaining behavior needed for the next band"
        }
      ]
    }
  ],
  "self_assessment": {
    "strongest": "learner's assessment",
    "weakest": "learner's assessment",
    "planned_change": "what the learner intended to change"
  },
  "baseline_score": 6.5,
  "final_score": 7.5,
  "score_delta": 1.0,
  "completed_loops": 1,
  "strengths": ["demonstrated behavior"],
  "gaps": ["behavior needing improvement"],
  "improvement_target": "single focused behavior",
  "artifact": {
    "type": "transcript|notes|file|recording|summary|none",
    "reference": "path, identifier, or concise summary"
  },
  "next_practice": "recommended scenario variation and timing"
}
```

Include only attempts that actually occurred. `save-state.sh` adds the timestamp and measured `duration_minutes` automatically.

---

## Summary

Present a compact completion summary:

- Topic and scenario
- Baseline score -> final score
- Strongest demonstrated behavior
- Improvement target and observed change
- Success threshold result
- Next practice recommendation
- Artifact reference, if any

Recommend the next session based on evidence:

- **Below 6**: repeat the isolated skill within 1-2 days
- **6-7.9**: repeat with one new constraint within a week
- **8 or above**: use a meaningfully different scenario within 1-2 weeks

Use `/learning-daily-recall "[topic]"` only when the failure came from missing knowledge. Use `/learning-apply-to-work` when the next step should happen in consequential real work rather than a simulation.
