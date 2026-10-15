namespace SportaApis.Models;

/// <summary>
/// لعبة رياضية (بادل، تنس، ...) تُدار من الأدمن عبر لوحة التحكم.
/// </summary>
public class Sport : BaseEntity
{
    /// <summary>
    /// مفتاح ثابت بالإنجليزي (lowercase)، يُشتق من <see cref="NameEn"/> عند
    /// الإنشاء ولا يتغيّر لاحقًا. يطابق نفس القيم المستخدمة كـ string حر في
    /// AssessmentQuestion.Sport / AssessmentLevel.Sport / User.FavoriteSport
    /// (مثل "padel").
    /// </summary>
    public string Key { get; set; } = string.Empty;

    public string NameAr { get; set; } = string.Empty;
    public string NameEn { get; set; } = string.Empty;
    public string? ImageUrl { get; set; }
    public string? Description { get; set; }

    /// <summary>عدد اللاعبين في المباراة الواحدة.</summary>
    public int PlayersPerMatch { get; set; } = 2;

    public int DurationMinutes { get; set; } = 60;
    public bool IsActive { get; set; } = true;

    /// <summary>ترتيب العرض (الأصغر أولًا).</summary>
    public int SortOrder { get; set; } = 0;

    // Navigation
    public ICollection<SportSetting> Settings { get; set; } = [];
}
