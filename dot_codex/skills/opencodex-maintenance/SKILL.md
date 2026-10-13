---
name: opencodex-maintenance
description: Maintain the user's OpenCodex integration, Codex model catalog, and LM Studio WireGuard routing. Use when OpenCodex models are missing or stale, after Codex or OpenCodex updates, while restoring a new environment, or when the LM Studio provider fails. Do not use for unrelated Codex usage questions.
---

# OpenCodex Maintenance

Keep the integration converged without interrupting active Codex work.

## Local invariants

- OpenCodex listens on `127.0.0.1:10100`; Codex uses `http://127.0.0.1:10100/v1`.
- LM Studio listens only on WireGuard at `10.44.0.1:1234`; OpenCodex uses `http://10.44.0.1:1234/v1`.
- The selected LM Studio chat models are `gemma-4-12b-it-qat` and `qwen3.5-9b`. Do not add the embedding model or duplicate alias `gemma-4-12b` to the Codex picker.
- Never widen LM Studio to `0.0.0.0` unless the user explicitly changes the network policy.
- `~/.codex/opencodex-catalog.json` is generated state. Do not store it in dotfiles.

## Diagnose first

For status, explanation, or diagnosis requests, remain read-only. Check the smallest relevant set:

```sh
codex --version
opencodex --version
opencodex ready --json
opencodex provider test lm-studio
ss -ltn
```

Confirm port `10100` is loopback-only and port `1234` is bound to `10.44.0.1`. Use LM Studio's `/v1/models` response only to confirm discovery; never print credentials or authentication files.

## Reconcile when authorized

- If the installed Codex catalog changed, run `opencodex sync`.
- If a genuinely new native Codex model is not understood by the installed OpenCodex version, update OpenCodex first, then sync.
- OpenCodex reads the installed Codex runtime's bundled catalog during sync and merges routed provider models into its generated catalog.
- Sync is not continuous. It runs when OpenCodex starts and when explicitly requested.
- Do not use `--restart-codex`, terminate app-server processes, unload LM Studio models, or restart the desktop app during an active turn. Report that a restart may be needed for the picker cache; restart only when explicitly requested or safely after the work is complete.
- A configured default model stays pinned. Do not change it merely because a newer catalog row appears.

## Keep dotfiles reproducible

Use the `dotfiles-config` skill for changes. The source of truth is `/home/hoya/.dotfiles`.

- OpenCodex config: `private_dot_opencodex/private_config.json.tmpl`
- Codex routing fields in `~/.codex/config.toml` are injected by `opencodex sync`; do not track the whole machine-specific file solely for OpenCodex.
- Fedora LM Studio service: `private_dot_config/systemd/user/lmstudio-server.service`
- OpenCodex install/start/sync automation: `run_onchange_after_20-opencodex-service.sh`

When upgrading OpenCodex, update the pinned version in the automation script. Keep volatile provider discovery caches, generated catalogs, logs, and authentication material out of dotfiles. Render, diff, and apply only the exact affected target; do not include unrelated repository changes.

## Verify and report

After an authorized repair, verify OpenCodex readiness, LM Studio provider connectivity, the exact listener addresses, and that the selected models appear in the generated catalog. Report changes and verification first, then any remaining picker restart or unsupported-model caveat.
