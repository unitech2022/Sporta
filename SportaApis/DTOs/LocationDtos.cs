using System.ComponentModel.DataAnnotations;

namespace SportaApis.DTOs;

// ── Responses ─────────────────────────────────────────────────────────────────

public class CountryDto
{
    public int Id { get; set; }
    public string NameAr { get; set; } = string.Empty;
    public string NameEn { get; set; } = string.Empty;
    public string Code { get; set; } = string.Empty;
    public string? PhoneCode { get; set; }
    public string? CurrencyCode { get; set; }
    public bool IsActive { get; set; }
    public int SortOrder { get; set; }

    /// <summary>Number of cities under this country (for the admin list).</summary>
    public int CitiesCount { get; set; }
}

public class CityDto
{
    public int Id { get; set; }
    public int CountryId { get; set; }
    public string? CountryNameAr { get; set; }
    public string NameAr { get; set; } = string.Empty;
    public string NameEn { get; set; } = string.Empty;
    public string? Region { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
    public bool IsActive { get; set; }
    public int SortOrder { get; set; }

    /// <summary>Number of districts under this city (for the admin list).</summary>
    public int DistrictsCount { get; set; }
}

public class DistrictDto
{
    public int Id { get; set; }
    public int CityId { get; set; }
    public string NameAr { get; set; } = string.Empty;
    public string NameEn { get; set; } = string.Empty;
    public bool IsActive { get; set; }
    public int SortOrder { get; set; }
}

// ── Admin requests ────────────────────────────────────────────────────────────

public class SaveCountryRequest
{
    [Required] public string NameAr { get; set; } = string.Empty;
    [Required] public string NameEn { get; set; } = string.Empty;
    [Required][StringLength(2, MinimumLength = 2)] public string Code { get; set; } = string.Empty;
    public string? PhoneCode { get; set; }
    public string? CurrencyCode { get; set; }
    public bool IsActive { get; set; } = true;
    public int SortOrder { get; set; } = 0;
}

public class SaveCityRequest
{
    [Required] public int CountryId { get; set; }
    [Required] public string NameAr { get; set; } = string.Empty;
    [Required] public string NameEn { get; set; } = string.Empty;
    public string? Region { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
    public bool IsActive { get; set; } = true;
    public int SortOrder { get; set; } = 0;
}

public class SaveDistrictRequest
{
    [Required] public int CityId { get; set; }
    [Required] public string NameAr { get; set; } = string.Empty;
    [Required] public string NameEn { get; set; } = string.Empty;
    public bool IsActive { get; set; } = true;
    public int SortOrder { get; set; } = 0;
}
