using Microsoft.EntityFrameworkCore;
using SportaApis.Data;
using SportaApis.DTOs;
using SportaApis.Models;

namespace SportaApis.Services;

public class LocationService : ILocationService
{
    private readonly AppDbContext _db;

    public LocationService(AppDbContext db) => _db = db;

    // ── Public ────────────────────────────────────────────────────────────────

    public async Task<List<CountryDto>> GetCountriesAsync(bool activeOnly = true)
    {
        var query = _db.Countries.AsQueryable();
        if (activeOnly) query = query.Where(c => c.IsActive);

        return await query
            .OrderBy(c => c.SortOrder).ThenBy(c => c.NameAr)
            .Select(c => new CountryDto
            {
                Id = c.Id,
                NameAr = c.NameAr,
                NameEn = c.NameEn,
                Code = c.Code,
                PhoneCode = c.PhoneCode,
                CurrencyCode = c.CurrencyCode,
                IsActive = c.IsActive,
                SortOrder = c.SortOrder,
                CitiesCount = c.Cities.Count(x => !activeOnly || x.IsActive),
            })
            .ToListAsync();
    }

    public async Task<List<CityDto>> GetCitiesAsync(bool activeOnly = true, int? countryId = null)
    {
        var query = _db.Cities.AsQueryable();
        if (activeOnly) query = query.Where(c => c.IsActive);
        if (countryId is int cid) query = query.Where(c => c.CountryId == cid);

        var items = await query
            .OrderBy(c => c.SortOrder).ThenBy(c => c.NameAr)
            .Select(c => new CityDto
            {
                Id = c.Id,
                CountryId = c.CountryId,
                CountryNameAr = c.Country.NameAr,
                NameAr = c.NameAr,
                NameEn = c.NameEn,
                Region = c.Region,
                Latitude = c.Latitude,
                Longitude = c.Longitude,
                IsActive = c.IsActive,
                SortOrder = c.SortOrder,
                DistrictsCount = c.Districts.Count(d => !activeOnly || d.IsActive),
            })
            .ToListAsync();
        return items;
    }

    public async Task<List<DistrictDto>> GetDistrictsAsync(int cityId, bool activeOnly = true)
    {
        var query = _db.Districts.Where(d => d.CityId == cityId);
        if (activeOnly) query = query.Where(d => d.IsActive);

        return await query
            .OrderBy(d => d.SortOrder).ThenBy(d => d.NameAr)
            .Select(d => new DistrictDto
            {
                Id = d.Id,
                CityId = d.CityId,
                NameAr = d.NameAr,
                NameEn = d.NameEn,
                IsActive = d.IsActive,
                SortOrder = d.SortOrder,
            })
            .ToListAsync();
    }

    // ── Admin CRUD ──────────────────────────────────────────────────────────────

    public async Task<CountryDto> CreateCountryAsync(SaveCountryRequest req)
    {
        var code = req.Code.Trim().ToUpperInvariant();
        if (await _db.Countries.AnyAsync(c => c.Code == code))
            throw new AuthException(
                "Country code already exists", "رمز الدولة مستخدم مسبقاً", "COUNTRY_CODE_TAKEN");

        var country = new Country();
        ApplyCountry(country, req);
        _db.Countries.Add(country);
        await _db.SaveChangesAsync();
        return ToCountryDto(country, 0);
    }

    public async Task<CountryDto> UpdateCountryAsync(int id, SaveCountryRequest req)
    {
        var country = await _db.Countries.FirstOrDefaultAsync(c => c.Id == id)
            ?? throw new AuthException("Country not found", "الدولة غير موجودة", "COUNTRY_NOT_FOUND");

        var code = req.Code.Trim().ToUpperInvariant();
        if (await _db.Countries.AnyAsync(c => c.Code == code && c.Id != id))
            throw new AuthException(
                "Country code already exists", "رمز الدولة مستخدم مسبقاً", "COUNTRY_CODE_TAKEN");

        ApplyCountry(country, req);
        country.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();
        var count = await _db.Cities.CountAsync(c => c.CountryId == id);
        return ToCountryDto(country, count);
    }

    public async Task DeleteCountryAsync(int id)
    {
        var country = await _db.Countries.FirstOrDefaultAsync(c => c.Id == id)
            ?? throw new AuthException("Country not found", "الدولة غير موجودة", "COUNTRY_NOT_FOUND");

        if (await _db.Cities.AnyAsync(c => c.CountryId == id))
            throw new AuthException(
                "Country still has cities", "لا يمكن حذف دولة تحتوي على مدن", "COUNTRY_HAS_CITIES");

        if (await _db.StaffProfiles.AnyAsync(s => s.CountryId == id))
            throw new AuthException(
                "Country assigned to staff", "لا يمكن حذف دولة مُسنَدة لموظفين", "COUNTRY_HAS_STAFF");

        _db.Countries.Remove(country);
        await _db.SaveChangesAsync();
    }

    public async Task<CityDto> CreateCityAsync(SaveCityRequest req)
    {
        if (!await _db.Countries.AnyAsync(c => c.Id == req.CountryId))
            throw new AuthException("Country not found", "الدولة غير موجودة", "COUNTRY_NOT_FOUND");

        var city = new City();
        ApplyCity(city, req);
        _db.Cities.Add(city);
        await _db.SaveChangesAsync();
        return ToCityDto(city, 0);
    }

    public async Task<CityDto> UpdateCityAsync(int id, SaveCityRequest req)
    {
        var city = await _db.Cities.FirstOrDefaultAsync(c => c.Id == id)
            ?? throw new AuthException("City not found", "المدينة غير موجودة", "CITY_NOT_FOUND");
        if (!await _db.Countries.AnyAsync(c => c.Id == req.CountryId))
            throw new AuthException("Country not found", "الدولة غير موجودة", "COUNTRY_NOT_FOUND");
        ApplyCity(city, req);
        city.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();
        var count = await _db.Districts.CountAsync(d => d.CityId == id);
        return ToCityDto(city, count);
    }

    public async Task DeleteCityAsync(int id)
    {
        var city = await _db.Cities.FirstOrDefaultAsync(c => c.Id == id)
            ?? throw new AuthException("City not found", "المدينة غير موجودة", "CITY_NOT_FOUND");

        if (await _db.StaffProfiles.AnyAsync(s => s.CityId == id))
            throw new AuthException(
                "City assigned to staff", "لا يمكن حذف مدينة مُسنَدة لموظفين", "CITY_HAS_STAFF");

        // Detach any users that referenced this city (FK is SetNull, but districts
        // cascade — clear those references first to avoid orphaned user.DistrictId).
        var districtIds = await _db.Districts.Where(d => d.CityId == id)
            .Select(d => d.Id).ToListAsync();
        var affected = await _db.Users
            .Where(u => u.CityId == id || (u.DistrictId != null && districtIds.Contains(u.DistrictId.Value)))
            .ToListAsync();
        foreach (var u in affected) { u.CityId = null; u.DistrictId = null; }

        _db.Cities.Remove(city); // districts cascade-delete
        await _db.SaveChangesAsync();
    }

    public async Task<DistrictDto> CreateDistrictAsync(SaveDistrictRequest req)
    {
        var cityExists = await _db.Cities.AnyAsync(c => c.Id == req.CityId);
        if (!cityExists)
            throw new AuthException("City not found", "المدينة غير موجودة", "CITY_NOT_FOUND");

        var district = new District { CityId = req.CityId };
        ApplyDistrict(district, req);
        _db.Districts.Add(district);
        await _db.SaveChangesAsync();
        return ToDistrictDto(district);
    }

    public async Task<DistrictDto> UpdateDistrictAsync(int id, SaveDistrictRequest req)
    {
        var district = await _db.Districts.FirstOrDefaultAsync(d => d.Id == id)
            ?? throw new AuthException("District not found", "الحي غير موجود", "DISTRICT_NOT_FOUND");
        ApplyDistrict(district, req);
        district.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();
        return ToDistrictDto(district);
    }

    public async Task DeleteDistrictAsync(int id)
    {
        var district = await _db.Districts.FirstOrDefaultAsync(d => d.Id == id)
            ?? throw new AuthException("District not found", "الحي غير موجود", "DISTRICT_NOT_FOUND");

        var affected = await _db.Users.Where(u => u.DistrictId == id).ToListAsync();
        foreach (var u in affected) u.DistrictId = null;

        _db.Districts.Remove(district);
        await _db.SaveChangesAsync();
    }

    // ── helpers ──────────────────────────────────────────────────────────────

    private static void ApplyCountry(Country country, SaveCountryRequest req)
    {
        country.NameAr = req.NameAr.Trim();
        country.NameEn = req.NameEn.Trim();
        country.Code = req.Code.Trim().ToUpperInvariant();
        country.PhoneCode = string.IsNullOrWhiteSpace(req.PhoneCode) ? null : req.PhoneCode.Trim();
        country.CurrencyCode = string.IsNullOrWhiteSpace(req.CurrencyCode)
            ? null : req.CurrencyCode.Trim().ToUpperInvariant();
        country.IsActive = req.IsActive;
        country.SortOrder = req.SortOrder;
    }

    private static void ApplyCity(City city, SaveCityRequest req)
    {
        city.CountryId = req.CountryId;
        city.NameAr = req.NameAr.Trim();
        city.NameEn = req.NameEn.Trim();
        city.Region = string.IsNullOrWhiteSpace(req.Region) ? null : req.Region.Trim();
        city.Latitude = req.Latitude;
        city.Longitude = req.Longitude;
        city.IsActive = req.IsActive;
        city.SortOrder = req.SortOrder;
    }

    private static void ApplyDistrict(District district, SaveDistrictRequest req)
    {
        district.CityId = req.CityId;
        district.NameAr = req.NameAr.Trim();
        district.NameEn = req.NameEn.Trim();
        district.IsActive = req.IsActive;
        district.SortOrder = req.SortOrder;
    }

    private static CountryDto ToCountryDto(Country c, int citiesCount) => new()
    {
        Id = c.Id,
        NameAr = c.NameAr,
        NameEn = c.NameEn,
        Code = c.Code,
        PhoneCode = c.PhoneCode,
        CurrencyCode = c.CurrencyCode,
        IsActive = c.IsActive,
        SortOrder = c.SortOrder,
        CitiesCount = citiesCount,
    };

    private static CityDto ToCityDto(City c, int districtsCount) => new()
    {
        Id = c.Id,
        CountryId = c.CountryId,
        NameAr = c.NameAr,
        NameEn = c.NameEn,
        Region = c.Region,
        Latitude = c.Latitude,
        Longitude = c.Longitude,
        IsActive = c.IsActive,
        SortOrder = c.SortOrder,
        DistrictsCount = districtsCount,
    };

    private static DistrictDto ToDistrictDto(District d) => new()
    {
        Id = d.Id,
        CityId = d.CityId,
        NameAr = d.NameAr,
        NameEn = d.NameEn,
        IsActive = d.IsActive,
        SortOrder = d.SortOrder,
    };
}
