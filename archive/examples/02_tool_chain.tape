#!/usr/bin/env tape
# ══════════════════════════════════════════════════════════════
# Example: multi-tool causal chain — assistant fans out 3 tools,
#          aggregates results, replies.  Shows multi-id `<- t001, t002, t003`
# ══════════════════════════════════════════════════════════════

@S start s002 :: session [T0 N0 ok]
  => "wilson — investigating a codebase"

@U u001 = "list the hexa files under core/ and count them" :: harness [T1 N2 ok]

@A a001 :: harness [T1 N3 ok]
  <- u001
  => "I'll glob for core/*.hexa, count lines in each"

# ── 세 도구 병렬 호출 (3 tool fan-out) ───────────────────

@T t001 glob pattern=core/*.hexa :: tool [T1 N3 ok]
  <- a001

@D d001 allow glob :: governance [T1 N3 ok]
  <- t001
  |> deterministic-tool

@R r001 glob ok :: tool [T1 N4 ok]
  <- t001
  <- d001
  => "7 paths matched"

@T t002 bash cmd="wc -l core/*.hexa" :: tool [T1 N4 ok]
  <- a001

@D d002 allow bash :: governance [T1 N4 ok]
  <- t002
  |> bash-allowlist:wc

@R r002 bash ok :: tool [T1 N5 ok]
  <- t002
  <- d002
  => "8420 total"

@T t003 read path=core/main.hexa :: tool [T1 N5 ok]
  <- a001

@D d003 allow read/core/main.hexa :: governance [T1 N5 ok]
  <- t003
  |> read-allowlist

@R r003 read ok :: tool [T1 N6 ok]
  <- t003
  <- d003
  => "3122 bytes returned"

# ── 결과 집약 + 응답 (aggregate + reply) ─────────────────

@A a002 :: harness [T1 N7 ok]
  <- a001
  <- r001, r002, r003
  => "7 .hexa files under core/, 8420 lines total; entry = core/main.hexa"

@K k001 = 24+62+1820 = 5896 ucents :: cost [T1 N8 ok]
  <- a002

@S end :: session [T1 N12 ok]
  ~> s002
