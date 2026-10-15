namespace SportaApis.Helpers;

/// <summary>
/// حساب رسوم بوابة الدفع على عملية شحن المحفظة.
///
/// المبلغ المخصوم من البطاقة = المبلغ المطلوب + الرسوم، بينما يُضاف للمحفظة
/// المبلغ المطلوب فقط (المستخدم يتحمل الرسوم).
///
/// يُحسب هنا حصراً — الخادم يبلّغ التطبيق بالناتج عبر <c>/wallet/topup-quote</c>
/// بدل أن يعيد التطبيق الحساب، لأن اختلاف هللة واحدة بين الطرفين يجعل التحقق من
/// مطابقة المبلغ في <see cref="Services.WalletService"/> يرفض كل عملية.
/// </summary>
public static class TopUpFee
{
    /// <param name="amount">المبلغ المراد إضافته للمحفظة.</param>
    /// <param name="percent">نسبة رسوم البوابة (%) قبل الضريبة.</param>
    /// <param name="fixedFee">رسم ثابت لكل عملية قبل الضريبة.</param>
    /// <param name="vatPercent">ضريبة القيمة المضافة (%) على الرسوم لا على المبلغ.</param>
    /// <returns>الرسوم شاملة الضريبة، والإجمالي المخصوم من البطاقة.</returns>
    public static (decimal Fee, decimal Total) Calculate(
        decimal amount, decimal percent, decimal fixedFee, decimal vatPercent)
    {
        if (amount <= 0) return (0m, 0m);

        var net = amount * percent / 100m + fixedFee;
        if (net <= 0) return (0m, Round(amount));

        // الضريبة على الرسوم فقط؛ المبلغ المشحون نفسه ليس سلعة خاضعة للضريبة.
        var fee = Round(net * (1m + vatPercent / 100m));
        return (fee, Round(amount + fee));
    }

    /// <summary>
    /// تقريب لأقرب هللة بعيداً عن الصفر — يطابق ما يرسله التطبيق للبوابة
    /// (بالهللات)، خلافاً لتقريب .NET الافتراضي (banker's rounding).
    /// </summary>
    private static decimal Round(decimal value) =>
        Math.Round(value, 2, MidpointRounding.AwayFromZero);
}
