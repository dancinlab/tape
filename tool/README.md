# `.tape` operational tools

The current toolchain lives entirely in the [`algorithms/`](../algorithms/) directory as hexa-lang modules — there is no separate dispatcher / linter / replay CLI yet (the [`hxc` repo](https://github.com/dancinlab/hxc) ships its toolchain alongside the algorithms; `.tape` follows the [`n6`](https://github.com/dancinlab/n6) shape of keeping the per-module CLIs self-sufficient).

Tool layer items planned for a future cycle:

- `tape_lint.hexa` — byte-canonical invariant linter (UTF-8 / LF / column-0 anchors / 2-space indent / no trailing whitespace / closed type alphabet)
- `tape_replay_cli.hexa` — replay a tape into `[Message]` for agent-loop resume (wraps `tape_replay`)
- `tape_grade_audit.hexa` — per-session delivery-state histogram (`ok` / `err` / `denied` / `cancelled` / `partial` rates by domain)
- `tape_promote.hexa` — dispatcher for `tape_to_n6` / `tape_to_hxc` / `tape_to_n12` with promotion-criterion flags
- `tape_diff.hexa` — KV-cache-aware diff between two tapes (preserve byte-prefix invariance, flag drift)

Until those land, the per-module CLIs under `algorithms/` cover the operational surface — see [`algorithms/README.md`](../algorithms/README.md).
