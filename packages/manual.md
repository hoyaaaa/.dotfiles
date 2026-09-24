# Manual restore inventory

Only software and setup that cannot be restored from `Brewfile` belongs here.
Downloaded installers, licenses, credentials, and private keys must not be committed.

## Burly

- Source: https://www.burly.click/
- Reason: the official macOS app is distributed directly and is unavailable through Homebrew and the Mac App Store.
- Restore: download it from the official site and move `Burly.app` to `/Applications`.
- Verify: open Burly and confirm it appears as a macOS default-browser option.

## ego lite

- Source: https://github.com/citrolabs/ego-lite
- Reason: distributed directly by CitroLabs and unavailable through Homebrew and the Mac App Store.
- Restore: install the latest signed macOS release from the official repository.
- Verify: launch `ego lite.app` and confirm its browser service starts.

## TrackPointD

- Source: no public upstream or installer was found; the installed bundle identifier is `com.user.trackpointd`.
- Reason: this appears to be a locally built helper and is unavailable through Homebrew and the Mac App Store.
- Restore: preserve the original source or signed installer outside this public repository, then install it to `~/Applications/TrackPointD.app`.
- Verify: launch it and confirm TrackPoint scrolling works.

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
