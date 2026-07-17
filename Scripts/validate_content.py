#!/usr/bin/env python3
"""Validate bundled word and phrase packs without third-party dependencies."""

from __future__ import annotations

import json
import sys
import uuid
from collections import Counter
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
RESOURCES = ROOT / "NorskWordOfTheDay" / "Resources"
ALLOWED_LEVELS = {"A1", "A2", "B1", "B2", "C1"}
ALLOWED_BANDS = {
    "core-500",
    "rank-501-1000",
    "rank-1001-1500",
    "rank-1501-2000",
    "rank-2001-2500",
}
ALLOWED_PHRASE_TYPES = {
    "collocation",
    "fixed-expression",
    "conversational-frame",
    "particle-verb",
    "idiom",
    "proverb",
    "slang",
    "sentence-stem",
}
ALLOWED_REGISTERS = {"neutral", "informal", "formal"}
MINIMUM_SHIPPING_WORDS = 1_500
DISALLOWED_GENERATED_EXAMPLE_FRAGMENTS = (
    "kan bety",
    "ordet ",
    "på engelsk",
    "can mean",
    "the word ",
    "means in english",
)


class ValidationFailure(Exception):
    pass


def load_json(path: Path) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as error:
        raise ValidationFailure(f"missing resource: {path}") from error
    except json.JSONDecodeError as error:
        raise ValidationFailure(
            f"{path}:{error.lineno}:{error.colno}: invalid JSON: {error.msg}"
        ) from error


def require(entry: dict[str, Any], fields: set[str], location: str) -> None:
    missing = sorted(fields - entry.keys())
    if missing:
        raise ValidationFailure(f"{location}: missing fields: {', '.join(missing)}")


def parse_id(value: Any, location: str) -> str:
    try:
        return str(uuid.UUID(str(value))).upper()
    except (ValueError, TypeError, AttributeError) as error:
        raise ValidationFailure(f"{location}: invalid UUID: {value!r}") from error


def ensure_nonempty_text(value: Any, location: str) -> None:
    if not isinstance(value, str) or not value.strip():
        raise ValidationFailure(f"{location}: expected non-empty text")


def duplicates(values: list[Any]) -> list[Any]:
    return sorted(value for value, count in Counter(values).items() if count > 1)


def validate_regional_variants(entry: dict[str, Any], location: str) -> None:
    variants = entry.get("regionalVariants")
    if variants is None:
        return
    if not isinstance(variants, list):
        raise ValidationFailure(f"{location}.regionalVariants: expected an array or null")

    forms: list[str] = []
    for index, variant in enumerate(variants):
        variant_location = f"{location}.regionalVariants[{index}]"
        if not isinstance(variant, dict):
            raise ValidationFailure(f"{variant_location}: expected an object")
        require(variant, {"form", "region", "note"}, variant_location)
        ensure_nonempty_text(variant["form"], f"{variant_location}.form")
        ensure_nonempty_text(variant["region"], f"{variant_location}.region")
        if variant["note"] is not None:
            ensure_nonempty_text(variant["note"], f"{variant_location}.note")
        forms.append(variant["form"].casefold())

    if repeated := duplicates(forms):
        raise ValidationFailure(f"{location}.regionalVariants: duplicate forms: {repeated}")
    if variants and "vestland" not in entry["tags"]:
        raise ValidationFailure(f"{location}.tags: regional variants require the vestland tag")


def validate_words(words: Any) -> set[str]:
    if not isinstance(words, list) or not words:
        raise ValidationFailure("words.json: expected a non-empty array")
    if len(words) < MINIMUM_SHIPPING_WORDS:
        raise ValidationFailure(
            f"words.json: expected at least {MINIMUM_SHIPPING_WORDS} entries, got {len(words)}"
        )

    required = {
        "id", "rank", "teachingPriority", "frequencyBand", "contentVersion", "level",
        "lemma", "displayForm", "partOfSpeech", "englishDefinition",
        "norwegianDefinition", "gender", "inflections", "exampleNorwegian",
        "exampleEnglish", "alternateMeanings", "tags",
    }
    ids: list[str] = []
    ranks: list[int] = []
    priorities: list[int] = []

    for index, word in enumerate(words):
        location = f"words.json[{index}]"
        if not isinstance(word, dict):
            raise ValidationFailure(f"{location}: expected an object")
        require(word, required, location)
        ids.append(parse_id(word["id"], f"{location}.id"))
        for field in ("lemma", "displayForm", "englishDefinition", "exampleNorwegian", "exampleEnglish"):
            ensure_nonempty_text(word[field], f"{location}.{field}")
        if not isinstance(word["rank"], int) or word["rank"] < 1:
            raise ValidationFailure(f"{location}.rank: expected a positive integer")
        if not isinstance(word["teachingPriority"], int) or word["teachingPriority"] < 1:
            raise ValidationFailure(f"{location}.teachingPriority: expected a positive integer")
        if word["frequencyBand"] not in ALLOWED_BANDS:
            raise ValidationFailure(f"{location}.frequencyBand: unsupported value")
        if word["level"] not in ALLOWED_LEVELS:
            raise ValidationFailure(f"{location}.level: unsupported value")
        validate_regional_variants(word, location)
        if "auto-generated" in word["tags"]:
            if "wiktionary" not in word["tags"]:
                raise ValidationFailure(f"{location}.tags: generated entries require attribution")
            if not any(str(tag).startswith("source-rank-") for tag in word["tags"]):
                raise ValidationFailure(f"{location}.tags: generated entries require source rank")
            example_pair = f"{word['exampleNorwegian']} {word['exampleEnglish']}".casefold()
            if any(fragment in example_pair for fragment in DISALLOWED_GENERATED_EXAMPLE_FRAGMENTS):
                raise ValidationFailure(
                    f"{location}: generated examples must be real usage, not a definition template"
                )
        ranks.append(word["rank"])
        priorities.append(word["teachingPriority"])

    if repeated := duplicates(ids):
        raise ValidationFailure(f"words.json: duplicate IDs: {', '.join(repeated)}")
    if repeated := duplicates(ranks):
        raise ValidationFailure(f"words.json: duplicate ranks: {repeated}")
    if repeated := duplicates(priorities):
        raise ValidationFailure(f"words.json: duplicate teaching priorities: {repeated}")
    if set(ranks) != set(range(1, len(words) + 1)):
        raise ValidationFailure("words.json: ranks must form a contiguous 1-based catalog")
    return set(ids)


def validate_phrases(phrases: Any, word_ids: set[str]) -> set[str]:
    if not isinstance(phrases, list) or not phrases:
        raise ValidationFailure("phrases.json: expected a non-empty array")

    required = {
        "id", "teachingPriority", "contentVersion", "level", "norwegian", "english",
        "literalTranslation", "usageNote", "type", "register", "componentWordIDs",
        "focusWordIDs", "exampleNorwegian", "exampleEnglish", "alternateForms", "slots",
        "isStandalone", "isWidgetEligible", "tags",
    }
    ids: list[str] = []
    priorities: list[int] = []

    for index, phrase in enumerate(phrases):
        location = f"phrases.json[{index}]"
        if not isinstance(phrase, dict):
            raise ValidationFailure(f"{location}: expected an object")
        require(phrase, required, location)
        ids.append(parse_id(phrase["id"], f"{location}.id"))
        priorities.append(phrase["teachingPriority"])
        for field in ("norwegian", "english", "exampleNorwegian", "exampleEnglish"):
            ensure_nonempty_text(phrase[field], f"{location}.{field}")
        if phrase["type"] not in ALLOWED_PHRASE_TYPES:
            raise ValidationFailure(f"{location}.type: unsupported value")
        if phrase["register"] not in ALLOWED_REGISTERS:
            raise ValidationFailure(f"{location}.register: unsupported value")
        if phrase["level"] not in ALLOWED_LEVELS:
            raise ValidationFailure(f"{location}.level: unsupported value")
        if not phrase["focusWordIDs"]:
            raise ValidationFailure(f"{location}.focusWordIDs: expected at least one word")
        references = phrase["componentWordIDs"] + phrase["focusWordIDs"]
        for reference_index, reference in enumerate(references):
            normalized = parse_id(reference, f"{location}.wordReference[{reference_index}]")
            if normalized not in word_ids:
                raise ValidationFailure(f"{location}: missing word reference {normalized}")
        validate_regional_variants(phrase, location)

    if repeated := duplicates(ids):
        raise ValidationFailure(f"phrases.json: duplicate IDs: {', '.join(repeated)}")
    if repeated := duplicates(priorities):
        raise ValidationFailure(f"phrases.json: duplicate teaching priorities: {repeated}")
    return set(ids)


def validate_manifest(manifest: Any, words: list[Any], phrases: list[Any]) -> None:
    if not isinstance(manifest, dict):
        raise ValidationFailure("content-manifest.json: expected an object")
    require(manifest, {"schemaVersion", "contentVersion", "language", "packs"}, "content-manifest.json")
    if manifest["schemaVersion"] != 1:
        raise ValidationFailure("content-manifest.json: unsupported schemaVersion")
    if manifest["language"] != "nb-NO":
        raise ValidationFailure("content-manifest.json: expected language nb-NO")

    expected_counts = {"words.json": len(words), "phrases.json": len(phrases)}
    seen_resources: set[str] = set()
    for index, pack in enumerate(manifest["packs"]):
        location = f"content-manifest.json.packs[{index}]"
        require(pack, {"id", "kind", "version", "resource", "itemCount"}, location)
        resource = pack["resource"]
        if resource not in expected_counts:
            raise ValidationFailure(f"{location}.resource: unexpected resource {resource!r}")
        if resource in seen_resources:
            raise ValidationFailure(f"{location}.resource: duplicate pack resource")
        seen_resources.add(resource)
        if pack["itemCount"] != expected_counts[resource]:
            raise ValidationFailure(
                f"{location}.itemCount: expected {expected_counts[resource]}, got {pack['itemCount']}"
            )
    if seen_resources != set(expected_counts):
        raise ValidationFailure("content-manifest.json: does not include every content resource")


def main() -> int:
    try:
        manifest = load_json(RESOURCES / "content-manifest.json")
        words = load_json(RESOURCES / "words.json")
        phrases = load_json(RESOURCES / "phrases.json")
        word_ids = validate_words(words)
        phrase_ids = validate_phrases(phrases, word_ids)
        if overlap := word_ids & phrase_ids:
            raise ValidationFailure(f"IDs reused across content types: {', '.join(sorted(overlap))}")
        validate_manifest(manifest, words, phrases)
    except ValidationFailure as error:
        print(f"Content validation failed: {error}", file=sys.stderr)
        return 1

    print(f"Validated {len(words)} words and {len(phrases)} phrases.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
