# Changelog

Chronological log of notable changes. One section per ship batch, date-keyed. Grammar version tracked as `.tape` spec `v<major>.<minor>`.

For the full audit trail, see `git log`.

---

## 2026-05-26

- **spec v1.6 amendment** — production survey (anima · demiurge roots) folds in two more repo-root declarative placements, both on existing types:
  - `CLAIMS.tape` — `@C <id> :: formula [slug= group=]` verifiable-claim index (claim → `hexa verify` g5 → `.verdicts/` → `/paper` gate). Free-body `@C`.
  - `NEXUS.tape` — `@X :: reuse-edge / provides / reuse-candidate` intra-project reuse lattice (commons `@D g67`). Free-body `@X` (deliberately not `@D`, to escape the do/dont closure).
  - grade bracket ratified as an **open tag-bag** — standardized tags keep fixed meaning; domain tags (bare `tier-2` / `paper-track`, or `key=value` `slug=` / `group=`) are skip-not-reject. Domain alphabet noted genuinely open (110+ tags surveyed).
  - `@verdict_<slug> :=` archive looseness (type/id not separated) flagged non-conforming, grandfathered. No new entry types.
- **TextMate grammar** — open tag-bag highlighting: `tier-N` + generic `key=value` grade tags.
- **version lockstep** — `bin/tape --version` v1.6 · `tree-sitter-tape` 0.1.2 · README badges (spec v1.6 · 10 placements) · spec title.

- **spec v1.5 amendment** — governance body reconciled with cross-project authoring practice (sidecar `commons.tape` / `project.tape` / every `SKILL.md`):
  - `tool` / `usage` (v1.4) **reverted** — `@D` body re-closed at `{do, dont}`; fold the CLI into the `do` imperative.
  - `do` / `dont` are **repeatable** — an entry may carry multiple `do =` / `dont =` lines (ordered directive list); no field-count cap, per-line ≤ ~100 char discipline instead.
  - two new declarative `@D` kinds — `:: skill` (`SKILL.md` body) and `:: glossary` (term→canonical-command map) — carry the identical `{do, dont}` repeatable body. Added to the open domain alphabet.
  - `DOMAINS.tape` roster placement — `@V := "domains" :: index` header + `@domain <NAME> := "<relpath>"` rows. Introduces the `:: index` kind and the first **named (multi-character) entry type** (`@domain`), permitted only in `:: index` placements (runtime/foundation/declarative stay closed at 17). `@goal:` / `@title:` clarified as `<DOMAIN>.md` markdown markers, not tape entries.
  - enforced by sidecar `tape-lint` (PreToolUse deny, do/dont-only + 100-char cap, diff-aware, no opt-out).
- **TextMate grammar** (`syntaxes/tape.tmLanguage.json`) — recognise declarative types `@V @X @F @N @C @L` in entry headers · optional grade bracket (for `:: skill` headers) · `@domain` roster rows (`DOMAINS.tape`) · v1.2 edges `<: :> ?> !> @>` · governance / scope / date / version grade tags · `do`/`dont` body-field highlighting.
- **tree-sitter grammar** (`tree-sitter-tape/grammar.js`) — `type` token extended to named multi-char types (`@domain`) for `:: index` rosters.
- **version lockstep** — `bin/tape --version`, `tree-sitter-tape` package description, README badges (spec v1.5 · 17 types · 12 edges · 8 placements), and the spec doc title all aligned to v1.5.

## 2026-05-22

- **spec v1.4 amendment** — governance tool annotation: the `@D :: governance` body extends with `tool` / `usage` fields. *(reverted in v1.5)*
- **Spec Kit removed** — interim GitHub Spec Kit scaffolding (`.specify/` + `speckit-*` skills) dropped.

## 2026-05-21

- **GitHub Spec Kit** — adopted then superseded; 10 `.tape` files relocated into `archive/`.

## 2026-05-20

- **spec v1.3 amendment** — governance imperative: `@D :: governance` body closed at `{do, dont}`.
- **spec v1.2 amendment** — compactness invariants for declarative entries.

## 2026-05-18

- **tree-sitter-tape** — tree-sitter grammar added.

## 2026-05-17

- **tape-lsp** — canonical `.tape` LSP server (stdio JSON-RPC).

## 2026-05-14

- **spec v1.2** — 6 new entry types, 5 new edges, governance grades, the `AGENTS.tape` pattern, project-tree convention (`@I id001` schema). `AGENTS.md` migrated to `AGENTS.tape`. Architecture-vs-history split for domain tapes (`<DOMAIN>.tape` vs `<DOMAIN>.log.tape`).
- **bin/tape** — CLI dispatcher (`hx install` entry point).
