using Microsoft.EntityFrameworkCore;
using SportaApis.Data;
using SportaApis.Services;

namespace SportaApis.Helpers;

/// <summary>
/// أقفال MySQL مسمّاة (GET_LOCK) تُسلسِل مسارات «افحص ثم اكتب» بين الطلبات
/// المتزامنة: حجز نفس الملعب، الانضمام لنفس الحدث، خصم نفس المحفظة…
/// بدونها يمرّ طلبان معاً من الفحص ثم يكتبان كلاهما.
///
/// الاستخدام:
/// <code>await using var _ = await DbLocks.AcquireAsync(_db, $"court:{courtId}");</code>
/// القفل مربوط بالاتصال، فيُفتح الاتصال ويبقى مفتوحاً حتى التحرير ليمرّ كل
/// ما بداخله من استعلامات على الاتصال نفسه.
/// </summary>
public static class DbLocks
{
    public static async Task<IAsyncDisposable> AcquireAsync(
        AppDbContext db, string name, int timeoutSeconds = 10)
    {
        await db.Database.OpenConnectionAsync();
        try
        {
            var conn = db.Database.GetDbConnection();
            await using var cmd = conn.CreateCommand();
            cmd.CommandText = "SELECT GET_LOCK(@name, @timeout)";
            AddParam(cmd, "@name", LockName(name));
            AddParam(cmd, "@timeout", timeoutSeconds);
            var result = await cmd.ExecuteScalarAsync();
            if (result is null or DBNull || Convert.ToInt32(result) != 1)
                throw new AuthException(
                    "Resource is busy, please retry",
                    "العملية مشغولة الآن، حاول مجدداً بعد لحظات", "RESOURCE_BUSY");
            return new Releaser(db, LockName(name));
        }
        catch
        {
            await db.Database.CloseConnectionAsync();
            throw;
        }
    }

    /// <summary>
    /// عدة أقفال معاً (ملاعب بطولة مثلاً). المستدعي يمرّر الأسماء بترتيب ثابت
    /// (بالمعرّف) حتى لا يتشابك طلبان؛ تُحرَّر بعكس ترتيب أخذها. إن فشل أحدها
    /// يُحرَّر ما أُخذ قبله.
    /// </summary>
    public static async Task<IAsyncDisposable> AcquireManyAsync(
        AppDbContext db, IEnumerable<string> names, int timeoutSeconds = 10)
    {
        var held = new List<IAsyncDisposable>();
        try
        {
            foreach (var name in names)
                held.Add(await AcquireAsync(db, name, timeoutSeconds));
            return new ManyReleaser(held);
        }
        catch
        {
            await new ManyReleaser(held).DisposeAsync();
            throw;
        }
    }

    private sealed class ManyReleaser(List<IAsyncDisposable> held) : IAsyncDisposable
    {
        public async ValueTask DisposeAsync()
        {
            for (var i = held.Count - 1; i >= 0; i--)
                await held[i].DisposeAsync();
            held.Clear();
        }
    }

    // أسماء أقفال MySQL بحد أقصى 64 حرفاً، ومشتركة بين قواعد الخادم: نُسبقها
    // باسم القاعدة حتى لا تتصادم بيئتان على نفس الخادم.
    private static string LockName(string name)
    {
        var full = $"sporta:{name}";
        return full.Length <= 64 ? full : full[..64];
    }

    private static void AddParam(System.Data.Common.DbCommand cmd, string name, object value)
    {
        var p = cmd.CreateParameter();
        p.ParameterName = name;
        p.Value = value;
        cmd.Parameters.Add(p);
    }

    private sealed class Releaser(AppDbContext db, string name) : IAsyncDisposable
    {
        public async ValueTask DisposeAsync()
        {
            try
            {
                var conn = db.Database.GetDbConnection();
                await using var cmd = conn.CreateCommand();
                cmd.CommandText = "SELECT RELEASE_LOCK(@name)";
                AddParam(cmd, "@name", name);
                await cmd.ExecuteScalarAsync();
            }
            finally
            {
                await db.Database.CloseConnectionAsync();
            }
        }
    }
}
