using SportaApis.Enums;

namespace SportaApis.Models;

/// <summary>
/// حجز الملعب - مع سياسة الإلغاء (2.8)
/// </summary>
public class Booking : BaseEntity
{
    public int CourtId { get; set; }
    public Court Court { get; set; } = null!;

    public int UserId { get; set; }
    public User User { get; set; } = null!;

    public DateTime StartTime { get; set; }
    public DateTime EndTime { get; set; }

    public decimal TotalPrice { get; set; }
    public BookingStatus Status { get; set; } = BookingStatus.Pending;

    // دفع كامل أو حصة فقط
    public bool PaidFullAmount { get; set; } = false;

    public DateTime? CancelledAt { get; set; }
    public string? CancellationReason { get; set; }
}
