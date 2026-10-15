using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Microsoft.Extensions.Configuration;

namespace SportaApis.Data;

/// <summary>
/// يبني <see cref="AppDbContext"/> لأوامر EF وقت التصميم (migrations add،
/// migrations script، database update).
///
/// وجوده ضروري لأن <c>Program.cs</c> يستعمل <c>ServerVersion.AutoDetect</c>،
/// وهو يفتح اتصالاً فعلياً بالقاعدة لحظة بناء المضيف. بدون هذا المصنع كان أي
/// أمر EF يفشل إذا لم تكن قاعدة التطوير شغّالة — بما فيه توليد سكربت الترقية
/// في <c>deploy.sh</c>، فيتعطّل نشرٌ لا علاقة له بالقاعدة المحلية أصلاً.
///
/// EF يفضّل هذا المصنع على <c>Program.cs</c> تلقائياً، فلا يمسّ هذا الملف
/// سلوك التشغيل إطلاقاً.
/// </summary>
public class DesignTimeDbContextFactory : IDesignTimeDbContextFactory<AppDbContext>
{
    /// <summary>
    /// النسخة المفترضة عند توليد الـ SQL. تُقرأ من <c>Database:ServerVersion</c>
    /// أو من متغيّر البيئة <c>MYSQL_VERSION</c>.
    ///
    /// الافتراضي 8.0 عمداً: SQL مُولَّد لـ 8.0 يعمل على 8.0 وما بعدها، بينما
    /// SQL مُولَّد لنسخة أحدث قد يحمل صيغة لا يفهمها خادم أقدم. والاتجاه الآمن
    /// هو الأقدم. إن كان خادم الإنتاج أقدم من 8.0 فاضبط القيمة صراحةً.
    /// </summary>
    private const string DefaultServerVersion = "8.0.0";

    public AppDbContext CreateDbContext(string[] args)
    {
        var config = new ConfigurationBuilder()
            .SetBasePath(Directory.GetCurrentDirectory())
            .AddJsonFile("appsettings.json", optional: true)
            .AddJsonFile(
                $"appsettings.{Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") ?? "Development"}.json",
                optional: true)
            .AddEnvironmentVariables()
            .Build();

        // سلسلة الاتصال قد تكون وهمية تماماً: توليد المايجريشن ومقارنته باللقطة
        // عمليتان محليتان لا تلمسان خادماً. تُستعمل فعلياً في database update وحده.
        var connectionString =
            config.GetConnectionString("DefaultConnection")
            ?? "server=localhost;database=SportaDb;user=root;password=";

        var version = config["Database:ServerVersion"]
            ?? Environment.GetEnvironmentVariable("MYSQL_VERSION")
            ?? DefaultServerVersion;

        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseMySql(connectionString, ServerVersion.Parse($"{version}-mysql"))
            .Options;

        return new AppDbContext(options);
    }
}
