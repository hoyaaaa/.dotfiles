---
name: manual-software-inventory
description: Maintain the user's recoverable Mac software inventory when installing, downloading, removing, auditing, or documenting apps and tools that may not be managed by Homebrew or the Mac App Store.
---

# Manual Software Inventory

Use `/Users/hoya/.dotfiles` as the source of truth.

1. Before installing software, use this strict source priority: Homebrew or Homebrew Cask first, the Mac App Store second, and a direct/manual install only when neither provides the intended official app.
2. For package-managed software, perform the requested operation and run `~/.dotfiles/bin/dotfiles packages-snapshot` after it succeeds.
3. For software that genuinely requires a direct download or custom installer, update `packages/manual.md` with its official source, why it is manual, restore steps, configuration location when useful, and a verification command or check.
4. Run `~/.dotfiles/bin/dotfiles apps-snapshot` after an app install or removal. Use `packages/discovered-apps.md` to find installed apps missing from both Homebrew Cask and the Mac App Store; it is an audit list, not proof that every listed app needs to be reinstalled.
5. Remove an inventory entry only after confirming the software was removed or is now represented in `Brewfile`.

Never commit installers, application bundles, license files, passwords, tokens, private keys, or copied secret values. Link to an official download page instead. Keep machine-specific notes out unless they are required to restore the setup.
