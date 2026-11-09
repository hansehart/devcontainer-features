#!/bin/bash
set -e

# Import the test library
source dev-container-features-test-lib

# Run as a non-root dev user, whose home keeps the state dir theirs across a UID remap.
check "state dir pre-created" test -d /home/ubuntu/.local/state/python
check "state dir writable by the dev user" bash -c 'touch /home/ubuntu/.local/state/python/.probe && rm /home/ubuntu/.local/state/python/.probe'
check "the folders above the state dir belong to the dev user" bash -c '[ "$(stat -c %U /home/ubuntu/.local /home/ubuntu/.local/state | sort -u)" = ubuntu ]'

# Run the hook as a container create does.
/usr/local/libexec/python/init.sh

check "UV_CACHE_DIR exported" bash -lc '[ "$UV_CACHE_DIR" = /home/ubuntu/.local/state/python/cache ]'
check "UV_TOOL_DIR exported" bash -lc '[ "$UV_TOOL_DIR" = /home/ubuntu/.local/state/python/tools ]'
check "UV_TOOL_BIN_DIR exported" bash -lc '[ "$UV_TOOL_BIN_DIR" = /home/ubuntu/.local/state/python/bin ]'
check "the Pythons stay in their own tree" bash -lc '[ "$UV_PYTHON_INSTALL_DIR" = /opt/python ]'

# This scenario keeps the state dir on the container filesystem, which the hook warns about.
check "the hook reports the unmounted state dir" \
  bash -c '/usr/local/libexec/python/init.sh 2>&1 >/dev/null | grep -q "on the container filesystem"'

# A path outside the home proves the guard rejects what it should.
check "a state dir outside the home is refused" \
  bash -c '! /usr/local/libexec/python/state-dir.sh python /var/python'
check "the refusal names the home" \
  bash -c '/usr/local/libexec/python/state-dir.sh python /var/python 2>&1 | grep -q "must be inside /home/ubuntu"'

# Report result
reportResults
