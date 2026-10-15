namespace SportaApis.DTOs;

/// <summary>One activity item in the "followed players" feed.</summary>
public class FeedItemDto
{
    public int ActorId { get; set; }
    public string ActorName { get; set; } = string.Empty;

    /// <summary>"match_joined" | "coach_session" | "level".</summary>
    public string Type { get; set; } = string.Empty;

    /// <summary>
    /// Human-readable Arabic description. التطبيق يركّب الجملة بلغته من الحقول
    /// المنظّمة أدناه ولا يعرض هذا إلا كاحتياطي (نسخ قديمة).
    /// </summary>
    public string Text { get; set; } = string.Empty;

    /// <summary>اسم الملعب ونسخته الإنجليزية — بنود "match_joined" فقط (قد يكونا null).</summary>
    public string? VenueName { get; set; }
    public string? VenueNameEn { get; set; }

    /// <summary>اسم المدرب — بنود "coach_session" فقط.</summary>
    public string? CoachName { get; set; }

    /// <summary>المستوى المحدَّد — بنود "level" فقط.</summary>
    public int? Level { get; set; }

    public DateTime CreatedAt { get; set; }
}
