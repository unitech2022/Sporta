using Microsoft.EntityFrameworkCore.Metadata;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SportaApis.Migrations
{
    /// <inheritdoc />
    public partial class AddEventChatRichMessages : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "AttachmentName",
                table: "EventChatMessages",
                type: "varchar(200)",
                maxLength: 200,
                nullable: true)
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.AddColumn<long>(
                name: "AttachmentSize",
                table: "EventChatMessages",
                type: "bigint",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "AttachmentType",
                table: "EventChatMessages",
                type: "varchar(10)",
                maxLength: 10,
                nullable: true)
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.AddColumn<string>(
                name: "AttachmentUrl",
                table: "EventChatMessages",
                type: "varchar(300)",
                maxLength: 300,
                nullable: true)
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.AddColumn<string>(
                name: "MentionedUserIds",
                table: "EventChatMessages",
                type: "varchar(500)",
                maxLength: 500,
                nullable: true)
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.AddColumn<int>(
                name: "ReplyToId",
                table: "EventChatMessages",
                type: "int",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "EventChatReactions",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("MySql:ValueGenerationStrategy", MySqlValueGenerationStrategy.IdentityColumn),
                    MessageId = table.Column<int>(type: "int", nullable: false),
                    UserId = table.Column<int>(type: "int", nullable: false),
                    Emoji = table.Column<string>(type: "varchar(16)", maxLength: 16, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_EventChatReactions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_EventChatReactions_EventChatMessages_MessageId",
                        column: x => x.MessageId,
                        principalTable: "EventChatMessages",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                })
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.CreateIndex(
                name: "IX_EventChatReactions_MessageId_UserId",
                table: "EventChatReactions",
                columns: new[] { "MessageId", "UserId" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "EventChatReactions");

            migrationBuilder.DropColumn(
                name: "AttachmentName",
                table: "EventChatMessages");

            migrationBuilder.DropColumn(
                name: "AttachmentSize",
                table: "EventChatMessages");

            migrationBuilder.DropColumn(
                name: "AttachmentType",
                table: "EventChatMessages");

            migrationBuilder.DropColumn(
                name: "AttachmentUrl",
                table: "EventChatMessages");

            migrationBuilder.DropColumn(
                name: "MentionedUserIds",
                table: "EventChatMessages");

            migrationBuilder.DropColumn(
                name: "ReplyToId",
                table: "EventChatMessages");
        }
    }
}
