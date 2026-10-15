# توقيع نسخة الإصدار واستخراج الـ Bundle

نسخة الإصدار مهيّأة لقراءة مفتاح التوقيع من `android/key.properties` (مستثنى من
git). بدون هذا الملف تُبنى النسخة بمفاتيح debug — تعمل للتجربة لكن **لا تُرفع على
Google Play**. للنشر الرسمي أنشئ مفتاح التوقيع مرة واحدة كالتالي.

> ⚠️ **كلمة مرور مفتاح التوقيع سرّ تملكه أنت.** لا تشاركها، ولا تفقدها —
> فقدانها يعني عدم القدرة على تحديث التطبيق على المتجر لاحقاً. لهذا تنشئه بنفسك
> ولم أنشئه لك.

## ١) أنشئ مفتاح التوقيع (مرة واحدة)

```bash
keytool -genkey -v \
  -keystore ~/sporta-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```
يطلب منك كلمة مرور واسمك — أدخل ما تريد واحفظه في مكان آمن. احتفظ بملف
`sporta-upload.jks` خارج المشروع (مثلاً في مجلد المنزل) ولا ترفعه على git.

## ٢) اربطه بالمشروع

أنشئ `android/key.properties` (لا يُرفع على git) بالقيم التي أدخلتها:

```properties
storePassword=كلمة_مرور_المخزن
keyPassword=كلمة_مرور_المفتاح
keyAlias=sporta
storeFile=sporta-upload.jks
```
`storeFile` مسار نسبي إلى `android/app/`. المفتاح الحالي موضوع في
`android/app/sporta-upload.jks` (مستثنى من git عبر قاعدة `**/*.jks`)، ونسخة
احتياطية منه في `~/sporta-upload.jks`.

## ٣) استخرج الـ Bundle

```bash
cd sporta_app
flutter build appbundle --release
```
الناتج: `build/app/outputs/bundle/release/app-release.aab` — هذا ما ترفعه على
Google Play Console.

للتجربة على جهاز (APK بدل bundle):
```bash
flutter build apk --release
```

## ملاحظات

- **العنوان:** التطبيق يستهدف الإنتاج (`https://apis.sportaapp.net`) افتراضياً،
  فالنسخة تضرب السيرفر الحقيقي مباشرة.
- **رقم الإصدار:** حالياً `1.0.0+1` في `pubspec.yaml` (`version: 1.0.0+1`).
  ارفع الرقم بعد `+` (versionCode) في كل رفعة جديدة للمتجر — Google Play يرفض
  نفس الرقم مرتين. مثال للتحديث التالي: `1.0.1+2`.
- **اسم التطبيق تحت الأيقونة:** "سبورتا" (عدّله في
  `android/app/src/main/AndroidManifest.xml` → `android:label` لو أردت غيره).
- **usesCleartextTraffic:** مفعّل حالياً للسماح بالتطوير المحلي عبر http. غير
  ضروري للإنتاج (https)، وتقدر تزيله من الـ manifest قبل النشر لتشديد الأمان.
