#!/usr/bin/env tape
# ══════════════════════════════════════════════════════════════════════
# .tape v1.2 — grammar primer (cold-read by any LLM / agent / human)
# ══════════════════════════════════════════════════════════════════════
# Form: each entry is `@<type> <id> := "<subject>" :: <kind> [<grades>]`
#       optionally followed by body lines (2-space indent) — key=value,
#       edges (<- -> => …), or quoted prose.
#
# ENTRY TYPES (17):
#   Runtime (10): @S session  @U user  @A assistant  @T tool-call  @R result
#                 @H hook  @D decision  @K cost  @P provider  @? anomaly
#   Foundation:   @I identity-claim
#   Declarative:  @X external-citation  @F forbidden-pattern  @N note
#                 @C config  @L layout  @V spec-version
#
# EDGES (12, on body lines, 2-space indent):
#   Causal:     <- caused-by   -> triggers   == continues
#               ~> supersedes  !! aborts     |> verified-by
#   Effect:     => produces (followed by quoted natural-language)
#   Structural: <: specializes  :> generalizes  ?> soft-depends
#               !> conflicts-with  @> projects-to (e.g. @> AGENTS.md)
#
# GRADE TAGS (in [...] on entry header):
#   Delivery:   ok · err · denied · cancelled · partial · superseded
#   Governance: required · recommended · optional · draft · active · deprecated
#   Scoped:     allow:<x> · deny:<x>
#   Time/index: T<n> (turn)  N<n> (wall-sec)  d=<YYYY-MM-DD>
#
# PAYLOAD SYNTAX (body lines):
#   key = "value"           single-line string
#   key = [a, b, c]         array literal
#   key <<~EOF              heredoc (multi-line; ends with EOF on own line)
#     multi-line text
#   EOF
#   "see [@x1] §3"          inline citation by entry id
#   `cmd or path`           backtick code-span (inline only)
#
# Full spec: ~/core/tape/spec/tape.md (or github.com/dancinlab/tape)
# ══════════════════════════════════════════════════════════════════════
#
# Example: AGENTS.tape demonstrating every v1.2 feature
# This is the SSOT for the (hypothetical) `dancinlab/hexa-demo` repo.

# ─── §1 Spec version ──────────────────────────────────────────────────

@V := "tape" :: spec [active]
  version = "1.2"
  uses = [@X, @F, @N, @C, @L, "<:", "@>", "[required]", heredoc, "[@id]"]
  primer = "see top-of-file 35-line comment block"

# ─── §2 Identity claims (what this project IS) ────────────────────────

@I id001 := "hexa-demo" :: identity-claim [d=2026-05-14 active]
  kind = "hexa-* standalone demo (v1.2 grammar showcase)"
  axis = "demonstration · not production"
  parent = "dancinlab/echoes"

@I id002 := "hexa-demo.scope" :: identity-claim [d=2026-05-14 active]
  <: id001
  ladder = [overview, examples, tooling]

# ─── §3 Config (paths · defaults) ─────────────────────────────────────

@C c1 := "session-dir" :: config [active]
  value = "~/.wilson/sessions/"
  why = "wilson harness-cli session storage"

@C c2 := "max-cell-references" :: config [recommended]
  value = "5"
  rationale = "Each operational cell should cite ≥5 mainstream invariants before claiming completeness"

# ─── §4 Repo layout ───────────────────────────────────────────────────

@L l1 := "repo-layout" :: structure [active]
  README.md -> "human intro · 18-block format"
  AGENTS.tape -> "this file · governance + identity (.tape v1.2)"
  CLAUDE.md -> "symlink → AGENTS.tape (Claude Code auto-discovery)"
  SEED.tape -> "runtime handoff · open decisions · anomalies · planned actions"
  LICENSE -> "MIT"
  docs/logo.svg -> "signature glyph"

# ─── §5 Governance rules ──────────────────────────────────────────────

@D g1 := "honest-caveat-first" :: governance [required]
  rule = "Every claim coupling n=6 lattice to external phenomena ships with one-line honest caveat."
  applies-to <<~EOF
    Every section in README.md
    Every entry referencing external entities (NASA · IPCC · IBC · constitutional bodies)
    Every n=6 → real-world claim
  EOF
  proof = "see [@x1] §1.2 + [@x2] §C3"
  @> AGENTS.md

@D g2 := "cite-real-practitioners" :: governance [required]
  rule = "Cells in operational rows must cite real architects / planners / treaty texts / code books."
  acceptable = [LeCorbusier, Howard, Niemeyer, "ISO 37120", IPCC, UNFCCC, "Rockström 2009"]
  forbidden = "claiming any external party adopts the n=6 lattice"
  <: g1
  @> AGENTS.md

@D g3 := "tape-runtime-trace" :: governance [required]
  rule = "Runtime trace + agent identity + per-domain history use .tape grammar."
  applies-to = [AGENTS.tape, SEED.tape, "*.tape"]
  why = "governance principle #9b · append-only event semantics"
  proof = "see `~/core/wilson/plugins/governance/SPEC.md` §#9b"

@D g4 := "draft-rule-example" :: governance [draft recommended]
  rule = "EXAMPLE — draft rule not yet enforced; will activate after community review."
  proposal-id = "RFC-001"
  ?> g1, g2
  @> AGENTS.md

# ─── §6 Forbidden patterns ────────────────────────────────────────────

@F f1 := "external-lattice-fit" :: governance [required deny:write]
  pattern = "n=6 / σφτ identity applied as derivation rule to NASA · SpaceX · IPCC · IBC · constitutional bodies"
  exception = "values may coincidentally match (e.g. 6 = 6 axes in IBC) — that's allowed as observation, NOT derivation"
  authority = "[@x1] §1.2/§1.3"

@F f2 := "no-amend-after-hook-fail" :: governance [required]
  pattern = "git commit --amend after a pre-commit hook failure"
  why = "hook failure means commit didn't happen — amend would modify the PREVIOUS commit, losing work"
  remedy = "fix the issue, re-stage, create a NEW commit"

# ─── §7 External citations ────────────────────────────────────────────

@X x1 := "echoes/LATTICE_POLICY.md" :: policy [d=2026-05-13 active]
  url = "https://github.com/dancinlab/echoes/blob/main/LATTICE_POLICY.md"
  version = "1.0"

  url = "https://github.com/dancinlab/echoes/blob/main/raw/10.md#c3"
  scope = "honest-caveat policy origin · forbidden lattice-fit on external entities"

@X x3 := "agents.md standard" :: convention [active]
  url = "https://agents.md/"
  scope = "third-party AI-agent harness file convention · Claude Code · Aider · Cursor"
  note = "AGENTS.tape is the dancinlab tape-native alternative; CLAUDE.md → AGENTS.tape symlink preserves auto-discovery"

@X x4 := "ISO 37120" :: standard [iso active]
  url = "https://www.iso.org/standard/68498.html"
  scope = "Sustainable cities and communities — Indicators for city services and quality of life"
  version = "2018"

# ─── §8 Notes (LLM-only hints) ────────────────────────────────────────

@N n1 := "build-tip" :: note [active]
  text = "After editing any .hexa file, rebuild the per-host binary (`build/<host>-<arch>/wilson`) before testing — `wilson` launcher prefers per-host binary over legacy `build/wilson`."

@N n2 := "session-resume" :: note [active]
  text <<~EOF
    Resume a previous session with `wilson -i "..." --session <sid>`.
    Session IDs live in `~/.wilson/harness-cli/sessions/`.
    Each session keeps its own `<sid>.tape` runtime trace — separate from AGENTS.tape.
  EOF

@N n3 := "deprecated-pattern-warning" :: note [deprecated]
  ~> g3
  text = "OLD: ad-hoc 'note:' prefix in AGENTS.md prose. NEW: @N entries in AGENTS.tape — same role, machine-readable."

# ─── §9 Generator hooks ───────────────────────────────────────────────

@H h1 := "agents-md-emit" :: generator [active]
  @> AGENTS.md
  consumer = "agents.md ecosystem tooling that doesn't speak .tape yet (Claude Code · Aider · Cursor)"
  algorithm = "tape_to_agents_md (algorithms/tape_to_agents_md.hexa)"
  trigger = "pre-commit hook + CI"
  fallback-only = true   # AGENTS.tape is SSOT; AGENTS.md is derived view

@H h2 := "claude-md-symlink" :: generator [active]
  rule = "ship `CLAUDE.md -> AGENTS.tape` symlink so Claude Code auto-discovery picks up the grammar primer first"
  command = `ln -sf AGENTS.tape CLAUDE.md`

# ─── §10 Demonstration of remaining edge operators ────────────────────

@D g5 := "decision-vs-forbidden" :: governance [optional]
  rule = "Use @D for allow/recommend rules; @F for explicit deny patterns."
  :> f1, f2   # generalizes — g5 is the umbrella; f1/f2 are concrete denies
  !> g4       # conflicts-with — g5 and the example g4 happen to be mutually exclusive in this demo
