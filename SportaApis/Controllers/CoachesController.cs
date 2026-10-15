using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SportaApis.Attributes;
using SportaApis.DTOs;
using SportaApis.Enums;
using SportaApis.Services;

namespace SportaApis.Controllers;

[ApiController]
[Route("api/coaches")]
[Authorize]
public class CoachesController : ControllerBase
{
    private readonly ICoachService _coachService;
    private readonly IWebHostEnvironment _env;

    public CoachesController(ICoachService coachService, IWebHostEnvironment env)
    {
        _coachService = coachService;
        _env = env;
    }

    /// <summary>
    /// معرّف المستخدم من التوكن، و<c>0</c> للزائر غير المسجّل — نقاط التصفح
    /// العامة مفتوحة له (App Store 5.1.1)، ولا يملك مفضلة ولا موقعاً محفوظاً.
    /// </summary>
    private bool IsAdminOrStaff => User.IsInRole("admin") || User.IsInRole("staff");

    /// <summary>
    /// الجوال وصورة الهوية وحالة الحساب للوحة التحكم فقط: القوائم العامة
    /// (بلا دخول حتى) كانت تعيدها لأي زائر.
    /// </summary>
    private static void StripPrivate(CoachDto c)
    {
        c.Phone = null;
        c.IdDocumentUrl = null;
    }

    private int CurrentUserId =>
        int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var id) ? id : 0;

    // GET /api/coaches?city=&gender=&includeInactive=&page=&pageSize=
    [AllowAnonymous]
    [HttpGet]
    public async Task<IActionResult> GetCoaches(
        [FromQuery] string? city,
        [FromQuery] string? gender,
        [FromQuery] bool includeInactive = false,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        try
        {
            var coaches = await _coachService.GetCoachesAsync(
                CurrentUserId, city, gender, includeInactive, page, pageSize);
            if (!IsAdminOrStaff)
                foreach (var c in coaches.Items) StripPrivate(c);
            return Ok(ApiResponse<PagedResult<CoachDto>>.Ok(coaches));
        }
        catch (Exception)
        {
            return StatusCode(500, ApiResponse<object>.Fail(
                "An unexpected error occurred", "حدث خطأ غير متوقع", "UNEXPECTED"));
        }
    }

    // GET /api/coaches/{id}
    [AllowAnonymous]
    [HttpGet("{id:int}")]
    public async Task<IActionResult> GetCoach(int id)
    {
        try
        {
            var coach = await _coachService.GetCoachByIdAsync(id);
            if (!IsAdminOrStaff) StripPrivate(coach);
            return Ok(ApiResponse<CoachDto>.Ok(coach));
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

    // POST /api/coaches/{id}/sessions
    [HttpPost("{id:int}/sessions")]
    public async Task<IActionResult> BookSession(
        int id, [FromBody] CreateCoachSessionRequest request)
    {
        try
        {
            var session = await _coachService.BookSessionAsync(CurrentUserId, id, request);
            return Ok(ApiResponse<CoachSessionDto>.Ok(session));
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

    // POST /api/coaches/sessions/{sessionId}/rate  (coach only — rates the player)
    [HttpPost("sessions/{sessionId:int}/rate")]
    [RequireApprovedRole(UserType.Coach)]
    public async Task<IActionResult> RateSession(
        int sessionId, [FromBody] RateSessionRequest request)
    {
        try
        {
            var session = await _coachService.RateSessionAsync(
                CurrentUserId, sessionId, request.Rating, request.Review);
            return Ok(ApiResponse<CoachSessionDto>.Ok(session));
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

    // POST /api/coaches/sessions/{sessionId}/rate-coach  (player — rates the coach)
    [HttpPost("sessions/{sessionId:int}/rate-coach")]
    public async Task<IActionResult> RateCoach(
        int sessionId, [FromBody] RateSessionRequest request)
    {
        try
        {
            var session = await _coachService.RateCoachAsync(
                CurrentUserId, sessionId, request.Rating, request.Review);
            return Ok(ApiResponse<CoachSessionDto>.Ok(session));
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

    // GET /api/coaches/assessments/pending?page=&pageSize=
    // المدرب المعتمد فقط: بدون هذا الشرط كان أي حساب يرى فيديوهات التقييم كلها
    // ويضع لأي لاعب مستواه.
    [HttpGet("assessments/pending")]
    [RequireApprovedRole(UserType.Coach)]
    public async Task<IActionResult> GetPendingAssessments(
        [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var items = await _coachService.GetPendingAssessmentsAsync(
            CurrentUserId, page, pageSize);
        return Ok(ApiResponse<PagedResult<LevelAssessmentDto>>.Ok(items));
    }

    // POST /api/coaches/assessments/{id}/assign
    [HttpPost("assessments/{id:int}/assign")]
    [RequireApprovedRole(UserType.Coach)]
    public async Task<IActionResult> AssignAssessment(
        int id, [FromBody] AssignLevelRequest request)
    {
        try
        {
            var dto = await _coachService.AssignAssessmentLevelAsync(
                CurrentUserId, id, request.Level, request.Notes);
            return Ok(ApiResponse<LevelAssessmentDto>.Ok(dto));
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

    // GET /api/coaches/dashboard
    [HttpGet("dashboard")]
    [RequireApprovedRole(UserType.Coach)]
    public async Task<IActionResult> GetDashboard()
    {
        try
        {
            var dto = await _coachService.GetDashboardAsync(CurrentUserId);
            return Ok(ApiResponse<CoachDashboardDto>.Ok(dto));
        }
        catch (Exception)
        {
            return StatusCode(500, ApiResponse<object>.Fail(
                "An unexpected error occurred", "حدث خطأ غير متوقع", "UNEXPECTED"));
        }
    }

    // GET /api/coaches/sessions/me
    [HttpGet("sessions/me")]
    public async Task<IActionResult> GetMySessions(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10,
        [FromQuery] string? status = null)
    {
        try
        {
            var sessions = await _coachService.GetMySessionsAsync(
                CurrentUserId, page, pageSize, status);
            return Ok(ApiResponse<PagedResult<CoachSessionDto>>.Ok(sessions));
        }
        catch (Exception)
        {
            return StatusCode(500, ApiResponse<object>.Fail(
                "An unexpected error occurred", "حدث خطأ غير متوقع", "UNEXPECTED"));
        }
    }

    // GET /api/coaches/sessions/requests  (coach only)
    [HttpGet("sessions/requests")]
    [RequireApprovedRole(UserType.Coach)]
    public async Task<IActionResult> GetSessionRequests(
        [FromQuery] int page = 1, [FromQuery] int pageSize = 10)
    {
        try
        {
            var requests = await _coachService.GetSessionRequestsAsync(
                CurrentUserId, page, pageSize);
            return Ok(ApiResponse<PagedResult<CoachSessionDto>>.Ok(requests));
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

    // GET /api/coaches/bookings  (coach only — all bookings, status filter)
    [HttpGet("bookings")]
    [RequireApprovedRole(UserType.Coach)]
    public async Task<IActionResult> GetCoachBookings(
        [FromQuery] int page = 1, [FromQuery] int pageSize = 10,
        [FromQuery] string? status = null)
    {
        try
        {
            var bookings = await _coachService.GetCoachBookingsAsync(
                CurrentUserId, page, pageSize, status);
            return Ok(ApiResponse<PagedResult<CoachSessionDto>>.Ok(bookings));
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

    // GET /api/coaches/me  (coach only — own profile for editing)
    [HttpGet("me")]
    [RequireApprovedRole(UserType.Coach)]
    public async Task<IActionResult> GetMyCoachProfile()
    {
        try
        {
            var coach = await _coachService.GetMyCoachProfileAsync(CurrentUserId);
            return Ok(ApiResponse<CoachDto>.Ok(coach));
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

    // PUT /api/coaches/me  (coach only — update own profile)
    [HttpPut("me")]
    [RequireApprovedRole(UserType.Coach)]
    public async Task<IActionResult> UpdateMyCoachProfile(
        [FromBody] UpdateCoachProfileRequest request)
    {
        try
        {
            var coach = await _coachService.UpdateMyCoachProfileAsync(CurrentUserId, request);
            return Ok(ApiResponse<CoachDto>.Ok(coach));
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

    // POST /api/coaches/id-document  (multipart, coach only)
    // صورة الهوية/الإقامة المطلوبة عند إنشاء حساب المدرب — تُعرض للأدمن في لوحة التحكم.
    [HttpPost("id-document")]
    [RequireApprovedRole(UserType.Coach)]
    public async Task<IActionResult> UploadIdDocument(IFormFile? file)
    {
        try
        {
            if (file == null || file.Length == 0)
                return BadRequest(ApiResponse<object>.Fail(
                    "No file uploaded", "لم يتم رفع أي ملف", "NO_FILE"));

            var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
            var allowed = new[] { ".jpg", ".jpeg", ".png", ".webp" };
            if (!allowed.Contains(ext))
                return BadRequest(ApiResponse<object>.Fail(
                    "Unsupported file type", "نوع ملف غير مدعوم", "BAD_FILE_TYPE"));

            if (file.Length > 5 * 1024 * 1024)
                return BadRequest(ApiResponse<object>.Fail(
                    "File too large (max 5MB)", "حجم الملف كبير (الحد 5 ميجا)", "FILE_TOO_LARGE"));

            var root = _env.WebRootPath
                ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
            var dir = Path.Combine(root, "uploads", "id-documents");
            Directory.CreateDirectory(dir);

            var fileName = $"{CurrentUserId}_{Guid.NewGuid():N}{ext}";
            await using (var stream = System.IO.File.Create(Path.Combine(dir, fileName)))
            {
                await file.CopyToAsync(stream);
            }

            var coach = await _coachService.UpdateIdDocumentAsync(
                CurrentUserId, $"/uploads/id-documents/{fileName}");
            return Ok(ApiResponse<CoachDto>.Ok(coach));
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

    // GET /api/coaches/students?page=&pageSize=  (coach only)
    [HttpGet("students")]
    [RequireApprovedRole(UserType.Coach)]
    public async Task<IActionResult> GetStudents(
        [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        try
        {
            var students = await _coachService.GetStudentsAsync(CurrentUserId, page, pageSize);
            return Ok(ApiResponse<PagedResult<CoachStudentDto>>.Ok(students));
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

    // GET /api/coaches/revenue?type=month|week&offset=N  (coach only)
    [HttpGet("revenue")]
    [RequireApprovedRole(UserType.Coach)]
    public async Task<IActionResult> GetRevenue(
        [FromQuery] string type = "month", [FromQuery] int offset = 0)
    {
        try
        {
            var report = await _coachService.GetRevenueReportAsync(CurrentUserId, type, offset);
            return Ok(ApiResponse<CoachRevenueReportDto>.Ok(report));
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

    // GET /api/coaches/offers  (coach only — all own offers, for management)
    [HttpGet("offers")]
    [RequireApprovedRole(UserType.Coach)]
    public async Task<IActionResult> GetMyOffers()
    {
        try
        {
            var offers = await _coachService.GetMyOffersAsync(CurrentUserId);
            return Ok(ApiResponse<List<CoachOfferDto>>.Ok(offers));
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

    // POST /api/coaches/offers  (coach only — create a new offer/discount)
    [HttpPost("offers")]
    [RequireApprovedRole(UserType.Coach)]
    public async Task<IActionResult> CreateOffer([FromBody] CreateCoachOfferRequest request)
    {
        try
        {
            var offer = await _coachService.CreateOfferAsync(CurrentUserId, request);
            return Ok(ApiResponse<CoachOfferDto>.Ok(offer));
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

    // POST /api/coaches/offers/{id}/active  { isActive }  (coach only)
    [HttpPost("offers/{id:int}/active")]
    [RequireApprovedRole(UserType.Coach)]
    public async Task<IActionResult> SetOfferActive(
        int id, [FromBody] SetCoachOfferActiveRequest request)
    {
        try
        {
            var offer = await _coachService.SetOfferActiveAsync(CurrentUserId, id, request.IsActive);
            return Ok(ApiResponse<CoachOfferDto>.Ok(offer));
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

    // DELETE /api/coaches/offers/{id}  (coach only)
    [HttpDelete("offers/{id:int}")]
    [RequireApprovedRole(UserType.Coach)]
    public async Task<IActionResult> DeleteOffer(int id)
    {
        try
        {
            await _coachService.DeleteOfferAsync(CurrentUserId, id);
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

    // POST /api/coaches/sessions/{id}/respond  { approve }  (coach only)
    [HttpPost("sessions/{id:int}/respond")]
    [RequireApprovedRole(UserType.Coach)]
    public async Task<IActionResult> RespondToSession(
        int id, [FromBody] SessionRespondRequest request)
    {
        try
        {
            var session = await _coachService.RespondToSessionAsync(
                CurrentUserId, id, request.Approve);
            return Ok(ApiResponse<CoachSessionDto>.Ok(session));
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
