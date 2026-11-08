#!/bin/bash
set -e

# Import the test library
source dev-container-features-test-lib

RUST="1.99.1"
RUSTUP="1.29.3"

check "rust pinned to $RUST" bash -lc "rustc --version | grep -qwF '$RUST'"
check "rustup pinned to $RUSTUP" bash -lc "rustup --version 2>/dev/null | grep -qwF '$RUSTUP'"

# Report result
reportResults
