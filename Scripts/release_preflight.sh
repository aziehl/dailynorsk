#!/usr/bin/env bash

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

failures=0

pass() {
  printf 'PASS: %s\n' "$1"
}

block() {
  printf 'BLOCKER: %s\n' "$1" >&2
  failures=$((failures + 1))
}

if Scripts/validate_content.py; then
  pass "Bundled content passes strict validation"
else
  block "Bundled content validation failed"
fi

word_count="$(jq 'length' NorskWordOfTheDay/Resources/words.json)"
phrase_count="$(jq 'length' NorskWordOfTheDay/Resources/phrases.json)"
minimum_words="${DAILY_NORSK_MINIMUM_RELEASE_WORDS:-1500}"
minimum_phrases="${DAILY_NORSK_MINIMUM_RELEASE_PHRASES:-20}"

if (( word_count >= minimum_words )); then
  pass "Bundled catalog contains ${word_count} words"
else
  block "Bundled catalog contains ${word_count} words; the configured release minimum is ${minimum_words}"
fi

if (( phrase_count >= minimum_phrases )); then
  pass "Bundled catalog contains ${phrase_count} phrases"
else
  block "Bundled catalog contains ${phrase_count} phrases; the configured release minimum is ${minimum_phrases}"
fi

identifier_files=(
  NorskWordOfTheDay.xcodeproj/project.pbxproj
  NorskWordOfTheDay/SupportingFiles/App.entitlements
  NorskWidget/SupportingFiles/Widget.entitlements
  NorskWordOfTheDay/Shared/SharedDefaults.swift
)

if rg -q '(^|[.=])com\.example|group\.com\.example' "${identifier_files[@]}"; then
  block "Example bundle or App Group identifiers remain"
else
  pass "Bundle and App Group identifiers are publisher-owned values"
fi

if rg -q 'DEVELOPMENT_TEAM = [A-Z0-9]+;' NorskWordOfTheDay.xcodeproj/project.pbxproj; then
  pass "An Apple development team is configured"
else
  block "No Apple development team is configured"
fi

publisher="$(sed -n 's/^- Publisher\/copyright holder:[[:space:]]*//p' LEGAL/CONTENT_RIGHTS.md | tail -n 1)"
editor="$(sed -n 's/^- Reviewing Norwegian editor:[[:space:]]*//p' LEGAL/CONTENT_RIGHTS.md | tail -n 1)"
approval_date="$(sed -n 's/^- Date approved:[[:space:]]*//p' LEGAL/CONTENT_RIGHTS.md | tail -n 1)"

if [[ -n "$publisher" && -n "$editor" && -n "$approval_date" ]]; then
  pass "Content-rights and Norwegian editorial sign-off is recorded"
else
  block "Content-rights release record is not signed by the publisher and Norwegian editor"
fi

validate_public_url() {
  local label="$1"
  local value="$2"
  if [[ "$value" == https://* ]]; then
    pass "$label is configured as HTTPS"
  else
    block "$label is missing; supply it as an HTTPS URL"
  fi
}

validate_public_url "Support URL" "${DAILY_NORSK_SUPPORT_URL:-}"
validate_public_url "Privacy Policy URL" "${DAILY_NORSK_PRIVACY_URL:-}"

if (( failures > 0 )); then
  printf '\nRelease preflight found %d blocker(s).\n' "$failures" >&2
  exit 1
fi

printf '\nRelease preflight passed. Complete signed Organizer validation and physical-device/TestFlight QA before submission.\n'
