# Norwegian content pipeline

This pipeline produces both editorial reports and the reproducible 1,500-word shipping lexicon. The shipping step preserves hand-curated lessons, promotes only entries with usable licensed gloss evidence, assigns stable IDs, and records provenance. Automated entries remain clearly tagged for continued fluent-speaker review.

## Reproduce the candidate reports

Initialize the pinned source repositories:

```sh
git submodule update --init --recursive
```

Create the disposable Python environment and install the pinned `wordfreq` checkout plus its runtime dependencies:

```sh
Scripts/bootstrap_content_pipeline.sh
```

Build all reports:

```sh
Scripts/run_content_pipeline.sh
```

Fetch the checksum-pinned Norwegian Bokmål dictionary extraction and the linked Tatoeba Norwegian Bokmål–English examples, then build the shipping lexicon:

```sh
Scripts/fetch_wiktionary_lexicon.sh
Scripts/fetch_tatoeba_examples.sh
Scripts/expand_lexicon.py
Scripts/validate_content.py
```

The rolling Kaikki and Tatoeba exports are deliberately pinned by SHA-256 in `Config/wiktionary-source.json` and `Config/tatoeba-source.json`. If upstream changes, the fetch command stops until the new export, license, and output are audited. The large source files are ignored by Git; the fetch metadata and generator are versioned. Git-based references remain submodules with their upstream URLs intact.

Generated reports are written under `ContentPipeline/Generated/` and intentionally ignored by Git. Each report records source commit hashes and configuration so it can be reproduced. Editorial overrides in `Config/editorial-overrides.json` are versioned.

## Outputs

- `word-candidates.json`: merged frequency, lemma, part-of-speech, gender, teaching-band evidence, and versioned Vestland/Bergen review suggestions.
- `word-exclusions.json`: rejected raw tokens and explicit reasons.
- `phrase-candidates.json`: recurring 2–5 token sequences for human phrase review.
- `pipeline-summary.json`: counts, revisions, and coverage diagnostics.
- `shipping-lexicon-evidence.json`: per-entry source rank, gloss, part-of-speech, source link, and example provenance. Tatoeba records retain both sentence IDs and contributor names for attribution and future audits.

Phrase candidates are corpus sequences, not automatically valid phrases. Reviewers must reject accidental adjacency, incomplete syntax, names, corpus-specific language, unnatural translations, and low-value fragments.

## Promotion checklist

Before promoting a word or phrase into the app:

1. Confirm the lemma, sense, part of speech, and standard Bokmål spelling.
2. Write original learner-facing definitions, translations, examples, and usage notes, or retain the required attribution and ShareAlike terms for licensed adaptations.
3. Preserve source frequency as evidence and assign teaching priority separately.
4. Link phrases to existing focus/component word IDs.
5. Add attribution or share-alike handling when a redistributed field requires it.
6. For regional forms, record the location, label the form as speech, and have a fluent speaker from the stated area check naturalness and current usage.
7. Keep standard Bokmål/Nynorsk forms distinguishable from unstandardized dialect spellings.
8. Have a fluent Norwegian editor approve the complete content entry.
9. Run `Scripts/validate_content.py` and the Xcode tests.
