# claude-code-now

Temporal awareness for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

## The problem

You're deep in a debugging session with Claude Code. You ask it to check a queue size — it reports 42. You step away for a coffee, come back 20 minutes later, and ask again.

> "The queue size is 42, as I already reported."

You insist. Claude pushes back — "nothing has changed." On the third or fourth attempt it finally re-checks and discovers the queue is now at 3,800. Cue the apologetic "Oh, I see 25 minutes have passed..."

This isn't Claude being lazy. **Claude Code simply doesn't tell Claude what time it is.** There's a date in the system prompt, but no clock. Between your messages, Claude has zero sense of how much time has passed — 5 seconds and 5 hours look identical. So it caches answers, skips re-checks, and treats every follow-up as if you asked it a second ago.

But it goes further. When Claude launches a background command or spawns parallel agents, **it can't tell you how long they took.** It doesn't know when its own tools started or finished. Ask "how long did that batch take?" and Claude has to guess from conversation context — because it has no timestamps on its own actions.

Under high cognitive load — monitoring deployments, debugging production issues, running parallel batch jobs — this isn't a minor annoyance. It wastes tokens, breaks your flow, and erodes trust in the tool.

## The fix

A single bash script. Zero dependencies. Installs in one command.

`claude-code-now` hooks into Claude Code's event system and injects precise timestamps across the entire agentic loop:

```
Current time: 2026-04-02 15:23:45 CEST | 3h 22m since last message
[15:23:46] Bash starting
[15:24:12] Bash completed
[15:24:13] Agent (general-purpose) started    <- seen by the subagent
[15:24:13] Agent completed                    <- seen by the parent
[15:27:45] Agent (general-purpose) finished   <- seen by the parent
[15:27:45] Turn ended (end_turn)
```

Claude now knows *when* you're talking to it, *how long* you've been away, and *when each of its own actions happened*. It won't serve stale results. It won't guess about durations. It just works.

### What gets timestamped

| Event | Who sees it | What Claude sees |
|---|---|---|
| Your message | Parent | Full timestamp + elapsed time since last message |
| Bash command start | Parent | `[HH:MM:SS] Bash starting` |
| Any tool completion | Parent | `[HH:MM:SS] Bash completed`, `[HH:MM:SS] Read completed`, etc. |
| Agent spawned | Subagent | `[HH:MM:SS] Agent (general-purpose) started` |
| Agent finished | Parent | `[HH:MM:SS] Agent (general-purpose) finished` |
| Turn ended | Parent | `[HH:MM:SS] Turn ended (end_turn)` |

## Install

### Option 1: Claude Code Plugin (recommended)

```bash
claude plugin marketplace add bdteo/claude-code-now
claude plugin install claude-code-now
```

Restart Claude Code.

### Update

```bash
claude plugin marketplace update claude-code-now
claude plugin update claude-code-now@claude-code-now
```

Restart Claude Code.

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
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "/absolute/path/to/claude-code-now/hooks/hook.sh || true"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "/absolute/path/to/claude-code-now/hooks/hook.sh || true"
          }
        ]
      }
    ],
    "SubagentStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "/absolute/path/to/claude-code-now/hooks/hook.sh || true"
          }
        ]
      }
    ],
    "SubagentStop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "/absolute/path/to/claude-code-now/hooks/hook.sh || true"
          }
        ]
      }
    ],
    "Stop": [
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

The hook script receives JSON on stdin from Claude Code with the event type and context. It extracts the event name, formats a timestamp, and outputs JSON that Claude Code injects as a system reminder — all before Claude processes the next step.

For user messages, it also tracks elapsed time since your last message using a state file at `~/.claude/.claude-code-now-last`.

All hooks use `|| true` so they never break your session. The entire script is ~95 lines of bash with zero dependencies.

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
