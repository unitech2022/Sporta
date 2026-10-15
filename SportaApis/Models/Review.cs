using SportaApis.Enums;

namespace SportaApis.Models;

/// <summary>
/// تقييم طرف لطرف آخر بعد تجربة مشتركة (مباراة/أمريكانو/بطولة، حجز ملعب،
/// جلسة تدريب): اللاعب يقيّم الملعب والمدرب وبقية اللاعبين، والمدرب يقيّم
/// اللاعب والملعب، وصاحب الملعب يقيّم اللاعبين والمدرب. تقييم واحد لكل
/// (مقيِّم، هدف، تجربة) ويُعدَّل ولا يتكرر.
/// </summary>
public class Review : BaseEntity
{
    public int RaterId { get; set; }
    public User Rater { get; set; } = null!;

    public ReviewerRole RaterRole { get; set; }

    public ReviewTargetType TargetType { get; set; }

    /// <summary>معرّف المستخدم (لاعب/مدرب) أو معرّف الملعب.</summary>
    public int TargetId { get; set; }

    public ReviewContextType ContextType { get; set; }
    public int ContextId { get; set; }

    /// <summary>1..5 نجوم.</summary>
    public int Score { get; set; }

    /// <summary>جوانب مختارة مفصولة بفواصل — المفاتيح بحسب نوع الهدف.</summary>
    public string? Tags { get; set; }

    public string? Comment { get; set; }
}
