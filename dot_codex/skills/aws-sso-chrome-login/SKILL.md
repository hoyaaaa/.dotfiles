---
name: aws-sso-chrome-login
description: Log in to AWS IAM Identity Center with the profile in AWS_DEFAULT_PROFILE and open the SSO verification URL in the user's Chrome profile named "창호". Use only when an AWS CLI command requiring that profile fails because SSO credentials are missing or expired.
---

# AWS SSO login in the user's Chrome profile

First check whether the configured AWS CLI profile already has usable credentials. For example:

```bash
aws sts get-caller-identity --profile "$AWS_DEFAULT_PROFILE"
```

If that succeeds, do not run this skill and do not ask the user to authenticate again. Only when the check (or the actual AWS CLI operation) fails because the profile is unauthenticated or its SSO session is expired, use the bundled helper instead of repeating a raw `aws sso login` command. Do not use it to resolve an IAM `AccessDenied`/policy permission error; report that error instead:

```bash
python3 /Users/hoya/.codex/skills/aws-sso-chrome-login/scripts/aws_sso_chrome_login.py
```

The helper requires `AWS_DEFAULT_PROFILE`. It runs `aws sso login --profile
"$AWS_DEFAULT_PROFILE" --no-browser`, detects the authorization URL, and opens
that URL in the Chrome profile whose visible name is `창호`. It waits for the
AWS CLI process to finish, so the command only succeeds after the SSO flow is
complete.

Rules:

- Do not invoke the browser login proactively or on every AWS request. Reuse valid AWS CLI credentials until AWS reports that SSO authentication is required.
- Never invent or silently substitute an AWS profile. If `AWS_DEFAULT_PROFILE`
  is unset, stop and ask for it.
- Resolve the Chrome profile from Chrome's local profile metadata; if `창호`
  is not present, stop rather than opening the URL in another profile.
- Do not pass credentials, tokens, or the authorization URL through shell
  history, files, or chat. The helper keeps the URL in memory and opens it
  directly.
- After a successful login, verify the active identity with:

  ```bash
  aws sts get-caller-identity --profile "$AWS_DEFAULT_PROFILE"
  ```

- Use `--dry-run` to validate profile discovery without starting an SSO login.
- If the browser flow fails, report the AWS CLI error and do not retry with a
  different profile or browser account automatically.
