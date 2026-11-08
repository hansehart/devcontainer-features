#!/bin/bash
set -e

# Import the test library
source dev-container-features-test-lib

check "pinned to 1.99.1" bash -lc "rustc --version | grep -qF 'rustc 1.99.1 '"

# Report result
reportResults
