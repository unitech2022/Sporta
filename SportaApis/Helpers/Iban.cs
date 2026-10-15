using System.Numerics;
using System.Text;

namespace SportaApis.Helpers;

/// <summary>
/// تطبيع رقم الآيبان والتحقق منه. التحقق ليس على الطول فقط بل بخوارزمية
/// mod-97 المعيارية (ISO 13616) — لأن خطأ رقم واحد في الآيبان يحوّل المال
/// لحساب آخر، والطول وحده لا يكشف ذلك.
/// </summary>
public static class Iban
{
    /// <summary>طول الآيبان السعودي: SA + رقمَي تحقق + 20 خانة = 24.</summary>
    public const int SaudiLength = 24;

    /// <summary>يزيل المسافات ويحوّل لحروف كبيرة — الصيغة المخزَّنة.</summary>
    public static string Normalize(string? raw) =>
        (raw ?? string.Empty).Replace(" ", string.Empty).Replace("-", string.Empty).ToUpperInvariant();

    /// <summary>
    /// صالح شكلاً ورقمَي تحقق. <paramref name="countryCode"/> يقيّده بدولة
    /// (null = أي دولة) — الافتراضي السعودية لأن التحويلات محلية.
    /// </summary>
    public static bool IsValid(string? raw, string? countryCode = "SA")
    {
        var iban = Normalize(raw);

        // 15..34 هو المدى المعياري لأطوال الآيبان عالمياً.
        if (iban.Length < 15 || iban.Length > 34) return false;
        if (!iban.All(char.IsLetterOrDigit)) return false;
        if (!char.IsLetter(iban[0]) || !char.IsLetter(iban[1])) return false;
        if (!char.IsDigit(iban[2]) || !char.IsDigit(iban[3])) return false;

        if (countryCode is not null)
        {
            if (!iban.StartsWith(countryCode, StringComparison.Ordinal)) return false;
            if (countryCode == "SA" && iban.Length != SaudiLength) return false;
        }

        // mod-97: تُنقل أول أربعة محارف للنهاية، ويُستبدل كل حرف برقمه (A=10…Z=35)،
        // ثم يجب أن يكون الباقي على 97 مساوياً 1.
        var rearranged = iban[4..] + iban[..4];
        var digits = new StringBuilder(rearranged.Length * 2);
        foreach (var ch in rearranged)
        {
            if (char.IsDigit(ch)) digits.Append(ch);
            else digits.Append(ch - 'A' + 10);
        }

        return BigInteger.TryParse(digits.ToString(), out var value)
               && value % 97 == 1;
    }

    /// <summary>عرض مُقنَّع للسجلات والواجهات: SA03 •••• •••• 1234.</summary>
    public static string Mask(string? raw)
    {
        var iban = Normalize(raw);
        if (iban.Length < 8) return iban;
        return $"{iban[..4]} •••• {iban[^4..]}";
    }
}
