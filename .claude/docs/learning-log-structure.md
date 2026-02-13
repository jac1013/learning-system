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
| `type` | string | `daily-recall`, `weekly-dive`, `monthly-synthesis`, `apply-to-work` |
| `topic` | string | Topic key (matches `.spaced-repetition.json` keys) |
| `score` | number | 0-10 recall/mastery score |
| `duration_minutes` | number | Session length |

### Optional Fields

| Field | Type | Description |
|---|---|---|
| `topic_name` | string | Human-readable topic name |
| `strengths` | string[] | What was recalled well |
| `gaps` | string[] | What was missed or weak |
| `next_review` | date string | Scheduled next review date |
| `notes` | string | Free-form session notes |

## Writing Entries

Entries are appended by `save-state.sh`:

```bash
bash ./.claude/scripts/save-state.sh log "$LOG_ENTRY"
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
