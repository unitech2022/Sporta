namespace SportaApis.Enums;

public enum MatchStatus
{
    Open = 0,       // مفتوحة - تحتاج لاعبين
    Full = 1,       // مكتملة - 4 لاعبين
    InProgress = 2, // جارية
    Completed = 3,  // منتهية
    Cancelled = 4   // ملغاة
}
