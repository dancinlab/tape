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
# AGENTS.tape — `dancinlab/tape` repo governance + identity.
# SPECIAL: this repo IS the home of the .tape spec — this file
# self-references `spec/tape.md` via @X x_self_spec. Downstream
# consumers (wilson, hexa-scale, AGENTS.tape ecosystem) re-pull
# from this SSOT after a spec bump.

# ─── §1 Spec version ──────────────────────────────────────────────────

@V := "tape" :: spec [active]
  version = "1.2"
  uses = [@I, @V, @L, @D, @F, @X, @N, @H, @C, "<:", "@>", "[required]", heredoc, "[@id]"]
  primer = "see top-of-file 35-line comment block"
  self-reference = "this AGENTS.tape is the v1.2 grammar applied to the v1.2 spec's home repo"

@X wilson_pool := "wilson pool — resource utilization" :: guide [active]
  tldr = "Heavy / deterministic work (build · drill · probe · compile · test-sweep · GPU fire) → do NOT serialize on localhost; route to the host pool: `wilson pool list` then `wilson pool on <host> <cmd>`, or a ToolUse `\"host\"` field. Empty roster = degrade-to-local, fine."
  detail = "~/core/atlas/POOL.tape"

# ─── §2 Identity claims (what this project IS) ────────────────────────

@I id001 := "tape" :: identity-claim [d=2026-05-14 active]
  kind = "agent-execution trace grammar — spec home (SSOT)"
  brief = "Agent-Execution Trace grammar spec · typed events · provenance edges · v1.2"
  tagline = "typed events · provenance edges · delivery grade · append-only"
  scope <<~EOF
    The dancinlab/tape repo is the canonical home of the `.tape` v1.2 grammar.
    Every other AGENTS.tape file across dancinlab (wilson · hexa-scale · echoes · n6 · hxc · n12)
    is a *consumer* — they re-pull this spec when it bumps. Breaking changes here ripple.
  EOF
  entry-types = 17
  edges = 12
  placements = 5
  algorithms = 19
  parent = "dancinlab"

@I id002 := "tape.sibling-role" :: identity-claim [d=2026-05-14 active]
  <: id001
  role = "fourth sibling format — operational / causal-temporal layer"
  siblings <<~EOF
    n6  — semantic / atlas layer (typed verified atoms · grade ladder)
    hxc — byte-canonical wire (KV-cache stable · cross-host ship)
    n12 — 12-axis sparse cube
    tape — operational / causal-temporal trace (THIS repo)
  EOF
  relation = "n6/hxc/n12 are PROMOTION TARGETS for refined data extracted from a tape"
  url-n6 = "https://github.com/dancinlab/n6"
  url-hxc = "https://github.com/dancinlab/hxc"
  url-n12 = "https://github.com/dancinlab/n12"

# ─── §3 Repo layout ───────────────────────────────────────────────────

@L l1 := "repo-layout" :: structure [active]
  spec/tape.md -> "v1.2 spec (THE canonical grammar definition)"
  algorithms/ -> "19 reference algorithms (tape_grep · tape_replay · tape_compact · md_to_tape · …)"
  examples/ -> "8 worked examples (01_basic_session … 08_agents_tape — v1.2 showcase)"
  bin/tape -> "CLI dispatcher (hx install entry point)"
  tool/ -> "ancillary tools (markers_to_tape · …)"
  AGENTS.tape -> "this file · governance + identity (.tape v1.2 self-applied)"
  CLAUDE.md -> "symlink → AGENTS.tape (Claude Code auto-discovery)"
  README.md -> "human intro · sibling positioning · at-a-glance"
  LICENSE -> "CC0-1.0"

# ─── §4 Governance rules ──────────────────────────────────────────────

@D g_inherit := "inherit-from-lattice-policy" :: governance [required]
  rule = "Inherit the LATTICE_POLICY rules from dancinlab/echoes — real-limits-first, lattice-is-tool, honesty-external."
  authority = "[@x_lattice_policy]"
  applies-to = ["spec/tape.md", "examples/", "algorithms/", "README.md", "AGENTS.tape"]
  @> AGENTS.md

@D g1 := "real-limits-first" :: governance [required]
  <: g_inherit
  rule = "A project's ceiling is set by mathematical / physical / empirical reality, not by the n=6 lattice."
  applies-to = "any claim about what `.tape` can/cannot represent — bound by event semantics + append-only physics, not by grammar aesthetics"
  proof = "see [@x_lattice_policy] §1.2"

@D g2 := "lattice-is-tool" :: governance [required]
  <: g_inherit
  rule = "격자는 도구이지 제약이 아니다 — lattice is a tool, not a constraint."
  applies-to = "`.tape`'s 17 entry types / 12 edges / 5 placements are descriptive, not derivational — values landing on n=6 or n=12 are coincidence, not authority"
  proof = "see [@x_lattice_policy] §1.3"

@D g3 := "honesty-external" :: governance [required]
  <: g_inherit
  rule = "Every claim coupling `.tape` to external phenomena (real codebases · standards bodies · runtime hosts) ships with a one-line honest caveat about what `.tape` does NOT carry."
  forbidden = "claiming `.tape` captures semantic meaning (that's n6) or wire-canonical bytes (that's hxc) or cube projections (that's n12)"
  proof = "see [@x_lattice_policy] §C3"
  @> AGENTS.md

@D g4 := "commit-conventions" :: governance [required]
  rule <<~EOF
    Conventional Commits prefixes used in this repo:
      spec:        — changes to spec/tape.md (the canonical grammar)
      algorithms:  — changes under algorithms/
      examples:    — changes under examples/
      tool:        — changes under tool/ or bin/
      README:      — README.md updates
      agents:      — AGENTS.tape / CLAUDE.md / governance changes
    Spec changes ALWAYS bump the version line + add a §"v1.x → v1.y migration" subsection.
  EOF
  applies-to = "every commit on `main`"

@D g_spec_authority := "spec-authority" :: governance [required]
  rule <<~EOF
    `.tape` spec changes happen HERE first — in `spec/tape.md` on `dancinlab/tape`.
    Downstream consumers (wilson, hexa-scale, every AGENTS.tape across the
    ecosystem) re-pull after a version bump. Never edit `.tape` grammar in a
    downstream repo and expect it to propagate back; file a PR / issue here.
  EOF
  authority = "[@x_self_spec]"
  consumers = ["wilson", "hexa-scale", "echoes", "n6", "hxc", "n12"]
  proof = "[@x_self_spec] §version-history"
  @> AGENTS.md

@D g_arch_vs_log_split := "v1.2 architecture-vs-history split" :: governance [required d=2026-05-14 active]
  rule = "UPPERCASE.tape files are EDITABLE architecture (latest-wins per id). Append-only event history lives in UPPERCASE.log.tape siblings."
  why = "declarative entries (governance · config · layout · identity) evolve naturally; locking them as append-only via ~> supersedes creates noisy histories. The split lets architecture stay current and history stay immutable."
  applies-to = "AGENTS.tape · all UPPERCASE.tape root files"
  authority = "[@x_tape_spec] §Domain-tape sibling §Architecture-vs-history split"
  @> AGENTS.md


# ─── §5 Forbidden patterns ────────────────────────────────────────────

@F f1 := "external-lattice-fit" :: governance [required deny:write]
  pattern = "fitting `.tape`'s entry-type count / edge count / placement count to a magic number (n=6, n=12, …) AFTER the fact"
  exception = "values may coincidentally match (17 entry types ≠ any lattice) — that's allowed as observation, NOT derivation"
  authority = "[@x_lattice_policy] §1.2/§1.3"

@F f2 := "breaking-grammar-without-version-bump" :: governance [required deny:write]
  pattern = "introducing a new entry type / edge / grade tag / payload form in `spec/tape.md` without bumping `version = \"x.y\"` and adding a migration subsection"
  why = "downstream consumers (wilson · hexa-scale · every AGENTS.tape) detect grammar version via the `@V` line; silent grammar drift breaks parsers + replays"
  remedy <<~EOF
    1. Bump spec/tape.md `version` (`v1.x` → `v1.y`).
    2. Add `## v1.x → v1.y migration` subsection listing every added/changed/removed feature.
    3. Update README badge (`spec-v1.y`).
    4. Update examples/ if any are affected.
    5. Bump `@V version` in this AGENTS.tape.
    6. Commit with `spec:` prefix.
  EOF

# ─── §6 External citations ────────────────────────────────────────────

@X x_lattice_policy := "echoes/LATTICE_POLICY.md" :: policy [d=2026-05-14 active]
  url = "https://github.com/dancinlab/echoes/blob/main/LATTICE_POLICY.md"
  version = "1.0"
  scope = "real-limits-first · lattice-is-tool · honesty-external — inherited governance for all dancinlab repos"
  local-path = "~/core/hexa-chip/LATTICE_POLICY.md"

@X x_self_spec := "spec/tape.md" :: spec [d=2026-05-14 active]
  url = "https://github.com/dancinlab/tape/blob/main/spec/tape.md"
  version = "1.2"
  scope = "THE canonical .tape grammar — this AGENTS.tape's authority for grammar correctness"
  self-reference = "this repo IS the spec home; AGENTS.tape applies the spec it defines"

@X x_example := "examples/08_agents_tape.tape" :: example [d=2026-05-14 active]
  url = "https://github.com/dancinlab/tape/blob/main/examples/08_agents_tape.tape"
  scope = "full v1.2 feature showcase — every entry type · every edge · every grade · heredocs · inline citations"
  use-as = "reference template when authoring a downstream AGENTS.tape"

@X x_agents_md := "agents.md standard" :: convention [active]
  url = "https://agents.md/"
  scope = "third-party AI-agent harness file convention (Claude Code · Aider · Cursor)"
  note = "AGENTS.tape is the dancinlab tape-native alternative; CLAUDE.md → AGENTS.tape symlink preserves auto-discovery"

# ─── §7 Notes (LLM-only hints) ────────────────────────────────────────

@N n1 := "spec-home-special-case" :: note [active]
  text <<~EOF
    This AGENTS.tape is unusual: the repo it lives in IS the home of the
    grammar it's written in. Any inconsistency between this file and
    `spec/tape.md` is a bug — the spec wins. File an issue or PR.
  EOF

@N n2 := "downstream-ripple" :: note [active]
  text <<~EOF
    When `spec/tape.md` bumps version (e.g. v1.2 → v1.3):
      1. Update `@V version` in this file.
      2. Notify downstream AGENTS.tape consumers (wilson · hexa-scale · …).
      3. They re-read `examples/08_agents_tape.tape` for the new feature surface.
      4. Their `@V version` lines update on next refresh.
  EOF

# ─── §8 Generator hooks ───────────────────────────────────────────────

@H h1 := "agents-md-emit" :: generator [active]
  @> AGENTS.md
  consumer = "agents.md ecosystem tooling that doesn't speak .tape yet (Claude Code · Aider · Cursor)"
  algorithm = "tape_to_md (algorithms/tape_to_md.hexa) — already implemented"
  trigger = "manual / pre-commit hook (when wired)"
  fallback-only = true   # AGENTS.tape is SSOT; AGENTS.md is derived view (currently absent — symlink-only auto-discovery)

@H h2 := "claude-md-symlink" :: generator [active]
  rule = "ship `CLAUDE.md -> AGENTS.tape` symlink so Claude Code auto-discovery picks up the grammar primer first"
  command = `ln -sf AGENTS.tape CLAUDE.md`
  rationale = "Claude Code looks for CLAUDE.md; without the symlink it would miss the grammar primer and try to parse AGENTS.tape as unstructured prose"
