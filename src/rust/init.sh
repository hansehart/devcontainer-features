#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/hook.sh"

# Create cargo's home in the state dir.
init_state() {
  if [ -n "${CARGO_HOME:-}" ]; then mkdir -p "$CARGO_HOME"; fi
}

init_main rust "$@"
