#!/bin/sh
set -eu

NOTIFY_KEY=/Users/hoya/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/PublicKeys/915c98ed905a95ae37ae94e98a038334.pub
SIGNING_PROGRAM=/Users/hoya/.local/bin/git-ssh-sign-secretive
EXPECTED_FINGERPRINT='SHA256:qJKGMujXWpOVJHbV3sOgOteLjhtZ7Q4y4QRasE6GwaA'

[ -r "$NOTIFY_KEY" ]
[ -x "$SIGNING_PROGRAM" ]

ACTUAL_FINGERPRINT="$(/usr/bin/ssh-keygen -lf "$NOTIFY_KEY" | /usr/bin/awk '{print $2}')"
[ "$ACTUAL_FINGERPRINT" = "$EXPECTED_FINGERPRINT" ]

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
