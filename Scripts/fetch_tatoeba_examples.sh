#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
METADATA="$ROOT/ContentPipeline/Config/tatoeba-source.json"
DESTINATION_DIR="$ROOT/ContentPipeline/Sources"

mkdir -p "$DESTINATION_DIR"

while IFS=$'\t' read -r name url expected_sha; do
  destination="$DESTINATION_DIR/$name"
  temporary="$(mktemp "${TMPDIR:-/tmp}/daily-norsk-tatoeba.XXXXXX")"
  trap 'rm -f "$temporary"' EXIT

  curl --fail --location --show-error "$url" --output "$temporary"
  actual_sha="$(shasum -a 256 "$temporary" | awk '{print $1}')"
  if [[ "$actual_sha" != "$expected_sha" ]]; then
    printf 'Tatoeba source checksum mismatch for %s.\nExpected: %s\nActual:   %s\n' \
      "$name" "$expected_sha" "$actual_sha" >&2
    printf 'The weekly export changed. Audit it and update tatoeba-source.json deliberately.\n' >&2
    exit 1
  fi

  mv "$temporary" "$destination"
  trap - EXIT
  printf 'Fetched verified Tatoeba source to %s\n' "$destination"
done < <(jq -r '.files[] | [.name, .downloadURL, .sha256] | @tsv' "$METADATA")
