using SportaApis.DTOs;

namespace SportaApis.Services;

public interface ILocationService
{
    // ── Public ────────────────────────────────────────────────────────────────

    /// <summary>Active countries ordered for display.</summary>
    Task<List<CountryDto>> GetCountriesAsync(bool activeOnly = true);

    /// <summary>Active cities ordered for display (name + optional coordinates).</summary>
    /// <param name="countryId">Optional filter — only cities of that country.</param>
    Task<List<CityDto>> GetCitiesAsync(bool activeOnly = true, int? countryId = null);

    /// <summary>Active districts of a city, ordered for display.</summary>
    Task<List<DistrictDto>> GetDistrictsAsync(int cityId, bool activeOnly = true);

    // ── Admin CRUD ──────────────────────────────────────────────────────────────

    Task<CountryDto> CreateCountryAsync(SaveCountryRequest req);
    Task<CountryDto> UpdateCountryAsync(int id, SaveCountryRequest req);
    Task DeleteCountryAsync(int id);

    Task<CityDto> CreateCityAsync(SaveCityRequest req);
    Task<CityDto> UpdateCityAsync(int id, SaveCityRequest req);
    Task DeleteCityAsync(int id);

    Task<DistrictDto> CreateDistrictAsync(SaveDistrictRequest req);
    Task<DistrictDto> UpdateDistrictAsync(int id, SaveDistrictRequest req);
    Task DeleteDistrictAsync(int id);
}
