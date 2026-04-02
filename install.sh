#!/usr/bin/env bash
# claude-code-now installer
# Adds the UserPromptSubmit hook to ~/.claude/settings.json

set -euo pipefail

HOOK_SCRIPT="$(cd "$(dirname "$0")" && pwd)/hooks/hook.sh"
SETTINGS_FILE="${HOME}/.claude/settings.json"

# Ensure hook script is executable
chmod +x "${HOOK_SCRIPT}"

# Ensure ~/.claude directory exists
mkdir -p "${HOME}/.claude"

# Create settings file if it doesn't exist
if [[ ! -f "$SETTINGS_FILE" ]]; then
    echo '{}' > "$SETTINGS_FILE"
fi

# Check if hook is already installed
if grep -q "claude-code-now" "$SETTINGS_FILE" 2>/dev/null; then
    echo "claude-code-now is already installed in ${SETTINGS_FILE}"
    echo "Run uninstall.sh first if you want to reinstall."
    exit 0
fi

# Use a temporary file for safe in-place editing
TMP_FILE=$(mktemp)
trap 'rm -f "$TMP_FILE"' EXIT

# Check if jq is available
if command -v jq &>/dev/null; then
    # Build the hook entry
    HOOK_ENTRY=$(cat <<HOOKJSON
{
    "matcher": "",
    "hooks": [
        {
            "type": "command",
            "command": "${HOOK_SCRIPT}"
        }
    ]
}
HOOKJSON
    )

    # Add hook to settings using jq
    jq --argjson hook "$HOOK_ENTRY" '
        .hooks //= {} |
        .hooks.UserPromptSubmit //= [] |
        .hooks.UserPromptSubmit += [$hook]
    ' "$SETTINGS_FILE" > "$TMP_FILE" && mv "$TMP_FILE" "$SETTINGS_FILE"

    echo "Installed claude-code-now successfully."
    echo ""
    echo "Hook script: ${HOOK_SCRIPT}"
    echo "Settings:    ${SETTINGS_FILE}"
    echo ""
    echo "Restart Claude Code for the hook to take effect."
else
    echo "jq is not installed. Please add the following manually to ${SETTINGS_FILE}:"
    echo ""
    echo "Under \"hooks\" -> \"UserPromptSubmit\", add:"
    echo ""
    cat <<MANUAL
{
    "matcher": "",
    "hooks": [
        {
            "type": "command",
            "command": "${HOOK_SCRIPT}"
        }
    ]
}
MANUAL
    echo ""
    echo "Install jq (brew install jq / apt install jq) for automatic installation."
    exit 1
fi
