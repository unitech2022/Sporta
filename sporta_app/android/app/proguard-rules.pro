# قواعد R8 لبناء الإصدار. أُضيفت مع تفعيل isMinifyEnabled/isShrinkResources
# استجابةً لتوصية Google Play. القاعدة العامة: الإضافات (plugins) تشحن قواعدها
# الخاصة (consumer rules) تلقائياً، فلا نكرّرها هنا — نكتفي بما يلمسه R8 عبر
# الانعكاس (reflection) أو ما يشير إليه محرّك Flutter دون أن يوجد في الحزمة.

# ── محرّك Flutter والتضمين ───────────────────────────────────────────────────
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Play Core: يشير إليه تضمين Flutter لدعم المكوّنات المؤجّلة، ونحن لا نستعملها
# ولا نضمّ المكتبة، فيحذّر R8 من أصناف مفقودة دون أن يكون ذلك خطأ.
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.splitcompat.SplitCompatApplication { *; }

# ── البصمة/قفل الجهاز (local_auth) ───────────────────────────────────────────
# MainActivity يرث FlutterFragmentActivity ويُحمَّل بالاسم من البيان.
-keep class com.sportaapp.sporta_app.MainActivity { *; }
-keep class androidx.fragment.app.** { *; }
-keep class androidx.biometric.** { *; }

# ── إشعارات OneSignal ────────────────────────────────────────────────────────
# تستدعي أصنافاً بالانعكاس عبر مستقبلات البثّ والخدمات.
-keep class com.onesignal.** { *; }
-dontwarn com.onesignal.**

# ── Firebase / Google Services ───────────────────────────────────────────────
-dontwarn com.google.firebase.**
-keep class com.google.firebase.** { *; }

# ── عام ──────────────────────────────────────────────────────────────────────
# الأصناف المُشار إليها في AndroidManifest أو الموارد تُحمَّل بالاسم.
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod
-keepattributes SourceFile, LineNumberTable

-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# JNI / الدوال الأصلية.
-keepclasseswithmembernames class * {
    native <methods>;
}
