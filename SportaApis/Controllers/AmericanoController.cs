using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SportaApis.DTOs;
using SportaApis.Services;

namespace SportaApis.Controllers;

[ApiController]
[Route("api/americano")]
[Authorize]
public class AmericanoController : ControllerBase
{
    private readonly IAmericanoService _americanoService;

    public AmericanoController(IAmericanoService americanoService) =>
        _americanoService = americanoService;

    /// <summary>معرّف المستخدم من التوكن، و<c>0</c> للزائر في نقاط التصفح العامة.</summary>
    private int CurrentUserId =>
        int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var id) ? id : 0;

    // GET /api/americano?page=&pageSize=&kind=americano|tournament
    [AllowAnonymous]
    [HttpGet]
    public async Task<IActionResult> GetAll(
        [FromQuery] int page = 1, [FromQuery] int pageSize = 20,
        [FromQuery] string? kind = null)
    {
        try
        {
            var list = await _americanoService.GetAllAsync(page, pageSize, kind, CurrentUserId);
            return Ok(ApiResponse<PagedResult<AmericanoDto>>.Ok(list));
        }
        catch (Exception)
        {
            return StatusCode(500, ApiResponse<object>.Fail(
                "An unexpected error occurred", "حدث خطأ غير متوقع", "UNEXPECTED"));
        }
    }

    // GET /api/americano/me?page=&pageSize=&kind=americano|tournament&active=true|finished=true
    [HttpGet("me")]
    public async Task<IActionResult> GetMine(
        [FromQuery] int page = 1, [FromQuery] int pageSize = 20,
        [FromQuery] string? kind = null, [FromQuery] bool active = false,
        [FromQuery] bool finished = false)
    {
        try
        {
            var list = await _americanoService.GetMineAsync(
                CurrentUserId, page, pageSize, kind, active, finished);
            return Ok(ApiResponse<PagedResult<AmericanoDto>>.Ok(list));
        }
        catch (Exception)
        {
            return StatusCode(500, ApiResponse<object>.Fail(
                "An unexpected error occurred", "حدث خطأ غير متوقع", "UNEXPECTED"));
        }
    }

    // GET /api/americano/{id}
    [AllowAnonymous]
    [HttpGet("{id:int}")]
    public async Task<IActionResult> GetById(int id)
    {
        try
        {
            var dto = await _americanoService.GetByIdAsync(id);
            return Ok(ApiResponse<AmericanoDto>.Ok(dto));
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

    // POST /api/americano
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateAmericanoRequest request)
    {
        try
        {
            var dto = await _americanoService.CreateAsync(CurrentUserId, request);
            return Ok(ApiResponse<AmericanoDto>.Ok(dto));
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

    // POST /api/americano/{id}/join  { team?, partnerId? }  (body optional; teams only)
    [HttpPost("{id:int}/join")]
    public async Task<IActionResult> Join(
        int id, [FromBody] JoinAmericanoRequest? request = null)
    {
        try
        {
            var dto = await _americanoService.JoinAsync(CurrentUserId, id, request);
            return Ok(ApiResponse<AmericanoDto>.Ok(dto));
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

    // POST /api/americano/{id}/invite  { userId }   (teams: captain invites a friend)
    [HttpPost("{id:int}/invite")]
    public async Task<IActionResult> InvitePartner(
        int id, [FromBody] AmericanoInviteRequest request)
    {
        try
        {
            var dto = await _americanoService.InvitePartnerAsync(
                CurrentUserId, id, request.UserId);
            return Ok(ApiResponse<AmericanoDto>.Ok(dto));
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

    // POST /api/americano/{id}/invite/respond  { accept }   (invited partner replies)
    [HttpPost("{id:int}/invite/respond")]
    public async Task<IActionResult> RespondToInvite(
        int id, [FromBody] AmericanoInviteRespondRequest request)
    {
        try
        {
            var dto = await _americanoService.RespondToPartnerInviteAsync(
                CurrentUserId, id, request.Accept);
            return Ok(ApiResponse<AmericanoDto>.Ok(dto));
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

    // POST /api/americano/rounds/{roundId}/score
    [HttpPost("rounds/{roundId:int}/score")]
    public async Task<IActionResult> SubmitScore(
        int roundId, [FromBody] SubmitRoundScoreRequest request)
    {
        try
        {
            var dto = await _americanoService.SubmitRoundScoreAsync(
                roundId, request, CurrentUserId);
            return Ok(ApiResponse<AmericanoDto>.Ok(dto));
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

    // POST /api/americano/rounds/{roundId}/score/respond { accept } — الفريق الآخر يؤكد/يرفض
    [HttpPost("rounds/{roundId:int}/score/respond")]
    public async Task<IActionResult> RespondScore(
        int roundId, [FromBody] RespondResultRequest request)
    {
        try
        {
            var dto = await _americanoService.RespondRoundScoreAsync(
                roundId, request, CurrentUserId);
            return Ok(ApiResponse<AmericanoDto>.Ok(dto));
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

    // POST /api/americano/{id}/requests/respond { userId, approve } — المنظّم يقبل/يرفض طلب انضمام
    [HttpPost("{id:int}/requests/respond")]
    public async Task<IActionResult> RespondToJoinRequest(
        int id, [FromBody] JoinRequestRespondRequest request)
    {
        try
        {
            var dto = await _americanoService.RespondToJoinRequestAsync(
                CurrentUserId, id, request.UserId, request.Approve);
            return Ok(ApiResponse<AmericanoDto>.Ok(dto));
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

    // POST /api/americano/{id}/withdraw — انسحاب من أمريكانو/بطولة (مباشر قبل 48 ساعة، وإلا طلب للمنظّم)
    [HttpPost("{id:int}/withdraw")]
    public async Task<IActionResult> Withdraw(int id, [FromServices] IWithdrawalService withdrawals)
    {
        try
        {
            var matchId = await withdrawals.MatchIdOfAmericanoAsync(id);
            var outcome = await withdrawals.WithdrawAsync(CurrentUserId, matchId);
            var dto = await _americanoService.GetByIdAsync(id);
            return Ok(ApiResponse<WithdrawalResultDto<AmericanoDto>>.Ok(new()
            {
                Outcome = MatchesController.WithdrawalOutcomeName(outcome),
                Event = dto,
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

    // POST /api/americano/{id}/withdraw/respond { userId, approve } — المنظّم يبتّ في طلب انسحاب
    [HttpPost("{id:int}/withdraw/respond")]
    public async Task<IActionResult> RespondWithdrawal(
        int id, [FromBody] WithdrawalRespondRequest request,
        [FromServices] IWithdrawalService withdrawals)
    {
        try
        {
            var matchId = await withdrawals.MatchIdOfAmericanoAsync(id);
            await withdrawals.RespondAsync(CurrentUserId, matchId, request.UserId, request.Approve);
            var dto = await _americanoService.GetByIdAsync(id);
            return Ok(ApiResponse<AmericanoDto>.Ok(dto));
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

    // GET/POST/DELETE /api/americano/{id}/waitlist — قائمة الانتظار (الأمريكانو الفردي)
    [AllowAnonymous]
    [HttpGet("{id:int}/waitlist")]
    public async Task<IActionResult> GetWaitlist(
        int id, [FromServices] IWaitlistService waitlist, [FromServices] IWithdrawalService withdrawals) =>
        await MatchesController.RunWaitlistCore(this, async () =>
            await waitlist.GetStatusAsync(CurrentUserId, await withdrawals.MatchIdOfAmericanoAsync(id)));

    [HttpPost("{id:int}/waitlist")]
    public async Task<IActionResult> JoinWaitlist(
        int id, [FromServices] IWaitlistService waitlist, [FromServices] IWithdrawalService withdrawals) =>
        await MatchesController.RunWaitlistCore(this, async () =>
            await waitlist.JoinAsync(CurrentUserId, await withdrawals.MatchIdOfAmericanoAsync(id)));

    [HttpDelete("{id:int}/waitlist")]
    public async Task<IActionResult> LeaveWaitlist(
        int id, [FromServices] IWaitlistService waitlist, [FromServices] IWithdrawalService withdrawals) =>
        await MatchesController.RunWaitlistCore(this, async () =>
            await waitlist.LeaveAsync(CurrentUserId, await withdrawals.MatchIdOfAmericanoAsync(id)));

    // POST /api/americano/rounds/{roundId}/score/resolve { team1Score, team2Score } — المنظّم يحسم الخلاف
    [HttpPost("rounds/{roundId:int}/score/resolve")]
    public async Task<IActionResult> ResolveScore(
        int roundId, [FromBody] ResolveResultRequest request)
    {
        try
        {
            var dto = await _americanoService.ResolveRoundScoreAsync(roundId, request, CurrentUserId);
            return Ok(ApiResponse<AmericanoDto>.Ok(dto));
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
