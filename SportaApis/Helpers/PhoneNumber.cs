namespace SportaApis.Helpers;

/// <summary>
/// أرقام الجوال تُخزَّن في القاعدة بالصيغة المحلية <c>05xxxxxxxx</c> — هي ما
/// يكتبه المستخدم وما تبحث به كل استعلاماتنا. مزوّدو الرسائل يشترطون E.164
/// (<c>+9665xxxxxxxx</c>)، فالتحويل يحصل عند حدود النظام فقط: نُطبّع الوارد إلى
/// الصيغة المحلية قبل أي مقارنة، ونحوّل إلى E.164 لحظة النداء الخارجي.
/// </summary>
public static class PhoneNumber
{
    private const string SaudiCode = "966";

    /// <summary>
    /// يُرجِع الرقم بالصيغة المحلية <c>05xxxxxxxx</c>، أو <c>null</c> إن لم يكن
    /// رقم جوال سعودياً صالحاً. يقبل <c>05…</c> و<c>5…</c> و<c>9665…</c>
    /// و<c>+9665…</c> و<c>009665…</c>، ويتجاهل المسافات والشرطات.
    /// </summary>
    public static string? TryNormalize(string? raw)
    {
        if (string.IsNullOrWhiteSpace(raw)) return null;

        var digits = new string(raw.Where(char.IsDigit).ToArray());

        if (digits.StartsWith("00" + SaudiCode, StringComparison.Ordinal))
            digits = digits[(2 + SaudiCode.Length)..];
        else if (digits.StartsWith(SaudiCode, StringComparison.Ordinal))
            digits = digits[SaudiCode.Length..];

        // بعد نزع المفتاح الدولي يبقى إمّا "5xxxxxxxx" أو "05xxxxxxxx".
        if (digits.Length == 9 && digits[0] == '5') digits = "0" + digits;

        return digits.Length == 10 && digits.StartsWith("05", StringComparison.Ordinal)
            ? digits
            : null;
    }

    /// <summary>
    /// نفس <see cref="TryNormalize"/> لكن يرمي عند رقم غير صالح — يُستخدم في
    /// المسارات التي يجب ألّا تمضي برقم مشوَّه (إرسال OTP مثلاً، فكل نداء بتكلفة).
    /// </summary>
    public static string Normalize(string? raw) =>
        TryNormalize(raw) ?? throw new ArgumentException($"Invalid Saudi mobile number: '{raw}'", nameof(raw));

    /// <summary>يحوّل رقماً محلياً أو أي صيغة مقبولة إلى <c>+9665xxxxxxxx</c>.</summary>
    public static string ToE164(string? raw) => "+" + SaudiCode + Normalize(raw)[1..];

    /// <summary>
    /// يُخفي وسط الرقم للسجلّات: <c>0501234567</c> ← <c>0501***567</c>. لا
    /// نكتب رقماً كاملاً في اللوق.
    /// </summary>
    public static string Mask(string? raw)
    {
        var local = TryNormalize(raw);
        if (local is null) return "***";
        return local[..4] + "***" + local[^3..];
    }
}
