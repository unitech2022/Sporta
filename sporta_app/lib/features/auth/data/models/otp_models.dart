/// الغرض الذي يُطلب رمز التحقق لأجله. يُرسَل مع كل طلب لأن الخادم يفرض به
/// شرطاً مختلفاً: [register] يشترط رقماً غير مسجّل، وبقيته تشترط حساباً قائماً.
/// الرمز الصادر لغرضٍ لا يصلح لغيره.
enum OtpPurpose {
  login('login'),
  register('register'),
  deleteAccount('delete');

  const OtpPurpose(this.wire);

  /// القيمة كما يفهمها الخادم.
  final String wire;
}

/// ردّ `POST /auth/otp/request` — يغذّي عدّاد الشاشة وزر «إعادة الإرسال».
class OtpRequested {
  const OtpRequested({
    required this.channel,
    required this.codeLength,
    required this.expiresInSeconds,
    required this.resendAfterSeconds,
    this.devCode,
  });

  factory OtpRequested.fromJson(Map<String, dynamic> json) => OtpRequested(
        channel: json['channel'] as String? ?? 'whatsapp',
        // 6 احتياطاً لخادم قديم لا يرسل الحقل؛ الخادم الحالي يرسله دائماً.
        codeLength: json['codeLength'] as int? ?? 6,
        expiresInSeconds: json['expiresInSeconds'] as int? ?? 600,
        resendAfterSeconds: json['resendAfterSeconds'] as int? ?? 60,
        devCode: json['devCode'] as String?,
      );

  /// القناة التي وصل عبرها فعلاً: `whatsapp` أو `sms` — تُذكر للمستخدم كي يبحث
  /// عن الرسالة في المكان الصحيح حين يسقط الخادم إلى الاحتياطي.
  final String channel;

  /// عدد خانات الرمز كما يقرّره الخادم. لا يُثبَّت في التطبيق: طول رمز المزوّد
  /// قد يتغيّر بتغيير قالبه، وشاشةٌ بخانات أكثر من أرقام الرمز لا تقبله أبداً.
  final int codeLength;

  final int expiresInSeconds;
  final int resendAfterSeconds;

  /// الرمز نصّاً — يصل من خادم التطوير وحده، ويظل `null` في الإنتاج.
  final String? devCode;

  bool get isWhatsApp => channel == 'whatsapp';
}
