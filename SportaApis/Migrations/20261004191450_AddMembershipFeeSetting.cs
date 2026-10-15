using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SportaApis.Migrations
{
    /// <inheritdoc />
    public partial class AddMembershipFeeSetting : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // نسبة سبورتا من إيراد عضويات الأندية — تُدار من الإعدادات.
            migrationBuilder.Sql(@"
INSERT INTO SystemSettings (`Key`, NameAr, NameEn, Type, ValueAr, ValueEn, IsSensitive, CreatedAt)
SELECT 'membership_commission_percent', 'نسبة سبورتا من عضويات الأندية (%)', 'Sporta Fee on Club Memberships (%)', 2, '10', '10', 0, UTC_TIMESTAMP()
WHERE NOT EXISTS (SELECT 1 FROM SystemSettings WHERE `Key` = 'membership_commission_percent');");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("DELETE FROM SystemSettings WHERE `Key` = 'membership_commission_percent';");
        }
    }
}
