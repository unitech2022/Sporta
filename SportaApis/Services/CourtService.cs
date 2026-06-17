using Microsoft.EntityFrameworkCore;
using SportaApis.Data;
using SportaApis.DTOs;
using SportaApis.Enums;
using SportaApis.Helpers;
using SportaApis.Models;

namespace SportaApis.Services;

public class CourtService : ICourtService
{
    private readonly AppDbContext _db;

    public CourtService(AppDbContext db) => _db = db;

    public async Task<List<CourtDto>> GetCourtsAsync(string? city, string? type, string? gender)
    {
        var query = _db.Courts
            .Include(c => c.Venue)
            .Where(c => c.Venue.IsActive)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(city))
            query = query.Where(c => c.Venue.City == city);

        if (!string.IsNullOrWhiteSpace(type) &&
            Enum.TryParse<CourtType>(type, ignoreCase: true, out var courtType))
            query = query.Where(c => c.Type == courtType);

        if (!string.IsNullOrWhiteSpace(gender) &&
            TryParseGender(gender, out var policy))
            query = query.Where(c => c.Venue.GenderPolicy == policy);

        var courts = await query
            .OrderBy(c => c.Venue.City)
            .ThenBy(c => c.Name)
            .ToListAsync();

        return courts.Select(ToDto).ToList();
    }

    public async Task<CourtDto> GetCourtByIdAsync(int id)
    {
        var court = await _db.Courts
            .Include(c => c.Venue)
            .FirstOrDefaultAsync(c => c.Id == id)
            ?? throw new AuthException("Court not found", "الملعب غير موجود", "COURT_NOT_FOUND");

        return ToDto(court);
    }

    public async Task<CourtAvailabilityDto> GetAvailabilityAsync(int courtId, DateTime date)
    {
        var court = await _db.Courts.FirstOrDefaultAsync(c => c.Id == courtId)
            ?? throw new AuthException("Court not found", "الملعب غير موجود", "COURT_NOT_FOUND");

        var day = date.Date;
        var nextDay = day.AddDays(1);

        // Active bookings that touch the requested day.
        var bookings = await _db.Bookings
            .Where(b => b.CourtId == courtId
                        && b.Status != BookingStatus.Cancelled
                        && b.StartTime < nextDay
                        && b.EndTime > day)
            .Select(b => new { b.StartTime, b.EndTime })
            .ToListAsync();

        var slots = new List<TimeSlotDto>();
        for (var hour = CourtSchedule.OpenHour; hour <= CourtSchedule.LastSlotHour; hour++)
        {
            var slotStart = day.AddHours(hour);
            var isBooked = bookings.Any(b => slotStart >= b.StartTime && slotStart < b.EndTime);

            slots.Add(new TimeSlotDto
            {
                Time = $"{hour:D2}:00",
                IsBooked = isBooked,
                IsPeak = CourtSchedule.IsPeak(hour),
                Price = CourtSchedule.HourlyRate(court, hour),
            });
        }

        return new CourtAvailabilityDto
        {
            Date = day.ToString("yyyy-MM-dd"),
            Slots = slots,
        };
    }

    // ── mapping ────────────────────────────────────────────────────────────────

    private static CourtDto ToDto(Court c) => new()
    {
        Id = c.Id,
        Name = c.Name,
        VenueId = c.VenueId,
        VenueName = c.Venue.Name,
        Country = c.Venue.Country,
        City = c.Venue.City,
        Neighborhood = c.Venue.Address,
        Type = c.Type == CourtType.Indoor ? "indoor" : "outdoor",
        Gender = GenderLabel(c.Venue.GenderPolicy),
        BasePrice = CourtSchedule.BasePrice(c),
        PeakHourPrice = CourtSchedule.PeakPrice(c),
        IsAvailable = c.IsAvailable,
        ImageUrl = c.ImageUrl,
        AvailableTimes = CourtSchedule.OpeningSlots(),
    };

    private static string GenderLabel(VenueGenderPolicy policy) => policy switch
    {
        VenueGenderPolicy.WomenOnly => "women",
        VenueGenderPolicy.FamilyOnly => "family",
        _ => "all",
    };

    private static bool TryParseGender(string value, out VenueGenderPolicy policy)
    {
        switch (value.ToLowerInvariant())
        {
            case "women":
                policy = VenueGenderPolicy.WomenOnly;
                return true;
            case "family":
                policy = VenueGenderPolicy.FamilyOnly;
                return true;
            case "all":
            case "mixed":
                policy = VenueGenderPolicy.Mixed;
                return true;
            default:
                policy = VenueGenderPolicy.Mixed;
                return false;
        }
    }
}
