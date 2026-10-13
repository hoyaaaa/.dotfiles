#!/usr/bin/env bash
set -Eeuo pipefail
# Parse the full workflow before execution: a pull may update this script itself.
main() {
  REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  cd "$REPO_DIR"
  [[ "$(git branch --show-current)" == main ]] || { echo 'Publication requires dotfiles main.' >&2; exit 1; }
  [[ "$(git remote get-url origin)" == 'git@github.com:hoyaaaa/.dotfiles.git' || "$(git remote get-url origin)" == 'https://github.com/hoyaaaa/.dotfiles.git' ]] || { echo 'Unexpected dotfiles origin.' >&2; exit 1; }
  [[ ! -f .git/MERGE_HEAD ]] || { echo 'Resolve the existing merge before syncing.' >&2; exit 1; }
  /bin/sh "$HOME/.codex/skills/secretive/scripts/ensure-notify-key.sh"
  stage_tracked_changes
  # Leave staged changes intact on failure for review; do not reset a conflict index.
  git diff --cached --check
  python3 "$REPO_DIR/scripts/check-staged.py"
  check_workflow
  if ! git diff --cached --quiet; then
    git commit -S -m "chore: sync dotfiles $(date '+%F %T')"
    rm -f "$(git rev-parse --git-path dotfiles-sync.pending)"
  fi
  # Preserve existing commit signatures; a divergent history receives a signed merge.
  # No autostash: tracked local changes were validated and committed above.
  git -c 'credential.helper=!gh auth git-credential' pull --no-rebase --no-edit -S https://github.com/hoyaaaa/.dotfiles.git main
  git diff --check
  check_workflow
  git verify-commit HEAD
  # Apply only repository-managed, non-encrypted agent files; app-owned skills
  # and secret values stay outside the update. Conflicting live edits cause failure.
  chezmoi --source "$REPO_DIR" apply --recursive --no-tty --exclude encrypted \
    "$HOME/.codex/AGENTS.md" "$HOME/.codex/skills" "$HOME/.agents/skills"
  git -c 'credential.helper=!gh auth git-credential' push https://github.com/hoyaaaa/.dotfiles.git HEAD:main
  local_sha="$(git rev-parse HEAD)"
  remote_sha="$(git -c 'credential.helper=!gh auth git-credential' ls-remote https://github.com/hoyaaaa/.dotfiles.git refs/heads/main | awk '{print $1}')"
  [[ "$local_sha" == "$remote_sha" ]] || { echo 'Remote SHA changed; inspect before retrying.' >&2; exit 1; }
  printf 'Verified dotfiles main: %s\n' "$local_sha"
}
check_workflow() {
  bash -n "$REPO_DIR/bin/dotfiles" "$REPO_DIR/scripts/codex-sync.sh" "$REPO_DIR/scripts/publish-dotfiles.sh" "$REPO_DIR/scripts/darwin/update-packages.sh"
  python3 "$REPO_DIR/scripts/tests/test_snapshot.py"
  python3 "$REPO_DIR/scripts/tests/test_staged.py"
  python3 "$REPO_DIR/scripts/tests/test_sync_resume.py"
}
stage_tracked_changes() {
  local pending fingerprint
  pending="$(git rev-parse --git-path dotfiles-sync.pending)"
  fingerprint="$(git rev-parse HEAD) $(git write-tree)"
  if ! git diff --cached --quiet; then
    [[ -f "$pending" && "$(cat "$pending")" == "$fingerprint" ]] || {
      echo 'Staged index is not a matching prior sync attempt; preserve for review.' >&2
      return 1
    }
  fi
  git add -u
  printf '%s %s\n' "$(git rev-parse HEAD)" "$(git write-tree)" >"$pending"
}
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then main "$@"; fi
