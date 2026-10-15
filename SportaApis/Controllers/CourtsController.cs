using System.Security.Claims;
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

    /// <summary>
    /// معرّف المستخدم من التوكن، و<c>0</c> للزائر غير المسجّل — نقاط التصفح
    /// العامة مفتوحة له (App Store 5.1.1)، ولا يملك مفضلة ولا موقعاً محفوظاً.
    /// </summary>
    private int CurrentUserId =>
        int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var id) ? id : 0;

    // GET /api/courts?city=&type=&gender=&page=&pageSize=
    //     &date=yyyy-MM-dd&fromHour=18&toHour=24&duration=60&onlyAvailable=false
    // date (اختياري) يفعّل البحث بالوقت: كل ملعب يحمل مواعيده الفارغة التي
    // تبدأ في [fromHour, toHour) بالمدة المطلوبة، ومن له مواعيد يأتي أولاً.
    [AllowAnonymous]
    [HttpGet]
    public async Task<IActionResult> GetCourts(
        [FromQuery] string? city,
        [FromQuery] string? type,
        [FromQuery] string? gender,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] DateTime? date = null,
        [FromQuery] int fromHour = 0,
        [FromQuery] int toHour = 24,
        [FromQuery] int duration = 60,
        [FromQuery] bool onlyAvailable = false)
    {
        try
        {
            CourtSlotWindow? window = null;
            if (date is DateTime day)
            {
                var from = Math.Clamp(fromHour, 0, 23);
                var to = Math.Clamp(toHour, from + 1, 24);
                window = new CourtSlotWindow(
                    day.Date, from, to, duration < 30 ? 60 : duration, onlyAvailable);
            }

            var courts = await _courtService.GetCourtsAsync(
                CurrentUserId, city, type, gender, page, pageSize, window);
            return Ok(ApiResponse<PagedResult<CourtDto>>.Ok(courts));
        }
        catch (Exception)
        {
            return StatusCode(500, ApiResponse<object>.Fail(
                "An unexpected error occurred", "حدث خطأ غير متوقع", "UNEXPECTED"));
        }
    }

    // GET /api/courts/favorites?page=&pageSize=
    // يسبق مسار {id:int} في الترتيب لكنه لا يزاحمه — القيد :int يمنع التقاط "favorites".
    [HttpGet("favorites")]
    public async Task<IActionResult> GetFavorites(
        [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        try
        {
            var courts = await _courtService.GetFavoritesAsync(
                CurrentUserId, page, pageSize);
            return Ok(ApiResponse<PagedResult<CourtDto>>.Ok(courts));
        }
        catch (Exception)
        {
            return StatusCode(500, ApiResponse<object>.Fail(
                "An unexpected error occurred", "حدث خطأ غير متوقع", "UNEXPECTED"));
        }
    }

    // PUT /api/courts/{id}/favorite  { "favorite": true }
    [HttpPut("{id:int}/favorite")]
    public async Task<IActionResult> ToggleFavorite(
        int id, [FromBody] ToggleCourtFavoriteRequest request)
    {
        try
        {
            var favorite =
                await _courtService.ToggleFavoriteAsync(CurrentUserId, id, request.Favorite);
            return Ok(ApiResponse<object>.Ok(new { favorite }));
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

    // GET /api/courts/{id}
    [AllowAnonymous]
    [HttpGet("{id:int}")]
    public async Task<IActionResult> GetCourt(int id)
    {
        try
        {
            var court = await _courtService.GetCourtByIdAsync(id, CurrentUserId);
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

    // GET /api/courts/{id}/availability?date=yyyy-MM-dd&durationMinutes=60&endDate=yyyy-MM-dd
    // endDate (اختياري): آخر يوم في المدى — يُستعمل للبطولة التي تشغل نفس
    // الموعد من كل يوم، فلا يُعرض الموعد متاحاً إلا إذا كان فارغاً فيها كلها.
    [AllowAnonymous]
    [HttpGet("{id:int}/availability")]
    public async Task<IActionResult> GetAvailability(
        int id, [FromQuery] DateTime? date, [FromQuery] int durationMinutes = 60,
        [FromQuery] DateTime? endDate = null)
    {
        try
        {
            var day = date ?? DateTime.UtcNow.Date;
            var availability = await _courtService.GetAvailabilityAsync(
                id, day, durationMinutes, requireApproved: true, endDate: endDate);
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
