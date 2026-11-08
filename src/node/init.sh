#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/hook.sh"

# Create the tool's cache, then apply the requested config.
init_state() {
  if [ -n "${NPM_CONFIG_CACHE:-}" ]; then mkdir -p "$NPM_CONFIG_CACHE"; fi
  apply_config requested-npmrc "${NPM_CONFIG_USERCONFIG:-$HOME/.npmrc}"
}

init_main node "$@"
