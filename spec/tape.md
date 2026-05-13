# Agent-Execution Trace — `.tape` format v1.1 (spec, 2026-05-13)

> Standalone mirror. Provenance: extracted from wilson harness-cli runtime instrumentation discussion (2026-05-13), patched with identity + domain-tape integration (v1.1, same day). Wilson today scatters runtime state across five `.jsonl` surfaces (transcript, recap, recap-index, cost ledger, task list) AND carries identity as a hard-coded 1-line block AND tracks per-domain history via author-discipline-only `## Log` sections; `.tape` is the typed grammar that collapses runtime, identity, and domain history into one append-only causal trace across 5 placements. Path references to wilson plugin ids are provenance markers; the grammar itself is self-contained and fully described below.

Append-only, line-oriented, human-readable, grep-friendly agent-execution trace grammar. Each entry is a typed event — runtime (session, user, assistant, tool call, tool result, hook fire, governance decision, cost sample, provider event, anomaly) OR foundational identity claim — carrying provenance edges (caused_by / triggers / produces / continues / supersedes / verified_by / aborts) and a delivery-state grade.

Fourth sibling of [`n6`](https://github.com/dancinlab/n6) (semantic / atlas layer), [`hxc`](https://github.com/dancinlab/hxc) (byte-canonical wire), and [`n12`](https://github.com/dancinlab/n12) (12-axis sparse cube). `.tape` is the **operational / causal-temporal** layer; the other three are *promotion targets* for refined / published data extracted from a tape.

## At a glance

```tape
@S start s001 :: session [T0 N0 ok]
  => "wilson session — provider=claude-cli model=opus-4-7"

@U u001 = "audit이 뭐야?" :: harness [T1 N3 ok]

@A a001 :: harness [T1 N4 ok]
  <- u001
  => "stream-delta 18 tokens"

@T t001 write path=HCX.md :: tool [T2 N49 ok]
  <- a001

@D d001 allow write/HCX.md :: governance [T2 N49 ok]
  <- t001
  |> tool-write/HCX.md

@R r001 write ok :: tool [T2 N50 ok]
  <- t001
  <- d001
  => "1023 bytes written"

@K k001 = 5+31+21852 = 46104 ucents :: cost [T2 N52 ok]
  <- a001
  => "in=5 out=31 cache=21852"

@H session_start@transform priority=28 :: hook [T0 N0 ok]
  <- s001

@P claude-cli open :: provider [T1 N12 ok]
  <- u001

@? abort001 = rate_limited :: provider [T8 N497 cancelled]
  !! a001
```

## Form

`.tape` is line-oriented, append-only, byte-canonical (UTF-8, LF, no BOM). Files are typically named `<session_id>.tape`, `wilson-<YYYY-MM-DD>.tape`, or `*.trace.tape`. All writes go through `tape_absorb()` (schema check + dangling-edge check) — see `algorithms/tape_absorb.hexa`.

### Five invariants

1. **UTF-8, no BOM, LF line endings.** CRLF, CR-only, and BOM-prefixed files are not valid `.tape`.
2. **Append-only.** New entries are appended to EOF; no in-place edits and no re-ordering. Resuming a session re-opens the same file in `O_APPEND` mode.
3. **Every byte-prefix is a valid partial parse.** A truncated tape (`SIGKILL` mid-write) loses *at most* the trailing partial line; everything before is a complete trace.
4. **One record per logical event.** An entry block is a header line at column 0 plus its 0..n continuation (edge) lines indented exactly two spaces. Blocks are separated by a blank line or the next column-0 header.
5. **Byte-canonical.** Same logical event → same bytes. This is the property that makes `.tape` KV-cache-stable: an LLM re-reading the file on session resume hits the provider's KV cache byte-for-byte.

## Entry header

```
@<type> <id>[ = <expr>] :: <domain> [<grade>]
```

- `<type>` — single letter (`S`/`U`/`A`/`T`/`R`/`H`/`D`/`K`/`P`/`I`) or `?` from the type alphabet
- `<id>` — snake_case identifier, unique within the file (typed prefix recommended: `u001`, `t012`, `r012`)
- `<expr>` — optional inline value: user text (`@U`), cost arithmetic (`@K`), hook signature (`@H session_start@transform`)
- `<domain>` — short tag from the domain alphabet (see below)
- `<grade>` — bracketed delivery state and indices (see Grade markers)

## Type alphabet

| Type | Meaning | Example |
|---|---|---|
| `@S` | Session boundary — start / resume / end / cancel | `@S start s001 :: session [T0 N0 ok]` |
| `@U` | User input (`Message{role=user}`) | `@U u001 = "audit이 뭐야?" :: harness [T1 N3 ok]` |
| `@A` | Assistant reply (`Message{role=assistant}`) | `@A a001 :: harness [T1 N4 ok]` |
| `@T` | Tool invocation | `@T t001 write path=HCX.md :: tool [T2 N49 ok]` |
| `@R` | Tool result | `@R r001 write ok :: tool [T2 N50 ok]` |
| `@H` | Hook fire — `event@phase` with optional priority | `@H session_start@transform priority=28 :: hook [T0 N0 ok]` |
| `@D` | Decision — governance allow / deny + reason | `@D d001 allow write/HCX.md :: governance [T2 N49 ok]` |
| `@K` | Cost sample — tokens / ucents | `@K k001 = 5+31+21852 = 46104 ucents :: cost [T2 N52 ok]` |
| `@P` | Provider event — open / close / stream-delta | `@P claude-cli open :: provider [T1 N12 ok]` |
| `@?` | Anomaly — error / abort / rate-limit / panic | `@? abort001 = rate_limited :: provider [T8 N497 cancelled]` |
| `@I` | Identity claim — foundational, non-runtime declaration (birth / scope / principle / version / succession) | `@I birth s_wilson :: identity [d=2026-05-13 ok]` |

The alphabet is **closed at 11**. New *runtime* categories must map onto an existing type (e.g. an MCP server start is a `@P` event with `domain=mcp`, not a new type); cost extensions to `@K`; permissions decisions to `@D`; meta-domain condition state to `@D` with `domain=meta-domain`; per-build version stamps to `@I` with sub-kind `version`. The closed alphabet is what makes downstream consumers (replay, audit, promotion adapters) tractable. `@I` is the *only* non-runtime type — it carries declarative claims about what the agent **IS** rather than what it **DID**; everything else is runtime.

## Grade markers

`.tape` carries **delivery state**, not n6-style verification grade. The bracket payload is space-separated and order-insensitive within the bracket.

| Marker | Meaning |
|---|---|
| `ok` | Delivered cleanly. `ToolResult.is_error=false` for `@R`; HTTP-200 for `@P`; `@I` claim active; `@D` condition held; etc. |
| `err` | Delivered but `is_error=true` — tool ran, returned an error message |
| `denied` | Governance / permissions blocked the call before it ran |
| `cancelled` | User Ctrl-C / rate-limit abort / timeout |
| `partial` | Streaming truncated — provider hung up, max-tokens reached, etc. |
| `T<n>` | Turn number within session (0-indexed; `T0` = pre-first-turn / session_start) |
| `N<n>` | Wall-clock seconds since `@S start` (relative; monotonic within a tape) |
| `d=<YYYY-MM-DD>` | ISO date stamp (used by `@I` and `@D :: meta-domain` events instead of `T<n> N<n>`) |
| `superseded` | (v1.1) a prior `@I` claim was replaced by a later one with the same `<id>` family |
| `v=<version>` | (v1.1) version tag — present on `@I version` and `@P build` |

Composable: `[T2 N48 ok]`, `[T5 N91 denied]`, `[T0 N0 ok]`, `[d=2026-05-13 ok]`, `[d=2026-05-13 v=0.0.1 build=Darwin-arm64 ok]`. Exactly one of `{ok, err, denied, cancelled, partial, superseded}` per bracket. `T<n>` and `N<n>` are optional but recommended for any non-session runtime event; `@I` events use `d=...` instead.

> Verification grade (n6's `[10*]` / `[11*]`) does **not** apply to `.tape` — runtime events carry *what happened* not *what's true*. A tape entry's claim is verified by promoting it to a `.n6` atom via `tape_to_n6`.

## Edge operators (continuation lines)

Continuation lines are indented exactly two spaces and prefixed with one of:

| Operator | Name | Meaning |
|---|---|---|
| `<-` | caused_by | this event was triggered by the listed prior id(s) |
| `->` | triggers | this event caused the listed downstream id(s) |
| `=>` | produces | natural-language description of effect (analog of n6's application edge) |
| `==` | continues | this event resumes / extends a prior session id (used by `@S resume`) |
| `~>` | supersedes | this event makes a prior listed one moot (used by `@S end ~> s001`) |
| `\|>` | verified_by | a validation pass — governance `ok`, hook `ok`, `ToolResult.is_error=false` |
| `!!` | aborts | error / panic / cancel-with-cause; payload is the aborted-id or reason |

Multiple edges of the same kind are allowed; one edge per line. Multi-id payload uses comma-separated ids: `<- t001, t002, t003`.

## Domain alphabet (open set)

The domain tag after `::` is a short token. The reference open set:

```
session    harness     provider    tool         governance
cost       recap       task        hook         mcp
permissions  swarm     pool        identity     meta-domain
atlas
```

Three v1.1 entries (`identity`, `meta-domain`, `atlas`) extend the alphabet to carry the three non-session placements (see Placement matrix below). New domains may be added; consumers MUST skip-unrecognised rather than reject. The closed surface that consumers depend on is the **type alphabet** (11) plus the **edge alphabet** (7), not the domain.

Domain-tag *uppercased* maps to the on-disk filename of the corresponding domain head — `domain=harness` ↔ `HARNESS.md` + `HARNESS.tape` sibling. Joint events emit a `+`-composed tag — `domain=harness+tool+provider` ↔ `HARNESS+TOOL+PROVIDER.md`. Cross-project: `domain=anima::clm` ↔ `~/core/atlas/CLM+HEXA-BRAIN::EEG.tape`. The `+` and `::` separators in domain tags are the same operators the wilson `governance` plugin enforces at the filename level (governance principle #4 `domain-meta-domain`).

## Inline description (quoted continuation prose)

Quoted strings (`"..."`) attached as continuations with no edge prefix act as **descriptive prose** belonging to the parent event. Conventionally the first prose line under an `@<type>` header is the canonical short description.

```tape
@A a042 :: harness [T7 N201 partial]
  "stream truncated — provider sent stop_reason=max_tokens"
  <- u042
```

## Comments and section dividers

| Form | Use |
|---|---|
| `# any text` | Comment (ignored by parser) |
| `# ══════════════════════════════════════════════════════════════` | Top-of-file boundary |
| `# ── 시작 (Session start) ─────────────────────────────────` | Section divider with translated label |
| `#!/usr/bin/env tape` | Shebang — informational only, parser ignores |

## Streaming invariants

1. UTF-8, no BOM, LF line endings.
2. New entries are appended to EOF; no in-place edits.
3. Every write passes through `tape_absorb()`:
   - schema validation (entry header well-formed)
   - dangling-edge check (every `<-` / `->` / `==` / `~>` / `\|>` / `!!` id payload references a prior id in the same file, OR is annotated as an external promise)
   - source citation: `algorithms/tape_absorb.hexa`
4. Streaming `@A` events MAY emit multiple lines as the provider streams — the canonical compaction step is `tape_compact` (folds consecutive stream-deltas of the same `@A id` into one block).
5. The canonical reader cut for "what did this session do" is:
   ```bash
   grep '^@\(T\|R\|D\) ' session.tape
   ```
   This selects tool invocations, results, and governance decisions — the side-effect surface.

## Validation pipeline (`tape_absorb` — 4-step schema/edge check)

Every append goes through:

1. **Header well-formedness.** Regex equivalent of `^@[SUATRHDKPI?] [\S]+( = .*?)? :: [\S]+ \[[^\]]+\]$` — well-formed header line.
2. **Type-grade compatibility.** A `@S start` must have `T0 N0`; a `@R` must carry one of `ok` / `err` / `denied` / `cancelled` / `partial`; a `@D deny` must carry `denied`. An `@I` event may carry `d=<YYYY-MM-DD>` instead of `T<n> N<n>` (identity claims are date-stamped, not turn-stamped) and exactly one of `ok` / `superseded`.
3. **Dangling-edge check.** Every id listed in a `<-` / `->` / `==` / `~>` / `\|>` / `!!` continuation MUST reference an id appearing earlier in the same tape (forward references are not permitted — append-only invariant). Unknown ids reject the append.
4. **Idempotency.** Same `(type, id)` cannot be appended twice unless the second entry is a streaming-delta compaction candidate (`@A id` with `partial` → `ok`). `tape_dedup` reports violations.

## Sibling cross-format (promotion targets)

`.tape` is the **runtime trace**; refined / published data is promoted to a sibling format via an adapter:

| Sibling | Layer | Adapter | Promotion criterion |
|---|---|---|---|
| [`n6`](https://github.com/dancinlab/n6) | semantic — typed verified atoms | `tape_to_n6` | An `@R` with `[ok]` whose result encodes a stable fact, OR an `@A` whose claim survives downstream verification |
| [`hxc`](https://github.com/dancinlab/hxc) | byte-canonical wire | `tape_to_hxc` | Cross-host ship — wrap a tape in HXC v2 to send to a swarm cell with KV-cache stability preserved |
| `n12` | 12-axis sparse cube | `tape_to_n12` | Aggregate metric cells — turn-count, cost-by-domain, denial-rate, etc. populate cube coordinates |

`.tape` is the source of truth for "what happened"; the siblings are the source of truth for "what was learned" / "what we ship" / "what we measure". Adapters are one-way (`.tape` → sibling).

## Reference adapters (wilson plugin surface mapping)

A wilson harness ships today with **five `.jsonl` surfaces** that collectively duplicate state. The `.tape` mapping:

| Wilson surface | `.tape` projection | Adapter |
|---|---|---|
| `~/.wilson/harness-cli/sessions/*.transcript.jsonl` | `@U` + `@A` + `@T` + `@R` lines, ordered | `tape_export_jsonl --kind=transcript --reverse` |
| `~/.wilson/recap/*.jsonl` | `@A` with `domain=recap` + summarising `=> "..."` prose | `tape_export_jsonl --kind=recap` |
| `~/.wilson/recap/index.jsonl` | `tape_index` output (turn / N seek table) | built-in |
| `~/.wilson/cost/*.jsonl` | `@K` lines | `tape_export_jsonl --kind=cost` |
| `~/.wilson/tasks/tasks.jsonl` | `@T add/list/done` + corresponding `@R` | `tape_export_jsonl --kind=task` |

The bidirectional adapter `tape_export_jsonl` ships in `algorithms/`. The intent is that a wilson session writes one tape, and the legacy `.jsonl` files are *derived views* extracted on demand.

## Placement matrix (v1.1)

One grammar, five on-disk placements. Each placement carries a *majority* of certain types but uses the same parser, validator, and algorithm catalog:

| Placement | What | Majority types | Writer | Reader |
|---|---|---|---|---|
| `~/.wilson/identity.tape` | agent identity SSOT (singleton) | `@I` + `@H`/`@P` (declarative) | wilson core boot, `hexa build` post-step, `wilson whoami --set` | `_identity_block()`, governance scope check, pool cells |
| `~/.wilson/harness-cli/sessions/<sid>.tape` | per-session conversation events | `@S`/`@U`/`@A`/`@T`/`@R`/`@K`/`@H`/`@D`/`@P`/`@?` | harness-cli per event | agent re-read on resume, recap injection, replay |
| `~/.wilson/recap/index.tape` | session pointer index | `@S` start headers | recap plugin (`session_start @ observe`) | next-session recap injection |
| `~/core/<repo>/<DOMAIN>.tape` | per-domain history events | `@A` + `@D` (with `domain=<lowercase>`) | git pre-commit hook by path→domain map, manual append | `wilson domain status`, `tape_to_md_log` (renders `## Log` section of `<DOMAIN>.md`) |
| `~/core/atlas/<PROJ>::<DOMAIN>.tape` | cross-project federated history | same as `<DOMAIN>.tape` with `domain=<proj>::<dom>` | each project's push hook | atlas reader, federated query |

All five share the same `tape_absorb` validator and the same `algorithms/tape_*.hexa` catalog. The placement determines what events dominate; the grammar is fixed.

## Identity tape (`~/.wilson/identity.tape`)

A singleton append-only file carrying the agent's foundational claims. Six dimensions, one `@I` event each (or grouped):

| Dimension | Sub-kind | Example |
|---|---|---|
| WHO | birth | `@I birth wilson :: identity [d=2026-05-13 ok]` |
| WHAT | scope | `@I scope :: identity [d=2026-05-13 ok]` with capabilities / refuses / authorizes payload |
| WHENCE | origin / succession_of | `@I origin :: identity [d=2026-05-13 ok]` + `<- hive` |
| WHEN | version (per-build, auto-emitted) | `@I version v0_0_1 :: identity [d=2026-05-13 v=0.0.1 build=Darwin-arm64 ok]` |
| WHERE | build_host / runtime_kind | inline in `@I version` payload |
| WHY | principle (pointer to governance SPEC) | `@I principle :: identity [d=2026-05-13 ok]` |

`_identity_block()` (wilson `core/main.hexa::_identity_block`) reads the tape and renders the canonical `## Identity` system-prompt block. This replaces the v0 hard-coded 1-liner; identity becomes file-backed, versioned, append-only.

`wilson whoami` CLI (cost-routing — LLM-bypass) prints the tape head + tail.

Pool / swarm cells inherit identity via a `<- mac-m1:identity@birth` edge in their cell-local identity tape; cells refuse to claim primary identity.

## Domain-tape sibling (`<DOMAIN>.tape` ↔ `<DOMAIN>.md`)

Wilson's governance principle #4 (`domain-meta-domain`) defines root `<UPPERCASE>(+<UPPERCASE>)*.md` files with a head (live conditions) + `---` + `## Log` (append-only chronological history). The `## Log` discipline is author-only — governance lint enforces filename shape but cannot enforce content.

`<DOMAIN>.tape` closes that gap. Each `<DOMAIN>.md` has a sibling `<DOMAIN>.tape`; the tape carries the events that *would* have been logged manually, and `tape_to_md_log` renders the `## Log` section deterministically from the tape tail.

Render template:

```markdown
<!-- AUTO-RENDER from HARNESS.tape (last N entries) -->
### 2026-05-13 14:30  ·  TUI raw-mode lands
@A a001 :: harness — commit b3706a1
<!-- /AUTO-RENDER -->
```

The `<!-- AUTO-RENDER -->` ... `<!-- /AUTO-RENDER -->` fence is the idempotent rewrite zone; anything outside is human-written and preserved.

`git pre-commit` hook (suggested wiring): walk the changed-file set, map each path → domain via `plugins/<id>/` → domain, append one `@A commit_<short_sha> :: <domain> [d=<date> ok]` event to each touched domain tape. ## Log auto-fills on next render.

## Meta-domain verification (`<D1+D2+D3>.md`)

A meta-domain file enumerates constituent conditions Cn and joint conditions Mm. v1.1 expresses each condition as a `@D` event in `<D1+D2+D3>.tape` with `domain=meta-domain`:

```tape
@D c1 := "HARNESS.input_loop" :: meta-domain [d=2026-05-13 ok]
  text = "wilson -p / interactive TUI claims input loop"
  proof = "plugins/harness-cli/main.hexa::harness_cli_activate"

@D c2 := "HARNESS.streaming" :: meta-domain [d=2026-05-13 ok]
  text = "streaming render via host_render(...streaming, delta)"
  |> commit b3706a1

@D m1 := "joint_turn_closes" :: meta-domain [d=2026-05-13 ok]
  <- c1, c2
  text = "host_run_turn returns Message + ToolResult"
  proof = "build/Darwin-arm64/wilson -p hi → assistant text streamed"
```

`tape_meta_verify` (`algorithms/tape_meta_verify.hexa`) parses the constituent `## Conditions` section of the `.md` head, walks the `.tape` for evidence of each Cn / Mm, and reports a held/violated matrix. State-transition events on subsequent re-verification append `@D <id>_violated := "violated"` (or `_held_continuous_7d := "promoted_stable"`) — the tape is the audit trail of meta-domain state.

`wilson domain status` (`core/main.hexa::_cmd_domain_status`) walks every `<DOMAIN>.md` + `.tape` pair and prints a one-screen matrix: per-meta-domain Mm state, condition coverage %, last-log-entry timestamp.

## Versioning

- **v1** (2026-05-13) — 10 types · 7 edges · 5 delivery markers · open domain alphabet. Single placement (per-session tape).
- **v1.1** (this spec, 2026-05-13) — 11 types (adds `@I` identity) · 7 edges (unchanged) · 6 grade markers (adds `superseded` for `@I`) · open domain alphabet extended with `identity` / `meta-domain` / `atlas`. Five placements (per-session, identity singleton, recap index, per-domain, cross-project atlas). Adds 4 algorithms: `tape_render_identity`, `tape_to_md_log`, `tape_meta_verify`, `tape_domain_status`.
- **v2** (reserved) — anticipated additions: structured payload on `@K` (per-model token breakdown); binary attachment side-car (analog of wilson's `_attachments` for `@R` lines pointing to images / files); n6-style verification-grade overlay for adapters that need it.

Forward-compatibility rule: a v1.1 reader MUST skip any header line whose `<type>` is not in the v1.1 alphabet of {S, U, A, T, R, H, D, K, P, I, ?} rather than reject. Edge operators outside the v1 set of {`<-`, `->`, `=>`, `==`, `~>`, `\|>`, `!!`} MUST also be skipped rather than rejected. v1 readers encountering an `@I` line MUST skip-not-reject per the same rule.

## Cross-references

- [`n6`](https://github.com/dancinlab/n6) — sister semantic atlas
- [`hxc`](https://github.com/dancinlab/hxc) — sister byte-canonical wire
- `n12` — sister multidimensional cube (private at `dancinlab/n12`)
- `algorithms/` — reference hexa-lang modules for guarded append, replay, grep, health check, compaction, indexing, dedup, KV-cache probe, JSONL adapter, n6 / hxc / n12 promotion stubs
- `docs/DESIGN.md` — design rationale: why a 4th sibling, why typed events not raw JSONL, why provenance edges
