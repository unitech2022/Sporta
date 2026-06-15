using SportaApis.DTOs;

namespace SportaApis.Services;

public interface IBookingService
{
    /// <summary>Creates a court booking for the given user.</summary>
    Task<BookingDto> CreateAsync(int userId, CreateBookingRequest request);

    /// <summary>Lists the user's bookings, newest first.</summary>
    Task<List<BookingDto>> GetMyBookingsAsync(int userId);

    /// <summary>Cancels one of the user's bookings.</summary>
    Task<BookingDto> CancelAsync(int userId, int bookingId, string? reason);
}
