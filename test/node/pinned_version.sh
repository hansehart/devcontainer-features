#!/bin/bash
set -e

# Import the test library
source dev-container-features-test-lib

NODE="22.23.4"
NVM="0.41.0"

check "node pinned to $NODE" bash -lc "node --version | grep -qwF 'v$NODE'"
check "nvm pinned to $NVM" bash -lc "nvm --version | grep -qwF '$NVM'"

# Report result
reportResults
