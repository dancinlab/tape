#!/usr/bin/env tape
# Example: HARNESS.tape ↔ HARNESS.log.tape — canonical v1.2 split
#
# This file shows the ARCHITECTURE-CURRENT half (editable, latest-wins
# per id). Its sibling HARNESS.log.tape carries the APPEND-ONLY history
# (every entry a time-anchored event). Together they replace the
# v1.1-era single-file <DOMAIN>.tape that mixed both kinds.
#
# Spec reference: ~/core/tape/spec/tape.md §"Architecture-vs-history
# split" + §"Authoring guide".
# Real-world canonical example: dancinlab/anima/REBORN.tape commit
# 7ceaa6882 (213 architecture entries · 1968 log entries split out).

# ══════════════════════════════════════════════════════════════
# HARNESS.tape — wilson harness substrate (architecture-current)
# ══════════════════════════════════════════════════════════════

@V := "tape" :: spec [active]
  version = "1.2"

# ─── §1 Identity ─────────────────────────────────────────────────────

@I id001 := "harness" :: identity-claim [d=2026-05-15 active]
  kind = "wilson harness substrate · input loop · streaming render · tool dispatch"
  brief = "raw-mode TUI + alt-screen + line editor + cell-grid diff renderer · plugins/harness-cli/"
  parent = "dancinlab/wilson"
  sibling-log = "HARNESS.log.tape"

# ─── §2 Config (paths · defaults · timers) ───────────────────────────

@C c_session_dir := "session-dir" :: config [active]
  value = "~/.wilson/harness-cli/sessions/"

@C c_max_tool_turns := "max-tool-turns" :: config [active]
  value = "20"
  why = "safety net per user line; prevents runaway loops"

@C c_spinner_hz := "spinner-frequency" :: config [active]
  value = "5"
  unit = "Hz"
  glyphs = "· ✢ ✳ ✶ ✻ ✽"

# ─── §3 Layout ───────────────────────────────────────────────────────

@L l1 := "harness-files" :: structure [active]
  plugin.hexa -> "@plugin manifest + harness_cli_dispatch + harness_cli_manifest"
  main.hexa -> "implementation · raw-mode input · streaming render · cell-grid diff"
  test_harness_cli.hexa -> "selftests (fake_host)"
  AGENTS.md -> "plugin-local prose SSOT"

# ─── §4 Governance ───────────────────────────────────────────────────

@D g_inherit := "inherits-wilson-governance" :: governance [required]
  rule = "All wilson AGENTS.tape rules (hexa-lang RULES + session log + plugin-first boundary) apply here unchanged."
  authority = "[@x_wilson_agents]"

@D g_streaming := "streaming-via-host-render" :: governance [required]
  rule = "All streaming output goes through host_render(host, 'streaming', delta). NEVER print/eprintln directly from agent_loop or plugins."
  why = "single render path · TUI vs plain-line mode swap · alt-screen safety"
  applies-to = "core/agent_loop.hexa · plugins/harness-* · provider plugins"

@D g_raw_mode := "raw-mode-alt-screen-required" :: governance [required]
  rule = "Interactive harness uses raw-mode + alt-screen + cell-grid diff. Plain-line fallback only on non-tty (`wilson | cat`)."
  why = "zero ANSI noise in pipes · proper redraw control in TTY"

# ─── §5 Forbidden patterns ───────────────────────────────────────────

@F f_print_in_plugin := "direct-print-in-plugin" :: governance [required deny:write]
  pattern = "println / eprintln calls in plugins/harness-* outside the render path"
  remedy = "use host_render(host, 'streaming'|'tool_result'|'edit_block', payload)"

@F f_blocking_stdin := "blocking-stdin-in-agent-loop" :: governance [required deny:write]
  pattern = "blocking stdin read in agent_loop · blocks streaming during input wait"
  remedy = "harness plugin owns the input loop · agent_loop is render-only"

# ─── §6 External citations ───────────────────────────────────────────

@X x_wilson_agents := "wilson root AGENTS.tape" :: parent-governance [active]
  url = "https://github.com/dancinlab/wilson/blob/main/AGENTS.tape"
  scope = "parent governance · all wilson rules apply"

@X x_spec := "tape v1.2 spec" :: spec [d=2026-05-14 active]
  url = "https://github.com/dancinlab/tape/blob/main/spec/tape.md"
  scope = "this file's grammar reference + §Authoring guide"

# ─── §7 Notes (LLM hints) ────────────────────────────────────────────

@N n_split := "v1.2 split note" :: note [active]
  text = "This file is the ARCHITECTURE half (editable). For commit landings · feature events · tool-call records · cost samples · see HARNESS.log.tape sibling."

@N n_emit := "emit canonical events" :: note [active]
  text <<~EOF
    Commit hooks should append @A entries to HARNESS.log.tape:
      @A commit_<sha> :: harness [d=YYYY-MM-DD ok]
        => "<one-line description>"
    Tool calls / results emit @T / @R during runtime.
    Cost samples emit @K with the model + provider.
  EOF

# ─── §8 Generator hooks ──────────────────────────────────────────────

@H h_md_render := "render to HARNESS.md ##Log" :: generator [active]
  consumer = "tape_to_md_log"
  source = "HARNESS.log.tape (NOT this file)"
  target = "HARNESS.md ## Log section (between <!-- AUTO-RENDER --> fences)"

@H h_pre_commit := "pre-commit hook wiring" :: generator [active]
  trigger = "git pre-commit"
  rule = "map changed paths → domain · append @A commit_<sha> :: <domain> [d=<date> ok] to <DOMAIN>.log.tape ONLY · never touch <DOMAIN>.tape"

# (End of HARNESS.tape — architecture-only · 14 entries · editable)
#
# Companion file HARNESS.log.tape (append-only) example layout:
#
#   #!/usr/bin/env tape
#   # ══════ v1.2 primer header (~35 lines) ══════
#   @V := "tape" :: spec [active]
#     version = "1.2"
#   # §Log — entries chronological, oldest first.
#
#   @A commit_b3706a1 :: harness [d=2026-05-12 ok]
#     => "raw-mode + alt-screen + line editor lands"
#
#   @A commit_184cbc1 :: harness [d=2026-05-13 ok]
#     <- commit_b3706a1
#     => "ToolResult out-of-band handoff"
#
#   @T t_streaming_test :: harness [d=2026-05-13 T1 N0 ok]
#     <- commit_184cbc1
#     => "stream-delta render verified"
#
#   @R r_streaming_test :: harness [d=2026-05-13 T1 N1 ok]
#     <- t_streaming_test
#     => "1024 chars rendered without artifact"
#
#   @K k_streaming :: harness [d=2026-05-13 T1 N1 ok]
#     value = "in=12 + out=187 + cache=4099 = 4298 ucents"
#     <- t_streaming_test
#
#   @? abort_001 :: harness [d=2026-05-14 T5 N42 cancelled]
#     reason = "user pressed Ctrl-C mid-stream"
#     !! a042
