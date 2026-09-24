# Manual restore inventory

Only software and setup that cannot be restored from `Brewfile` belongs here.
Downloaded installers, licenses, credentials, and private keys must not be committed.

## Powerlevel10k

- Source: https://github.com/romkatv/powerlevel10k
- Reason: the shell configuration currently loads `~/powerlevel10k/powerlevel10k.zsh-theme`.
- Restore: follow the upstream manual installation instructions and clone it to `~/powerlevel10k`.
- Verify: open a new interactive Zsh session and confirm the prompt loads without an error.

## Shorebird

- Source: https://docs.shorebird.dev/getting-started/
- Reason: installed under `~/.shorebird`; it is not currently represented in `Brewfile`.
- Restore: follow the official installation guide, then authenticate as required.
- Verify: `shorebird --version`

## Recovery-only setup

- Restore `~/.config/chezmoi/key.txt` from the Apple Passwords entry named `chezmoi age recovery key`, then set mode `600`.
- Recreate or select the Secretive Secure Enclave key named `notify-key`. Its private key is intentionally non-exportable and is never stored here.
