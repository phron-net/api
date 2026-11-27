#!/usr/bin/env bash
# Regenerate gen/ and tidy go.mod/go.sum. Run by CI (see README); not meant for
# a developer workstation.
set -euo pipefail
cd "$(dirname "$0")/.."
# shellcheck source=tools.env
source scripts/tools.env
export GOBIN="${RUNNER_TEMP:-/tmp}/phron-api-tools"
mkdir -p "$GOBIN"
export PATH="$GOBIN:$PATH"
go install "google.golang.org/protobuf/cmd/protoc-gen-go@${PROTOC_GEN_GO}"
go install "connectrpc.com/connect/cmd/protoc-gen-connect-go@${CONNECT_GO}"
buf --version
buf lint
buf generate
go mod tidy
