---
name: learning-init-project
description: Initialize project-mode learning. Analyzes the codebase, creates a knowledge map, interviews you about familiarity, and generates a personalized learning path for your project.
disable-model-invocation: false
---

# Project Learning Initialization

Set up codebase learning for **this project**. I'll analyze the code, understand the architecture, and create a personalized path to deepen your knowledge.

This takes 10-15 minutes:
1. **Detect & Map** (automatic) - Project type, structure, tech stack
2. **Developer Interview** (5 questions) - Your familiarity and goals
3. **Codebase Analysis** (automatic) - Knowledge areas, layers, dependencies
4. **Knowledge Map** (generated) - `project-knowledge.json`
5. **Learning Path** (generated) - `roadmap.json` tailored to your gaps

---

## Step 1: Check Existing State

!`source ./.claude/plugins/local/learning-science/helpers/load-state.sh`

!`if has_project_knowledge; then
    echo "**Existing project knowledge map detected**"
    echo ""
    echo "Project: $(get_project_field 'project_name')"
    echo "Analyzed: $(get_project_field 'analyzed_at')"
    echo "Commit: $(get_project_field 'analyzed_commit')"
    echo ""
    echo "What would you like to do?"
    echo "1. Fresh start (re-analyze everything)"
    echo "2. Keep knowledge map, regenerate learning path only"
    echo "3. Cancel"
fi`

---

## Step 2: Detect Project Type

Automatically detect the project by reading manifest files and directory structure.

**Read these files (if they exist) to determine the tech stack:**
- `package.json`, `tsconfig.json`, `next.config.*` (Node/JS/TS ecosystem)
- `go.mod`, `go.sum` (Go)
- `Cargo.toml` (Rust)
- `pyproject.toml`, `setup.py`, `requirements.txt` (Python)
- `pom.xml`, `build.gradle` (Java/Kotlin)
- `Gemfile` (Ruby)
- `docker-compose.yml`, `Dockerfile` (Infrastructure)
- `.github/workflows/` (CI/CD)

**Read the top-level directory listing** to understand project layout.

Present findings to the developer:

> **Project Detection Results**
>
> - **Name**: [from manifest or directory name]
> - **Tech Stack**: [languages, frameworks, databases detected]
> - **Project Type**: [web app / API / CLI / library / monorepo / etc.]
> - **Directory Structure**: [brief layout summary]
>
> Does this look right? Anything to add or correct?

---

## Step 3: Developer Interview

Ask these 5 questions (wait for answers before proceeding):

### 1. Tenure & Context
**How long have you been working on this project?**
- Just starting / onboarding
- A few weeks/months
- 6+ months, but there are areas I don't touch
- Long-time contributor

### 2. Familiar Areas
**Which parts of the codebase do you know well?**
(List specific directories, modules, or features you're confident in)

### 3. Unfamiliar Areas
**Which parts feel like a black box?**
(Areas you avoid, don't understand, or have never touched)

### 4. Learning Goal
**What's your primary goal?**
- **Onboard**: Get productive quickly across the whole codebase
- **Deepen**: Master the areas I already work in
- **Broaden**: Understand parts I never touch
- **Prepare**: Get ready to own/maintain a specific area

### 5. Time Commitment
**How much time can you spend learning about the codebase?**
- Daily practice: ___ minutes/day
- Deep dives: ___ hours/week

---

## Step 4: Codebase Analysis

**This is where you (Claude) do the real work.** Read the actual source code to build a knowledge map.

### Analysis Instructions

Read the codebase systematically and categorize what you find into knowledge **areas**. Each area is a cohesive unit of understanding — something a developer needs to "get" as a whole.

**Layer classification** — assign each area to one of these layers:
- `data`: Models, schemas, migrations, database access
- `domain`: Business logic, rules, core algorithms
- `infrastructure`: Auth, logging, config, middleware, shared utilities
- `api`: Routes, controllers, endpoints, request/response handling
- `deployment`: CI/CD, Docker, cloud config, environment setup
- `testing`: Test patterns, fixtures, test utilities

**For each area, determine:**
- `name`: Human-readable name
- `description`: 1-2 sentence summary of what this area does and why it matters
- `key_files`: 3-8 most important files (entry points, not every file)
- `concepts`: Technical concepts a developer needs to understand this area
- `depends_on`: Other area keys this area builds on
- `importance`: `critical` (breaks everything if wrong), `high` (core feature), `medium` (important but contained), `low` (nice to know)
- `layer`: One of the layers above

**How to decide what constitutes an "area":**
- Group by **domain responsibility**, not by directory structure
- An area should be explainable in 2-3 minutes
- If an area has more than 8 key files, consider splitting it
- If two directories always change together, they're probably one area
- Look for natural boundaries: separate APIs, distinct features, independent subsystems

**Identify critical paths** — sequences of areas that handle the most important user-facing flows (e.g., authentication -> authorization -> data access).

**Identify entry points** — areas that are best learned first because other areas depend on them (low `depends_on`, high `depended-on-by`).

---

### Generate `project-knowledge.json`

Based on the analysis above, create the knowledge map:

!`cat > ./project-knowledge.json <<'PKG_END'
{
  "project_name": "[detected or confirmed name]",
  "analyzed_at": "$(date -I)",
  "analyzed_commit": "$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')",
  "tech_stack": ["[detected technologies]"],
  "architecture_patterns": ["[detected patterns]"],
  "areas": {
    "[area-key]": {
      "name": "[Human-readable name]",
      "description": "[1-2 sentence summary]",
      "key_files": ["[path/to/file.ext]"],
      "concepts": ["[concept1]", "[concept2]"],
      "depends_on": ["[other-area-key]"],
      "importance": "[critical|high|medium|low]",
      "layer": "[data|domain|infrastructure|api|deployment|testing]"
    }
  },
  "layers": {
    "data": { "description": "[what the data layer looks like in this project]", "areas": [] },
    "domain": { "description": "[...]", "areas": [] },
    "infrastructure": { "description": "[...]", "areas": [] },
    "api": { "description": "[...]", "areas": [] },
    "deployment": { "description": "[...]", "areas": [] },
    "testing": { "description": "[...]", "areas": [] }
  },
  "critical_paths": ["[area-key-1]", "[area-key-2]"],
  "entry_points": ["[area-key-best-to-learn-first]"]
}
PKG_END`

**Tell the developer what you found:**

> **Codebase Knowledge Map**
>
> I identified **[N] knowledge areas** across [N] layers:
>
> | Area | Layer | Importance | Key Concepts |
> |------|-------|-----------|--------------|
> | [name] | [layer] | [importance] | [concepts] |
> | ... | ... | ... | ... |
>
> **Critical paths**: [list]
> **Recommended starting points**: [list]
>
> Does this match your understanding? Any areas missing or miscategorized?

---

## Step 5: Generate Learning Path

Based on the knowledge map + developer's familiarity gaps + learning goal, generate a `roadmap.json`.

**Prioritization rules by goal:**
- **Onboard**: Start with entry points, cover all critical/high areas, breadth-first
- **Deepen**: Focus on areas the developer already knows, add adjacent concepts
- **Broaden**: Prioritize the developer's stated "black box" areas
- **Prepare**: Build a deep path through the specific area and its dependencies

**Topic naming**: Each topic maps to a knowledge area. The topic key in the roadmap should match the area key in `project-knowledge.json`.

### Save Roadmap

!`cat > ./roadmap.json <<'ROADMAP'
{
  "primary_goal": "[from interview: onboard/deepen/broaden/prepare] [project_name]",
  "timeline_weeks": 12,
  "current_phase": "Phase 1",
  "topics": {
    "[area-key]": {
      "name": "[Area name from knowledge map]",
      "phase": 1,
      "sequence": 1,
      "status": "ready",
      "prerequisites": ["[other-area-key or empty]"],
      "estimated_hours": 2,
      "project_area": "[area-key]",
      "type": "project-knowledge"
    }
  },
  "phases": {
    "1": { "name": "Foundations", "weeks": "1-4" },
    "2": { "name": "Core Systems", "weeks": "5-8" },
    "3": { "name": "Advanced & Integration", "weeks": "9-12" }
  },
  "created_at": "$(date -I)",
  "updated_at": "$(date -I)",
  "metadata": {
    "mode": "project",
    "project_name": "[name]",
    "learning_goal": "[from interview]",
    "last_updated": "$(date -I)"
  }
}
ROADMAP`

---

## Step 6: Create Profile (if needed)

!`if ! has_profile; then
    echo "**Quick Profile Setup**"
    echo ""
    echo "I'll create a minimal profile from your interview answers."
    echo "You can enrich it later with /learning-create-profile"
fi`

*If no profile exists, create a minimal one from the interview answers (name, role from context, time commitment, learning style defaults). Save to `profile.json`.*

---

## Step 7: Summary & Next Steps

### Setup Complete!

**Project**: [name]
**Knowledge Areas**: [N] areas across [N] layers
**Learning Path**: [N] topics over 12 weeks
**Mode**: Project Learning

### Your Learning Path

**Phase 1: Foundations** (Weeks 1-4)
- [Topic list with area names]

**Phase 2: Core Systems** (Weeks 5-8)
- [Topic list]

**Phase 3: Advanced & Integration** (Weeks 9-12)
- [Topic list]

### Key Files Created

- `project-knowledge.json` — Codebase knowledge map (commit this! your team can use it)
- `roadmap.json` — Your personal learning path (gitignored)
- `profile.json` — Your learner profile (gitignored)

### Next Steps

1. **Start learning**: `/learning-daily-recall` — Quick recall on your first topic
2. **Deep dive**: `/learning-weekly-dive` — Socratic exploration of an area
3. **Review the map**: `cat project-knowledge.json | jq` — See all knowledge areas

The system will quiz you on **your actual codebase** — I'll read the real source code to verify your answers!
