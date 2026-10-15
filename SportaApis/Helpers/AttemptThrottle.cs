using Microsoft.Extensions.Caching.Memory;

namespace SportaApis.Helpers;

/// <summary>
/// عدّاد محاولات في الذاكرة لمسارات بلا حماية في قاعدة البيانات: محاولات كلمة
/// مرور اللوحة، ورفع الصور المجهول. يكفي لخادم واحد (وهو وضعنا)؛ تعدد الخوادم
/// يحتاج مخزناً مشتركاً.
/// </summary>
public sealed class AttemptThrottle(IMemoryCache cache)
{
    /// <summary>هل تجاوز <paramref name="key"/> <paramref name="limit"/> محاولة خلال النافذة؟</summary>
    public bool IsBlocked(string key, int limit) =>
        cache.TryGetValue<int>(key, out var n) && n >= limit;

    /// <summary>يسجّل محاولة ويعيد العدد بعدها (النافذة تبدأ من أول محاولة).</summary>
    public int Hit(string key, TimeSpan window)
    {
        var n = cache.TryGetValue<int>(key, out var cur) ? cur + 1 : 1;
        // الدخول الأول يثبّت مدة النافذة؛ ما بعده يبقي النهاية كما هي.
        if (n == 1) cache.Set(key, n, window);
        else cache.Set(key, n, new MemoryCacheEntryOptions
        {
            AbsoluteExpiration = cache.TryGetValue(key + ":until", out DateTimeOffset until)
                ? until : DateTimeOffset.UtcNow.Add(window),
        });
        if (n == 1) cache.Set(key + ":until", DateTimeOffset.UtcNow.Add(window), window);
        return n;
    }

    public void Reset(string key)
    {
        cache.Remove(key);
        cache.Remove(key + ":until");
    }
}
