using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SportaApis.DTOs;
using SportaApis.Services;

namespace SportaApis.Controllers;

[ApiController]
[Route("api/assessment")]
[Authorize]
public class AssessmentController : ControllerBase
{
    private readonly IAssessmentService _assessment;

    public AssessmentController(IAssessmentService assessment) =>
        _assessment = assessment;

    // GET /api/assessment/questions?sport=padel
    [HttpGet("questions")]
    public async Task<IActionResult> GetQuestions([FromQuery] string sport = "padel")
    {
        var items = await _assessment.GetQuestionsAsync(sport);
        return Ok(ApiResponse<List<AssessmentQuestionDto>>.Ok(items));
    }

    // GET /api/assessment/levels?sport=padel
    [HttpGet("levels")]
    public async Task<IActionResult> GetLevels([FromQuery] string sport = "padel")
    {
        var items = await _assessment.GetLevelsAsync(sport);
        return Ok(ApiResponse<List<AssessmentLevelDto>>.Ok(items));
    }
}
