namespace SportaApis.Helpers;

/// <summary>
/// كتالوج صلاحيات لوحة التحكم. كل مفتاح يمثّل عملية واحدة (عرض/تعديل/إجراء)،
/// ويُفرَض على الـ endpoints عبر <see cref="Attributes.RequirePermissionAttribute"/>.
/// الأدمن (UserType.Admin) يملك كل الصلاحيات ضمناً؛ الموظف (UserType.Staff)
/// يملك فقط ما يُسنَد له.
/// </summary>
public static class Permissions
{
    // ── الرئيسية ──────────────────────────────────────────────────────────────
    public const string DashboardView = "dashboard.view";

    // ── الألعاب ───────────────────────────────────────────────────────────────
    public const string SportsView = "sports.view";
    public const string SportsManage = "sports.manage";

    // ── المستويات والتقييم ────────────────────────────────────────────────────
    public const string AssessmentView = "assessment.view";
    public const string AssessmentManage = "assessment.manage";

    // ── الأندية ───────────────────────────────────────────────────────────────
    public const string VenuesView = "venues.view";
    public const string VenuesApprove = "venues.approve";

    /// <summary>حذف نادٍ وملاعبه — منفصلة عن الاعتماد لأنها لا رجعة فيها.</summary>
    public const string VenuesDelete = "venues.delete";

    // ── الملاعب ───────────────────────────────────────────────────────────────
    public const string CourtsView = "courts.view";
    public const string CourtsSuspend = "courts.suspend";
    public const string CourtsCommission = "courts.commission";

    /// <summary>حذف ملعب — منفصلة عن الإيقاف لأنها لا رجعة فيها.</summary>
    public const string CourtsDelete = "courts.delete";

    // ── المدربون ──────────────────────────────────────────────────────────────
    public const string CoachesView = "coaches.view";

    /// <summary>حذف حساب مدرب نهائياً — منفصلة عن العرض والإيقاف.</summary>
    public const string CoachesDelete = "coaches.delete";

    public const string CoachSpecializationsView = "coachSpecializations.view";
    public const string CoachSpecializationsManage = "coachSpecializations.manage";

    // ── المستويات والنقاط ─────────────────────────────────────────────────────
    public const string PointsSystemView = "pointsSystem.view";
    public const string PointsSystemManage = "pointsSystem.manage";

    // ── اللاعبون / المستخدمون ─────────────────────────────────────────────────
    public const string UsersView = "users.view";
    public const string UsersLock = "users.lock";
    public const string UsersPointsAdjust = "users.points.adjust";

    /// <summary>تعديل مستوى لاعب يدوياً — يتجاوز ما قرّره التقييم أو المدرب،
    /// ويغيّر المباريات التي يحقّ له دخولها، فلا يُمنح مع صلاحية العرض.</summary>
    public const string UsersLevelEdit = "users.level.edit";

    /// <summary>حذف حساب لاعب نهائياً — منفصلة عن الحظر لأنها لا رجعة فيها.</summary>
    public const string UsersDelete = "users.delete";

    // ── الدول والمدن والأحياء ─────────────────────────────────────────────────
    public const string LocationsView = "locations.view";
    public const string LocationsManage = "locations.manage";

    // ── مناطق الخدمة ──────────────────────────────────────────────────────────
    public const string ServiceZonesView = "serviceZones.view";
    public const string ServiceZonesManage = "serviceZones.manage";

    // ── المباريات ─────────────────────────────────────────────────────────────
    public const string MatchesView = "matches.view";

    /// <summary>حذف مباراة نهائياً — منفصلة عن العرض لأنها لا رجعة فيها.</summary>
    public const string MatchesDelete = "matches.delete";

    // ── الإعلانات ─────────────────────────────────────────────────────────────
    public const string AdsView = "ads.view";
    public const string AdsManage = "ads.manage";

    // ── الباقات ───────────────────────────────────────────────────────────────
    public const string PackagesView = "packages.view";
    public const string PackagesManage = "packages.manage";

    // ── الفواتير / الحجوزات ───────────────────────────────────────────────────
    public const string BookingsView = "bookings.view";

    // ── المالية ───────────────────────────────────────────────────────────────
    public const string FinanceView = "finance.view";
    public const string FinanceWithdrawalsManage = "finance.withdrawals.manage";
    public const string FinanceCommissionManage = "finance.commission.manage";

    // ── الخصومات والعروض ──────────────────────────────────────────────────────
    public const string DiscountsView = "discounts.view";
    public const string DiscountsManage = "discounts.manage";

    // ── اشتراكات الملاعب ──────────────────────────────────────────────────────
    public const string VenueSubscriptionsView = "venueSubscriptions.view";
    public const string VenueSubscriptionsManage = "venueSubscriptions.manage";

    // ── الإشعارات ─────────────────────────────────────────────────────────────
    public const string NotificationsView = "notifications.view";
    public const string NotificationsSend = "notifications.send";
    public const string NotificationsDelete = "notifications.delete";

    // ── الدردشة والدعم الفني ──────────────────────────────────────────────────
    public const string SupportView = "support.view";
    public const string SupportReply = "support.reply";

    // ── السياسات ──────────────────────────────────────────────────────────────
    public const string PoliciesView = "policies.view";
    public const string PoliciesManage = "policies.manage";

    // ── الإعدادات ─────────────────────────────────────────────────────────────
    public const string SettingsView = "settings.view";
    public const string SettingsManage = "settings.manage";

    // ── الموظفون والصلاحيات ───────────────────────────────────────────────────
    public const string StaffView = "staff.view";
    public const string StaffManage = "staff.manage";

    /// <summary>حذف الموظف نهائياً — منفصلة عن التعديل لأنها لا رجعة فيها.</summary>
    public const string StaffDelete = "staff.delete";

    /// <summary>
    /// الكتالوج المعروض في شاشة إضافة موظف — مجموعات بترتيب القائمة الجانبية.
    /// </summary>
    public static readonly IReadOnlyList<PermissionGroup> Catalog =
    [
        new("dashboard", "الرئيسية",
        [
            new(DashboardView, "عرض إحصائيات اللوحة"),
        ]),
        new("sports", "الألعاب",
        [
            new(SportsView, "عرض الألعاب وإعداداتها"),
            new(SportsManage, "إضافة وتعديل وحذف الألعاب"),
        ]),
        new("assessment", "المستويات والتقييم",
        [
            new(AssessmentView, "عرض المستويات والأسئلة"),
            new(AssessmentManage, "إضافة وتعديل وحذف المستويات والأسئلة"),
        ]),
        // الأندية والملاعب قسم واحد في اللوحة — الملاعب تُعرض داخل تفاصيل ناديها.
        new("venues", "الأندية والملاعب",
        [
            new(VenuesView, "عرض الأندية وبياناتها"),
            new(VenuesApprove, "اعتماد أو رفض الأندية"),
            new(VenuesDelete, "حذف الأندية"),
            new(CourtsView, "عرض الملاعب"),
            new(CourtsSuspend, "إيقاف أو تفعيل ملعب"),
            new(CourtsCommission, "تعديل نسبة سبورتا للملعب"),
            new(CourtsDelete, "حذف الملاعب"),
        ]),
        new("coaches", "المدربون",
        [
            new(CoachesView, "عرض المدربين"),
            new(CoachesDelete, "حذف حسابات المدربين"),
            new(CoachSpecializationsView, "عرض تخصصات المدربين"),
            new(CoachSpecializationsManage, "إضافة وتعديل وحذف التخصصات"),
        ]),
        new("pointsSystem", "المستويات والنقاط",
        [
            new(PointsSystemView, "عرض سُلَّم المستويات وقواعد النقاط"),
            new(PointsSystemManage, "تعديل المستويات وقيم نقاط المكافآت والمستوى"),
        ]),
        new("users", "اللاعبون",
        [
            new(UsersView, "عرض المستخدمين وبياناتهم"),
            new(UsersLock, "حظر أو فك حظر مستخدم"),
            new(UsersPointsAdjust, "تعديل رصيد نقاط مستخدم"),
            new(UsersLevelEdit, "تعديل مستوى لاعب"),
            new(UsersDelete, "حذف حسابات اللاعبين"),
        ]),
        new("locations", "الدول والمدن والأحياء",
        [
            new(LocationsView, "عرض الدول والمدن والأحياء"),
            new(LocationsManage, "إضافة وتعديل وحذف الدول والمدن والأحياء"),
        ]),
        new("serviceZones", "مناطق الخدمة",
        [
            new(ServiceZonesView, "عرض مناطق الخدمة على الخريطة"),
            new(ServiceZonesManage, "رسم وتعديل وحذف مناطق الخدمة ورسالة خارج النطاق"),
        ]),
        new("matches", "المباريات",
        [
            new(MatchesView, "عرض المباريات"),
            new(MatchesDelete, "حذف المباريات"),
        ]),
        new("ads", "الإعلانات",
        [
            new(AdsView, "عرض الإعلانات"),
            new(AdsManage, "إضافة وتعديل وحذف الإعلانات"),
        ]),
        new("packages", "الباقات",
        [
            new(PackagesView, "عرض الباقات"),
            new(PackagesManage, "إضافة وتعديل وحذف الباقات"),
        ]),
        new("bookings", "الفواتير والحجوزات",
        [
            new(BookingsView, "عرض الحجوزات والفواتير"),
        ]),
        new("finance", "المالية",
        [
            new(FinanceView, "عرض الإحصائيات والمعاملات المالية"),
            new(FinanceWithdrawalsManage, "الموافقة على طلبات السحب أو رفضها"),
            new(FinanceCommissionManage, "تعديل نسب العمولة (الملاعب والمدربين)"),
        ]),
        new("discounts", "الخصومات والعروض",
        [
            new(DiscountsView, "عرض الخصومات ومستفيديها"),
            new(DiscountsManage, "إضافة وتعديل الخصومات وتحديد المستفيدين"),
        ]),
        new("venueSubscriptions", "اشتراكات الملاعب",
        [
            new(VenueSubscriptionsView, "عرض تسعيرة الاشتراك والمشتركين"),
            new(VenueSubscriptionsManage, "تعديل تسعيرة اشتراك الملاعب"),
        ]),
        new("notifications", "الإشعارات",
        [
            new(NotificationsView, "عرض سجل الإشعارات"),
            new(NotificationsSend, "إرسال إشعار أو بث عام"),
            new(NotificationsDelete, "حذف الإشعارات"),
        ]),
        new("support", "الدردشة والدعم الفني",
        [
            new(SupportView, "عرض محادثات المستخدمين"),
            new(SupportReply, "الرد على المحادثات وإغلاقها"),
        ]),
        new("policies", "السياسات",
        [
            new(PoliciesView, "عرض السياسات"),
            new(PoliciesManage, "تعديل نصوص السياسات"),
        ]),
        new("settings", "الإعدادات",
        [
            new(SettingsView, "عرض إعدادات النظام"),
            new(SettingsManage, "تعديل إعدادات النظام"),
        ]),
        new("staff", "الموظفون والصلاحيات",
        [
            new(StaffView, "عرض الموظفين وصلاحياتهم"),
            new(StaffManage, "إضافة وتعديل الموظفين وتحديد صلاحياتهم"),
            new(StaffDelete, "حذف الموظفين نهائياً"),
        ]),
    ];

    /// <summary>كل المفاتيح الصالحة — تُستخدم للتحقق عند حفظ صلاحيات موظف.</summary>
    public static readonly IReadOnlySet<string> All =
        Catalog.SelectMany(g => g.Permissions).Select(p => p.Key).ToHashSet();

    public static bool IsValid(string key) => All.Contains(key);
}

/// <summary>مجموعة صلاحيات تخص قسماً واحداً من اللوحة.</summary>
public record PermissionGroup(string Key, string Label, IReadOnlyList<PermissionItem> Permissions);

/// <summary>صلاحية واحدة: مفتاحها ووصفها العربي.</summary>
public record PermissionItem(string Key, string Label);
