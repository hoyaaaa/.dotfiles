#!/usr/bin/env bash
set -Eeuo pipefail

# Codex hooks send event JSON on stdin; this sync does not need its contents.
cat >/dev/null || true

REPO_DIR="$HOME/.dotfiles"
LOCK_DIR="${TMPDIR:-/tmp}/com.hoyaaaa.dotfiles-codex-sync.lock"
LOG_DIR="$HOME/Library/Logs"
LOG_FILE="$LOG_DIR/dotfiles-sync.log"

mkdir -p "$LOG_DIR"
exec >>"$LOG_FILE" 2>&1
trap 'printf "[%s] sync failed\n" "$(date "+%F %T")"; exit 0' ERR

if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  exit 0
fi
trap 'rmdir "$LOCK_DIR"' EXIT

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$HOME/.local/bin:$PATH"
branch="$(git -C "$REPO_DIR" branch --show-current)"
branch="${branch:-main}"

readd_codex_targets() {
  command -v chezmoi >/dev/null 2>&1 || return 0
  chezmoi --source "$REPO_DIR" re-add \
    "$HOME/.codex/AGENTS.md" \
    "$HOME/.codex/hooks.json" \
    "$HOME/.codex/skills"
}

apply_managed_agents() {
  command -v chezmoi >/dev/null 2>&1 || return 0
  chezmoi --source "$REPO_DIR" apply \
    --force --no-tty --skip-secrets \
    "$HOME/.codex" "$HOME/.agents"
}

readd_codex_targets
git -C "$REPO_DIR" pull --rebase --autostash origin "$branch"
"$REPO_DIR/bin/dotfiles" packages-snapshot --quiet
"$REPO_DIR/bin/dotfiles" apps-snapshot --quiet
git -C "$REPO_DIR" add -u
git -C "$REPO_DIR" add -- \
  Brewfile \
  README.md \
  bin/dotfiles \
  dot_codex \
  launchd/com.hoyaaaa.dotfiles-maintenance.plist \
  packages/discovered-apps.md \
  packages/manual.md \
  private_dot_agents \
  private_dot_config/private_chezmoi-secrets \
  scripts/codex-sync.sh \
  scripts/manual-apps-snapshot.sh \
  scripts/update-packages.sh

if git -C "$REPO_DIR" diff --cached --quiet; then
  apply_managed_agents
  exit 0
fi

blocked_name_pattern='(^|/)(\.env($|\.)|credentials$|hosts\.yml$|rclone\.conf$)|\.(pem|key|p12|pfx)$'
if git -C "$REPO_DIR" diff --cached --name-only | rg -q "$blocked_name_pattern"; then
  printf '[%s] sync blocked: secret-bearing filename\n' "$(date '+%F %T')"
  exit 0
fi

if git -C "$REPO_DIR" diff --cached --no-ext-diff --unified=0 | rg -q '(BEGIN (RSA |OPENSSH |EC )?PRIVATE KEY|AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{30,}|gh[pousr]_[0-9A-Za-z]{30,})'; then
  printf '[%s] sync blocked: credential-like content\n' "$(date '+%F %T')"
  exit 0
fi

git -C "$REPO_DIR" commit -m "chore: sync dotfiles $(date '+%F %T')"
git -C "$REPO_DIR" push origin "$branch"
apply_managed_agents
printf '[%s] sync completed\n' "$(date '+%F %T')"
