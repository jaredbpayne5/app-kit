/**
 * Sync apps/web/content/*.md → apps/web/{privacy,terms}.html
 *
 * Tiny markdown subset: headings, paragraphs, lists, bold, links.
 * No dependency — keep this file small and idempotent (R6).
 * Legal is hosted-only (no in-app legal-content.ts).
 *
 * Usage: npm run sync:legal
 */
import { cpSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';

/** Override for fixture smokes (`FACTORY_ROOT=/tmp/...`). Default: repo root. */
const ROOT = process.env.FACTORY_ROOT
  ? path.resolve(process.env.FACTORY_ROOT)
  : path.resolve(__dirname, '../..');

type Inline =
  | { kind: 'text'; value: string }
  | { kind: 'bold'; value: string }
  | { kind: 'link'; text: string; href: string };

type Block =
  | { type: 'heading'; level: 1 | 2 | 3; text: string }
  | { type: 'paragraph'; inlines: Inline[] }
  | { type: 'list'; items: Inline[][] };

const DOCS = [
  {
    key: 'privacy',
    title: 'Privacy Policy',
    src: 'apps/web/content/privacy.md',
    htmlOut: 'apps/web/privacy.html',
  },
  {
    key: 'terms',
    title: 'Terms of Use',
    src: 'apps/web/content/terms.md',
    htmlOut: 'apps/web/terms.html',
  },
] as const;

function parseInlines(input: string): Inline[] {
  const out: Inline[] = [];
  const re = /(\*\*([^*]+)\*\*)|\[([^\]]+)\]\(([^)]+)\)/g;
  let last = 0;
  let m: RegExpExecArray | null;
  while ((m = re.exec(input)) !== null) {
    if (m.index > last) out.push({ kind: 'text', value: input.slice(last, m.index) });
    if (m[1]) out.push({ kind: 'bold', value: m[2] });
    else out.push({ kind: 'link', text: m[3], href: m[4] });
    last = m.index + m[0].length;
  }
  if (last < input.length) out.push({ kind: 'text', value: input.slice(last) });
  return out.length ? out : [{ kind: 'text', value: input }];
}

function parseMarkdown(md: string): Block[] {
  const lines = md.replace(/\r\n/g, '\n').split('\n');
  const blocks: Block[] = [];
  let i = 0;

  while (i < lines.length) {
    const line = lines[i] ?? '';
    if (!line.trim() || line.trim().startsWith('<!--')) {
      i += 1;
      continue;
    }

    const heading = /^(#{1,3})\s+(.+)$/.exec(line);
    if (heading) {
      blocks.push({
        type: 'heading',
        level: heading[1].length as 1 | 2 | 3,
        text: heading[2].trim(),
      });
      i += 1;
      continue;
    }

    if (/^[-*]\s+/.test(line)) {
      const items: Inline[][] = [];
      while (i < lines.length && /^[-*]\s+/.test(lines[i] ?? '')) {
        items.push(parseInlines((lines[i] ?? '').replace(/^[-*]\s+/, '').trim()));
        i += 1;
      }
      blocks.push({ type: 'list', items });
      continue;
    }

    const para: string[] = [];
    while (i < lines.length) {
      const cur = lines[i] ?? '';
      if (
        !cur.trim() ||
        cur.trim().startsWith('<!--') ||
        /^(#{1,3})\s+/.test(cur) ||
        /^[-*]\s+/.test(cur)
      ) {
        break;
      }
      para.push(cur.trim());
      i += 1;
    }
    if (para.length) blocks.push({ type: 'paragraph', inlines: parseInlines(para.join(' ')) });
  }

  return blocks;
}

function inlinesToHtml(inlines: Inline[]): string {
  return inlines
    .map((n) => {
      if (n.kind === 'text') return escapeHtml(n.value);
      if (n.kind === 'bold') return `<strong>${escapeHtml(n.value)}</strong>`;
      return `<a href="${escapeAttr(n.href)}">${escapeHtml(n.text)}</a>`;
    })
    .join('');
}

function blocksToHtml(blocks: Block[]): string {
  return blocks
    .map((b) => {
      if (b.type === 'heading') {
        const tag = `h${b.level + 1}`; // page already has h1 title
        return `<${tag}>${escapeHtml(b.text)}</${tag}>`;
      }
      if (b.type === 'paragraph') return `<p>${inlinesToHtml(b.inlines)}</p>`;
      const lis = b.items.map((item) => `<li>${inlinesToHtml(item)}</li>`).join('');
      return `<ul>${lis}</ul>`;
    })
    .join('\n');
}

function escapeHtml(s: string): string {
  return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

function escapeAttr(s: string): string {
  return escapeHtml(s).replace(/"/g, '&quot;');
}

function writeHtmlPage(title: string, contentHtml: string, outRel: string) {
  const templatePath = path.join(ROOT, 'apps/web/template/legal.template.html');
  const template = readFileSync(templatePath, 'utf8');
  if (!template.includes('{{TITLE}}') || !template.includes('{{CONTENT}}')) {
    throw new Error('legal.template.html missing {{TITLE}} or {{CONTENT}}');
  }
  const html = template
    .replaceAll('{{TITLE}}', escapeHtml(title))
    .replaceAll('{{CONTENT}}', contentHtml);
  const outPath = path.join(ROOT, outRel);
  mkdirSync(path.dirname(outPath), { recursive: true });
  writeFileSync(outPath, html, 'utf8');
  console.log(`wrote ${path.relative(ROOT, outPath)}`);
}

function main() {
  for (const doc of DOCS) {
    const md = readFileSync(path.join(ROOT, doc.src), 'utf8');
    const blocks = parseMarkdown(md);
    const html = blocksToHtml(blocks);
    writeHtmlPage(doc.title, html, doc.htmlOut);
  }

  // Legal pages link style.css; keep a copy next to apps/web/{privacy,terms}.html.
  const styleSrc = path.join(ROOT, 'apps/web/template/style.css');
  const styleDest = path.join(ROOT, 'apps/web/style.css');
  cpSync(styleSrc, styleDest);
  console.log('wrote apps/web/style.css');

  console.log('sync:legal complete');
}

main();
