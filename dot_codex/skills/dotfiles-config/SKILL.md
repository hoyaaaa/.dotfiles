---
name: dotfiles-config
description: Maintain the user's chezmoi-managed global settings, shell/editor configuration, and user-owned agent skills in ~/.dotfiles; keep changed configuration captured for restoration.
---

# Dotfiles Config

Use `/Users/hoya/.dotfiles` as the chezmoi source of truth. Inspect `bin/dotfiles`, the relevant source file, and its live target before changing settings.

- For a managed live file, edit it and run `chezmoi --source ~/.dotfiles re-add <exact-target>`. For a source edit, apply only its exact target; do not overwrite unrelated live changes.
- For a newly requested non-secret configuration or user-owned skill, add only its exact path with `chezmoi --source ~/.dotfiles add <exact-target>`. Built-in/plugin/app-owned skills, authentication caches, private keys, and logs stay outside this source.
- Use `$dotfiles-software` for package/app inventory and `$dotfiles-secrets` for secret values. Never print decrypted secrets or add a secret as plaintext.
- After configuration work, run `~/.dotfiles/bin/dotfiles snapshot`. It captures existing non-encrypted managed files and refreshes package/app inventories locally. New files require explicit registration; encrypted secrets use their helper.
- Codex session end captures local snapshots; the hourly Codex automation runs `~/.dotfiles/bin/dotfiles sync` to validate, sign, commit, and push tracked dotfiles updates directly to main under the user’s standing authorization. Inspect `~/.local/state/dotfiles/snapshot-state.json` and `~/Library/Logs/dotfiles-sync.log` for completion or failure. A completed sync includes verification of the signed local commit and matching remote main SHA; a snapshot alone is local.
- Preserve existing Git signing. The user explicitly authorized direct main publication for this dotfiles repository. Keep automatic publication limited to tracked files; review/register new paths explicitly. On signing, scan, index, or remote divergence failures, stop and report rather than force-pushing or disabling signing.
