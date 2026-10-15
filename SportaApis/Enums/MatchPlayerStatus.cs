namespace SportaApis.Enums;

public enum MatchPlayerStatus
{
    Pending = 0,  // طلب انضمام بانتظار موافقة المنشئ
    Approved = 1, // عضو مُعتمد في المباراة
    Invited = 2,  // دعوة من صديق بانتظار قبول المدعو
}
