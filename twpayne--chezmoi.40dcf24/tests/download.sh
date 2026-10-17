#!/usr/bin/env bash
# download.sh — ONLINE dependency preparation for the offline build.
#
# This file is SOURCED, not executed. It warms the Go module cache with the
# dependency modules a chezmoi.io/chezmoi/v2 implementation needs and lets the Go toolchain
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
module chezmoi.io/chezmoi/v2

go 1.26.0

require (
	filippo.io/age v1.3.2
	github.com/Azure/azure-sdk-for-go/sdk/azidentity v1.14.1
	github.com/Azure/azure-sdk-for-go/sdk/security/keyvault/azsecrets v1.5.0
	github.com/BurntSushi/toml v1.6.0
	github.com/Masterminds/sprig/v3 v3.3.0
	github.com/Shopify/ejson v1.6.0
	github.com/alecthomas/assert/v2 v2.11.0
	github.com/aws/aws-sdk-go-v2 v1.47.3
	github.com/aws/aws-sdk-go-v2/config v1.33.9
	github.com/aws/aws-sdk-go-v2/service/secretsmanager v1.50.4
	github.com/bartventer/httpcache v0.14.0
	github.com/betterleaks/betterleaks v1.9.0
	github.com/bmatcuk/doublestar/v4 v4.10.2
	github.com/bradenhilton/mozillainstallhash v1.0.1
	github.com/charmbracelet/bubbles v0.20.0
	github.com/charmbracelet/bubbletea v1.3.10
	github.com/charmbracelet/glamour v1.0.0
	github.com/charmbracelet/lipgloss v1.1.1-0.20250404203927-76690c660834
	github.com/coreos/go-semver v0.3.1
	github.com/dustin/go-humanize v1.1.0
	github.com/fsnotify/fsnotify v1.10.1
	github.com/go-git/go-git/v5 v5.19.3
	github.com/go-sprout/sprout v1.1.2
	github.com/go-viper/mapstructure/v2 v2.5.0
	github.com/goccy/go-yaml v1.19.2
	github.com/google/go-github/v72 v72.0.0
	github.com/google/renameio/v2 v2.0.2
	github.com/gopasspw/gopass v1.17.4
	github.com/itchyny/gojq v0.12.19
	github.com/klauspost/compress v1.20.1
	github.com/mitchellh/copystructure v1.2.0
	github.com/muesli/combinator v0.3.0
	github.com/muesli/termenv v0.16.0
	github.com/nwaples/rardecode/v2 v2.4.2
	github.com/pete-woods/go-expect v0.1.4
	github.com/rogpeppe/go-internal v1.16.0
	github.com/spf13/cobra v1.10.2
	github.com/spf13/pflag v1.0.10
	github.com/tailscale/hujson v0.0.0-20260727124030-b80ff77dac4f
	github.com/tobischo/gokeepasslib/v3 v3.7.0
	github.com/twpayne/go-pinentry/v4 v4.0.1
	github.com/twpayne/go-shell v0.5.0
	github.com/twpayne/go-vfs/v5 v5.0.5
	github.com/twpayne/go-xdg/v6 v6.1.3
	github.com/ulikunitz/xz v0.5.17
	github.com/zalando/go-keyring v0.2.8
	go.etcd.io/bbolt v1.5.0
	golang.org/x/crypto v0.58.0
	golang.org/x/oauth2 v0.37.0
	golang.org/x/sync v0.24.0
	golang.org/x/sys v0.49.0
	golang.org/x/term v0.47.0
	golang.org/x/text v0.43.0
	gopkg.in/ini.v1 v1.67.3
	howett.net/plist v1.0.1
	mvdan.cc/sh/v3 v3.14.1
	znkr.io/diff v1.0.2
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
