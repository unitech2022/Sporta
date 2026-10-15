using System.ComponentModel.DataAnnotations;

namespace SportaApis.DTOs;

// ── Requests ──────────────────────────────────────────────────────────────────

/// <summary>تفصيل ما سيُخصم من البطاقة مقابل شحن مبلغ معيّن.</summary>
public class TopUpQuoteDto
{
    /// <summary>المبلغ الذي سيُضاف إلى المحفظة.</summary>
    public decimal Amount { get; set; }

    /// <summary>رسوم بوابة الدفع شاملة الضريبة (صفر إذا لم تُضبط الرسوم).</summary>
    public decimal Fee { get; set; }

    /// <summary>الإجمالي المخصوم من البطاقة = <see cref="Amount"/> + <see cref="Fee"/>.</summary>
    public decimal Total { get; set; }
}

public class CreateWithdrawalRequest
{
    [Range(1, 100000)] public decimal Amount { get; set; }

    // بيانات البنك لم تعد تُرسل مع الطلب — تُقرأ من الحساب البنكي المحفوظ في
    // ملف المستخدم، فلا يمكن توجيه التحويل لحساب غير موثّق. الحقول أدناه تبقى
    // للتوافق مع النسخ القديمة من التطبيق وتُتجاهَل.
    [MaxLength(34)] public string? Iban { get; set; }
    [MaxLength(100)] public string? BankName { get; set; }
    [MaxLength(150)] public string? AccountHolderName { get; set; }
}

/// <summary>الحساب البنكي المحفوظ — يُقرأ ويُحدَّث من الملف الشخصي.</summary>
public class BankAccountDto
{
    public string? Iban { get; set; }
    public string? BankName { get; set; }
    public string? AccountHolderName { get; set; }

    /// <summary>عرض مُقنَّع للواجهة: SA03 •••• 1234.</summary>
    public string? IbanMasked { get; set; }

    /// <summary>false حين لم يُضَف الحساب بعد — التطبيق يعرض المطالبة.</summary>
    public bool IsSet { get; set; }
}

public class SaveBankAccountRequest
{
    [MaxLength(34)] public string Iban { get; set; } = string.Empty;
    [MaxLength(100)] public string BankName { get; set; } = string.Empty;
    [MaxLength(150)] public string AccountHolderName { get; set; } = string.Empty;
}

public class ProcessWithdrawalRequest
{
    public bool Approved { get; set; }
    public string? AdminNotes { get; set; }
}

// ── Responses ─────────────────────────────────────────────────────────────────

public class WalletTransactionDto
{
    public int Id { get; set; }
    public decimal Amount { get; set; }

    /// <summary>Enum name: deposit | refund | matchPayment | bookingPayment | coachPayment | reward | withdrawal | coachEarning | venueEarning | creatorEarning.</summary>
    public string Type { get; set; } = string.Empty;

    /// <summary>"completed" | "failed" — failed attempts moved no money.</summary>
    public string Status { get; set; } = string.Empty;

    /// <summary>معرّف الكيان المرتبط (حجز / مباراة / جلسة) حسب <see cref="Type"/>.</summary>
    public int? ReferenceId { get; set; }

    public string? Description { get; set; }

    /// <summary>معرّف العملية لدى بوابة الدفع (FINY) — null للتحويلات الداخلية.</summary>
    public string? PaymentReference { get; set; }

    public DateTime CreatedAt { get; set; }
}

public class WalletDto
{
    public decimal Balance { get; set; }
    public List<WalletTransactionDto> Transactions { get; set; } = [];

    /// <summary>Minimum balance required to request a withdrawal (from SystemSettings).</summary>
    public decimal WithdrawalThreshold { get; set; }

    /// <summary>Amount pending in an existing withdrawal request (0 if none pending).</summary>
    public decimal PendingWithdrawalAmount { get; set; }
}

public class WithdrawalRequestDto
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public string UserName { get; set; } = string.Empty;
    public string UserPhone { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string Status { get; set; } = string.Empty;
    public string Iban { get; set; } = string.Empty;
    public string BankName { get; set; } = string.Empty;
    public string AccountHolderName { get; set; } = string.Empty;
    public string? AdminNotes { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? ProcessedAt { get; set; }
}
