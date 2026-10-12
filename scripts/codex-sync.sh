#!/usr/bin/env bash
set -Eeuo pipefail

# Capture live settings; --publish also signs and pushes tracked changes to main.
REPO_DIR="$HOME/.dotfiles"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
LOCK_DIR="$STATE_DIR/snapshot.lock"
LOG_DIR="$HOME/Library/Logs"
mkdir -p "$STATE_DIR" "$LOG_DIR"
exec >>"$LOG_DIR/dotfiles-sync.log" 2>&1
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  exit 0
fi
write_state() {
  printf '{"status":"%s","updated_at":"%s"}\n' "$1" "$(date -u '+%FT%TZ')" >"$STATE_DIR/snapshot-state.json.tmp"
  mv "$STATE_DIR/snapshot-state.json.tmp" "$STATE_DIR/snapshot-state.json"
}
finish() {
  local code=$?
  if (( code )); then write_state failed; else write_state completed; fi
  printf '[%s] snapshot exit=%s\n' "$(date '+%F %T')" "$code"
  rmdir "$LOCK_DIR"
}
trap finish EXIT
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$HOME/.local/bin:$PATH"
write_state started
printf '[%s] snapshot started\n' "$(date '+%F %T')"
write_state running
# Preserve encryption boundaries; secret updates use dotfiles-secrets instead.
chezmoi --source "$REPO_DIR" re-add --exclude encrypted --no-tty
"$REPO_DIR/bin/dotfiles" packages-snapshot --quiet
"$REPO_DIR/bin/dotfiles" apps-snapshot --quiet
if [[ "${1:-}" == "--publish" ]]; then
  "$REPO_DIR/scripts/publish-dotfiles.sh"
fi
