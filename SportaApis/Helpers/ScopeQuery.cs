using SportaApis.Models;
using SportaApis.Services;

namespace SportaApis.Helpers;

/// <summary>
/// تصفية استعلامات اللوحة حسب نطاق الموظف الجغرافي. الأدمن (scope = null) يرى
/// كل شيء؛ الموظف يرى مدينته فقط، أو كل مدن دولته لو لم تُحدَّد مدينة.
/// ملاحظة: السجلات غير المربوطة بمدينة (CityId = null) لا تظهر للموظف — الأمان
/// يسبق الاكتمال، والـ backfill في DbSeeder يربط القديم منها بالاسم النصي.
/// </summary>
public static class ScopeQuery
{
    public static IQueryable<Venue> InScope(this IQueryable<Venue> query, GeoScope? scope)
    {
        if (scope is null) return query;
        if (scope.CityId is int cityId) return query.Where(v => v.CityId == cityId);
        var countryId = scope.CountryId;
        return query.Where(v => v.CityRef != null && v.CityRef.CountryId == countryId);
    }

    public static IQueryable<Court> InScope(this IQueryable<Court> query, GeoScope? scope)
    {
        if (scope is null) return query;
        if (scope.CityId is int cityId) return query.Where(c => c.Venue.CityId == cityId);
        var countryId = scope.CountryId;
        return query.Where(c =>
            c.Venue.CityRef != null && c.Venue.CityRef.CountryId == countryId);
    }

    public static IQueryable<User> InScope(this IQueryable<User> query, GeoScope? scope)
    {
        if (scope is null) return query;
        if (scope.CityId is int cityId) return query.Where(u => u.CityId == cityId);
        var countryId = scope.CountryId;
        return query.Where(u => u.CityRef != null && u.CityRef.CountryId == countryId);
    }

    public static IQueryable<Booking> InScope(this IQueryable<Booking> query, GeoScope? scope)
    {
        if (scope is null) return query;
        if (scope.CityId is int cityId) return query.Where(b => b.Court.Venue.CityId == cityId);
        var countryId = scope.CountryId;
        return query.Where(b =>
            b.Court.Venue.CityRef != null && b.Court.Venue.CityRef.CountryId == countryId);
    }

    public static IQueryable<Match> InScope(this IQueryable<Match> query, GeoScope? scope)
    {
        if (scope is null) return query;
        if (scope.CityId is int cityId)
            return query.Where(m => m.Court != null && m.Court.Venue.CityId == cityId);
        var countryId = scope.CountryId;
        return query.Where(m =>
            m.Court != null && m.Court.Venue.CityRef != null &&
            m.Court.Venue.CityRef.CountryId == countryId);
    }

    public static IQueryable<Notification> InScope(
        this IQueryable<Notification> query, GeoScope? scope)
    {
        if (scope is null) return query;
        if (scope.CityId is int cityId) return query.Where(n => n.User.CityId == cityId);
        var countryId = scope.CountryId;
        return query.Where(n =>
            n.User.CityRef != null && n.User.CityRef.CountryId == countryId);
    }

    /// <summary>معاملات المحفظة تتبع مدينة صاحب المحفظة.</summary>
    public static IQueryable<WalletTransaction> InScope(
        this IQueryable<WalletTransaction> query, GeoScope? scope)
    {
        if (scope is null) return query;
        if (scope.CityId is int cityId)
            return query.Where(t => t.Wallet.User.CityId == cityId);
        var countryId = scope.CountryId;
        return query.Where(t =>
            t.Wallet.User.CityRef != null && t.Wallet.User.CityRef.CountryId == countryId);
    }

    public static IQueryable<WithdrawalRequest> InScope(
        this IQueryable<WithdrawalRequest> query, GeoScope? scope)
    {
        if (scope is null) return query;
        if (scope.CityId is int cityId) return query.Where(w => w.User.CityId == cityId);
        var countryId = scope.CountryId;
        return query.Where(w =>
            w.User.CityRef != null && w.User.CityRef.CountryId == countryId);
    }

    /// <summary>هل تقع هذه المدينة داخل نطاق الموظف؟ (للتحقق قبل إجراء على سجل واحد).</summary>
    public static bool Covers(this GeoScope? scope, int? cityId, int? countryIdOfCity) =>
        scope is null ||
        (scope.CityId is int c ? cityId == c : countryIdOfCity == scope.CountryId);
}
