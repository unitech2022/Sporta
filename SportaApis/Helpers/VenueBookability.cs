using Microsoft.EntityFrameworkCore;
using SportaApis.Data;
using SportaApis.Models;

namespace SportaApis.Helpers;

/// <summary>
/// هل يقبل ملعبٌ الحجز من اللاعبين؟ النادي مفعّل ومعتمد، والملعب غير موقوف
/// من الإدارة ولا معطَّل من مالكه، ولمالكه اشتراك ساري (ما دام متطلب الاشتراك
/// مفعّلاً من الأدمن).
/// مصدر واحد يستعمله بحث الملاعب والحجز المباشر معاً، حتى لا يُحجز بالمعرّف
/// (من المفضّلة أو رابط قديم) ملعبٌ أخفاه البحث.
/// </summary>
public static class VenueBookability
{
    /// <summary>هل متطلب اشتراك الملاعب مفعّل؟ غياب صف التسعيرة يعني القيم
    /// الافتراضية (مفعّل) — نفس سلوك إنشائه الكسول في خدمة الاشتراك.</summary>
    public static async Task<bool> SubscriptionRequiredAsync(AppDbContext db)
    {
        var isActive = await db.VenueSubscriptionPricings
            .Select(p => (bool?)p.IsActive)
            .FirstOrDefaultAsync();
        return isActive ?? true;
    }

    /// <summary>يقصر الاستعلام على الملاعب القابلة للحجز من اللاعبين.</summary>
    public static async Task<IQueryable<Court>> WhereBookableAsync(
        this IQueryable<Court> query, AppDbContext db)
    {
        query = query.Where(c => c.Venue.IsActive && c.Venue.IsApproved
                                 && !c.IsSuspended && c.IsAvailable);

        // ملاعب المالك الذي لا اشتراك سارياً له تختفي — انتهاء الاشتراك
        // يخفيها تلقائياً. يُعطَّل الفرض كلياً بمفتاح الأدمن IsActive.
        if (await SubscriptionRequiredAsync(db))
        {
            var now = DateTime.UtcNow;
            query = query.Where(c => db.VenueSubscriptions.Any(s =>
                s.OwnerId == c.Venue.OwnerId &&
                s.StartsAt <= now && s.EndsAt > now));
        }

        return query;
    }

    /// <summary>نفس شروط <see cref="WhereBookableAsync"/> لملعب واحد.</summary>
    public static async Task<bool> IsBookableAsync(AppDbContext db, int courtId) =>
        await (await db.Courts.NotDeleted().Where(c => c.Id == courtId).WhereBookableAsync(db))
            .AnyAsync();
}
