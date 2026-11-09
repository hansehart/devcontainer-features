#!/bin/bash
set -e

# Import the test library
source dev-container-features-test-lib

PYTHON="3.15.2"
UV="0.13.7"

check "python pinned to $PYTHON" bash -lc "python3 --version | grep -qwF '$PYTHON'"
check "uv pinned to $UV" bash -lc "uv --version | grep -qwF '$UV'"

# Report result
reportResults
