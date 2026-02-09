# Learning Log Structure

This document defines the structured format for `learning-log.md` to enable automated analysis and prevent duplicate learning.

## File Format: `learning-log.md`

```markdown
# Learning Log

**Owner**: [Learner name from profile]
**Started**: [Date]
**Last Entry**: [Auto-updated]

---

## [YYYY-MM-DD] - [Topic] - [Domain]

**Session Type**: Daily Recall / Weekly Dive / Monthly Synthesis / Apply-to-Work
**Duration**: [X minutes]
**Recall/Mastery Score**: [0-10]
**Status**: ✅ Completed / ⚠️ Needs Review / 🎓 Mastered

### Session Summary
[Brief 1-2 sentence description of what was learned/reviewed]

### What Was Tested/Learned
- [Key concept 1 covered]
- [Key concept 2 covered]
- [Key concept 3 covered]

### Strengths Demonstrated
- [Specific thing you understood well]
- [Another strength with example]

### Gaps Identified
1. **[Gap topic]**: [Specific description]
   - **Priority**: High / Medium / Low
   - **How to fill**: [Specific action or resource]

2. **[Another gap]**: [Description]
   ...

### Insights & Connections
[What you learned about your learning or connections to other topics]

Example: "Realized circuit breakers connect to bulkhead pattern I learned last month. Both are about isolation and resilience."

### Application (if applicable)
- **Applied to**: [Specific work task, PR, document]
- **Outcome**: [What happened when you applied it]
- **Confidence**: High / Medium / Low

### Next Actions
- **Next Review**: [Date - from spaced repetition]
- **Recommended**: [Suggested next step, e.g., "Weekly dive on saga pattern"]

### Tags
`#domain:[code/qa/writing/architecture/security]` `#type:[recall/dive/synthesis/apply]` `#score:[0-10]` `#status:[completed/needs-review/mastered]`

---

## Statistics & Tracking

### Overall Progress
**Total Sessions**: [Auto-count entries]
**Total Hours**: [Sum of all durations]
**Average Score**: [Average of all scores]
**Domains Covered**: [Unique domains]

### This Week
- **Sessions**: [Count this week]
- **Hours**: [Sum this week]
- **Topics**: [List topics covered]

### This Month
- **Sessions**: [Count this month]
- **Hours**: [Sum this month]
- **Topics**: [List topics covered]
- **Mastered**: [List topics that reached mastered status]

### By Domain
| Domain | Sessions | Hours | Avg Score | Topics Covered |
|--------|----------|-------|-----------|----------------|
| Code | [N] | [X.X] | [Y.Y] | [List] |
| QA | [N] | [X.X] | [Y.Y] | [List] |
| Writing | [N] | [X.X] | [Y.Y] | [List] |
| Architecture | [N] | [X.X] | [Y.Y] | [List] |
| Security | [N] | [X.X] | [Y.Y] | [List] |

---

## Archive (Older than 3 months)

[Move older entries here to keep main log focused on recent learning]

---
```

## Entry Examples

### Example 1: Daily Recall Session
```markdown
## 2026-01-29 - Test Pyramid - QA

**Session Type**: Daily Recall
**Duration**: 12 minutes
**Recall Score**: 7/10
**Status**: ✅ Completed

### Session Summary
Reviewed test pyramid structure and proportions. Remembered layers correctly but initially forgot exact proportions.

### What Was Tested
- Three layers of test pyramid (unit, integration, E2E)
- Proportions (70/20/10 guideline)
- Why pyramid shape matters (speed, cost, feedback time)
- When to deviate from pyramid

### Strengths Demonstrated
- Correctly identified all three layers
- Explained speed/cost trade-offs clearly
- Gave good examples of each test type

### Gaps Identified
1. **Exact Proportions**: Hesitated on 70/20/10 vs 80/15/5
   - **Priority**: Low
   - **How to fill**: Not critical—ranges are acceptable

2. **Ice Cream Cone Anti-pattern**: Mentioned it exists but couldn't describe
   - **Priority**: Medium
   - **How to fill**: Quick reference lookup on test anti-patterns

### Insights & Connections
Test pyramid isn't absolute rule—need to consider project context. Connects to cost/benefit analysis.

### Next Actions
- **Next Review**: 2026-02-05 (7 days)
- **Recommended**: Apply-to-work when writing next test suite

### Tags
`#domain:qa` `#type:recall` `#score:7` `#status:completed`

---
```

### Example 2: Weekly Dive Session
```markdown
## 2026-01-28 - Circuit Breakers - Architecture

**Session Type**: Weekly Dive
**Duration**: 45 minutes
**Teach-Back Score**: 8/10
**Status**: ✅ Completed

### Session Summary
Deep dive on circuit breaker pattern. Socratic phase revealed I understood basic mechanism but missed configuration nuances. Teach-back went well after gap filling.

### What Was Learned
- Circuit breaker states (closed, open, half-open)
- Transition logic between states
- Configuration parameters (threshold, timeout, half-open requests)
- Difference from retry pattern
- When to use vs not use

### Strengths Demonstrated
- Clear understanding of state machine
- Good analogy to electrical circuit breakers
- Identified use cases correctly (external service calls)

### Gaps Identified
1. **Configuration Tuning**: Didn't know how to choose threshold values
   - **Priority**: High
   - **How to fill**: Research configuration best practices, look at real examples

2. **Monitoring & Alerts**: Forgot to mention observability aspect
   - **Priority**: High
   - **How to fill**: Study how to monitor circuit breaker states in production

3. **Fallback Strategies**: Mentioned circuit breaker but not what to do when open
   - **Priority**: Medium
   - **How to fill**: Study fallback patterns (cache, default value, degraded mode)

### Insights & Connections
Circuit breaker is about failing fast to prevent cascading failures. Connects to:
- Bulkhead pattern (resource isolation)
- Retry pattern (complementary, not alternative)
- Chaos engineering (testing resilience)

### Application
Plan to review payment service API calls next week to identify circuit breaker candidates.

### Next Actions
- **Next Review**: 2026-02-04 (7 days) - Daily recall
- **Recommended**: Weekly dive on "Fallback Patterns" to complete picture
- **Apply-to-work**: Review payment service resilience in upcoming PR

### Tags
`#domain:architecture` `#type:dive` `#score:8` `#status:completed` `#needs-application`

---
```

### Example 3: Monthly Synthesis Session
```markdown
## 2026-01-27 - Microservices Fundamentals - Architecture

**Session Type**: Monthly Synthesis
**Duration**: 90 minutes
**Mastery Score**: 9/10
**Status**: 🎓 Mastered

### Session Summary
Complete reconstruction of microservices architecture from memory. Successfully explained to "mid-level engineer" persona. Strong scenario analysis. Created synthesis document.

### What Was Synthesized
- Complete microservices architecture (services, API gateway, service mesh, data stores)
- Service boundaries and communication patterns
- Resilience patterns (circuit breaker, bulkhead, retry)
- Data management (database per service, eventual consistency)
- Deployment and observability

### Strengths Demonstrated
- 90% accurate reconstruction without references
- Explained trade-offs clearly (complexity vs autonomy)
- Handled scenario analysis well (incident response, design alternatives)
- Connected to real work (current payment service architecture)

### Gaps Identified
1. **Service Mesh Details**: High-level understanding but fuzzy on sidecar implementation
   - **Priority**: Low (not immediately needed)
   - **How to fill**: Optional deep dive if working with service mesh

### Insights & Connections
Microservices isn't about technology—it's about organizational autonomy. The complexity is justified only when teams are independent and services have clear boundaries.

Key mental model shift: Monolith-first is often right. Microservices is optimization for specific constraints (team size, scaling needs), not a default architecture.

### Application
- Applied to: Current payment service architecture review
- Outcome: Identified 2 services that should merge (unnecessary boundaries)
- Confidence: High

### Synthesis Document
Created: `./synthesis/microservices-fundamentals-2026-01-27.md`

### Next Actions
- **Next Review**: 2026-02-27 (30 days) - Maintenance review
- **Status**: Moved to "Mastered" in roadmap
- **Recommended**: Start Phase 2 (Advanced patterns: CQRS, Event Sourcing)

### Tags
`#domain:architecture` `#type:synthesis` `#score:9` `#status:mastered` `#milestone`

---
```

### Example 4: Apply-to-Work Session
```markdown
## 2026-01-26 - Active Voice - Writing

**Session Type**: Apply-to-Work (Writing)
**Duration**: 35 minutes (10 min recall + 25 min application)
**Application Score**: 8/10
**Status**: ✅ Completed

### Session Summary
Applied active voice technique to API documentation draft. Pre-application recall test went well (score: 8). Successfully converted 12 passive constructions to active voice.

### Pre-Application Recall
- Explained active vs passive voice correctly
- Identified valid passive use cases (actor unknown/irrelevant)
- Gave good examples

### What Was Applied
- Reviewed API documentation draft (3 pages)
- Identified 15 passive voice constructions
- Converted 12 to active voice
- Kept 3 passive (appropriate use cases)

**Examples**:
- "The token is validated by the server" → "The server validates the token"
- "Errors are returned when..." → "The API returns errors when..."
- "The database was accessed" → Left passive (actor irrelevant)

### Strengths Demonstrated
- Confidently identified passive voice
- Made good judgment calls on when to keep passive
- Documentation reads more clearly now

### Gaps/Struggles
1. **Parallel Structure**: Noticed some list items weren't parallel, but not part of today's focus
   - **Action**: Add "parallel structure" to roadmap for future dive

### Insights & Connections
Active voice makes API docs more concrete and actionable. Reader knows "who does what" clearly. This connects to "clarity principle" in technical writing.

### Application Outcome
- **Applied to**: API documentation draft
- **Result**: Documentation approved by tech lead with positive feedback on clarity
- **Confidence**: High
- **Would apply again**: Yes, will check all future docs

### Next Actions
- **Next Review**: 2026-02-09 (14 days) - Extended interval due to successful application
- **Recommended**: Add "parallel structure" to roadmap
- **Application Score**: Affects spaced repetition (8 = strong retention)

### Tags
`#domain:writing` `#type:apply` `#score:8` `#status:completed` `#real-world-success`

---
```

## Parsing Rules for Automation

To enable automated analysis, follow these rules:

### Required Fields
Every entry MUST have:
- Date (YYYY-MM-DD)
- Topic
- Domain
- Session Type
- Duration
- Score (recall/mastery/application)
- Status

### Structured Sections
Use consistent headings:
- `### Session Summary`
- `### What Was Tested/Learned/Synthesized`
- `### Strengths Demonstrated`
- `### Gaps Identified`
- `### Insights & Connections`
- `### Application` (if applicable)
- `### Next Actions`
- `### Tags`

### Tags Format
Always include tags in this format:
```
`#domain:[domain]` `#type:[type]` `#score:[0-10]` `#status:[status]`
```

Optional tags:
- `#needs-review` - Topic needs another review soon
- `#needs-application` - Ready to apply to work
- `#milestone` - Significant achievement
- `#real-world-success` - Successfully applied to work
- `#struggling` - Consistent difficulty with topic

## Benefits of Structure

1. **Prevent Duplicate Learning**: Check log before scheduling topics
2. **Identify Patterns**: What domains you're strong in? What you struggle with?
3. **Track Progress**: Hours spent, scores over time
4. **Optimize Schedule**: Which topics need more attention?
5. **Context for Commands**: Analyzer reads log to suggest topics
6. **Celebrate Wins**: See mastered topics and applications

## Integration with System

### Learning Context Analyzer
Reads log to:
- Find recent topics (avoid repeating)
- Identify struggling topics (recommend weekly dive)
- Find successful applications (reinforce pattern)
- Calculate learning velocity (adjust roadmap)

### Progress Archivist
Updates log with:
- New entries after each session
- Statistics (total sessions, hours, average scores)
- Status changes (topic moved to mastered)

### Roadmap Generator
Reads log to:
- Identify completed topics (update roadmap)
- Find gaps that need addressing
- Adjust pacing based on actual time spent

## Migration from Unstructured Log

If you have existing unstructured entries:
1. Keep old entries in "Archive" section
2. Start using structured format for new entries
3. Optionally back-fill recent entries (last month)
4. System works fine with mixed format (uses tags to parse)
