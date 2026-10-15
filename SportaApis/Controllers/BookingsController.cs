using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SportaApis.DTOs;
using SportaApis.Services;

namespace SportaApis.Controllers;

[ApiController]
[Route("api/bookings")]
[Authorize]
public class BookingsController : ControllerBase
{
    private readonly IBookingService _bookingService;

    public BookingsController(IBookingService bookingService) =>
        _bookingService = bookingService;

    private int CurrentUserId =>
        int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    // POST /api/bookings
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateBookingRequest request)
    {
        try
        {
            var booking = await _bookingService.CreateAsync(CurrentUserId, request);
            return Ok(ApiResponse<BookingDto>.Ok(booking));
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

    // POST /api/bookings/quote — تسعير قبل الحجز (لا يُنشئ حجزاً ولا يخصم رصيداً)
    [HttpPost("quote")]
    public async Task<IActionResult> Quote([FromBody] BookingQuoteRequest request)
    {
        try
        {
            var quote = await _bookingService.QuoteAsync(CurrentUserId, request);
            return Ok(ApiResponse<BookingQuoteDto>.Ok(quote));
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

    // GET /api/bookings/me
    [HttpGet("me")]
    public async Task<IActionResult> GetMyBookings(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10,
        [FromQuery] string? status = null)
    {
        try
        {
            var bookings = await _bookingService.GetMyBookingsAsync(
                CurrentUserId, page, pageSize, status);
            return Ok(ApiResponse<PagedResult<BookingDto>>.Ok(bookings));
        }
        catch (Exception)
        {
            return StatusCode(500, ApiResponse<object>.Fail(
                "An unexpected error occurred", "حدث خطأ غير متوقع", "UNEXPECTED"));
        }
    }

    // PUT /api/bookings/{id}/cancel
    [HttpPut("{id:int}/cancel")]
    public async Task<IActionResult> Cancel(int id, [FromBody] CancelBookingRequest? request)
    {
        try
        {
            var booking = await _bookingService.CancelAsync(CurrentUserId, id, request?.Reason);
            return Ok(ApiResponse<BookingDto>.Ok(booking));
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
}

public class CancelBookingRequest
{
    public string? Reason { get; set; }
}
