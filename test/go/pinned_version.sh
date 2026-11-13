#!/bin/bash
set -e

# Import the test library
source dev-container-features-test-lib

check "pinned to 1.27.4" bash -lc "go version | grep -qwF 'go1.27.4'"

# Report result
reportResults
