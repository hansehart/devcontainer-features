#!/bin/bash
set -e

# Import the test library
source dev-container-features-test-lib

check "pinned to 0.167.1" bash -lc "codex --version | grep -qwF '0.167.1'"

# Report result
reportResults
