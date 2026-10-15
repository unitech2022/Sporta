namespace SportaApis.Enums;

public enum CourtPriceKind
{
    Booking = 0, // سعر حجز الملعب حسب المدة (تُستخدم أيضاً لتسعير المباريات)

    /// <summary>Unused — matches now price off the Booking tier for their duration.</summary>
    Match = 1,
}
