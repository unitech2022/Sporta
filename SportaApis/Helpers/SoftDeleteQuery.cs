using SportaApis.Models;

namespace SportaApis.Helpers;

/// <summary>
/// إخفاء الأندية والملاعب المحذوفة من اللوحة. الحذف من لوحة التحكم ناعم — قيد
/// قاعدة البيانات على الحجوزات يمنع مسح الصف، والسجل المالي يجب أن يبقى
/// متماسكاً — فكل استعلام يسرد نادياً أو ملعباً <b>ككيان</b> يمرّ من هنا.
/// سجلات الحجوزات والفواتير السابقة تبقى مرتبطة بملعبها كما هي.
/// </summary>
public static class SoftDeleteQuery
{
    /// <summary>الأندية غير المحذوفة.</summary>
    public static IQueryable<Venue> NotDeleted(this IQueryable<Venue> query) =>
        query.Where(v => !v.IsDeleted);

    /// <summary>الملاعب غير المحذوفة — ويشمل ملاعب نادٍ محذوف.</summary>
    public static IQueryable<Court> NotDeleted(this IQueryable<Court> query) =>
        query.Where(c => !c.IsDeleted && !c.Venue.IsDeleted);
}
