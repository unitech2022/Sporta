using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SportaApis.DTOs;
using SportaApis.Services;

namespace SportaApis.Controllers;

/// <summary>سُلَّم المستويات كما يعرضه التطبيق — عام بلا تسجيل دخول.</summary>
[ApiController]
[Route("api/levels")]
public class LevelsController : ControllerBase
{
    private readonly ILevelDefinitionService _levels;

    public LevelsController(ILevelDefinitionService levels) => _levels = levels;

    // GET /api/levels
    [AllowAnonymous]
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var items = await _levels.GetActiveAsync();
        return Ok(ApiResponse<List<PlayerLevelDefinitionDto>>.Ok(items));
    }
}
