using SportaApis.Data;

namespace SportaApis.Helpers;

/// <summary>
/// قفل حدث واحد (مباراة/أمريكانو/بطولة) على <see cref="DbLocks"/> باسم
/// <c>match:{matchId}</c>: يُسلسِل الانضمام والقبول والرفض والانسحاب على نفس
/// الحدث، فلا تُخصم حصة مرتين بنقرتين ولا تتجاوز المقاعد السعة.
///
/// يُحرَّر مبكراً بـ <see cref="ReleaseAsync"/> (قبل الإشعارات البطيئة مثلاً)،
/// والتحرير مرة واحدة فقط مهما تكرّر — <c>await using</c> يحرّره إن لم يُحرَّر.
/// </summary>
public sealed class MatchLock : IAsyncDisposable
{
    private IAsyncDisposable? _inner;

    private MatchLock(IAsyncDisposable inner) => _inner = inner;

    public static async Task<MatchLock> AcquireAsync(AppDbContext db, int matchId) =>
        new(await DbLocks.AcquireAsync(db, $"match:{matchId}"));

    public async Task ReleaseAsync()
    {
        var inner = Interlocked.Exchange(ref _inner, null);
        if (inner != null) await inner.DisposeAsync();
    }

    public async ValueTask DisposeAsync() => await ReleaseAsync();
}
