#!/bin/bash
# Learning System - Load State Helper
# Loads profile, roadmap, and learning state into environment variables

set -euo pipefail

# Derive project root from script location (portable across systems)
# This script is at: .claude/scripts/load-state.sh
# Project root is 2 levels up
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LEARNING_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

PROFILE_FILE="$LEARNING_ROOT/profile.json"
ROADMAP_FILE="$LEARNING_ROOT/roadmap.json"
LEARNING_LOG="$LEARNING_ROOT/learning-log.jsonl"
SPACED_REP_FILE="$LEARNING_ROOT/.spaced-repetition.json"
REVIEW_SCHEDULE_FILE="$LEARNING_ROOT/.review-schedule.json"
PROJECT_KNOWLEDGE_FILE="$LEARNING_ROOT/project-knowledge.json"

# Export state file paths
export LEARNING_ROOT
export PROFILE_FILE
export ROADMAP_FILE
export LEARNING_LOG
export SPACED_REP_FILE
export REVIEW_SCHEDULE_FILE
export PROJECT_KNOWLEDGE_FILE

# Function to check if profile exists
has_profile() {
    [[ -f "$PROFILE_FILE" ]]
}

# Function to check if roadmap exists
has_roadmap() {
    [[ -f "$ROADMAP_FILE" ]]
}

# Function to get profile field
get_profile_field() {
    local field="$1"
    if has_profile; then
        jq -r ".$field // empty" "$PROFILE_FILE"
    fi
}

# Function to get roadmap field
get_roadmap_field() {
    local field="$1"
    if has_roadmap; then
        jq -r ".$field // empty" "$ROADMAP_FILE"
    fi
}

# Function to check if project knowledge map exists
has_project_knowledge() {
    [[ -f "$PROJECT_KNOWLEDGE_FILE" ]]
}

# Function to detect project vs generic learning mode
is_project_mode() {
    has_project_knowledge
}

# Function to get project knowledge field
get_project_field() {
    local field="$1"
    if has_project_knowledge; then
        jq -r ".$field // empty" "$PROJECT_KNOWLEDGE_FILE"
    fi
}

# Export helper functions
export -f has_profile
export -f has_roadmap
export -f get_profile_field
export -f get_roadmap_field
export -f has_project_knowledge
export -f is_project_mode
export -f get_project_field

# Load current state (if files exist)
if has_profile; then
    export LEARNER_NAME=$(get_profile_field "name")
    export LEARNER_ROLE=$(get_profile_field "role")
    export LEARNING_STYLE=$(get_profile_field "learning_style.mode")
    export TIME_DAILY=$(get_profile_field "time_commitment.daily_minutes")
    export TIME_WEEKLY=$(get_profile_field "time_commitment.weekly_hours")
fi

if has_roadmap; then
    export CURRENT_PHASE=$(get_roadmap_field "current_phase")
    export ROADMAP_GOAL=$(get_roadmap_field "primary_goal")
fi

# Detect learning mode
if is_project_mode; then
    export LEARNING_MODE="project"
    export PROJECT_NAME=$(get_project_field "project_name")
else
    export LEARNING_MODE="generic"
    export PROJECT_NAME=""
fi

# Return success
return 0 2>/dev/null || exit 0
