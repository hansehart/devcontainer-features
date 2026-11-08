#!/bin/bash
set -e

# Import the test library
source dev-container-features-test-lib

# Use a login shell, which reads the feature's profile.
for cmd in rustc cargo rustup; do
  check "$cmd on PATH" bash -lc "command -v $cmd"
done
check "rustc version" bash -lc "rustc --version"

# The toolchain lives in its own tree, its commands linked onto the PATH.
check "cargo links into the rust tree" bash -c 'case "$(readlink -f "$(command -v cargo)")" in /opt/rust/*) ;; *) exit 1;; esac'
check "the container names the toolchain's home" bash -c '[ "$RUSTUP_HOME" = /opt/rust/rustup ]'
check "a process without the profile runs cargo" bash --noprofile --norc -c 'cargo --version'
check "the home holds none of the toolchain" bash -c '[ ! -e "$HOME/.rustup" ]'

# The minimal profile installs the compiler, cargo and the standard library alone.
check "only the minimal components" bash -lc '! rustup component list --installed | grep -q clippy'

# A crate using the standard library alone builds and runs without the network.
project="$(mktemp -d)"
check "a new crate builds and runs" bash -lc "cd '$project' && cargo new -q --offline hello && cd hello && cargo run -q --offline | grep -qx 'Hello, world!'"

# The feature keeps rustup's own defaults.
check "rustup's auto-install left at its default" bash -lc '[ -z "${RUSTUP_AUTO_INSTALL:-}" ]'

# Report result
reportResults
