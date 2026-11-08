#!/bin/bash
set -e

# Import the test library
source dev-container-features-test-lib

# Run as a non-root dev user, whose home keeps the state dir theirs across a UID remap.
check "state dir pre-created" test -d /home/ubuntu/rust
check "state dir writable by the dev user" bash -c 'touch /home/ubuntu/rust/.probe && rm /home/ubuntu/rust/.probe'

# Run the hook as a container create does.
/usr/local/libexec/rust/init.sh

check "CARGO_HOME is the state dir" bash -lc '[ "$CARGO_HOME" = /home/ubuntu/rust ]'

# A tool installed with cargo lands in the state dir and runs from the PATH.
project="$(mktemp -d)"
check "cargo install lands in the state dir" bash -lc "cd '$project' && cargo new -q --offline probe && cargo install -q --offline --path probe && [ -x /home/ubuntu/rust/bin/probe ]"
check "the installed tool runs from the PATH" bash -lc "probe | grep -qx 'Hello, world!'"

# The hook keeps the state dir private to the dev user.
check "state dir private to the dev user" \
  bash -c '[ -z "$(find /home/ubuntu/rust -maxdepth 0 -perm /g+rwx,o+rwx)" ]'

# This scenario keeps the state dir on the container filesystem, which the hook warns about.
check "the hook reports the unmounted state dir" \
  bash -c '/usr/local/libexec/rust/init.sh 2>&1 >/dev/null | grep -q "on the container filesystem"'

# A path outside the home proves the guard rejects what it should.
check "a state dir outside the home is refused" \
  bash -c '! /usr/local/libexec/rust/state-dir.sh rust /var/rust'
check "the refusal names the home" \
  bash -c '/usr/local/libexec/rust/state-dir.sh rust /var/rust 2>&1 | grep -q "must be inside /home/ubuntu"'

# Report result
reportResults
