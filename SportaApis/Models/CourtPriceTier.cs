using SportaApis.Enums;

namespace SportaApis.Models;

/// <summary>
/// شريحة سعر يحددها صاحب الملعب من لوحته: مدة → سعر،
/// إمّا لحجز الملعب أو لحصة المباراة (مثال: 60 دقيقة = 150 ر.س).
/// </summary>
public class CourtPriceTier : BaseEntity
{
    public int CourtId { get; set; }
    public Court Court { get; set; } = null!;

    public CourtPriceKind Kind { get; set; }
    public int DurationMinutes { get; set; }
    public decimal Price { get; set; }
}
