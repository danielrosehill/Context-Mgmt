---
name: check-launch-context
description: Check launch context by running /context in a fresh session, suggest ways to minimise the load, then apply them.
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
session. `/context` is a local command, so it makes no model call. Set `BILLED=1` for a billed baseline too,
which does make one. Do that whenever trimming may follow.

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
- **`/context` can hide a saving.** Disabling skills cut its Skills line and raised its
  System tools line by about as much, leaving the total flat, while billed tokens fell. Judge a
  change on `billed_first_turn` (`BILLED=1`, one tiny call, under $0.01 on Haiku when
  measured). Compare runs on the same model only: it is a print-mode figure, for before and after.
- The system prompt is fixed. Built-in skills and tools are not.

## 4. Suggest remediation

Always follow the measurement with suggestions. Give a table, largest saving first: item,
tokens, fix, estimated saving, what is lost, scope (user or project). Read each candidate
before judging it, and end with the few you recommend and the total they would save.

| Surface | Fixes, gentlest first |
|---|---|
| CLAUDE.md | Remove duplicates and stale text. Move path-specific rules to `.claude/rules/` with `paths:`. Move reference material to files read on demand, or a subfolder's CLAUDE.md. Skip irrelevant ancestors with `claudeMdExcludes` |
| Plugins | Set `enabledPlugins` to false at user level, and true in the projects that use it |
| Skills | `skillOverrides`: `name-only`, `user-invocable-only` or `off`. For your own: shorten the description, or `disable-model-invocation: true` |
| Built-in skills | `skillOverrides` one by one, or `disableBundledSkills` for all |
| MCP servers | Remove duplicates, move single-project servers out of user scope, disable per project in `/mcp`. Check `ENABLE_TOOL_SEARCH` isn't `false`, and that `alwaysLoad` is needed where set |
| Custom agents | Shorten descriptions. Move single-project agents to that project's `.claude/agents/` |
| Built-in tools | `permissions.deny` with a bare tool name removes it. Never deny `ToolSearch` |
| Git instructions | `includeGitInstructions: false` if your own rules cover commits |
| SessionStart hooks | Run each and measure its output. Print only on a problem |
| Memory index | Prune `MEMORY.md`. Topic files load on demand |

Measured 2026-11-23, 2.1.330, Haiku, print mode, empty folder, 19,928 billed at baseline
(three identical runs). One setup, so a guide to size only:

| Change | Billed tokens |
|---|---|
| Deny `Agent` | -3,273 |
| `disableBundledSkills` | -1,338 |
| Disable two plugins (10 skills) | -668 |
| Deny one MCP server (25 deferred tools) | -485 |
| `includeGitInstructions: false` | -480 |
| Deny two custom agents | -347 |

The other fixes come from the Claude Code docs and were not measured. Denying `Agent`
removes subagents, so offer it only where they are never used. Don't move a rule that must
always apply out of CLAUDE.md: rules that aren't loaded aren't followed.

**Canopy:** if a Canopy server is connected (a `catalogue__search` tool is in the session),
use `skill:canopy-manager/check-launch-context` instead. It owns what may be trimmed there.

## 5. Apply and re-measure

Ask which rows to apply, unless the user already said. Then, for each:

1. Back up the file (`<file>.bak-YYYYMMDD`), and make the change.
2. Repeat step 2 in the same folder with `BILLED=1`, and report before and after.
3. No drop in billed tokens, or something needed is gone: offer to revert.

Finish with what was applied, what was declined, and the total saved.

## Data storage

Reads `check-launch-context.md` from the data folder. Captures go to `<outdir>`, or a
temporary folder. Writes nothing to the plugin.
