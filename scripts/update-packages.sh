#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCK_DIR="${TMPDIR:-/tmp}/com.hoyaaaa.dotfiles-maintenance.lock"
LOG_DIR="$HOME/Library/Logs"
LOG_FILE="$LOG_DIR/dotfiles-update.log"

mkdir -p "$LOG_DIR"
if [[ -f "$LOG_FILE" ]] && [[ $(stat -f %z "$LOG_FILE") -gt 5242880 ]]; then
  mv "$LOG_FILE" "$LOG_FILE.1"
fi
exec >>"$LOG_FILE" 2>&1

if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  printf '%s already running\n' "$(date '+%F %T')"
  exit 0
fi
trap 'rmdir "$LOCK_DIR"' EXIT

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$HOME/.local/bin:$PATH"
printf '\n[%s] package update started\n' "$(date '+%F %T')"

if command -v brew >/dev/null 2>&1; then
  brew update
  brew bundle install --no-upgrade --file="$REPO_DIR/Brewfile"
  brew upgrade
fi

if command -v pipx >/dev/null 2>&1; then
  pipx upgrade-all || true
fi

if command -v uv >/dev/null 2>&1; then
  uv tool upgrade --all || true
fi

if command -v npm >/dev/null 2>&1; then
  npm update --global || true
fi

if command -v rustup >/dev/null 2>&1; then
  rustup update || true
fi

"$REPO_DIR/bin/dotfiles" packages-snapshot --quiet
"$REPO_DIR/bin/dotfiles" apps-snapshot --quiet

# Synchronize only files that are already tracked, plus the package manifest.
# New untracked files are deliberately ignored so an accidental secret cannot
# be published merely by placing it in the repository directory.
branch="$(git -C "$REPO_DIR" branch --show-current)"
branch="${branch:-main}"
if git -C "$REPO_DIR" pull --rebase --autostash origin "$branch"; then
  git -C "$REPO_DIR" add -u
  git -C "$REPO_DIR" add -- Brewfile
  if ! git -C "$REPO_DIR" diff --cached --quiet; then
    git -C "$REPO_DIR" commit -m "chore: sync dotfiles $(date +%F)"
  fi
  git -C "$REPO_DIR" push origin "$branch"
else
  echo 'Remote synchronization skipped because the rebase did not complete.'
fi

printf '[%s] package update completed\n' "$(date '+%F %T')"
