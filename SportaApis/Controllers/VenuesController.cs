using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SportaApis.Attributes;
using SportaApis.DTOs;
using SportaApis.Enums;
using SportaApis.Services;

namespace SportaApis.Controllers;

[ApiController]
[Route("api/venues")]
[Authorize]
// كل مسارات هذا الكنترولر لصاحب الملعب، فتُقفل كلها حتى يعتمد الأدمن حسابه.
[RequireApprovedRole(UserType.VenueOwner)]
public class VenuesController : ControllerBase
{
    private readonly IVenueService _venueService;
    private readonly IVenueSubscriptionService _subscriptions;

    public VenuesController(
        IVenueService venueService, IVenueSubscriptionService subscriptions)
    {
        _venueService = venueService;
        _subscriptions = subscriptions;
    }

    private int CurrentUserId =>
        int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    // ── Subscription (venue owner) ────────────────────────────────────────────

    // GET /api/venues/subscription — الاشتراك الساري (null حين لا اشتراك)
    [HttpGet("subscription")]
    public async Task<IActionResult> GetSubscription()
    {
        var current = await _subscriptions.GetCurrentAsync(CurrentUserId);
        return Ok(ApiResponse<VenueSubscriptionDto?>.Ok(current));
    }

    // GET /api/venues/subscription/quote?yearly=  — السعر بعدد ملاعبه بعد الخصم
    [HttpGet("subscription/quote")]
    public async Task<IActionResult> QuoteSubscription([FromQuery] bool yearly = false)
    {
        var quote = await _subscriptions.QuoteAsync(CurrentUserId, yearly);
        return Ok(ApiResponse<VenueSubscriptionQuoteDto>.Ok(quote));
    }

    // POST /api/venues/subscription  { isYearly }
    [HttpPost("subscription")]
    public async Task<IActionResult> Subscribe([FromBody] SubscribeVenueRequest request)
    {
        try
        {
            var created = await _subscriptions.SubscribeAsync(CurrentUserId, request.IsYearly);
            return Ok(ApiResponse<VenueSubscriptionDto>.Ok(created));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    // GET /api/venues/options
    // Anonymous so the coach registration flow can list venues before an
    // account exists (picking a "preferred training venue" while registering).
    [HttpGet("options")]
    [AllowAnonymous]
    public async Task<IActionResult> GetOptions()
    {
        var items = await _venueService.GetOptionsAsync();
        return Ok(ApiResponse<List<VenueOptionDto>>.Ok(items));
    }

    // GET /api/venues/dashboard
    [HttpGet("dashboard")]
    public async Task<IActionResult> GetDashboard()
    {
        try
        {
            var dto = await _venueService.GetDashboardAsync(CurrentUserId);
            return Ok(ApiResponse<VenueDashboardDto>.Ok(dto));
        }
        catch (Exception)
        {
            return StatusCode(500, ApiResponse<object>.Fail(
                "An unexpected error occurred", "حدث خطأ غير متوقع", "UNEXPECTED"));
        }
    }

    // GET /api/venues/revenue?type=month|week&offset=0
    [HttpGet("revenue")]
    public async Task<IActionResult> GetRevenue(
        [FromQuery] string type = "month", [FromQuery] int offset = 0)
    {
        try
        {
            var dto = await _venueService.GetRevenueReportAsync(
                CurrentUserId, type, Math.Max(0, offset));
            return Ok(ApiResponse<VenueRevenueReportDto>.Ok(dto));
        }
        catch (Exception)
        {
            return StatusCode(500, ApiResponse<object>.Fail(
                "An unexpected error occurred", "حدث خطأ غير متوقع", "UNEXPECTED"));
        }
    }

    // GET /api/venues/mine
    [HttpGet("mine")]
    public async Task<IActionResult> GetMine()
    {
        var venues = await _venueService.GetMyVenuesAsync(CurrentUserId);
        return Ok(ApiResponse<List<OwnerVenueDto>>.Ok(venues));
    }

    // GET /api/venues/bookings?page=&pageSize=&status=
    [HttpGet("bookings")]
    public async Task<IActionResult> GetVenueBookings(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10,
        [FromQuery] string? status = null)
    {
        var result = await _venueService.GetVenueBookingsAsync(
            CurrentUserId, page, pageSize, status);
        return Ok(ApiResponse<PagedResult<VenueBookingDto>>.Ok(result));
    }

    // POST /api/venues/bookings/{id}/respond  { approve }
    [HttpPost("bookings/{id:int}/respond")]
    public async Task<IActionResult> RespondToBooking(
        int id, [FromBody] BookingRespondRequest request)
    {
        try
        {
            var booking = await _venueService.RespondToBookingAsync(
                CurrentUserId, id, request.Approve);
            return Ok(ApiResponse<VenueBookingDto>.Ok(booking));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
        catch (Exception)
        {
            return StatusCode(500, ApiResponse<object>.Fail(
                "An unexpected error occurred", "حدث خطأ غير متوقع", "UNEXPECTED"));
        }
    }

    // GET /api/venues/match-requests?page=&pageSize=&status=&kind=
    [HttpGet("match-requests")]
    public async Task<IActionResult> GetMatchRequests(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10,
        [FromQuery] string? status = null,
        [FromQuery] bool mine = false,
        [FromQuery] string? kind = null)
    {
        var result = await _venueService.GetMatchRequestsAsync(
            CurrentUserId, page, pageSize, status, mine, kind);
        return Ok(ApiResponse<PagedResult<VenueMatchRequestDto>>.Ok(result));
    }

    // GET /api/venues/match-requests/{id}
    [HttpGet("match-requests/{id:int}")]
    public async Task<IActionResult> GetMatchRequest(int id)
    {
        try
        {
            var match = await _venueService.GetMatchRequestAsync(CurrentUserId, id);
            return Ok(ApiResponse<VenueMatchRequestDetailDto>.Ok(match));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    // POST /api/venues/match-requests/{id}/respond  { approve }
    [HttpPost("match-requests/{id:int}/respond")]
    public async Task<IActionResult> RespondToMatchRequest(
        int id, [FromBody] BookingRespondRequest request)
    {
        try
        {
            var match = await _venueService.RespondToMatchRequestAsync(
                CurrentUserId, id, request.Approve);
            return Ok(ApiResponse<VenueMatchRequestDto>.Ok(match));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
        catch (Exception)
        {
            return StatusCode(500, ApiResponse<object>.Fail(
                "An unexpected error occurred", "حدث خطأ غير متوقع", "UNEXPECTED"));
        }
    }

    // POST /api/venues
    [HttpPost]
    public async Task<IActionResult> CreateVenue([FromBody] CreateVenueRequest request)
    {
        try
        {
            var venue = await _venueService.CreateVenueAsync(CurrentUserId, request);
            return Ok(ApiResponse<OwnerVenueDto>.Ok(venue));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
        catch (Exception)
        {
            return StatusCode(500, ApiResponse<object>.Fail(
                "An unexpected error occurred", "حدث خطأ غير متوقع", "UNEXPECTED"));
        }
    }

    // POST /api/venues/{venueId}/courts
    [HttpPost("{venueId:int}/courts")]
    public async Task<IActionResult> AddCourt(
        int venueId, [FromBody] CreateCourtRequest request)
    {
        try
        {
            var court = await _venueService.AddCourtAsync(CurrentUserId, venueId, request);
            return Ok(ApiResponse<OwnerCourtDto>.Ok(court));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
        catch (Exception)
        {
            return StatusCode(500, ApiResponse<object>.Fail(
                "An unexpected error occurred", "حدث خطأ غير متوقع", "UNEXPECTED"));
        }
    }

    // PUT /api/venues/courts/{courtId}
    [HttpPut("courts/{courtId:int}")]
    public async Task<IActionResult> UpdateCourt(
        int courtId, [FromBody] UpdateCourtRequest request)
    {
        try
        {
            var court = await _venueService.UpdateCourtAsync(CurrentUserId, courtId, request);
            return Ok(ApiResponse<OwnerCourtDto>.Ok(court));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
        catch (Exception)
        {
            return StatusCode(500, ApiResponse<object>.Fail(
                "An unexpected error occurred", "حدث خطأ غير متوقع", "UNEXPECTED"));
        }
    }

    // PUT /api/venues/courts/{courtId}/schedule — دوام الأسبوع وقواعد التسعير
    [HttpPut("courts/{courtId:int}/schedule")]
    public async Task<IActionResult> UpdateCourtSchedule(
        int courtId, [FromBody] UpdateCourtScheduleRequest request)
    {
        try
        {
            var court = await _venueService.UpdateCourtScheduleAsync(
                CurrentUserId, courtId, request);
            return Ok(ApiResponse<OwnerCourtDto>.Ok(court));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
        catch (Exception)
        {
            return StatusCode(500, ApiResponse<object>.Fail(
                "An unexpected error occurred", "حدث خطأ غير متوقع", "UNEXPECTED"));
        }
    }

    // GET /api/venues/{venueId}/pricing — أسعار النادي حسب الوقت (كل ملاعبه)
    [HttpGet("{venueId:int}/pricing")]
    public Task<IActionResult> GetVenuePricing(int venueId) =>
        RunPricing(() => _venueService.GetVenuePricingAsync(CurrentUserId, venueId));

    // PUT /api/venues/{venueId}/pricing — يطبّق النطاقات على كل الملاعب أو المختار منها
    [HttpPut("{venueId:int}/pricing")]
    public Task<IActionResult> UpdateVenuePricing(
        int venueId, [FromBody] UpdateVenuePriceRulesRequest request) =>
        RunPricing(() => _venueService.UpdateVenuePricingAsync(CurrentUserId, venueId, request));

    private async Task<IActionResult> RunPricing(Func<Task<VenuePricingDto>> action)
    {
        try
        {
            return Ok(ApiResponse<VenuePricingDto>.Ok(await action()));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
        catch (Exception)
        {
            return StatusCode(500, ApiResponse<object>.Fail(
                "An unexpected error occurred", "حدث خطأ غير متوقع", "UNEXPECTED"));
        }
    }

    // DELETE /api/venues/courts/{courtId}
    [HttpDelete("courts/{courtId:int}")]
    public async Task<IActionResult> DeleteCourt(int courtId)
    {
        try
        {
            await _venueService.DeleteCourtAsync(CurrentUserId, courtId);
            return Ok(ApiResponse<object>.Ok(new { deleted = true }));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
        catch (Exception)
        {
            return StatusCode(500, ApiResponse<object>.Fail(
                "An unexpected error occurred", "حدث خطأ غير متوقع", "UNEXPECTED"));
        }
    }

    // GET /api/venues/courts/{courtId}/slots?date=yyyy-MM-dd
    [HttpGet("courts/{courtId:int}/slots")]
    public async Task<IActionResult> GetCourtSlots(int courtId, [FromQuery] string? date)
    {
        try
        {
            var day = ParseDate(date);
            var slots = await _venueService.GetCourtSlotsAsync(CurrentUserId, courtId, day);
            return Ok(ApiResponse<OwnerCourtSlotsDto>.Ok(slots));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    // POST /api/venues/courts/{courtId}/slots/toggle  {date, hour}
    [HttpPost("courts/{courtId:int}/slots/toggle")]
    public async Task<IActionResult> ToggleCourtSlot(
        int courtId, [FromBody] ToggleSlotRequest request)
    {
        try
        {
            var day = ParseDate(request.Date);
            var slots = await _venueService.ToggleCourtSlotAsync(
                CurrentUserId, courtId, day, request.Hour);
            return Ok(ApiResponse<OwnerCourtSlotsDto>.Ok(slots));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    // POST /api/venues/courts/{courtId}/slots/bulk  {date, hours[], available}
    [HttpPost("courts/{courtId:int}/slots/bulk")]
    public async Task<IActionResult> SetCourtSlots(
        int courtId, [FromBody] BulkSlotsRequest request)
    {
        try
        {
            var day = ParseDate(request.Date);
            var slots = await _venueService.SetCourtSlotsAsync(
                CurrentUserId, courtId, day, request.Hours, request.Available);
            return Ok(ApiResponse<OwnerCourtSlotsDto>.Ok(slots));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    private static DateTime ParseDate(string? date) =>
        DateTime.TryParse(date, out var d) ? d.Date : DateTime.UtcNow.Date;
}
