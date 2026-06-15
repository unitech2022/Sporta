# Sporta

تطبيق حجز وإدارة المباريات الرياضية. يحتوي هذا المستودع على مشروعين:

## 📱 sporta_app — تطبيق Flutter
واجهة المستخدم (موبايل). معمارية feature-first تحت `lib/features/`.

```bash
cd sporta_app
flutter pub get
flutter run
```

## 🖥️ SportaApis — الواجهة الخلفية (ASP.NET Core + EF Core / MySQL)
واجهات REST مع مصادقة JWT.

```bash
cd SportaApis
dotnet restore
dotnet ef database update   # تطبيق الـ migrations على قاعدة البيانات
dotnet run
```

> اضبط `appsettings.Development.json` (سلسلة الاتصال + مفتاح JWT) قبل التشغيل.

## الحالة الحالية
- ✅ المصادقة (تسجيل/دخول/OTP) مربوطة end-to-end.
- ✅ تسجيل الأدوار (لاعب/مدرب/مالك ملعب) مع إنشاء الملفات الخاصة بكل دور.
- ✅ اختيار اللعبة المفضلة + تقييم مستوى اللاعب (سلّم 1..7) وعرضه.
- ✅ الملاعب والحجز مربوطة end-to-end: عرض الملاعب (`GET /api/courts`)، تفاصيل ملعب، التوافر حسب اليوم (`/availability`)، إنشاء حجز (`POST /api/bookings`)، حجوزاتي وإلغاء الحجز. يوجد seed تجريبي للملاعب في بيئة التطوير.
- 🟡 باقي الشاشات (المباريات/المدربين/الدفع) واجهات على بيانات مبدئية، قيد الربط.
