---
name: aws-sso-browser-login
description: Log in to AWS IAM Identity Center using AWS_DEFAULT_PROFILE and the user's chosen browser and profile. Use when AWS CLI credentials are missing, SSO has expired, or the user explicitly requests a login-flow verification.
---

# AWS SSO browser login

Check the actual AWS operation or `aws sts get-caller-identity --profile "$AWS_DEFAULT_PROFILE"` first. Reuse working credentials unless the user explicitly requests a real login-flow verification. Do not launch login proactively or for IAM AccessDenied errors. Never invent an AWS profile. If AWS_DEFAULT_PROFILE is unset, ask for it.

## Saved user preference — AWS SSO uses Zen Browser

Use **Zen Browser** for AWS SSO authentication. This is an explicit, persistent browser choice and takes precedence over the global ego-lite default for browser work, including login, passkeys, OTP and user intervention. Do not open Ego Lite for AWS SSO unless the user explicitly requests that change. The previous Ego Lite / 회사용 preference is superseded.

Resolve `/Applications/Zen.app/Contents/MacOS/zen` and read `~/Library/Application Support/zen/profiles.ini`. Honor an explicitly requested Zen profile; otherwise resolve the existing default profile from the installation's Default path. Do not translate Ego profile names into Zen profile names or guess a company profile. As verified on 2026-10-18, the default installation points to `Profiles/unified.containers`, whose profile name is `통합`; rediscover it before login.

Use the native launcher helper below with Zen's Firefox-compatible `-P` option and the resolved profile name. Keep the AWS CLI alive until authorization completes. Never substitute another browser on failure. User-presence prompts must be completed by the user in Zen; do not use Ego handoff for this flow.

Verify AWS CLI exit code 0 and a successful STS identity check before reporting authentication complete. Do not quit Zen or close unrelated user tabs. Close only the authentication tab if it can be identified safely; otherwise leave it for the user.

The [Ego-specific reference](references/ego-login.md) is historical/optional and applies only if the user explicitly chooses Ego Lite. It does not change the Zen preference above.

## Choose the browser and profile

Honor the browser and profile explicitly specified in the conversation. Otherwise use the saved preference above, then an explicitly saved AWS_SSO_BROWSER_COMMAND and AWS_SSO_BROWSER_PROFILE pair. If no browser preference can be resolved, stop and ask; do not fall back to Ego Lite for AWS SSO. Do not silently choose Chrome, the OS default browser, another profile, or the Codex in-app browser.

For an explicit browser choice, resolve its installed executable and documented profile launch options. Verify that the requested profile exists and is unambiguous before login. For Chromium browsers, resolve a visible profile name using that browser's Local State metadata and pass the matching directory key. For Firefox, resolve the requested profile using its profiles.ini and supported profile options. Other browsers require their own supported profile launcher; never assume Chromium flags work. If exact profile routing cannot be established, stop and explain the limitation.

Use the helper when the browser supports a command that reliably routes to the requested profile, including when already running. Pass an argv JSON array (no shell evaluation) containing a standalone `{url}` argument and a `{profile}` placeholder. The profile value is the browser-native identifier resolved above, not necessarily the visible name. For example, after verifying the executable and profile:

```bash
python3 /Users/hoya/.codex/skills/aws-sso-browser-login/scripts/aws_sso_browser_login.py   --browser-command '["/Applications/Zen.app/Contents/MacOS/zen", "-P", "{profile}", "{url}"]'   --browser-profile '통합' --dry-run
```

Remove `--dry-run` to log in. `--browser-command` and `--browser-profile` override AWS_SSO_BROWSER_COMMAND and AWS_SSO_BROWSER_PROFILE respectively. Do not persist a preference unless requested. Dry-run checks command structure and executable availability only; it does not prove profile existence or correct routing. If the chosen browser needs a supported browser tool rather than a native launcher, use that tool with the explicit browser/profile while keeping the AWS CLI login process alive.

The helper runs `aws sso login --profile "$AWS_DEFAULT_PROFILE" --no-browser`, opens the authorization URL in memory, suppresses URL-bearing CLI output, and waits for completion. Do not put authorization URLs, codes, credentials, or tokens in chat, shell history, logs, or files. Do not automatically retry with another browser/account on failure. Keep a long-running login steerable using the command session; cancel it if the flow cannot continue.

After completion, verify identity with `aws sts get-caller-identity --profile "$AWS_DEFAULT_PROFILE"`. A browser launch alone is not login success.
