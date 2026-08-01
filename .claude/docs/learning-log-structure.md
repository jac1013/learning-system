# Learning Log Structure

This document defines the structured format for `learning-log.jsonl` to enable automated analysis and prevent duplicate learning.

## File Format: `learning-log.jsonl`

The learning log is a **JSONL** (JSON Lines) file — one JSON object per line, appended after each session. This format is machine-parseable by `jq` and supports append-only writes without parsing the entire file.

### Entry Schema

Each line is a JSON object with these fields:

```json
{
  "timestamp": "2026-02-01T08:00:00Z",
  "type": "daily-recall",
  "practice_type": "knowledge",
  "topic": "observability-fundamentals",
  "topic_name": "Observability Fundamentals",
  "score": 7,
  "duration_minutes": 15,
  "strengths": [
    "Named all three pillars correctly",
    "Explained use cases well"
  ],
  "gaps": [
    "Distributed tracing mechanics (trace ID vs span ID)",
    "Formal metric types (Counter, Gauge, Histogram, Summary)"
  ],
  "next_review": "2026-02-08",
  "notes": "Baseline assessment - stronger than self-assessed"
}
```

### Required Fields

| Field | Type | Description |
|---|---|---|
| `timestamp` | ISO 8601 | When the session occurred |
| `type` | string | Workflow, such as `daily-recall`, `performance-practice`, or `apply-to-work` |
| `practice_type` | string | `knowledge`, `performance`, or `application` |
| `duration_minutes` | number | Session length |

### Optional Fields

| Field | Type | Description |
|---|---|---|
| `topic_name` | string | Human-readable topic name |
| `topic` | string | Topic key or name; may be absent for multi-topic application sessions |
| `score` | number | 0-10 recall score for knowledge-practice workflows |
| `strengths` | string[] | What was recalled well |
| `gaps` | string[] | What was missed or weak |
| `next_review` | date string | Scheduled next review date |
| `notes` | string | Free-form session notes |

Workflow-specific fields are allowed and encouraged. A performance-practice entry normally includes `scenario`, `mode`, `timebox_minutes`, the frozen `rubric`, an `attempts` array with criterion-level scores and evidence, `self_assessment`, `baseline_score`, `final_score`, `score_delta`, `completed_loops`, `improvement_target`, and an artifact reference. An application entry normally includes `work_type`, `target`, and `topics_applied`.

Performance scores must not be written to `.spaced-repetition.json`: execution quality and memory recall are different measurements.

### `quiz` Entries

Written by `/learning-quiz`. `practice_type` is `knowledge`.

| Field | Type | Description |
|---|---|---|
| `mode` | string | `practice` or `exam` |
| `topic` | string | Topic key or name; `all` for a mixed exam |
| `questions_total` | number | Questions served |
| `questions_correct` | number | Correct answers; multi-select is all-or-nothing |
| `score` | number | 0-10 integer form of `score_percent`, for consistency with other workflows |
| `score_percent` | number | 0-100 |
| `passed` | boolean | Exam mode only — whether `score_percent >= threshold` |
| `threshold` | number | Exam mode only — pass percentage, default 72 |
| `timebox_minutes` | number | Exam mode only — the declared exam timebox, not the measured duration |
| `by_difficulty` | object | Keyed by `recall`/`application`/`analysis`, each `{correct, total}` |
| `missed` | object[] | `{question_id, picked, correct, concept}` per miss |
| `cards_created` | number | Flashcards generated from misses |

Quiz scores must not be written to `.spaced-repetition.json`: discrimination under multiple choice and free recall are different measurements, and a standalone quiz would otherwise shift a topic's review interval on recognition evidence alone. Inside a weekly dive the quiz result instead informs the **Accuracy** dimension of that session's teach-back score, and appears as a `quiz` sub-object (`{questions_total, questions_correct, score_percent}`) on the `weekly-dive` entry rather than as its own log line.

Per-question statistics live in `.quiz-bank.json`, not in the log. The log records what happened in the session; the bank records what to serve next.

## Writing Entries

Entries are appended by `save-state.sh`:

```bash
bash ./.claude/scripts/learning/save-state.sh log "$LOG_ENTRY"
```

Where `$LOG_ENTRY` is a JSON object with the fields above.

**Important**: This file is append-only. Never overwrite or truncate it.

## Reading Entries

Query the log with `jq`:

```bash
# All sessions for a topic
jq -c 'select(.topic == "observability-fundamentals")' learning-log.jsonl

# Average score across all sessions
jq -s '[.[].score] | add / length' learning-log.jsonl

# Sessions this week
jq -c --arg since "2026-02-10" 'select(.timestamp >= $since)' learning-log.jsonl

# Count sessions by type
jq -s 'group_by(.type) | map({type: .[0].type, count: length})' learning-log.jsonl
```

## Benefits of JSONL

1. **Append-only**: New entries don't require reading/parsing existing data
2. **Machine-parseable**: `jq` queries for analysis, filtering, aggregation
3. **Line-oriented**: Easy to count entries (`wc -l`), tail recent ones (`tail -5`)
4. **No corruption risk**: Writing one line is atomic; partial writes don't corrupt existing data
5. **Integration**: Scripts (`infer-next.sh`, `save-state.sh`) can read/write programmatically

## Integration with System

### Save State (`save-state.sh`)
- Appends new entry after each session
- Called by skills in Phase 4 (Evaluation & Scheduling)

### Infer Next (`infer-next.sh`)
- Reads `.spaced-repetition.json` (not the log directly) for scheduling
- The log serves as audit trail and analysis source

### Context Analysis
- Recent entries inform topic suggestions
- Score trends identify struggling vs mastered topics
- Duration data helps adjust pacing estimates
