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

const FONT_SIZE = 13;
const LINE_HEIGHT = 20;
const CHAR_WIDTH = 7.8;
const PAD = 16;
const LABEL_H = 22;
const GAP = 18;

const escapeXml = s =>
  s.replace(/&/g, '&amp;')
   .replace(/</g, '&lt;')
   .replace(/>/g, '&gt;')
   .replace(/"/g, '&quot;');

function renderTheme(themeName) {
  const labelColor = themeName.includes('dark') ? '#8b949e' : '#57606a';
  const borderColor = themeName.includes('dark') ? '#30363d' : '#d0d7de';
  const pageBg = themeName.includes('dark') ? '#0d1117' : '#ffffff';

  const blocks = [];
  let y = PAD;
  let maxLineChars = 0;
  let codeBg = pageBg;

  for (const file of examples) {
    const src = readFileSync(join(repo, 'examples', file), 'utf8').replace(/\n+$/, '');
    const result = hl.codeToTokens(src, { lang: 'tape', theme: themeName });
    codeBg = result.bg;

    blocks.push(
      `<text x="${PAD}" y="${y + LABEL_H - 8}" font-family="ui-monospace, SFMono-Regular, Menlo, monospace" font-size="11" fill="${labelColor}">${escapeXml('examples/' + file)}</text>`
    );
    y += LABEL_H;

    const lines = result.tokens;
    const codeHeight = lines.length * LINE_HEIGHT + PAD;
    const codeY = y;

    blocks.push(`__BG_PLACEHOLDER__${codeY}__${codeHeight}__`);

    let lineY = y + LINE_HEIGHT;
    for (const line of lines) {
      const tspans = line
        .map(t => `<tspan fill="${t.color || result.fg}">${escapeXml(t.content)}</tspan>`)
        .join('');
      blocks.push(
        `<text x="${PAD * 1.5}" y="${lineY}" font-family="ui-monospace, SFMono-Regular, Menlo, monospace" font-size="${FONT_SIZE}" xml:space="preserve">${tspans}</text>`
      );
      lineY += LINE_HEIGHT;
      const chars = line.reduce((n, t) => n + t.content.length, 0);
      if (chars > maxLineChars) maxLineChars = chars;
    }

    y = codeY + codeHeight + GAP;
  }

  const totalWidth = Math.ceil(maxLineChars * CHAR_WIDTH + PAD * 3);
  const totalHeight = y - GAP + PAD;
  const codeBoxW = totalWidth - PAD;

  const rendered = blocks.map(b => {
    if (b.startsWith('__BG_PLACEHOLDER__')) {
      const [, , yy, hh] = b.split('__');
      return `<rect x="${PAD / 2}" y="${yy}" width="${codeBoxW}" height="${hh}" fill="${codeBg}" stroke="${borderColor}" stroke-width="1" rx="6"/>`;
    }
    return b;
  });

  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${totalWidth} ${totalHeight}" width="${totalWidth}" height="${totalHeight}" font-family="ui-monospace, SFMono-Regular, Menlo, monospace">
<rect width="100%" height="100%" fill="${pageBg}"/>
${rendered.join('\n')}
</svg>
`;
}

writeFileSync(join(repo, 'docs/preview-dark.svg'), renderTheme('github-dark'));
writeFileSync(join(repo, 'docs/preview-light.svg'), renderTheme('github-light'));

const darkSize = readFileSync(join(repo, 'docs/preview-dark.svg')).length;
const lightSize = readFileSync(join(repo, 'docs/preview-light.svg')).length;
console.log(`wrote docs/preview-dark.svg (${darkSize} bytes) + docs/preview-light.svg (${lightSize} bytes)`);
