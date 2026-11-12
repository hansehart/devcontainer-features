#!/bin/bash
set -e

# Import the test library
source dev-container-features-test-lib

check "pinned to 2.1.321" bash -lc "claude --version | grep -qwF '2.1.321'"

# Report result
reportResults
