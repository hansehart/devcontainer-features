#!/bin/bash
set -e

# Import the test library
source dev-container-features-test-lib

check "rustup pinned to 1.29.3" bash -lc "rustup --version 2>/dev/null | grep -qF 'rustup 1.29.3 '"

# Report result
reportResults
