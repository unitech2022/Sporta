using System.Text.Json;

namespace SportaApis.Helpers;

/// <summary>
/// أدوات المضلّعات الجغرافية لمناطق الخدمة. المضلّع يُخزَّن كـ JSON
/// [[lat,lng],...] ولا نستخدم أنواع MySQL المكانية حفاظاً على بساطة الترحيل.
/// </summary>
public static class GeoPolygonHelper
{
    /// <summary>يحوّل JSON المخزَّن إلى قائمة رؤوس (lat, lng). يعيد قائمة فارغة عند أي خطأ.</summary>
    public static List<(double Lat, double Lng)> Parse(string? polygonJson)
    {
        var result = new List<(double, double)>();
        if (string.IsNullOrWhiteSpace(polygonJson)) return result;
        try
        {
            var raw = JsonSerializer.Deserialize<List<double[]>>(polygonJson);
            if (raw == null) return result;
            foreach (var p in raw)
            {
                if (p is { Length: >= 2 } && IsValidLat(p[0]) && IsValidLng(p[1]))
                    result.Add((p[0], p[1]));
            }
        }
        catch (JsonException)
        {
            // JSON تالف → مضلّع فارغ = لا يحتوي أي نقطة
        }
        return result;
    }

    public static string Serialize(IEnumerable<(double Lat, double Lng)> points)
        => JsonSerializer.Serialize(points.Select(p => new[] { p.Lat, p.Lng }));

    public static bool IsValidLat(double lat) => !double.IsNaN(lat) && lat >= -90 && lat <= 90;
    public static bool IsValidLng(double lng) => !double.IsNaN(lng) && lng >= -180 && lng <= 180;

    /// <summary>
    /// اختبار احتواء النقطة داخل المضلّع بطريقة Ray casting. النقاط الواقعة
    /// على الحدود تُعامل كأنها داخل المضلّع. أقل من 3 رؤوس = لا يحتوي شيئاً.
    /// </summary>
    public static bool Contains(IReadOnlyList<(double Lat, double Lng)> polygon, double lat, double lng)
    {
        if (polygon == null || polygon.Count < 3) return false;

        var inside = false;
        var n = polygon.Count;
        for (int i = 0, j = n - 1; i < n; j = i++)
        {
            double yi = polygon[i].Lat, xi = polygon[i].Lng;
            double yj = polygon[j].Lat, xj = polygon[j].Lng;

            if (OnSegment(xi, yi, xj, yj, lng, lat)) return true;

            var intersect = ((yi > lat) != (yj > lat)) &&
                            (lng < (xj - xi) * (lat - yi) / (yj - yi) + xi);
            if (intersect) inside = !inside;
        }
        return inside;
    }

    private static bool OnSegment(double x1, double y1, double x2, double y2, double px, double py)
    {
        const double eps = 1e-9;
        var cross = (px - x1) * (y2 - y1) - (py - y1) * (x2 - x1);
        if (Math.Abs(cross) > eps) return false;
        return px >= Math.Min(x1, x2) - eps && px <= Math.Max(x1, x2) + eps &&
               py >= Math.Min(y1, y2) - eps && py <= Math.Max(y1, y2) + eps;
    }
}
