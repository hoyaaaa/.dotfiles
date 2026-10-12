---
name: dotfiles-secrets
description: Reuse saved local credentials before asking for passwords or API keys during authorized login, API, database, or server work; also manage the age-encrypted chezmoi secret store. Excludes hosted secret-manager administration.
---

# Dotfiles Secrets

Use `~/.config/chezmoi-secrets/secrets.json` as the local source of truth. Its repository copy is encrypted with age. Use `scripts/secrets.sh` for every operation.

## Reuse before asking

- For authorized work requiring a password, API key, or other credential, first check existing authenticated sessions, CLI configuration, and connected tools without printing credentials. Prefer a working existing session.
- Before asking the user for a secret, run `/Users/hoya/.agents/skills/dotfiles-secrets/scripts/secrets.sh list` and match entry paths to the service, account, and environment. Inspect only paths, never values. Preserve legacy entry paths.
- If one stored entry clearly matches, use it for the already-authorized operation without asking the user to provide it again. If several match, ask which account/environment; do not ask for the secret value. Ask for new input only when no entry exists, the credential has been rejected, or genuinely new authentication (such as OTP) is required.
- For browser password entry, use the ego-lite skill: verify the intended site and account, focus the password input, run `scripts/secrets.sh copy <exact-path>`, and paste with the documented native keyboard shortcut. Do not read the clipboard into tool output, type a literal secret in code, inspect password-input values, or capture a page that reveals it. Verify login from non-secret success indicators.
- For CLI/API credentials, use an existing trusted integration that consumes the secret privately in its runtime with redacted output. The `copy` command only supplies the clipboard; it is not a generic CLI/API injection helper. If no private integration exists, explain that limitation and prepare the integration instead of asking the user to resend an already stored value. Never use `pbpaste` or secret-reading commands in a way that returns their output to the model.
- Reusing a credential does not authorize unrelated actions, account changes, or storing newly obtained credentials.

## Safety boundary

- Never print, read back, summarize, search within, or expose a decrypted value to model context, command output, logs, or shell history.
- Copy an existing value with `scripts/secrets.sh copy <exact-path>`; it writes only to the macOS clipboard.
- To add or replace a value, ask the user to run `pbpaste | scripts/secrets.sh set <exact-path>` in their own terminal. Do not provide or pipe the value for them.
- Listing entry paths is allowed, but show only what the task requires.
- Before removing an entry, confirm its exact path. The encrypted Git history remains recoverable.
- Never commit the decrypted JSON file or the age identity.

## Paths and workflow

- Preserve existing paths. For new entries, use a clear hierarchy such as `<scope>/<service>/<environment-or-account>[/<field>]`.
- After a successful set or remove, the helper refreshes the encrypted chezmoi source automatically.
- Verify metadata or exit status only. If the user needs to view a value, tell them to copy it and paste it into the intended application privately.
