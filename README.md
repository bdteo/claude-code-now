# claude-code-now

Temporal awareness for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

Claude Code doesn't tell Claude what time it is between messages. So when you leave for 3 hours and come back asking "check that metric again," Claude thinks no time has passed and may serve stale results or refuse to re-run commands. This hook fixes that.

## What it does

A zero-dependency bash hook for Claude Code's `UserPromptSubmit` event that injects:

- **Precise timestamp** with seconds and timezone on every message
- **Elapsed time** since your last message in human-friendly format

What Claude sees with every prompt:

```
Current time: 2026-04-02 15:23:45 CEST | 3h 22m since last message
```

## Install

### Option 1: Claude Code Plugin (recommended)

```bash
claude plugin add bdteo/claude-code-now
```

That's it. Restart Claude Code.

### Option 2: Script installer

```bash
git clone https://github.com/bdteo/claude-code-now.git
cd claude-code-now
bash install.sh
```

Restart Claude Code.

### Option 3: Manual

1. Clone the repo and make the hook executable:

```bash
git clone https://github.com/bdteo/claude-code-now.git
chmod +x claude-code-now/hooks/hook.sh
```

2. Add this to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "/absolute/path/to/claude-code-now/hooks/hook.sh || true"
          }
        ]
      }
    ]
  }
}
```

3. Restart Claude Code.

## Uninstall

**Plugin install:**

```bash
claude plugin remove claude-code-now
```

**Script install:**

```bash
bash uninstall.sh
```

## How it works

On every prompt submission, the hook:

1. Captures the current timestamp with second precision
2. Reads the last interaction timestamp from `~/.claude/.claude-code-now-last`
3. Calculates elapsed time and formats it as human-friendly text (`2d 5h`, `3h 22m`, `45m 12s`, `8s`)
4. Saves the current timestamp for the next invocation
5. Outputs JSON that Claude Code injects as a system reminder

The hook gracefully fails silent (`|| true`) so it never breaks your session.

The entire script is ~40 lines of bash with no dependencies.

## Requirements

- Claude Code v1.0.55+
- bash
- `jq` (only for `install.sh` / `uninstall.sh` — the hook itself has zero dependencies)

## Why not just use CLAUDE.md?

Adding "always check the time before responding" to your CLAUDE.md is unreliable. Claude may ignore it, forget it after context compaction, or decide it's not relevant. A hook runs **every time**, injecting the timestamp at the system level before Claude even sees your message.

## Prior art

- [anthropics/claude-code#2618](https://github.com/anthropics/claude-code/issues/2618) — the issue that surfaced this gap
- [hodgesmr/temporal-awareness](https://github.com/hodgesmr/temporal-awareness) — a skill-based approach (on-demand, not passive)
- [veteranbv/claude-UserPromptSubmit-hook](https://github.com/veteranbv/claude-UserPromptSubmit-hook) — Python-based hook with broader scope

## License

MIT
