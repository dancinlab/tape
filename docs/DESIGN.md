# `.tape` — design notes

> Why a 4th sibling? Why typed events instead of raw JSONL? Why provenance edges? Why the promotion-target sibling pattern? Recorded 2026-05-13 alongside the v1 spec.

## Position table — four siblings

The four-format quartet partitions the agent-system data plane along **four orthogonal axes**:

| Sibling | Layer | Time | Mutability | What it answers |
|---|---|---|---|---|
| [`n6`](https://github.com/dancinlab/n6) | semantic | atemporal | append + dedup | "What do we know?" |
| [`hxc`](https://github.com/dancinlab/hxc) | byte-canonical wire | atemporal | content-addressed | "How do we ship it?" |
| `n12` | multidimensional cube | atemporal aggregate | overwrite cells | "How do we measure it?" |
| **`tape`** | **operational / causal-temporal** | **strictly ordered** | **append-only** | **"What did the agent do?"** |

The four are complementary: `.tape` records the runtime trace, then `tape_to_n6` extracts verified facts, `tape_to_hxc` ships the trace cross-host with byte-canonical KV-cache stability, `tape_to_n12` populates measurement-cube coordinates. None of the three siblings can replace `.tape` because none of them is *causally ordered* — they answer time-independent questions about a corpus, not the time-sequence of one execution.

## Why typed events — not raw JSONL?

Wilson's harness today writes **five `.jsonl` surfaces** (`harness-cli/sessions/*.transcript.jsonl`, `recap/*.jsonl`, `recap/index.jsonl`, `cost/*.jsonl`, `tasks/tasks.jsonl`). A cargo audit of these surfaces showed:

1. **Schema drift.** Each `.jsonl` evolved independently. `recap/*.jsonl`'s `turn` field is 1-indexed; `cost/*.jsonl`'s is 0-indexed. The `transcript.jsonl`'s `role` is one of `user`/`assistant`/`tool`/`system`; `recap`'s `kind` is unrelated. Consumers re-learn each schema.
2. **Triple-counting.** A single tool call writes to `transcript.jsonl` (call + result), to `cost/*.jsonl` (token sample), and *sometimes* to `tasks/tasks.jsonl` (if the call was `task_add`). Reconciling the three views by `turn` index is fragile.
3. **`@observe`-driven, not principled.** Each surface was added when someone wanted to observe a new thing — the data plane grew by accretion, not by design. There's no answer to "where does an MCP server start event go?" — currently nowhere structured.
4. **No causal edges.** JSONL is a linear log. To answer "what tool produced this assistant turn's content?" you read a window and match by timing — a guess, not a certainty.

`.tape`'s response to each:

1. **Closed type alphabet (10).** Every runtime category maps to one of `S/U/A/T/R/H/D/K/P/?`. New runtime categories extend an existing type's domain tag (e.g. MCP server start = `@P claude-cli` with `domain=mcp`), not the alphabet.
2. **One record per logical event.** A tool call writes one `@T` + one `@D` + one `@R` + at most one `@K`. The three triple-counted views (transcript + cost + tasks) are *derived projections* via `tape_export_jsonl --kind=...`.
3. **Schema-validated append.** `tape_absorb()` checks header well-formedness + type-grade compatibility + dangling-edge resolution before write. No accretion path; every entry is a typed event.
4. **Provenance edges as first-class.** The 7 edge operators (`<-` / `->` / `=>` / `==` / `~>` / `\|>` / `!!`) express causal structure inline. "Which tool result did assistant turn `a042` consume?" → `grep '^@A a042' -A 5 | grep '<- r'`. Direct.

## Why provenance edges (causal replay > linear log)?

The n6 sister format taught a lesson: a **typed-and-edged** atlas is qualitatively more useful than a typed-only one. n6's 7 edge operators (`<-` depends_on, `->` derives, `=>` application, `==` equivalent, `~>` converges, `|>` verified_by, `!!` breakthrough) let a query engine answer ancestor / descendant / verified-core questions by `grep + recursive resolve`, without a graph database.

`.tape` borrows the **same shapes** with runtime semantics:

| n6 | tape | Shape preserved |
|---|---|---|
| `<-` depends_on | `<-` caused_by | "what came before" |
| `->` derives | `->` triggers | "what comes after" |
| `=>` application | `=>` produces | natural-language effect |
| `==` equivalent | `==` continues | identity / continuation |
| `~>` converges | `~>` supersedes | targeted state-change |
| `\|>` verified_by | `\|>` verified_by | validation pass |
| `!!` breakthrough | `!!` aborts | exceptional event |

Same 7 sigils, ported from semantic-graph use to causal-trace use. This makes the format learnable for anyone fluent in `.n6`; it also means `tape_to_n6` is a near-mechanical sigil-preserving projection rather than an alphabet conversion.

## KV-cache stability — the byte-canonical property

A practical motivation: when an agent resumes a session, the provider's KV cache hits **only if the re-submitted message-history bytes are identical** to what was originally streamed. JSONL fails this in subtle ways — JSON formatters re-order keys, escape strings differently, or drop nulls. `.tape` is byte-canonical by construction: same logical event → same bytes. `tape_kv_probe` is a small verifier that takes a tape, simulates a resume, and asserts `bytes_eq(original, replayed)`.

This is why the tape grammar is *line-oriented* (one record = one block of column-0 header + 2-space-indented continuations) rather than nested: a line-oriented format has trivial byte-canonical normalisation (UTF-8, LF, exact two-space indent, no trailing whitespace) — properties the CI workflow checks.

## Why one tape per session, not one per agent run?

A wilson session may span multiple `wilson` invocations (resume across days). A single `<session_id>.tape` is *opened in O_APPEND* on each resume; every event from every invocation lands in one file. This keeps the causal chain intact across resumes — `@S resume == s001` continuation edges express the temporal break without splitting the file.

Cross-session aggregation (e.g. "what did wilson do this week") is a query, not a storage decision: `cat *.tape | grep '^@T'` etc.

## Promotion-target sibling pattern

The general pattern: **runtime layer is verbose + cheap + lossy-OK; semantic / wire / cube layers are curated + canonical + lossless**. `.tape` records everything that happened, no matter how small or trivial; promotion to a sibling is a deliberate curation step driven by a domain-specific criterion:

- `.tape` → `.n6`: an `@R [ok]` whose content encodes a stable, generalisable fact. Most `@R` lines never promote; the few that do (e.g. "wilson supports 28 plugins as of build X") become typed atoms with grade markers.
- `.tape` → `.hxc`: a tape (or tape slice) being shipped cross-host. The HXC v2 byte-canonical wrap preserves KV-cache stability for the receiving host's provider cache.
- `.tape` → `.n12`: aggregate metrics — turns-per-session, denial-rate-by-domain, cost-by-provider — populate sparse cube cells. No individual `.tape` row promotes; an aggregator does.

This pattern is the inverse of the "build a god-schema upfront" anti-pattern: instead of one schema that's correct for all four use-cases, four schemas each optimised for its layer, with explicit one-way adapters between them.

## Open questions (v2 scope)

- `@M` memory events. Currently subsumed into `@T memory_*` via `tool-core`'s memory family. Decide whether memory deserves its own type (and the bookkeeping cost) or whether the tool-typing is sufficient.
- Per-model token breakdown on `@K`. The v1 form is `in+out+cache = total ucents`; multi-provider sessions may need `<model_id>:in+out+cache`.
- Binary side-car. Wilson's `_attachments` (multimodal v2) currently round-trips inline base64 in the `@R` content. A `.tape.attach/` sidecar directory with content-addressed payloads + path references would keep the tape line-oriented.
- n6-grade overlay. For tape entries that promote to `.n6`, an in-tape grade marker (`[T2 N48 ok | 9*]`?) lets `tape_to_n6` skip the manual grade-assignment step.

None are blocking for v1. v2 ships when ≥ 3 of these are validated against a real wilson workload.
