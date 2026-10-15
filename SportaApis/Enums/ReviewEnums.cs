namespace SportaApis.Enums;

/// <summary>ما يُقيَّم: لاعب أو مدرب (معرّف المستخدم) أو ملعب (معرّف الملعب).</summary>
public enum ReviewTargetType
{
    Player = 0,
    Coach = 1,
    Court = 2,
}

/// <summary>التجربة التي جرى فيها التقييم — المرجع معرّفها.</summary>
public enum ReviewContextType
{
    /// <summary>مباراة / أمريكانو / بطولة (معرّف المباراة الأساسية).</summary>
    Match = 0,
    /// <summary>حجز ملعب مباشر.</summary>
    Booking = 1,
    /// <summary>جلسة تدريب.</summary>
    CoachSession = 2,
}

/// <summary>صفة المقيِّم في تلك التجربة.</summary>
public enum ReviewerRole
{
    Player = 0,
    Coach = 1,
    VenueOwner = 2,
}
