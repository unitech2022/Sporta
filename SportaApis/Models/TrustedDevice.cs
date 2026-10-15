namespace SportaApis.Models;

/// <summary>
/// جهاز موثوق: هاتفٌ سجّل صاحبُ الحساب بصمته عليه. الدخول العادي يتم منه
/// وحده — بالرقم + سرّ الجهاز الذي لا يُفرَج عنه إلا بعد بصمة نظام التشغيل —
/// فمعرفةُ الرقم على هاتفٍ آخر لا تكفي للدخول. الهاتف الجديد يمرّ برمز
/// واتساب مرة واحدة ثم يُسجَّل هو الآخر.
///
/// السرّ لا يُخزَّن هنا، بل تجزئته: تسريب القاعدة لا يُسلّم أجهزة أحد.
/// </summary>
public class TrustedDevice : BaseEntity
{
    public int UserId { get; set; }

    /// <summary>معرّف يولّده التطبيق مرة واحدة لكل تثبيت.</summary>
    public string DeviceId { get; set; } = string.Empty;

    /// <summary>SHA-256 لسرّ الجهاز (hex).</summary>
    public string SecretHash { get; set; } = string.Empty;

    public string? Name { get; set; }

    /// <summary>ios | android | غير ذلك.</summary>
    public string? Platform { get; set; }

    public DateTime? LastUsedAt { get; set; }
    public DateTime? RevokedAt { get; set; }

    // Navigation
    public User User { get; set; } = null!;

    public bool IsActive => RevokedAt is null;
}
