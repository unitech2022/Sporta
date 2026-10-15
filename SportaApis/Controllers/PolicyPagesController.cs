using System.Net;
using System.Text;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SportaApis.Services;

namespace SportaApis.Controllers;

/// <summary>
/// صفحات الوثائق القانونية كموقع عام يُفتح في المتصفح (متاجر التطبيقات تطلب
/// رابطاً علنياً لسياسة الخصوصية). النص يُقرأ من نفس إعدادات النظام التي
/// يحرّرها الأدمن — لا نسخة ثانية تُنسى.
///
/// <code>
/// /privacy      /privacy/ar      /privacy/en
/// /terms        /refund          (نفس الآلية)
/// </code>
/// اللغة الافتراضية بلا مقطع لغة: العربية.
/// </summary>
[ApiController]
[AllowAnonymous]
public class PolicyPagesController : ControllerBase
{
    private readonly ISettingsService _settings;

    public PolicyPagesController(ISettingsService settings) => _settings = settings;

    [HttpGet("/privacy")]
    [HttpGet("/privacy/{lang}")]
    public Task<IActionResult> Privacy(string? lang) => PageAsync("privacy_policy", lang);

    [HttpGet("/terms")]
    [HttpGet("/terms/{lang}")]
    public Task<IActionResult> Terms(string? lang) => PageAsync("terms_conditions", lang);

    [HttpGet("/refund")]
    [HttpGet("/refund/{lang}")]
    public Task<IActionResult> Refund(string? lang) => PageAsync("refund_policy", lang);

    /// <summary>المسارات الثلاثة ومقابلها العربي/الإنجليزي في شريط التنقل.</summary>
    private static readonly (string Path, string Key, string Ar, string En)[] Nav =
    {
        ("/privacy", "privacy_policy", "سياسة الخصوصية", "Privacy Policy"),
        ("/terms", "terms_conditions", "الشروط والأحكام", "Terms & Conditions"),
        ("/refund", "refund_policy", "سياسة الاسترجاع", "Refund Policy"),
    };

    private async Task<IActionResult> PageAsync(string key, string? lang)
    {
        // أي شيء عدا "en" يُعرض بالعربية — رابط بلغة مكتوبة خطأ لا يجب أن يعطي 404.
        var arabic = !string.Equals(lang, "en", StringComparison.OrdinalIgnoreCase);

        var setting = await _settings.GetByKeyAsync(key);
        if (setting == null)
            return NotFound(Html(BuildMissingPage(arabic), HttpStatusCode.NotFound));

        var body = arabic ? setting.ValueAr : setting.ValueEn;
        // الإنجليزية قد تكون فارغة لو حذفها الأدمن — العربية أفضل من صفحة بيضاء.
        if (string.IsNullOrWhiteSpace(body)) body = setting.ValueAr;

        var title = arabic ? setting.NameAr : setting.NameEn;
        return Html(BuildPage(key, title, body, arabic));
    }

    private ContentResult Html(string html, HttpStatusCode status = HttpStatusCode.OK) =>
        new()
        {
            Content = html,
            ContentType = "text/html; charset=utf-8",
            StatusCode = (int)status,
        };

    // ── بناء الصفحة ─────────────────────────────────────────────────────────

    private static string BuildPage(string key, string title, string markdown, bool arabic)
    {
        var sb = new StringBuilder();
        Head(sb, title, arabic);

        sb.Append("<header class=\"top\"><div class=\"wrap\">");
        sb.Append("<a class=\"brand\" href=\"/privacy/").Append(arabic ? "ar" : "en")
          .Append("\">SPORTA</a>");
        // نفس الصفحة باللغة الأخرى — يحافظ على الوثيقة التي يقرأها الزائر.
        var otherPath = Nav.First(n => n.Key == key).Path + (arabic ? "/en" : "/ar");
        sb.Append("<a class=\"lang\" href=\"").Append(otherPath).Append("\" hreflang=\"")
          .Append(arabic ? "en" : "ar").Append("\">")
          .Append(arabic ? "English" : "العربية").Append("</a>");
        sb.Append("</div></header>");

        sb.Append("<main class=\"wrap\">");
        sb.Append("<h1>").Append(Escape(title)).Append("</h1>");

        sb.Append("<nav class=\"docs\">");
        foreach (var (path, navKey, ar, en) in Nav)
        {
            var href = path + (arabic ? "/ar" : "/en");
            sb.Append("<a class=\"doc").Append(navKey == key ? " on" : "").Append("\" href=\"")
              .Append(href).Append("\">").Append(Escape(arabic ? ar : en)).Append("</a>");
        }
        sb.Append("</nav>");

        sb.Append("<article>");
        Render(sb, markdown);
        sb.Append("</article>");

        sb.Append("<footer><p>")
          .Append(arabic
              ? "للاستفسار عن هذه الوثيقة تواصل معنا عبر الدعم داخل تطبيق سبورتا."
              : "For questions about this document, contact us through support inside the Sporta app.")
          .Append("</p></footer>");

        sb.Append("</main></body></html>");
        return sb.ToString();
    }

    private static string BuildMissingPage(bool arabic)
    {
        var title = arabic ? "الوثيقة غير متاحة" : "Document unavailable";
        var sb = new StringBuilder();
        Head(sb, title, arabic);
        sb.Append("<main class=\"wrap\"><h1>").Append(Escape(title)).Append("</h1><article><p>")
          .Append(arabic
              ? "لم يُنشر نص هذه الوثيقة بعد. حاول لاحقاً أو تواصل مع الدعم."
              : "This document has not been published yet. Please try again later or contact support.")
          .Append("</p></article></main></body></html>");
        return sb.ToString();
    }

    private static void Head(StringBuilder sb, string title, bool arabic)
    {
        sb.Append("<!doctype html><html lang=\"").Append(arabic ? "ar" : "en")
          .Append("\" dir=\"").Append(arabic ? "rtl" : "ltr").Append("\"><head>");
        sb.Append("<meta charset=\"utf-8\">");
        sb.Append("<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">");
        sb.Append("<title>").Append(Escape(title)).Append(" — Sporta</title>");
        sb.Append("<style>").Append(Css).Append("</style>");
        sb.Append("</head><body>");
    }

    /// <summary>
    /// نفس نكهة الماركداون التي يعرضها التطبيق (policy_markdown.dart): عناوين
    /// <c>##</c> و<c>###</c>، ونقاط <c>-</c>، والأسطر المتتابعة فقرة واحدة.
    /// </summary>
    private static void Render(StringBuilder sb, string markdown)
    {
        var paragraph = new List<string>();
        var bullets = new List<string>();

        void FlushParagraph()
        {
            if (paragraph.Count == 0) return;
            sb.Append("<p>").Append(Escape(string.Join(' ', paragraph))).Append("</p>");
            paragraph.Clear();
        }

        void FlushBullets()
        {
            if (bullets.Count == 0) return;
            sb.Append("<ul>");
            foreach (var b in bullets) sb.Append("<li>").Append(Escape(b)).Append("</li>");
            sb.Append("</ul>");
            bullets.Clear();
        }

        foreach (var raw in markdown.Replace("\r\n", "\n").Split('\n'))
        {
            var line = raw.Trim();
            if (line.Length == 0)
            {
                FlushParagraph();
                FlushBullets();
            }
            else if (line.StartsWith("### ", StringComparison.Ordinal))
            {
                FlushParagraph();
                FlushBullets();
                sb.Append("<h3>").Append(Escape(line[4..])).Append("</h3>");
            }
            else if (line.StartsWith("## ", StringComparison.Ordinal))
            {
                FlushParagraph();
                FlushBullets();
                sb.Append("<h2>").Append(Escape(line[3..])).Append("</h2>");
            }
            else if (line.StartsWith("- ", StringComparison.Ordinal))
            {
                FlushParagraph();
                bullets.Add(line[2..]);
            }
            else
            {
                FlushBullets();
                paragraph.Add(line);
            }
        }

        FlushParagraph();
        FlushBullets();
    }

    /// <summary>
    /// النص يحرّره الأدمن، فيُهرَّب دائماً قبل الطباعة — وإلا صار حقل تعديل
    /// السياسة في اللوحة ثغرة XSS على نطاقنا.
    /// </summary>
    private static string Escape(string value) => WebUtility.HtmlEncode(value);

    private const string Css = """
    :root {
      --primary: #2ab5ce; --navy: #0a2540; --bg: #f8f9fa; --card: #fff;
      --ink: #1a1a1a; --muted: #6b7280; --border: #e5e7eb;
    }
    * { box-sizing: border-box; }
    body {
      margin: 0; background: var(--bg); color: var(--ink);
      font: 16px/1.85 -apple-system, BlinkMacSystemFont, "Segoe UI", Tahoma,
            "Helvetica Neue", Arial, sans-serif;
      -webkit-text-size-adjust: 100%;
    }
    .wrap { max-width: 820px; margin: 0 auto; padding: 0 20px; }
    .top { background: var(--navy); padding: 18px 0; }
    .top .wrap { display: flex; align-items: center; justify-content: space-between; }
    .brand {
      color: #fff; font-weight: 700; letter-spacing: .22em; font-size: 18px;
      text-decoration: none;
    }
    .lang {
      color: var(--navy); background: #fff; text-decoration: none;
      padding: 6px 16px; border-radius: 999px; font-size: 14px; font-weight: 600;
    }
    .lang:hover { background: var(--primary); color: #fff; }
    main { padding-bottom: 64px; }
    h1 {
      font-size: 30px; line-height: 1.35; margin: 40px 0 20px; color: var(--navy);
    }
    .docs { display: flex; flex-wrap: wrap; gap: 8px; margin-bottom: 28px; }
    .doc {
      font-size: 14px; text-decoration: none; color: var(--muted);
      border: 1px solid var(--border); background: var(--card);
      padding: 7px 15px; border-radius: 999px;
    }
    .doc:hover { color: var(--navy); border-color: var(--navy); }
    .doc.on { background: var(--primary); border-color: var(--primary); color: #fff; }
    article {
      background: var(--card); border: 1px solid var(--border); border-radius: 16px;
      padding: 12px 30px 30px;
    }
    article h2 {
      font-size: 20px; color: var(--navy); margin: 30px 0 12px;
      padding-top: 22px; border-top: 1px solid var(--border);
    }
    article h2:first-of-type { border-top: 0; padding-top: 6px; }
    article h3 { font-size: 17px; color: var(--navy); margin: 22px 0 8px; }
    article p { margin: 0 0 14px; }
    article ul { margin: 0 0 16px; padding-inline-start: 22px; }
    article li { margin-bottom: 8px; }
    footer { margin-top: 26px; color: var(--muted); font-size: 14px; text-align: center; }
    @media (max-width: 600px) {
      h1 { font-size: 24px; margin: 28px 0 16px; }
      article { padding: 10px 20px 22px; border-radius: 12px; }
      body { font-size: 15px; }
    }
    @media print {
      .top, .docs, footer { display: none; }
      body { background: #fff; }
      article { border: 0; padding: 0; }
    }
    """;
}
