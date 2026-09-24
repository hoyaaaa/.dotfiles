#!/usr/bin/env bash
set -Eeuo pipefail

store="${XDG_CONFIG_HOME:-$HOME/.config}/chezmoi-secrets/secrets.json"

usage() {
  printf 'Usage: %s list | copy <path> | set <path> | remove <path> | sync\n' "$0" >&2
  exit 2
}

require_store() {
  [[ -f "$store" ]] || { printf 'Missing secret store: %s\n' "$store" >&2; exit 1; }
}

sync_store() {
  chmod 600 "$store"
  chezmoi add --encrypt "$store"
}

command="${1:-}"
case "$command" in
  list)
    require_store
    jq -r 'keys[]' "$store"
    ;;
  copy)
    [[ $# -eq 2 ]] || usage
    require_store
    jq -er --arg path "$2" '.[$path]' "$store" | base64 -D | pbcopy
    printf 'Copied %s to the clipboard.\n' "$2"
    ;;
  set)
    [[ $# -eq 2 ]] || usage
    [[ ! -t 0 ]] || { printf 'Pipe the value on stdin, for example: pbpaste | %s set %q\n' "$0" "$2" >&2; exit 2; }
    mkdir -p "$(dirname "$store")"
    [[ -f "$store" ]] || printf '{}\n' >"$store"
    chmod 600 "$store"
    encoded="$(mktemp "${TMPDIR:-/tmp}/chezmoi-secret.XXXXXX")"
    next="$(mktemp "${TMPDIR:-/tmp}/chezmoi-secrets.XXXXXX")"
    trap 'rm -f "$encoded" "$next"' EXIT
    base64 >"$encoded"
    jq --arg path "$2" --rawfile value "$encoded" '.[$path] = ($value | sub("\\n$"; ""))' "$store" >"$next"
    mv "$next" "$store"
    sync_store
    printf 'Updated %s.\n' "$2"
    ;;
  remove)
    [[ $# -eq 2 ]] || usage
    require_store
    jq -e --arg path "$2" 'has($path)' "$store" >/dev/null
    next="$(mktemp "${TMPDIR:-/tmp}/chezmoi-secrets.XXXXXX")"
    trap 'rm -f "$next"' EXIT
    jq --arg path "$2" 'del(.[$path])' "$store" >"$next"
    mv "$next" "$store"
    sync_store
    printf 'Removed %s.\n' "$2"
    ;;
  sync)
    require_store
    sync_store
    ;;
  *)
    usage
    ;;
esac
