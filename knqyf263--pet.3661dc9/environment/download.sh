#!/usr/bin/env bash
# download.sh — ONLINE dependency preparation for the offline build.
#
# This file is SOURCED, not executed. It warms the Go module cache with the
# dependency modules a github.com/knqyf263/pet implementation needs and lets the Go toolchain
# auto-resolve the release required by the module. No source tree is
# required: the reproduction agent writes its own source and compiles it
# offline with compile.sh against this prepared cache.
#
# This file is pipeline-managed (generated deterministically from the
# repository's go.mod). Do not edit.

set -u
export GOTOOLCHAIN=auto
export GOFLAGS=-mod=mod

WS="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)" || return 1
BUILD_ENV="$WS/.programgym_build_env"
PREFETCH="$BUILD_ENV/go-prefetch"
mkdir -p "$PREFETCH"

export GOPATH="$BUILD_ENV/gopath"
export GOMODCACHE="$GOPATH/pkg/mod"
export GOCACHE="$BUILD_ENV/gocache"
mkdir -p "$GOMODCACHE" "$GOCACHE"

cat > "$PREFETCH/go.mod" <<'PROGRAMGYM_GO_MOD_EOF'
module github.com/knqyf263/pet

go 1.21

require (
	github.com/atotto/clipboard v0.1.4
	github.com/briandowns/spinner v1.23.1
	github.com/chzyer/readline v1.5.1
	github.com/fatih/color v1.18.0
	github.com/google/go-github v17.0.0+incompatible
	github.com/mattn/go-runewidth v0.0.16
	github.com/pkg/errors v0.9.1
	github.com/spf13/cobra v1.8.1
	github.com/xanzy/go-gitlab v0.114.0
	golang.org/x/oauth2 v0.24.0
	github.com/awesome-gocui/gocui v1.1.0
	github.com/go-test/deep v1.1.1
	github.com/pelletier/go-toml v1.9.5
	golang.org/x/term v0.27.0
	github.com/stretchr/testify v1.10.0
)

PROGRAMGYM_GO_MOD_EOF

# Resolve the toolchain the scratch module asks for (auto-downloaded through
# GOPROXY into the module cache). Pin PATH to it for the offline phase.
if _RESOLVED_GOROOT="$(cd "$PREFETCH" && go env GOROOT 2>/dev/null)" && [ -n "$_RESOLVED_GOROOT" ]; then
  if [ "$_RESOLVED_GOROOT" != "$(GOTOOLCHAIN=local go env GOROOT 2>/dev/null)" ]; then
    export GOROOT="$_RESOLVED_GOROOT"
    export PATH="$GOROOT/bin:$PATH"
  fi
fi

# Warm the module cache with every dependency (and its transitive tree).
if ! (cd "$PREFETCH" && go mod download all); then
  printf 'download.sh: dependency prefetch failed\n' >&2
  return 1
fi

printf 'download.sh: dependencies and toolchain prepared\n'
