#!/usr/bin/env bash
# claude-code-now — Temporal awareness for Claude Code
# https://github.com/bdteo/claude-code-now
#
# Injects precise timestamps and elapsed time into every Claude Code
# interaction via the UserPromptSubmit hook.

set -euo pipefail

STATE_FILE="${HOME}/.claude/.claude-code-now-last"
NOW_EPOCH=$(date +%s)
NOW_HUMAN=$(date '+%Y-%m-%d %H:%M:%S %Z')

# Calculate elapsed time since last message
ELAPSED=""
if [[ -f "$STATE_FILE" ]]; then
    LAST_EPOCH=$(<"$STATE_FILE")
    DIFF=$((NOW_EPOCH - LAST_EPOCH))
    if (( DIFF >= 86400 )); then
        DAYS=$((DIFF / 86400))
        HOURS=$(( (DIFF % 86400) / 3600 ))
        ELAPSED=" | ${DAYS}d ${HOURS}h since last message"
    elif (( DIFF >= 3600 )); then
        HOURS=$((DIFF / 3600))
        MINS=$(( (DIFF % 3600) / 60 ))
        ELAPSED=" | ${HOURS}h ${MINS}m since last message"
    elif (( DIFF >= 60 )); then
        MINS=$((DIFF / 60))
        SECS=$((DIFF % 60))
        ELAPSED=" | ${MINS}m ${SECS}s since last message"
    elif (( DIFF > 5 )); then
        ELAPSED=" | ${DIFF}s since last message"
    fi
fi

# Persist current timestamp for next invocation
echo "${NOW_EPOCH}" > "${STATE_FILE}"

# Inject temporal context into Claude's awareness
cat <<EOF
{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"Current time: ${NOW_HUMAN}${ELAPSED}"}}
EOF
