namespace SportaApis.Enums;

/// <summary>
/// نوعا النقاط في سبورتا: نقاط المكافآت (تُكسب بالنشاط وتُستبدل برصيد محفظة)
/// ونقاط المستوى (تتحرك صعوداً وهبوطاً بنتائج المباريات ولا تُستبدل).
/// </summary>
public enum PointsKind
{
    Reward = 0,
    Level = 1,
}
