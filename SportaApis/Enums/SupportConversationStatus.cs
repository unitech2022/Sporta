namespace SportaApis.Enums;

public enum SupportConversationStatus
{
    Open = 0,   // محادثة مفتوحة - الطرفان يستطيعان الكتابة
    Closed = 1  // أغلقها الدعم - تبقى للقراءة حتى يكتب المستخدم فتُفتح تلقائياً
}
