#!/usr/bin/env bash
# claude-code-now uninstaller
# Removes the UserPromptSubmit hook from ~/.claude/settings.json

set -euo pipefail

SETTINGS_FILE="${HOME}/.claude/settings.json"
STATE_FILE="${HOME}/.claude/.claude-code-now-last"

if [[ ! -f "$SETTINGS_FILE" ]]; then
    echo "No settings file found at ${SETTINGS_FILE}. Nothing to uninstall."
    exit 0
fi

if ! grep -q "claude-code-now" "$SETTINGS_FILE" 2>/dev/null; then
    echo "claude-code-now is not installed in ${SETTINGS_FILE}. Nothing to uninstall."
    exit 0
fi

if ! command -v jq &>/dev/null; then
    echo "jq is required to uninstall. Please remove the claude-code-now hook entry"
    echo "from ${SETTINGS_FILE} manually."
    exit 1
fi

TMP_FILE=$(mktemp)
trap 'rm -f "$TMP_FILE"' EXIT

# Remove hook entries whose command contains "claude-code-now"
jq '
    .hooks.UserPromptSubmit //= [] |
    .hooks.UserPromptSubmit = [
        .hooks.UserPromptSubmit[] |
        select(.hooks | all(.command | test("claude-code-now") | not))
    ] |
    if .hooks.UserPromptSubmit == [] then del(.hooks.UserPromptSubmit) else . end |
    if .hooks == {} then del(.hooks) else . end
' "$SETTINGS_FILE" > "$TMP_FILE" && mv "$TMP_FILE" "$SETTINGS_FILE"

# Clean up state file
rm -f "$STATE_FILE"

echo "Uninstalled claude-code-now successfully."
echo "Restart Claude Code for the change to take effect."
