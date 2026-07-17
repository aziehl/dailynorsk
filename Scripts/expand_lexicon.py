#!/usr/bin/env python3
"""Build a 1,500-word shipping pack from curated lessons and licensed evidence."""

from __future__ import annotations

import argparse
import bz2
from collections import Counter, defaultdict
import hashlib
import json
import re
import sys
from pathlib import Path
from typing import Any
from urllib.parse import quote


ROOT = Path(__file__).resolve().parents[1]
RESOURCES = ROOT / "NorskWordOfTheDay" / "Resources"
DEFAULT_CANDIDATES = ROOT / "ContentPipeline" / "Generated" / "word-candidates.json"
DEFAULT_WIKTIONARY = ROOT / "ContentPipeline" / "Sources" / "kaikki-norwegian-bokmal.jsonl"
DEFAULT_SOURCE_METADATA = ROOT / "ContentPipeline" / "Config" / "wiktionary-source.json"
DEFAULT_TATOEBA_METADATA = ROOT / "ContentPipeline" / "Config" / "tatoeba-source.json"
DEFAULT_TATOEBA_DIRECTORY = ROOT / "ContentPipeline" / "Sources"
DEFAULT_EVIDENCE = ROOT / "ContentPipeline" / "Generated" / "shipping-lexicon-evidence.json"

POS_MAPPING: dict[str, tuple[str, set[str]]] = {
    "NOUN": ("noun", {"noun"}),
    "VERB": ("verb", {"verb"}),
    "AUX": ("verb", {"verb"}),
    "ADJ": ("adjective", {"adj"}),
    "ADV": ("adverb", {"adv"}),
    "PART": ("adverb", {"adv", "particle"}),
    "ADP": ("preposition", {"prep"}),
    "CCONJ": ("conjunction", {"conj"}),
    "SCONJ": ("conjunction", {"conj"}),
    "DET": ("determiner", {"det", "article"}),
    "PRON": ("pronoun", {"pron"}),
    "NUM": ("numeral", {"num"}),
    "INTJ": ("interjection", {"intj"}),
}

DISCOURAGED_SENSE_TAGS = {
    "abbreviation",
    "archaic",
    "dated",
    "historical",
    "initialism",
    "misspelling",
    "nonstandard",
    "obsolete",
    "rare",
}

DISCOURAGED_GLOSS_FRAGMENTS = (
    "abbreviation of",
    "alternative form of",
    "alternative spelling of",
    "comparative of",
    "dated form of",
    "inflection of",
    "initialism of",
    "misspelling of",
    "obsolete form of",
    "past participle of",
    "plural of",
    "present participle of",
    "superlative of",
)

USEFUL_FORM_TAGS = {
    "comparative",
    "definite",
    "feminine",
    "imperative",
    "indefinite",
    "masculine",
    "neuter",
    "participle",
    "passive",
    "past",
    "plural",
    "present",
    "singular",
    "superlative",
}

GLOSS_STOP_WORDS = {
    "a", "an", "the", "used",
}

METALINGUISTIC_EXAMPLE_FRAGMENTS = (
    "kan bety",
    "ordet betyr",
    "ordet ",
    "på engelsk",
    "can mean",
    "means in english",
    "the word means",
    "the word ",
)

UNSUITABLE_EXAMPLE_FRAGMENTS = (
    "porno",
    "pornography",
    "pornos",
    "meth",
    "heroin",
    "kokain",
    "cocaine",
    "voldtekt",
    "rape",
    "selvmord",
    "suicide",
    "seksuelt",
    "sexual intercourse",
    "oral intercourse",
    "anal intercourse",
)


def is_safe_example_pair(norwegian: str, english: str) -> bool:
    lowered_pair = f"{normalized(norwegian)} {normalized(english)}"
    return not any(
        fragment in lowered_pair
        for fragment in (*METALINGUISTIC_EXAMPLE_FRAGMENTS, *UNSUITABLE_EXAMPLE_FRAGMENTS)
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--target-count", type=int, default=1_500)
    parser.add_argument("--candidates", type=Path, default=DEFAULT_CANDIDATES)
    parser.add_argument("--wiktionary", type=Path, default=DEFAULT_WIKTIONARY)
    parser.add_argument("--source-metadata", type=Path, default=DEFAULT_SOURCE_METADATA)
    parser.add_argument("--tatoeba-metadata", type=Path, default=DEFAULT_TATOEBA_METADATA)
    parser.add_argument("--tatoeba-directory", type=Path, default=DEFAULT_TATOEBA_DIRECTORY)
    parser.add_argument("--words", type=Path, default=RESOURCES / "words.json")
    parser.add_argument("--manifest", type=Path, default=RESOURCES / "content-manifest.json")
    parser.add_argument("--evidence-output", type=Path, default=DEFAULT_EVIDENCE)
    return parser.parse_args()


def normalized(value: str) -> str:
    return value.strip().casefold()


def collapse_text(value: str) -> str:
    return re.sub(r"\s+", " ", value).strip()


def word_tokens(value: str) -> list[str]:
    return re.findall(
        r"[^\W_]+(?:[-’'][^\W_]+)*",
        normalized(value),
        flags=re.UNICODE,
    )


def dictionary_gloss(value: str) -> str:
    """Turn an extracted explanatory gloss into a concise dictionary head gloss."""
    gloss = collapse_text(value).strip(" .")
    gloss = re.sub(
        r"^(?:used as (?:an? )?[^:]+|existing in [^:]+):\s*",
        "",
        gloss,
        flags=re.IGNORECASE,
    )
    depth = 0
    lowered = gloss.casefold()
    explanatory_suffixes = (
        " indicating ",
        " introducing ",
        " used as ",
        " used for ",
        " used to ",
        " especially when ",
    )
    for position, character in enumerate(gloss):
        if character in "([":
            depth += 1
        elif character in ")]":
            depth = max(0, depth - 1)
        elif character == ";" and depth == 0:
            gloss = gloss[:position].strip()
            break
        elif depth == 0 and any(
            lowered.startswith(suffix, position) for suffix in explanatory_suffixes
        ):
            gloss = gloss[:position].strip()
            break
    gloss = gloss.strip(" ,;.")
    return gloss or collapse_text(value).strip(" .")


def file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def frequency_band(rank: int) -> str:
    if rank <= 500:
        return "core-500"
    if rank <= 1_000:
        return "rank-501-1000"
    if rank <= 1_500:
        return "rank-1001-1500"
    if rank <= 2_000:
        return "rank-1501-2000"
    return "rank-2001-2500"


def cefr_level(rank: int) -> str:
    if rank <= 500:
        return "A1"
    if rank <= 1_000:
        return "A2"
    if rank <= 1_500:
        return "B1"
    if rank <= 2_000:
        return "B2"
    return "C1"


def candidate_for_curated(
    word: dict[str, Any], candidates: list[dict[str, Any]]
) -> dict[str, Any] | None:
    lemma = normalized(word["lemma"])
    exact = [candidate for candidate in candidates if normalized(candidate["lemma"]) == lemma]
    if exact:
        return min(exact, key=lambda item: item["frequencyRank"])

    token_matches = [
        candidate
        for candidate in candidates
        if any(normalized(token["token"]) == lemma for token in candidate["sourceTokens"])
    ]
    return min(token_matches, key=lambda item: item["frequencyRank"], default=None)


def load_wiktionary(path: Path, wanted: set[str]) -> dict[str, list[dict[str, Any]]]:
    entries: dict[str, list[dict[str, Any]]] = {}
    with path.open(encoding="utf-8") as handle:
        for line_number, line in enumerate(handle, start=1):
            try:
                item = json.loads(line)
            except json.JSONDecodeError as error:
                raise SystemExit(f"{path}:{line_number}: invalid JSON: {error}") from error
            key = normalized(item.get("word", ""))
            if key in wanted:
                entries.setdefault(key, []).append(item)
    return entries


def load_tatoeba_index(
    source_directory: Path,
    metadata: dict[str, Any],
) -> dict[str, list[dict[str, Any]]]:
    files = {item["name"]: item for item in metadata["files"]}
    nob_name = "tatoeba-nob-sentences-detailed.tsv.bz2"
    eng_name = "tatoeba-eng-sentences-detailed.tsv.bz2"
    links_name = "tatoeba-eng-nob-links.tsv.bz2"
    for name in (nob_name, eng_name, links_name):
        if name not in files:
            raise SystemExit(f"Tatoeba metadata is missing {name}.")
        path = source_directory / name
        if not path.exists():
            raise SystemExit(f"Missing {path}. Run Scripts/fetch_tatoeba_examples.sh.")
        actual_sha = file_sha256(path)
        if actual_sha != files[name]["sha256"]:
            raise SystemExit(
                f"Tatoeba source checksum mismatch for {name}. "
                "Run Scripts/fetch_tatoeba_examples.sh or audit the new weekly export."
            )

    norwegian: dict[int, dict[str, str]] = {}
    with bz2.open(source_directory / nob_name, "rt", encoding="utf-8") as handle:
        for line in handle:
            row = line.rstrip("\n").split("\t")
            if len(row) >= 4:
                norwegian[int(row[0])] = {"text": row[2], "author": row[3]}

    links: list[tuple[int, int]] = []
    english_ids: set[int] = set()
    with bz2.open(source_directory / links_name, "rt", encoding="utf-8") as handle:
        for line in handle:
            english_id, norwegian_id = (int(value) for value in line.split())
            links.append((english_id, norwegian_id))
            english_ids.add(english_id)

    english: dict[int, dict[str, str]] = {}
    with bz2.open(source_directory / eng_name, "rt", encoding="utf-8") as handle:
        for line in handle:
            row = line.rstrip("\n").split("\t")
            if len(row) >= 4 and int(row[0]) in english_ids:
                english[int(row[0])] = {"text": row[2], "author": row[3]}

    index: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for english_id, norwegian_id in links:
        norwegian_record = norwegian.get(norwegian_id)
        english_record = english.get(english_id)
        if norwegian_record is None or english_record is None:
            continue
        norwegian_text = collapse_text(norwegian_record["text"])
        english_text = collapse_text(english_record["text"])
        tokens = word_tokens(norwegian_text)
        if not 2 <= len(tokens) <= 18:
            continue
        if len(norwegian_text) > 140 or len(english_text) > 180:
            continue
        if not is_safe_example_pair(norwegian_text, english_text):
            continue
        example = {
            "norwegian": norwegian_text,
            "english": english_text,
            "norwegianID": norwegian_id,
            "englishID": english_id,
            "norwegianAuthor": norwegian_record["author"],
            "englishAuthor": english_record["author"],
            "norwegianTokens": tokens,
            "englishTokens": word_tokens(english_text),
        }
        for token in set(tokens):
            index[token].append(example)
    return dict(index)


def usable_gloss(sense: dict[str, Any]) -> str | None:
    if sense.get("form_of") or sense.get("alt_of"):
        return None
    tags = set(sense.get("tags") or [])
    if tags & DISCOURAGED_SENSE_TAGS:
        return None
    glosses = sense.get("glosses") or []
    if not glosses:
        return None
    gloss = collapse_text(glosses[0])
    lowered = gloss.casefold()
    if not gloss or len(gloss) > 220:
        return None
    if any(fragment in lowered for fragment in DISCOURAGED_GLOSS_FRAGMENTS):
        return None
    return gloss


def choose_lexical_evidence(
    candidate: dict[str, Any], entries: list[dict[str, Any]]
) -> tuple[dict[str, Any], dict[str, Any], str] | None:
    mapping = POS_MAPPING.get(candidate["partOfSpeechEvidence"])
    if mapping is None:
        return None
    _, wiktionary_parts_of_speech = mapping

    choices: list[tuple[int, dict[str, Any], dict[str, Any], str]] = []
    for entry_position, entry in enumerate(entries):
        if entry.get("pos") not in wiktionary_parts_of_speech:
            continue
        for sense_position, sense in enumerate(entry.get("senses") or []):
            gloss = usable_gloss(sense)
            if gloss is None:
                continue
            # Wiktionary orders an entry's senses deliberately. Preserve that
            # dictionary ordering instead of allowing example availability or
            # gloss length to promote a secondary meaning.
            score = 10_000 - (entry_position * 100) - (sense_position * 10)
            choices.append((score, entry, sense, gloss))

    if not choices:
        return None
    _, entry, sense, gloss = max(choices, key=lambda value: value[0])
    return entry, sense, gloss


def gender_for(entry: dict[str, Any], sense: dict[str, Any]) -> str | None:
    if entry.get("pos") != "noun":
        return None
    tags = set(sense.get("tags") or [])
    if "neuter" in tags:
        return "neuter"
    if "masculine" in tags:
        return "masculine"
    if "feminine" in tags:
        return "feminine"
    return None


def display_form(lemma: str, part_of_speech: str, gender: str | None) -> str:
    if part_of_speech == "verb":
        return f"å {lemma}"
    if part_of_speech == "noun":
        article = {"feminine": "ei", "neuter": "et"}.get(gender, "en")
        return f"{article} {lemma}"
    return lemma


def inflections_for(entry: dict[str, Any], lemma: str) -> list[str]:
    result: list[str] = []
    seen = {normalized(lemma)}
    for form in entry.get("forms") or []:
        value = collapse_text(form.get("form", ""))
        key = normalized(value)
        if not value or key in seen or len(value) > 60 or " " in value:
            continue
        tags = set(form.get("tags") or [])
        if tags & ({"canonical", "romanization", "table-tags"} | DISCOURAGED_SENSE_TAGS):
            continue
        if not tags & USEFUL_FORM_TAGS:
            continue
        seen.add(key)
        result.append(value)
        if len(result) == 6:
            break
    return result


def alternate_meanings(entry: dict[str, Any], primary: str) -> list[str]:
    result: list[str] = []
    seen = {normalized(dictionary_gloss(primary))}
    for sense in entry.get("senses") or []:
        gloss = usable_gloss(sense)
        if gloss is None:
            continue
        gloss = dictionary_gloss(gloss)
        if normalized(gloss) in seen:
            continue
        seen.add(normalized(gloss))
        result.append(gloss)
        if len(result) == 3:
            break
    return result


def example_forms(entry: dict[str, Any], lemma: str) -> set[str]:
    forms = {normalized(lemma)}
    for form in entry.get("forms") or []:
        value = normalized(form.get("form", ""))
        tags = set(form.get("tags") or [])
        if not value or " " in value or len(value) > 60:
            continue
        if tags & ({"romanization", "table-tags"} | DISCOURAGED_SENSE_TAGS):
            continue
        forms.add(value)
    return forms


def wiktionary_example_for(
    sense: dict[str, Any], lemma: str
) -> tuple[str, str, dict[str, Any]] | None:
    candidates: list[tuple[int, str, str]] = []
    for example in sense.get("examples") or []:
        norwegian = collapse_text(example.get("text", ""))
        english = collapse_text(example.get("english") or example.get("translation") or "")
        if example.get("type") != "example" or example.get("ref") or not norwegian or not english:
            continue
        if len(norwegian) > 140 or len(english) > 180:
            continue
        if "\n" in norwegian or "\n" in english:
            continue
        if not is_safe_example_pair(norwegian, english):
            continue
        norwegian_token_count = len(word_tokens(norwegian))
        english_token_count = len(word_tokens(english))
        # Prefer complete, naturally readable examples but retain a concise
        # source phrase when it is the only licensed example for an entry.
        score = norwegian_token_count + english_token_count
        if norwegian.endswith((".", "!", "?")):
            score += 20
        if english.endswith((".", "!", "?")):
            score += 10
        if norwegian_token_count >= 3 and english_token_count >= 3:
            score += 10
        candidates.append((score, norwegian, english))
    if not candidates:
        return None
    _, norwegian, english = max(candidates, key=lambda item: item[0])
    return (
        norwegian,
        english,
        {
            "name": "English Wiktionary",
            "entry": f"https://en.wiktionary.org/wiki/{quote(lemma)}",
        },
    )


def tatoeba_example_for(
    entry: dict[str, Any],
    lemma: str,
    gloss: str,
    index: dict[str, list[dict[str, Any]]],
    used_norwegian_ids: set[int],
) -> tuple[str, str, dict[str, Any]] | None:
    forms = {form for form in example_forms(entry, lemma) if len(form) > 1 or form == lemma}
    candidates: dict[tuple[int, int], dict[str, Any]] = {}
    for form in forms:
        for example in index.get(form, []):
            candidates[(example["norwegianID"], example["englishID"])] = example
    if not candidates:
        return None

    lemma_key = normalized(lemma)
    gloss_tokens = {
        token
        for token in word_tokens(dictionary_gloss(gloss))
        if token not in GLOSS_STOP_WORDS
    }

    def score(example: dict[str, Any]) -> tuple[int, int, int]:
        norwegian_tokens = set(example["norwegianTokens"])
        english_tokens = set(example["englishTokens"])
        token_count = len(example["norwegianTokens"])
        value = 0
        if example["norwegianID"] not in used_norwegian_ids:
            value += 40
        if lemma_key in norwegian_tokens:
            value += 80
        value += 100 * len(gloss_tokens & english_tokens)
        if 3 <= token_count <= 10:
            value += 25
        value -= abs(token_count - 6)
        if example["norwegian"].endswith((".", "!", "?")):
            value += 5
        if example["english"].endswith((".", "!", "?")):
            value += 3
        if example["norwegianAuthor"] not in {"", "\\N"}:
            value += 2
        if example["englishAuthor"] not in {"", "\\N"}:
            value += 2
        return value, -example["norwegianID"], -example["englishID"]

    selected = max(candidates.values(), key=score)
    used_norwegian_ids.add(selected["norwegianID"])
    return (
        selected["norwegian"],
        selected["english"],
        {
            "name": "Tatoeba",
            "norwegianSentenceID": selected["norwegianID"],
            "englishSentenceID": selected["englishID"],
            "norwegianAuthor": selected["norwegianAuthor"],
            "englishAuthor": selected["englishAuthor"],
            "norwegianURL": f"https://tatoeba.org/en/sentences/show/{selected['norwegianID']}",
            "englishURL": f"https://tatoeba.org/en/sentences/show/{selected['englishID']}",
        },
    )


def examples_for(
    entry: dict[str, Any],
    sense: dict[str, Any],
    lemma: str,
    gloss: str,
    tatoeba_index: dict[str, list[dict[str, Any]]],
    used_tatoeba_ids: set[int],
) -> tuple[str, str, dict[str, Any]] | None:
    wiktionary_example = wiktionary_example_for(sense, lemma)
    if wiktionary_example is not None:
        return wiktionary_example
    return tatoeba_example_for(
        entry,
        lemma,
        gloss,
        tatoeba_index,
        used_tatoeba_ids,
    )


def build_generated_word(
    candidate: dict[str, Any],
    evidence: tuple[dict[str, Any], dict[str, Any], str],
    tatoeba_index: dict[str, list[dict[str, Any]]],
    used_tatoeba_ids: set[int],
) -> tuple[dict[str, Any], dict[str, Any]] | None:
    entry, sense, gloss = evidence
    part_of_speech, _ = POS_MAPPING[candidate["partOfSpeechEvidence"]]
    gender = gender_for(entry, sense)
    selected_example = examples_for(
        entry,
        sense,
        candidate["lemma"],
        gloss,
        tatoeba_index,
        used_tatoeba_ids,
    )
    if selected_example is None:
        return None
    norwegian_example, english_example, example_source = selected_example
    primary_gloss = dictionary_gloss(gloss)
    regional_variants = candidate.get("regionalVariants") or None
    tags = [
        "frequency",
        part_of_speech,
        "wiktionary",
        "auto-generated",
        f"source-rank-{candidate['frequencyRank']}",
    ]
    if example_source["name"] == "Tatoeba":
        tags.append("tatoeba")
    if regional_variants:
        tags.extend(["vestland", "spoken-dialect"])

    word = {
        "id": candidate["candidateID"],
        "rank": 0,
        "teachingPriority": 0,
        "frequencyBand": "core-500",
        "contentVersion": 5,
        "level": "A1",
        "lemma": candidate["lemma"],
        "displayForm": display_form(candidate["lemma"], part_of_speech, gender),
        "partOfSpeech": part_of_speech,
        "englishDefinition": primary_gloss,
        "norwegianDefinition": None,
        "gender": gender,
        "inflections": inflections_for(entry, candidate["lemma"]),
        "exampleNorwegian": norwegian_example,
        "exampleEnglish": english_example,
        "alternateMeanings": alternate_meanings(entry, primary_gloss),
        "regionalVariants": regional_variants,
        "tags": tags,
    }
    evidence_record = {
        "id": candidate["candidateID"],
        "lemma": candidate["lemma"],
        "sourceFrequencyRank": candidate["frequencyRank"],
        "partOfSpeechEvidence": candidate["partOfSpeechEvidence"],
        "wiktionaryPartOfSpeech": entry.get("pos"),
        "primaryGloss": primary_gloss,
        "exampleSource": example_source,
        "wiktionaryEntry": f"https://en.wiktionary.org/wiki/{quote(candidate['lemma'])}",
    }
    return word, evidence_record


def main() -> int:
    args = parse_args()
    if args.target_count < 1:
        raise SystemExit("--target-count must be positive")

    source_metadata = json.loads(args.source_metadata.read_text(encoding="utf-8"))
    tatoeba_metadata = json.loads(args.tatoeba_metadata.read_text(encoding="utf-8"))
    actual_sha = file_sha256(args.wiktionary)
    if actual_sha != source_metadata["sha256"]:
        raise SystemExit(
            "Wiktionary source checksum mismatch. Run Scripts/fetch_wiktionary_lexicon.sh "
            "or audit and update the pinned source metadata."
        )

    candidate_document = json.loads(args.candidates.read_text(encoding="utf-8"))
    candidates = sorted(
        candidate_document["candidates"], key=lambda item: (item["frequencyRank"], item["lemma"])
    )
    current_words = json.loads(args.words.read_text(encoding="utf-8"))
    curated_words = [word for word in current_words if "auto-generated" not in word.get("tags", [])]
    if len(curated_words) > args.target_count:
        raise SystemExit("The target is smaller than the curated catalog.")

    wanted = {normalized(candidate["lemma"]) for candidate in candidates}
    wiktionary_entries = load_wiktionary(args.wiktionary, wanted)
    tatoeba_index = load_tatoeba_index(args.tatoeba_directory, tatoeba_metadata)

    selected: list[dict[str, Any]] = []
    evidence_records: list[dict[str, Any]] = []
    used_candidates: set[str] = set()
    curated_ids = {word["id"] for word in curated_words}
    curated_lemmas = {normalized(word["lemma"]) for word in curated_words}
    used_tatoeba_ids: set[int] = set()

    for word in curated_words:
        candidate = candidate_for_curated(word, candidates)
        source_rank = candidate["frequencyRank"] if candidate else word["rank"]
        if candidate:
            used_candidates.add(candidate["candidateID"])
        refreshed_word = dict(word)
        refreshed_word["contentVersion"] = 5
        selected.append({"word": refreshed_word, "sourceRank": source_rank, "curated": True})

    for candidate in candidates:
        if len(selected) >= args.target_count:
            break
        if candidate["candidateID"] in used_candidates:
            continue
        if candidate["candidateID"] in curated_ids or normalized(candidate["lemma"]) in curated_lemmas:
            continue
        evidence = choose_lexical_evidence(
            candidate, wiktionary_entries.get(normalized(candidate["lemma"]), [])
        )
        if evidence is None:
            continue
        built = build_generated_word(
            candidate,
            evidence,
            tatoeba_index,
            used_tatoeba_ids,
        )
        if built is None:
            continue
        word, evidence_record = built
        selected.append(
            {"word": word, "sourceRank": candidate["frequencyRank"], "curated": False}
        )
        evidence_records.append(evidence_record)
        used_candidates.add(candidate["candidateID"])

    if len(selected) < args.target_count:
        raise SystemExit(
            f"Only {len(selected)} usable words were found; target is {args.target_count}."
        )

    by_frequency = sorted(selected, key=lambda item: (item["sourceRank"], item["word"]["lemma"]))
    for rank, item in enumerate(by_frequency, start=1):
        word = item["word"]
        word["rank"] = rank
        word["frequencyBand"] = frequency_band(rank)
        if not item["curated"]:
            word["level"] = cefr_level(rank)
            word["tags"] = [word["level"], *word["tags"]]

    highest_curated_priority = max(
        (item["word"]["teachingPriority"] for item in selected if item["curated"]), default=0
    )
    generated_by_frequency = sorted(
        (item for item in selected if not item["curated"]),
        key=lambda item: (item["sourceRank"], item["word"]["lemma"]),
    )
    for offset, item in enumerate(generated_by_frequency, start=1):
        item["word"]["teachingPriority"] = highest_curated_priority + offset

    output_words = [
        item["word"] for item in sorted(selected, key=lambda item: item["word"]["teachingPriority"])
    ]
    if len({word["id"] for word in output_words}) != len(output_words):
        raise SystemExit("Generated catalog contains duplicate IDs.")
    if len({word["rank"] for word in output_words}) != len(output_words):
        raise SystemExit("Generated catalog contains duplicate ranks.")

    manifest = json.loads(args.manifest.read_text(encoding="utf-8"))
    manifest["contentVersion"] = "2026.07.5-dictionary-examples"
    word_pack = next(pack for pack in manifest["packs"] if pack["kind"] == "word")
    word_pack.update(
        {
            "id": "daily-norsk-words-1500",
            "version": 5,
            "itemCount": len(output_words),
            "minimumFrequencyRank": 1,
            "maximumFrequencyRank": len(output_words),
        }
    )

    args.words.write_text(
        json.dumps(output_words, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    args.manifest.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    args.evidence_output.parent.mkdir(parents=True, exist_ok=True)
    args.evidence_output.write_text(
        json.dumps(
            {
                "metadata": {
                    "schemaVersion": 2,
                    "targetCount": args.target_count,
                    "curatedCount": len(curated_words),
                    "generatedCount": len(output_words) - len(curated_words),
                    "candidateMetadata": candidate_document["metadata"],
                    "wiktionarySource": source_metadata,
                    "tatoebaSource": tatoeba_metadata,
                    "exampleSourceCounts": dict(
                        sorted(
                            Counter(
                                record["exampleSource"]["name"]
                                for record in evidence_records
                            ).items()
                        )
                    ),
                },
                "entries": evidence_records,
            },
            ensure_ascii=False,
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )

    print(
        f"Built {len(output_words)} words: {len(curated_words)} curated and "
        f"{len(output_words) - len(curated_words)} licensed/generated expansions."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
