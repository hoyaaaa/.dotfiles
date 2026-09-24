#!/usr/bin/env python3
"""Run AWS SSO login and open its verification URL in a named Chrome profile."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys


DEFAULT_CHROME_PROFILE = "창호"
URL_RE = re.compile(r"https?://[^\s\"'<>]+")


def chrome_profile_directory(profile_name: str) -> str:
    local_state = Path.home() / "Library/Application Support/Google/Chrome/Local State"
    try:
        data = json.loads(local_state.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise RuntimeError(f"Chrome Local State not found: {local_state}") from exc
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"Chrome Local State is not valid JSON: {local_state}") from exc

    matches = [
        directory
        for directory, info in data.get("profile", {}).get("info_cache", {}).items()
        if info.get("name") == profile_name
    ]
    if len(matches) != 1:
        if not matches:
            raise RuntimeError(f'Chrome profile "{profile_name}" was not found')
        raise RuntimeError(f'Chrome profile "{profile_name}" is ambiguous: {matches}')
    return matches[0]


def open_in_chrome(profile_directory: str, url: str) -> None:
    chrome = Path("/Applications/Google Chrome.app/Contents/MacOS/Google Chrome")
    if chrome.is_file():
        subprocess.Popen(
            [str(chrome), f"--profile-directory={profile_directory}", url],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        return

    open_bin = shutil.which("open")
    if open_bin is None:
        raise RuntimeError("macOS open command is unavailable")
    subprocess.Popen(
        [open_bin, "-a", "Google Chrome", "--args", f"--profile-directory={profile_directory}", url],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def run(profile: str, chrome_name: str, dry_run: bool) -> int:
    chrome_directory = chrome_profile_directory(chrome_name)
    if dry_run:
        print(f'AWS profile: {profile}')
        print(f'Chrome profile: {chrome_name} ({chrome_directory})')
        return 0

    command = ["aws", "sso", "login", "--profile", profile, "--no-browser"]
    try:
        process = subprocess.Popen(
            command,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
        )
    except FileNotFoundError as exc:
        raise RuntimeError("aws CLI was not found on PATH") from exc

    opened = False
    assert process.stdout is not None
    for line in process.stdout:
        sys.stdout.write(line)
        sys.stdout.flush()
        if opened:
            continue
        match = URL_RE.search(line)
        if match:
            open_in_chrome(chrome_directory, match.group(0).rstrip(".,)"))
            opened = True
            print(f'Opened AWS SSO authorization in Chrome profile "{chrome_name}".', flush=True)

    return process.wait()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--chrome-profile",
        default=os.environ.get("AWS_SSO_CHROME_PROFILE", DEFAULT_CHROME_PROFILE),
        help='visible Chrome profile name (default: "창호")',
    )
    parser.add_argument("--dry-run", action="store_true", help="validate profile discovery only")
    args = parser.parse_args()

    profile = os.environ.get("AWS_DEFAULT_PROFILE", "").strip()
    if not profile:
        print("AWS_DEFAULT_PROFILE must be set", file=sys.stderr)
        return 2

    try:
        return run(profile, args.chrome_profile, args.dry_run)
    except RuntimeError as exc:
        print(f"aws-sso-chrome-login: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
