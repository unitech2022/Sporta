using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SportaApis.DTOs;
using SportaApis.Enums;
using SportaApis.Services;

namespace SportaApis.Controllers;

/// <summary>
/// التقييم المتبادل بعد التجربة.
/// <list type="bullet">
/// <item>GET  /api/reviews/pending — تجارب انتهت وفيها أطراف لم أقيّمهم.</item>
/// <item>GET  /api/reviews/{match|booking|session}/{id} — من يحقّ لي تقييمه وتقييماتي.</item>
/// <item>POST /api/reviews/{match|booking|session}/{id} — إرسال/تعديل دفعة تقييمات.</item>
/// <item>GET  /api/courts/{courtId}/ratings — ملخّص الملعب ومراجعاته (عام).</item>
/// <item>GET  /api/players/{userId}/reputation — سمعة اللاعب (بلا أسماء ولا تعليقات).</item>
/// </list>
/// </summary>
[ApiController]
[Authorize]
public class ReviewsController : ControllerBase
{
    private readonly IReviewService _reviews;

    public ReviewsController(IReviewService reviews) => _reviews = reviews;

    private int CurrentUserId =>
        int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var id) ? id : 0;

    private static ReviewContextType? ParseContext(string context) => context.ToLowerInvariant() switch
    {
        "match" => ReviewContextType.Match,
        "booking" => ReviewContextType.Booking,
        "session" => ReviewContextType.CoachSession,
        _ => null,
    };

    [HttpGet("api/reviews/pending")]
    public Task<IActionResult> Pending() => Run(() => _reviews.GetPendingAsync(CurrentUserId));

    [HttpGet("api/reviews/{context}/{id:int}")]
    public Task<IActionResult> Session(string context, int id) =>
        ParseContext(context) is { } ctx
            ? Run(() => _reviews.GetSessionAsync(CurrentUserId, ctx, id))
            : Task.FromResult(BadContext());

    [HttpPost("api/reviews/{context}/{id:int}")]
    public Task<IActionResult> Submit(string context, int id, [FromBody] SubmitReviewsRequest request) =>
        ParseContext(context) is { } ctx
            ? Run(() => _reviews.SubmitAsync(CurrentUserId, ctx, id, request))
            : Task.FromResult(BadContext());

    [AllowAnonymous]
    [HttpGet("api/courts/{courtId:int}/ratings")]
    public Task<IActionResult> CourtRatings(
        int courtId, [FromQuery] int page = 1, [FromQuery] int pageSize = 10) =>
        Run(() => _reviews.GetCourtRatingsAsync(courtId, page, pageSize));

    [HttpGet("api/players/{userId:int}/reputation")]
    public Task<IActionResult> Reputation(int userId) =>
        Run(() => _reviews.GetPlayerReputationAsync(userId));

    private IActionResult BadContext() => BadRequest(ApiResponse<object>.Fail(
        "Unknown context", "نوع التجربة غير معروف", "REVIEW_BAD_CONTEXT"));

    private async Task<IActionResult> Run<T>(Func<Task<T>> action)
    {
        try
        {
            return Ok(ApiResponse<T>.Ok(await action()));
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
