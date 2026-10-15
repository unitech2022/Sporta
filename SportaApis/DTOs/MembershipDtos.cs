using System.ComponentModel.DataAnnotations;

namespace SportaApis.DTOs;

public class MembershipPlanDto
{
    public int Id { get; set; }
    public int VenueId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? NameEn { get; set; }
    public string? Description { get; set; }
    public decimal MonthlyPrice { get; set; }
    public decimal DiscountPercent { get; set; }
    public int? MonthlyDiscountHours { get; set; }
    public int PriorityDays { get; set; }
    public bool IsActive { get; set; }
    public int ActiveMembers { get; set; }
}

public class SaveMembershipPlanRequest
{
    [Required, MaxLength(80)] public string Name { get; set; } = string.Empty;
    [MaxLength(80)] public string? NameEn { get; set; }
    [MaxLength(500)] public string? Description { get; set; }
    [Range(1, 100000)] public decimal MonthlyPrice { get; set; }
    [Range(0, 100)] public decimal DiscountPercent { get; set; }
    [Range(1, 744)] public int? MonthlyDiscountHours { get; set; }
    [Range(0, 60)] public int PriorityDays { get; set; }
    public bool IsActive { get; set; } = true;
}

public class MembershipDto
{
    public int Id { get; set; }
    public int PlanId { get; set; }
    public int VenueId { get; set; }
    public string VenueName { get; set; } = string.Empty;
    public string? VenueNameEn { get; set; }
    public string? VenueImageUrl { get; set; }
    public string PlanName { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public decimal DiscountPercent { get; set; }
    public int? MonthlyDiscountHours { get; set; }
    public int PriorityDays { get; set; }
    public DateTime PeriodStart { get; set; }
    public DateTime PeriodEnd { get; set; }
    public bool AutoRenew { get; set; }
    public bool IsActive { get; set; }

    /// <summary>دقائق الخصم المستخدمة في الفترة الحالية (من السقف).</summary>
    public int UsedDiscountMinutes { get; set; }
}

/// <summary>عضوية النادي كما يراها اللاعب: الخطط المتاحة وعضويته ونافذة الحجز.</summary>
public class VenueMembershipDto
{
    public int VenueId { get; set; }
    public string VenueName { get; set; } = string.Empty;
    public string? VenueNameEn { get; set; }

    /// <summary>نافذة الحجز لغير الأعضاء (null = بلا حد).</summary>
    public int? BookingWindowDays { get; set; }

    /// <summary>نافذة الحجز لهذا المستخدم (بأولوية عضويته إن وُجدت).</summary>
    public int? MyBookingWindowDays { get; set; }

    public List<MembershipPlanDto> Plans { get; set; } = [];
    public MembershipDto? MyMembership { get; set; }

    /// <summary>المستخدم مالك النادي — لا يشترك في ناديه.</summary>
    public bool IsOwnVenue { get; set; }
}

public class VenueMembersDto
{
    public int VenueId { get; set; }
    public int? BookingWindowDays { get; set; }
    public decimal SportaFeePercent { get; set; }
    public List<MembershipPlanDto> Plans { get; set; } = [];
    public List<VenueMemberDto> Members { get; set; } = [];
    public decimal MonthlyRevenue { get; set; }
}

public class VenueMemberDto
{
    public int MembershipId { get; set; }
    public int UserId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? AvatarUrl { get; set; }
    public int? Level { get; set; }
    public string PlanName { get; set; } = string.Empty;
    public DateTime PeriodEnd { get; set; }
    public bool AutoRenew { get; set; }
    public int UsedDiscountMinutes { get; set; }
    public int? MonthlyDiscountHours { get; set; }
}

public class SetBookingWindowRequest
{
    /// <summary>null = بلا حد.</summary>
    [Range(1, 365)] public int? Days { get; set; }
}

/// <summary>حصة لاعب في حدث بعد خصم عضويته: السعر الأصلي وما سيُخصم فعلاً.</summary>
public class MemberShareDto
{
    public decimal Price { get; set; }
    public decimal Amount { get; set; }
    public decimal Discount { get; set; }
    public string? MembershipPlanName { get; set; }
}

public class SubscribeMembershipRequest
{
    public int PlanId { get; set; }

    /// <summary>تجديد شهري تلقائي من المحفظة — اختيار اللاعب، مطفأ افتراضياً.</summary>
    public bool AutoRenew { get; set; }
}
