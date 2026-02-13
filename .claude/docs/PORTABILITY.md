# Portability Guide

## Overview

The entire `.claude` folder and learning system is now **fully portable** across different systems, users, and directory locations. All paths are relative and dynamically calculated.

## Key Changes

### 1. Helper Scripts (`.claude/plugins/local/learning-science/helpers/`)

All helper scripts now derive the project root dynamically:

```bash
# Before (hard-coded):
LEARNING_ROOT="/home/jac/learning"

# After (portable):
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LEARNING_ROOT="$(cd "$SCRIPT_DIR/../../../../.." && pwd)"
```

**Files updated:**
- `load-state.sh` - Derives all state file paths from project root
- `save-state.sh` - Sources load-state.sh (inherits portable paths)
- `infer-next.sh` - Sources load-state.sh (inherits portable paths)

### 2. Skills (`.claude/skills/learning-*/SKILL.md`)

All skill files now use relative paths:

```bash
# Before:
source /home/jac/learning/.claude/plugins/local/learning-science/helpers/load-state.sh

# After:
source ./.claude/plugins/local/learning-science/helpers/load-state.sh
```

**Skills updated:**
- `init/SKILL.md`
- `daily-recall/SKILL.md`
- `weekly-dive/SKILL.md`
- `monthly-synthesis/SKILL.md`
- `create-profile/SKILL.md`
- `create-roadmap/SKILL.md`
- `apply-to-work/SKILL.md`

### 3. Hooks (`.claude/hooks/`)

The session-start hook calculates paths dynamically:

```bash
# Before (hard-coded):
LEARNING_ROOT="/home/jac/learning"

# After (portable):
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LEARNING_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
```

### 4. Documentation (`.claude/docs/`)

All documentation now uses generic path placeholders:

- `/home/jac/learning/` → `./` or `<project-root>/`
- `/home/jac/.claude/` → `.claude/`

**Files updated:**
- `REFACTORING-STATUS.md`
- `QUICK-START.md`
- `PERSONALIZATION-LAYER-README.md`
- `LEARNING-FRAMEWORK-README.md`
- `learning-log-structure.md`
- `REFACTORING-COMPLETE.md`
- `IMPLEMENTATION-STATUS.md`
- `START-HERE.md`
- `IMPLEMENTATION-SUMMARY.md`

## Directory Structure

The portable structure:

```
<project-root>/                     # Can be anywhere!
├── .claude/
│   ├── skills/learning-*/           # All use relative paths
│   ├── hooks/                      # SessionStart hook
│   ├── plugins/local/learning-science/
│   │   └── helpers/                # Dynamically derive project root
│   ├── docs/                       # Generic path references
│   └── settings.json               # Hook registration
├── profile.json                    # Created in project root
├── roadmap.json                    # Created in project root
├── learning-log.jsonl              # Created in project root
├── .spaced-repetition.json         # Created in project root
├── .review-schedule.json           # Created in project root
└── synthesis/                      # Created in project root
```

## How It Works

### Path Resolution

1. **Helper scripts** detect their location using `${BASH_SOURCE[0]}`
2. Navigate up the directory tree to find project root
3. All other paths are derived from this root
4. No hard-coded absolute paths anywhere

### Skills Execution

1. Skills use `./` relative paths from current working directory
2. Assumes execution happens from project root (standard Claude Code behavior)
3. All created files go into project root

## Testing Portability

You can verify portability by:

```bash
# Copy the entire directory
cp -r /home/jac/learning /tmp/test-learning

# Navigate to new location
cd /tmp/test-learning

# Skills and helpers should work identically
./.claude/plugins/local/learning-science/helpers/load-state.sh
# Output: Will use /tmp/test-learning as root
```

## Moving the System

To move your learning system to another location or machine:

1. **Copy the entire directory:**
   ```bash
   cp -r <current-location> <new-location>
   ```

2. **That's it!** Everything will continue working because:
   - All paths are calculated dynamically
   - No hard-coded references to old location
   - No absolute paths anywhere

## Benefits

✅ **Cross-System**: Works on any Linux/macOS/WSL system
✅ **Multi-User**: Each user can have their own copy
✅ **Relocatable**: Move directory anywhere without breaking
✅ **Version Control**: Can be tracked in git without user-specific paths
✅ **Shareable**: Can share `.claude` folder as template
✅ **Testable**: Can create test copies for experimentation

## Important Notes

1. **Current Working Directory**: Skills assume execution from project root (standard Claude Code behavior)
2. **State Files**: Profile, roadmap, logs, etc. are created in project root
3. **Shell Scripts**: Use `./` prefix when sourcing helpers from skills
4. **Documentation**: Uses generic placeholders like `./` and `<project-root>/`

## Example Use Cases

### Team Template
```bash
# Create a template for your team
cp -r learning-template /shared/templates/
# Anyone can copy and use it
```

### Backup & Restore
```bash
# Backup
tar -czf learning-backup.tar.gz learning/

# Restore anywhere
tar -xzf learning-backup.tar.gz -C /new/location/
```

### Multiple Projects
```bash
# Different learning systems for different topics
~/projects/web-dev-learning/
~/projects/ml-learning/
~/projects/security-learning/
# Each completely independent
```

## Summary

Every file in `.claude` is now portable and generic. The system automatically adapts to wherever it's placed, making it easy to move, share, and replicate across different environments.
