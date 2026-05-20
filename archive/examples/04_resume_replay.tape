#!/usr/bin/env tape
# ══════════════════════════════════════════════════════════════
# Example: resume + replay — `@S resume == s001` continuation edge.
#   `tape_replay` rebuilds [Message] from the resumed tape:
#     prior @U/@A pairs → Message{role=user|assistant}
#     prior @T/@R pairs → tool-role Messages
#   Continuation is byte-canonical: the resumed tape is a strict
#   suffix of the original file (same path, O_APPEND reopen).
# ══════════════════════════════════════════════════════════════

# Imagine s001 = `examples/01_basic_session.tape` (id reused for clarity).

@S resume s001r1 :: session [T0 N0 ok]
  == s001
  => "WILSON_SESSION=s001 → re-open ~/.wilson/harness-cli/sessions/s001.tape"

# tape_replay populates the agent loop's history from the prior tape:
#   [Message{user,"안녕"},
#    Message{assistant,"반가워요…"},
#    Message{user,"프로젝트 README 한줄 요약해"},
#    Message{assistant,"wilson 은 …"}]
# No new @U/@A entries are emitted at resume — they already exist.

@H session_resume@transform priority=28 :: hook [T0 N0 ok]
  <- s001r1

# ── 새 턴 (new turn on top of resumed history) ──────────

@U u003 = "그 hexa 파일들 중 가장 큰 거?" :: harness [T3 N5 ok]

@A a004 :: harness [T3 N6 ok]
  <- u003
  <- s001r1
  => "이전 컨텍스트 — 7개 core/*.hexa 파일을 봤었지. core/main.hexa 가 가장 큼 (3122 bytes)."

@K k003 = 8+22+312 = 824 ucents :: cost [T3 N7 ok]
  <- a004

@S end :: session [T3 N15 ok]
  ~> s001r1
