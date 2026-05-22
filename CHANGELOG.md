# Changelog

Chronological log of notable changes. One section per ship batch, date-keyed. Grammar version tracked as `.tape` spec `v<major>.<minor>`.

For the full audit trail, see `git log`.

---

## 2026-05-22

- **spec v1.4 amendment** — governance tool annotation: the `@D :: governance` body extends with `tool` / `usage` fields.
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
