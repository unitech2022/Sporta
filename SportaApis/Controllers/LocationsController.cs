using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SportaApis.DTOs;
using SportaApis.Services;

namespace SportaApis.Controllers;

[ApiController]
[Route("api/locations")]
public class LocationsController : ControllerBase
{
    private readonly ILocationService _locations;

    public LocationsController(ILocationService locations) => _locations = locations;

    // GET /api/locations/countries  — عام (يُستخدم أثناء التسجيل قبل تسجيل الدخول)
    [HttpGet("countries")]
    [AllowAnonymous]
    public async Task<IActionResult> GetCountries()
    {
        var items = await _locations.GetCountriesAsync();
        return Ok(ApiResponse<List<CountryDto>>.Ok(items));
    }

    // GET /api/locations/cities?countryId=  — عام (يُستخدم أثناء التسجيل)
    [HttpGet("cities")]
    [AllowAnonymous]
    public async Task<IActionResult> GetCities([FromQuery] int? countryId)
    {
        var items = await _locations.GetCitiesAsync(countryId: countryId);
        return Ok(ApiResponse<List<CityDto>>.Ok(items));
    }

    // GET /api/locations/cities/{cityId}/districts  — أحياء مدينة
    [HttpGet("cities/{cityId:int}/districts")]
    [AllowAnonymous]
    public async Task<IActionResult> GetDistricts(int cityId)
    {
        var items = await _locations.GetDistrictsAsync(cityId);
        return Ok(ApiResponse<List<DistrictDto>>.Ok(items));
    }
}
