#!/usr/bin/env bash
set -Eeuo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_DIR"
[[ "$(git branch --show-current)" == main ]] || { echo 'Publication requires dotfiles main.' >&2; exit 1; }
[[ "$(git remote get-url origin)" == 'git@github.com:hoyaaaa/.dotfiles.git' ]] || { echo 'Unexpected dotfiles origin.' >&2; exit 1; }
git diff --cached --quiet || { echo 'Existing staged changes: review before publishing.' >&2; exit 1; }
/bin/sh "$HOME/.codex/skills/secretive/scripts/ensure-notify-key.sh"
# Use existing GitHub HTTPS authentication; commit signing still uses Secretive.
git -c 'credential.helper=!gh auth git-credential' fetch https://github.com/hoyaaaa/.dotfiles.git main:refs/remotes/origin/main
git merge-base --is-ancestor origin/main HEAD || { echo 'Remote main advanced or diverged: reconcile before publishing.' >&2; exit 1; }
# New paths require review and registration; ordinary automatic sync stages tracked files only.
git add -u
cleanup_index() {
  local code=$?
  # On failed validation/signing, undo only our staging and preserve working files.
  if (( code )); then git reset --quiet; fi
}
trap cleanup_index EXIT
git diff --cached --check
python3 "$REPO_DIR/scripts/check-staged.py"
bash -n "$REPO_DIR/bin/dotfiles" "$REPO_DIR/scripts/codex-sync.sh" "$REPO_DIR/scripts/publish-dotfiles.sh" "$REPO_DIR/scripts/darwin/update-packages.sh"
python3 "$REPO_DIR/scripts/tests/test_snapshot.py"
python3 "$REPO_DIR/scripts/tests/test_staged.py"
if ! git diff --cached --quiet; then
  git commit -S -m "chore: sync dotfiles $(date '+%F %T')"
fi
git verify-commit HEAD
git -c 'credential.helper=!gh auth git-credential' push https://github.com/hoyaaaa/.dotfiles.git HEAD:main
local_sha="$(git rev-parse HEAD)"
remote_sha="$(git -c 'credential.helper=!gh auth git-credential' ls-remote https://github.com/hoyaaaa/.dotfiles.git refs/heads/main | awk '{print $1}')"
[[ "$local_sha" == "$remote_sha" ]] || { echo 'Remote SHA changed; inspect before retrying.' >&2; exit 1; }
printf 'Verified dotfiles main: %s\n' "$local_sha"
