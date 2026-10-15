using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SportaApis.DTOs;
using SportaApis.Services;

namespace SportaApis.Controllers;

/// <summary>
/// البطولة الإقصائية. الانضمام ودعوة الشريك والردّ عليها عبر
/// <c>/api/americano/{id}/join|invite|invite/respond</c> (البطولة أمريكانو فرق
/// بنظام إقصائي)؛ هنا الإنشاء والقراءة والنتائج وإجراءات المنظّم.
/// </summary>
[ApiController]
[Route("api/tournaments")]
[Authorize]
public class TournamentsController : ControllerBase
{
    private readonly ITournamentService _tournaments;
    private readonly IShowcaseTournamentService _showcase;

    public TournamentsController(ITournamentService tournaments, IShowcaseTournamentService showcase)
    {
        _tournaments = tournaments;
        _showcase = showcase;
    }

    private int CurrentUserId =>
        int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var id) ? id : 0;

    // GET /api/tournaments — البطولات الاستعراضية (دولية/محلية) للعرض فقط
    [AllowAnonymous]
    [HttpGet]
    public Task<IActionResult> GetShowcase() => Run(() => _showcase.GetAllAsync());

    // POST /api/tournaments/quote — تقدير قبل الإنشاء
    [HttpPost("quote")]
    public Task<IActionResult> Quote([FromBody] TournamentQuoteRequest request) =>
        Run(() => _tournaments.QuoteAsync(request));

    // POST /api/tournaments
    [HttpPost]
    public Task<IActionResult> Create([FromBody] CreateTournamentRequest request) =>
        Run(() => _tournaments.CreateAsync(CurrentUserId, request));

    // GET /api/tournaments/{id}
    [AllowAnonymous]
    [HttpGet("{id:int}")]
    public Task<IActionResult> GetById(int id) =>
        Run(() => _tournaments.GetByIdAsync(id), notFound: true);

    // POST /api/tournaments/fixtures/{fixtureId}/score
    [HttpPost("fixtures/{fixtureId:int}/score")]
    public Task<IActionResult> SubmitScore(int fixtureId, [FromBody] SubmitFixtureScoreRequest request) =>
        Run(() => _tournaments.SubmitFixtureScoreAsync(CurrentUserId, fixtureId, request));

    // POST /api/tournaments/fixtures/{fixtureId}/score/respond { accept } — الفريق الآخر يؤكد/يرفض
    [HttpPost("fixtures/{fixtureId:int}/score/respond")]
    public Task<IActionResult> RespondScore(int fixtureId, [FromBody] RespondResultRequest request) =>
        Run(() => _tournaments.RespondFixtureScoreAsync(CurrentUserId, fixtureId, request));

    // POST /api/tournaments/fixtures/{fixtureId}/score/resolve { team1Score, team2Score } — المنظّم يحسم الخلاف
    [HttpPost("fixtures/{fixtureId:int}/score/resolve")]
    public Task<IActionResult> ResolveScore(int fixtureId, [FromBody] SubmitFixtureScoreRequest request) =>
        Run(() => _tournaments.ResolveFixtureScoreAsync(CurrentUserId, fixtureId, request));

    // POST /api/tournaments/fixtures/{fixtureId}/score/organizer { team1Score, team2Score, walkover }
    // المنظّم يسجّل نتيجة مباراة مرّ موعدها بلا اعتماد، أو فوزاً إدارياً عند غياب فريق
    [HttpPost("fixtures/{fixtureId:int}/score/organizer")]
    public Task<IActionResult> RecordScore(int fixtureId, [FromBody] OrganizerFixtureResultRequest request) =>
        Run(() => _tournaments.RecordFixtureResultAsync(CurrentUserId, fixtureId, request));

    // PUT /api/tournaments/{id}/teams/{team}/name { name }
    [HttpPut("{id:int}/teams/{team:int}/name")]
    public Task<IActionResult> RenameTeam(int id, int team, [FromBody] RenameTeamRequest request) =>
        Run(() => _tournaments.RenameTeamAsync(CurrentUserId, id, team, request.Name));

    // POST /api/tournaments/{id}/start — البدء بالفرق المكتملة الحالية
    [HttpPost("{id:int}/start")]
    public Task<IActionResult> Start(int id) =>
        Run(() => _tournaments.StartWithCurrentAsync(CurrentUserId, id));

    // POST /api/tournaments/{id}/postpone { scheduledAt }
    [HttpPost("{id:int}/postpone")]
    public Task<IActionResult> Postpone(int id, [FromBody] PostponeTournamentRequest request) =>
        Run(() => _tournaments.PostponeAsync(CurrentUserId, id, request.ScheduledAt));

    // POST /api/tournaments/{id}/cancel
    [HttpPost("{id:int}/cancel")]
    public Task<IActionResult> Cancel(int id) =>
        Run(() => _tournaments.CancelAsync(CurrentUserId, id));

    private async Task<IActionResult> Run<T>(Func<Task<T>> action, bool notFound = false)
    {
        try
        {
            return Ok(ApiResponse<T>.Ok(await action()));
        }
        catch (AuthException ex)
        {
            var body = ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code);
            return notFound ? NotFound(body) : BadRequest(body);
        }
        catch (Exception)
        {
            return StatusCode(500, ApiResponse<object>.Fail(
                "An unexpected error occurred", "حدث خطأ غير متوقع", "UNEXPECTED"));
        }
    }
}
