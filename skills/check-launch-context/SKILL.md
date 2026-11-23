---
name: check-launch-context
description: Check launch context by running /context in a fresh session, analyse the load context and trim it.
---

# Check launch context

Measure what a new Claude Code session loads before the user types anything, say what
isn't earning its place, then trim what the user approves and measure again.

Run it in a **separate new session**, never the current one: this session's `/context`
includes its conversation.

## 1. Load your settings

Find the data folder: `$CONTEXT_MGMT_HOME`, `$CLAUDE_USER_DATA/context-mgmt/`, then
`~/.claude-user-data/context-mgmt/`. Read `check-launch-context.md` if it exists. It can
name other owners for some fixes and things never to propose. It wins over the defaults.

## 2. Capture

```bash
"${CLAUDE_PLUGIN_ROOT}/skills/check-launch-context/scripts/launch-context.sh" <dir> <outdir>
```

If `CLAUDE_PLUGIN_ROOT` is unset, clone <https://github.com/danielrosehill/Context-Mgmt>
and run it from there. Needs `claude` and `tmux` on the machine being measured.

`<dir>` is the folder to launch in, by default the current one. It matters: project
CLAUDE.md, `.mcp.json` and memory depend on it. To split user-level from project-level
cost, capture an empty folder too and compare.

The script opens `claude` in a detached tmux terminal, waits for MCP servers
(`MCP_SETTLE`, default 12 seconds), types `/context all`, saves the screen and closes the
session. `/context` is a local command, so no model call is made and it costs nothing.

| File | Use it for |
|---|---|
| `interactive.txt` | The real total and categories |
| `headless.md` | `claude -p "/context"`: per-item tables, deferred tool sizes |
| `launch.json` | Folder, version, time, and `interactive` status |

Status other than `ok`: `trust-dialog` means the folder isn't trusted, so ask the user to
open it once. `timeout`: raise `MCP_SETTLE`. `no-tmux`: use `headless.md` and say so.

Don't quote the headless total as the launch total. Measured 2026-11-23 on 2.1.330, same
folder: 17.4k interactive, 14k headless. Print mode has a smaller system prompt and tool set.

## 3. Read it correctly

- **Deferred is not loaded.** "MCP tools (deferred)" and "System tools (deferred)" are
  excluded from the total. Removing a deferred server saves its names and instructions,
  not its schema size. Never report that size as a saving.
- **Free space and autocompact buffer** are not load.
- **`/context` undercounts.** It estimates, and text injected with the first message
  (hook output, deferred tool names) may be missing. For the billed figure, read the first
  assistant `usage` in a recent transcript for that folder
  (`~/.claude/projects/<folder>/*.jsonl`): `input_tokens` + `cache_creation_input_tokens` +
  `cache_read_input_tokens`. It includes the user's first message. On 2026-11-23 one
  session read 28.4k against a `/context` of 17.4k.
- System prompt, built-in tools and built-in skills are mostly fixed. List them as such.

## 4. Analyse

Report a short table, largest first: item, tokens, loaded or deferred, verdict (keep,
trim, remove, fixed), and the proposed change. Check each candidate before judging it:

| Surface | Look for |
|---|---|
| Memory files | Reference material that could be read on demand, duplicates, stale sections |
| Skills | Installed plugins tied to one project: move to project scope or disable |
| MCP servers | Duplicates, servers for one project at user scope, long instructions |
| Custom agents | Long descriptions, agents for one project at user scope |
| SessionStart hooks | Output that repeats or isn't used (run the hook and measure it) |

Don't move a rule that must always apply out of CLAUDE.md to save tokens: rules that
aren't loaded aren't followed.

## 5. Trim

Ask which rows to apply, unless the user already said. Then, for each:

1. Back up the file (`<file>.bak-YYYYMMDD`).
2. Make the change, using `chunk-claude` for CLAUDE.md where it fits.
3. Re-run step 2 in the same folder and report before and after. A change only shows in a
   new session, so the second capture is the proof. No drop means say so and offer to revert.

## Data storage

Reads `check-launch-context.md` from the data folder. Captures go to `<outdir>`, or a
temporary folder. Writes nothing to the plugin.
