using SportaApis.Enums;

namespace SportaApis.Models;

/// <summary>
/// اشتراك Sporta Plus - مزايا حصرية (الفصل السادس)
/// </summary>
public class Subscription : BaseEntity
{
    public int UserId { get; set; }
    public User User { get; set; } = null!;

    public SubscriptionPlan Plan { get; set; } = SubscriptionPlan.Free;
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public bool IsActive => Plan == SubscriptionPlan.Free || (EndDate.HasValue && EndDate > DateTime.UtcNow);

    // تجربة مجانية 14 يوم
    public bool TrialUsed { get; set; } = false;
    public DateTime? TrialEndDate { get; set; }
}
