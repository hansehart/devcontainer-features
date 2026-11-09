#!/bin/bash
set -e

# Import the test library
source dev-container-features-test-lib

# The patch floats, so assert the line only.
check "resolved the 3.14 line" bash -lc "python3 --version | grep -qE '^Python 3\.14\.[0-9]+$'"

# Report result
reportResults
