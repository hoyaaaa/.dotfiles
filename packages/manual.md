# Manual restore inventory

Only software and setup that cannot be restored from `Brewfile` belongs here.
Downloaded installers, licenses, credentials, and private keys must not be committed.

## Default browser setup

- Use the macOS-provided Safari with profiles 개인, 회사, 베이스. Set both HTTP and HTTPS handlers to `local.hoya.safari-link-chooser` so external links prompt for 개인/회사/베이스; HTML files remain associated with Safari.
- Bookmarks are shared by Safari profiles; keep imported Orion bookmarks in profile-named folders. History and login cookies are isolated by profile.
- Restore private data from a separate local backup. Never add browser data, cookies, passwords, or import archives to dotfiles.
- Orion and its legacy launchers/chooser were removed after Safari verification. Private source data and removal backups remain under `~/Library/Application Support/Browser Migration/2026-11-03/`.
- Active tabs and tab groups were explicitly excluded from the Safari migration.

## Safari profile launchers and optional link chooser

- Safari profile symbols: 개인 uses person, 회사 uses bag, 베이스 uses house; these native profile settings sync through iCloud.

- Dock uses one native Safari icon; choose a profile through its New Window submenu. Optional profile launchers remain in Applications, but are not pinned because running windows belong to Safari.

- Source: chezmoi-managed `~/.local/share/safari-profile-tools/`; locally built with AppleScript, Swift/AppKit, Python, and native macOS tools. No third-party launcher dependency.
- Restore: create the three Korean-named profiles in Safari, then run `python3 ~/.local/share/safari-profile-tools/install.py`.
- Installed apps: `~/Applications/Safari Profiles/Safari - 개인.app`, `Safari - 회사.app`, `Safari - 베이스.app`, and `~/Applications/Safari Link Chooser.app`.
- The profile helpers use Safari's named menus and reuse matching existing windows. Safari stays one browser process. Korean Safari menus and macOS Automation/Accessibility access are required; arbitrary group names can prevent window-title matching.
- The chooser handles HTTP/HTTPS links and prompts for a Safari profile. Its installer does not change default handlers or install any background launch agent.
- Verify: run `~/Applications/Safari Link Chooser.app/Contents/MacOS/SafariLinkChooser --self-test`, then test each launcher twice and confirm profile/window reuse before putting it in the Dock.


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

## Fedora GPU inference: LM Studio llmster

- Official source: https://lmstudio.ai/docs/developer/core/headless
- Installed on Fedora with the official Linux installer; the headless vendor runtime is independent of the Mac desktop app.
- Restore: install llmster with the official installer, then copy `scripts/lmstudio-fedora-start.sh` to `~/.local/bin/lmstudio-server-start` and make it executable.
- Active model: `google/gemma-4-12B-it-qat-q4_0-gguf/gemma-4-12b-it-qat-q4_0.gguf` under `~/.lmstudio/models/`; restore the model separately, never commit the model binary.
- Load settings: context 32768, parallel 1, GPU offload ratio 0.8 (32K context fits RTX 3070 VRAM), Flash Attention, K/V cache q8_0. Set these as model defaults in LM Studio before starting the saved helper.
- For Codex compatibility, the Qwen template must render additional system messages instead of raising `System message must be at the beginning.` Preserve tool formatting.
- Verify on Fedora: `~/.lmstudio/bin/lms ps` and `nvidia-smi`.
- Mac entrypoint: `codex-fedora`, using the `fedora-gemma` Codex profile and direct WireGuard access at `http://10.44.0.1:1234/v1` (server bound only to its WireGuard address). The Mac launcher and profile are managed by chezmoi; authentication remains in the existing SSH configuration.

- CUDA runtime: llama.cpp 2.56.0 or later with Gemma 4 support. Main and chapter-worker context 32768; auto-compaction 8000. The previous Qwen model/profile remain available as a fallback.

## OpenCodex (Mac and Fedora)

- Source: https://github.com/lidge-jun/opencodex
- Manual install: no Homebrew formula; npm package `@bitkyc08/opencodex@2.84.0`, global prefix `~/.local`.
- Restore: apply `~/.opencodex/config.json`, then run `run_onchange_after_20-opencodex-service.sh` with Node/npm on PATH.
- Each computer runs its own loopback-only OpenCodex on port 10100; Mac connects directly to Fedora LM Studio via WireGuard `10.44.0.1:1234/v1`.
- Mac Gemma entrypoint: `opencodex-fedora`; `codex-fedora` delegates to it for compatibility. No SSH inference tunnel.
- Model: `lm-studio/gemma-4-12b-it-qat`; context 32768, compaction 8000.
- Verify: `opencodex ready`, `opencodex provider test lm-studio`, and a Codex response through the proxy.

## Fedora long-context writing configuration

- Active model: existing Qwen3.5-9B Q4_K_M, context 65536, parallel 1, full GPU offload, Flash Attention, Q4_0 K/V caches.
- Project compaction: 18000; OpenCodex LM Studio cap 65536. Gemma remains on disk as a fallback.
- Q4 KV cache trades precision for memory; compare writing quality on actual manuscripts.

## Fedora Qwen 4B 128K trial

- Model: lmstudio-community/Qwen3.5-4B-GGUF/Qwen3.5-4B-Q4_K_M.gguf; restore from https://huggingface.co/lmstudio-community/Qwen3.5-4B-GGUF .
- Active context 131072; parallel 1; full GPU offload; Q4_0 K/V cache; Flash Attention. Project compaction 104857 (80% of 131072).
- Previous Qwen 9B and Gemma remain on disk; only active 4B is selected in OpenCodex to avoid advertising the same context cap for differently loaded models.

## Active Fedora Qwen 9B 128K configuration

- Qwen3.5-9B Q4_K_M restored as active model; previous 4B remains on disk.
- Context 131072, project compaction 104857 (80%), parallel 1, Q4_0 K/V cache, GPU offload 0.75.
- Startup helper and OpenCodex Home selection use qwen3.5-9b; Mac Child receives Home catalog.

## OpenCodex independent routing

- Mac Remote Link Child disconnected; both Mac and Fedora independently manage their own providers and credentials.
- Mac Codex → Mac loopback OpenCodex :10100 → Fedora LM Studio over WireGuard 10.44.0.1:1234. No remote OpenCodex relay.

- Mac OpenCodex LM Studio provider uses `codexToolMode: shell`; routed Qwen exposes native exec_command instead of code_mode_only JavaScript wrapper.

## Xcode 26.3 (Apple silicon)

- Source: https://developer.apple.com/download/all/?q=Xcode%2026.3
- Reason: Homebrew has no Xcode cask; the current Mac App Store version requires a newer macOS than this installation.
- Restore: sign in to Apple Developer, download the official Apple silicon XIP, expand into `/Applications`, and complete Xcode first-launch setup.
- Installed app: `/Applications/Xcode.app`. Initial license and component setup still pending as of 2026-10-29.
- Verify: `/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -version` after first-launch setup.
- Signing accounts, certificates, provisioning profiles, and AAC approval must be configured separately; never store credentials here.
