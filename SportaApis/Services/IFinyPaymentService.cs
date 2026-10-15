using SportaApis.DTOs;

namespace SportaApis.Services;

public interface IFinyPaymentService
{
    /// <summary>هل الربط مضبوط؟ يُفحص قبل عرض الدفع في التطبيق.</summary>
    bool IsConfigured { get; }

    /// <summary>
    /// ينشئ عملية دفع لدى FINY ويعيدها بصفحة دفعها. الطلب موقَّع، والمبلغ داخل
    /// التوقيع — فلا يعدّله أحد بين تطبيقنا وFINY.
    /// </summary>
    /// <param name="metadata">
    /// بيانات تعود كما هي في كل استعلام لاحق. عبرها نعرف لاحقاً صاحب العملية
    /// والمبلغ المتفق عليه، فلا نحتاج جدولاً وسيطاً عندنا.
    /// </param>
    /// <param name="paymentMethod">
    /// طريقة الدفع بمفردات FINY (<c>applepay</c>…) — null تترك الاختيار
    /// لصفحة الدفع المستضافة.
    /// </param>
    Task<FinyPayment> CreatePaymentAsync(
        decimal amount,
        string description,
        Dictionary<string, string> metadata,
        string? idempotencyKey = null,
        string? paymentMethod = null,
        CancellationToken ct = default);

    /// <summary>
    /// يجلب العملية من FINY. هي المصدر الوحيد الموثوق لحالة الدفع: التطبيق
    /// يقول «انتهيت» والإشعار قد يتأخر، وكلاهما لا يُعتمد لتحريك رصيد.
    /// </summary>
    Task<FinyPayment?> GetPaymentAsync(int paymentId, CancellationToken ct = default);
}
