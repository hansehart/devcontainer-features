#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/lib.sh"

# Options (uppercased by the CLI): VERSION, STATEDIR, UVVERSION.
FEATURE=python
VERSION="$(option VERSION latest)"
UV_VERSION="$(option UVVERSION latest)"

# Accept only options in the feature's format, before anything is installed.
require_version '^(latest|3\.[0-9]+(\.[0-9]+)?)$'
require_version '^(latest|v?[0-9]+\.[0-9]+\.[0-9]+)$' "$UV_VERSION" uvVersion

# Resolve uv's release, its archive and its checksum, and the Python uv installs.
resolve_version() {
  local uv
  uv="$(release_tag github astral-sh/uv "$UV_VERSION" --bare)"
  log "with uv $uv ($UV_VERSION)"
  url="https://github.com/astral-sh/uv/releases/download/$uv/uv-$(arch_name x86_64=x86_64-unknown-linux-gnu aarch64=aarch64-unknown-linux-gnu).tar.gz"
  checksum="$url.sha256"
  tag="$VERSION"
}

# Install uv on the PATH, then the chosen Python into its own tree, owned by the dev user so they
# can add and switch versions, with its commands linked onto the PATH for every process.
install_program() {
  local request=""
  untar
  install_bin "$tmp/uv" "$tmp/uvx"
  install -d -o "$_REMOTE_USER" -g "$(id -gn "$_REMOTE_USER")" "$FEATURE_ROOT/opt/python"
  if [ "$VERSION" != latest ]; then request="'$VERSION'"; fi
  as_user "UV_PYTHON_INSTALL_DIR=/opt/python UV_PYTHON_BIN_DIR=/opt/python/bin UV_NO_CACHE=1 \
    $FEATURE_ROOT/usr/local/bin/uv python install --default --preview-features python-install-default $request"
  link_bin /opt/python/bin
}

# Write the login profile: the Pythons' home for shells that start from a fresh environment, and
# uv's cache and tools in the state dir when set.
profile() {
  echo 'export UV_PYTHON_INSTALL_DIR=/opt/python'
  echo 'export UV_PYTHON_BIN_DIR=/opt/python/bin'
  echo 'export PATH="$HOME/.local/bin:$PATH"'
  if [ -n "$STATE_DIR" ]; then
    echo "export UV_CACHE_DIR=\"$STATE_DIR/cache\""
    echo "export UV_TOOL_DIR=\"$STATE_DIR/tools\""
    echo "export UV_TOOL_BIN_DIR=\"$STATE_DIR/bin\""
    echo 'export UV_LINK_MODE=copy'
    echo "export PATH=\"$STATE_DIR/bin:\$PATH\""
  fi
}

# Confirm Python and both tools run from the PATH.
confirm() {
  python3 --version
  uv --version
  command -v uvx >/dev/null
}

feature_main
