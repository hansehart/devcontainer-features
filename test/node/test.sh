#!/bin/bash
set -e

# Import the test library
source dev-container-features-test-lib

# Use a login shell, which reads the feature's profile.
check "node on PATH" bash -lc "command -v node"
check "node version" bash -lc "node --version"
# The default channel floats, so assert its mark: LTS majors are even.
check "default resolved an LTS line" bash -lc "node --version | grep -qE '^v[0-9]*[02468]\.'"
check "npm on PATH" bash -lc "command -v npm"
check "npx on PATH" bash -lc "command -v npx"
check "nvm in a login shell" bash -lc "nvm --version"

# The runtime lives in nvm's tree, its current version linked onto the PATH.
for cmd in node npm npx; do
  check "$cmd links into nvm's current version" bash -c "[ \"\$(readlink \"\$(command -v $cmd)\")\" = /opt/nvm/current/bin/$cmd ]"
done
check "the container names nvm's home" bash -c '[ "$NVM_DIR" = /opt/nvm ]'
check "a process without the profile runs node" bash --noprofile --norc -c 'node --version'
check "the home holds none of Node" bash -c '[ ! -e "$HOME/.nvm" ]'
# Global packages live with their Node version, so npm runs without a prefix of its own.
check "npm sets no prefix" bash -lc '[ -z "${NPM_CONFIG_PREFIX:-}" ] && [ "$(npm prefix -g)" = "$(readlink -f /opt/nvm/current)" ]'
# The tool's config arrives as a file o3s copies in, so the build records none.
check "no recorded config" test ! -e /usr/local/etc/node/requested-npmrc

# A project whose postinstall leaves a marker shows whether npm runs install scripts.
project="$(mktemp -d)"
cat > "$project/package.json" <<'EOF'
{
  "name": "probe",
  "version": "1.0.0",
  "scripts": { "postinstall": "touch ran" }
}
EOF

# The feature keeps npm's own defaults, which o3s hardens through its env.
check "npm keeps its own default" bash -lc '[ -z "${NPM_CONFIG_IGNORE_SCRIPTS:-}" ]'
check "npm install runs the postinstall" bash -lc "cd '$project' && npm install --offline --no-audit --no-fund >/dev/null && [ -e ran ]"

# Report result
reportResults
