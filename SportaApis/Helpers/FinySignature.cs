using System.Security.Cryptography;
using System.Text;

namespace SportaApis.Helpers;

/// <summary>
/// توقيع طلبات FINY والتحقق من إشعاراتها.
///
/// التوقيعان مختلفان عمداً ولا يُخلطان:
/// الصادر <c>t=&lt;unix&gt;,v1=&lt;hex&gt;</c> بسرّ الـ API ويغطّي الطريقة
/// والمسار والجسم — فلا يعدّل وسيطٌ المبلغ ولا يُعاد إرسال طلب ناجح.
/// والوارد hex مجرّد بسرّ الـ Webhook على الجسم الخام.
/// </summary>
public static class FinySignature
{
    /// <summary>
    /// قيمة ترويسة <c>X-Finy-Signature</c> لطلب صادر.
    /// </summary>
    /// <param name="body">
    /// الجسم كما سيُرسَل حرفياً. أي إعادة تسلسل بعد التوقيع (ترتيب مفاتيح أو
    /// مسافة) تُنتج توقيعاً لا يطابق ما وصل — وهو أشيع أخطاء التكامل.
    /// </param>
    public static string ForRequest(
        string apiSecret, string method, string path, string body, DateTimeOffset now)
    {
        var t = now.ToUnixTimeSeconds();
        var bodyHash = Hex(SHA256.HashData(Encoding.UTF8.GetBytes(body)));
        var canonical = $"v1:{t}:{method.ToUpperInvariant()}:{path}:{bodyHash}";
        var v1 = Hex(HMACSHA256.HashData(
            Encoding.UTF8.GetBytes(apiSecret), Encoding.UTF8.GetBytes(canonical)));

        return $"t={t},v1={v1}";
    }

    /// <summary>
    /// هل هذا الإشعار من FINY فعلاً؟ يُنادى على الجسم الخام قبل أي تحليل —
    /// تحليلُ ما لم يُتحقق منه بعدُ هو تنفيذ لمدخلات مجهولة المصدر.
    /// </summary>
    public static bool VerifyWebhook(string webhookSecret, string rawBody, string? signature)
    {
        if (string.IsNullOrWhiteSpace(webhookSecret) || string.IsNullOrWhiteSpace(signature))
            return false;

        var expected = Hex(HMACSHA256.HashData(
            Encoding.UTF8.GetBytes(webhookSecret), Encoding.UTF8.GetBytes(rawBody)));
        var given = signature.Trim().ToLowerInvariant();

        // مقارنة ثابتة الزمن: المقارنة العادية تتوقف عند أول اختلاف، فيُستدل من
        // زمنها على التوقيع الصحيح حرفاً حرفاً.
        var expectedBytes = Encoding.UTF8.GetBytes(expected);
        var givenBytes = Encoding.UTF8.GetBytes(given);
        return expectedBytes.Length == givenBytes.Length &&
               CryptographicOperations.FixedTimeEquals(expectedBytes, givenBytes);
    }

    private static string Hex(byte[] bytes) => Convert.ToHexString(bytes).ToLowerInvariant();
}
