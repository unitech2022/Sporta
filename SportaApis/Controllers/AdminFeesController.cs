using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SportaApis.Attributes;
using SportaApis.DTOs;
using SportaApis.Helpers;
using SportaApis.Services;

namespace SportaApis.Controllers;

/// <summary>
/// رسوم المنصة: الخصومات (عامة أو مخصصة) وتسعيرة اشتراك الملاعب.
/// </summary>
[ApiController]
[Route("api/admin")]
[Authorize(Roles = "admin,staff")]
public class AdminFeesController : ControllerBase
{
    private readonly IDiscountService _discounts;
    private readonly IVenueSubscriptionService _subscriptions;
    private readonly ISettingsService _settings;

    public AdminFeesController(
        IDiscountService discounts, IVenueSubscriptionService subscriptions,
        ISettingsService settings)
    {
        _discounts = discounts;
        _subscriptions = subscriptions;
        _settings = settings;
    }

    // ── Discounts ─────────────────────────────────────────────────────────────

    // GET /api/admin/discounts
    [HttpGet("discounts")]
    [RequirePermission(Permissions.DiscountsView)]
    public async Task<IActionResult> GetDiscounts() =>
        Ok(ApiResponse<List<DiscountDto>>.Ok(await _discounts.GetAllAsync()));

    // GET /api/admin/discounts/{id}
    [HttpGet("discounts/{id:int}")]
    [RequirePermission(Permissions.DiscountsView)]
    public async Task<IActionResult> GetDiscount(int id)
    {
        var discount = await _discounts.GetAsync(id);
        return discount is null
            ? NotFound(ApiResponse<object>.Fail(
                "Discount not found", "الخصم غير موجود", "DISCOUNT_NOT_FOUND"))
            : Ok(ApiResponse<DiscountDto>.Ok(discount));
    }

    // POST /api/admin/discounts
    [HttpPost("discounts")]
    [RequirePermission(Permissions.DiscountsManage)]
    public async Task<IActionResult> CreateDiscount([FromBody] SaveDiscountRequest request)
    {
        try
        {
            return Ok(ApiResponse<DiscountDto>.Ok(await _discounts.CreateAsync(request)));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    // PUT /api/admin/discounts/{id}
    [HttpPut("discounts/{id:int}")]
    [RequirePermission(Permissions.DiscountsManage)]
    public async Task<IActionResult> UpdateDiscount(int id, [FromBody] SaveDiscountRequest request)
    {
        try
        {
            return Ok(ApiResponse<DiscountDto>.Ok(await _discounts.UpdateAsync(id, request)));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    // DELETE /api/admin/discounts/{id}
    [HttpDelete("discounts/{id:int}")]
    [RequirePermission(Permissions.DiscountsManage)]
    public async Task<IActionResult> DeleteDiscount(int id)
    {
        try
        {
            await _discounts.DeleteAsync(id);
            return Ok(ApiResponse<object>.Ok(new { deleted = true }));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    // GET /api/admin/discounts/user-search?search=&target=  — مرشّحون للإضافة كمستفيدين
    [HttpGet("discounts/user-search")]
    [RequirePermission(Permissions.DiscountsManage)]
    public async Task<IActionResult> SearchUsers(
        [FromQuery] string? search, [FromQuery] string target = "venueCommission")
    {
        try
        {
            var items = await _discounts.SearchUsersAsync(
                search, DiscountService.ParseTarget(target));
            return Ok(ApiResponse<List<DiscountUserOptionDto>>.Ok(items));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    // GET /api/admin/discounts/{id}/beneficiaries
    [HttpGet("discounts/{id:int}/beneficiaries")]
    [RequirePermission(Permissions.DiscountsView)]
    public async Task<IActionResult> GetBeneficiaries(int id) =>
        Ok(ApiResponse<List<DiscountBeneficiaryDto>>.Ok(
            await _discounts.GetBeneficiariesAsync(id)));

    // POST /api/admin/discounts/{id}/beneficiaries  { userId }
    [HttpPost("discounts/{id:int}/beneficiaries")]
    [RequirePermission(Permissions.DiscountsManage)]
    public async Task<IActionResult> AddBeneficiary(int id, [FromBody] AddBeneficiaryRequest request)
    {
        try
        {
            var added = await _discounts.AddBeneficiaryAsync(id, request.UserId);
            return Ok(ApiResponse<DiscountBeneficiaryDto>.Ok(added));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    // DELETE /api/admin/discounts/{id}/beneficiaries/{userId}
    [HttpDelete("discounts/{id:int}/beneficiaries/{userId:int}")]
    [RequirePermission(Permissions.DiscountsManage)]
    public async Task<IActionResult> RemoveBeneficiary(int id, int userId)
    {
        try
        {
            await _discounts.RemoveBeneficiaryAsync(id, userId);
            return Ok(ApiResponse<object>.Ok(new { removed = true }));
        }
        catch (AuthException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message, ex.MessageAr, ex.Code));
        }
    }

    // ── Venue subscription pricing ────────────────────────────────────────────

    // GET /api/admin/venue-subscriptions/pricing
    [HttpGet("venue-subscriptions/pricing")]
    [RequirePermission(Permissions.VenueSubscriptionsView)]
    public async Task<IActionResult> GetPricing() =>
        Ok(ApiResponse<VenueSubscriptionPricingDto>.Ok(await _subscriptions.GetPricingAsync()));

    // PUT /api/admin/venue-subscriptions/pricing
    [HttpPut("venue-subscriptions/pricing")]
    [RequirePermission(Permissions.VenueSubscriptionsManage)]
    public async Task<IActionResult> SavePricing(
        [FromBody] SaveVenueSubscriptionPricingRequest request) =>
        Ok(ApiResponse<VenueSubscriptionPricingDto>.Ok(
            await _subscriptions.SavePricingAsync(request)));

    // GET /api/admin/venue-subscriptions?page=&pageSize=
    [HttpGet("venue-subscriptions")]
    [RequirePermission(Permissions.VenueSubscriptionsView)]
    public async Task<IActionResult> GetSubscriptions(
        [FromQuery] int page = 1, [FromQuery] int pageSize = 20) =>
        Ok(ApiResponse<PagedResult<VenueSubscriptionDto>>.Ok(
            await _subscriptions.GetAllAsync(page, pageSize)));

    // ── Coach commission ──────────────────────────────────────────────────────

    // GET /api/admin/settings/coach-commission
    [HttpGet("settings/coach-commission")]
    [RequirePermission(Permissions.FinanceView)]
    public async Task<IActionResult> GetCoachCommission() =>
        Ok(ApiResponse<object>.Ok(new { percent = await _settings.GetCoachCommissionAsync() }));

    // PUT /api/admin/settings/coach-commission  { percent }
    [HttpPut("settings/coach-commission")]
    [RequirePermission(Permissions.FinanceCommissionManage)]
    public async Task<IActionResult> SetCoachCommission([FromBody] UpdateCourtCommissionRequest request)
    {
        if (request.Percent < 0 || request.Percent > 100)
            return BadRequest(ApiResponse<object>.Fail(
                "Invalid percent", "نسبة غير صحيحة", "INVALID_PERCENT"));

        await _settings.SetCoachCommissionAsync(request.Percent);
        return Ok(ApiResponse<object>.Ok(new { percent = request.Percent }));
    }
}
