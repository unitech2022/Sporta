using SportaApis.DTOs;

namespace SportaApis.Services;

public interface ICoachService
{
    /// <summary>Lists coaches (paged), optionally filtered by city, gender
    /// ("male"/"female") and the requester's nearby radius. Admin may include
    /// suspended accounts.</summary>
    Task<PagedResult<CoachDto>> GetCoachesAsync(
        int currentUserId, string? city, string? gender = null,
        bool includeInactive = false, int page = 1, int pageSize = 20);

    /// <summary>Returns a single coach by their coach-profile id.</summary>
    Task<CoachDto> GetCoachByIdAsync(int id);

    /// <summary>Books a training session with the coach for the given player.</summary>
    Task<CoachSessionDto> BookSessionAsync(
        int playerId, int coachId, CreateCoachSessionRequest req);

    /// <summary>Lists the player's booked sessions (paged + status filter).</summary>
    Task<PagedResult<CoachSessionDto>> GetMySessionsAsync(
        int playerId, int page, int pageSize, string? status);

    /// <summary>Pending session booking requests for the signed-in coach.</summary>
    Task<PagedResult<CoachSessionDto>> GetSessionRequestsAsync(
        int coachUserId, int page, int pageSize);

    /// <summary>All bookings for the signed-in coach (paged + status filter).</summary>
    Task<PagedResult<CoachSessionDto>> GetCoachBookingsAsync(
        int coachUserId, int page, int pageSize, string? status);

    /// <summary>The signed-in coach's own profile (for editing).</summary>
    Task<CoachDto> GetMyCoachProfileAsync(int coachUserId);

    /// <summary>Updates the signed-in coach's profile (name/city/bio/specialization/rate).</summary>
    Task<CoachDto> UpdateMyCoachProfileAsync(int coachUserId, UpdateCoachProfileRequest req);

    /// <summary>Stores the coach's uploaded identity/iqama document URL.</summary>
    Task<CoachDto> UpdateIdDocumentAsync(int coachUserId, string relativeUrl);

    /// <summary>Coach approves/rejects a pending session booking request.</summary>
    Task<CoachSessionDto> RespondToSessionAsync(
        int coachUserId, int sessionId, bool approve);

    /// <summary>Home dashboard stats for the signed-in coach.</summary>
    Task<CoachDashboardDto> GetDashboardAsync(int coachUserId);

    /// <summary>
    /// Coach rates the player after a paid, ended session. A good rating
    /// (4+) raises the player's level by one step.
    /// </summary>
    Task<CoachSessionDto> RateSessionAsync(
        int coachUserId, int sessionId, int rating, string? review);

    /// <summary>
    /// Player rates the coach after a paid, ended session. Player ratings feed
    /// the coach's displayed rating and the automatic "معتمد" badge.
    /// </summary>
    Task<CoachSessionDto> RateCoachAsync(
        int playerId, int sessionId, int rating, string? review);

    /// <summary>Pending level assessments this coach can review (paged; video + requested).</summary>
    Task<PagedResult<LevelAssessmentDto>> GetPendingAssessmentsAsync(
        int coachUserId, int page = 1, int pageSize = 20);

    /// <summary>Assigns a level to a pending assessment and updates the player.</summary>
    Task<LevelAssessmentDto> AssignAssessmentLevelAsync(
        int coachUserId, int assessmentId, int level, string? notes);

    /// <summary>The coach's students — unique players from paid sessions, most
    /// recently trained first (paged).</summary>
    Task<PagedResult<CoachStudentDto>> GetStudentsAsync(
        int coachUserId, int page = 1, int pageSize = 20);

    /// <summary>Earnings report for one period (month or week), for the
    /// coach's financial-reports page.</summary>
    Task<CoachRevenueReportDto> GetRevenueReportAsync(
        int coachUserId, string periodType, int offset);

    /// <summary>All of the signed-in coach's offers (active, inactive and
    /// expired) — for the "العروض والخصومات" management section.</summary>
    Task<List<CoachOfferDto>> GetMyOffersAsync(int coachUserId);

    /// <summary>Creates a new offer/discount on the coach's profile.</summary>
    Task<CoachOfferDto> CreateOfferAsync(int coachUserId, CreateCoachOfferRequest req);

    /// <summary>Activates or deactivates one of the coach's own offers.</summary>
    Task<CoachOfferDto> SetOfferActiveAsync(int coachUserId, int offerId, bool isActive);

    /// <summary>Deletes one of the coach's own offers.</summary>
    Task DeleteOfferAsync(int coachUserId, int offerId);
}
