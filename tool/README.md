# `.tape` operational tools

The current toolchain lives entirely in the [`algorithms/`](../algorithms/) directory as hexa-lang modules — there is no separate dispatcher / linter / replay CLI yet (the [`hxc` repo](https://github.com/dancinlab/hxc) ships its toolchain alongside the algorithms; `.tape` follows the [`n6`](https://github.com/dancinlab/n6) shape of keeping the per-module CLIs self-sufficient).

## Landed

- **`markers_to_tape.hexa`** — convert a hexa-hook `state/markers/*.marker` directory tree into a single canonical `.tape` file. Each marker → one `@T <check>_<ts> :: <domain> [d=<iso> <grade>]` row; `_FAILED` / `_PENDING` / `_ERR` filename suffixes map to delivery grades. Honors `.PRESERVE-AS-SSOT` sentinels (skips DESIGN ledgers). Selftest covers happy-path + 3 suffix grades + malformed + idempotency. `hexa run tool/markers_to_tape.hexa --selftest`.

## Planned

- `tape_lint.hexa` — byte-canonical invariant linter (UTF-8 / LF / column-0 anchors / 2-space indent / no trailing whitespace / closed type alphabet)
- `tape_replay_cli.hexa` — replay a tape into `[Message]` for agent-loop resume (wraps `tape_replay`)
- `tape_grade_audit.hexa` — per-session delivery-state histogram (`ok` / `err` / `denied` / `cancelled` / `partial` rates by domain)
- `tape_promote.hexa` — dispatcher for `tape_to_n6` / `tape_to_hxc` / `tape_to_n12` with promotion-criterion flags
- `tape_diff.hexa` — KV-cache-aware diff between two tapes (preserve byte-prefix invariance, flag drift)

Until those land, the per-module CLIs under `algorithms/` plus `markers_to_tape` cover the operational surface — see [`algorithms/README.md`](../algorithms/README.md).
