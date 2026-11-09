#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/lib.sh"

# Options (uppercased by the CLI): VERSION, STATEDIR, NVMVERSION.
FEATURE=node
VERSION="$(option VERSION lts)"
NVM_VERSION="$(option NVMVERSION latest)"

# Accept only options in the feature's format, before anything is installed.
require_version '^(latest|lts|v?[0-9]+(\.[0-9]+){0,2})$'
require_version '^(latest|v?[0-9]+\.[0-9]+\.[0-9]+)$' "$NVM_VERSION" nvmVersion

# Run the Node builds, which link against this shared library.
PACKAGES+=(libatomic1)

# Resolve nvm's release, and the Node request nvm resolves and verifies itself.
resolve_version() {
  nvm_tag="$(release_tag github nvm-sh/nvm "$NVM_VERSION")"
  [[ "$nvm_tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "could not resolve nvmVersion '$NVM_VERSION'"
  log "with nvm $nvm_tag ($NVM_VERSION)"
  case "$VERSION" in
    lts) tag='lts/*' ;;
    latest) tag=node ;;
    *) tag="$VERSION" ;;
  esac
  delegated="nvm checks each Node download against its release's SHASUMS256"
}

# Install nvm and the chosen Node into their own tree, owned by the dev user so they can add and
# switch versions, with the current version's commands linked onto the PATH for every process.
install_program() {
  local file
  install -d -o "$_REMOTE_USER" -g "$(id -gn "$_REMOTE_USER")" "$FEATURE_ROOT/opt/nvm"
  # Fetch nvm's release by its tag, the way its own installer does, since it publishes no checksums.
  for file in nvm.sh nvm-exec bash_completion; do
    curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/$nvm_tag/$file" -o "$FEATURE_ROOT/opt/nvm/$file"
  done
  chmod 0755 "$FEATURE_ROOT/opt/nvm/nvm-exec"
  chown "$_REMOTE_USER:" "$FEATURE_ROOT"/opt/nvm/*
  as_user "export NVM_DIR=/opt/nvm NVM_SYMLINK_CURRENT=true; . /opt/nvm/nvm.sh --no-use \\
    && nvm install -b '$tag' && nvm alias default '$tag' && nvm use default"
  link_bin /opt/nvm/current/bin node npm npx
}

# Write the login profile: nvm for shells that start from a fresh environment, the commands of
# global packages, and npm's cache and user config in the state dir when set.
profile() {
  echo 'export NVM_DIR=/opt/nvm'
  echo 'export NVM_SYMLINK_CURRENT=true'
  echo '. "$NVM_DIR/nvm.sh" --no-use'
  echo 'export PATH="$NVM_DIR/current/bin:$PATH"'
  if [ -n "$STATE_DIR" ]; then
    echo "export NPM_CONFIG_CACHE=\"$STATE_DIR/cache\""
    echo "export NPM_CONFIG_USERCONFIG=\"$STATE_DIR/npmrc\""
  fi
}

# Confirm the runtime and its package tools run from the PATH.
confirm() {
  node --version
  npm --version
  command -v npx >/dev/null
}

feature_main
