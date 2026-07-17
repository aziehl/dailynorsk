#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
METADATA="$ROOT/ContentPipeline/Config/wiktionary-source.json"
DESTINATION="$ROOT/ContentPipeline/Sources/kaikki-norwegian-bokmal.jsonl"

url="$(jq -r '.downloadURL' "$METADATA")"
expected_sha="$(jq -r '.sha256' "$METADATA")"

mkdir -p "$(dirname "$DESTINATION")"
temporary="$(mktemp "${TMPDIR:-/tmp}/daily-norsk-wiktionary.XXXXXX")"
trap 'rm -f "$temporary"' EXIT

curl --fail --location --show-error "$url" --output "$temporary"
actual_sha="$(shasum -a 256 "$temporary" | awk '{print $1}')"

if [[ "$actual_sha" != "$expected_sha" ]]; then
  printf 'Wiktionary source checksum mismatch.\nExpected: %s\nActual:   %s\n' \
    "$expected_sha" "$actual_sha" >&2
  printf 'The upstream rolling export changed. Audit it and update wiktionary-source.json deliberately.\n' >&2
  exit 1
fi

mv "$temporary" "$DESTINATION"
trap - EXIT
printf 'Fetched verified lexical source to %s\n' "$DESTINATION"
