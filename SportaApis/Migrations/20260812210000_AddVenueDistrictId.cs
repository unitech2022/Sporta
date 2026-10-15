using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using SportaApis.Data;

#nullable disable

namespace SportaApis.Migrations
{
    /// <summary>
    /// يضيف معرّف الحي للنادي، ويعبّئ معرّفات الدولة/المدينة/الحي للأندية القديمة
    /// من أسمائها النصية. الأعمدة تبقى nullable لأن صفوفاً قديمة قد لا يوجد لها
    /// ما يطابقها في القوائم؛ الإلزام مفروض على الإنشاء في VenueService.
    /// </summary>
    [DbContext(typeof(AppDbContext))]
    [Migration("20260812210000_AddVenueDistrictId")]
    public partial class AddVenueDistrictId : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "DistrictId",
                table: "Venues",
                type: "int",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Venues_DistrictId",
                table: "Venues",
                column: "DistrictId");

            migrationBuilder.AddForeignKey(
                name: "FK_Venues_Districts_DistrictId",
                table: "Venues",
                column: "DistrictId",
                principalTable: "Districts",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);

            // ── Backfill ────────────────────────────────────────────────────────
            migrationBuilder.Sql(@"
                UPDATE Venues v
                JOIN Cities c ON v.City = c.NameAr OR v.City = c.NameEn
                SET v.CityId = c.Id
                WHERE v.CityId IS NULL;");

            migrationBuilder.Sql(@"
                UPDATE Venues v
                JOIN Cities c ON c.Id = v.CityId
                SET v.CountryId = c.CountryId
                WHERE v.CountryId IS NULL;");

            migrationBuilder.Sql(@"
                UPDATE Venues v
                JOIN Districts d
                  ON d.CityId = v.CityId
                 AND (v.District = d.NameAr OR v.District = d.NameEn)
                SET v.DistrictId = d.Id
                WHERE v.DistrictId IS NULL AND v.District IS NOT NULL;");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Venues_Districts_DistrictId",
                table: "Venues");

            migrationBuilder.DropIndex(
                name: "IX_Venues_DistrictId",
                table: "Venues");

            migrationBuilder.DropColumn(
                name: "DistrictId",
                table: "Venues");
        }
    }
}
