#!/usr/bin/env node
/**
 * يبني موقع السياسات في `dist/`.
 *
 * يقرأ نص كل وثيقة من نقطة الإعدادات العامة في الـ API — أي أن مصدر الحقيقة
 * واحد: ما يحرّره الأدمن في لوحة التحكم. أعد التشغيل بعد أي تعديل على السياسات.
 *
 *   npm run build                          من الإنتاج
 *   API_BASE=http://localhost:7050 npm run build   من باك إند محلي
 */
import { mkdir, readFile, rm, writeFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

import config from './site.config.mjs';
import { escape, fileName, renderPage } from './src/render.mjs';

const root = dirname(fileURLToPath(import.meta.url));
const dist = join(root, 'dist');
const LANGS = ['ar', 'en'];

const api = config.apiBase.replace(/\/+$/, '');
const site = config.siteUrl.replace(/\/+$/, '');
// تاريخ محلي لا UTC — وإلا ظهر تاريخ الأمس لمن يبني ليلاً بتوقيت السعودية.
const buildDate = (() => {
  const d = new Date();
  const pad = (n) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
})();

/** يجلب وثيقة واحدة، ويشرح سبب الفشل بدل ترك رسالة fetch الغامضة. */
async function fetchDocument(key) {
  const url = `${api}/api/settings/public/${key}`;
  let res;
  try {
    res = await fetch(url, { signal: AbortSignal.timeout(20_000) });
  } catch (cause) {
    throw new Error(`تعذّر الوصول إلى ${url} — تحقّق أن الـ API يعمل`, { cause });
  }
  if (!res.ok) throw new Error(`${url} أعاد ${res.status}`);

  const payload = await res.json();
  const data = payload?.data;
  if (!data) throw new Error(`لا توجد وثيقة بالمفتاح "${key}" على ${api}`);

  // الإنجليزية قد تكون فارغة لو حذفها الأدمن — العربية أفضل من صفحة بيضاء.
  const valueEn = data.valueEn?.trim() ? data.valueEn : data.valueAr;
  if (!data.valueAr?.trim()) throw new Error(`نص الوثيقة "${key}" فارغ على الخادم`);

  return {
    ar: { title: data.nameAr, body: data.valueAr },
    en: { title: data.nameEn || data.nameAr, body: valueEn },
  };
}

async function main() {
  if (!/^https?:\/\/[^/]+\.[^/]+$/.test(site)) {
    console.warn(`! siteUrl لا يبدو دوماً صالحاً (${site}) — راجع site.config.mjs`);
  }

  console.log(`▸ المصدر: ${api}`);
  const docs = await Promise.all(
    config.documents.map(async (d) => ({ ...d, langs: await fetchDocument(d.key) }))
  );

  const styles = await readFile(join(root, 'src', 'styles.css'), 'utf8');

  await rm(dist, { recursive: true, force: true });
  await mkdir(dist, { recursive: true });

  const written = [];
  const write = async (name, content) => {
    await writeFile(join(dist, name), content, 'utf8');
    written.push(name);
  };

  for (const doc of docs) {
    for (const lang of LANGS) {
      const { title, body } = doc.langs[lang];
      const nav = docs.map((d) => ({ slug: d.slug, title: d.langs[lang].title }));
      const html = renderPage({
        config, slug: doc.slug, lang, title, body, nav, buildDate,
      }).replace('__STYLES__', styles);
      await write(fileName(doc.slug, lang), html);
    }
  }

  // جذر الدومين → الوثيقة الافتراضية. تحويل فوري مع رابط يدوي إن عُطّل.
  const home = fileName(config.home.slug, config.home.lang);
  const homeAlt = fileName(config.home.slug, config.home.lang === 'ar' ? 'en' : 'ar');
  await write(
    'index.html',
    `<!doctype html>
<html lang="${config.home.lang}" dir="${config.home.lang === 'ar' ? 'rtl' : 'ltr'}">
<head>
<meta charset="utf-8">
<meta http-equiv="refresh" content="0; url=${home}">
<link rel="canonical" href="${site}/${home}">
<title>${escape(config.brand)}</title>
</head>
<body><p><a href="${home}">${escape(config.brand)}</a> · <a href="${homeAlt}">English / العربية</a></p></body>
</html>
`
  );

  const urls = docs.flatMap((d) => LANGS.map((l) => `${site}/${fileName(d.slug, l)}`));
  await write(
    'sitemap.xml',
    `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
${urls.map((u) => `  <url><loc>${u}</loc><lastmod>${buildDate}</lastmod></url>`).join('\n')}
</urlset>
`
  );

  await write('robots.txt', `User-agent: *\nAllow: /\nSitemap: ${site}/sitemap.xml\n`);

  console.log(`▸ dist/ (${written.length} ملفاً)`);
  for (const f of written) console.log(`  ${f}`);
  console.log(`✓ جاهز للرفع — تاريخ النسخة ${buildDate}`);
}

main().catch((err) => {
  console.error(`✗ فشل البناء: ${err.message}`);
  if (err.cause) console.error(`  السبب: ${err.cause.message ?? err.cause}`);
  process.exitCode = 1;
});
