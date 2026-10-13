#!/bin/sh
set -eu

version=2.84.0
PATH="$HOME/.local/bin:$PATH"
export PATH

if ! command -v npm >/dev/null 2>&1; then
  printf '%s\n' 'opencodex: Node.js/npm 18+ is required; skipping setup.' >&2
  exit 0
fi

if ! command -v opencodex >/dev/null 2>&1 ||
  [ "$(opencodex --version 2>/dev/null)" != "opencodex $version" ]; then
  npm install --global --prefix "$HOME/.local" "@bitkyc08/opencodex@$version"
fi

opencodex service
opencodex sync
