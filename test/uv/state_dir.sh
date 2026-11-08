#!/bin/bash
set -e

# Import the test library
source dev-container-features-test-lib

# Run as a non-root dev user, whose home keeps the state dir theirs across a UID remap.
check "state dir pre-created" test -d /home/ubuntu/.local/state/uv
check "state dir writable by the dev user" bash -c 'touch /home/ubuntu/.local/state/uv/.probe && rm /home/ubuntu/.local/state/uv/.probe'
check "the folders above the state dir belong to the dev user" bash -c '[ "$(stat -c %U /home/ubuntu/.local /home/ubuntu/.local/state | sort -u)" = ubuntu ]'

# Run the hook as a container create does.
/usr/local/libexec/uv/init.sh

check "UV_CACHE_DIR exported" bash -lc '[ "$UV_CACHE_DIR" = /home/ubuntu/.local/state/uv/cache ]'

# This scenario keeps the state dir on the container filesystem, which the hook warns about.
check "the hook reports the unmounted state dir" \
  bash -c '/usr/local/libexec/uv/init.sh 2>&1 >/dev/null | grep -q "on the container filesystem"'

# A path outside the home proves the guard rejects what it should.
check "a state dir outside the home is refused" \
  bash -c '! /usr/local/libexec/uv/state-dir.sh uv /var/uv'
check "the refusal names the home" \
  bash -c '/usr/local/libexec/uv/state-dir.sh uv /var/uv 2>&1 | grep -q "must be inside /home/ubuntu"'

# Report result
reportResults
