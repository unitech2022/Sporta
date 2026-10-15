namespace SportaApis.Models;

/// <summary>
/// تسعيرة اشتراك الملاعب كما يضبطها الأدمن — صف واحد في الجدول. السعر يتدرّج
/// بعدد ملاعب المالك: ملعب واحد، ملعبان، ثم مبلغ ثابت لكل ملعب إضافي.
/// </summary>
public class VenueSubscriptionPricing : BaseEntity
{
    // ── شهري ──
    public decimal MonthlyOneCourt { get; set; } = 39m;
    public decimal MonthlyTwoCourts { get; set; } = 59m;
    public decimal MonthlyExtraCourt { get; set; } = 20m;

    // ── سنوي ──
    public decimal YearlyOneCourt { get; set; } = 399m;
    public decimal YearlyTwoCourts { get; set; } = 599m;
    public decimal YearlyExtraCourt { get; set; } = 199m;

    /// <summary>هل الاشتراك مفعّل كمتطلب على الملاعب أصلاً؟</summary>
    public bool IsActive { get; set; } = true;

    /// <summary>سعر الاشتراك لعدد ملاعب معيّن قبل أي خصم.</summary>
    public decimal PriceFor(int courtCount, bool yearly)
    {
        var (one, two, extra) = yearly
            ? (YearlyOneCourt, YearlyTwoCourts, YearlyExtraCourt)
            : (MonthlyOneCourt, MonthlyTwoCourts, MonthlyExtraCourt);

        if (courtCount <= 1) return one;
        if (courtCount == 2) return two;
        return two + (courtCount - 2) * extra;
    }
}

/// <summary>
/// اشتراك مالك ملعب. الفترة والسعر لقطة وقت الشراء، فتغيّر التسعيرة أو عدد
/// الملاعب لاحقاً لا يمسّ اشتراكاً قائماً.
/// </summary>
public class VenueSubscription : BaseEntity
{
    /// <summary>مالك الملعب المشترِك.</summary>
    public int OwnerId { get; set; }
    public User Owner { get; set; } = null!;

    /// <summary>سنوي أم شهري.</summary>
    public bool IsYearly { get; set; }

    /// <summary>عدد الملاعب وقت الشراء (أساس التسعير).</summary>
    public int CourtCount { get; set; }

    /// <summary>السعر قبل الخصم.</summary>
    public decimal BasePrice { get; set; }

    /// <summary>نسبة الخصم المطبَّقة وقت الشراء (لقطة).</summary>
    public decimal DiscountPercent { get; set; }

    /// <summary>المبلغ المدفوع فعلاً من المحفظة.</summary>
    public decimal PaidAmount { get; set; }

    public DateTime StartsAt { get; set; }
    public DateTime EndsAt { get; set; }

    public bool IsCurrent(DateTime now) => StartsAt <= now && EndsAt > now;
}
