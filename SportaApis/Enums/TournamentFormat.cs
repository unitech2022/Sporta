namespace SportaApis.Enums;

/// <summary>نظام البطولة الإقصائية (كأس العالم).</summary>
public enum TournamentFormat
{
    /// <summary>مجموعات بنظام الدوري ثم خروج المغلوب بين المتأهلين.</summary>
    GroupsKnockout = 0,

    /// <summary>خروج المغلوب من المباراة الأولى.</summary>
    Knockout = 1,
}
