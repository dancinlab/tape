#!/usr/bin/env tape
# ══════════════════════════════════════════════════════════════
# Example: HARNESS.tape — per-domain history (v1.1)
#
# Sibling of HARNESS.md (governance principle #4 domain-meta-domain).
# The `## Log` section of HARNESS.md is auto-rendered from this tape
# via `tape_to_md_log HARNESS.md HARNESS.tape 20`.
# Append via git pre-commit hook (path→domain map) or manually.
# ══════════════════════════════════════════════════════════════

# ── 조건 (referenced by `## Conditions` head section) ─────────

@D c1 := "harness.input_loop" :: harness [d=2026-05-12 ok]
  text = "wilson -p / interactive TUI claims input loop"
  proof = "plugins/harness-cli/main.hexa::harness_cli_activate"

@D c2 := "harness.streaming" :: harness [d=2026-05-12 ok]
  text = "streaming render via host_render(...streaming, delta)"
  proof = "core/agent_loop.hexa::_stream_loop"
  |> commit b3706a1

# ── 변경 이력 (commit-driven via git pre-commit hook) ─────────

@A commit_b3706a1 :: harness [d=2026-05-12 ok]
  <- c1, c2
  => "TUI raw-mode + alt-screen lands"

@A commit_184cbc1 :: harness [d=2026-05-13 ok]
  <- commit_b3706a1
  => "ToolResult out-of-band handoff — agent loop returns {assistant, tool_results}"

@A commit_92004fa :: harness [d=2026-05-13 ok]
  <- commit_184cbc1
  => "bidi-stdio primitive unlocks real MCP JSON-RPC client"

@A commit_d916009 :: harness [d=2026-05-13 ok]
  <- commit_92004fa
  => "wilson build → build/<host>-<arch>/wilson per-host (stale-shadowing fix)"

# ── 다음 (planned) ────────────────────────────────────────────

@T plan_shift_enter :: harness [d=2026-05-13 ok]
  <- commit_d916009
  => "Shift+Enter / Alt+Enter multi-line input (deferred to next branch)"
