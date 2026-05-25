# `.tape` TextMate grammar

`tape.tmLanguage.json` — token rules for `.tape` files. Uses standard TextMate scopes so any theme renders without per-theme tuning.

## What it highlights

| Token | TextMate scope | Visual role |
|---|---|---|
| `#!/usr/bin/env tape` shebang | `comment.line.shebang` | File header |
| `# ── Section ──` divider | `markup.heading.section` | Section break |
| `# ═══` box divider | `markup.heading.box` | Major divider |
| `# ...` other | `comment.line.number-sign` | Plain comment |
| `@S @U @A @T @R @H @D @K @P @? @I @V @X @F @N @C @L` type prefix | `keyword.control.type` | Event / declarative type |
| `<id>` event identifier | `entity.name.event` | Event name |
| `:: <domain>` | `keyword.operator.domain` + `entity.name.namespace` | Domain / kind tag |
| `[T2 N48 ok]` · `[required active]` · `[d=2026-05-26]` · `[allow:read]` · `[tier-2 slug=x]` grade | `keyword.other.delivery-state` · `keyword.other.governance-state` · `keyword.other.scope` · `constant.numeric.{turn-index,wall-clock,date,version,tier}` · `variable.parameter.grade` | Delivery / governance state + indices + open tag-bag (bracket optional) |
| `<-` `->` `=>` `==` `~>` `\|>` `!!` `<:` `:>` `?>` `!>` `@>` edges | `keyword.operator.edge` | Provenance + structural operators |
| `"..."` quoted prose | `string.quoted.double.prose` | Descriptive prose |
| `do = "..."` / `key = "..."` body field | `variable.parameter.field` + `keyword.operator.assignment` + `string.quoted.double` | Body field line (2-space indent) |
| `key=value` | `variable.parameter` + `keyword.operator.assignment` + `string.unquoted` | Inline key-value pair on header |
| `123` / `-1.5e6` | `constant.numeric` | Numeric literal |
| `+` / `-` / `*` / `^` / `(` `)` | `keyword.operator.arithmetic` | Expression operators |

## Local use without a published extension

### VS Code (manual install)

1. Copy to a local extensions folder:
   ```bash
   mkdir -p ~/.vscode/extensions/tape-local
   cp -r syntaxes ~/.vscode/extensions/tape-local/
   ```
2. Create `~/.vscode/extensions/tape-local/package.json`:
   ```json
   {
     "name": "tape-local",
     "version": "0.0.1",
     "engines": { "vscode": "^1.60.0" },
     "contributes": {
       "languages": [{ "id": "tape", "extensions": [".tape"] }],
       "grammars": [{
         "language": "tape",
         "scopeName": "source.tape",
         "path": "./syntaxes/tape.tmLanguage.json"
       }]
     }
   }
   ```
3. Restart VS Code → `.tape` files highlight automatically.

### Sublime Text / TextMate / Atom

Drop the `.tmLanguage.json` into the bundle/grammars directory of your editor.

## License

CC0-1.0 — free to copy into any extension/package.
