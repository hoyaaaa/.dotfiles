---
name: aws-sso-browser-login
description: Log in to AWS IAM Identity Center using AWS_DEFAULT_PROFILE and the user's chosen browser and profile. Use when AWS CLI credentials are missing, SSO has expired, or the user explicitly requests a login-flow verification.
---

# AWS SSO browser login

Check the actual AWS operation or `aws sts get-caller-identity --profile "$AWS_DEFAULT_PROFILE"` first. Reuse working credentials unless the user explicitly requests a real login-flow verification. Do not launch login proactively or for IAM AccessDenied errors. Never invent an AWS profile. If AWS_DEFAULT_PROFILE is unset, ask for it.

For the tested Ego Lite execution sequence, read [references/ego-login.md](references/ego-login.md). It keeps the CLI alive through authorization, verifies identity, closes the login space, and checks its absence.

## Saved user preference

Use **Ego Lite**, profile **회사용**, for future AWS SSO login. This replaces the previous Zen preference. A later explicit browser/profile choice overrides it.

Use the ego-lite skill. Before creating the login TaskSpace, call `profiles()` through `ego-browser nodejs` and resolve the exact name `회사용` uniquely. The verified current ID is `Default`; rediscover it rather than assuming it remains stable. If missing or ambiguous, stop without substituting another profile.

Create one new login TaskSpace with `await taskSpace("AWS SSO login", { profileId: selected.id })` and navigate its initial `p1` page. `profileId` applies only to new spaces; do not reuse an existing space belonging to another profile.

Keep the AWS CLI child process and authorization URL in the same `ego-browser nodejs` invocation's memory: spawn `aws sso login --profile <AWS_DEFAULT_PROFILE> --no-browser` using Node's child_process API, capture stdout/stderr privately, and navigate `p1` to the detected authorization URL without logging the raw output, URL or device code. Do not use the native browser launcher helper for Ego Lite. Continue the authentication through the documented ego-lite API; if user intervention is required, follow its handoff/resume rules and keep the CLI session alive. Never terminate the waiting login merely because the page appears approved.

### Close after successful approval

The user explicitly requests automatic cleanup after SSO approval. Wait for AWS CLI exit code 0, then verify `aws sts get-caller-identity --profile <AWS_DEFAULT_PROFILE>` succeeds. After both succeed, call `await task.finish({ keep: [] })` exactly once and await completion before reporting success. Close the login TaskSpace and agent-created login pages; do not quit the Ego Lite application or close unrelated user tabs. If authentication fails or pauses for user action, preserve the space according to ego-lite's error/handoff rules. If cleanup fails after authentication succeeds, report the two outcomes separately.

## Choose the browser and profile

Honor the browser and profile explicitly specified in the conversation. Otherwise use the saved preference above, then an explicitly saved AWS_SSO_BROWSER_COMMAND and AWS_SSO_BROWSER_PROFILE pair. If none exists, use the ego-lite skill for browser authentication; if ego-lite is unavailable, stop and report it. Do not silently choose Chrome, the OS default browser, another profile, or the Codex in-app browser.

For an explicit browser choice, resolve its installed executable and documented profile launch options. Verify that the requested profile exists and is unambiguous before login. For Chromium browsers, resolve a visible profile name using that browser's Local State metadata and pass the matching directory key. For Firefox, resolve the requested profile using its profiles.ini and supported profile options. Other browsers require their own supported profile launcher; never assume Chromium flags work. If exact profile routing cannot be established, stop and explain the limitation.

Use the helper when the browser supports a command that reliably routes to the requested profile, including when already running. Pass an argv JSON array (no shell evaluation) containing a standalone `{url}` argument and a `{profile}` placeholder. The profile value is the browser-native identifier resolved above, not necessarily the visible name. For example, after verifying the executable and profile:

```bash
python3 /Users/hoya/.codex/skills/aws-sso-browser-login/scripts/aws_sso_browser_login.py   --browser-command '["/Applications/Firefox.app/Contents/MacOS/firefox", "-P", "{profile}", "{url}"]'   --browser-profile '업무' --dry-run
```

Remove `--dry-run` to log in. `--browser-command` and `--browser-profile` override AWS_SSO_BROWSER_COMMAND and AWS_SSO_BROWSER_PROFILE respectively. Do not persist a preference unless requested. Dry-run checks command structure and executable availability only; it does not prove profile existence or correct routing. If the chosen browser needs a supported browser tool rather than a native launcher, use that tool with the explicit browser/profile while keeping the AWS CLI login process alive.

The helper runs `aws sso login --profile "$AWS_DEFAULT_PROFILE" --no-browser`, opens the authorization URL in memory, suppresses URL-bearing CLI output, and waits for completion. Do not put authorization URLs, codes, credentials, or tokens in chat, shell history, logs, or files. Do not automatically retry with another browser/account on failure. Keep a long-running login steerable using the command session; cancel it if the flow cannot continue.

After completion, verify identity with `aws sts get-caller-identity --profile "$AWS_DEFAULT_PROFILE"`. A browser launch alone is not login success.
