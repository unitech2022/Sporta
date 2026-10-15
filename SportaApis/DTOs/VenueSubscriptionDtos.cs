using System.ComponentModel.DataAnnotations;

namespace SportaApis.DTOs;

public class VenueSubscriptionPricingDto
{
    public decimal MonthlyOneCourt { get; set; }
    public decimal MonthlyTwoCourts { get; set; }
    public decimal MonthlyExtraCourt { get; set; }
    public decimal YearlyOneCourt { get; set; }
    public decimal YearlyTwoCourts { get; set; }
    public decimal YearlyExtraCourt { get; set; }
    public bool IsActive { get; set; }
}

public class SaveVenueSubscriptionPricingRequest
{
    [Range(0, 100000)] public decimal MonthlyOneCourt { get; set; }
    [Range(0, 100000)] public decimal MonthlyTwoCourts { get; set; }
    [Range(0, 100000)] public decimal MonthlyExtraCourt { get; set; }
    [Range(0, 100000)] public decimal YearlyOneCourt { get; set; }
    [Range(0, 100000)] public decimal YearlyTwoCourts { get; set; }
    [Range(0, 100000)] public decimal YearlyExtraCourt { get; set; }
    public bool IsActive { get; set; } = true;
}

/// <summary>عرض سعر اشتراك للمالك الحالي قبل الشراء.</summary>
public class VenueSubscriptionQuoteDto
{
    public int CourtCount { get; set; }
    public bool IsYearly { get; set; }
    public decimal BasePrice { get; set; }
    public decimal DiscountPercent { get; set; }
    public decimal DiscountAmount { get; set; }
    public decimal Total { get; set; }
}

public class VenueSubscriptionDto
{
    public int Id { get; set; }
    public int OwnerId { get; set; }
    public string OwnerName { get; set; } = string.Empty;
    public bool IsYearly { get; set; }
    public int CourtCount { get; set; }
    public decimal BasePrice { get; set; }
    public decimal DiscountPercent { get; set; }
    public decimal PaidAmount { get; set; }
    public DateTime StartsAt { get; set; }
    public DateTime EndsAt { get; set; }
    public bool IsCurrent { get; set; }
}

public class SubscribeVenueRequest
{
    /// <summary>true = اشتراك سنوي، false = شهري.</summary>
    public bool IsYearly { get; set; }
}
