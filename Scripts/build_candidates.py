#!/usr/bin/env python3
"""Merge wordfreq ranks with UD Bokmål lemma and morphology evidence."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
import unicodedata
import uuid
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any, Iterable


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_UD = ROOT / "References" / "ud-norwegian-bokmaal"
DEFAULT_WORDFREQ = ROOT / "References" / "wordfreq"
DEFAULT_CONFIG = ROOT / "ContentPipeline" / "Config" / "editorial-overrides.json"
DEFAULT_OUTPUT = ROOT / "ContentPipeline" / "Generated"
LEXICAL_POS = {"NOUN", "VERB", "ADJ", "ADV"}
FUNCTION_POS = {"ADP", "AUX", "CCONJ", "SCONJ", "DET", "PART", "PRON", "NUM", "INTJ"}
ID_NAMESPACE = uuid.UUID("ab40f62a-9df9-5e48-bd0d-fd13d731c701")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--limit", type=int, default=5_000)
    parser.add_argument("--ud", type=Path, default=DEFAULT_UD)
    parser.add_argument("--wordfreq", type=Path, default=DEFAULT_WORDFREQ)
    parser.add_argument("--config", type=Path, default=DEFAULT_CONFIG)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    return parser.parse_args()


def git_revision(path: Path) -> str:
    try:
        return subprocess.check_output(
            ["git", "-C", str(path), "rev-parse", "HEAD"], text=True, stderr=subprocess.DEVNULL
        ).strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return "unavailable"


def normalized(value: str) -> str:
    return unicodedata.normalize("NFC", value.strip().lower())


def iter_conllu(paths: Iterable[Path]) -> Iterable[tuple[str, str, str, dict[str, str]]]:
    for path in paths:
        for line in path.read_text(encoding="utf-8").splitlines():
            if not line or line.startswith("#"):
                continue
            columns = line.split("\t")
            if len(columns) != 10 or "-" in columns[0] or "." in columns[0]:
                continue
            form, lemma, upos, features = columns[1], columns[2], columns[3], columns[5]
            parsed_features = {}
            if features != "_":
                parsed_features = dict(
                    item.split("=", 1) for item in features.split("|") if "=" in item
                )
            yield normalized(form), normalized(lemma), upos, parsed_features


def load_ud_evidence(directory: Path) -> dict[str, Any]:
    files = sorted(directory.glob("*.conllu"))
    if not files:
        raise SystemExit(f"No .conllu files found under {directory}")

    form_lemmas: dict[str, Counter[str]] = defaultdict(Counter)
    lemma_pos: dict[str, Counter[str]] = defaultdict(Counter)
    lemma_forms: dict[str, Counter[str]] = defaultdict(Counter)
    lemma_genders: dict[str, Counter[str]] = defaultdict(Counter)
    lemma_counts: Counter[str] = Counter()

    for form, lemma, upos, features in iter_conllu(files):
        if lemma in {"_", "$"}:
            continue
        form_lemmas[form][lemma] += 1
        lemma_pos[lemma][upos] += 1
        lemma_forms[lemma][form] += 1
        lemma_counts[lemma] += 1
        if gender := features.get("Gender"):
            lemma_genders[lemma][gender] += 1

    return {
        "form_lemmas": form_lemmas,
        "lemma_pos": lemma_pos,
        "lemma_forms": lemma_forms,
        "lemma_genders": lemma_genders,
        "lemma_counts": lemma_counts,
        "tokenCount": sum(lemma_counts.values()),
    }


def load_frequency_tokens(wordfreq_path: Path, limit: int) -> list[str]:
    sys.path.insert(0, str(wordfreq_path))
    try:
        from wordfreq import top_n_list  # type: ignore
    except ImportError as error:
        raise SystemExit(
            "wordfreq dependencies are unavailable. Run Scripts/bootstrap_content_pipeline.sh first. "
            f"Original error: {error}"
        ) from error
    return [normalized(token) for token in top_n_list("nb", limit, wordlist="best")]


def frequency_band(rank: int) -> str | None:
    if rank <= 500:
        return "core-500"
    if rank <= 1_000:
        return "rank-501-1000"
    if rank <= 1_500:
        return "rank-1001-1500"
    if rank <= 2_000:
        return "rank-1501-2000"
    if rank <= 2_500:
        return "rank-2001-2500"
    return None


def main() -> int:
    args = parse_args()
    config = json.loads(args.config.read_text(encoding="utf-8"))
    evidence = load_ud_evidence(args.ud)
    tokens = load_frequency_tokens(args.wordfreq, args.limit)
    excluded_config = config["excludedTokens"]
    lemma_overrides = config["lemmaOverrides"]
    forced_pos = config["forcedPartOfSpeech"]
    regional_variants = config.get("regionalVariants", {})
    essential = set(config["essentialFunctionWords"])

    candidates_by_lemma: dict[str, dict[str, Any]] = {}
    exclusions: list[dict[str, Any]] = []

    for rank, token in enumerate(tokens, start=1):
        reason = excluded_config.get(token)
        if reason:
            exclusions.append({"token": token, "frequencyRank": rank, "reason": reason})
            continue
        if not token or not all(character.isalpha() or character in "-'" for character in token):
            exclusions.append({"token": token, "frequencyRank": rank, "reason": "non-lexical characters"})
            continue

        observed_lemmas: Counter[str] = evidence["form_lemmas"].get(token, Counter())
        lemma = lemma_overrides.get(token) or (observed_lemmas.most_common(1)[0][0] if observed_lemmas else token)
        pos_counts: Counter[str] = evidence["lemma_pos"].get(lemma, Counter())
        part_of_speech = forced_pos.get(lemma) or (pos_counts.most_common(1)[0][0] if pos_counts else "UNKNOWN")
        is_lexical = part_of_speech in LEXICAL_POS
        is_essential_function = lemma in essential and part_of_speech in FUNCTION_POS | {"UNKNOWN"}
        if part_of_speech == "PROPN":
            exclusions.append({"token": token, "frequencyRank": rank, "lemma": lemma, "reason": "proper name"})
            continue

        entry = candidates_by_lemma.get(lemma)
        if entry is None:
            genders = evidence["lemma_genders"].get(lemma, Counter())
            entry = {
                "candidateID": str(uuid.uuid5(ID_NAMESPACE, f"nb-word:{lemma}")).upper(),
                "lemma": lemma,
                "frequencyRank": rank,
                "frequencyBand": frequency_band(rank),
                "partOfSpeechEvidence": part_of_speech,
                "isLexical": is_lexical,
                "isEssentialFunctionWord": is_essential_function,
                "treebankOccurrences": evidence["lemma_counts"].get(lemma, 0),
                "genderEvidence": genders.most_common(1)[0][0] if genders else None,
                "observedForms": [form for form, _ in evidence["lemma_forms"].get(lemma, Counter()).most_common(12)],
                "regionalVariants": regional_variants.get(lemma, []),
                "sourceTokens": [],
                "reviewFlags": [],
                "editorialStatus": "candidate",
            }
            if part_of_speech == "UNKNOWN":
                entry["reviewFlags"].append("missing-treebank-analysis")
            if entry["regionalVariants"]:
                entry["reviewFlags"].append("regional-variants-require-local-review")
            if not is_lexical and not is_essential_function:
                entry["reviewFlags"].append("non-lexical-review")
            candidates_by_lemma[lemma] = entry
        entry["sourceTokens"].append({"token": token, "rank": rank})

    candidates = sorted(candidates_by_lemma.values(), key=lambda item: (item["frequencyRank"], item["lemma"]))
    args.output.mkdir(parents=True, exist_ok=True)
    metadata = {
        "schemaVersion": 1,
        "language": "nb-NO",
        "wordfreqRevision": git_revision(args.wordfreq),
        "udNorwegianBokmaalRevision": git_revision(args.ud),
        "rawFrequencyLimit": args.limit,
        "treebankTokenCount": evidence["tokenCount"],
        "config": str(args.config.relative_to(ROOT)),
    }
    (args.output / "word-candidates.json").write_text(
        json.dumps({"metadata": metadata, "candidates": candidates}, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    (args.output / "word-exclusions.json").write_text(
        json.dumps({"metadata": metadata, "exclusions": exclusions}, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    summary = {
        **metadata,
        "rawTokens": len(tokens),
        "candidateLemmas": len(candidates),
        "lexicalCandidatesThrough2500": sum(
            1 for item in candidates if item["frequencyRank"] <= 2_500 and item["isLexical"]
        ),
        "explicitOrAutomaticExclusions": len(exclusions),
        "candidatesByBand": dict(Counter(item["frequencyBand"] or "after-2500" for item in candidates)),
        "candidatesByPartOfSpeech": dict(Counter(item["partOfSpeechEvidence"] for item in candidates)),
        "candidatesWithRegionalVariants": sum(1 for item in candidates if item["regionalVariants"]),
    }
    (args.output / "pipeline-summary.json").write_text(
        json.dumps(summary, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    print(
        f"Generated {len(candidates)} lemma candidates from {len(tokens)} frequency tokens; "
        f"{len(exclusions)} tokens excluded."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
