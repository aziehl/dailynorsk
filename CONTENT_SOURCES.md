# Content sources and licensing ledger

The 32 curated words and 42 phrases were written specifically for this project. The expanded lexical entries adapt licensed English Wiktionary fields, Tatoeba Norwegian Bokmål–English example pairs, frequency evidence, and morphology/POS evidence as recorded below; required attribution and license notices are included in-app and in `THIRD_PARTY_NOTICES.md`. Regional forms remain labeled representations of speech because dialect spelling is not standardized.

## Rules for adding source material

1. Record the source, exact version or retrieval date, URL, license, fields used, and whether redistribution is permitted.
2. Keep corpus frequency evidence separate from app-facing definitions and examples.
3. Write original learner-facing definitions and examples unless a source license and attribution plan explicitly permit reuse.
4. Never assume an open-source API implementation grants redistribution rights to the dictionary or corpus content it serves.
5. Add any fetched open-source repository under `References/` as a Git submodule. Do not copy or flatten its checkout into this repository.
6. Pin the submodule revision used for a generated content-pack release and record it below.

## Source ledger

| Source | Revision/date | License | Purpose | Redistributed fields | Notes |
|---|---|---|---|---|---|
| Project-authored demo content | 2026-07-16 | All rights reserved under the root `LICENSE` | Exercise app schemas and UI | All demo fields | Requires Norwegian editorial review and publisher ownership confirmation before release |
| `rspeer/wordfreq` | `912caf64b657478d1dff1138efdc078947d54bb1` | Apache-2.0 code; included data CC BY-SA 4.0 with additional attribution notes in upstream `NOTICE.md` | Frequency candidate evidence for `nb` | Frequency ordering and source-rank provenance in generated entries | Pinned at `References/wordfreq`; attribution and ShareAlike handling retained |
| Universal Dependencies Norwegian Bokmål | `396d11f0c2bd290a2a2711015c04ac25bc3dcc06` | CC BY-SA 4.0 | Lemma, morphology, POS, and phrase-candidate evidence | Lemma/POS selection in generated entries | Pinned at `References/ud-norwegian-bokmaal`; treebank genres are news, blog, and nonfiction and do not represent conversation alone |
| English Wiktionary Norwegian Bokmål entries via Kaikki.org | Wiktionary dump 2026-07-06; extraction 2026-07-09; SHA-256 `53812cdf115ef0a2b8f4a3bcbe7c814912adc94db868c9f146fbe0556db1aeb9` | CC BY-SA 4.0 | English glosses, inflections, selected contributor examples | Adapted lexical fields in generated entries of `words.json` | Source and modifications are attributed in-app and in `THIRD_PARTY_NOTICES.md`; checksum-pinned fetch metadata is versioned in `ContentPipeline/Config/wiktionary-source.json` |
| Tatoeba Norwegian Bokmål–English sentence pairs | export 2026-07-11; `nob` SHA-256 `a8b511a555055423e1ac36a5d5867f2dd921fc11c679a3df428b682115a06c1e`; `eng` SHA-256 `86dfa17528230f4bacd5d51108d0126548ad56f984dab4ad11262d8327ba7e6f`; links SHA-256 `b90493c605377dc0a1d4a6dae14e82a87ba050f2bf6feda881fd95c52637b786` | CC BY 2.0 France | Real translated examples for generated word entries | Norwegian and English example text | Sentence IDs and contributor names are retained in `shipping-lexicon-evidence.json`; source metadata and checksum-pinned fetcher are versioned in `ContentPipeline/Config/tatoeba-source.json` and `Scripts/fetch_tatoeba_examples.sh` |
| [Store norske leksikon, “Bergen bymål”](https://snl.no/Bergen_bym%C3%A5l) | accessed 2026-07-17 | SNL site terms; article facts used as editorial evidence | Verify Bergen question-word forms and dialect variation | None copied | Supports `ka`, `kor`, `koffår`, `kossen`, and `kordan`; project-authored wording and examples only |
| [Store norske leksikon, “dialekter på Karmøy”](https://snl.no/dialekter_p%C3%A5_Karm%C3%B8y) | accessed 2026-07-17 | SNL site terms; article facts used as editorial evidence | Cross-check broader western variation | None copied | Supports regional variation including `ka`, `koffårr`, `koss`, and `kossen` |
| Product-owner direction | 2026-07-17 | Project-authored | Select `koffer` as a learner-facing Bergen spelling preference | `koffer` form only | Also show `koffor` and `koffår` and explain that dialect spelling varies |
| [Store norske leksikon, “gå mann”](https://snl.no/g%C3%A5_mann) | accessed 2026-07-17 | SNL site terms; article facts used as editorial evidence | Verify region, function, and register of the Bergen/Hordaland exclamation | None copied | Learner definition, translation, note, and example are project-authored |
| [Bokmålsordboka, `tjommi`](https://ordbokene.no/bm/tjommi) | accessed 2026-07-17 | Dictionary consulted as editorial evidence | Cross-check a common colloquial friendship term for future lessons | None copied | Not yet shipped because the current frequency-band schema ends at rank 2,500 |
| [Bokmålsordboka, `konge`](https://ordbokene.no/bm/konge) and [`gå på trynet`](https://ordbokene.no/bm/g%C3%A5%20p%C3%A5%20trynet) | accessed 2026-07-17 | Dictionary consulted as editorial evidence | Verify informal adjectival and idiomatic senses | None copied | All learner-facing wording and examples are project-authored |
| [Bokmålsordboka, `aldri`](https://ordbokene.no/bm/aldri), [`borte`](https://ordbokene.no/bm/borte), and [`eple`](https://ordbokene.no/bm/eple) | accessed 2026-07-17 | Dictionary consulted as editorial evidence | Verify recorded fixed sayings and intended senses | None copied | Covers “bedre sent enn aldri”, “aldri så galt …”, “borte bra …”, and “eplet faller …” |
| [Bokmålsordboka, `le`](https://ordbokene.no/bm/le), [`å`](https://ordbokene.no/bm/%C3%A5), [`øvelse`](https://ordbokene.no/bm/%C3%B8velse), and [`morgenstund har gull i munn`](https://ordbokene.no/bm/123136) | accessed 2026-07-17 | Dictionary consulted as editorial evidence | Verify additional traditional expressions and meanings | None copied | Covers “den som ler sist …”, “mange bekker små …”, “øvelse gjør mester”, and “morgenstund …” |

## Planned reference layout

```text
References/
  wordfreq/                # Git submodule
  ud-norwegian-bokmaal/    # Git submodule
```

When a reference is added, initialize it after cloning with:

```sh
git submodule update --init --recursive
```
