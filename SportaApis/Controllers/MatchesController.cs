using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SportaApis.DTOs;
using SportaApis.Services;

namespace SportaApis.Controllers;

[ApiController]
[Route("api/matches")]
[Authorize]
public class MatchesController : ControllerBase
{
    private readonly IMatchService _matchService;

    public MatchesController(IMatchService matchService) =>
        _matchService = matchService;

    /// <summary>
    /// معرّف المستخدم من التوكن، و<c>0</c> للزائر غير المسجّل — نقاط التصفح
    /// العامة مفتوحة له (App Store 5.1.1)، ولا يملك مفضلة ولا موقعاً محفوظاً.
    /// </summary>
    private int CurrentUserId =>
        int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var id) ? id : 0;

    // GET /api/matches?city=&gender=&page=&pageSize=
    [AllowAnonymous]
    [HttpGet]
    public async Task<IActionResult> GetMatches(
        [FromQuery] string? city,
        [FromQuery] string? gender,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        try
        {
            var matches = await _matchService.GetMatchesAsync(
                CurrentUserId, city, gender, page, pageSize);
            return Ok(ApiResponse<PagedResult<MatchDto>>.Ok(matches));
        }
        catch (Exception)
        {
            return StatusCode(500, ApiResponse<object>.Fail(
                "An unexpected error occurred", "حدث خطأ غير متوقع", "UNEXPECTED"));
        }
    }

    // GET /api/matches/me?page=&pageSize=&status=&active=true|finished=true&matchesOnly=true&sort=newest
    [HttpGet("me")]
    public async Task<IActionResult> GetMyMatches(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10,
        [FromQuery] string? status = null,
        [FromQuery] bool active = false,
        [FromQuery] bool matchesOnly = false,
        [FromQuery] string? sort = null,
        [FromQuery] bool finished = false)
    {
        try
        {
            var matches = await _matchService.GetMyMatchesAsync(
                CurrentUserId, page, pageSize, status, active, matchesOnly,
                newestFirst: string.Equals(sort, "newest", StringComparison.OrdinalIgnoreCase),
                finishedOnly: finished);
            return Ok(ApiResponse<PagedResult<MatchDto>>.Ok(matches));
        }
        catch (Exception)
        {
            return StatusCode(500, ApiResponse<object>.Fail(
                "An unexpected error occurred", "حدث خطأ غير متوقع", "UNEXPECTED"));
        }
    }

    // GET /api/matches/upcoming
    [HttpGet("upcoming")]
    public async Task<IActionResult> GetUpcoming()
    {
        try
        {
            var matches = await _matchService.GetUpcomingAsync(CurrentUserId);
            return Ok(ApiResponse<List<MatchDto>>.Ok(matches));
        }
        catch (Exception)
        {
            return StatusCode(500, ApiResponse<object>.Fail(
                "An unexpected error occurred", "حدث خطأ غير متوقع", "UNEXPECTED"));
        }
    }

    // GET /api/matches/{id}
    [AllowAnonymous]
    [HttpGet("{id:int}")]
    public async Task<IActionResult> GetMatch(int id)
    {
        try
        {
            var match = await _matchService.GetByIdAsync(CurrentUserId, id);
            return Ok(ApiResponse<MatchDto>.Ok(match));
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

    // POST /api/matches
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateMatchRequest request)
    {
        try
        {
            var match = await _matchService.CreateAsync(CurrentUserId, request);
            return Ok(ApiResponse<MatchDto>.Ok(match));
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

    // POST /api/matches/{id}/cancel — صاحب الملعب يلغي حدثاً يستضيفه
    [HttpPost("{id:int}/cancel")]
    public async Task<IActionResult> CancelHosted(int id)
    {
        try
        {
            var match = await _matchService.CancelHostedAsync(CurrentUserId, id);
            return Ok(ApiResponse<MatchDto>.Ok(match));
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

    // POST /api/matches/{id}/result
    [HttpPost("{id:int}/result")]
    public async Task<IActionResult> SubmitResult(
        int id, [FromBody] SubmitMatchResultRequest request)
    {
        try
        {
            var match = await _matchService.SubmitResultAsync(CurrentUserId, id, request);
            return Ok(ApiResponse<MatchDto>.Ok(match));
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

    // POST /api/matches/{id}/result/respond { accept, ratings } — لاعب من الفريق الآخر يؤكد/يرفض
    [HttpPost("{id:int}/result/respond")]
    public async Task<IActionResult> RespondResult(int id, [FromBody] RespondResultRequest request)
    {
        try
        {
            var match = await _matchService.RespondResultAsync(CurrentUserId, id, request);
            return Ok(ApiResponse<MatchDto>.Ok(match));
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

    // POST /api/matches/{id}/result/resolve { team1Score, team2Score, team1PlayerIds } — المنظّم يحسم الخلاف
    [HttpPost("{id:int}/result/resolve")]
    public async Task<IActionResult> ResolveResult(int id, [FromBody] ResolveResultRequest request)
    {
        try
        {
            var match = await _matchService.ResolveResultAsync(CurrentUserId, id, request);
            return Ok(ApiResponse<MatchDto>.Ok(match));
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

    // POST /api/matches/{id}/make-public — المنشئ يفتح مباراته الخاصة للجميع
    [HttpPost("{id:int}/make-public")]
    public async Task<IActionResult> MakePublic(int id)
    {
        try
        {
            var match = await _matchService.MakePublicAsync(CurrentUserId, id);
            return Ok(ApiResponse<MatchDto>.Ok(match));
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

    // POST /api/matches/{id}/invite
    [HttpPost("{id:int}/invite")]
    public async Task<IActionResult> Invite(int id, [FromBody] InvitePlayerRequest request)
    {
        try
        {
            var match = await _matchService.InviteAsync(CurrentUserId, id, request.UserId);
            return Ok(ApiResponse<MatchDto>.Ok(match));
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

    // POST /api/matches/{id}/invite/respond  (invited player accepts/declines)
    [HttpPost("{id:int}/invite/respond")]
    public async Task<IActionResult> RespondToInvite(
        int id, [FromBody] InviteRespondRequest request)
    {
        try
        {
            var match = await _matchService.RespondToInviteAsync(
                CurrentUserId, id, request.Accept);
            return Ok(ApiResponse<MatchDto>.Ok(match));
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

    // POST /api/matches/{id}/join
    [HttpPost("{id:int}/join")]
    public async Task<IActionResult> Join(int id)
    {
        try
        {
            var match = await _matchService.JoinAsync(CurrentUserId, id);
            return Ok(ApiResponse<MatchDto>.Ok(match));
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

    // POST /api/matches/{id}/withdraw — انسحاب اللاعب (مباشر قبل 24 ساعة، وإلا طلب للمنشئ)
    [HttpPost("{id:int}/withdraw")]
    public async Task<IActionResult> Withdraw(int id, [FromServices] IWithdrawalService withdrawals)
    {
        try
        {
            var outcome = await withdrawals.WithdrawAsync(CurrentUserId, id);
            var match = await _matchService.GetByIdAsync(CurrentUserId, id);
            return Ok(ApiResponse<WithdrawalResultDto<MatchDto>>.Ok(new()
            {
                Outcome = WithdrawalOutcomeName(outcome),
                Event = match,
            }));
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

    // POST /api/matches/{id}/withdraw/respond { userId, approve } — المنشئ يبتّ في طلب انسحاب
    [HttpPost("{id:int}/withdraw/respond")]
    public async Task<IActionResult> RespondWithdrawal(
        int id, [FromBody] WithdrawalRespondRequest request,
        [FromServices] IWithdrawalService withdrawals)
    {
        try
        {
            await withdrawals.RespondAsync(CurrentUserId, id, request.UserId, request.Approve);
            var match = await _matchService.GetByIdAsync(CurrentUserId, id);
            return Ok(ApiResponse<MatchDto>.Ok(match));
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

    internal static string WithdrawalOutcomeName(WithdrawalOutcome outcome) => outcome switch
    {
        WithdrawalOutcome.Requested => "requested",
        WithdrawalOutcome.RequestCancelled => "requestCancelled",
        _ => "withdrawn",
    };

    // GET/POST/DELETE /api/matches/{id}/waitlist — قائمة الانتظار (حالتها، التسجيل، المغادرة)
    [AllowAnonymous]
    [HttpGet("{id:int}/waitlist")]
    public Task<IActionResult> GetWaitlist(int id, [FromServices] IWaitlistService waitlist) =>
        RunWaitlist(() => waitlist.GetStatusAsync(CurrentUserId, id));

    [HttpPost("{id:int}/waitlist")]
    public Task<IActionResult> JoinWaitlist(int id, [FromServices] IWaitlistService waitlist) =>
        RunWaitlist(() => waitlist.JoinAsync(CurrentUserId, id));

    [HttpDelete("{id:int}/waitlist")]
    public Task<IActionResult> LeaveWaitlist(int id, [FromServices] IWaitlistService waitlist) =>
        RunWaitlist(() => waitlist.LeaveAsync(CurrentUserId, id));

    internal static async Task<IActionResult> RunWaitlistCore(
        ControllerBase c, Func<Task<WaitlistStatusDto>> action)
    {
        try
        {
            return c.Ok(ApiResponse<WaitlistStatusDto>.Ok(await action()));
        }
        catch (AuthException ex)
        {
            return c.BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
        catch (Exception)
        {
            return c.StatusCode(500, ApiResponse<object>.Fail(
                "An unexpected error occurred", "حدث خطأ غير متوقع", "UNEXPECTED"));
        }
    }

    private Task<IActionResult> RunWaitlist(Func<Task<WaitlistStatusDto>> action) =>
        RunWaitlistCore(this, action);

    // GET /api/matches/{id}/requests  (creator only)
    [HttpGet("{id:int}/requests")]
    public async Task<IActionResult> GetRequests(int id)
    {
        try
        {
            var requests = await _matchService.GetJoinRequestsAsync(CurrentUserId, id);
            return Ok(ApiResponse<List<MatchPlayerDto>>.Ok(requests));
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

    // POST /api/matches/{id}/requests/respond  (creator only)
    [HttpPost("{id:int}/requests/respond")]
    public async Task<IActionResult> RespondToRequest(
        int id, [FromBody] JoinRequestRespondRequest request)
    {
        try
        {
            var match = await _matchService.RespondToJoinRequestAsync(
                CurrentUserId, id, request.UserId, request.Approve);
            return Ok(ApiResponse<MatchDto>.Ok(match));
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
