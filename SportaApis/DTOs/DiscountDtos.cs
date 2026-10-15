using System.ComponentModel.DataAnnotations;

namespace SportaApis.DTOs;

public class DiscountDto
{
    public int Id { get; set; }
    public string NameAr { get; set; } = string.Empty;
    public string? DescriptionAr { get; set; }

    /// <summary>"venueCommission" | "coachCommission" | "venueSubscription" | "playerSubscription" | "playerBooking"</summary>
    public string Target { get; set; } = string.Empty;

    public decimal Percent { get; set; }
    public bool IsGeneral { get; set; }
    public DateTime? StartsAt { get; set; }
    public DateTime? EndsAt { get; set; }
    public int? MaxBeneficiaries { get; set; }
    public bool GrantsLifetime { get; set; }
    public bool IsActive { get; set; }

    /// <summary>عدد المستفيدين الحاليين (للعروض المخصصة وعروض «أول N»).</summary>
    public int BeneficiariesCount { get; set; }

    /// <summary>المتبقي من سقف المستفيدين (null حين لا سقف).</summary>
    public int? RemainingSlots { get; set; }

    /// <summary>سقف عدد الحجوزات/الجلسات التي يسري عليها الخصم (null = بلا سقف).</summary>
    public int? MaxUses { get; set; }

    /// <summary>كم مرة طُبّق الخصم فعلاً حتى الآن.</summary>
    public int UsedCount { get; set; }

    /// <summary>المتبقي من سقف الحجوزات (null حين لا سقف).</summary>
    public int? RemainingUses { get; set; }

    /// <summary>هل الخصم فعّال الآن (مفعّل وضمن نافذته الزمنية)؟</summary>
    public bool IsRunning { get; set; }
}

public class DiscountBeneficiaryDto
{
    public int UserId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public bool AutoEnrolled { get; set; }
    public DateTime GrantedAt { get; set; }
}

public class SaveDiscountRequest
{
    [Required] public string NameAr { get; set; } = string.Empty;
    public string? DescriptionAr { get; set; }

    /// <summary>"venueCommission" | "coachCommission" | "venueSubscription" | "playerSubscription" | "playerBooking"</summary>
    [Required] public string Target { get; set; } = string.Empty;

    [Range(0.01, 100)] public decimal Percent { get; set; }

    public bool IsGeneral { get; set; } = true;
    public DateTime? StartsAt { get; set; }
    public DateTime? EndsAt { get; set; }

    [Range(1, 100000)] public int? MaxBeneficiaries { get; set; }

    /// <summary>سقف عدد الحجوزات/الجلسات التي يسري عليها الخصم (null = بلا سقف).</summary>
    [Range(1, 1000000)] public int? MaxUses { get; set; }

    public bool GrantsLifetime { get; set; }
    public bool IsActive { get; set; } = true;
}

public class AddBeneficiaryRequest
{
    [Required] public int UserId { get; set; }
}

/// <summary>مستخدم مرشّح لإضافته كمستفيد من خصم.</summary>
public class DiscountUserOptionDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;

    /// <summary>وصف عربي للدور ("مالك ملعب"، "مدرب"، "لاعب") لتمييز المتشابهين.</summary>
    public string RoleLabel { get; set; } = string.Empty;
}
