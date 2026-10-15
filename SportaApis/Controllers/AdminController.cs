using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SportaApis.Attributes;
using SportaApis.DTOs;
using SportaApis.Enums;
using SportaApis.Helpers;
using SportaApis.Services;

namespace SportaApis.Controllers;

[ApiController]
[Route("api/admin")]
[Authorize(Roles = "admin,staff")]
public class AdminController : ControllerBase
{
    private readonly IAdminService _admin;
    private readonly IAdService _ads;
    private readonly ISportService _sports;
    private readonly IPackageService _packages;
    private readonly IWalletService _wallet;
    private readonly ILocationService _locations;
    private readonly ICourtService _courts;
    private readonly ISettingsService _settings;
    private readonly IPointsService _points;
    private readonly ILevelDefinitionService _levels;
    private readonly IVenueService _venues;
    private readonly ICoachSpecializationService _coachSpecializations;
    private readonly IMatchService _matches;

    public AdminController(IAdminService admin, IAdService ads, ISportService sports, IPackageService packages, IWalletService wallet, ILocationService locations, ICourtService courts, ISettingsService settings, IPointsService points, IVenueService venues, ICoachSpecializationService coachSpecializations, IMatchService matches, ILevelDefinitionService levels)
    {
        _admin = admin;
        _ads = ads;
        _sports = sports;
        _packages = packages;
        _wallet = wallet;
        _locations = locations;
        _courts = courts;
        _settings = settings;
        _points = points;
        _levels = levels;
        _venues = venues;
        _coachSpecializations = coachSpecializations;
        _matches = matches;
    }

    // ── Matches ──────────────────────────────────────────────────────────────

    // DELETE /api/admin/matches/{id}
    [HttpDelete("matches/{id:int}")]
    [RequirePermission(Permissions.MatchesDelete)]
    public async Task<IActionResult> DeleteMatch(int id)
    {
        try
        {
            await _matches.DeleteAsync(id, "حُذفت المباراة من إدارة المنصة");
            return Ok(ApiResponse<object>.Ok(new { deleted = true }));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    // POST /api/admin/matches/run-autocancel — تشغيل فحص الإلغاء التلقائي فوراً
    // بدل انتظار نبضة العامل الخلفي (للتحقق بعد تغيير المهلة).
    [HttpPost("matches/run-autocancel")]
    [RequirePermission(Permissions.MatchesDelete)]
    // يقبل hours لتجربة مهلة أخرى دون تغيير الإعداد المحفوظ (ضمن 0..72).
    public async Task<IActionResult> RunAutoCancel([FromQuery] double? hours = null)
    {
        var configured = await _settings.GetAutoCancelHoursAsync();
        var lead = hours is >= 0 and <= 72 ? hours.Value : configured;
        var count = await _matches.CancelIncompleteBeforeStartAsync(
            TimeSpan.FromHours(lead));
        return Ok(ApiResponse<object>.Ok(new { cancelled = count, hours = lead, configured }));
    }

    // ── Venues (owner onboarding review) ─────────────────────────────────────
    // GET /api/admin/venues?search=&page=&pageSize=
    [HttpGet("venues")]
    [RequirePermission(Permissions.VenuesView)]
    public async Task<IActionResult> GetVenues(
        [FromQuery] string? search, [FromQuery] int page = 1, [FromQuery] int pageSize = 15)
    {
        var venues = await _venues.GetAllVenuesAsync(search, page, pageSize);
        return Ok(ApiResponse<PagedResult<AdminVenueDto>>.Ok(venues));
    }

    // GET /api/admin/venues/{id}
    [HttpGet("venues/{id:int}")]
    [RequirePermission(Permissions.VenuesView)]
    public async Task<IActionResult> GetVenue(int id)
    {
        var venue = await _venues.GetVenueByIdAsync(id);
        return venue is null
            ? NotFound(ApiResponse<object>.Fail(
                "Venue not found", "الملعب غير موجود", "VENUE_NOT_FOUND"))
            : Ok(ApiResponse<AdminVenueDto>.Ok(venue));
    }

    // PUT /api/admin/venues/{id}/approve  — الموافقة على الملعب مع إشعار المالك
    [HttpPut("venues/{id:int}/approve")]
    [RequirePermission(Permissions.VenuesApprove)]
    public async Task<IActionResult> SetVenueApproved(
        int id, [FromBody] UpdateVenueApprovedRequest request)
    {
        try
        {
            await _admin.SetVenueApprovedAsync(id, request.Approved);
            return Ok(ApiResponse<object>.Ok(new { approved = request.Approved }));
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

    // DELETE /api/admin/venues/{id}  — حذف النادي وكل ملاعبه
    // حذف ناعم: يختفي النادي وملاعبه من اللوحة والتطبيق ولوحة المالك، وتُلغى
    // الحجوزات القادمة مع ردّ ما دُفع، بينما تبقى الحجوزات السابقة في السجل.
    [HttpDelete("venues/{id:int}")]
    [RequirePermission(Permissions.VenuesDelete)]
    public async Task<IActionResult> DeleteVenue(int id)
    {
        try
        {
            await _admin.DeleteVenueAsync(id);
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

    // GET /api/admin/stats  — أرقام لوحة التحكم
    [HttpGet("stats")]
    [RequirePermission(Permissions.DashboardView)]
    public async Task<IActionResult> Stats()
    {
        var stats = await _admin.GetStatsAsync();
        return Ok(ApiResponse<AdminStatsDto>.Ok(stats));
    }

    // GET /api/admin/users?role=&search=&page=&pageSize=
    [HttpGet("users")]
    [RequirePermission(Permissions.UsersView)]
    public async Task<IActionResult> Users(
        [FromQuery] string? role, [FromQuery] string? search,
        [FromQuery] int page = 1, [FromQuery] int pageSize = 15)
    {
        var users = await _admin.GetUsersAsync(role, search, page, pageSize);
        return Ok(ApiResponse<PagedResult<AdminUserDto>>.Ok(users));
    }

    // GET /api/admin/users/{id}
    [HttpGet("users/{id:int}")]
    [RequirePermission(Permissions.UsersView)]
    public async Task<IActionResult> User(int id)
    {
        var user = await _admin.GetUserAsync(id);
        return user is null
            ? NotFound(ApiResponse<object>.Fail(
                "User not found", "المستخدم غير موجود", "USER_NOT_FOUND"))
            : Ok(ApiResponse<AdminUserDetailDto>.Ok(user));
    }

    // GET /api/admin/notifications?page=&pageSize=
    [HttpGet("notifications")]
    [RequirePermission(Permissions.NotificationsView)]
    public async Task<IActionResult> Notifications(
        [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var items = await _admin.GetNotificationsAsync(page, pageSize);
        return Ok(ApiResponse<PagedResult<AdminNotificationDto>>.Ok(items));
    }

    // ── Ads (announcements) management ──────────────────────────────────────────
    // GET /api/admin/ads
    [HttpGet("ads")]
    [RequirePermission(Permissions.AdsView)]
    public async Task<IActionResult> GetAds()
    {
        var items = await _ads.GetAllAsync();
        return Ok(ApiResponse<List<AdDto>>.Ok(items));
    }

    // POST /api/admin/ads
    [HttpPost("ads")]
    [RequirePermission(Permissions.AdsManage)]
    public async Task<IActionResult> CreateAd([FromBody] SaveAdRequest request)
    {
        var dto = await _ads.CreateAsync(request);
        return Ok(ApiResponse<AdDto>.Ok(dto));
    }

    // PUT /api/admin/ads/{id}
    [HttpPut("ads/{id:int}")]
    [RequirePermission(Permissions.AdsManage)]
    public async Task<IActionResult> UpdateAd(int id, [FromBody] SaveAdRequest request)
    {
        try
        {
            var dto = await _ads.UpdateAsync(id, request);
            return Ok(ApiResponse<AdDto>.Ok(dto));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    // DELETE /api/admin/ads/{id}
    [HttpDelete("ads/{id:int}")]
    [RequirePermission(Permissions.AdsManage)]
    public async Task<IActionResult> DeleteAd(int id)
    {
        try
        {
            await _ads.DeleteAsync(id);
            return Ok(ApiResponse<object>.Ok(new { deleted = true }));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    // ── Sports management ────────────────────────────────────────────────────
    // GET /api/admin/sports
    [HttpGet("sports")]
    [RequirePermission(Permissions.SportsView)]
    public async Task<IActionResult> GetSports()
    {
        var items = await _sports.GetAllAsync();
        return Ok(ApiResponse<List<SportDto>>.Ok(items));
    }

    // POST /api/admin/sports
    [HttpPost("sports")]
    [RequirePermission(Permissions.SportsManage)]
    public async Task<IActionResult> CreateSport([FromBody] SaveSportRequest request)
    {
        var dto = await _sports.CreateAsync(request);
        return Ok(ApiResponse<SportDto>.Ok(dto));
    }

    // PUT /api/admin/sports/{id}
    [HttpPut("sports/{id:int}")]
    [RequirePermission(Permissions.SportsManage)]
    public async Task<IActionResult> UpdateSport(int id, [FromBody] SaveSportRequest request)
    {
        try
        {
            var dto = await _sports.UpdateAsync(id, request);
            return Ok(ApiResponse<SportDto>.Ok(dto));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    // DELETE /api/admin/sports/{id}
    [HttpDelete("sports/{id:int}")]
    [RequirePermission(Permissions.SportsManage)]
    public async Task<IActionResult> DeleteSport(int id)
    {
        try
        {
            await _sports.DeleteAsync(id);
            return Ok(ApiResponse<object>.Ok(new { deleted = true }));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    // ── Sport settings (title + items per sport) ─────────────────────────────
    // GET /api/admin/sports/{sportId}/settings
    [HttpGet("sports/{sportId:int}/settings")]
    [RequirePermission(Permissions.SportsView)]
    public async Task<IActionResult> GetSportSettings(int sportId)
    {
        var items = await _sports.GetSettingsAsync(sportId);
        return Ok(ApiResponse<List<SportSettingDto>>.Ok(items));
    }

    // POST /api/admin/sports/{sportId}/settings
    [HttpPost("sports/{sportId:int}/settings")]
    [RequirePermission(Permissions.SportsManage)]
    public async Task<IActionResult> CreateSportSetting(int sportId, [FromBody] SaveSportSettingRequest request)
    {
        try
        {
            var dto = await _sports.CreateSettingAsync(sportId, request);
            return Ok(ApiResponse<SportSettingDto>.Ok(dto));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    // PUT /api/admin/sports/settings/{id}
    [HttpPut("sports/settings/{id:int}")]
    [RequirePermission(Permissions.SportsManage)]
    public async Task<IActionResult> UpdateSportSetting(int id, [FromBody] SaveSportSettingRequest request)
    {
        try
        {
            var dto = await _sports.UpdateSettingAsync(id, request);
            return Ok(ApiResponse<SportSettingDto>.Ok(dto));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    // DELETE /api/admin/sports/settings/{id}
    [HttpDelete("sports/settings/{id:int}")]
    [RequirePermission(Permissions.SportsManage)]
    public async Task<IActionResult> DeleteSportSetting(int id)
    {
        try
        {
            await _sports.DeleteSettingAsync(id);
            return Ok(ApiResponse<object>.Ok(new { deleted = true }));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    // ── Coach specializations management ─────────────────────────────────────
    // ── سُلَّم المستويات (المستويات والنقاط) ──────────────────────────────────
    // GET /api/admin/level-definitions
    [HttpGet("level-definitions")]
    [RequirePermission(Permissions.PointsSystemView)]
    public async Task<IActionResult> GetLevelDefinitions()
    {
        var items = await _levels.GetAllAsync();
        return Ok(ApiResponse<List<PlayerLevelDefinitionDto>>.Ok(items));
    }

    // POST /api/admin/level-definitions
    [HttpPost("level-definitions")]
    [RequirePermission(Permissions.PointsSystemManage)]
    public async Task<IActionResult> CreateLevelDefinition(
        [FromBody] SavePlayerLevelDefinitionRequest request)
    {
        try
        {
            var dto = await _levels.CreateAsync(request);
            return Ok(ApiResponse<PlayerLevelDefinitionDto>.Ok(dto));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    // PUT /api/admin/level-definitions/{id}
    [HttpPut("level-definitions/{id:int}")]
    [RequirePermission(Permissions.PointsSystemManage)]
    public async Task<IActionResult> UpdateLevelDefinition(
        int id, [FromBody] SavePlayerLevelDefinitionRequest request)
    {
        try
        {
            var dto = await _levels.UpdateAsync(id, request);
            return Ok(ApiResponse<PlayerLevelDefinitionDto>.Ok(dto));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    // DELETE /api/admin/level-definitions/{id}
    [HttpDelete("level-definitions/{id:int}")]
    [RequirePermission(Permissions.PointsSystemManage)]
    public async Task<IActionResult> DeleteLevelDefinition(int id)
    {
        try
        {
            await _levels.DeleteAsync(id);
            return Ok(ApiResponse<object>.Ok(new { deleted = true }));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    // GET /api/admin/coach-specializations
    [HttpGet("coach-specializations")]
    [RequirePermission(Permissions.CoachSpecializationsView)]
    public async Task<IActionResult> GetCoachSpecializations()
    {
        var items = await _coachSpecializations.GetAllAsync();
        return Ok(ApiResponse<List<CoachSpecializationDto>>.Ok(items));
    }

    // POST /api/admin/coach-specializations
    [HttpPost("coach-specializations")]
    [RequirePermission(Permissions.CoachSpecializationsManage)]
    public async Task<IActionResult> CreateCoachSpecialization(
        [FromBody] SaveCoachSpecializationRequest request)
    {
        var dto = await _coachSpecializations.CreateAsync(request);
        return Ok(ApiResponse<CoachSpecializationDto>.Ok(dto));
    }

    // PUT /api/admin/coach-specializations/{id}
    [HttpPut("coach-specializations/{id:int}")]
    [RequirePermission(Permissions.CoachSpecializationsManage)]
    public async Task<IActionResult> UpdateCoachSpecialization(
        int id, [FromBody] SaveCoachSpecializationRequest request)
    {
        try
        {
            var dto = await _coachSpecializations.UpdateAsync(id, request);
            return Ok(ApiResponse<CoachSpecializationDto>.Ok(dto));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    // DELETE /api/admin/coach-specializations/{id}
    [HttpDelete("coach-specializations/{id:int}")]
    [RequirePermission(Permissions.CoachSpecializationsManage)]
    public async Task<IActionResult> DeleteCoachSpecialization(int id)
    {
        try
        {
            await _coachSpecializations.DeleteAsync(id);
            return Ok(ApiResponse<object>.Ok(new { deleted = true }));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    // ── Packages management ──────────────────────────────────────────────────
    // GET /api/admin/packages
    [HttpGet("packages")]
    [RequirePermission(Permissions.PackagesView)]
    public async Task<IActionResult> GetPackages()
    {
        var items = await _packages.GetAllAsync();
        return Ok(ApiResponse<List<PackageDto>>.Ok(items));
    }

    // POST /api/admin/packages
    [HttpPost("packages")]
    [RequirePermission(Permissions.PackagesManage)]
    public async Task<IActionResult> CreatePackage([FromBody] SavePackageRequest request)
    {
        var dto = await _packages.CreateAsync(request);
        return Ok(ApiResponse<PackageDto>.Ok(dto));
    }

    // PUT /api/admin/packages/{id}
    [HttpPut("packages/{id:int}")]
    [RequirePermission(Permissions.PackagesManage)]
    public async Task<IActionResult> UpdatePackage(int id, [FromBody] SavePackageRequest request)
    {
        try
        {
            var dto = await _packages.UpdateAsync(id, request);
            return Ok(ApiResponse<PackageDto>.Ok(dto));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    // DELETE /api/admin/packages/{id}
    [HttpDelete("packages/{id:int}")]
    [RequirePermission(Permissions.PackagesManage)]
    public async Task<IActionResult> DeletePackage(int id)
    {
        try
        {
            await _packages.DeleteAsync(id);
            return Ok(ApiResponse<object>.Ok(new { deleted = true }));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    // GET /api/admin/bookings?status=&page=&pageSize=  — all bookings/invoices platform-wide
    [HttpGet("bookings")]
    [RequirePermission(Permissions.BookingsView)]
    public async Task<IActionResult> GetBookings(
        [FromQuery] string? status, [FromQuery] int page = 1, [FromQuery] int pageSize = 15)
    {
        var items = await _admin.GetBookingsAsync(status, page, pageSize);
        return Ok(ApiResponse<PagedResult<AdminBookingDto>>.Ok(items));
    }

    // GET /api/admin/bookings/{id}
    [HttpGet("bookings/{id:int}")]
    [RequirePermission(Permissions.BookingsView)]
    public async Task<IActionResult> GetBooking(int id)
    {
        var booking = await _admin.GetBookingAsync(id);
        return booking is null
            ? NotFound(ApiResponse<object>.Fail(
                "Booking not found", "الحجز غير موجود", "BOOKING_NOT_FOUND"))
            : Ok(ApiResponse<AdminBookingDto>.Ok(booking));
    }

    // ── Finance ──────────────────────────────────────────────────────────────

    // GET /api/admin/finance/stats  — ملخص مالي شامل (وارد/صادر/أرصدة)
    [HttpGet("finance/stats")]
    [RequirePermission(Permissions.FinanceView)]
    public async Task<IActionResult> FinanceStats()
    {
        var stats = await _admin.GetFinanceStatsAsync();
        return Ok(ApiResponse<FinanceStatsDto>.Ok(stats));
    }

    // GET /api/admin/transactions?type=&status=&search=&page=&pageSize=  — كل تعاملات المحفظة
    [HttpGet("transactions")]
    [RequirePermission(Permissions.FinanceView)]
    public async Task<IActionResult> GetTransactions(
        [FromQuery] string? type, [FromQuery] string? search,
        [FromQuery] int page = 1, [FromQuery] int pageSize = 20,
        [FromQuery] string? status = null)
    {
        var items = await _admin.GetTransactionsAsync(type, search, page, pageSize, status);
        return Ok(ApiResponse<PagedResult<AdminTransactionDto>>.Ok(items));
    }

    // GET /api/admin/transactions/{id}
    [HttpGet("transactions/{id:int}")]
    [RequirePermission(Permissions.FinanceView)]
    public async Task<IActionResult> GetTransaction(int id)
    {
        var tx = await _admin.GetTransactionAsync(id);
        return tx is null
            ? NotFound(ApiResponse<object>.Fail(
                "Transaction not found", "المعاملة غير موجودة", "TRANSACTION_NOT_FOUND"))
            : Ok(ApiResponse<AdminTransactionDto>.Ok(tx));
    }

    // GET /api/admin/withdrawals?status=&page=&pageSize=  — طلبات سحب الرصيد
    [HttpGet("withdrawals")]
    [RequirePermission(Permissions.FinanceView)]
    public async Task<IActionResult> GetWithdrawals(
        [FromQuery] string? status, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var items = await _wallet.GetWithdrawalRequestsAsync(page, pageSize, status);
        return Ok(ApiResponse<PagedResult<WithdrawalRequestDto>>.Ok(items));
    }

    // PATCH /api/admin/withdrawals/{id}  — قبول/رفض طلب سحب
    [HttpPatch("withdrawals/{id:int}")]
    [RequirePermission(Permissions.FinanceWithdrawalsManage)]
    public async Task<IActionResult> ProcessWithdrawal(
        int id, [FromBody] ProcessWithdrawalRequest request)
    {
        try
        {
            var result = await _wallet.ProcessWithdrawalAsync(id, request);
            return Ok(ApiResponse<WithdrawalRequestDto>.Ok(result));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    // ── Countries / Cities / Districts ─────────────────────────────────────────

    // GET /api/admin/countries  — كل الدول (نشطة وغير نشطة)
    [HttpGet("countries")]
    [RequirePermission(Permissions.LocationsView)]
    public async Task<IActionResult> GetCountries()
    {
        var items = await _locations.GetCountriesAsync(activeOnly: false);
        return Ok(ApiResponse<List<CountryDto>>.Ok(items));
    }

    [HttpPost("countries")]
    [RequirePermission(Permissions.LocationsManage)]
    public async Task<IActionResult> CreateCountry([FromBody] SaveCountryRequest request)
    {
        try
        {
            var country = await _locations.CreateCountryAsync(request);
            return Ok(ApiResponse<CountryDto>.Ok(country));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    [HttpPut("countries/{id:int}")]
    [RequirePermission(Permissions.LocationsManage)]
    public async Task<IActionResult> UpdateCountry(int id, [FromBody] SaveCountryRequest request)
    {
        try
        {
            var country = await _locations.UpdateCountryAsync(id, request);
            return Ok(ApiResponse<CountryDto>.Ok(country));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    [HttpDelete("countries/{id:int}")]
    [RequirePermission(Permissions.LocationsManage)]
    public async Task<IActionResult> DeleteCountry(int id)
    {
        try
        {
            await _locations.DeleteCountryAsync(id);
            return Ok(ApiResponse<object>.Ok(new { deleted = true }));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    // GET /api/admin/cities?countryId=  — كل المدن (نشطة وغير نشطة)
    [HttpGet("cities")]
    [RequirePermission(Permissions.LocationsView)]
    public async Task<IActionResult> GetCities([FromQuery] int? countryId)
    {
        var items = await _locations.GetCitiesAsync(activeOnly: false, countryId: countryId);
        return Ok(ApiResponse<List<CityDto>>.Ok(items));
    }

    [HttpPost("cities")]
    [RequirePermission(Permissions.LocationsManage)]
    public async Task<IActionResult> CreateCity([FromBody] SaveCityRequest request)
    {
        var city = await _locations.CreateCityAsync(request);
        return Ok(ApiResponse<CityDto>.Ok(city));
    }

    [HttpPut("cities/{id:int}")]
    [RequirePermission(Permissions.LocationsManage)]
    public async Task<IActionResult> UpdateCity(int id, [FromBody] SaveCityRequest request)
    {
        try
        {
            var city = await _locations.UpdateCityAsync(id, request);
            return Ok(ApiResponse<CityDto>.Ok(city));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    [HttpDelete("cities/{id:int}")]
    [RequirePermission(Permissions.LocationsManage)]
    public async Task<IActionResult> DeleteCity(int id)
    {
        try
        {
            await _locations.DeleteCityAsync(id);
            return Ok(ApiResponse<object>.Ok(new { deleted = true }));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    // GET /api/admin/cities/{cityId}/districts
    [HttpGet("cities/{cityId:int}/districts")]
    [RequirePermission(Permissions.LocationsView)]
    public async Task<IActionResult> GetDistricts(int cityId)
    {
        var items = await _locations.GetDistrictsAsync(cityId, activeOnly: false);
        return Ok(ApiResponse<List<DistrictDto>>.Ok(items));
    }

    [HttpPost("districts")]
    [RequirePermission(Permissions.LocationsManage)]
    public async Task<IActionResult> CreateDistrict([FromBody] SaveDistrictRequest request)
    {
        try
        {
            var district = await _locations.CreateDistrictAsync(request);
            return Ok(ApiResponse<DistrictDto>.Ok(district));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    [HttpPut("districts/{id:int}")]
    [RequirePermission(Permissions.LocationsManage)]
    public async Task<IActionResult> UpdateDistrict(int id, [FromBody] SaveDistrictRequest request)
    {
        try
        {
            var district = await _locations.UpdateDistrictAsync(id, request);
            return Ok(ApiResponse<DistrictDto>.Ok(district));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    [HttpDelete("districts/{id:int}")]
    [RequirePermission(Permissions.LocationsManage)]
    public async Task<IActionResult> DeleteDistrict(int id)
    {
        try
        {
            await _locations.DeleteDistrictAsync(id);
            return Ok(ApiResponse<object>.Ok(new { deleted = true }));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    // GET /api/admin/notifications/unread-count
    [HttpGet("notifications/unread-count")]
    [RequirePermission(Permissions.NotificationsView)]
    public async Task<IActionResult> UnreadNotificationsCount()
    {
        var count = await _admin.GetUnreadNotificationsCountAsync();
        return Ok(ApiResponse<object>.Ok(new { count }));
    }

    // POST /api/admin/notifications/broadcast  — إشعار للجميع
    [HttpPost("notifications/broadcast")]
    [RequirePermission(Permissions.NotificationsSend)]
    public async Task<IActionResult> Broadcast([FromBody] AdminBroadcastRequest request)
    {
        try
        {
            await _admin.BroadcastAsync(request.Title, request.Body);
            return Ok(ApiResponse<object>.Ok(new { sent = true }));
        }
        catch (Exception)
        {
            return StatusCode(500, ApiResponse<object>.Fail(
                "An unexpected error occurred", "حدث خطأ غير متوقع", "UNEXPECTED"));
        }
    }

    // POST /api/admin/notifications/delete  — حذف إشعارات محددة (والبث من الجميع اختيارياً)
    [HttpPost("notifications/delete")]
    [RequirePermission(Permissions.NotificationsDelete)]
    public async Task<IActionResult> DeleteNotifications(
        [FromBody] AdminDeleteNotificationsRequest request)
    {
        try
        {
            var deleted = await _admin.DeleteNotificationsAsync(request.Ids, request.WholeBroadcast);
            return Ok(ApiResponse<object>.Ok(new { deleted }));
        }
        catch (Exception)
        {
            return StatusCode(500, ApiResponse<object>.Fail(
                "An unexpected error occurred", "حدث خطأ غير متوقع", "UNEXPECTED"));
        }
    }

    // POST /api/admin/notifications/send  — إشعار لمستخدم محدد
    [HttpPost("notifications/send")]
    [RequirePermission(Permissions.NotificationsSend)]
    public async Task<IActionResult> SendToUser(
        [FromBody] AdminSendNotificationRequest request)
    {
        try
        {
            await _admin.SendToUserAsync(request.UserId, request.Title, request.Body);
            return Ok(ApiResponse<object>.Ok(new { sent = true }));
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

    // GET /api/admin/courts  — كل الملاعب (بما فيها الموقوفة) للوحة التحكم
    [HttpGet("courts")]
    [RequirePermission(Permissions.CourtsView)]
    public async Task<IActionResult> Courts()
    {
        var courts = await _courts.GetAllForAdminAsync();
        return Ok(ApiResponse<List<CourtDto>>.Ok(courts));
    }

    // GET /api/admin/courts/{id} — تفاصيل ملعب للوحة، حتى لو لم يُعتمد ناديه بعد.
    // المسار العام /api/courts/{id} يشترط الاعتماد، فلوحة التحكم كانت تسرد ملاعب
    // لا تستطيع فتحها (404). هذا المسار يوائم القائمة مع التفاصيل.
    [HttpGet("courts/{id:int}")]
    [RequirePermission(Permissions.CourtsView)]
    public async Task<IActionResult> GetCourt(int id)
    {
        try
        {
            var court = await _courts.GetCourtByIdAsync(id, requireApproved: false);
            return Ok(ApiResponse<CourtDto>.Ok(court));
        }
        catch (AuthException ex)
        {
            return NotFound(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    // GET /api/admin/courts/{id}/availability?date=&durationMinutes=
    [HttpGet("courts/{id:int}/availability")]
    [RequirePermission(Permissions.CourtsView)]
    public async Task<IActionResult> GetCourtAvailability(
        int id, [FromQuery] DateTime? date, [FromQuery] int durationMinutes = 60)
    {
        try
        {
            var availability = await _courts.GetAvailabilityAsync(
                id, date ?? DateTime.UtcNow.Date, durationMinutes, requireApproved: false);
            return Ok(ApiResponse<CourtAvailabilityDto>.Ok(availability));
        }
        catch (AuthException ex)
        {
            return NotFound(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    // PUT /api/admin/courts/{id}/suspend  — إيقاف/تفعيل الملعب مع إشعار المالك
    [HttpPut("courts/{id:int}/suspend")]
    [RequirePermission(Permissions.CourtsSuspend)]
    public async Task<IActionResult> SetCourtSuspended(
        int id, [FromBody] UpdateCourtSuspendedRequest request)
    {
        try
        {
            await _admin.SetCourtSuspendedAsync(id, request.Suspended);
            return Ok(ApiResponse<object>.Ok(new { suspended = request.Suspended }));
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

    // PUT /api/admin/courts/{id}/commission  — نسبة سبورتا للملعب
    [HttpPut("courts/{id:int}/commission")]
    [RequirePermission(Permissions.CourtsCommission)]
    public async Task<IActionResult> SetCourtCommission(
        int id, [FromBody] UpdateCourtCommissionRequest request)
    {
        try
        {
            await _admin.SetCourtCommissionAsync(id, request.Percent);
            return Ok(ApiResponse<object>.Ok(new { percent = request.Percent }));
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

    // DELETE /api/admin/courts/{id}  — حذف الملعب (حذف ناعم، انظر حذف النادي)
    [HttpDelete("courts/{id:int}")]
    [RequirePermission(Permissions.CourtsDelete)]
    public async Task<IActionResult> DeleteCourt(int id)
    {
        try
        {
            await _admin.DeleteCourtAsync(id);
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

    // GET /api/admin/settings/default-commission  — نسبة سبورتا الافتراضية للملاعب الجديدة
    [HttpGet("settings/default-commission")]
    [RequirePermission(Permissions.FinanceView)]
    public async Task<IActionResult> GetDefaultCommission()
    {
        var percent = await _settings.GetDefaultCommissionAsync();
        return Ok(ApiResponse<object>.Ok(new { percent }));
    }

    // PUT /api/admin/settings/default-commission  { percent }
    [HttpPut("settings/default-commission")]
    [RequirePermission(Permissions.FinanceCommissionManage)]
    public async Task<IActionResult> SetDefaultCommission(
        [FromBody] UpdateCourtCommissionRequest request)
    {
        await _settings.SetDefaultCommissionAsync(request.Percent);
        return Ok(ApiResponse<object>.Ok(new { percent = request.Percent }));
    }

    // ── نقاط الولاء ──────────────────────────────────────────────────────────

    // GET /api/admin/users/{id}/points?page=&pageSize=  — رصيد وسجل نقاط مستخدم
    [HttpGet("users/{id:int}/points")]
    [RequirePermission(Permissions.UsersView)]
    public async Task<IActionResult> UserPoints(
        int id, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var summary = await _points.GetSummaryAsync(id, page, pageSize);
        return Ok(ApiResponse<PointsSummaryDto>.Ok(summary));
    }

    // POST /api/admin/users/{id}/points/adjust  — منح/خصم يدوي
    [HttpPost("users/{id:int}/points/adjust")]
    [RequirePermission(Permissions.UsersPointsAdjust)]
    public async Task<IActionResult> AdjustPoints(
        int id, [FromBody] AdminAdjustPointsRequest request)
    {
        try
        {
            var balance = await _points.AdminAdjustAsync(id, request.Amount, request.Reason);
            return Ok(ApiResponse<object>.Ok(new { balance }));
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

    // GET /api/admin/points/stats  — إجماليات النقاط
    [HttpGet("points/stats")]
    [RequirePermission(Permissions.UsersView)]
    public async Task<IActionResult> PointsStats()
    {
        var stats = await _points.GetStatsAsync();
        return Ok(ApiResponse<PointsStatsDto>.Ok(stats));
    }

    // POST /api/admin/users/{id}/approve-role  { role, approved }
    // تفعيل حساب المدرب/صاحب الملعب بعد مراجعة بياناته.
    [HttpPost("users/{id:int}/approve-role")]
    [RequirePermission(Permissions.UsersLock)]
    public async Task<IActionResult> ApproveRole(
        int id, [FromBody] ApproveUserRoleRequest request)
    {
        var role = request.Role?.ToLowerInvariant() switch
        {
            "coach" => (UserType?)UserType.Coach,
            "venue" or "venueowner" => UserType.VenueOwner,
            _ => null,
        };

        if (role is not UserType roleType)
            return BadRequest(ApiResponse<object>.Fail(
                "Invalid role", "الدور غير صحيح", "INVALID_ROLE"));

        try
        {
            await _admin.SetRoleApprovedAsync(id, roleType, request.Approved);
            return Ok(ApiResponse<object>.Ok(
                new { role = request.Role, approved = request.Approved }));
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

    // PUT /api/admin/users/{id}/level  { level }  — تعديل مستوى لاعب يدوياً
    [HttpPut("users/{id:int}/level")]
    [RequirePermission(Permissions.UsersLevelEdit)]
    public async Task<IActionResult> SetPlayerLevel(
        int id, [FromBody] SetPlayerLevelRequest request)
    {
        try
        {
            var level = await _admin.SetPlayerLevelAsync(id, request.Level);
            return Ok(ApiResponse<object>.Ok(new { level }));
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

    // POST /api/admin/users/{id}/lock  — قفل الحساب
    [HttpPost("users/{id:int}/lock")]
    [RequirePermission(Permissions.UsersLock)]
    public async Task<IActionResult> Lock(int id)
    {
        try
        {
            await _admin.SetLockedAsync(id, true);
            return Ok(ApiResponse<object>.Ok(new { locked = true }));
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

    // POST /api/admin/users/{id}/unlock  — تفعيل الحساب
    [HttpPost("users/{id:int}/unlock")]
    [RequirePermission(Permissions.UsersLock)]
    public async Task<IActionResult> Unlock(int id)
    {
        try
        {
            await _admin.SetLockedAsync(id, false);
            return Ok(ApiResponse<object>.Ok(new { locked = false }));
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

    // DELETE /api/admin/users/{id}  — حذف حساب لاعب نهائياً
    // نفس مسار حذف المستخدم لحسابه من التطبيق: إلغاء الالتزامات القادمة مع ردّ
    // الأموال، مسح البيانات الشخصية والملفات، ثم تعمية الحساب. لا رجعة فيه.
    [HttpDelete("users/{id:int}")]
    [RequirePermission(Permissions.UsersDelete)]
    public Task<IActionResult> DeleteUser(int id, [FromQuery] string? reason) =>
        DeleteAccountAsync(id, reason);

    // DELETE /api/admin/coaches/{userId}  — حذف حساب مدرب نهائياً
    // المعرّف هو معرّف المستخدم (CoachDto.userId) لا معرّف ملف المدرب؛ الحذف
    // يطال الحساب كاملاً كما في شاشة اللاعبين، بصلاحية مستقلة لقسم المدربين.
    [HttpDelete("coaches/{userId:int}")]
    [RequirePermission(Permissions.CoachesDelete)]
    public Task<IActionResult> DeleteCoach(int userId, [FromQuery] string? reason) =>
        DeleteAccountAsync(userId, reason);

    private async Task<IActionResult> DeleteAccountAsync(int userId, string? reason)
    {
        if (userId == CurrentUserId())
            return BadRequest(ApiResponse<object>.Fail(
                "Cannot delete your own account", "لا يمكنك حذف حسابك", "SELF_DELETE"));

        try
        {
            await _admin.DeleteUserAccountAsync(userId, reason);
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

    // base.User — الكنترولر يعرّف أكشن باسم User(int) يحجب خاصية ControllerBase.
    private int? CurrentUserId() =>
        int.TryParse(base.User.FindFirst(ClaimTypes.NameIdentifier)?.Value, out var id)
            ? id : null;
}
