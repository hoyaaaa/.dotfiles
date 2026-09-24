# hoyaaaa dotfiles

macOS configuration and package maintenance managed with chezmoi from this repository.

## Commands

```sh
~/.dotfiles/bin/dotfiles install
~/.dotfiles/bin/dotfiles status
~/.dotfiles/bin/dotfiles update
~/.dotfiles/bin/dotfiles packages-snapshot
~/.dotfiles/bin/dotfiles bootstrap
```

- `install` applies managed files with chezmoi and registers weekly maintenance.
- `bootstrap` installs missing Homebrew dependencies from `Brewfile` on a new Mac.
- `update` updates Homebrew, pipx, uv, npm, and rustup packages that are installed.
- `packages-snapshot` refreshes `Brewfile` from the current Homebrew state.

## Automation

- A global Codex `Stop` hook refreshes `Brewfile` after package installs or removals,
  then commits and pushes tracked dotfiles changes.
- `launchd` runs package maintenance every Sunday at 10:00 local time.
- Weekly maintenance commits tracked configuration and `Brewfile`, rebases, and pushes to `origin`.
- Untracked files are never included in the automatic commit.
- Update logs are written to `~/Library/Logs/dotfiles-update.log`.

## Security boundary

Public preferences are stored as plain source files. Manually maintained connection
and credential files are stored only as age-encrypted chezmoi source files. Private
keys, credential databases, authentication caches, certificates, histories, and logs
remain local and must never be committed.

The age identity is stored only at `~/.config/chezmoi/key.txt`; its recovery copy
lives in Apple Passwords.
