using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SportaApis.Attributes;
using SportaApis.DTOs;
using SportaApis.Helpers;
using SportaApis.Services;

namespace SportaApis.Controllers;

/// <summary>Admin CRUD for assessment levels and questions (per sport).</summary>
[ApiController]
[Route("api/admin/assessment")]
[Authorize(Roles = "admin,staff")]
public class AdminAssessmentController : ControllerBase
{
    private readonly IAssessmentService _assessment;

    public AdminAssessmentController(IAssessmentService assessment) =>
        _assessment = assessment;

    // ── Levels ────────────────────────────────────────────────────────────────

    // GET /api/admin/assessment/levels?sport=padel
    [HttpGet("levels")]
    [RequirePermission(Permissions.AssessmentView)]
    public async Task<IActionResult> GetLevels([FromQuery] string? sport)
    {
        var items = await _assessment.AdminGetLevelsAsync(sport);
        return Ok(ApiResponse<List<AssessmentLevelDto>>.Ok(items));
    }

    // POST /api/admin/assessment/levels
    [HttpPost("levels")]
    [RequirePermission(Permissions.AssessmentManage)]
    public async Task<IActionResult> CreateLevel([FromBody] SaveAssessmentLevelRequest req)
    {
        var dto = await _assessment.CreateLevelAsync(req);
        return Ok(ApiResponse<AssessmentLevelDto>.Ok(dto));
    }

    // PUT /api/admin/assessment/levels/{id}
    [HttpPut("levels/{id:int}")]
    [RequirePermission(Permissions.AssessmentManage)]
    public async Task<IActionResult> UpdateLevel(int id, [FromBody] SaveAssessmentLevelRequest req)
    {
        try
        {
            var dto = await _assessment.UpdateLevelAsync(id, req);
            return Ok(ApiResponse<AssessmentLevelDto>.Ok(dto));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    // DELETE /api/admin/assessment/levels/{id}
    [HttpDelete("levels/{id:int}")]
    [RequirePermission(Permissions.AssessmentManage)]
    public async Task<IActionResult> DeleteLevel(int id)
    {
        try
        {
            await _assessment.DeleteLevelAsync(id);
            return Ok(ApiResponse<object>.Ok(new { deleted = true }));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    // ── Questions ───────────────────────────────────────────────────────────────

    // GET /api/admin/assessment/questions?sport=padel
    [HttpGet("questions")]
    [RequirePermission(Permissions.AssessmentView)]
    public async Task<IActionResult> GetQuestions([FromQuery] string? sport)
    {
        var items = await _assessment.AdminGetQuestionsAsync(sport);
        return Ok(ApiResponse<List<AssessmentQuestionDto>>.Ok(items));
    }

    // POST /api/admin/assessment/questions
    [HttpPost("questions")]
    [RequirePermission(Permissions.AssessmentManage)]
    public async Task<IActionResult> CreateQuestion([FromBody] SaveAssessmentQuestionRequest req)
    {
        var dto = await _assessment.CreateQuestionAsync(req);
        return Ok(ApiResponse<AssessmentQuestionDto>.Ok(dto));
    }

    // PUT /api/admin/assessment/questions/{id}
    [HttpPut("questions/{id:int}")]
    [RequirePermission(Permissions.AssessmentManage)]
    public async Task<IActionResult> UpdateQuestion(
        int id, [FromBody] SaveAssessmentQuestionRequest req)
    {
        try
        {
            var dto = await _assessment.UpdateQuestionAsync(id, req);
            return Ok(ApiResponse<AssessmentQuestionDto>.Ok(dto));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    // DELETE /api/admin/assessment/questions/{id}
    [HttpDelete("questions/{id:int}")]
    [RequirePermission(Permissions.AssessmentManage)]
    public async Task<IActionResult> DeleteQuestion(int id)
    {
        try
        {
            await _assessment.DeleteQuestionAsync(id);
            return Ok(ApiResponse<object>.Ok(new { deleted = true }));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }
}
