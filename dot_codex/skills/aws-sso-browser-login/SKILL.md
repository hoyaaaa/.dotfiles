---
name: aws-sso-browser-login
description: Log in to AWS IAM Identity Center using AWS_DEFAULT_PROFILE and the user's chosen browser and profile. Use when AWS CLI credentials are missing, SSO has expired, or the user explicitly requests a login-flow verification.
---

# AWS SSO browser login

Check the actual AWS operation or `aws sts get-caller-identity --profile "$AWS_DEFAULT_PROFILE"` first. Reuse working credentials unless the user explicitly requests a real login-flow verification. Do not launch login for IAM AccessDenied errors. Never invent an AWS profile. If AWS_DEFAULT_PROFILE is unset, ask for it.

## Saved user preference — Ego Lite 회사용

Use **Ego Lite with the `회사용` profile** for AWS SSO authentication. This preference was explicitly requested on 2026-10-20 and supersedes the previous Zen Browser preference. Honor a later explicit browser/profile request. Never silently substitute another browser or profile.

Read the ego-lite skill and follow [the verified login and cleanup workflow](references/ego-login.md). Resolve the exact existing `회사용` profile via `profiles()` and create one uniquely named login TaskSpace. Do not reuse an unrelated space merely because its name matches. Keep the AWS CLI process alive until authorization finishes. Authorization URLs, codes and tokens stay in memory; never print or persist them. User-presence prompts require the user and ego-lite handoff.

After login, require AWS CLI exit code 0 and a successful STS identity check. Then close the authentication TaskSpace with `finish({ keep: [] })` exactly once, and verify its numeric ID is absent from `listTaskSpaces()`. **Always clean up the login window/tabs when authentication is complete.** Preserve unrelated user tabs and do not quit the entire browser application. Report authentication and cleanup separately if either fails.

If authentication requires user action, hand off the same TaskSpace and explain the required action. If the selected browser is unavailable, stop and report the blocker. Do not switch browsers/accounts automatically. Do not persist further preference changes unless requested.
