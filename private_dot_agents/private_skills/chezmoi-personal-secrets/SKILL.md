---
name: chezmoi-personal-secrets
description: Manage the user's personal passwords, API keys, notes, and other local secrets in the age-encrypted chezmoi store. Use when the user asks to store, organize, list, copy, update, or remove a personal secret. Do not use for deployment secrets or hosted secret managers.
---

# Chezmoi Personal Secrets

Use `~/.config/chezmoi-secrets/secrets.json` as the local source of truth. Its repository copy is encrypted with age. Use `scripts/secrets.sh` for every operation.

## Safety boundary

- Never print, read back, summarize, search within, or expose a decrypted value to model context, command output, logs, or shell history.
- Copy an existing value with `scripts/secrets.sh copy <exact-path>`; it writes only to the macOS clipboard.
- To add or replace a value, ask the user to run `pbpaste | scripts/secrets.sh set <exact-path>` in their own terminal. Do not provide or pipe the value for them.
- Listing entry paths is allowed, but show only what the task requires.
- Before removing an entry, confirm its exact path. The encrypted Git history remains recoverable.
- Never commit the decrypted JSON file or the age identity.

## Paths and workflow

- Use `personal/<service>/<account-or-host>[/<field>]` for personal entries.
- Use `unboxers/<service>/<environment>/<component>/<account-or-role>[/<field>]` for organization or project entries.
- After a successful set or remove, the helper refreshes the encrypted chezmoi source automatically.
- Verify metadata or exit status only. If the user needs to view a value, tell them to copy it and paste it into the intended application privately.
