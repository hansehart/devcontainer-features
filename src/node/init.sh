#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/hook.sh"

# Create the tool's cache.
init_state() {
  if [ -n "${NPM_CONFIG_CACHE:-}" ]; then mkdir -p "$NPM_CONFIG_CACHE"; fi
}

init_main node "$@"
