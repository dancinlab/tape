# Reference algorithms — `.tape` toolchain

17 hexa-lang modules covering the operational surface of `.tape` v1.1 — guarded append, bootstrap, replay, typed filter, health audit, streaming compaction, time-axis indexing, dedup detection, KV-cache invariance probe, JSONL adapter, the two promotion-adapter stubs (n6 / hxc), the four v1.1 placement-bridge modules (identity projection, domain `## Log` renderer, meta-domain verifier, domain status matrix), and the v1.1 P1 whole-tape markdown adapter.

## Provenance

Written in [hexa-lang](https://github.com/dancinlab/hexa-fusion) — require the hexa-lang interpreter (`~/.hx/bin/hexa`) to execute. The mirror lineage is n6's `atlas_*.hexa` modules and hxc's `hxc_a*.hexa` codec modules; the `.tape` toolchain is the same calibre at v1 (selftest-gated, hexa-RULES-compliant, byte-canonical-preserving).

## Catalog

| Module | Role |
|---|---|
| `tape_absorb.hexa` | Guarded ingestion — schema check + dangling-edge check + idempotency check + append. The one entry point for any byte landing in a `.tape` file. |
| `tape_bootstrap.hexa` | Initialise a fresh tape with shebang + box-divider header + `@S start <sid>` line. Idempotent (refuses to overwrite). |
| `tape_replay.hexa` | Reconstruct `[Message]` from a tape for agent-loop resume. `@U` → role=user, `@A` → role=assistant, `@R` → role=tool; skips operational events. |
| `tape_grep.hexa` | Typed filter: `--type=T` / `--domain=tool` / `--grade=denied` — replaces ad-hoc `grep '^@T '` with a type-alphabet-aware reader. |
| `tape_health.hexa` | End-to-end audit: per-type histogram, dangling-edge count, total events. Mirrors n6 atlas_health.hexa. |
| `tape_compact.hexa` | Fold consecutive streaming-delta `@A` rows sharing the same id into one block. |
| `tape_index.hexa` | Build a `(turn, N, byte_offset, line_offset)` seek index for fast resume. |
| `tape_dedup.hexa` | Detect duplicate `(type, id)` headers — violation of `tape_absorb`'s idempotency rule. |
| `tape_kv_probe.hexa` | Verify byte-canonical prefix invariance — the KV-cache-stability check. |
| `tape_export_jsonl.hexa` | Bidirectional `.tape` ↔ wilson `.jsonl` adapter (transcript / recap / cost / task). |
| `tape_to_n6.hexa` | Promotion-adapter scaffold: `.tape` `@R [ok]` → n6 verified atom (PASS-2 grade assignment pending). |
| `tape_to_hxc.hexa` | Promotion-adapter scaffold: wrap a `.tape` in HXC v2 byte-canonical wire for cross-host ship (PASS-2 delegation to `hxc_composite_chain` pending). |
| `tape_render_identity.hexa` (v1.1) | Read `~/.wilson/identity.tape` and render the canonical `## Identity` system-prompt block — slot #1 of wilson's session_start fold. Walks `@I` events, keeps latest-per-subkind, folds into a numbered block. |
| `tape_to_md_log.hexa` (v1.1) | Render the `<!-- AUTO-RENDER -->` fence inside the `## Log` section of `<DOMAIN>.md` from the tail of `<DOMAIN>.tape`. Idempotent. Closes governance #4's `## Log` author-discipline gap. |
| `tape_meta_verify.hexa` (v1.1) | Walk a meta-domain `<D1+D2+D3>.md` head section for typed `@D` Cn/Mm condition lines, cross-reference each against the sibling `.tape` for evidence, emit a held/violated matrix. |
| `tape_domain_status.hexa` (v1.1) | Scan a directory for `<UPPERCASE>(+<UPPERCASE>)*.md` files (governance #4 pattern), summarise each via its sibling `.tape`, print a one-screen domain-status matrix. Companion to `wilson domain list`. |
| `tape_to_md.hexa` (v1.1 P1) | Project a whole `.tape` to markdown — `#` preamble → quote, `# ── X ────` → H2, `@D` → bullets, `@A` → `## Log` H3 entries with date + body. Generalisation of `tape_to_md_log` (which only rewrites the AUTO-RENDER fence). Enables `.tape`-as-SSOT with `.md` as auto-rendered view (TAPE.md adoption path P1). |

## Usage shape

```bash
hexa algorithms/tape_absorb.hexa --selftest
hexa algorithms/tape_bootstrap.hexa /tmp/s_test.tape s001
hexa algorithms/tape_replay.hexa s001.tape
hexa algorithms/tape_grep.hexa s001.tape --type=T --grade=denied
hexa algorithms/tape_health.hexa s001.tape
hexa algorithms/tape_compact.hexa s001.tape s001-compact.tape
hexa algorithms/tape_kv_probe.hexa s001.tape
hexa algorithms/tape_export_jsonl.hexa export transcript s001.tape transcript.jsonl
hexa algorithms/tape_render_identity.hexa ~/.wilson/identity.tape
hexa algorithms/tape_to_md_log.hexa HARNESS.md HARNESS.tape 20
hexa algorithms/tape_meta_verify.hexa HARNESS+TOOL+PROVIDER.md HARNESS+TOOL+PROVIDER.tape
hexa algorithms/tape_domain_status.hexa ~/core/wilson
hexa algorithms/tape_to_md.hexa <tape.in> <md.out>
```

Every module ships a `--selftest` flag returning exit 0 on pass.

## Convention

Each module:

- Top-of-file `// @module(slug=..., desc=...)` + one or more `// @usage(...)` + `// @exit_codes(...)`
- One `fn _selftest() -> i64` with at least one round-trip fixture
- Module-level `let _rc = _selftest() ; if _rc != 0 { exit(1) } else { println("OK") } ; exit(0)`
- Strict hexa-lang RULES compliance: no `>=` / `<=` operators, no bare `exec`, no silent catch
- Pure hexa file I/O (`read_file` / `write_file` / `file_exists`) — no fork, no shell-out

## Porting notes

The append path (`tape_absorb`) is the safety-critical surface — schema validation + dangling-edge check + idempotency. Any non-hexa implementation must preserve the byte-canonical append semantics described in [`../spec/tape.md` §Streaming invariants](../spec/tape.md#streaming-invariants) and the 4-step validation pipeline in [`../spec/tape.md` §Validation pipeline](../spec/tape.md#validation-pipeline).

The promotion adapters (`tape_to_n6`, `tape_to_hxc`) ship as PASS-1 scaffolds; PASS-2 work is tracked in `docs/DESIGN.md §Open-questions`.
