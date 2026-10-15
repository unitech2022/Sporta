using System.ComponentModel.DataAnnotations;

namespace SportaApis.DTOs;

// ── Responses ─────────────────────────────────────────────────────────────────

public class StaffDto
{
    /// <summary>معرّف المستخدم (وليس معرّف ملف الموظف).</summary>
    public int UserId { get; set; }
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? JobTitle { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }

    // ── النطاق الجغرافي ──
    public int CountryId { get; set; }
    public string CountryNameAr { get; set; } = string.Empty;

    /// <summary>null تعني «كل مدن الدولة».</summary>
    public int? CityId { get; set; }
    public string? CityNameAr { get; set; }

    /// <summary>مختصر للواجهة: هل النطاق كل المدن؟</summary>
    public bool AllCities => CityId is null;

    /// <summary>مفاتيح الصلاحيات الممنوحة.</summary>
    public List<string> Permissions { get; set; } = [];
}

/// <summary>الصلاحيات ونطاق المستخدم الحالي — تستخدمها اللوحة لإظهار/إخفاء الأقسام.</summary>
public class MyAccessDto
{
    /// <summary>"admin" أو "staff".</summary>
    public string Role { get; set; } = string.Empty;
    public List<string> Permissions { get; set; } = [];

    public int? CountryId { get; set; }
    public string? CountryNameAr { get; set; }
    public int? CityId { get; set; }
    public string? CityNameAr { get; set; }

    /// <summary>true للأدمن أو لموظف نطاقه كل مدن دولته.</summary>
    public bool AllCities { get; set; }
}

public class PermissionGroupDto
{
    public string Key { get; set; } = string.Empty;
    public string Label { get; set; } = string.Empty;
    public List<PermissionItemDto> Permissions { get; set; } = [];
}

public class PermissionItemDto
{
    public string Key { get; set; } = string.Empty;
    public string Label { get; set; } = string.Empty;
}

// ── Requests ──────────────────────────────────────────────────────────────────

public class CreateStaffRequest
{
    /// <summary>
    /// معرّف مستخدم قائم لترقيته موظفاً بدل إنشاء حساب جديد: يحتفظ برقمه
    /// وبياناته وأدواره في التطبيق، ويُضاف له دور الموظف وصلاحياته.
    /// </summary>
    public int? UserId { get; set; }

    [Required] public string FirstName { get; set; } = string.Empty;
    [Required] public string LastName { get; set; } = string.Empty;
    [Required] public string Phone { get; set; } = string.Empty;
    [Required][EmailAddress] public string Email { get; set; } = string.Empty;
    [Required][MinLength(6)] public string Password { get; set; } = string.Empty;
    public string? JobTitle { get; set; }

    [Required] public int CountryId { get; set; }

    /// <summary>اتركها null لمنح الموظف كل مدن الدولة.</summary>
    public int? CityId { get; set; }

    public List<string> Permissions { get; set; } = [];
}

public class UpdateStaffRequest
{
    [Required] public string FirstName { get; set; } = string.Empty;
    [Required] public string LastName { get; set; } = string.Empty;
    [Required][EmailAddress] public string Email { get; set; } = string.Empty;
    public string? JobTitle { get; set; }

    /// <summary>اتركها فارغة لإبقاء كلمة المرور الحالية.</summary>
    public string? Password { get; set; }

    [Required] public int CountryId { get; set; }
    public int? CityId { get; set; }

    public List<string> Permissions { get; set; } = [];
    public bool IsActive { get; set; } = true;
}
