#!/bin/bash
set -e

# Import the test library
source dev-container-features-test-lib

# Run as a non-root dev user, whose home keeps the state dir theirs across a UID remap.
check "state dir pre-created" test -d /home/ubuntu/state/claude-code
check "state dir writable by the dev user" bash -c 'touch /home/ubuntu/state/claude-code/.probe && rm /home/ubuntu/state/claude-code/.probe'
check "the folder above the state dir belongs to the dev user" bash -c '[ "$(stat -c %U /home/ubuntu/state)" = ubuntu ]'

# Run the hook as a container create does.
/usr/local/libexec/claude-code/init.sh

check "CLAUDE_CONFIG_DIR exported" bash -lc '[ "$CLAUDE_CONFIG_DIR" = /home/ubuntu/state/claude-code ]'

# The hook prepares the state dir alone, private to the dev user.
check "the hook writes no settings" test ! -e /home/ubuntu/state/claude-code/settings.json
check "state dir private to the dev user" \
  bash -c '[ -z "$(find /home/ubuntu/state/claude-code -maxdepth 0 -perm /g+rwx,o+rwx)" ]'

# This scenario keeps the state dir on the container filesystem, which the hook warns about.
check "the hook reports the unmounted state dir" \
  bash -c '/usr/local/libexec/claude-code/init.sh 2>&1 >/dev/null | grep -q "on the container filesystem"'

# A path outside the home proves the guard rejects what it should.
check "a state dir outside the home is refused" \
  bash -c '! /usr/local/libexec/claude-code/state-dir.sh claude-code /var/claude-code'
check "the refusal names the home" \
  bash -c '/usr/local/libexec/claude-code/state-dir.sh claude-code /var/claude-code 2>&1 | grep -q "must be inside /home/ubuntu"'

# Report result
reportResults
