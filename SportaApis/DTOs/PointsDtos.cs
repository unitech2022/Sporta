using System.ComponentModel.DataAnnotations;

namespace SportaApis.DTOs;

public class PointsTransactionDto
{
    public int Id { get; set; }
    public int Amount { get; set; }
    public string Type { get; set; } = string.Empty;

    /// <summary>"reward" | "level".</summary>
    public string Kind { get; set; } = "reward";
    public string? Description { get; set; }
    public DateTime CreatedAt { get; set; }
}

/// <summary>رصيد النقاط + قواعد الاستبدال الحالية + آخر الحركات.</summary>
public class PointsSummaryDto
{
    public int Balance { get; set; }

    /// <summary>كم نقطة تلزم مقابل ريال واحد عند الاستبدال.</summary>
    public int RedeemPointsPerRiyal { get; set; }

    /// <summary>الحد الأدنى من النقاط المسموح باستبداله.</summary>
    public int MinRedeemPoints { get; set; }

    /// <summary>القيمة النقدية للرصيد الحالي بالريال.</summary>
    public decimal BalanceValueSar { get; set; }

    /// <summary>نقاط تُكسب لكل 10 ريال إنفاق مدفوع.</summary>
    public int EarnPer10Sar { get; set; }

    /// <summary>نقاط إتمام مباراة.</summary>
    public int MatchReward { get; set; }

    /// <summary>مضاعف النقاط الحالي للمستخدم (أكبر من 1 للمشتركين).</summary>
    public decimal Multiplier { get; set; } = 1m;

    // ── نقاط المستوى ─────────────────────────────────────────────────────────

    /// <summary>صافي نقاط المستوى (قد تكون سالبة).</summary>
    public int LevelPoints { get; set; }

    /// <summary>هل اعتمد مدرب مستوى اللاعب؟ شرط دخول نظام نقاط المستوى.</summary>
    public bool LevelCoachVerified { get; set; }

    /// <summary>هل اعتماد المدرب مطلوب أصلاً (إعداد إداري)؟</summary>
    public bool LevelPointsRequireCoachVerification { get; set; } = true;

    /// <summary>نقاط كل نشاط (حجز ملعب، تنظيم أمريكانو…) كما يضبطها الأدمن.</summary>
    public List<PointsRuleDto> RewardRules { get; set; } = [];

    /// <summary>قواعد الفوز/الخسارة بحسب فرق المستوى كما يضبطها الأدمن.</summary>
    public List<PointsRuleDto> LevelRules { get; set; } = [];

    public PagedResult<PointsTransactionDto> Transactions { get; set; } = new();
}

/// <summary>قاعدة نقاط واحدة: مفتاح الإعداد + تسميته + قيمتها الحالية.</summary>
public class PointsRuleDto
{
    public string Key { get; set; } = string.Empty;
    public string LabelAr { get; set; } = string.Empty;
    public string LabelEn { get; set; } = string.Empty;
    public int Points { get; set; }
}

/// <summary>صف في لوحة المتصدرين.</summary>
public class LeaderboardEntryDto
{
    public int Rank { get; set; }
    public int UserId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? AvatarUrl { get; set; }
    public int? Level { get; set; }
    public int Points { get; set; }
    public bool IsMe { get; set; }
}

/// <summary>أعلى الحاصلين على النقاط لنوع وفترة، مع موقع المستخدم الحالي.</summary>
public class LeaderboardDto
{
    /// <summary>"reward" | "level".</summary>
    public string Kind { get; set; } = "reward";

    /// <summary>"all" | "daily" | "weekly" | "monthly".</summary>
    public string Period { get; set; } = "all";

    public List<LeaderboardEntryDto> Entries { get; set; } = [];

    /// <summary>صف المستخدم الحالي حتى لو لم يكن ضمن القائمة (null بلا نقاط).</summary>
    public LeaderboardEntryDto? Me { get; set; }
}

/// <summary>مستوى من سُلَّم المستويات المعروض في التطبيق.</summary>
public class PlayerLevelDefinitionDto
{
    public int Id { get; set; }
    public decimal Value { get; set; }
    public string TitleAr { get; set; } = string.Empty;
    public string TitleEn { get; set; } = string.Empty;
    public string? DescriptionAr { get; set; }
    public string? DescriptionEn { get; set; }
    public int SortOrder { get; set; }
    public bool IsActive { get; set; }
}

public class SavePlayerLevelDefinitionRequest
{
    [Range(0, 10)] public decimal Value { get; set; }
    [Required] public string TitleAr { get; set; } = string.Empty;
    [Required] public string TitleEn { get; set; } = string.Empty;
    public string? DescriptionAr { get; set; }
    public string? DescriptionEn { get; set; }
    public int SortOrder { get; set; }
    public bool IsActive { get; set; } = true;
}

public class RedeemPointsRequest
{
    [Range(1, int.MaxValue)]
    public int Points { get; set; }
}

/// <summary>إجماليات النقاط للوحة التحكم.</summary>
public class PointsStatsDto
{
    public long TotalEarned { get; set; }
    public long TotalRedeemed { get; set; }
    public long OutstandingBalance { get; set; }
}

public class AdminAdjustPointsRequest
{
    /// <summary>موجب = منح، سالب = خصم.</summary>
    [Required]
    public int Amount { get; set; }

    public string? Reason { get; set; }
}
