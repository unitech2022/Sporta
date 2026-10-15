using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SportaApis.Migrations
{
    /// <summary>
    /// عملية دفع واحدة لا تشحن المحفظة مرتين. مع بوابة FINY يصل تأكيدان لنفس
    /// العملية — من التطبيق ومن الـ webhook — وقد يتزامنان فيمرّان معاً من فحص
    /// «هل عولجت من قبل؟» قبل أن يحفظ أيٌّ منهما. القيد يجعل الثانية تفشل.
    /// </summary>
    public partial class UniqueWalletPaymentReference : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // تكرار قائم قبل القيد يمنع إنشاءه أصلاً. لا يُحذف صفٌّ هنا — تُفكّ
            // صلته بالعملية فقط، فيبقى أثره المالي وسجلّه كما هما.
            migrationBuilder.Sql("""
                UPDATE WalletTransactions t
                JOIN (
                    SELECT PaymentReference, MIN(Id) AS KeepId
                    FROM WalletTransactions
                    WHERE PaymentReference IS NOT NULL
                    GROUP BY PaymentReference
                    HAVING COUNT(*) > 1
                ) d ON d.PaymentReference = t.PaymentReference
                SET t.PaymentReference = CONCAT(LEFT(t.PaymentReference, 80), '_dup', t.Id)
                WHERE t.Id <> d.KeepId;
                """);

            migrationBuilder.AlterColumn<string>(
                name: "PaymentReference",
                table: "WalletTransactions",
                type: "varchar(100)",
                maxLength: 100,
                nullable: true,
                oldClrType: typeof(string),
                oldType: "longtext",
                oldNullable: true)
                .Annotation("MySql:CharSet", "utf8mb4")
                .OldAnnotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.CreateIndex(
                name: "IX_WalletTransactions_PaymentReference",
                table: "WalletTransactions",
                column: "PaymentReference",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_WalletTransactions_PaymentReference",
                table: "WalletTransactions");

            migrationBuilder.AlterColumn<string>(
                name: "PaymentReference",
                table: "WalletTransactions",
                type: "longtext",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "varchar(100)",
                oldMaxLength: 100,
                oldNullable: true)
                .Annotation("MySql:CharSet", "utf8mb4")
                .OldAnnotation("MySql:CharSet", "utf8mb4");
        }
    }
}
