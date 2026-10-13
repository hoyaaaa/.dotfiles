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

## AWS Session Manager plugin

- Source: https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html
- Reason: the official Homebrew Cask requires a system installer with sudo; this machine uses the official package's binary at `~/.local/bin/session-manager-plugin` instead.
- Restore: fetch the official `session-manager-plugin` Cask package, expand it with `pkgutil --expand-full`, and install its binary to `~/.local/bin/session-manager-plugin` with mode `755`.
- Verify: `session-manager-plugin --version`

## Recovery-only setup

- Restore `~/.config/chezmoi/key.txt` from the Apple Passwords entry named `chezmoi age recovery key`, then set mode `600`.
- Recreate or select the Secretive Secure Enclave key named `notify-key`. Its private key is intentionally non-exportable and is never stored here.

## LM Studio headless runtime (llmster)

- Source: https://lmstudio.ai/docs/developer/core/headless
- Reason: LM Studio app is managed by Homebrew Cask, but its official headless runtime has no Homebrew formula or Mac App Store package.
- Restore: follow the official llmster installation guide; pass `--no-modify-path` to the installer when the shell PATH is managed separately.
- Storage: `~/.lmstudio/bin/lms`, `~/.lmstudio/llmster`; model weights live under `~/.lmstudio/models` and are re-downloaded.
- Verify: `~/.lmstudio/bin/lms daemon status` and `~/.lmstudio/bin/lms server status`.

## Qwen3.5 9B local model

- Source: https://huggingface.co/lmstudio-community/Qwen3.5-9B-GGUF
- Reason: model weights are downloaded separately from the LM Studio app and are not included in Brewfile.
- Restore: use LM Studio to download `lmstudio-community/Qwen3.5-9B-GGUF` with `Q4_K_M` quantization (about 5.6 GB).
- Verify: `~/.lmstudio/bin/lms ls` lists the model; `lms load` can load it.

## Fedora GPU inference: LM Studio llmster

- Official source: https://lmstudio.ai/docs/developer/core/headless
- Installed on Fedora with the official Linux installer; the headless vendor runtime is independent of the Mac desktop app.
- Restore: install llmster with the official installer, then copy `scripts/lmstudio-fedora-start.sh` to `~/.local/bin/lmstudio-server-start` and make it executable.
- Active model: `google/gemma-4-12B-it-qat-q4_0-gguf/gemma-4-12b-it-qat-q4_0.gguf` under `~/.lmstudio/models/`; restore the model separately, never commit the model binary.
- Load settings: context 16384, parallel 1, full GPU offload, Flash Attention, K/V cache q8_0. Set these as model defaults in LM Studio before starting the saved helper.
- For Codex compatibility, the Qwen template must render additional system messages instead of raising `System message must be at the beginning.` Preserve tool formatting.
- Verify on Fedora: `~/.lmstudio/bin/lms ps` and `nvidia-smi`.
- Mac entrypoint: `codex-fedora`, using the `fedora-gemma` Codex profile and direct Tailscale DNS access at `http://fedora.tailbce116.ts.net:1234/v1` (server bound only to its Tailscale address). The Mac launcher and profile are managed by chezmoi; authentication remains in the existing SSH configuration.

- CUDA runtime: llama.cpp 2.56.0 or later with Gemma 4 support. Main and chapter-worker context 16384; auto-compaction 12000. The previous Qwen model/profile remain available as a fallback.
