using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SportaApis.DTOs;
using SportaApis.Services;

namespace SportaApis.Controllers;

[ApiController]
[Route("api/coach-specializations")]
[Authorize]
public class CoachSpecializationsController : ControllerBase
{
    private readonly ICoachSpecializationService _specializations;

    public CoachSpecializationsController(ICoachSpecializationService specializations) =>
        _specializations = specializations;

    // GET /api/coach-specializations
    // Anonymous so the registration flow can list specializations before an
    // account exists (the coach picks his specializations while registering).
    [HttpGet]
    [AllowAnonymous]
    public async Task<IActionResult> GetAll()
    {
        var items = await _specializations.GetActiveAsync();
        return Ok(ApiResponse<List<CoachSpecializationDto>>.Ok(items));
    }
}
