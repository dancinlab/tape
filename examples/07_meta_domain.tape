#!/usr/bin/env tape
# ══════════════════════════════════════════════════════════════
# Example: HARNESS+TOOL+PROVIDER.tape — meta-domain joint condition (v1.1)
#
# Sibling of HARNESS+TOOL+PROVIDER.md (governance #4 meta-domain).
# Wilson's "minimal viable agent" meta-domain — held iff all five
# constituent conditions plus the joint M1 are evidenced in the tape.
# Verify via `tape_meta_verify HARNESS+TOOL+PROVIDER.md HARNESS+TOOL+PROVIDER.tape`.
# ══════════════════════════════════════════════════════════════

# ── 구성요소 조건 (Cn) ────────────────────────────────────────

@D c1 := "harness.input_loop" :: meta-domain [d=2026-05-13 ok]
  text = "wilson -p / interactive TUI claims input loop"
  proof = "plugins/harness-cli/main.hexa::harness_cli_activate"

@D c2 := "harness.streaming" :: meta-domain [d=2026-05-13 ok]
  text = "streaming render via host_render(...streaming, delta)"
  proof = "core/agent_loop.hexa::_stream_loop"

@D c3 := "tool.read_write_edit" :: meta-domain [d=2026-05-13 ok]
  text = "tool-core registers read/write/edit/bash/glob/grep at activate"
  proof = "plugins/tool-core/main.hexa::tool_core_activate"

@D c4 := "provider.registered" :: meta-domain [d=2026-05-13 ok]
  text = "at least one provider plugin registered"
  proof = "plugins/provider-claude-cli/main.hexa::provider_claude_cli_activate"

@D c5 := "provider.stream_open_next_close" :: meta-domain [d=2026-05-13 ok]
  text = "stream_open / stream_next / stream_close produce AsmEvents"
  proof = "core/agent_loop.hexa::_stream_loop"

# ── 결합 조건 (Mm — joint of all Cn) ──────────────────────────

@D m1 := "joint_turn_closes" :: meta-domain [d=2026-05-13 ok]
  <- c1, c2, c3, c4, c5
  text = "host_run_turn(messages, tools, opts) returns Message + ToolResult"
  proof = "build/Darwin-arm64/wilson -p 'hi' → assistant text streamed"

# ── 상태 전이 (state transitions over time) ───────────────────

@D m1_continuous_24h := "joint_stable_24h" :: meta-domain [d=2026-05-14 ok]
  <- m1
  duration_hours = 24
  => "all constituent conditions still hold — meta-domain stays live"
