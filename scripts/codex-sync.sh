#!/usr/bin/env bash
set -Eeuo pipefail

# Capture live settings; --publish also signs and pushes tracked changes to main.
REPO_DIR="$HOME/.dotfiles"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
if [[ "${DOTFILES_SYNC_LOCKED:-}" != "$$" ]]; then
  exec python3 "$REPO_DIR/scripts/with-sync-lock.py" "$0" "$@"
fi
LOG_DIR="$HOME/Library/Logs"
mkdir -p "$STATE_DIR" "$LOG_DIR"
exec >>"$LOG_DIR/dotfiles-sync.log" 2>&1
write_state() {
  printf '{"status":"%s","updated_at":"%s"}\n' "$1" "$(date -u '+%FT%TZ')" >"$STATE_DIR/snapshot-state.json.tmp"
  mv "$STATE_DIR/snapshot-state.json.tmp" "$STATE_DIR/snapshot-state.json"
}
finish() {
  local code=$?
  if (( code )); then write_state failed; else write_state completed; fi
  printf '[%s] snapshot exit=%s\n' "$(date '+%F %T')" "$code"
}
trap finish EXIT
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$HOME/.local/bin:$PATH"
write_state started
printf '[%s] snapshot started\n' "$(date '+%F %T')"
write_state running
# These wrappers contain only a macOS source fragment. Preserve automatic
# capture of live edits even though chezmoi re-add skips template files.
if [[ "$(uname -s)" == Darwin ]]; then
  for name in bashrc gitconfig profile zshrc; do
    live="$HOME/.$name"
    fragment="$REPO_DIR/.chezmoitemplates/darwin/dot_$name"
    if [[ -f "$live" && -f "$fragment" ]] && ! cmp -s "$live" "$fragment"; then
      cp "$live" "$fragment"
    fi
  done
fi
# Preserve encryption boundaries; secret updates use dotfiles-secrets instead.
chezmoi --source "$REPO_DIR" re-add --exclude encrypted --no-tty
"$REPO_DIR/bin/dotfiles" packages-snapshot --quiet
"$REPO_DIR/bin/dotfiles" apps-snapshot --quiet
if [[ "${1:-}" == "--publish" ]]; then
  "$REPO_DIR/scripts/publish-dotfiles.sh"
fi
