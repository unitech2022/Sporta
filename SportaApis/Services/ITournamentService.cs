using SportaApis.DTOs;

namespace SportaApis.Services;

/// <summary>
/// البطولة الإقصائية (نظام كأس العالم): فرق من لاعبَين، مجموعات و/أو خروج
/// المغلوب، والتطبيق يشكّل الفرق والقرعة والمجموعات والمباريات والجدول على
/// الملاعب؛ المنظّم يسجّل النتائج فقط. الانضمام ودعوة الشريك عبر نقاط
/// الأمريكانو نفسها (<c>/api/americano/{id}/join|invite</c>) — البطولة
/// <see cref="Models.AmericanoMatch"/> بـ <c>Format != null</c>.
/// </summary>
public interface ITournamentService
{
    /// <summary>تقدير قبل الإنشاء: المجموعات، عدد المباريات، سعة الجدول، السعر.</summary>
    Task<TournamentQuoteDto> QuoteAsync(TournamentQuoteRequest req);

    Task<TournamentDto> CreateAsync(int creatorId, CreateTournamentRequest req);

    Task<TournamentDto> GetByIdAsync(int id);

    /// <summary>القرعة إن اكتمل العدد وكان الحدث مفتوحاً ولم تُجرَ بعد. تعيد
    /// true إن أُجريت الآن.</summary>
    Task<bool> TryDrawAsync(int americanoId);

    /// <summary>المنظّم يبدأ بالفرق المكتملة الحالية: تُحذف الناقصة (مع ردّ ما
    /// دُفع) وتُجرى القرعة.</summary>
    Task<TournamentDto> StartWithCurrentAsync(int userId, int id);

    /// <summary>المنظّم يؤجّل البطولة إلى موعد جديد (تنتقل الأيام والمباريات معاً).</summary>
    Task<TournamentDto> PostponeAsync(int userId, int id, DateTime newStart);

    /// <summary>المنظّم يلغي البطولة ويُعاد لكل من دفع.</summary>
    Task<TournamentDto> CancelAsync(int userId, int id);

    /// <summary>تسمية فريق (أحد لاعبيه أو المنظّم)؛ الاسم الفارغ يعيده لحرفه.</summary>
    Task<TournamentDto> RenameTeamAsync(int userId, int id, int team, string? name);

    /// <summary>المنظّم يسجّل نتيجة مباراة؛ يتقدّم الفائز تلقائياً وتُملأ
    /// الإقصائيات حين تكتمل المجموعات.</summary>
    Task<TournamentDto> SubmitFixtureScoreAsync(
        int userId, int fixtureId, SubmitFixtureScoreRequest req);
    Task<TournamentDto> RespondFixtureScoreAsync(int userId, int fixtureId, RespondResultRequest req);
    Task<TournamentDto> ResolveFixtureScoreAsync(int userId, int fixtureId, SubmitFixtureScoreRequest req);

    /// <summary>المنظّم يسجّل نتيجة (أو فوزاً إدارياً) لمباراة لم تُعتمد بعد
    /// مرور موعدها، فلا تتعطّل البطولة بغياب فريق أو تجاهل التأكيد.</summary>
    Task<TournamentDto> RecordFixtureResultAsync(int userId, int fixtureId, OrganizerFixtureResultRequest req);
}

/// <summary>نتيجة يسجّلها المنظّم؛ <see cref="Walkover"/> = فوز إداري (غياب
/// الفريق الآخر) بلا نقاط مستوى، والنتيجة المرسلة تُحسب في جدول المجموعة.</summary>
public class OrganizerFixtureResultRequest : SubmitFixtureScoreRequest
{
    public bool Walkover { get; set; }
}
