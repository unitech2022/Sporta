using SportaApis.DTOs;

namespace SportaApis.Services;

public interface IBookingService
{
    /// <summary>Creates a court booking for the given user.</summary>
    Task<BookingDto> CreateAsync(int userId, CreateBookingRequest request);

    /// <summary>
    /// تسعير حجز قبل تأكيده: السعر الأساسي وخصم باقة اللاعب والإجمالي المستحق.
    /// يستخدم نفس حساب <see cref="CreateAsync"/> فلا يختلف المعروض عن المخصوم.
    /// </summary>
    Task<BookingQuoteDto> QuoteAsync(int userId, BookingQuoteRequest request);

    /// <summary>Lists the user's bookings, newest first (paged + status filter).</summary>
    Task<PagedResult<BookingDto>> GetMyBookingsAsync(
        int userId, int page, int pageSize, string? status);

    /// <summary>Cancels one of the user's bookings.</summary>
    Task<BookingDto> CancelAsync(int userId, int bookingId, string? reason);
}
