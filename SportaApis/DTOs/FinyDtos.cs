using System.Text.Json.Serialization;

namespace SportaApis.DTOs;

/// <summary>غلاف ردود FINY الموحّد — النجاح والفشل بنفس الشكل.</summary>
public class FinyEnvelope<T>
{
    public bool Success { get; set; }
    public T? Data { get; set; }
    public string? Message { get; set; }
    public string? MessageAr { get; set; }
    public string? Code { get; set; }
}

/// <summary>عملية دفع لدى FINY كما تعود من <c>/api/v1/payments</c>.</summary>
public class FinyPayment
{
    public int Id { get; set; }
    public string? Number { get; set; }

    /// <summary>اسم التطبيق المالك — يُتحقق منه قبل اعتماد أي عملية.</summary>
    public string? Application { get; set; }

    public decimal Amount { get; set; }
    public string? Currency { get; set; }
    public string? Method { get; set; }

    /// <summary>created · pending · processing · paid · failed · cancelled …</summary>
    public string? Status { get; set; }

    /// <summary>عنوان صفحة الدفع أو تحقق 3-D Secure — null متى حُسمت العملية.</summary>
    public string? RedirectUrl { get; set; }

    public Dictionary<string, string>? Metadata { get; set; }

    public bool IsPaid =>
        string.Equals(Status, "paid", StringComparison.OrdinalIgnoreCase);
}

/// <summary>حدث وارد من FINY (webhook).</summary>
public class FinyWebhookEvent
{
    /// <summary>معرّف الحدث — يُخزَّن لتجاهل المكرر، فالحدث قد يصل مرتين.</summary>
    public string? Id { get; set; }

    /// <summary>payment.succeeded · payment.failed · payment.refunded …</summary>
    public string? Type { get; set; }

    public DateTime CreatedAt { get; set; }
    public FinyWebhookPayment? Data { get; set; }
}

public class FinyWebhookPayment
{
    public int Id { get; set; }
    public string? Number { get; set; }
    public decimal Amount { get; set; }
    public string? Currency { get; set; }
    public string? Status { get; set; }
    public string? Method { get; set; }
}

// ── ما يُرسَل إلى التطبيق ──────────────────────────────────────────────────────

/// <summary>جلسة شحن جاهزة: يفتح التطبيق <see cref="RedirectUrl"/> ثم يؤكّد.</summary>
public class TopUpSessionDto
{
    /// <summary>معرّف العملية لدى FINY — يُرسله التطبيق عند التأكيد.</summary>
    public int PaymentId { get; set; }

    /// <summary>صفحة الدفع المستضافة. يفتحها التطبيق في WebView.</summary>
    public string RedirectUrl { get; set; } = string.Empty;

    /// <summary>العنوان الذي يعني وصولُه انتهاءَ الدفع — يرصده التطبيق ويُغلق.</summary>
    public string CallbackUrl { get; set; } = string.Empty;

    /// <summary>المبلغ الذي سيُضاف للمحفظة.</summary>
    public decimal Amount { get; set; }

    /// <summary>الإجمالي المخصوم من البطاقة (المبلغ + الرسوم).</summary>
    public decimal Total { get; set; }
}

public class StartTopUpRequest
{
    [System.ComponentModel.DataAnnotations.Range(0.01, 1000000)]
    public decimal Amount { get; set; }

    public string? Description { get; set; }
}

public class ConfirmTopUpRequest
{
    [JsonPropertyName("paymentId")]
    public int PaymentId { get; set; }
}

/// <summary>شحن بـ Apple Pay: المبلغ + توكن ورقة آبل (paymentData) كما هو.</summary>
public class ApplePayTopUpRequest
{
    [System.ComponentModel.DataAnnotations.Range(0.01, 1000000)]
    public decimal Amount { get; set; }

    /// <summary>
    /// JSON توكن Apple Pay الخام من PassKit — مشفّر لميسر وحده؛ لا نقرؤه ولا
    /// نخزّنه، بل نمرّره إلى FINY في نداء واحد.
    /// </summary>
    [System.ComponentModel.DataAnnotations.Required]
    public string Token { get; set; } = string.Empty;

    public string? Description { get; set; }
}
