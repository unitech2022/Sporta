#!/usr/bin/env node
/**
 * خادم معاينة محلي لمجلد `dist` — للتجربة قبل الرفع فقط، لا للإنتاج.
 * بلا أي حزم خارجية.
 *
 *   npm run preview        يبني ثم يفتح على 4173
 *   PORT=8080 node serve.mjs
 */
import { createReadStream } from 'node:fs';
import { stat } from 'node:fs/promises';
import { createServer } from 'node:http';
import { dirname, extname, join, normalize } from 'node:path';
import { fileURLToPath } from 'node:url';

const dist = join(dirname(fileURLToPath(import.meta.url)), 'dist');
const port = Number(process.env.PORT) || 4173;

const TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.xml': 'application/xml; charset=utf-8',
  '.txt': 'text/plain; charset=utf-8',
};

createServer(async (req, res) => {
  const url = new URL(req.url, 'http://localhost');
  // normalize يمنع الخروج من dist عبر «..» في المسار.
  let path = normalize(decodeURIComponent(url.pathname)).replace(/^(\.\.[/\\])+/, '');
  if (path.endsWith('/')) path += 'index.html';

  const file = join(dist, path);
  try {
    const info = await stat(file);
    if (!info.isFile()) throw new Error('not a file');
    res.writeHead(200, { 'Content-Type': TYPES[extname(file)] ?? 'application/octet-stream' });
    createReadStream(file).pipe(res);
  } catch {
    res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
    res.end('404');
  }
}).listen(port, () => {
  console.log(`▸ معاينة: http://localhost:${port}/  (Ctrl+C للإيقاف)`);
});
