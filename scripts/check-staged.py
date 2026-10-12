#!/usr/bin/env python3
"""Inspect staged bytes without exposing their contents in output."""
import json
from pathlib import PurePosixPath
import re
import subprocess


def check(path, content):
    parts = PurePosixPath(path).parts
    forbidden = {'.env', 'credentials', 'hosts.yml', 'rclone.conf', 'key.txt'}
    if any(p in forbidden or p.startswith('.env.') for p in parts) or path.endswith(('.pem', '.key', '.p12', '.pfx')):
        raise ValueError('secret-bearing filename')
    if path.endswith('.age'):
        if not content.startswith((b'age-encryption.org/v1', b'-----BEGIN AGE ENCRYPTED FILE-----')):
            raise ValueError('invalid encrypted file header')
        return
    if re.search(rb'BEGIN (?:RSA |OPENSSH |EC )?PRIVATE KEY|AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{30,}|gh[pousr]_[0-9A-Za-z]{30,}|github_pat_[0-9A-Za-z_]{30,}', content):
        raise ValueError('credential-like content')
    if path.endswith('hooks.json'):
        json.loads(content)


def main():
    files = subprocess.check_output(['git', 'diff', '--cached', '--name-only', '--diff-filter=ACMR', '-z']).split(b'\0')
    for raw in filter(None, files):
        path = raw.decode()
        data = subprocess.check_output(['git', 'show', ':' + path])
        try:
            check(path, data)
        except (ValueError, UnicodeError):
            raise SystemExit('Staged validation failed: ' + path)
    print('PASS: staged file validation and secret scan')


if __name__ == '__main__':
    main()
