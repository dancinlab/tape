import { createHighlighter } from 'shiki';
import { readFileSync, writeFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';

const repo = '/Users/ghost/core/tape';
const grammar = JSON.parse(readFileSync(join(repo, 'syntaxes/tape.tmLanguage.json'), 'utf8'));

const hl = await createHighlighter({
  themes: ['github-dark', 'github-light'],
  langs: [{
    name: 'tape',
    scopeName: 'source.tape',
    fileTypes: ['tape'],
    patterns: grammar.patterns,
    repository: grammar.repository
  }]
});

const examples = readdirSync(join(repo, 'examples'))
  .filter(f => f.endsWith('.tape'))
  .sort();

const renders = examples.map(f => {
  const src = readFileSync(join(repo, 'examples', f), 'utf8');
  return {
    name: f,
    dark: hl.codeToHtml(src, { lang: 'tape', theme: 'github-dark' }),
    light: hl.codeToHtml(src, { lang: 'tape', theme: 'github-light' })
  };
});

const html = `<!doctype html>
<html lang="en"><head>
<meta charset="utf-8">
<title>⊳ tape — syntax highlighting preview</title>
<style>
  :root { color-scheme: light dark; }
  body { font-family: ui-sans-serif, system-ui, -apple-system, sans-serif; max-width: 1100px; margin: 2rem auto; padding: 0 1rem; background: #fafafa; color: #111; }
  @media (prefers-color-scheme: dark) { body { background: #0d1117; color: #e6edf3; } a { color: #58a6ff; } }
  h1 { font-family: ui-monospace, monospace; }
  h2 { font-family: ui-monospace, monospace; font-size: 1rem; color: #6e7681; margin-top: 2.5rem; border-bottom: 1px solid #30363d33; padding-bottom: 0.3rem; }
  .row { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; }
  @media (max-width: 720px) { .row { grid-template-columns: 1fr; } }
  pre { margin: 0; padding: 0.85rem 1rem; border-radius: 6px; font-size: 13px; line-height: 1.55; overflow-x: auto; border: 1px solid #30363d33; }
  .label { font-size: 11px; font-family: ui-monospace, monospace; color: #6e7681; margin-bottom: 0.3rem; letter-spacing: 0.05em; }
  .meta { color: #6e7681; font-size: 0.9em; }
  code { font-family: ui-monospace, monospace; }
</style>
</head><body>
<h1>⊳ tape — syntax preview</h1>
<p class="meta">Rendered with <a href="https://shiki.style/">shiki</a> using the grammar at <code>syntaxes/tape.tmLanguage.json</code>. Left = <code>github-dark</code>, right = <code>github-light</code>.</p>
${renders.map(r => `
<h2>examples/${r.name}</h2>
<div class="row">
  <div><div class="label">github-dark</div>${r.dark}</div>
  <div><div class="label">github-light</div>${r.light}</div>
</div>
`).join('')}
</body></html>
`;

writeFileSync(join(repo, 'docs/preview.html'), html);
console.log('wrote ' + join(repo, 'docs/preview.html') + ' (' + html.length + ' bytes)');
