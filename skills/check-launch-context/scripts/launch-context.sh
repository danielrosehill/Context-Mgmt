#!/usr/bin/env bash
# Capture what a fresh Claude Code session loads in DIR. No model call is made.
# Usage: launch-context.sh [DIR] [OUTDIR]
#   OUTDIR/interactive.txt  /context all from a real terminal session (the true total)
#   OUTDIR/headless.md      /context from `claude -p` (markdown tables, deferred tool sizes)
#   OUTDIR/launch.json      capture metadata
set -uo pipefail
dir=$(cd "${1:-$PWD}" && pwd) || exit 1
out=${2:-$(mktemp -d)}; mkdir -p "$out"; out=$(cd "$out" && pwd)
command -v claude >/dev/null || { echo "claude not on PATH" >&2; exit 1; }
# A child of a running session must not inherit that session's markers.
unset_args=()
while IFS= read -r v; do unset_args+=(-u "$v"); done < <(compgen -e | grep -E '^(CLAUDECODE|CLAUDE_CODE_(ENTRYPOINT|SESSION_ID|SSE_PORT|CHILD_SESSION|EXECPATH)|CLAUDE_EFFORT|CLAUDE_PID)$')
cd "$dir" || exit 1
env "${unset_args[@]}" timeout 120 claude -p "/context" --no-session-persistence > "$out/headless.md" 2> "$out/headless.err" </dev/null
status=ok
if ! command -v tmux >/dev/null; then status="no-tmux"
else
  t() { env "${unset_args[@]}" tmux -L launch-context-$$ "$@"; }
  trap 't kill-server 2>/dev/null' EXIT
  t -f /dev/null new-session -d -s p -x 200 -y 600 -c "$dir" claude
  cap() { t capture-pane -p -t p; }
  for _ in $(seq 60); do
    sleep 1; s=$(cap)
    # Never answer the trust dialog: that decision is the user's.
    if grep -qiE 'do you trust|trust this folder' <<<"$s"; then status="trust-dialog"; break; fi
    grep -q '^❯' <<<"$s" && break
  done
  if [ "$status" = ok ]; then
    sleep "${MCP_SETTLE:-12}"          # MCP servers connect after the prompt appears
    t send-keys -t p -l '/context all'; sleep 1.5; t send-keys -t p Enter
    status=timeout
    for _ in $(seq 30); do sleep 1; s=$(cap); grep -q 'Free space' <<<"$s" && { status=ok; break; }; done
    sleep 2
  fi
  cap | sed 's/[[:space:]]*$//' | cat -s > "$out/interactive.txt"
fi
printf '{"dir":"%s","claude":"%s","captured":"%s","interactive":"%s"}\n' \
  "$dir" "$(claude --version)" "$(date -u +%FT%TZ)" "$status" | tee "$out/launch.json"
echo "$out"
