<p align="center">
  <img src="docs/logo.svg" width="140" alt="tape">
</p>

<h1 align="center">⊳ tape</h1>

<p align="center"><strong>Agent-Execution Trace</strong> — typed events · provenance edges · delivery grade · append-only</p>

<p align="center">
  <a href="LICENSE"><img alt="License" src="https://img.shields.io/badge/license-CC0--1.0-blue"></a>
  <a href=".github/workflows/lint.yml"><img alt="CI" src="https://github.com/dancinlab/tape/actions/workflows/lint.yml/badge.svg"></a>
  <img alt="Spec" src="https://img.shields.io/badge/spec-v1.1-success">
  <img alt="Types" src="https://img.shields.io/badge/types-11-informational">
  <img alt="Edges" src="https://img.shields.io/badge/edges-7-informational">
  <img alt="Placements" src="https://img.shields.io/badge/placements-5-informational">
  <img alt="Sibling" src="https://img.shields.io/badge/sibling-n6%20·%20hxc%20·%20n12-blueviolet">
</p>

<p align="center">Append-only · line-oriented · grep-friendly · type-graded · provenance-edged · KV-cache-stable</p>

---

`.tape` is an agent-execution trace grammar: each entry is a typed event — runtime (session, user, assistant, tool call, tool result, hook, decision, cost, provider, anomaly) OR foundational identity claim — carrying provenance edges (caused_by, triggers, produces, continues, supersedes, verified_by, aborts) and a delivery-state grade (`ok` / `err` / `denied` / `cancelled` / `partial` / `superseded` plus turn / wall-clock / date indices).

> [!NOTE]
> Fourth sibling of [`n6`](https://github.com/dancinlab/n6) (semantic / atlas layer), [`hxc`](https://github.com/dancinlab/hxc) (byte-canonical wire), and `n12` (12-axis sparse cube). `.tape` is the **operational / causal-temporal** layer — what the agent did, in order, with what edges. The three siblings are *promotion targets* for refined / published data extracted from a tape.

## At a glance

```ruby
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

@S end :: session [T2 N53 ok]
  ~> s001
```

- `@<type> <id> [= <expr>] :: <domain> [<grade>]` — entry header
- Edges indented 2 spaces, prefixed by one of `<-` `->` `=>` `==` `~>` `|>` `!!`
- Delivery grade markers: `ok` · `err` · `denied` · `cancelled` · `partial`; composable with `T<n>` (turn) and `N<n>` (wall-clock seconds since session start)

See [`examples/`](examples/) for more, [`spec/tape.md`](spec/tape.md) for the full grammar.

## Why tape

Wilson's runtime instrumentation today is scattered across **five `.jsonl` surfaces**: transcript, recap, recap-index, cost ledger, task list. Each grew independently as an `@observe`-driven ledger; together they triple-count effects, drift schema, and force ad-hoc consumers per surface.

`.tape` collapses the five into **one typed grammar** with a fixed type alphabet (10), a fixed edge alphabet (7), and a byte-canonical append rule. Because every byte-prefix is a valid partial parse, an LLM re-reading a tape on session resume hits the **provider KV-cache** byte-for-byte — no re-tokenisation tax. `grep '^@T.*\[denied\]' s001.tape` answers "what did governance block in this session" in one read.

The promotion sibling pattern decouples **what was done** (`.tape`, append-only, every event) from **what is known** (`.n6`, verified atoms, semantic), from **how it's shipped** (`.hxc`, byte-canonical wire), from **how it's measured** (`.n12`, sparse cube). A tape adapter (`tape_to_n6`, `tape_to_hxc`, `tape_to_n12`) refines a runtime trace into each promoted form when criteria are met.

## Status

- v1.1 spec live (2026-05-13) — adds `@I` identity type + 5-placement matrix (per-session, identity singleton, recap index, per-domain, cross-project atlas)
- 11 types · 7 edges · 6 delivery-state markers · open domain alphabet
- 16 reference hexa-lang algorithms (`algorithms/`) — v1 catalog + `tape_render_identity` / `tape_to_md_log` / `tape_meta_verify` / `tape_domain_status`
- TextMate grammar shipped (`syntaxes/tape.tmLanguage.json`)
- Wilson integration: reference adapters mapped in [`spec/tape.md`](spec/tape.md#reference-adapters-wilson-plugin-surface-mapping) and [`spec/tape.md#placement-matrix-v11`](spec/tape.md#placement-matrix-v11); plugin landing TBD

> [!IMPORTANT]
> All writes go through `tape_absorb()` (schema check + dangling-edge check). The append path is the safety-critical surface — see [`algorithms/tape_absorb.hexa`](algorithms/tape_absorb.hexa).

## Type alphabet

| Type | Meaning | Wilson source |
|---|---|---|
| `@S` | Session boundary — start / resume / end / cancel | `harness-cli` session lifecycle |
| `@U` | User input — `Message{role=user}` | `harness-cli` stdin |
| `@A` | Assistant reply — `Message{role=assistant}` | `agent_loop` provider result |
| `@T` | Tool invocation — `host_plugin_call(owner, "invoke", ...)` | `agent_loop` tool dispatch |
| `@R` | Tool result — `ToolResult{content, is_error, _attachments}` | `agent_loop` tool return |
| `@H` | Hook fire — `event_name@phase`, with priority | `event_bus.dispatch` |
| `@D` | Decision — governance verdict (allow / deny + reason) | `governance` plugin |
| `@K` | Cost sample — tokens + ucents | `cost` plugin |
| `@P` | Provider event — open / close / stream-delta | provider plugins |
| `@?` | Anomaly — error / abort / rate-limit / panic | any |
| `@I` | Identity claim — foundational (birth / scope / principle / version / succession) | wilson `core/main.hexa::_identity_block`, `hexa build` post-step |

Full grammar → [`spec/tape.md`](spec/tape.md).

## Five placements

| Placement | What | Singleton / per-X |
|---|---|---|
| `~/.wilson/identity.tape` | agent identity SSOT (replaces hard-coded `_identity_block()`) | **singleton** |
| `~/.wilson/harness-cli/sessions/<sid>.tape` | per-session conversation events | per-session |
| `~/.wilson/recap/index.tape` | session pointer index | singleton |
| `~/core/<repo>/<DOMAIN>.tape` | per-domain history (sibling of `<DOMAIN>.md`) | per-domain |
| `~/core/atlas/<PROJ>::<DOMAIN>.tape` | cross-project federated history (governance #4 `domain-meta-domain`) | per-cross-domain |

All five share the same grammar, validator (`tape_absorb`), and algorithm catalog. See [`spec/tape.md#placement-matrix-v11`](spec/tape.md).

## Editor support

`.tape` is not yet a registered language on [github/linguist](https://github.com/github-linguist/linguist). The repo ships a TextMate grammar — see [`syntaxes/README.md`](syntaxes/README.md) for VS Code / Sublime / TextMate install steps.

## Repo layout

```
tape/
├── README.md
├── LICENSE                       CC0-1.0
├── spec/
│   └── tape.md                   v1 grammar
├── examples/                     valid .tape samples
├── algorithms/                   16 hexa-lang reference modules
├── tool/                         planned lint / replay / grade-audit CLIs
├── syntaxes/
│   └── tape.tmLanguage.json      TextMate grammar
├── docs/
│   ├── INDEX.md                  doc index
│   ├── DESIGN.md                 why a 4th sibling · why typed events
│   └── logo.svg                  hexagon + tape glyph
└── .github/workflows/
    └── lint.yml                  byte-canonical + entry-header invariant CI
```

## License

[CC0-1.0](LICENSE) — public domain. Use freely.
