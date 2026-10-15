/**
 * تحويل نص السياسة إلى صفحة HTML مكتفية بذاتها.
 *
 * نكهة الماركداون هنا هي نفسها التي يعرضها التطبيق
 * (sporta_app/lib/features/settings/presentation/widgets/policy_markdown.dart):
 * عناوين `##` و`###`، ونقاط `-`، والأسطر المتتابعة فقرة واحدة. لا شيء غيرها —
 * فأي صياغة أخرى في النص ستظهر كما هي.
 */

/** النص يحرّره الأدمن، فيُهرَّب دائماً قبل الطباعة (وإلا صار حقل التعديل ثغرة XSS). */
export const escape = (s) =>
  String(s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');

export function markdownToHtml(markdown) {
  const out = [];
  let paragraph = [];
  let bullets = [];

  const flushParagraph = () => {
    if (!paragraph.length) return;
    out.push(`<p>${escape(paragraph.join(' '))}</p>`);
    paragraph = [];
  };
  const flushBullets = () => {
    if (!bullets.length) return;
    out.push(`<ul>${bullets.map((b) => `<li>${escape(b)}</li>`).join('')}</ul>`);
    bullets = [];
  };

  for (const raw of String(markdown).replace(/\r\n/g, '\n').split('\n')) {
    const line = raw.trim();
    if (!line) {
      flushParagraph();
      flushBullets();
    } else if (line.startsWith('### ')) {
      flushParagraph();
      flushBullets();
      out.push(`<h3>${escape(line.slice(4))}</h3>`);
    } else if (line.startsWith('## ')) {
      flushParagraph();
      flushBullets();
      out.push(`<h2>${escape(line.slice(3))}</h2>`);
    } else if (line.startsWith('- ')) {
      flushParagraph();
      bullets.push(line.slice(2));
    } else {
      flushBullets();
      paragraph.push(line);
    }
  }
  flushParagraph();
  flushBullets();
  return out.join('\n');
}

/** أول فقرة نصية، مقصوصة — لوصف الصفحة في نتائج البحث والمشاركة. */
function summarize(markdown, limit = 155) {
  const line = String(markdown)
    .split('\n')
    .map((l) => l.trim())
    .find((l) => l && !l.startsWith('#') && !l.startsWith('- '));
  if (!line) return '';
  return line.length <= limit ? line : `${line.slice(0, limit - 1).trimEnd()}…`;
}

export const fileName = (slug, lang) => `${slug}-${lang}.html`;

/**
 * يبني صفحة وثيقة كاملة.
 *
 * @param {object} p
 * @param {import('../site.config.mjs').default} p.config
 * @param {string} p.slug        وثيقة هذه الصفحة
 * @param {'ar'|'en'} p.lang
 * @param {string} p.title       اسم الوثيقة بلغة الصفحة
 * @param {string} p.body        نص الوثيقة (ماركداون)
 * @param {Array<{slug: string, title: string}>} p.nav  كل الوثائق بلغة الصفحة
 * @param {string} p.buildDate   YYYY-MM-DD
 */
export function renderPage({ config, slug, lang, title, body, nav, buildDate }) {
  const ar = lang === 'ar';
  const other = ar ? 'en' : 'ar';
  const site = config.siteUrl.replace(/\/+$/, '');

  const t = ar
    ? {
        version: 'تاريخ هذه النسخة',
        contact: 'لأي استفسار عن هذه الوثيقة راسلنا على',
        switch: 'English',
      }
    : {
        version: 'Version date',
        contact: 'For any question about this document, email us at',
        switch: 'العربية',
      };

  const navLinks = nav
    .map(
      (d) =>
        `<a class="doc${d.slug === slug ? ' on' : ''}" href="${fileName(d.slug, lang)}">` +
        `${escape(d.title)}</a>`
    )
    .join('');

  // hreflang يربط النسختين ببعضهما، فتعرض محركات البحث الصحيحة لكل زائر.
  const alternates = ['ar', 'en']
    .map(
      (l) =>
        `<link rel="alternate" hreflang="${l}" href="${site}/${fileName(slug, l)}">`
    )
    .join('');

  const contact = config.contactEmail
    ? `<p>${escape(t.contact)} <a href="mailto:${escape(config.contactEmail)}">` +
      `${escape(config.contactEmail)}</a></p>`
    : '';

  return `<!doctype html>
<html lang="${lang}" dir="${ar ? 'rtl' : 'ltr'}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${escape(title)} — ${escape(config.brand)}</title>
<meta name="description" content="${escape(summarize(body))}">
<link rel="canonical" href="${site}/${fileName(slug, lang)}">
${alternates}
<meta property="og:title" content="${escape(title)} — ${escape(config.brand)}">
<meta property="og:type" content="article">
<style>__STYLES__</style>
</head>
<body>
<header class="top"><div class="wrap">
<a class="brand" href="${fileName(config.home.slug, lang)}">${escape(config.brand)}</a>
<a class="lang" href="${fileName(slug, other)}" hreflang="${other}">${escape(t.switch)}</a>
</div></header>
<main class="wrap">
<h1>${escape(title)}</h1>
<nav class="docs">${navLinks}</nav>
<article>
${markdownToHtml(body)}
</article>
<footer>
<p>${escape(t.version)}: <time datetime="${buildDate}">${buildDate}</time></p>
${contact}
</footer>
</main>
</body>
</html>
`;
}
