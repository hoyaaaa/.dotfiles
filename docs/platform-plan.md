# Platform scope and follow-up

One repository and main branch remain authoritative. This change separates the working macOS implementation; Fedora and Windows installation/application are not implemented or tested yet.

## Current macOS layout

- `packages/darwin/Brewfile`: installed package manifest; existing snapshot behavior is preserved.
- `scripts/darwin/`: macOS package maintenance and app discovery.
- `.chezmoitemplates/darwin/`: existing Bash, Profile, Zsh, and Git settings, rendered unchanged on macOS.
- `.chezmoiignore`: excludes macOS shell/Git templates, apps, signing, hooks, automation IDs, and machine credentials from other OSes. Shared editor settings and portable user skills remain in the source root.
- `bin/dotfiles`: stable macOS command entry point. Other OSes fail explicitly until their implementation is complete.
- Session-end snapshots copy live edits for the four macOS-only template fragments before re-add, preserving automatic capture.
- Existing paths for logs, Secretive, encrypted secret storage, Codex hooks and automatic main publication remain intact.

## Fedora follow-up

1. Inspect existing host settings and signing without reading secrets; preserve local overrides before applying anything.
2. Add Fedora shell/Git templates and native path handling, distro detection and a local profile (`general` or an explicitly selected role).
3. Implement DNF bootstrap/update and host-specific RPM/Flatpak inventory, separate from desired package lists.
4. Port secret helper to Python stdlib with wl-copy/wl-paste (Wayland), an explicitly available X11 alternative, and clear behavior for headless hosts.
5. Keep age identity local; support public configuration before restoring encrypted files.
6. Use the host's existing signing key, not Secretive paths; verify signatures after any history integration. Never create replacement private keys automatically.
7. Handle multiple main writers with conflict-preserving integration and normal pushes. Templates are source-edited: re-add does not capture rendered template changes.
8. Register machine-specific Codex automation rather than restoring a Mac thread ID. No background scheduler is added.
9. User validates Fedora rendering/diff and applies settings on their host.

## Windows plan only

Support native PowerShell (WSL is a distinct Linux environment), OS-specific config destinations, winget packages, clipboard access and existing local signing. Keep public skill instructions portable. Reuse common Python logic where justified and add a small PowerShell entry point; do not require Bash or deploy Unix/macOS hooks. Implementation is deferred.

## Verification ownership

The user requested to perform platform validation. No Fedora or Windows settings are applied by this change. Mac-specific template contents are retained verbatim; source layout and caller paths are reviewed before committing.
