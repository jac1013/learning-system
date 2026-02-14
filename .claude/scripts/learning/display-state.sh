#!/bin/bash
# Learning System - Display State Helper
# Usage: bash ./.claude/scripts/learning/display-state.sh <what>
# Options: profile-summary, profile-analysis, roadmap-summary

set -uo pipefail

source "$(dirname "$0")/load-state.sh"

WHAT="${1:-}"

case "$WHAT" in
    profile-summary)
        echo "**Your Profile**:"
        echo ""
        echo "- **Role**: $(get_profile_field "role" || echo "unknown")"
        echo "- **Experience**: $(get_profile_field "experience_years" || echo "unknown") years"
        echo "- **Primary Goal**: $(get_profile_field "goals.three_month[0].topic" || echo "unknown")"
        echo "- **Success in 3 months**: $(get_profile_field "goals.three_month[0].success_criteria" || echo "unknown")"
        echo "- **Learning Style**: $(get_profile_field "learning_style.mode" || echo "unknown") (stress tolerance: $(get_profile_field "learning_style.stress_tolerance" || echo "unknown"))"
        echo "- **Time Commitment**: $(get_profile_field "time_commitment.daily_minutes" || echo "unknown") min/day, $(get_profile_field "time_commitment.weekly_hours" || echo "unknown") hours/week"
        ;;

    profile-analysis)
        echo "**Analyzing Your Profile...**"
        echo ""
        echo "**Your 3-Month Goal**: $(get_profile_field 'goals.three_month[0].topic' || echo "unknown")"
        echo "**Success Criteria**: $(get_profile_field 'goals.three_month[0].success_criteria' || echo "unknown")"
        echo ""
        echo "**Time Available**:"
        echo "- Daily: $(get_profile_field 'time_commitment.daily_minutes' || echo "unknown") min/day"
        echo "- Weekly: $(get_profile_field 'time_commitment.weekly_hours' || echo "unknown") hours/week"
        echo ""
        echo "**Learning Style**: $(get_profile_field 'learning_style.mode' || echo "unknown")"
        echo ""
        echo "Generating roadmap..."
        ;;

    roadmap-summary)
        if [[ ! -f "$ROADMAP_FILE" ]]; then
            echo "No roadmap found." >&2
            exit 0
        fi

        echo "**Your Learning Path**"
        echo ""
        echo "**Goal**: $(jq -r '.primary_goal' "$ROADMAP_FILE" 2>/dev/null || echo "unknown")"
        echo "**Timeline**: 12 weeks"
        echo "**Total Estimated Effort**: $(jq -r '.metadata.total_hours_estimated' "$ROADMAP_FILE" 2>/dev/null || echo "unknown") hours"
        echo ""
        echo "**Phase Breakdown**:"
        jq -r '.phases | to_entries[] | "Phase \(.key): \(.value.name) (Weeks \(.value.weeks)) - \(.value.focus)"' "$ROADMAP_FILE" 2>/dev/null
        echo ""
        echo "**First Topic**: $(jq -r '.topics["topic-1-1"].name' "$ROADMAP_FILE" 2>/dev/null || echo "unknown")"
        echo "**Ready to start!**"
        ;;

    pacing)
        daily=$(get_profile_field "time_commitment.daily_minutes" || echo "0")
        weekly=$(get_profile_field "time_commitment.weekly_hours" || echo "0")
        weekly_from_daily=$(echo "$daily * 7 / 60" | bc 2>/dev/null || echo "0")

        echo "**Your capacity**:"
        echo "- Daily: ${daily} min/day = ${weekly_from_daily} hours/week minimum"
        echo "- Weekly deep dives: ${weekly} hours/week"
        ;;

    *)
        echo "Unknown display type: $WHAT" >&2
        echo "Usage: bash display-state.sh <profile-summary|profile-analysis|roadmap-summary|pacing>" >&2
        exit 1
        ;;
esac
