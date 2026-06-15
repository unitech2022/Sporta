using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SportaApis.DTOs;
using SportaApis.Services;

namespace SportaApis.Controllers;

[ApiController]
[Route("api/courts")]
[Authorize]
public class CourtsController : ControllerBase
{
    private readonly ICourtService _courtService;

    public CourtsController(ICourtService courtService) =>
        _courtService = courtService;

    // GET /api/courts?city=&type=&gender=
    [HttpGet]
    public async Task<IActionResult> GetCourts(
        [FromQuery] string? city,
        [FromQuery] string? type,
        [FromQuery] string? gender)
    {
        try
        {
            var courts = await _courtService.GetCourtsAsync(city, type, gender);
            return Ok(ApiResponse<List<CourtDto>>.Ok(courts));
        }
        catch (Exception)
        {
            return StatusCode(500, ApiResponse<object>.Fail(
                "An unexpected error occurred", "حدث خطأ غير متوقع", "UNEXPECTED"));
        }
    }

    // GET /api/courts/{id}
    [HttpGet("{id:int}")]
    public async Task<IActionResult> GetCourt(int id)
    {
        try
        {
            var court = await _courtService.GetCourtByIdAsync(id);
            return Ok(ApiResponse<CourtDto>.Ok(court));
        }
        catch (AuthException ex)
        {
            return NotFound(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
        catch (Exception)
        {
            return StatusCode(500, ApiResponse<object>.Fail(
                "An unexpected error occurred", "حدث خطأ غير متوقع", "UNEXPECTED"));
        }
    }

    // GET /api/courts/{id}/availability?date=yyyy-MM-dd
    [HttpGet("{id:int}/availability")]
    public async Task<IActionResult> GetAvailability(int id, [FromQuery] DateTime? date)
    {
        try
        {
            var day = date ?? DateTime.UtcNow.Date;
            var availability = await _courtService.GetAvailabilityAsync(id, day);
            return Ok(ApiResponse<CourtAvailabilityDto>.Ok(availability));
        }
        catch (AuthException ex)
        {
            return NotFound(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
        catch (Exception)
        {
            return StatusCode(500, ApiResponse<object>.Fail(
                "An unexpected error occurred", "حدث خطأ غير متوقع", "UNEXPECTED"));
        }
    }
}
