#!/bin/sh
set -eu

NOTIFY_KEY=/Users/hoya/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/PublicKeys/915c98ed905a95ae37ae94e98a038334.pub
SIGNING_PROGRAM=/Users/hoya/.local/bin/git-ssh-sign-secretive
SECRETIVE_SOCKET=/Users/hoya/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh
SECRETIVE_AGENT_LABEL=com.maxgoedjen.Secretive.SecretAgent
EXPECTED_FINGERPRINT='SHA256:qJKGMujXWpOVJHbV3sOgOteLjhtZ7Q4y4QRasE6GwaA'

[ -r "$NOTIFY_KEY" ] || { printf '%s\n' 'Pinned notify-key public file is missing.' >&2; exit 1; }
[ -x "$SIGNING_PROGRAM" ] || { printf '%s\n' 'Secretive signing wrapper is missing or not executable.' >&2; exit 1; }
[ -S "$SECRETIVE_SOCKET" ] || { printf '%s\n' 'Secretive agent socket is missing; inspect the service before retrying.' >&2; exit 1; }

ACTUAL_FINGERPRINT="$(/usr/bin/ssh-keygen -lf "$NOTIFY_KEY" | /usr/bin/awk '{print $2}')"
[ "$ACTUAL_FINGERPRINT" = "$EXPECTED_FINGERPRINT" ] || {
  printf '%s\n' 'Pinned public file does not match the expected notify-key fingerprint.' >&2
  exit 1
}

# Secretive's agent can remain alive while its socket is deadlocked. That makes
# signing, fetch, and push wait forever even though notify-key itself requires no
# user approval. Probe the socket with a short deadline and restart only the
# background agent when it is unhealthy.
probe_agent() {
  /usr/bin/perl -e 'alarm shift; exec @ARGV' 5 \
    /usr/bin/env SSH_AUTH_SOCK="$SECRETIVE_SOCKET" /usr/bin/ssh-add -l
}

if AGENT_KEYS="$(probe_agent 2>&1)"; then
  :
else
  PROBE_STATUS=$?
  if [ "$PROBE_STATUS" -eq 1 ]; then
    printf '%s\n' "Secretive agent replied without identities: $AGENT_KEYS" >&2
    printf '%s\n' 'An empty listing does not prove key deletion. See references/empty-identities.md; distinguish key-store access from socket failure.' >&2
    exit 1
  fi
  printf '%s\n' "Agent probe failed (status $PROBE_STATUS); restarting its launchd service once." >&2
  /bin/launchctl kickstart -k "gui/$(/usr/bin/id -u)/$SECRETIVE_AGENT_LABEL"
  /bin/sleep 1
  if ! AGENT_KEYS="$(probe_agent 2>&1)"; then
    printf '%s\n' "Secretive recovery failed: $AGENT_KEYS" >&2
    exit 1
  fi
fi

if ! printf '%s\n' "$AGENT_KEYS" | /usr/bin/grep -Fq "$EXPECTED_FINGERPRINT"; then
  printf '%s\n' "Secretive agent does not expose the expected notify-key fingerprint." >&2
  exit 1
fi

/usr/bin/git config --global gpg.format ssh
/usr/bin/git config --global gpg.ssh.program "$SIGNING_PROGRAM"
/usr/bin/git config --global user.signingkey "$NOTIFY_KEY"
/usr/bin/git config --global commit.gpgsign true
/usr/bin/git config --global tag.gpgsign true

# Git commit signing and GitHub transport are separate SSH operations. Keep the
# GitHub host pinned to notify-key too; otherwise Secretive may offer whichever
# key appears first in the agent (often main-key) during push/fetch.
SSH_CONFIG=/Users/hoya/.ssh/config
[ -r "$SSH_CONFIG" ]
/usr/bin/ssh -G github.com 2>/dev/null | /usr/bin/grep -Fq "identityfile $NOTIFY_KEY"
/usr/bin/ssh -G github.com 2>/dev/null | /usr/bin/grep -Fq "identitiesonly yes"
