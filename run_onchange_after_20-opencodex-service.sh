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

# Preserve provider lookup for older Fedora LM Studio sessions on macOS.
if [ "$(uname -s)" = Darwin ]; then
  python3 - <<'PYCOMPAT'
from pathlib import Path
p = Path.home() / ".codex/config.toml"
s = p.read_text()
if "[model_providers.fedora-lmstudio]" not in s:
    p.write_text(s + '\n[model_providers.fedora-lmstudio]\nname = "Mac OpenCodex (legacy Fedora session)"\nbase_url = "http://127.0.0.1:10100/v1"\nwire_api = "responses"\nrequires_openai_auth = false\n')
PYCOMPAT
fi
