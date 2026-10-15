using System.ComponentModel.DataAnnotations;

namespace SportaApis.DTOs;

/// <summary>
/// تجربة واحدة كما يراها المستخدم الحالي: ما يحقّ له تقييمه فيها ومن قيّمه.
/// context: match | booking | session.
/// </summary>
public class ReviewSessionDto
{
    public string Context { get; set; } = "match";
    public int ContextId { get; set; }

    /// <summary>match | americano | tournament | booking | session — للعرض.</summary>
    public string Kind { get; set; } = "match";

    public string Title { get; set; } = string.Empty;
    public string? TitleEn { get; set; }
    public string? Subtitle { get; set; }
    public string? SubtitleEn { get; set; }
    public string? ImageUrl { get; set; }
    public DateTime? StartsAt { get; set; }

    /// <summary>player | coach | venue — صفة المستخدم في هذه التجربة.</summary>
    public string? MyRole { get; set; }

    public bool CanReview { get; set; }

    /// <summary>حين CanReview=false: not_member | not_ended | cancelled | not_paid | nothing.</summary>
    public string? Reason { get; set; }

    public List<ReviewTargetDto> Targets { get; set; } = [];
    public int RatedCount { get; set; }
}

public class ReviewTargetDto
{
    /// <summary>player | coach | court</summary>
    public string Type { get; set; } = "player";
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? NameEn { get; set; }
    public string? ImageUrl { get; set; }

    /// <summary>player | coach | venue | court — شارة الدور بجانب الاسم.</summary>
    public string Role { get; set; } = "player";

    public ReviewItemDto? MyReview { get; set; }
}

public class SubmitReviewsRequest
{
    public List<ReviewInput> Reviews { get; set; } = [];
}

public class ReviewInput
{
    /// <summary>player | coach | court</summary>
    [Required] public string Type { get; set; } = "player";
    public int Id { get; set; }
    [Range(1, 5)] public int Score { get; set; }
    public List<string>? Tags { get; set; }
    [MaxLength(500)] public string? Comment { get; set; }
}

public class ReviewItemDto
{
    public int Id { get; set; }
    public int RaterId { get; set; }
    public string RaterName { get; set; } = string.Empty;
    public string? RaterAvatarUrl { get; set; }
    public string RaterRole { get; set; } = "player";
    public int Score { get; set; }
    public List<string> Tags { get; set; } = [];
    public string? Comment { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}

/// <summary>تجربة انتهت وفيها أطراف لم يُقيَّموا بعد — بطاقة «قيّم تجربتك».</summary>
public class PendingReviewDto
{
    public string Context { get; set; } = "match";
    public int ContextId { get; set; }
    public string Kind { get; set; } = "match";
    public string Title { get; set; } = string.Empty;
    public string? TitleEn { get; set; }
    public string? Subtitle { get; set; }
    public string? SubtitleEn { get; set; }
    public string? ImageUrl { get; set; }
    public DateTime StartsAt { get; set; }
    public string MyRole { get; set; } = "player";
    public int PendingCount { get; set; }
}

/// <summary>ملخّص تقييمات ملعب + صفحة من المراجعات.</summary>
public class CourtRatingsDto
{
    public int CourtId { get; set; }
    public double Average { get; set; }
    public int Count { get; set; }

    /// <summary>عدد التقييمات لكل نجمة: المفتاح 1..5.</summary>
    public Dictionary<int, int> Distribution { get; set; } = [];

    /// <summary>أكثر الجوانب ذكراً في التقييمات الجيدة (٤ نجوم فأكثر).</summary>
    public List<ReviewTagCountDto> TopPraised { get; set; } = [];

    public PagedResult<ReviewItemDto> Reviews { get; set; } = new();
}

/// <summary>سمعة لاعب: متوسط ما منحه إياه اللاعبون والمدربون وأصحاب الملاعب.
/// بلا أسماء ولا تعليقات — كي لا تتحوّل التقييمات إلى خصومات.</summary>
public class PlayerReputationDto
{
    public int UserId { get; set; }
    public double Average { get; set; }
    public int Count { get; set; }
    public Dictionary<int, int> Distribution { get; set; } = [];
    public List<ReviewTagCountDto> TopPraised { get; set; } = [];

    /// <summary>عدد التقييمات بحسب صفة المقيِّم: player / coach / venue.</summary>
    public Dictionary<string, int> ByRole { get; set; } = [];
}

public class ReviewTagCountDto
{
    public string Tag { get; set; } = string.Empty;
    public int Count { get; set; }
}
