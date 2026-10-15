namespace SportaApis.DTOs;

/// <summary>حالة قائمة انتظار حدث كما يراها المستخدم الحالي.</summary>
public class WaitlistStatusDto
{
    /// <summary>هل للحدث قائمة انتظار أصلاً (لا لأمريكانو الفرق ولا للبطولة).</summary>
    public bool Supported { get; set; }

    /// <summary>القائمة تقبل تسجيلاً الآن (الحدث مفتوح ولم يبدأ).</summary>
    public bool IsOpen { get; set; }

    /// <summary>عدد المنتظرين (ومنهم من عُرض عليه مقعد).</summary>
    public int Count { get; set; }

    /// <summary>ترتيب المستخدم في القائمة (1 = الأول)؛ null إن لم يكن فيها.</summary>
    public int? Position { get; set; }

    /// <summary>للمستخدم مقعد محجوز الآن ينتظر أن يطلب الانضمام.</summary>
    public bool OfferActive { get; set; }

    /// <summary>الدقائق الباقية من حجز المقعد له؛ null بلا عرض.</summary>
    public int? OfferMinutesLeft { get; set; }

    /// <summary>
    /// يوجد مقعد شاغر لكنه محجوز لمنتظرين قبله — طلب الانضمام يُرفض، والحل
    /// التسجيل في القائمة.
    /// </summary>
    public bool SeatReservedForOthers { get; set; }

    /// <summary>يستطيع التسجيل في القائمة الآن.</summary>
    public bool CanJoin { get; set; }

    /// <summary>مدة حجز المقعد لمن يأتي دوره (بالدقائق).</summary>
    public int OfferWindowMinutes { get; set; }
}
