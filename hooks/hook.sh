#!/usr/bin/env bash
# shellcheck shell=bash
# claude-code-now — Temporal awareness for Claude Code
# https://github.com/bdteo/claude-code-now
#
# Multi-event hook that injects precise timestamps into Claude Code's
# context for user messages, tool executions, and turn endings.

set -euo pipefail

STATE_FILE="${HOME}/.claude/.claude-code-now-last"

# Single date call, extract all formats via string manipulation
NOW_ALL=$(date '+%s %Y-%m-%d %H:%M:%S %Z')
NOW_EPOCH="${NOW_ALL%% *}"
NOW_HUMAN="${NOW_ALL#* }"
NOW_TIME="${NOW_HUMAN:11:8}"

# Read stdin (hook input JSON)
INPUT=$(cat)

# Simple JSON string field extractor (no jq dependency)
json_field() {
    echo "$INPUT" | grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -1 | sed 's/.*:[[:space:]]*"//;s/"$//' || true
}

EVENT=$(json_field "hook_event_name")

# Format elapsed time since last user message
format_elapsed() {
    local DIFF="$1"
    if (( DIFF >= 86400 )); then
        echo " | $((DIFF / 86400))d $(( (DIFF % 86400) / 3600 ))h since last message"
    elif (( DIFF >= 3600 )); then
        echo " | $((DIFF / 3600))h $(( (DIFF % 3600) / 60 ))m since last message"
    elif (( DIFF >= 60 )); then
        echo " | $((DIFF / 60))m $((DIFF % 60))s since last message"
    elif (( DIFF > 5 )); then
        echo " | ${DIFF}s since last message"
    fi
}

# Build the additionalContext based on event type
# Only extract fields needed per event to minimize process forks
case "$EVENT" in
    UserPromptSubmit)
        ELAPSED=""
        if [[ -f "$STATE_FILE" ]]; then
            LAST_EPOCH=$(<"$STATE_FILE")
            if [[ "$LAST_EPOCH" =~ ^[0-9]+$ ]]; then
                ELAPSED=$(format_elapsed "$((NOW_EPOCH - LAST_EPOCH))")
            fi
        fi
        echo "${NOW_EPOCH}" > "${STATE_FILE}"
        CONTEXT="Current time: ${NOW_HUMAN}${ELAPSED}"
        ;;
    PreToolUse)
        TOOL_NAME=$(json_field "tool_name")
        CONTEXT="[${NOW_TIME}] ${TOOL_NAME} starting"
        ;;
    PostToolUse)
        TOOL_NAME=$(json_field "tool_name")
        CONTEXT="[${NOW_TIME}] ${TOOL_NAME} completed"
        ;;
    SubagentStart)
        AGENT_TYPE=$(json_field "agent_type")
        CONTEXT="[${NOW_TIME}] Agent (${AGENT_TYPE}) started"
        ;;
    SubagentStop)
        AGENT_TYPE=$(json_field "agent_type")
        CONTEXT="[${NOW_TIME}] Agent (${AGENT_TYPE}) finished"
        ;;
    Stop)
        STOP_REASON=$(json_field "stop_reason")
        CONTEXT="[${NOW_TIME}] Turn ended (${STOP_REASON})"
        ;;
    *)
        CONTEXT="[${NOW_TIME}] ${EVENT}"
        ;;
esac

# Inject temporal context into Claude's awareness
# PreToolUse, PostToolUse, UserPromptSubmit, SubagentStart, SubagentStop use hookSpecificOutput
# Stop uses top-level additionalContext
case "$EVENT" in
    PreToolUse|PostToolUse|UserPromptSubmit|SubagentStart|SubagentStop)
        cat <<EOF
{"hookSpecificOutput":{"hookEventName":"${EVENT}","additionalContext":"${CONTEXT}"}}
EOF
        ;;
    *)
        cat <<EOF
{"additionalContext":"${CONTEXT}"}
EOF
        ;;
esac
