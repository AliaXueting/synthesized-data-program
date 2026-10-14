#!/usr/bin/env bash
# download.sh — ONLINE dependency preparation for the offline build.
#
# This file is SOURCED, not executed. It warms the Go module cache with the
# dependency modules an mvdan.cc/sh/v3 (shfmt) implementation needs and lets
# the Go toolchain auto-resolve the release required by the module (>= 1.26;
# the pinned /usr/local/go toolchain is older). No source tree is required:
# the reproduction agent writes its own source and compiles it offline with
# compile.sh against this prepared cache.
#
# This file is pipeline-managed. Do not edit.

set -u
export GOTOOLCHAIN=auto
export GOFLAGS=-mod=mod

WS="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)" || return 1
BUILD_ENV="$WS/.programgym_build_env"
PREFETCH="$BUILD_ENV/go-prefetch"
mkdir -p "$PREFETCH"

# Cache layout lives inside the workspace so the offline phase (same
# workspace, no network) finds everything. The variable NAMES are the
# contract between the two phases; compile.sh re-derives path values from
# its own location.
export GOPATH="$BUILD_ENV/gopath"
export GOMODCACHE="$GOPATH/pkg/mod"
export GOCACHE="$BUILD_ENV/gocache"
mkdir -p "$GOMODCACHE" "$GOCACHE"

cat > "$PREFETCH/go.mod" <<'PROGRAMGYM_GO_MOD_EOF'
module mvdan.cc/sh/v3

go 1.26.0

require (
	github.com/creack/pty v1.1.24
	github.com/google/renameio/v2 v2.0.2
	golang.org/x/sys v0.49.0
	golang.org/x/term v0.47.0
	mvdan.cc/editorconfig v0.3.0
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
