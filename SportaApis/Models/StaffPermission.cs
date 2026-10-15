namespace SportaApis.Models;

/// <summary>
/// صلاحية واحدة ممنوحة لموظف — القيمة مفتاح من
/// <see cref="Helpers.Permissions.All"/> (مثل "venues.approve").
/// </summary>
public class StaffPermission : BaseEntity
{
    public int StaffProfileId { get; set; }
    public StaffProfile StaffProfile { get; set; } = null!;

    public string Permission { get; set; } = string.Empty;
}
