#!/usr/bin/env python3
"""Run AWS SSO login using an explicitly configured browser/profile launcher."""
import argparse
import json
import os
import re
import shutil
import subprocess
import sys

URL_RE = re.compile(r"https?://[^\s\"'<>]+")


def browser_argv(command, profile):
    try:
        argv = json.loads(command)
    except (ValueError, TypeError) as exc:
        raise ValueError("Browser command must be a JSON argv array") from exc
    if not isinstance(argv, list) or not argv or not all(isinstance(x, str) and x for x in argv):
        raise ValueError("Browser command must be a nonempty array of nonempty strings")
    if argv.count("{url}") != 1 or not any("{profile}" in x for x in argv[1:]):
        raise ValueError("Browser command needs one standalone {url} and a {profile} argument")
    if "{url}" in argv[0] or "{profile}" in argv[0] or not profile.strip():
        raise ValueError("An explicit executable and nonempty browser profile are required")
    if not shutil.which(argv[0]):
        raise ValueError("Browser executable not found or not executable")
    return [x.replace("{profile}", profile) for x in argv]


def run(aws_profile, argv):
    process = subprocess.Popen(
        ["aws", "sso", "login", "--profile", aws_profile, "--no-browser"],
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1,
    )
    opened = False
    try:
        for line in process.stdout:
            match = URL_RE.search(line)
            if match and not opened:
                url = match.group(0).rstrip(".,)")
                subprocess.Popen(
                    [url if arg == "{url}" else arg for arg in argv],
                    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                )
                opened = True
                print("Opened AWS SSO in the selected browser/profile.", flush=True)
            # AWS output may contain tokens, device codes or authorization URLs.
            # Keep it out of logs; report status without reproducing it.
        status = process.wait()
        if status:
            print(f"AWS SSO login failed (exit {status}); check AWS configuration and browser authentication.", file=sys.stderr)
        elif not opened:
            print("AWS CLI completed without a browser URL; verify identity before reporting success.")
        return status
    finally:
        if process.poll() is None:
            process.terminate()
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--browser-command", default=os.environ.get("AWS_SSO_BROWSER_COMMAND"))
    parser.add_argument("--browser-profile", default=os.environ.get("AWS_SSO_BROWSER_PROFILE", ""))
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    profile = os.environ.get("AWS_DEFAULT_PROFILE", "").strip()
    try:
        if not profile:
            raise ValueError("AWS_DEFAULT_PROFILE must be set")
        argv = browser_argv(args.browser_command, args.browser_profile)
        if args.dry_run:
            print("Browser command and executable validated; no login started. Verify profile existence separately.")
            return 0
        return run(profile, argv)
    except (ValueError, OSError) as exc:
        print(f"aws-sso-browser-login: {exc}", file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        return 130


if __name__ == "__main__":
    sys.exit(main())
