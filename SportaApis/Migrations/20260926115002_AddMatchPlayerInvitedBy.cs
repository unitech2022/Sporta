using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SportaApis.Migrations
{
    /// <inheritdoc />
    public partial class AddMatchPlayerInvitedBy : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "InvitedById",
                table: "MatchPlayers",
                type: "int",
                nullable: true);

            // دعوات الشريك المعلّقة التي أرسلها المنشئ عند إنشاء الأمريكانو/البطولة:
            // المدعو في فريق المنشئ نفسه ⇐ الداعي هو المنشئ (دعوته تكفي للانضمام).
            // غيرها يبقى null فيُعامل كدعوة من غير المنشئ (طلب ينتظر موافقته).
            migrationBuilder.Sql(@"
UPDATE MatchPlayers mp
JOIN Matches m ON m.Id = mp.MatchId
JOIN MatchPlayers c ON c.MatchId = mp.MatchId AND c.UserId = m.CreatorId
SET mp.InvitedById = m.CreatorId
WHERE mp.Status = 2 AND mp.InvitedById IS NULL
  AND mp.Team IS NOT NULL AND c.Team = mp.Team;");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "InvitedById",
                table: "MatchPlayers");
        }
    }
}
