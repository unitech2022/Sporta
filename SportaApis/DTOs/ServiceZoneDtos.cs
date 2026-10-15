namespace SportaApis.DTOs;

public class ServiceZonePointDto
{
    public double Lat { get; set; }
    public double Lng { get; set; }
}

/// <summary>طلب إنشاء/تعديل منطقة خدمة من لوحة التحكم.</summary>
public class SaveServiceZoneRequest
{
    public string NameAr { get; set; } = string.Empty;
    public string NameEn { get; set; } = string.Empty;
    public List<ServiceZonePointDto> Polygon { get; set; } = [];
    public string? Color { get; set; }
    public bool IsActive { get; set; } = true;
}

/// <summary>منطقة خدمة كما تُعرض في اللوحة (مع المضلّع).</summary>
public class ServiceZoneDto
{
    public int Id { get; set; }
    public string NameAr { get; set; } = string.Empty;
    public string NameEn { get; set; } = string.Empty;
    public List<ServiceZonePointDto> Polygon { get; set; } = [];
    public string? Color { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}

/// <summary>نتيجة فحص نقطة (موقع المستخدم) ضد مناطق الخدمة.</summary>
public class ServiceZoneCheckDto
{
    /// <summary>هل توجد مناطق مفعّلة أصلاً؟ (false = التطبيق يعمل في كل مكان)</summary>
    public bool HasZones { get; set; }

    /// <summary>هل النقطة داخل نطاق الخدمة؟</summary>
    public bool InsideServiceArea { get; set; } = true;

    /// <summary>اسم المنطقة التي تحتوي النقطة (إن وُجدت).</summary>
    public string? ZoneNameAr { get; set; }
    public string? ZoneNameEn { get; set; }

    /// <summary>رسالة «خارج النطاق» القابلة للتعديل من اللوحة.</summary>
    public string MessageAr { get; set; } = string.Empty;
    public string MessageEn { get; set; } = string.Empty;
}

/// <summary>نص رسالة «خارج نطاق الخدمة» بالعربية والإنجليزية.</summary>
public class ServiceZoneMessageDto
{
    public string ValueAr { get; set; } = string.Empty;
    public string ValueEn { get; set; } = string.Empty;
}
