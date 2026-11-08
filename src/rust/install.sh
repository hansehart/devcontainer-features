#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/lib.sh"

# Options (uppercased by the CLI): VERSION, STATEDIR, RUSTUPVERSION.
FEATURE=rust
VERSION="$(option VERSION latest)"
RUSTUP_VERSION="$(option RUSTUPVERSION latest)"

# Accept only options in the feature's format, before anything is installed.
require_version '^(latest|beta|nightly|[0-9]+\.[0-9]+(\.[0-9]+)?)$'
require_version '^(latest|[0-9]+\.[0-9]+\.[0-9]+)$' "$RUSTUP_VERSION" rustupVersion

# Link the programs Rust builds, with the C toolchain it links them through.
PACKAGES+=(gcc libc6-dev)

# Resolve rustup's release and its checksum, and the toolchain rustup installs.
resolve_version() {
  local rustup="$RUSTUP_VERSION"
  if [ "$rustup" = latest ]; then
    # Follow the release pointer, which names the newest rustup.
    rustup="$(curl -fsSL https://static.rust-lang.org/rustup/release-stable.toml | grep -oP "^version = '\K[0-9.]+" || true)"
  fi
  [[ "$rustup" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "could not resolve rustupVersion '$RUSTUP_VERSION'"
  log "with rustup $rustup ($RUSTUP_VERSION)"
  url="https://static.rust-lang.org/rustup/archive/$rustup/$(arch_name x86_64=x86_64-unknown-linux-gnu aarch64=aarch64-unknown-linux-gnu)/rustup-init"
  checksum="$url.sha256"
  # Name the channel rustup knows the newest stable release by.
  if [ "$VERSION" = latest ]; then tag=stable; else tag="$VERSION"; fi
}

# Install rustup and the minimal toolchain as the dev user, then link its commands onto the PATH
# for every process.
install_program() {
  local home init
  home="${_REMOTE_USER_HOME:-$(getent passwd "$_REMOTE_USER" | cut -d: -f6)}"
  # Hand the verified installer to the dev user in a folder they can read.
  init="$(mktemp -d)"
  chmod 0755 "$init"
  install -m 0755 "$tmp/rustup-init" "$init/rustup-init"
  as_user "$init/rustup-init -y --no-modify-path --profile minimal --default-toolchain '$tag'"
  rm -rf "${init:?}"
  link_bin "$home/.cargo/bin"
}

# Write the login profile: cargo's data in the state dir when set, and the tools cargo installs.
profile() {
  if [ -n "$STATE_DIR" ]; then
    echo "export CARGO_HOME=\"$STATE_DIR\""
    echo "export PATH=\"$STATE_DIR/bin:\$PATH\""
  else
    echo 'export PATH="$HOME/.cargo/bin:$PATH"'
  fi
}

# Confirm the toolchain runs for the dev user.
confirm() {
  as_user "rustc --version && cargo --version"
}

feature_main
