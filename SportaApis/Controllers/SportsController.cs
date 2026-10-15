using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SportaApis.DTOs;
using SportaApis.Services;

namespace SportaApis.Controllers;

[ApiController]
[Route("api/sports")]
[Authorize]
public class SportsController : ControllerBase
{
    private readonly ISportService _sports;

    public SportsController(ISportService sports) => _sports = sports;

    // GET /api/sports
    // Anonymous so the registration flow can list sports before an account exists
    // (the coach picks his specialization sport while registering).
    [HttpGet]
    [AllowAnonymous]
    public async Task<IActionResult> GetAll()
    {
        var items = await _sports.GetActiveAsync();
        return Ok(ApiResponse<List<SportDto>>.Ok(items));
    }

    // GET /api/sports/{id}/settings — إعدادات اللعبة (عنوان + عناصر)
    [HttpGet("{id:int}/settings")]
    public async Task<IActionResult> GetSettings(int id)
    {
        var items = await _sports.GetSettingsAsync(id);
        return Ok(ApiResponse<List<SportSettingDto>>.Ok(items));
    }
}
