## Examples

| File | Demonstrates |
|---|---|
| `01_basic_session.tape` | `@S start` / `@U` / `@A` / `@T` / `@D allow` / `@R` / `@K` / `@S end` — minimal valid session |
| `02_tool_chain.tape` | Multi-tool fan-out — one `@A` produces 3 `@T`, each with its own `@D` + `@R`; aggregated via `<- r001, r002, r003` multi-id edge |
| `03_governance_deny.tape` | `@D deny` blocks a `@T`; `@? abort001` carries `!! t001` abort edge; `[denied]` grade |
| `04_resume_replay.tape` | `@S resume == s001` continuation edge — how `tape_replay` reconstructs `[Message]` for the agent loop |
| `05_identity.tape` (v1.1) | `~/.wilson/identity.tape` SSOT — six `@I` events covering WHO / WHAT / WHENCE / WHY / WHEN dimensions; `tape_render_identity` projects this into wilson's `## Identity` system-prompt block |
| `06_domain_log.tape` (v1.1) | `<DOMAIN>.tape` sibling of `HARNESS.md` — `@D c1/c2` condition declarations + `@A commit_*` history events; rendered into `## Log` AUTO-RENDER fence by `tape_to_md_log` |
| `07_meta_domain.tape` (v1.1) | `<D1+D2+D3>.tape` for `HARNESS+TOOL+PROVIDER.md` — five Cn + one Mm joint condition; `tape_meta_verify` walks the constituents and emits a held/violated matrix |

All examples are valid `.tape` v1.1:

- UTF-8, no BOM, LF line endings
- Headers at column 0, edges indented two spaces
- One event per `@<type>` block; multiple edges allowed per event
- Delivery state + indices in trailing `[...]`

See [`../spec/tape.md`](../spec/tape.md) for the full grammar.

## Quick grep cookbook

```bash
# every tool invocation
grep '^@T ' *.tape

# every governance denial
grep '^@D .* \[.*denied' *.tape

# every anomaly / abort
grep '^@? ' *.tape

# every cost sample
grep '^@K ' *.tape

# everything in turn 2 of a session
grep '^@.*\[T2 ' s001.tape

# session boundaries
grep '^@S ' *.tape

# what got verified-by something (governance ok / hook ok / result ok)
grep '^  |> ' *.tape

# every identity claim (v1.1)
grep '^@I ' identity.tape

# every meta-domain Cn / Mm condition (v1.1)
grep '^@D .* :: meta-domain' *.tape

# every superseded claim (replaced by a later @I)
grep '^@I .* superseded' identity.tape
```
