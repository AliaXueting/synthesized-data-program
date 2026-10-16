#!/usr/bin/env bash
# download.sh — ONLINE dependency preparation for the offline build.
#
# This file is SOURCED, not executed. It warms the Go module cache with the
# dependency modules a github.com/itchyny/gojq implementation needs and lets the Go toolchain
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
module github.com/itchyny/gojq

go 1.24.0

require (
	github.com/google/go-cmp v0.7.0
	github.com/itchyny/go-yaml v0.0.0-20260915070000-e6b590a63860
	github.com/itchyny/timefmt-go v0.1.8
	github.com/mattn/go-isatty v0.0.20
	github.com/mattn/go-runewidth v0.0.19
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
