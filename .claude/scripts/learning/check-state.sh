#!/bin/bash
# Learning System - Check State Helper
# Consolidated state checker for skill initialization blocks
# Usage: bash ./.claude/scripts/learning/check-state.sh <context>
# Contexts: init, profile, roadmap, project, profile-exists

set -uo pipefail

source "$(dirname "$0")/load-state.sh"

CONTEXT="${1:-}"

case "$CONTEXT" in
    init)
        if has_profile && has_roadmap; then
            echo "**Existing Setup Detected**"
            echo ""
            echo "Profile: $PROFILE_FILE (created $(stat -c %y "$PROFILE_FILE" | cut -d' ' -f1))"
            echo "Roadmap: $ROADMAP_FILE (created $(stat -c %y "$ROADMAP_FILE" | cut -d' ' -f1))"
            echo ""
            echo "What would you like to do?"
            echo "1. Fresh start (delete and recreate both)"
            echo "2. Update profile only -> /learning-create-profile"
            echo "3. Update roadmap only -> /learning-create-roadmap"
            echo "4. Skip to system tour"
            echo "5. Cancel"
        else
            echo "STATUS=new"
        fi
        ;;

    profile)
        if has_profile; then
            echo "**Existing Profile Found**"
            echo ""
            echo "Profile: $PROFILE_FILE"
            echo "Created: $(jq -r '.created_at' "$PROFILE_FILE" 2>/dev/null || echo "unknown")"
            echo "Last updated: $(jq -r '.updated_at' "$PROFILE_FILE" 2>/dev/null || echo "unknown")"
            echo ""
            echo "Current goals:"
            jq -r '.goals.three_month[].topic' "$PROFILE_FILE" 2>/dev/null | while read goal; do
                echo "- $goal"
            done
            echo ""
            echo "What would you like to do?"
            echo "1. Update profile (keep most, change some)"
            echo "2. Fresh profile (delete and recreate)"
            echo "3. Cancel"
        else
            echo "STATUS=new"
        fi
        ;;

    roadmap)
        if ! has_profile; then
            echo "ERROR=no-profile"
            echo ""
            echo "I need your learning profile to generate a roadmap."
            echo ""
            echo "Create profile first: /learning-create-profile"
            exit 0
        fi

        if has_roadmap; then
            echo "**Existing Roadmap Found**"
            echo ""
            echo "Roadmap: $ROADMAP_FILE"
            echo "Created: $(jq -r '.created_at' "$ROADMAP_FILE" 2>/dev/null || echo "unknown")"
            echo "Goal: $(jq -r '.primary_goal' "$ROADMAP_FILE" 2>/dev/null || echo "unknown")"
            echo "Current phase: $(jq -r '.current_phase' "$ROADMAP_FILE" 2>/dev/null || echo "unknown")"
            echo ""
            echo "What would you like to do?"
            echo "1. Update roadmap (adjust pacing, add/remove topics)"
            echo "2. Fresh roadmap (delete and recreate)"
            echo "3. Cancel"
        else
            echo "STATUS=new"
        fi
        ;;

    project)
        if has_project_knowledge; then
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
        else
            echo "STATUS=new"
        fi
        ;;

    profile-exists)
        if ! has_profile; then
            echo "**Quick Profile Setup**"
            echo ""
            echo "I'll create a minimal profile from your interview answers."
            echo "You can enrich it later with /learning-create-profile"
        else
            echo "STATUS=has-profile"
        fi
        ;;

    *)
        echo "Unknown context: $CONTEXT" >&2
        echo "Usage: bash check-state.sh <init|profile|roadmap|project|profile-exists>" >&2
        exit 1
        ;;
esac
