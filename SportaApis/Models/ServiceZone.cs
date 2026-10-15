namespace SportaApis.Models;

/// <summary>
/// منطقة خدمة جغرافية يرسمها المشرف من لوحة التحكم كمضلّع على الخريطة.
///
/// القواعد:
/// - لا توجد مناطق مفعّلة → التطبيق يعمل في كل مكان.
/// - توجد مناطق مفعّلة → يجب أن يكون المستخدم داخل إحداها وإلا ظهرت له
///   رسالة «أنت حالياً خارج نطاق خدمة التطبيق».
/// </summary>
public class ServiceZone : BaseEntity
{
    public string NameAr { get; set; } = string.Empty;
    public string NameEn { get; set; } = string.Empty;

    /// <summary>
    /// رؤوس المضلّع كـ JSON: [[lat,lng],[lat,lng],...] بترتيب الرسم.
    /// لا يُشترط تكرار النقطة الأولى في النهاية.
    /// </summary>
    public string PolygonJson { get; set; } = "[]";

    /// <summary>لون العرض على خريطة اللوحة (اختياري، hex).</summary>
    public string? Color { get; set; }

    public bool IsActive { get; set; } = true;
}
