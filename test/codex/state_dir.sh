#!/bin/bash
set -e

# Import the test library
source dev-container-features-test-lib

# Run as a non-root dev user, whose home keeps the state dir theirs across a UID remap.
check "state dir pre-created" test -d /home/ubuntu/.local/state/codex
check "state dir writable by the dev user" bash -c 'touch /home/ubuntu/.local/state/codex/.probe && rm /home/ubuntu/.local/state/codex/.probe'
check "the folders above the state dir belong to the dev user" bash -c '[ "$(stat -c %U /home/ubuntu/.local /home/ubuntu/.local/state | sort -u)" = ubuntu ]'

# Run the hook as a container create does.
/usr/local/libexec/codex/init.sh

check "CODEX_HOME exported" bash -lc '[ "$CODEX_HOME" = /home/ubuntu/.local/state/codex ]'

# The hook prepares the state dir alone, private to the dev user.
check "the hook writes no config" test ! -e /home/ubuntu/.local/state/codex/config.toml
check "state dir private to the dev user" \
  bash -c '[ -z "$(find /home/ubuntu/.local/state/codex -maxdepth 0 -perm /g+rwx,o+rwx)" ]'
# The binary keeps running with the state dir moved.
check "codex runs against the state dir" bash -lc "codex --version"

# This scenario keeps the state dir on the container filesystem, which the hook warns about.
check "the hook reports the unmounted state dir" \
  bash -c '/usr/local/libexec/codex/init.sh 2>&1 >/dev/null | grep -q "on the container filesystem"'

# A path outside the home proves the guard rejects what it should.
check "a state dir outside the home is refused" \
  bash -c '! /usr/local/libexec/codex/state-dir.sh codex /var/codex'
check "the refusal names the home" \
  bash -c '/usr/local/libexec/codex/state-dir.sh codex /var/codex 2>&1 | grep -q "must be inside /home/ubuntu"'

# Report result
reportResults
