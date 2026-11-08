#!/bin/bash
set -e

# Import the test library
source dev-container-features-test-lib

# The patch floats, so assert the line only.
check "resolved the 1.98 line" bash -lc "rustc --version | grep -qE '^rustc 1\.98\.[0-9]+ '"

# Report result
reportResults
