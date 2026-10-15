using SportaApis.DTOs;

namespace SportaApis.Services;

public interface IVenueService
{
    /// <summary>Home dashboard stats for the signed-in venue owner.</summary>
    Task<VenueDashboardDto> GetDashboardAsync(int ownerUserId);

    /// <summary>Approved venues as a minimal list, for public pickers (e.g. coach
    /// registration's "preferred training venue" field).</summary>
    Task<List<VenueOptionDto>> GetOptionsAsync();

    /// <summary>Financial report for one period ("month" | "week"), <paramref
    /// name="offset"/> periods back from the current one (0 = current).</summary>
    Task<VenueRevenueReportDto> GetRevenueReportAsync(
        int ownerUserId, string periodType, int offset);

    /// <summary>The owner's venues with their courts.</summary>
    Task<List<OwnerVenueDto>> GetMyVenuesAsync(int ownerUserId);

    /// <summary>Creates a venue owned by the user.</summary>
    Task<OwnerVenueDto> CreateVenueAsync(int ownerUserId, CreateVenueRequest req);

    /// <summary>Adds a court to a venue the user owns.</summary>
    Task<OwnerCourtDto> AddCourtAsync(int ownerUserId, int venueId, CreateCourtRequest req);

    /// <summary>Updates a court's price/availability (owner only).</summary>
    Task<OwnerCourtDto> UpdateCourtAsync(int ownerUserId, int courtId, UpdateCourtRequest req);

    /// <summary>حفظ دوام أسبوع الملعب وقواعد تسعيره حسب اليوم والوقت.</summary>
    Task<OwnerCourtDto> UpdateCourtScheduleAsync(
        int ownerUserId, int courtId, UpdateCourtScheduleRequest req);

    /// <summary>أسعار النادي حسب الوقت: ملاعبه بأسعارها الأساسية وقواعدها الحالية.</summary>
    Task<VenuePricingDto> GetVenuePricingAsync(int ownerUserId, int venueId);

    /// <summary>يطبّق نطاقات الأسعار نفسها على كل ملاعب النادي أو على المختار منها.</summary>
    Task<VenuePricingDto> UpdateVenuePricingAsync(
        int ownerUserId, int venueId, UpdateVenuePriceRulesRequest req);

    /// <summary>Deletes a court the user owns (blocked if it has active bookings). Returns the venue id.</summary>
    Task<int> DeleteCourtAsync(int ownerUserId, int courtId);

    /// <summary>The day's hourly slots for an owned court (booked / blocked / available).</summary>
    Task<OwnerCourtSlotsDto> GetCourtSlotsAsync(int ownerUserId, int courtId, DateTime date);

    /// <summary>Toggles a slot's availability (owner only). Booked slots can't be toggled.</summary>
    Task<OwnerCourtSlotsDto> ToggleCourtSlotAsync(
        int ownerUserId, int courtId, DateTime date, int hour);

    /// <summary>Blocks or unblocks several slots at once. Booked slots are skipped.</summary>
    Task<OwnerCourtSlotsDto> SetCourtSlotsAsync(
        int ownerUserId, int courtId, DateTime date, List<int> hours, bool available);

    /// <summary>Court bookings across the owner's venues (paged + status filter).</summary>
    Task<PagedResult<VenueBookingDto>> GetVenueBookingsAsync(
        int ownerUserId, int page, int pageSize, string? status);

    /// <summary>Owner approves/rejects a booking on one of their courts.</summary>
    Task<VenueBookingDto> RespondToBookingAsync(
        int ownerUserId, int bookingId, bool approve);

    /// <summary>Match-hosting requests on the owner's courts (paged + status filter).</summary>
    /// <paramref name="mine"/> = الأحداث التي أنشأها الملعب بنفسه فقط («مبارياتي»).
    /// <paramref name="kind"/> = match | americano | tournament (null = الكل).
    /// <paramref name="status"/> يقبل عدة حالات مفصولة بفاصلة.
    Task<PagedResult<VenueMatchRequestDto>> GetMatchRequestsAsync(
        int ownerUserId, int page, int pageSize, string? status, bool mine = false,
        string? kind = null);

    /// <summary>One match request in full (players, creator contact, payout).</summary>
    Task<VenueMatchRequestDetailDto> GetMatchRequestAsync(
        int ownerUserId, int matchId);

    /// <summary>Owner approves/rejects a match hosted on one of their courts.</summary>
    Task<VenueMatchRequestDto> RespondToMatchRequestAsync(
        int ownerUserId, int matchId, bool approve);

    // ── Admin ────────────────────────────────────────────────────────────────

    /// <summary>All venues (any owner), with owner contact info and onboarding
    /// documents, for the admin dashboard.</summary>
    Task<PagedResult<AdminVenueDto>> GetAllVenuesAsync(
        string? search, int page, int pageSize);

    /// <summary>A single venue with owner + documents (admin only).</summary>
    Task<AdminVenueDto?> GetVenueByIdAsync(int id);
}
