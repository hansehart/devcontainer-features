#!/bin/bash
set -e

# Import the test library
source dev-container-features-test-lib

# Use a login shell, which reads the feature's profile.
for cmd in python python3 uv uvx; do
  check "$cmd on PATH" bash -lc "command -v $cmd"
done
check "python version" bash -lc "python3 --version"

# The Pythons live in their own tree, their commands linked onto the PATH.
check "python3 links into the python tree" bash -c 'case "$(readlink -f "$(command -v python3)")" in /opt/python/*) ;; *) exit 1;; esac'
check "the container names the Pythons' home" bash -c '[ "$UV_PYTHON_INSTALL_DIR" = /opt/python ]'
check "a process without the profile runs python3" bash --noprofile --norc -c 'python3 --version'
check "the home holds none of the Pythons" bash -c '[ ! -e "$HOME/.local/share/uv/python" ]'

# uv finds the installed Python as one it manages.
check "uv finds the installed Python" bash -lc 'uv python find >/dev/null'

# The feature keeps uv's own defaults.
check "python downloads left at uv's default" bash -lc '[ -z "${UV_PYTHON_DOWNLOADS:-}" ]'

# Report result
reportResults
