using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SportaApis.DTOs;
using SportaApis.Services;

namespace SportaApis.Controllers;

[ApiController]
[Route("api/ads")]
[Authorize]
public class AdsController : ControllerBase
{
    private readonly IAdService _ads;

    public AdsController(IAdService ads) => _ads = ads;

    // GET /api/ads?page=home
    // page: أين يُعرض الإعلان ("home" | "courts" | "matches" | "coaches").
    // بدونه تُرجَع كل الإعلانات النشطة (توافقًا مع النسخ القديمة من التطبيق).
    [AllowAnonymous]
    [HttpGet]
    public async Task<IActionResult> GetAll([FromQuery] string? page = null)
    {
        var items = await _ads.GetActiveAsync(page);
        return Ok(ApiResponse<List<AdDto>>.Ok(items));
    }
}
