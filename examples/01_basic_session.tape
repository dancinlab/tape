#!/usr/bin/env tape
# ══════════════════════════════════════════════════════════════
# Example: minimal session — start, two turns, one tool, end
# ══════════════════════════════════════════════════════════════

# ── 시작 (Session start) ─────────────────────────────────

@S start s001 :: session [T0 N0 ok]
  => "wilson — provider=claude-cli model=opus-4-7"

# ── 첫 턴 (Turn 1: greeting) ─────────────────────────────

@U u001 = "안녕" :: harness [T1 N3 ok]

@A a001 :: harness [T1 N4 ok]
  <- u001
  => "반가워요. 어떻게 도와드릴까요?"

@K k001 = 4+12+0 = 16 ucents :: cost [T1 N5 ok]
  <- a001

# ── 두번째 턴 (Turn 2: tool call) ────────────────────────

@U u002 = "프로젝트 README 한줄 요약해" :: harness [T2 N28 ok]

@A a002 :: harness [T2 N29 ok]
  <- u002
  => "Let me read the README"

@T t001 read path=README.md :: tool [T2 N29 ok]
  <- a002

@D d001 allow read/README.md :: governance [T2 N29 ok]
  <- t001
  |> read-allowlist

@R r001 read ok :: tool [T2 N30 ok]
  <- t001
  <- d001
  => "5249 bytes returned"

@A a003 :: harness [T2 N31 ok]
  <- a002
  <- r001
  => "wilson 은 hexa-native AI coding agent — minimal core + plugin-first."

@K k002 = 11+24+428 = 932 ucents :: cost [T2 N32 ok]
  <- a003

# ── 종료 (Session end) ────────────────────────────────────

@S end :: session [T2 N40 ok]
  ~> s001
  => "clean exit — /exit"
