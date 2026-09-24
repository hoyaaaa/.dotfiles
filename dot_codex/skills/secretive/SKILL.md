---
name: secretive
description: Use Secretive for SSH authentication and Git commit or tag signing. Apply when configuring Git signing, creating signed commits or tags, troubleshooting Secretive, or choosing among the user's Secretive keys; use notify-key by default.
---

# Secretive

Use the Secretive Secure Enclave key named `notify-key` for Git signing. Never select `main-key` unless the user explicitly overrides this preference.

The global setup is enforced by `scripts/ensure-notify-key.sh`. Run it before changing or diagnosing the signing configuration. Keep signing enabled for commits and tags, use SSH signature format, and use the existing Secretive signing wrapper.

Treat the private key as non-exportable. Do not attempt to read, copy, or reconstruct it. It is safe to inspect the public key and fingerprint. The expected `notify-key` fingerprint is `SHA256:qJKGMujXWpOVJHbV3sOgOteLjhtZ7Q4y4QRasE6GwaA`.

If signing requires Touch ID or user presence, let Secretive request it. If the key or agent is unavailable, report that exact condition instead of falling back to another key or disabling signature verification.
