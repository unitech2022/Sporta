using Microsoft.EntityFrameworkCore;
using SportaApis.Data;
using SportaApis.DTOs;
using SportaApis.Enums;
using SportaApis.Helpers;
using SportaApis.Models;

namespace SportaApis.Services;

public class BookingService : IBookingService
{
    private readonly AppDbContext _db;

    public BookingService(AppDbContext db) => _db = db;

    public async Task<BookingDto> CreateAsync(int userId, CreateBookingRequest request)
    {
        var court = await _db.Courts
            .Include(c => c.Venue)
            .FirstOrDefaultAsync(c => c.Id == request.CourtId)
            ?? throw new AuthException("Court not found", "الملعب غير موجود", "COURT_NOT_FOUND");

        if (!court.IsAvailable)
            throw new AuthException(
                "Court is not available", "الملعب غير متاح للحجز", "COURT_UNAVAILABLE");

        var start = request.StartTime;
        var end = start.AddMinutes(request.DurationMinutes);

        if (start.Hour < CourtSchedule.OpenHour || start.Hour > CourtSchedule.LastSlotHour)
            throw new AuthException(
                "Selected time is outside opening hours",
                "الوقت المختار خارج ساعات العمل", "OUTSIDE_OPENING_HOURS");

        // Reject overlapping bookings on the same court.
        var overlaps = await _db.Bookings.AnyAsync(b =>
            b.CourtId == court.Id &&
            b.Status != BookingStatus.Cancelled &&
            b.StartTime < end &&
            b.EndTime > start);

        if (overlaps)
            throw new AuthException(
                "This slot is already booked", "هذا الموعد محجوز بالفعل", "SLOT_TAKEN");

        var booking = new Booking
        {
            CourtId = court.Id,
            UserId = userId,
            StartTime = start,
            EndTime = end,
            TotalPrice = CourtSchedule.TotalPrice(court, start, request.DurationMinutes),
            Status = BookingStatus.Confirmed,
            PaidFullAmount = request.PaidFullAmount,
        };

        _db.Bookings.Add(booking);
        await _db.SaveChangesAsync();

        return ToDto(booking, court);
    }

    public async Task<List<BookingDto>> GetMyBookingsAsync(int userId)
    {
        var bookings = await _db.Bookings
            .Include(b => b.Court).ThenInclude(c => c.Venue)
            .Where(b => b.UserId == userId)
            .OrderByDescending(b => b.StartTime)
            .ToListAsync();

        return bookings.Select(b => ToDto(b, b.Court)).ToList();
    }

    public async Task<BookingDto> CancelAsync(int userId, int bookingId, string? reason)
    {
        var booking = await _db.Bookings
            .Include(b => b.Court).ThenInclude(c => c.Venue)
            .FirstOrDefaultAsync(b => b.Id == bookingId && b.UserId == userId)
            ?? throw new AuthException(
                "Booking not found", "الحجز غير موجود", "BOOKING_NOT_FOUND");

        if (booking.Status == BookingStatus.Cancelled)
            throw new AuthException(
                "Booking is already cancelled", "الحجز ملغى بالفعل", "ALREADY_CANCELLED");

        if (booking.Status == BookingStatus.Completed)
            throw new AuthException(
                "Completed bookings cannot be cancelled",
                "لا يمكن إلغاء حجز مكتمل", "BOOKING_COMPLETED");

        booking.Status = BookingStatus.Cancelled;
        booking.CancelledAt = DateTime.UtcNow;
        booking.CancellationReason = reason;
        booking.UpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync();

        return ToDto(booking, booking.Court);
    }

    // ── mapping ────────────────────────────────────────────────────────────────

    private static BookingDto ToDto(Booking b, Court court) => new()
    {
        Id = b.Id,
        CourtId = b.CourtId,
        CourtName = court.Name,
        VenueName = court.Venue?.Name ?? string.Empty,
        City = court.Venue?.City ?? string.Empty,
        StartTime = b.StartTime,
        EndTime = b.EndTime,
        DurationMinutes = (int)(b.EndTime - b.StartTime).TotalMinutes,
        TotalPrice = b.TotalPrice,
        Status = b.Status.ToString(),
        PaidFullAmount = b.PaidFullAmount,
    };
}
