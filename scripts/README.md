# scripts

Maintenance scripts. Not part of the format — these regenerate auxiliary artifacts under `docs/`.

## `render_preview.mjs` — browser HTML preview

Generates `docs/preview.html` — side-by-side rendering of every `examples/*.tape` with `github-dark` + `github-light` themes via [shiki](https://shiki.style/).

## `render_svg.mjs` — README-embeddable SVG previews

Generates `docs/preview-dark.svg` + `docs/preview-light.svg` — two self-contained SVG renderings (one per theme). Embedded in the root `README.md` via a `<picture>` element so GitHub auto-switches based on the viewer's color scheme.

## Run

```bash
npm install --no-save shiki
node scripts/render_preview.mjs
node scripts/render_svg.mjs
```

## When to regenerate

- After editing `syntaxes/tape.tmLanguage.json`
- After adding or modifying files under `examples/`

Re-run both scripts so the checked-in HTML and SVGs stay current.
