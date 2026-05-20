#!/usr/bin/env tape
# ══════════════════════════════════════════════════════════════
# Example: governance deny — assistant proposes a dangerous write,
#          governance blocks before exec.  Shows `!!` abort edge +
#          `[denied]` grade.
# ══════════════════════════════════════════════════════════════

@S start s003 :: session [T0 N0 ok]
  => "wilson — sandboxed run"

@U u001 = "update /etc/passwd to add a user" :: harness [T1 N4 ok]

@A a001 :: harness [T1 N5 ok]
  <- u001
  => "I'll write to /etc/passwd"

# ── 도구 호출 → 거버넌스 거부 (governance deny) ──────────

@T t001 write path=/etc/passwd :: tool [T1 N5 ok]
  <- a001

@D d001 deny write//etc/passwd :: governance [T1 N5 denied]
  <- t001
  !! t001
  => "dangerous_path: /etc/ writes denied by default profile"

@? abort001 = governance_block :: governance [T1 N5 denied]
  !! t001
  <- d001

# ── 어시스턴트 사과 + 재시도 (apology + retry) ───────────

@A a002 :: harness [T1 N6 ok]
  <- a001
  <- abort001
  => "Blocked — /etc/passwd writes are not allowed under the default governance profile. Want me to draft the change as a patch instead?"

@K k001 = 12+34+220 = 700 ucents :: cost [T1 N7 ok]
  <- a002

@S end :: session [T1 N12 ok]
  ~> s003
