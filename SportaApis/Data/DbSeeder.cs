using Microsoft.EntityFrameworkCore;
using SportaApis.Enums;
using SportaApis.Models;

namespace SportaApis.Data;

/// <summary>
/// Development-only seed data so the courts/booking screens have something to
/// show before any venue owner has created real venues. Idempotent: it does
/// nothing once courts already exist.
/// </summary>
public static class DbSeeder
{
    public static async Task SeedCourtsAsync(AppDbContext db)
    {
        if (await db.Courts.AnyAsync())
            return;

        // A venue needs an owner; reuse the first registered user.
        var ownerId = await db.Users
            .OrderBy(u => u.Id)
            .Select(u => (int?)u.Id)
            .FirstOrDefaultAsync();

        if (ownerId is null)
            return; // No users yet — register one and the seed runs next launch.

        var venues = new[]
        {
            new Venue
            {
                Name = "نادي البادل الملكي",
                OwnerId = ownerId.Value,
                Country = "السعودية",
                City = "الدمام",
                Address = "العزيزية",
                GenderPolicy = VenueGenderPolicy.Mixed,
                Courts =
                {
                    new Court { Name = "ملعب 1", Type = CourtType.Indoor, PricePerHour = 100 },
                    new Court { Name = "ملعب 2", Type = CourtType.Indoor, PricePerHour = 100 },
                    new Court { Name = "ملعب 3", Type = CourtType.Outdoor, PricePerHour = 80 },
                },
            },
            new Venue
            {
                Name = "بادل كلوب الشرقية",
                OwnerId = ownerId.Value,
                Country = "السعودية",
                City = "الخبر",
                Address = "الثقبة",
                GenderPolicy = VenueGenderPolicy.WomenOnly,
                Courts =
                {
                    new Court { Name = "ملعب 1", Type = CourtType.Outdoor, PricePerHour = 80 },
                    new Court { Name = "ملعب 2", Type = CourtType.Outdoor, PricePerHour = 80 },
                },
            },
            new Venue
            {
                Name = "مركز بادل المدينة",
                OwnerId = ownerId.Value,
                Country = "السعودية",
                City = "الدمام",
                Address = "الفيصلية",
                GenderPolicy = VenueGenderPolicy.FamilyOnly,
                Courts =
                {
                    new Court { Name = "ملعب 1", Type = CourtType.Indoor, PricePerHour = 120 },
                    new Court { Name = "ملعب 2", Type = CourtType.Indoor, PricePerHour = 120 },
                },
            },
        };

        db.Venues.AddRange(venues);
        await db.SaveChangesAsync();
    }
}
