#!/bin/bash
set -e

# Import the test library
source dev-container-features-test-lib

# Use a login shell, which reads the feature's profile.
check "claude on PATH" bash -lc "command -v claude"
check "claude version" bash -lc "claude --version"
# The feature keeps the tool's own defaults, which o3s hardens through its env.
check "nonessential traffic left at the vendor default" bash -lc '[ -z "${CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC:-}" ]'
# The requested settings sit with the feature's config.
check "requested settings in the feature's config dir" test -f /usr/local/etc/claude-code/requested-settings.json

# Report result
reportResults
