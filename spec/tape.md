# Agent-Execution Trace — `.tape` format v1.6 (spec, 2026-05-26)

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
| `@X` | (v1.2) External citation — third-party standard / paper / vendor doc / regulation. Carries `url` / `scope` / `version` keys. | `@X x1 := "ISO 37120" :: standard [iso active]` |
| `@F` | (v1.2) Forbidden pattern — formal "deny:" rule with `pattern` / `why` keys. Replaces ad-hoc `forbid =` payload. | `@F f1 := "external-lattice-fit" :: governance [required]` |
| `@N` | (v1.2) Note / LLM-only hint — plugins skip; human + LLM read. Replaces `// note:` prose comments. | `@N n1 := "build-tip" :: note [active]` |
| `@C` | (v1.2) Config / parameter — static value (port / timeout / path). Replaces ad-hoc `key = value` in @P entries. | `@C c1 := "session-dir" :: config [active]` |
| `@L` | (v1.2) Layout / directory structure — `path -> "purpose"` body lines. Replaces markdown tree tables. | `@L l1 := "repo-layout" :: structure [active]` |
| `@V` | (v1.2) Spec version self-declaration — file announces which `.tape` version + extensions it uses. Subject MAY name a format dialect (`"domains"` for `DOMAINS.tape`). | `@V := "tape" :: spec  version = "1.6"` |

The alphabet is **closed at 17** (11 runtime + `@I` foundational + 5 declarative). New *runtime* categories must map onto an existing type (e.g. an MCP server start is a `@P` event with `domain=mcp`, not a new type); cost extensions to `@K`; permissions decisions to `@D`; meta-domain condition state to `@D` with `domain=meta-domain`; per-build version stamps to `@I` with sub-kind `version`. The closed alphabet is what makes downstream consumers (replay, audit, promotion adapters) tractable.

**Three classes of types (v1.2)**:
- **Runtime (10)** `@S @U @A @T @R @H @D @K @P @?` — events that happened, time-stamped (`T<n> N<n>`).
- **Foundation (1)** `@I` — declarative identity claims about what the agent IS, date-stamped (`d=…`).
- **Declarative (6, v1.2)** `@X @F @N @C @L @V` — static facts (no causal `<-` required), used by `AGENTS.tape` and other configuration-style tapes. Date-stamped or stateless.

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
| `required` | (v1.2) governance rule that MUST be obeyed — violation triggers deny |
| `recommended` | (v1.2) governance rule that SHOULD be obeyed — violation triggers warn |
| `optional` | (v1.2) governance hint — violation is silent |
| `draft` | (v1.2) proposed rule — not yet enforced |
| `active` | (v1.2) currently in effect (default for declarative entries — implicit if omitted) |
| `deprecated` | (v1.2) superseded but kept for context — `~>` edge points to replacement |
| `allow:<scope>` | (v1.2) scope-bound allowance, e.g. `[allow:read]` `[allow:write/docs]` |
| `deny:<scope>` | (v1.2) scope-bound denial, e.g. `[deny:write/LATTICE_POLICY.md]` |

Composable: `[T2 N48 ok]`, `[T5 N91 denied]`, `[d=2026-05-13 ok]`, `[required]`, `[recommended draft]`, `[allow:read deny:write]`. Exactly one of the **runtime** set `{ok, err, denied, cancelled, partial, superseded}` per bracket when present. Governance / scope tags compose freely with each other but not with runtime delivery tags (an `@F` forbidden-pattern entry doesn't have "delivery state"). `T<n>` and `N<n>` are optional but recommended for any non-session runtime event; `@I` events use `d=...` instead; v1.2 declarative entries (`@X @F @N @C @L @V`) typically use `d=...` or omit time stamps entirely.

**Open tag-bag (v1.6).** The bracket is an OPEN tag set, not a closed enum. The tags listed above are the *standardized* ones — they carry defined semantics and MUST NOT be redefined. A placement MAY add **domain-specific tags** alongside them, either bare (`tier-2`, `paper-track`, `fire-tier`, `g6-append-only`) or `key=value` (`slug=chat-init-ce-floor`, `group=CHAT`, `verdict=...`, `tier=2`). Conformant consumers skip-not-reject any tag they don't recognise (forward-compatibility rule). Observed in the wild: `@C … :: formula [slug=… group=…]` (CLAIMS.tape), `@X … :: reuse-edge [tier-2 active]` (NEXUS.tape). (Note: `key=value` *inside a quoted value or prose* — e.g. a math interval `[min=2, max=64]` in a `do` string — is NOT a grade bracket; only the trailing `[...]` of an entry-header line is.)

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
| `<:` | (v1.2) specializes / is-a | this entry is a specialization of the listed parent (identity hierarchy) |
| `:>` | (v1.2) generalizes / extends | inverse of `<:` — parent points down to specializations |
| `?>` | (v1.2) soft-depends | non-binding dependency / recommended prerequisite |
| `!>` | (v1.2) conflicts-with | this entry is mutually-exclusive with the listed id(s) |
| `@>` | (v1.2) projects-to / renders-to | declares a generator target — e.g. `@> AGENTS.md` means this entry contributes to the AGENTS.md rendition |

Multiple edges of the same kind are allowed; one edge per line. Multi-id payload uses comma-separated ids: `<- t001, t002, t003`.

The **v1 edge set** `{<-, ->, =>, ==, ~>, |>, !!}` covers runtime causality + effect description. The **v1.2 additions** `{<:, :>, ?>, !>, @>}` cover declarative-static relationships (hierarchy, recommendation, conflict, generator targeting) needed by `AGENTS.tape` / `@F` / `@X` / `@C` / `@L` / `@V` entries. A v1.1 reader MUST skip-not-reject any v1.2 edge per forward-compatibility rule.

## Domain alphabet (open set)

The domain tag after `::` is a short token. The reference open set:

```
session    harness     provider    tool         governance
cost       recap       task        hook         mcp
permissions  swarm     pool        identity     meta-domain
atlas        skill       glossary    index
formula      reuse-edge  provides    reuse-candidate
```

Three v1.1 entries (`identity`, `meta-domain`, `atlas`) extend the alphabet to carry the three non-session placements (see Placement matrix below). Three v1.5 entries: `skill` and `glossary` are declarative `@D` kinds that carry the same `{do, dont}` body as `:: governance` (see the v1.5 amendment) — `:: skill` for a `SKILL.md` body, `:: glossary` for a term→canonical-command map; `index` is the kind of a roster file's `@V` header (`DOMAINS.tape` — see the v1.5 amendment). Four v1.6 entries — `formula` (`CLAIMS.tape` claim entries) and `reuse-edge` / `provides` / `reuse-candidate` (`NEXUS.tape` lattice) — are free-body declarative kinds on `@C` / `@X` (see the v1.6 amendment). The alphabet is genuinely open and heavily exercised in the wild (a survey of two repos found 110+ distinct domain tags); the listing above is the *reference / standardized* set, not an enumeration. New domains may be added; consumers MUST skip-unrecognised rather than reject. The closed surface that consumers depend on is the **type alphabet** (11) plus the **edge alphabet** (7), not the domain.

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
2. New entries are appended to EOF; no in-place edits — **APPLIES TO**: `<sid>.tape` (per-session), `<DOMAIN>.log.tape` (domain history, v1.2 amendment), `recap/index.tape`, `<PROJ>::<DOMAIN>.tape` (cross-project federated). **DOES NOT APPLY TO**: `AGENTS.tape` (project-level governance), `identity.tape` (singleton), `<DOMAIN>.tape` (per v1.2 amendment, architecture-current — editable). These declarative-state files use latest-wins per `<id>` semantics.
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
| `~/.wilson/identity.tape` | agent identity SSOT (singleton · **editable** v1.2) | `@I` + `@H`/`@P` (declarative) | wilson core boot, `hexa build` post-step, `wilson whoami --set` | `_identity_block()`, governance scope check, pool cells |
| `~/.wilson/harness-cli/sessions/<sid>.tape` | per-session conversation events (**append-only**) | `@S`/`@U`/`@A`/`@T`/`@R`/`@K`/`@H`/`@D`/`@P`/`@?` | harness-cli per event | agent re-read on resume, recap injection, replay |
| `~/.wilson/recap/index.tape` | session pointer index (**append-only**) | `@S` start headers | recap plugin (`session_start @ observe`) | next-session recap injection |
| `~/core/<repo>/AGENTS.tape` | project-level agent harness (**editable** v1.2) | `@V`/`@I`/`@C`/`@L`/`@D :: governance`/`@F`/`@X`/`@N`/`@H` declarative | hand-edited, per-repo session | Claude Code · Aider · downstream `tape_walk_tree` |
| `~/core/<repo>/<DOMAIN>.tape` | per-domain **architecture-current** (**editable** v1.2) | `@V`/`@I`/`@C`/`@L`/`@D :: governance`/`@F`/`@X`/`@N` declarative | hand-edited as design evolves | `wilson domain status`, downstream consumers |
| `~/core/<repo>/<DOMAIN>.log.tape` | per-domain **append-only history** (v1.2 NEW) | `@A`/`@T`/`@R`/`@K`/`@H`/`@?`/`@D :: decision` events | git pre-commit hook, runtime emit | `tape_to_md_log` (renders `## Log` section of `<DOMAIN>.md`) |
| `~/core/<repo>/DOMAINS.tape` | repo-root domain **roster** (**editable** · v1.5 NEW) | `@V :: index` + `@domain <NAME> := "<relpath>"` rows | sidecar `domain` plugin (`/domain init`) | `/domain list` · roster NAME→path resolution |
| `~/core/<repo>/CLAIMS.tape` | repo-root verifiable-**claim index** (**editable** · v1.6 NEW) | `@C <id> :: formula [slug= group=]` free-body | hand-edited per claim | `hexa verify` (g5) → `.verdicts/` → `/paper` gate |
| `~/core/<repo>/NEXUS.tape` | repo-root intra-project **reuse lattice** (**editable** · v1.6 NEW) | `@X :: reuse-edge / provides / reuse-candidate` free-body | hand-edited (commons `@D g67`) | reuse-graph query · INDEX.md pointer |
| `~/core/atlas/<PROJ>::<DOMAIN>.log.tape` | cross-project federated **history** (**append-only**) | same as `<DOMAIN>.log.tape` with `domain=<proj>::<dom>` | each project's push hook | atlas reader, federated query |

All placements share the same `tape_absorb` validator and the same `algorithms/tape_*.hexa` catalog. The placement determines what events dominate AND the mutability semantics (editable vs append-only). The grammar is fixed.

**v1.2 mutability summary**: declarative placements (`identity.tape`, `AGENTS.tape`, `<DOMAIN>.tape`) are EDITABLE — they carry the current architecture state and evolve in place with latest-wins-per-id semantics. Event-stream placements (`<sid>.tape`, `<DOMAIN>.log.tape`, `<PROJ>::<DOMAIN>.log.tape`, `recap/index.tape`) are APPEND-ONLY per §"Streaming invariants" rule #2.

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

### Architecture-vs-history split (v1.2 amendment, 2026-05-14)

Domain tapes now use **two separate placements** with different mutability semantics:

| File | Mutability | Carries | Edit policy |
|---|---|---|---|
| **`<DOMAIN>.tape`** | architecture-current (editable) | `@V` · `@I` · `@C` · `@L` · `@D :: governance` · `@F` · `@X` · `@N` declarative entries | Continuously edited as the design evolves. Latest-wins per `<id>`. Like `<DOMAIN>.md` itself — it carries the architecture-complete current state. |
| **`<DOMAIN>.log.tape`** | append-only history | `@A` · `@T` · `@R` · `@K` · `@?` runtime events · `@D :: decision` decision events · `@H` hook fires | Strictly append-only per §"Streaming invariants" rule #2. Each entry is a historical event; never edited or deleted. |

**Why split**: declarative governance / identity / layout claims naturally evolve (a config value changes, a rule is reworded, a layout entry is renamed). Forcing all updates to be append-only with `~>` supersedes edges produces a noisy history where every edit creates 2 entries. The split lets architecture entries live in their natural "current state" form while history (events that already happened) stays immutable.

**Rule of thumb**: if removing or rewording an entry would be a coherent action ("the spec changed"), it belongs in `<DOMAIN>.tape`. If the entry records something that **happened** at a specific point in time, it belongs in `<DOMAIN>.log.tape`.

### Render

`tape_to_md_log` renders the `## Log` section of `<DOMAIN>.md` from `<DOMAIN>.log.tape` (not from `<DOMAIN>.tape`):

```markdown
<!-- AUTO-RENDER from HARNESS.log.tape (last N entries) -->
### 2026-05-13 14:30  ·  TUI raw-mode lands
@A a001 :: harness — commit b3706a1
<!-- /AUTO-RENDER -->
```

The `<!-- AUTO-RENDER -->` ... `<!-- /AUTO-RENDER -->` fence is the idempotent rewrite zone; anything outside is human-written and preserved.

`git pre-commit` hook (suggested wiring): walk the changed-file set, map each path → domain via `plugins/<id>/` → domain, **append** one `@A commit_<short_sha> :: <domain> [d=<date> ok]` event to each touched `<DOMAIN>.log.tape`. The `## Log` section of `<DOMAIN>.md` auto-fills on next render. The architecture `<DOMAIN>.tape` is untouched by commit hooks; it changes only when the design changes.

### Migration of pre-split tapes

Tapes that existed before this split (v1.1 era) carried both architecture and history mixed in a single `<DOMAIN>.tape`. Migration is optional and per-repo:

1. Leave existing `<DOMAIN>.tape` as the architecture-current form (drop or supersede stale history entries).
2. Create `<DOMAIN>.log.tape` for new append-only events.
3. Old history entries already mixed in `<DOMAIN>.tape` are not moved — they remain as historical artifacts. New entries follow the split.

> **Auto-classification doesn't work** — runtime grade markers like `[ok]` were used in v1.1-era tapes both for "delivered cleanly" runtime events and for "this fact is current/true" architecture entries. Any mechanical heuristic (grade · prefix · entry type) misclassifies a substantial fraction. **Split requires LLM-judgment per entry** based on author intent: does this describe what something IS (architecture) or what happened at a point in time (log)? See `dancinlab/anima/REBORN.tape` (213 arch · 1968 log split commit `7ceaa6882`) for a canonical example.

### Authoring guide — `<DOMAIN>.tape` (architecture-current)

**When to add an entry to `.tape`**: the entry describes the **current state** of the substrate. Removing or rewording it would be a coherent action ("the spec changed"). The entry has no time anchor.

**Entry types belonging in `.tape`**:
- `@V` — spec version declaration (once at top)
- `@I id001` — domain identity (once · kind / brief / parent / sibling-log)
- `@I id00N` — sub-identity claims (specializations of id001 via `<:`)
- `@C` — config values · paths · defaults
- `@L l1` — repo / sub-tree layout
- `@D :: governance` — policy clauses · rules · contracts
- `@F` — forbidden patterns · deny rules
- `@X` — external citations · cross-refs to other repos / standards
- `@N` — LLM-only notes · hints · clarifications
- `@H` — generator hooks (`@> <output>`)

**How to edit**: open `.tape`, change the entry in place. No `~>` supersedes needed. Commit as part of the design change that motivated it.

```tape
# WAS:
@C c_session_dir := "session-dir" :: config [active]
  value = "~/.wilson/sessions/"

# NOW (config value changed · just edit in place):
@C c_session_dir := "session-dir" :: config [active]
  value = "~/.wilson/harness-cli/sessions/"
```

### Authoring guide — `<DOMAIN>.log.tape` (append-only history)

**When to add an entry to `.log.tape`**: the entry records something that **happened at a specific point in time**. The entry is permanent — never edited, never deleted.

**Entry types belonging in `.log.tape`**:
- `@A` — assistant action · commit landed · feature implemented
- `@T` — tool invocation · test run
- `@R` — tool result · test outcome
- `@K` — cost record · per-cycle measurement
- `@H` — hook fire event (not a hook declaration · that's in `.tape`)
- `@?` — anomaly · error · rate-limit
- `@D :: decision` — decision event (not a governance rule · which goes in `.tape`)
- `@S` — session start / end / resume

**How to append**: open `.log.tape`, add new entry at EOF (or at the bottom of `# §Log` section). Always include `d=<YYYY-MM-DD>` or `T<n> N<n>` time anchor in the grade bracket.

```tape
# Daily entry pattern (canonical):
@A commit_2709dc7 :: harness [d=2026-05-14 ok]
  <- prev_a_id
  => "TUI logo aspect fix — flat-top hexagons"

@D d_dispatch_table_regen := "regenerate dispatch_table" :: decision [d=2026-05-14 ok]
  <- request_from_user
  why = "wilson build --with X needs runtime dispatch table edit"
  |> bash_exec_passed
```

**Pre-commit hook integration** (suggested wiring):

```bash
#!/bin/sh
# .git/hooks/pre-commit — append @A commit event to touched <DOMAIN>.log.tape
SHA=$(git rev-parse --short HEAD)
DATE=$(date +%Y-%m-%d)
git diff --cached --name-only | while read f; do
  # path → domain map (per repo)
  domain=$(map_path_to_domain "$f")
  echo "" >> "${domain}.log.tape"
  echo "@A commit_${SHA} :: ${domain} [d=${DATE} ok]" >> "${domain}.log.tape"
  echo "  => \"$(git log -1 --pretty=%s)\"" >> "${domain}.log.tape"
done
```

The hook NEVER touches `<DOMAIN>.tape` — that file changes only when the design changes (manual edit).

### Common pitfalls

- ❌ **Adding an `@A commit_*` event to `.tape`** — `@A` is always log. Move to `.log.tape`.
- ❌ **Adding a `@C config-value` to `.log.tape`** — `@C` is always architecture. Move to `.tape`.
- ❌ **Editing an entry in `.log.tape`** — break of append-only invariant. Use `~>` supersedes edge in a NEW entry instead.
- ❌ **Letting `.tape` accumulate dated entries** — over time `.tape` becomes a log. Periodic LLM review + extraction to `.log.tape` is required.
- ❌ **Forgetting the time anchor on `.log.tape` entries** — every log entry MUST have `d=<date>` or `T<n>` for chronological ordering. Without it, replay/recap cannot order events.

### Validation

The `tape_absorb` validator enforces:
1. `.tape` files reject `@A` / `@T` / `@R` / `@K` / `@?` types (runtime events) at append time. (Implementation pending.)
2. `.log.tape` files reject in-place edits — only EOF appends allowed. (Implementation pending — currently honor-system enforced.)
3. Every `.log.tape` entry must carry a time-anchor grade tag (`d=YYYY-MM-DD` or `T<n> N<n>`). (Implementation pending.)

Until validators land, authoring is honor-system. The LLM-judgment classification rule is the primary discipline.

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

## Payload syntax (v1.2)

Body lines (indented 2 spaces under an entry header) carry the entry's data. v1.2 standardises four payload forms beyond the v1.1 single-line `key = "value"`:

```tape
@D g1 := "honest-caveat-first" :: governance [required]
  rule = "Every claim coupling n=6 to an external phenomenon ships a one-line honest caveat."
  scales = [multiverse, universe, galaxy, planet, country, city]
  applies-to <<~EOF
    Every section in README.md
    Every cell in SCALE.md
    Every entry in this file that mentions n=6 vs external entity
  EOF
  proof = "see [@x1] §4 and `LATTICE_POLICY.md` §1.2"
```

| Form | Grammar | Use |
|---|---|---|
| **Single-line string** | `key = "value"` | Most fields. Inline `\"` escapes if needed. |
| **Array literal** | `key = [a, b, c]` (or `[\"a\", \"b\"]` if quoted) | Ordered lists — scales, phases, options, choices. |
| **Heredoc** | `key <<~EOF` … `EOF` (`~` strips common leading indent) | Multi-line prose / code block. Ends on EOF token alone on a line. |
| **Inline citation** | `"see [@<id>] §..."` inside a quoted value | Reference another entry in the same file by id — like markdown footnote. |
| **Backtick code** | `` `cmd or path` `` inside a quoted value | Inline code-span — render as monospace by adapters. |

Consumers MAY parse only the forms they need; `[@<id>]` is informational (no semantic dependency).

## Grammar primer (mandatory header for `AGENTS.tape`, recommended for cold-read tapes)

Any `AGENTS.tape` (and any tape file likely to be cold-read by an LLM or new contributor) SHOULD begin with this exact ~35-line comment header. The primer makes the file self-describing — an LLM seeing it for the first time (via `CLAUDE.md` symlink or otherwise) immediately knows how to parse the rest.

```
#!/usr/bin/env tape
# ══════════════════════════════════════════════════════════════════════
# .tape v1.6 — grammar primer (cold-read by any LLM / agent / human)
# ══════════════════════════════════════════════════════════════════════
# Form: each entry is `@<type> <id> := "<subject>" :: <kind> [<grades>]`
#       optionally followed by body lines (2-space indent) — key=value,
#       edges (<- -> => …), or quoted prose.
#
# ENTRY TYPES (17):
#   Runtime (10): @S session  @U user  @A assistant  @T tool-call  @R result
#                 @H hook  @D decision  @K cost  @P provider  @? anomaly
#   Foundation:   @I identity-claim
#   Declarative:  @X external-citation  @F forbidden-pattern  @N note
#                 @C config  @L layout  @V spec-version
#
# EDGES (12, on body lines, 2-space indent):
#   Causal:     <- caused-by   -> triggers   == continues
#               ~> supersedes  !! aborts     |> verified-by
#   Effect:     => produces (followed by quoted natural-language)
#   Structural: <: specializes  :> generalizes  ?> soft-depends
#               !> conflicts-with  @> projects-to (e.g. @> AGENTS.md)
#
# GRADE TAGS (in [...] on entry header):
#   Delivery:   ok · err · denied · cancelled · partial · superseded
#   Governance: required · recommended · optional · draft · active · deprecated
#   Scoped:     allow:<x> · deny:<x>
#   Time/index: T<n> (turn)  N<n> (wall-sec)  d=<YYYY-MM-DD>
#
# PAYLOAD SYNTAX (body lines):
#   key = "value"           single-line string
#   key = [a, b, c]         array literal
#   key <<~EOF              heredoc (multi-line; ends with EOF on own line)
#     multi-line text
#   EOF
#   "see [@x1] §3"          inline citation by entry id
#   `cmd or path`           backtick code-span (inline only)
#
# @D BODY (governance · skill · glossary): {do, dont} ONLY — both keys
#   repeatable (one imperative per line), no other key. v1.5.
#   @C/@X/@N/@I/@L/@V bodies stay free-key (NEXUS · CLAIMS placements). v1.6.
#
# Full spec: ~/core/tape/spec/tape.md (or github.com/dancinlab/tape)
# ══════════════════════════════════════════════════════════════════════
```

The primer is a **comment block** — the tape parser ignores it (lines starting with `#` are skipped per §"Comments and section dividers"). Its sole purpose is making the file self-describing to first-time readers.

After the primer, the canonical first non-comment line is `@V` declaring the spec version:

```tape
@V := "tape" :: spec
  version = "1.6"
  uses = [@X, @F, @N, @C, @L, "<:", "@>", "[required]"]
```

## AGENTS.tape pattern (v1.2 — cross-project agent-harness file)

`AGENTS.tape` is the dancinlab convention name for the file that replaces `AGENTS.md` (the [agents.md](https://agents.md/) standard) across every repo. It is the **declarative + identity** half of `.tape` — no runtime events. Recommended top-level structure:

```
AGENTS.tape
├── §0 grammar primer (the mandatory ~35-line comment block above)
├── §1 @V spec-version declaration
├── §2 @I identity-claim entries  (what this project IS)
├── §3 @C config entries          (paths · ports · timeouts · defaults)
├── §4 @L layout entry            (directory structure)
├── §5 @D :: governance entries   (g1..gN — project rules, [required] / [recommended])
├── §6 @F forbidden-pattern entries (deny-rules)
├── §7 @X external-citation       (standards · papers · vendor docs)
├── §8 @N notes                   (LLM-only hints, build tips)
└── §9 @H :: generator hooks      (e.g. `@> AGENTS.md` for fallback markdown emission)
```

A separate `SEED.tape` (or per-session `<sid>.tape`) carries the **runtime** half — `@S` / `@U` / `@A` / `@T` / `@R` / `@D :: decision` (open) / `@?` (anomalies) / `@T plan` (planned actions) / log entries. The split keeps governance stable while runtime evolves.

**Symlink convention**: each repo SHOULD ship `CLAUDE.md → AGENTS.tape` (symlink) so Claude Code's `CLAUDE.md` auto-discovery picks up the grammar primer first. Aider / Cursor / future agents.md ecosystem support for `AGENTS.tape` proposed upstream.

**Fallback generator**: `tape_to_agents_md(AGENTS.tape) → AGENTS.md` (per `@H :: generator` hooks with `@> AGENTS.md` edge) emits a markdown rendition for tooling that doesn't speak `.tape` natively. The `.tape` is the SSOT; the `.md` is a derived view.

## Compactness invariants (v1.2 amendment, 2026-05-20)

Declarative entries in `AGENTS.tape`, `identity.tape`, and `<DOMAIN>.tape` are subject to hard caps on per-entry size. The cap forces terse, dense entries — long prose belongs in commit messages or linked `.md` files, not in tape entries that every agent re-reads on every session.

| Cap | Limit | Rationale |
|---|---|---|
| Entry total | ≤ 500 chars (header line + all body lines, joined with `\n`, including indentation) | Forces a single concept per entry; the longest pre-cap real-world entry was ~570 chars and was already drifting toward prose |
| Field value | 1 line (no `\n` inside a value — heredoc payload form is banned in declarative tapes) | The heredoc form (`<<~EOF`) is a multi-line escape hatch; allowing it lets prose creep back in |
| Field count | ≤ 5 fields per entry | Forces decomposition of overloaded entries — split into multiple `@<type>` blocks rather than overloading one |

**Character counting**: 1 glyph = 1 char. CJK (Korean / Chinese / Japanese) is weighted identically to Latin — Korean's higher information density means the same 500 char cap is stricter for English than for Korean, which matches authoring intent. Newline characters count as 1 char each.

**Measurement range**: the header line + every continuation line that belongs to the entry (indented two spaces, until blank line or next column-0 header). Comments (`#`) are not part of any entry and are not counted.

**Scope**: applies to **declarative** placements — `AGENTS.tape`, `identity.tape`, `<DOMAIN>.tape`. **Does NOT apply to** append-only event-stream placements — `<sid>.tape`, `<DOMAIN>.log.tape`, `recap/index.tape` — those record what happened and runtime events have natural length variation.

**Enforcement**:

- `tape_absorb()` SHOULD emit a `[recommended]`-grade warning for oversized declarative entries (validator implementation pending).
- Sidecar `wilson-minimal-keep` plugin (≥ 0.6.0) blocks `PreToolUse` Write/Edit/MultiEdit that introduces an oversized `@<type>` block via its S4 signal.

**Authoring recipe when over the cap**:

1. Split — separate concerns into two `@<type>` entries with a `<:` / `?>` edge between them.
2. Shorten — replace prose with symbol-dense notation (`·` instead of "and", `→` instead of "then", `⊕` instead of "with").
3. Reference — point to an external `.md` via `parent` / `ssot` / inline citation `[@<id>]` instead of restating its content.
4. Drop — if the field is redundant with another entry or with `<DOMAIN>.md` content, remove it.

Splitting a `<<~EOF` heredoc into multiple `key1` / `key2` / `key3` single-line fields (or into multiple entries) is the canonical migration path off the banned heredoc form for declarative tapes.

## Governance imperative — `@D :: governance` body closed at {do, dont} (v1.3 amendment, 2026-05-20)

`@D :: governance` entries (in `AGENTS.tape`, `identity.tape`, `<DOMAIN>.tape`) carry **imperative directives only**. The body fields are constrained to a closed two-key set; legacy field keys (`rule`, `why`, `apply`, `cross_link`, `honest_carve_out`, `scope_guard`, `*_examples`, `*_calculus`, `authority`, `remedy`, `evidence`, `note`, `status`, `forbidden`, `insufficient`, …) are deprecated and rejected at validation. The single concept per entry stays — but the entry says only **what to do** and **what not to do**, not *why* or *how* or *for whom* (those belong in `archive/PHILOSOPHY.tape`, commit messages, or `<DOMAIN>.md` prose).

| Field | Form | Use |
|---|---|---|
| `do = "<imperative>"` | Single line | What MUST be done — the rule itself in imperative form |
| `dont = "<imperative>"` | Single line | What MUST NOT be done — forbidden patterns. Inline exceptions go in parentheticals: `dont = "X (단 Y / Z 예외)"` |

Edges (`@>`, `<-`, `<:`, `?>`, `!>`, …) remain allowed as before — they are not body keys. The `:= "<subject>"` header subject is the short slug (≤ 60 chars).

**Worked example** (anima `g_no_cost_scope_limit`, before/after):

```tape
# v1.2-era (verbose — now deprecated):
@D g_no_cost_scope_limit := "cost cap + scope limit + rate-limit-floor = ALL UNLIMITED — 어디서도 limit 표현 금지" :: governance [required d=2026-05-20 active]
  rule = "anima 의 모든 작업에 cost cap 없음 · scope limit 없음 · rate-limit floor 없음. user directive verbatim..."
  scrub_target = "AGENTS.tape body 의 'conservative cost cap' 표현 ..."
  apply = "(1) AGENTS.tape g_fire_autonomous + g_resource_active_parallel + ..."
  why = "user 8-directive batch 2026-05-20 ..."
  honest_carve_out = "**제한 0 = 안전 0 아님**: B-EMERGE-7 / B-IDENTITY-5 ..."
  cross_link = "g_fire_autonomous + g_resource_active_parallel + ..."
  @> CLAUDE.md

# v1.3 (imperative — required):
@D g_no_cost_scope_limit := "cost·scope·rate-limit 0" :: governance [required d=2026-05-20 active]
  do   = "모든 작업에 cost cap 0 · scope limit 0 · rate-limit floor 0"
  dont = "hard-floor·'conservative cap'·'production safety floor' (단 g_blue/B-IDENTITY-5/g3/f1f2 honest invariants 예외)"
  @> CLAUDE.md
```

**Caps** (v1.3 narrows the field set; size stays under v1.2's general cap):

| Cap | v1.2 (all declarative) | v1.3 (`@D :: governance` only) |
|---|---|---|
| Entry total | ≤ 500 chars | unchanged (S4 already enforces) |
| Field count | ≤ 5 fields | ≤ 2 fields (`{do, dont}`) — *superseded by v1.5: `do`/`dont` are repeatable, no count cap* |
| Field key set | open | closed: `{do, dont}` |
| Field value | 1 line, heredoc banned | unchanged |

The 2-field × ~200-char-each + header bounds governance entries naturally under 500 — no separate v1.3 size cap needed.

**Where the dropped content goes**:

- `why` (rationale · user-directive verbatim · incident anchor) → `archive/PHILOSOPHY.tape` (anima-style append-only ledger) or commit message.
- `cross_link` (related entry IDs) → slug naming convention (e.g. `g_fire_*` family) + `grep` when needed.
- `apply` / `scope_guard` (how/where to apply) → folded into `do`/`dont` body with `·` separator.
- `honest_carve_out` (exceptions / invariants) → folded into `dont` with parenthetical `(단 X / Y 예외)`.
- `*_examples` / `*_calculus` (illustrative cases) → dropped, or moved to `<DOMAIN>.md` prose body.
- `authority` / `remedy` / `evidence` → dropped (the rule is its own authority; remedies/evidence live elsewhere).

**Scope**: applies **only to `@D :: governance` entries**. Other declarative types (`@I` identity, `@C` config, `@L` layout, `@X` external citation, `@F` forbidden, `@N` note, `@V` spec version) keep their open-key body form. The v1.2 Compactness invariants (≤ 500 chars · ≤ 5 fields · heredoc banned) continue to apply to those.

`@D :: decision` (decision events on `<DOMAIN>.log.tape`) is NOT governance and is unaffected — append-only event-stream tapes carry runtime `@D` events that record what was decided (with `why` / `proof` / etc.) and are out of scope.

**Enforcement**:

- `tape_absorb()` SHOULD reject `@D :: governance` with non-`{do, dont}` body keys (validator implementation pending — same status as v1.2 Compactness).
- Sidecar `wilson-minimal-keep` plugin (≥ 0.8.0) blocks `PreToolUse` Write/Edit/MultiEdit via its S5 signal — same hook surface as the existing S4 cap.

**Migration**: pre-v1.3 entries are **grandfathered until the next Write touches them**. A one-shot scrub recipe:

1. Backup the current `AGENTS.tape` to `archive/AGENTS-pre-v1.3-<date>.tape` (preserves history without violating the live cap).
2. Rewrite each `@D :: governance` entry in `do`/`dont` form, condensing exceptions into parentheticals.
3. Commit. PHILOSOPHY.tape retains the historical `why` context — no information is lost, only relocated.

A scrub that leaves *any* `@D :: governance` entry with a non-conforming key will be blocked by `wilson-minimal-keep` ≥ 0.8.0 on the next Write of the full file (S1 + S5 fire together).

## Governance tool annotation — `@D :: governance` body extended with `tool` / `usage` (v1.4 amendment, 2026-05-22)

> [!WARNING]
> **Reverted in v1.5** (see the next section). `tool` / `usage` were never authored in practice and are no longer valid `@D` body keys — the body is closed at `{do, dont}` again. This section is retained as a historical amendment record only; fold the canonical CLI into the `do` imperative instead.

v1.3 closed the body at `{do, dont}`. v1.4 ADDS two OPTIONAL keys for canonical CLI / tool annotation. The closed set is now `{do, dont, tool, usage}` — body-cap stays under the v1.2 general 5-fields-per-entry rule (4 keys max with all present).

| Field | Form | Use |
|---|---|---|
| `tool = "<name>"` | Single line · optional | Canonical CLI / tool / feature the rule references (e.g. `"hexa verify"`, `"pool"`, `"Monitor (Claude Code)"`). Omit when the rule is language-level / process-level and names no specific tool. |
| `usage = "<syntax>"` | Single line · optional | Canonical invocation syntax mirroring `--help` (e.g. `"hexa cloud {run\|nohup\|poll\|copy-to\|copy-from}"`, `"pool on <host> <cmd>"`). Omit when `tool` itself is the full invocation. |

Field order convention: `do`, `dont`, `tool`, `usage`.

**Rationale**: cross-project governance commons (`commons.tape` and equivalents) routinely reference specific CLI verbs (`hexa verify`, `pool`, `Monitor`). v1.3's strict do/dont closure forced the tool name inline in the `do` sentence — visually scannable but not machine-extractable. `tool = "..."` makes the canonical tool a first-class field that tooling (LSP hover, registry indexers, dashboard widgets) can read directly, and gives LLM attention an explicit anchor for which command to recommend.

**Worked example** (sidecar commons):

```tape
@D g8 := "runpod dispatch via hexa cloud" :: governance [required active]
  do    = "for runpod dispatch use hexa cloud (structured argv)"
  dont  = "raw `ssh` / `scp` for runpod"
  tool  = "hexa cloud"
  usage = "hexa cloud {run|nohup|poll|copy-to|copy-from}"

@D g9 := "pool CLI available" :: governance [active]
  do    = "use `pool` for host roster + remote exec"
  tool  = "pool"
  usage = "pool {list|add <host>|on <host> <cmd>|status|install tailscale}"
```

Both keys are optional and independent — a rule MAY use neither (e.g. `g1 := "ai-native"`), only `tool`, only `usage`, or both. Pre-v1.4 entries with just `do` / `dont` remain valid — fully backwards compatible. Enforced by `tape_absorb` (pending) and by sidecar `wilson-minimal-keep` ≥ 0.8.0 (S5 extended to recognize the two new keys).

## Governance body re-closed at {do, dont} · repeatable · `skill` / `glossary` kinds (v1.5 amendment, 2026-05-26)

v1.5 reconciles the spec with cross-project authoring practice (sidecar `commons.tape` · `project.tape` · every `SKILL.md` body). Three changes, all backwards compatible with v1.3.

**1. `tool` / `usage` reverted — body re-closed at `{do, dont}`.** The v1.4 amendment added optional `tool` / `usage` keys. In practice they were never authored (0 occurrences across the sidecar commons and all `SKILL.md` bodies), and the canonical CLI reads cleanly inline in the `do` imperative. v1.5 drops them — the `@D` body is closed at `{do, dont}`, exactly as v1.3. Fold the tool name into the directive:

```tape
# v1.4 (reverted):                          # v1.5 (canonical):
@D g8 := "runpod dispatch" :: governance     @D g8 := "runpod dispatch" :: governance
  do    = "use hexa cloud"                      do   = "runpod dispatch → `hexa cloud {run|nohup|poll|copy-to|copy-from}`"
  tool  = "hexa cloud"                          dont = "raw `ssh` / `scp` / `runpodctl`"
  usage = "hexa cloud {run|nohup|poll}"
```

**2. `do` / `dont` are repeatable — ordered directive lists.** v1.3 was read as "≤ 2 fields (one `do`, one `dont`)". v1.5 makes the intent explicit: a `@D` entry MAY carry **multiple** `do =` lines and **multiple** `dont =` lines. Each line is one imperative directive; lines sharing a key form an ordered list. There is no field-count cap on `do` / `dont` — the discipline is per-line length, not line count.

| Key | Cardinality | Form |
|---|---|---|
| `do = "<imperative>"` | 0..N (repeatable) | one directive per line — what MUST be done |
| `dont = "<imperative>"` | 0..N (repeatable) | one directive per line — what MUST NOT be done |

No other body key is permitted on a `@D` entry (`why` · `tool` · `usage` · `note` · `rule` · `apply` · … all rejected). Edges (`<-` · `@>` · `<:` · …) are not body keys and remain allowed.

**3. New declarative kinds — `:: skill` and `:: glossary`.** Two non-governance kinds carry the identical `{do, dont}` body and the same repeatable-line semantics:

| Kind | Placement | Use |
|---|---|---|
| `:: skill` | a `SKILL.md` body — one `@D <name> :: skill` block | the skill's do/dont contract (no per-skill prose / README) |
| `:: glossary` | a `@D <name> :: glossary` entry in a governance commons | non-Latin / phonetic term → canonical-command map (stall-prevention) |

Both are added to the open domain alphabet and follow rule 2.

**Per-value length discipline.** Each `do` / `dont` value SHOULD stay terse — ≤ ~100 chars. Overflow splits into another `do` / `dont` line rather than running long. Per-line discipline + repeatability naturally keeps an entry under v1.2's 500-char entry total.

**Enforcement.** Sidecar `tape-lint` (PreToolUse Edit/Write deny on any `*.tape`) enforces do/dont-only — any other body key denies the write — and, on `commons.tape` / `project.tape`, the ≤ 100-char-per-value cap. Diff-aware: pre-existing violations are grandfathered; only newly-introduced or worsened keys/lines block. No opt-out by design (no env var, no config, no exception list).

**Worked example** (sidecar commons `g61` — repeatable `do` / `dont`):

```tape
@D g61 := "hexa-lang stdlib is the SSOT for shared code" :: governance [required active]
  do   = "promote reusable general primitives (math/info/signal/bitops/stats) to hexa-lang `stdlib/`"
  do   = "≥2-repo reusable domain engine → `stdlib/<domain>/` (e.g. `consciousness/iit4` · `dsp`)"
  do   = "stdlib = plain `.hexa` · callers import-only (thin shim/adapter) · keep byte-equal"
  dont = "duplicate a primitive OR engine across repos · anima-locked abs-path import"
  dont = "compiler builtin when stdlib fits · hand-edit `hexa_cc.c` (use `hexa cc --regen`)"
```

`:: skill` body (a `SKILL.md`):

```tape
@D ship := "atomic ship tail for sidecar plugin changes" :: skill
  do   = "bump SemVer + lockstep all version surfaces FIRST · then `/ship -m <msg> <path>…`"
  dont = "`/ship` with `-A`/`-u` (explicit paths only) · skip the version bump or credential scan"
```

**4. `DOMAINS.tape` roster placement — `:: index` kind + `@domain` named type.** The sidecar `domain` plugin keeps a repo-root `DOMAINS.tape` that maps each domain NAME to its snapshot path (`<DOMAIN>.md`). It is a declarative, editable roster — NAME→path is authoritative; progress and `@goal` stay *derived* (read live from each snapshot), so the roster never churns. The format is a minimal tape dialect:

```tape
# DOMAINS.tape — domain roster (NAME → snapshot path; progress/goal stay derived)
@V := "domains" :: index

@domain BRAIN := "./BRAIN.md"
@domain AGENT := "./AGENT/AGENT.md"
```

- `@V := "domains" :: index` — header: subject `"domains"` (the format name), kind `:: index`. (The `@V` *subject* is informational; `:: index` is the placement marker.)
- `@domain <NAME> := "<relpath>"` — one roster row per domain. Trailing `# comment` is allowed. An optional `@title = "<display>"` sub-line may follow but is informational (the display title stays authoritative in the snapshot).

`@domain` is a **named (multi-character) entry type** — it sits OUTSIDE the closed-17 single-letter alphabet on purpose. The closed alphabet guarantees tractability for *runtime* consumers (replay / audit / promotion adapters); a `:: index` roster is config-like, never replayed, so a placement-local named type is safe and a conformant reader skip-not-rejects it per the forward-compatibility rule. Named entry types are permitted ONLY in `:: index` placements; runtime / foundation / declarative tapes stay closed at the 17-letter alphabet.

> `@goal:` and `@title:` (colon form) are MARKDOWN line-markers inside a `<DOMAIN>.md` snapshot — the final-goal north-star and optional display header. They are not `.tape` entries (note the `:` vs the `:=` of a tape header) and are parsed by the `domain` plugin, not `tape_absorb`.

## `CLAIMS.tape` + `NEXUS.tape` declarative placements (v1.6 amendment, 2026-05-26)

A survey of two production repos (anima, demiurge) surfaced two more repo-root declarative placements, both built from the **existing** type alphabet (no new types) and the open domain alphabet. v1.6 documents them and ratifies the open grade tag-bag (see §Grade markers) they rely on.

### `CLAIMS.tape` — verifiable-claim index (`@C :: formula`)

A single audit index of a repo's verifiable claims, each routed claim → `hexa verify` (g5) → `.verdicts/<slug>/<id>.txt` → `/paper` gate. One `@C <id> :: formula` per claim; body keys are free-form (the `@D`-only `{do, dont}` restriction does NOT apply to `@C`).

```tape
@V := "tape" :: spec
  version = "1.6"

@I := "claims-index" :: identity [active]
  brief = "Single audit index of verifiable claims."

@C chat_init_ce_floor := "init_CE floor = ln(151936) = 11.931… (untrained CLM lower bound)" :: formula [slug=chat-init-ce-floor group=CHAT]
  method = "expr"
  cmd    = "hexa verify --expr ln 151936 11.931"
  raw    = ".verdicts/chat-init-ce-floor/chat_init_ce_floor.txt"
  src    = "HEXAD/LIFE/H_247_init_ce_catastrophic_floor.md §C4"
```

`slug=` / `group=` are open grade tags (§Grade markers). The verdict surface is the repo's own typed records — `tape_absorb` does not adjudicate truth (that is `hexa verify`).

### `NEXUS.tape` — intra-project reuse lattice (`@X :: reuse-edge`)

The repo-root reuse graph mandated by sidecar commons `@D g67` — nodes are domains, edges are *verified* primitive/discovery reuse between sibling domains (intra-project only; the hexa-lang stdlib/atlas hub is the one cross-project link, g68). Built from `@X` (external-citation / declarative) with free-form body — the author deliberately uses `@X` precisely because the `@D` do/dont closure does not bind it.

```tape
@V := "tape" :: spec
  version = "1.6"

@I nexus := "intra-project reuse lattice" :: identity [active]
  scope = "intra-project ONLY — never link domains across repos (@D g67)"

@X e1 := "NOVEL-TOOL current_loop_offaxis -> RTSC" :: reuse-edge [tier-2 active]
  provides  = "NOVEL-TOOL M2.4"
  primitive = "current_loop_offaxis (elliptic K/E on-axis B Green fn)"
  reused_by = "RTSC"
  evidence  = "PR #900 -> #168"

@X p1 := "RTSC provides[]" :: provides [active]
  primitives = "Wheeler on-axis B verifier · getdp solenoid templates"

@X c1 := "ANTIMATTER -> HEXA-GRAV (proposed)" :: reuse-candidate [draft]
```

Three kinds: `reuse-edge` (a verified edge), `provides` (a domain's offered-primitive registry), `reuse-candidate` (a proposed, not-yet-realized edge). `tier-N` is an open grade tag for the reuse/verification tier.

### Named (multi-char) types stay scoped

Neither placement adds a named entry type — both reuse `@C` / `@X` / `@I`. The only blessed named type remains `@domain` (`:: index`, v1.5). Loose forms seen in archive ledgers (e.g. `@verdict_<slug> :=` in `archive/PHILOSOPHY.tape`, where type and id are not separated) are **non-conforming** and grandfathered as history — do not author new ones; use `@D … :: verdict-tier` or `@X` instead.

## Project-tree convention (v1.2 — for `AGENTS.tape` ecosystem)

Each `AGENTS.tape`'s top-level `@I id001` (the repo identity) carries tree-edge fields that let an algorithm (`tape_walk_tree`) crawl every `~/core/*/AGENTS.tape` and emit an aggregate project tree as a *derived view*. SSOT stays per-repo; the tree is computed.

### `@I id001` enhanced schema

```tape
@I id001 := "<repo-name>" :: identity-claim [d=<YYYY-MM-DD> active]
  kind     = "<emoji + 1-line classification>"        # required (e.g. "🔥 HEXA-Fusion family — fusion · plasma")
  brief    = "<1-line plain description>"             # required (e.g. "fusion physics standalone · 12 reactor closures · 122/122 EXACT")
  parent   = "dancinlab/<parent-repo>" | "dancinlab"  # required (org-root or another repo)
  siblings = [<repo>, <repo>, ...]                     # optional (peers under the same parent)
```

`parent` rules:
- Domain-family standalones extracted from echoes (hexa-fusion · hexa-chip · hexa-mind · …) → `"dancinlab/echoes"`
- Sibling formats (n6 · hxc · n12 · tape) → `"dancinlab"` (org-root)
- Sub-projects with a clearly-named parent (anima/hexa-senses · anima/anima-experience · echoes/echoes-experience) → `"dancinlab/<parent>"`
- All other dancinlab repos → `"dancinlab"`

### `tape_walk_tree` algorithm (`algorithms/tape_walk_tree.hexa`)

Input: a directory glob (default `~/core/*/AGENTS.tape`).

Output: a tree rendered as nested markdown bullets (or `@L` layout block for embedding in another tape). Steps:

1. Scan all matching `AGENTS.tape` files.
2. For each, extract the first `@I id001` block (header + body keys: `kind` · `brief` · `parent` · `siblings`).
3. Build adjacency map keyed by `parent`.
4. Render top-down starting from `"dancinlab"` root, recursing through children sorted alphabetically.
5. Each node prints as `<emoji-from-kind> <repo> — <brief>`.

Example render:

```
dancinlab/
├── 💎 hexa-lang — native compiler with atlas-bound theorems
├── 🪞 echoes — discoveries catalog · LATTICE_POLICY home
│   ├── 🔥 hexa-fusion — fusion physics · 12 reactor closures
│   ├── 💻 hexa-chip — semiconductor architecture · 6 stages
│   ├── … (17 domain families)
│   └── 🪞 echoes-experience — σφτ interactive proof HF Space
├── 🏐 wilson — hexa-native AI coding agent · 28-plugin bundle
├── 🧠 anima — Living Consciousness Agent
│   ├── ✨ anima-experience — MI visualizer HF Space
│   └── 👁️ hexa-senses — 5-verb sensory substrate
├── 🏛 hexa-scale — multi-scale architecture (6×4=24 lattice)
├── ⊳ tape — Agent-Execution Trace spec
├── ⬢ n6 — semantic atom layer
├── ⬡ hxc — byte-canonical wire
├── ⬨ n12 — 12-axis sparse cube
└── … (other apps, tools, archives)
```

### Cross-file references

Tape edges (`<:` `:>` `<-` etc.) are within-file only per §"Edge operators". Cross-file parent edges use the `parent = "<string>"` payload key, which `tape_walk_tree` treats as a graph edge. For richer cross-references (URLs · DOIs · papers · vendor docs), use `@X external-citation`.

### Drift avoidance

- SSOT is per-repo (each AGENTS.tape carries its own `@I id001`); no atlas-level master file.
- A CI job (`tape_walk_tree --check`) can compare current per-repo `parent`/`siblings` claims against a golden tree to catch typos.
- New repos automatically appear in the tree after their first `AGENTS.tape` ships with `parent = "..."`.

## Versioning

- **v1** (2026-05-13) — 10 types · 7 edges · 5 delivery markers · open domain alphabet. Single placement (per-session tape).
- **v1.1** (2026-05-13) — 11 types (adds `@I` identity) · 7 edges (unchanged) · 6 grade markers (adds `superseded` for `@I`) · open domain alphabet extended with `identity` / `meta-domain` / `atlas`. Five placements (per-session, identity singleton, recap index, per-domain, cross-project atlas). Adds 4 algorithms: `tape_render_identity`, `tape_to_md_log`, `tape_meta_verify`, `tape_domain_status`.
- **v1.2** (this spec, 2026-05-14) — 17 types (adds `@X` external-citation, `@F` forbidden-pattern, `@N` note, `@C` config, `@L` layout, `@V` spec-version) · 12 edges (adds `<:` specializes, `:>` generalizes, `?>` soft-depends, `!>` conflicts-with, `@>` projects-to) · governance grade tags (`required` / `recommended` / `optional` / `draft` / `active` / `deprecated` / `allow:<x>` / `deny:<x>`) · payload-syntax extensions (heredoc / array literal / `[@id]` inline citation / backtick code-span) · grammar primer header convention · `AGENTS.tape` pattern (replaces `AGENTS.md` cross-project). Adds 1 algorithm: `tape_to_agents_md` (fallback markdown generator).
- **v1.2 amendment** (2026-05-20) — Compactness invariants for declarative entries (`AGENTS.tape` / `identity.tape` / `<DOMAIN>.tape`): per-entry ≤ 500 chars · field values must be 1 line (heredoc banned in declarative tapes) · ≤ 5 fields per entry. CJK and Latin glyphs counted identically (1 glyph = 1 char). Append-only event-stream tapes (`<sid>.tape` / `<DOMAIN>.log.tape`) are unaffected. Enforced by `tape_absorb` (warning-grade, pending) and by sidecar `wilson-minimal-keep` ≥ 0.6.0 (PreToolUse block).
- **v1.3 amendment** (2026-05-20) — Governance imperative for `@D :: governance` entries: body keys closed at `{do, dont}` only · ≤ 2 fields. Size stays under v1.2's general 500-char cap (no separate v1.3 size threshold). Other declarative types unaffected. Pre-v1.3 entries grandfathered until next Write. Enforced by `tape_absorb` (pending) and by sidecar `wilson-minimal-keep` ≥ 0.8.0 (PreToolUse S5 block).
- **v1.4 amendment** (2026-05-22) — Governance tool annotation: `@D :: governance` body opens up two OPTIONAL keys — `tool = "<name>"` (canonical CLI / tool the rule references) and `usage = "<syntax>"` (one-line invocation form). Closed set extended to `{do, dont, tool, usage}`; body still under v1.2's ≤ 5 field cap. **Reverted in v1.5** — never authored in practice.
- **v1.5 amendment** (2026-05-26) — Governance body reconciled with practice: (1) `tool` / `usage` reverted — `@D` body re-closed at `{do, dont}` (fold the CLI into the `do` imperative); (2) `do` / `dont` are **repeatable** — an entry may carry multiple `do =` / `dont =` lines, each one ordered directive, no field-count cap (per-line ≤ ~100 char discipline instead); (3) two new declarative `@D` kinds — `:: skill` (`SKILL.md` body) and `:: glossary` (term→canonical-command map) — carry the identical `{do, dont}` repeatable body; (4) `DOMAINS.tape` roster placement — `@V :: index` header + `@domain <NAME> := "<relpath>"` rows, introducing the `:: index` kind and the first named (multi-character) entry type, permitted only in `:: index` placements (runtime/foundation/declarative stay closed at 17). Enforced by sidecar `tape-lint` (PreToolUse deny, do/dont-only + 100-char cap, diff-aware, no opt-out). Backwards compatible with v1.3.
- **v1.6 amendment** (2026-05-26) — Two more repo-root declarative placements documented from production survey (anima, demiurge), both built on existing types: `CLAIMS.tape` (`@C :: formula` verifiable-claim index → `hexa verify` → `/paper` gate) and `NEXUS.tape` (`@X :: reuse-edge / provides / reuse-candidate` intra-project reuse lattice, commons `@D g67`). Grade bracket ratified as an OPEN tag-bag: standardized tags keep fixed semantics, domain-specific tags (bare `tier-2` / `paper-track`, or `key=value` `slug=` / `group=`) are skip-not-reject. Domain alphabet noted as genuinely open (110+ tags observed). No new entry types; `@verdict_<slug>` archive looseness flagged non-conforming (grandfathered). Backwards compatible.
- **v2** (reserved) — anticipated additions: structured payload on `@K` (per-model token breakdown); binary attachment side-car (analog of wilson's `_attachments` for `@R` lines pointing to images / files); n6-style verification-grade overlay for adapters that need it.

Forward-compatibility rule: a v1.1 reader MUST skip any header line whose `<type>` is not in the v1.1 alphabet of {S, U, A, T, R, H, D, K, P, I, ?} rather than reject. Edge operators outside the v1 set of {`<-`, `->`, `=>`, `==`, `~>`, `\|>`, `!!`} MUST also be skipped rather than rejected. v1 readers encountering an `@I` line MUST skip-not-reject per the same rule. v1.1 readers encountering v1.2 types `{X, F, N, C, L, V}` or v1.2 edges `{<:, :>, ?>, !>, @>}` MUST skip-not-reject per the same rule.

## Cross-references

- [`n6`](https://github.com/dancinlab/n6) — sister semantic atlas
- [`hxc`](https://github.com/dancinlab/hxc) — sister byte-canonical wire
- `n12` — sister multidimensional cube (private at `dancinlab/n12`)
- `algorithms/` — reference hexa-lang modules for guarded append, replay, grep, health check, compaction, indexing, dedup, KV-cache probe, JSONL adapter, n6 / hxc / n12 promotion stubs
- `docs/DESIGN.md` — design rationale: why a 4th sibling, why typed events not raw JSONL, why provenance edges
