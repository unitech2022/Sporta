/**
 * إعدادات موقع السياسات. عدّل هنا فقط — البناء يقرأ منه.
 */
export default {
  /**
   * دومين الموقع بعد الرفع (بلا شرطة في آخره). يُستخدم في sitemap.xml
   * وروابط hreflang التي تربط النسخة العربية بالإنجليزية.
   * غيّره إلى دومينك قبل أول بناء.
   */
  siteUrl: 'https://policy.sportaapp.net',

  /**
   * مصدر النص: نفس النقطة العامة التي يقرأ منها التطبيق، فما يحرّره الأدمن
   * في لوحة التحكم هو ما يظهر هنا عند إعادة البناء.
   * للبناء من باك إند محلي: API_BASE=http://localhost:7050 npm run build
   */
  apiBase: process.env.API_BASE || 'https://apis.sportaapp.net',

  brand: 'SPORTA',

  /** رابط تواصل يظهر في تذييل كل صفحة (اتركه فارغاً لإخفاء السطر). */
  contactEmail: 'support@sportaapp.net',

  /**
   * الوثائق المنشورة. `key` هو مفتاح الإعداد في الخادم، و`slug` اسم الملف.
   * احذف سطراً لتتوقف صفحته عن الصدور.
   */
  documents: [
    { key: 'privacy_policy', slug: 'privacy' },
    { key: 'terms_conditions', slug: 'terms' },
    { key: 'refund_policy', slug: 'refund' },
  ],

  /** الوثيقة التي يفتح عليها الدومين، واللغة الافتراضية. */
  home: { slug: 'privacy', lang: 'ar' },
};
