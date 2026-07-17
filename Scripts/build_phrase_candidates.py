#!/usr/bin/env python3
"""Extract recurring Bokmål n-grams as phrase-review candidates."""

from __future__ import annotations

import argparse
import json
import subprocess
import unicodedata
import uuid
from collections import Counter, defaultdict
from pathlib import Path
from typing import Iterable


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_UD = ROOT / "References" / "ud-norwegian-bokmaal"
DEFAULT_OUTPUT = ROOT / "ContentPipeline" / "Generated"
ID_NAMESPACE = uuid.UUID("492084cc-8d6c-5df8-a2f4-391c627ea4f4")
LEXICAL_POS = {"NOUN", "VERB", "ADJ", "ADV"}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--ud", type=Path, default=DEFAULT_UD)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--minimum-count", type=int, default=4)
    parser.add_argument("--limit", type=int, default=2_000)
    return parser.parse_args()


def git_revision(path: Path) -> str:
    return subprocess.check_output(["git", "-C", str(path), "rev-parse", "HEAD"], text=True).strip()


def normalize(value: str) -> str:
    return unicodedata.normalize("NFC", value.lower().strip())


def sentences(paths: Iterable[Path]) -> Iterable[list[tuple[str, str, str]]]:
    current: list[tuple[str, str, str]] = []
    for path in paths:
        for line in path.read_text(encoding="utf-8").splitlines() + [""]:
            if not line:
                if current:
                    yield current
                    current = []
                continue
            if line.startswith("#"):
                continue
            columns = line.split("\t")
            if len(columns) != 10 or "-" in columns[0] or "." in columns[0]:
                continue
            if columns[3] == "PUNCT":
                continue
            current.append((normalize(columns[1]), normalize(columns[2]), columns[3]))


def main() -> int:
    args = parse_args()
    files = sorted(args.ud.glob("*.conllu"))
    if not files:
        raise SystemExit(f"No .conllu files found under {args.ud}")

    counts: Counter[tuple[str, ...]] = Counter()
    examples: dict[tuple[str, ...], Counter[str]] = defaultdict(Counter)
    patterns: dict[tuple[str, ...], Counter[str]] = defaultdict(Counter)

    for sentence in sentences(files):
        for size in range(2, 6):
            for start in range(0, len(sentence) - size + 1):
                window = sentence[start : start + size]
                if not any(pos in LEXICAL_POS for _, _, pos in window):
                    continue
                forms = tuple(form for form, _, _ in window)
                if any(not token or not all(character.isalpha() or character in "-'" for character in token) for token in forms):
                    continue
                counts[forms] += 1
                examples[forms][" ".join(forms)] += 1
                patterns[forms][" ".join(pos for _, _, pos in window)] += 1

    ranked = []
    for forms, count in counts.most_common():
        if count < args.minimum_count:
            break
        text = " ".join(forms)
        ranked.append(
            {
                "candidateID": str(uuid.uuid5(ID_NAMESPACE, f"nb-phrase:{text}")).upper(),
                "norwegian": text,
                "corpusCount": count,
                "partOfSpeechPattern": patterns[forms].most_common(1)[0][0],
                "reviewStatus": "candidate",
                "reviewFlags": ["corpus-ngram-not-yet-validated-as-phrase"],
            }
        )
        if len(ranked) >= args.limit:
            break

    args.output.mkdir(parents=True, exist_ok=True)
    payload = {
        "metadata": {
            "schemaVersion": 1,
            "language": "nb-NO",
            "udNorwegianBokmaalRevision": git_revision(args.ud),
            "minimumCorpusCount": args.minimum_count,
            "warning": "Candidates require fluent-speaker review and are not shipping phrases.",
        },
        "candidates": ranked,
    }
    (args.output / "phrase-candidates.json").write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"Generated {len(ranked)} phrase-review candidates.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
