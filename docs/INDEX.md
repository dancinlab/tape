# tape documentation index

## Format

- [`spec/tape.md`](../spec/tape.md) — canonical v1.1 grammar (entry header, type alphabet, grade markers, edge operators, streaming invariants, validation pipeline, placement matrix, identity / domain-tape / meta-domain conventions, sibling cross-format)

## Examples

- [`examples/01_basic_session.tape`](../examples/01_basic_session.tape) — minimal session: start / user / assistant / tool / decision / result / cost / end
- [`examples/02_tool_chain.tape`](../examples/02_tool_chain.tape) — multi-tool fan-out with multi-id `<-` aggregation
- [`examples/03_governance_deny.tape`](../examples/03_governance_deny.tape) — governance block + `!!` abort edge + `[denied]` grade
- [`examples/04_resume_replay.tape`](../examples/04_resume_replay.tape) — `@S resume == s001` continuation pattern + `tape_replay` semantics
- [`examples/05_identity.tape`](../examples/05_identity.tape) (v1.1) — `~/.wilson/identity.tape` SSOT — six `@I` events (birth/scope/origin/principle/version)
- [`examples/06_domain_log.tape`](../examples/06_domain_log.tape) (v1.1) — `HARNESS.tape` per-domain history; renders into `## Log` AUTO-RENDER fence via `tape_to_md_log`
- [`examples/07_meta_domain.tape`](../examples/07_meta_domain.tape) (v1.1) — `HARNESS+TOOL+PROVIDER.tape` meta-domain joint condition; verified by `tape_meta_verify`

## Algorithms

- [`algorithms/`](../algorithms/) — 16 reference hexa-lang modules. v1 (12): guarded append, bootstrap, replay, grep, health, compaction, indexing, dedup, KV-cache probe, JSONL adapter, n6 / hxc promotion stubs. v1.1 (+4): `tape_render_identity`, `tape_to_md_log`, `tape_meta_verify`, `tape_domain_status`.
- [`algorithms/README.md`](../algorithms/README.md) — module catalog + usage shape

## Tools

- [`tool/`](../tool/) — planned lint / replay / grade-audit / cross-format-promotion CLIs (not yet implemented)

## Editor support

- [`syntaxes/tape.tmLanguage.json`](../syntaxes/tape.tmLanguage.json) — TextMate grammar
- [`syntaxes/README.md`](../syntaxes/README.md) — VS Code / Sublime / TextMate install guides

## Design notes

- [`docs/DESIGN.md`](DESIGN.md) — why a 4th sibling · why typed events not raw JSONL · why provenance edges · promotion-target sibling pattern

## CI

- [`.github/workflows/lint.yml`](../.github/workflows/lint.yml) — byte-canonical invariants + entry-header well-formedness checks on `examples/*.tape`

## Sibling formats

- [`n6`](https://github.com/dancinlab/n6) — semantic / atlas layer (typed verified atoms · grade ladder · `*` / `!` / `?` markers)
- [`hxc`](https://github.com/dancinlab/hxc) — byte-canonical wire (HXC v2 · KV-cache stable · cross-host ship)
- `n12` — 12-axis sparse cube (multidimensional metric layer; private at `dancinlab/n12`)
