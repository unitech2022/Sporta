using System;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using SportaApis.Data;

#nullable disable

namespace SportaApis.Migrations
{
    /// <summary>
    /// موافقة الأدمن على دوري المدرب وصاحب الملعب. الأدوار الموجودة تُعتبر معتمدة
    /// (القيمة الافتراضية للعمود) حتى لا يُقفل أحد بأثر رجعي.
    /// </summary>
    [DbContext(typeof(AppDbContext))]
    [Migration("20260812220000_AddUserRoleApproval")]
    public partial class AddUserRoleApproval : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "IsApproved",
                table: "UserRoles",
                type: "tinyint(1)",
                nullable: false,
                defaultValue: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "ApprovedAt",
                table: "UserRoles",
                type: "datetime(6)",
                nullable: true);

            // الأدوار القائمة قبل هذه الميزة تبقى فعّالة، وتاريخ الاعتماد = تاريخ إنشائها.
            migrationBuilder.Sql(
                "UPDATE UserRoles SET IsApproved = 1, ApprovedAt = CreatedAt WHERE ApprovedAt IS NULL;");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(name: "ApprovedAt", table: "UserRoles");
            migrationBuilder.DropColumn(name: "IsApproved", table: "UserRoles");
        }
    }
}
