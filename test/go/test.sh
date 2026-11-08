#!/bin/bash
set -e

# Import the test library
source dev-container-features-test-lib

# Use a login shell, which reads the feature's profile.
check "go on PATH" bash -lc "command -v go"
check "gofmt on PATH" bash -lc "command -v gofmt"
check "go version" bash -lc "go version"

# The toolchain lives in its own folder, linked onto the PATH.
for cmd in go gofmt; do
  check "$cmd links into the go folder" bash -c "readlink -f \"\$(command -v $cmd)\" | grep -q '^/opt/go/'"
done
check "go finds its own root" bash -lc '[ "$(go env GOROOT)" = /opt/go ]'

# A program using the standard library alone builds and runs without the network.
project="$(mktemp -d)"
printf 'package main\n\nimport "fmt"\n\nfunc main() { fmt.Println("hello from go") }\n' > "$project/main.go"
check "a program builds and runs" bash -lc "cd '$project' && go run main.go | grep -qx 'hello from go'"

# The feature keeps Go's own toolchain setting, which o3s hardens through its env.
check "toolchain left at Go's default" bash -lc '[ "$(go env GOTOOLCHAIN)" = auto ]'

# Installed tools land on the PATH.
check "installed tools on PATH" bash -lc 'case ":$PATH:" in *":$(go env GOPATH)/bin:"*) ;; *) exit 1;; esac'

# Report result
reportResults
