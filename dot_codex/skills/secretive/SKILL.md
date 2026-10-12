---
name: secretive
description: Use Secretive for SSH authentication and Git commit or tag signing. Apply when configuring Git signing, creating signed commits or tags, troubleshooting Secretive, or choosing among the user's Secretive keys; use notify-key by default.
---

# Secretive

Use the Secure Enclave key named `notify-key` for Git signing. Expected fingerprint: `SHA256:qJKGMujXWpOVJHbV3sOgOteLjhtZ7Q4y4QRasE6GwaA`. Never select `main-key` unless the user explicitly overrides this preference. Keep commit/tag signing enabled, SSH signature format, and the existing signing wrapper. Never export, copy, reconstruct, delete, or regenerate private keys as a repair.

Run `scripts/ensure-notify-key.sh` before changing or diagnosing signing configuration. It checks the pinned public key, agent identity, signing settings and GitHub transport configuration. A successful identity listing proves discovery only, not signing. Run `scripts/check-notify-signing.sh` to sign and cryptographically verify a disposable local message before retrying a failed commit.

## Diagnose before retrying

`notify-key` is configured without user presence; do not reflexively ask for Touch ID. If an unexpected approval appears, check the selected key and current key policy; do not bypass the prompt or weaken it.

- Timeout: stop the hung command, inspect the exact socket owner and launchd service, then recover the affected background agent. Check for duplicate SecretAgent processes; do not kill unrelated SSH agents. Do not assume every signing failure is a dead socket.
- `agent refused operation`: the agent replied but could not sign. Verify the actual signing probe, current key policy, and relevant SecretAgent/Security logs. Listing a fingerprint does not rule out inaccessible key material or stale cached state.
- `The agent has no identities` / `No private key found`: distinguish a wrong/missing socket, an empty Secretive app/agent, missing pinned public file, and inaccessible key-store state. Read [references/empty-identities.md](references/empty-identities.md) for source-backed cases, safe recovery order, and the separate macOS 27 public-file restriction. An unlocked login keychain or existing `.pub` does not establish Secure Enclave/data-protection keychain access; do not infer deletion.
- Fetch/push authentication failures: check GitHub SSH identity routing separately; commit signing success does not prove transport authentication.

Retry once after a specific recovery and verify the result. If that fails, continue read-only diagnosis when it can distinguish causes; do not repeat unchanged retries. Apply a further repair only when new evidence supports it. Report the exact remaining error and state whether commit creation or push failed. Never silently disable signing or switch keys.

Do not infer a version regression from mixed running versions alone. Any temporary version/configuration experiment must preserve the original state, validate official signatures, and be reverted if it does not resolve the issue. Do not automatically edit keychain search lists, credential records, or install/downgrade software as routine socket recovery.

After success, verify the commit signature and that the remote branch points to the local commit before reporting a push complete. Do not store personal Mac authentication diagnostics in company memory; record only the company task's outcome there.
