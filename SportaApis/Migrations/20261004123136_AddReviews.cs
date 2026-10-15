using System;
using Microsoft.EntityFrameworkCore.Metadata;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SportaApis.Migrations
{
    /// <inheritdoc />
    public partial class AddReviews : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "ReviewPromptSentAt",
                table: "CoachSessions",
                type: "datetime(6)",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "ReviewPromptSentAt",
                table: "Bookings",
                type: "datetime(6)",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "Reviews",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("MySql:ValueGenerationStrategy", MySqlValueGenerationStrategy.IdentityColumn),
                    RaterId = table.Column<int>(type: "int", nullable: false),
                    RaterRole = table.Column<int>(type: "int", nullable: false),
                    TargetType = table.Column<int>(type: "int", nullable: false),
                    TargetId = table.Column<int>(type: "int", nullable: false),
                    ContextType = table.Column<int>(type: "int", nullable: false),
                    ContextId = table.Column<int>(type: "int", nullable: false),
                    Score = table.Column<int>(type: "int", nullable: false),
                    Tags = table.Column<string>(type: "varchar(200)", maxLength: 200, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    Comment = table.Column<string>(type: "varchar(500)", maxLength: 500, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    CreatedAt = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime(6)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Reviews", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Reviews_Users_RaterId",
                        column: x => x.RaterId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                })
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.CreateIndex(
                name: "IX_Reviews_ContextType_ContextId_RaterId_TargetType_TargetId",
                table: "Reviews",
                columns: new[] { "ContextType", "ContextId", "RaterId", "TargetType", "TargetId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Reviews_RaterId",
                table: "Reviews",
                column: "RaterId");

            migrationBuilder.CreateIndex(
                name: "IX_Reviews_TargetType_TargetId_CreatedAt",
                table: "Reviews",
                columns: new[] { "TargetType", "TargetId", "CreatedAt" });

            // ── نقل التقييمات القائمة إلى الجدول الموحّد ──
            // تقييمات الملاعب (CourtRatings): لاعب ← ملعب في مباراة.
            migrationBuilder.Sql(@"
INSERT IGNORE INTO Reviews (RaterId, RaterRole, TargetType, TargetId, ContextType, ContextId, Score, Tags, Comment, CreatedAt, UpdatedAt)
SELECT UserId, 0, 2, CourtId, 0, MatchId, Score, Tags, Comment, CreatedAt, UpdatedAt FROM CourtRatings;");

            // تقييم الزملاء مع النتيجة (MatchRatings): لاعب ← لاعب.
            migrationBuilder.Sql(@"
INSERT IGNORE INTO Reviews (RaterId, RaterRole, TargetType, TargetId, ContextType, ContextId, Score, Tags, Comment, CreatedAt, UpdatedAt)
SELECT RaterId, 0, 0, RatedUserId, 0, MatchId, LEAST(GREATEST(Score, 1), 5), NULL, NULL, CreatedAt, UpdatedAt FROM MatchRatings;");

            // جلسات التدريب: لاعب ← مدرب.
            migrationBuilder.Sql(@"
INSERT IGNORE INTO Reviews (RaterId, RaterRole, TargetType, TargetId, ContextType, ContextId, Score, Tags, Comment, CreatedAt, UpdatedAt)
SELECT s.PlayerId, 0, 1, cp.UserId, 2, s.Id, LEAST(GREATEST(s.PlayerRating, 1), 5), NULL, LEFT(s.PlayerReview, 500), COALESCE(s.UpdatedAt, s.CreatedAt), NULL
FROM CoachSessions s JOIN CoachProfiles cp ON cp.Id = s.CoachProfileId
WHERE s.PlayerRating IS NOT NULL;");

            // جلسات التدريب: مدرب ← لاعب.
            migrationBuilder.Sql(@"
INSERT IGNORE INTO Reviews (RaterId, RaterRole, TargetType, TargetId, ContextType, ContextId, Score, Tags, Comment, CreatedAt, UpdatedAt)
SELECT cp.UserId, 1, 0, s.PlayerId, 2, s.Id, LEAST(GREATEST(s.CoachRating, 1), 5), NULL, LEFT(s.CoachReview, 500), COALESCE(s.UpdatedAt, s.CreatedAt), NULL
FROM CoachSessions s JOIN CoachProfiles cp ON cp.Id = s.CoachProfileId
WHERE s.CoachRating IS NOT NULL;");

            // سمعة اللاعب = متوسط كل تقييماته من الجدول الموحّد.
            migrationBuilder.Sql(@"
UPDATE PlayerProfiles p
LEFT JOIN (SELECT TargetId, AVG(Score) AS a, COUNT(*) AS c FROM Reviews WHERE TargetType = 0 GROUP BY TargetId) r
  ON r.TargetId = p.UserId
SET p.PeerRatingAverage = COALESCE(r.a, 0), p.PeerRatingCount = COALESCE(r.c, 0);");

            migrationBuilder.DropTable(
                name: "CourtRatings");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Reviews");

            migrationBuilder.DropColumn(
                name: "ReviewPromptSentAt",
                table: "CoachSessions");

            migrationBuilder.DropColumn(
                name: "ReviewPromptSentAt",
                table: "Bookings");

            migrationBuilder.CreateTable(
                name: "CourtRatings",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("MySql:ValueGenerationStrategy", MySqlValueGenerationStrategy.IdentityColumn),
                    CourtId = table.Column<int>(type: "int", nullable: false),
                    MatchId = table.Column<int>(type: "int", nullable: false),
                    UserId = table.Column<int>(type: "int", nullable: false),
                    Comment = table.Column<string>(type: "varchar(500)", maxLength: 500, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    CreatedAt = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    Score = table.Column<int>(type: "int", nullable: false),
                    Tags = table.Column<string>(type: "varchar(200)", maxLength: 200, nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    UpdatedAt = table.Column<DateTime>(type: "datetime(6)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CourtRatings", x => x.Id);
                    table.ForeignKey(
                        name: "FK_CourtRatings_Courts_CourtId",
                        column: x => x.CourtId,
                        principalTable: "Courts",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_CourtRatings_Matches_MatchId",
                        column: x => x.MatchId,
                        principalTable: "Matches",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_CourtRatings_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                })
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.CreateIndex(
                name: "IX_CourtRatings_CourtId_CreatedAt",
                table: "CourtRatings",
                columns: new[] { "CourtId", "CreatedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_CourtRatings_MatchId_UserId",
                table: "CourtRatings",
                columns: new[] { "MatchId", "UserId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_CourtRatings_UserId",
                table: "CourtRatings",
                column: "UserId");
        }
    }
}
