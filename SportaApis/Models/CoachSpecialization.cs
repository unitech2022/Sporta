namespace SportaApis.Models;

/// <summary>
/// تخصص تدريبي (تدريب المبتدئين، اللياقة البدنية، ...) يُدار من الأدمن عبر
/// لوحة التحكم. المدرب يختار واحدًا أو أكثر عند التسجيل.
/// </summary>
public class CoachSpecialization : BaseEntity
{
    public string NameAr { get; set; } = string.Empty;
    public string NameEn { get; set; } = string.Empty;
    public bool IsActive { get; set; } = true;

    /// <summary>ترتيب العرض (الأصغر أولًا).</summary>
    public int SortOrder { get; set; } = 0;

    // Navigation
    public ICollection<CoachProfileSpecialization> CoachProfiles { get; set; } = [];
}

/// <summary>ربط مدرب بتخصص (علاقة متعددة إلى متعددة).</summary>
public class CoachProfileSpecialization
{
    public int CoachProfileId { get; set; }
    public CoachProfile CoachProfile { get; set; } = null!;

    public int SpecializationId { get; set; }
    public CoachSpecialization Specialization { get; set; } = null!;
}
