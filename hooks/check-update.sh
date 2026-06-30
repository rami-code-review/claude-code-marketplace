#!/usr/bin/env bash
set -u

STATE_DIR="${HOME}/.claude/rami"
CACHE_FILE="${STATE_DIR}/.last-check"
DEBUG_LOG="${STATE_DIR}/update-check.log"
TTL_MIN=1440
LATEST_URL="https://raw.githubusercontent.com/rami-code-review/claude-code-marketplace/main/.claude-plugin/plugin.json"
CHANGELOG_URL="https://github.com/rami-code-review/claude-code-marketplace/blob/main/CHANGELOG.md"

log() { [ -n "${RAMI_DEBUG:-}" ] && printf '%s %s\n' "$(date -u +%FT%TZ)" "$1" >>"$DEBUG_LOG" 2>/dev/null; return 0; }

# One network check per day; silent on every other start and on any failure.
if [ -f "$CACHE_FILE" ] && [ -z "$(find "$CACHE_FILE" -mmin +"$TTL_MIN" 2>/dev/null)" ]; then
  exit 0
fi

mkdir -p "$STATE_DIR" 2>/dev/null || exit 0
touch "$CACHE_FILE" 2>/dev/null

extract_version() { sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1; }
valid_version() { case "$1" in ''|*[!0-9.]*) return 1 ;; *) return 0 ;; esac; }

local_json="${CLAUDE_PLUGIN_ROOT:-}/.claude-plugin/plugin.json"
if [ -z "${CLAUDE_PLUGIN_ROOT:-}" ] || [ ! -f "$local_json" ]; then
  log "no plugin.json under CLAUDE_PLUGIN_ROOT"; exit 0
fi

installed="$(extract_version < "$local_json")"
valid_version "$installed" || { log "installed version invalid: '${installed}'"; exit 0; }

latest="$(curl -fsS --max-time 4 "$LATEST_URL" 2>/dev/null | extract_version)"
valid_version "$latest" || { log "latest fetch/parse failed (curl error, 4xx/5xx, or non-version): '${latest}'"; exit 0; }

newer="$(awk -v a="$installed" -v b="$latest" '
  function norm(v,  n,arr,i,s){ split(v,arr,"."); s=""; for(i=1;i<=4;i++){ s=s sprintf("%010d",(arr[i]+0)) } return s }
  BEGIN { print (norm(b) > norm(a)) ? "1" : "0" }
')"
if [ "$newer" != "1" ]; then
  log "up to date (installed=${installed} latest=${latest})"; exit 0
fi

msg="Rami plugin update available: ${installed} -> ${latest}. Run /rami:upgrade to update."
ctx="The installed Rami plugin (${installed}) is behind the latest published version (${latest}). If the user wants to update, run /rami:upgrade. Changelog: ${CHANGELOG_URL}"
printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"},"systemMessage":"%s"}\n' "$ctx" "$msg"
log "nudged (installed=${installed} latest=${latest})"
exit 0
