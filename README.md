# Context-Mgmt

Context management for Claude Code: measure and trim what a fresh session loads, checkpoint cluttered sessions, chunk `CLAUDE.md`, and keep `CONTEXT.md` and `CLAUDE.md` in sync.

Split out of [Claude-Rudder](https://github.com/danielrosehill/Claude-Rudder) on 2026-11-23.

## Skills

- `check-launch-context`: run `/context` in a new terminal session, suggest ways to minimise the startup load, apply and re-measure
- `context-gate`: checkpoint a cluttered session into a handover plan
- `context-break-evaluator`: criteria for starting a fresh session
- `chunk-claude-md`: prune a bloated `CLAUDE.md`
- `context-workflow-reference`: the `CONTEXT.md` / `CLAUDE.md` two-file workflow

## Commands

`add-to-context`, `remove-from-context`, `manual-context-update`, `chunk-claude`, `chunk-repo-context`, `context-to-claude`, `claude-to-context`, `context-health-check`, `should-i-start-fresh`

## Also included

Agents `context-converter` and `context-manager`, and hooks that detect `CONTEXT.md` at session start and remind you to keep the pair in sync.

## Install

```
/plugin marketplace add danielrosehill/Claude-Code-Plugins
/plugin install context-mgmt@danielrosehill
```

Optional private notes for a skill go in `~/.claude-user-data/context-mgmt/<skill-name>.md`.

## License

MIT
