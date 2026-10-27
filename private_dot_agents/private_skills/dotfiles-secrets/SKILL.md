---
name: dotfiles-secrets
description: Reuse saved local or Bitwarden credentials before asking for passwords or API keys during authorized login, API, database, or server work; manage the age-encrypted chezmoi secret store. Excludes hosted secret-manager administration.
---

# Dotfiles Secrets

Use `~/.config/chezmoi-secrets/secrets.json` as the local source of truth. Its repository copy is encrypted with age. Use `scripts/secrets.sh` for every operation.

## Reuse before asking

- For authorized work requiring a password, API key, or other credential, first check existing authenticated sessions, CLI configuration, and connected tools without printing credentials. Prefer a working existing session.
- Before asking the user for a secret, run `~/.agents/skills/dotfiles-secrets/scripts/secrets.sh list` and match entry paths to the service, account, and environment. Inspect only paths, never values. Preserve legacy entry paths.
- If one stored entry clearly matches, use it for the already-authorized operation without asking the user to provide it again. If several match, ask which account/environment; do not ask for the secret value. Ask for new input only when no entry exists, the credential has been rejected, or genuinely new authentication (such as OTP) is required.
- For browser password entry, use the ego-lite skill: verify the intended site and account, focus the password input, run `scripts/secrets.sh copy <exact-path>`, and paste with the documented native keyboard shortcut. Do not read the clipboard into tool output, type a literal secret in code, inspect password-input values, or capture a page that reveals it. Verify login from non-secret success indicators.
- For CLI/API credentials, use an existing trusted integration that consumes the secret privately in its runtime with redacted output. Use `scripts/secrets.sh exec-env <path> <ENV_NAME> [...] -- <command> [args...]` when a local command accepts credentials through environment variables; the helper injects values without printing them. The `copy` command only supplies the clipboard and is not a generic CLI/API injection helper. If no private integration exists, explain that limitation and prepare the integration instead of asking the user to resend an already stored value. Never use clipboard-reading or secret-reading commands in a way that returns their output to the model.
- Reusing a credential does not authorize unrelated actions, account changes, or storing newly obtained credentials.

## Bitwarden: use the official bw CLI directly

The user explicitly requested direct use of the official `bw` CLI, with credentials loaded privately from the existing chezmoi secret store when needed. Do not create or use a separate Bitwarden wrapper, daemon, or persistent session cache.

- Reuse `unboxers/bitwarden/cli/client_id`, `client_secret`, and `master_password` when present. The user authorized age-encrypted master-password storage. If the master-password entry is absent, ask the user to save it once through the existing `secrets.sh set` mechanism, never in chat.
- Use the existing `secrets.sh exec-env` to supply `BW_CLIENTID`, `BW_CLIENTSECRET`, and a temporary master-password environment variable to a short-lived shell/process. Run official `bw login --apikey` only when unauthenticated, then `bw unlock --passwordenv <variable> --raw`. Capture the session privately as `BW_SESSION`; never print it. Remove the master-password variable before other child commands and run `bw sync`.
- Search with official `bw list items`, filter inside the private runtime for the exact username and intended URI hostname, and emit only item IDs/names/usernames. Resolve ambiguous matches before selecting an item.
- For browser login, verify the domain and username, focus the password field in ego-lite, and pipe `bw get password <selected-uuid>` directly to `pbcopy` with no value in command arguments or output. Check the retrieval exit status before pasting, use the native paste shortcut, and never read the clipboard into model context.
- Always run `bw lock` in cleanup and discard `BW_SESSION` when done. Keep decrypted credentials/session keys out of files, shell profiles, logs, and Git. Avoid concurrent `bw unlock` calls because a new session invalidates older keys.

## Safety boundary

- Never print, read back, summarize, search within, or expose a decrypted value to model context, command output, logs, or shell history.
- Copy an existing value with `scripts/secrets.sh copy <exact-path>`; it writes only to the platform clipboard.
- To add or replace a value, ask the user to pipe it privately into `scripts/secrets.sh set <exact-path>` in their own terminal. Do not provide or pipe the value for them.
- Listing entry paths is allowed, but show only what the task requires.
- Before removing an entry, confirm its exact path. The encrypted Git history remains recoverable.
- Never commit the decrypted JSON file or the age identity.

## Paths and workflow

- Preserve existing paths. For new entries, use a clear hierarchy such as `<scope>/<service>/<environment-or-account>[/<field>]`.
- After a successful set or remove, the helper refreshes the encrypted chezmoi source automatically.
- Verify metadata or exit status only. If the user needs to view a value, tell them to copy it and paste it into the intended application privately.

- For authorized dotfiles publication, use `$dotfiles-config` and `~/.dotfiles/bin/dotfiles sync` on macOS: validate and preserve local changes, integrate remote main, update managed user skills, then sign/push. A remote-ahead state is handled by pull/merge; actual conflicts or signing failures preserve work and stop.
