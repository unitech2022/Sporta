import { useState } from "react";
import { Bell, MapPin, Users, Calendar, Award, Clock, Map, Star, Trophy, Flame, Zap, MessageCircle, Globe, UserPlus, Plus, AlertTriangle, Trash2, ChevronLeft } from "lucide-react";
import logo from "../../imports/new_logo.png";
import CoachHomePage from "./CoachHomePage";
import VenueHomePage from "./VenueHomePage";
import PointsSystemPage from "./PointsSystemPage";
function HomePage({ onNavigate, activeRole: propActiveRole, onRoleChange }) {
  const [showRoleMenu, setShowRoleMenu] = useState(false);
  const [showAddRoleMenu, setShowAddRoleMenu] = useState(false);
  const [deleteWarning, setDeleteWarning] = useState(null);
  const [showPointsPage, setShowPointsPage] = useState(false);
  const [friendRequests, setFriendRequests] = useState([]);
  const [currentRole, setCurrentRole] = useState(() => {
    return propActiveRole || localStorage.getItem("currentRole") || "player";
  });
  const [userRoles] = useState(() => {
    const saved = localStorage.getItem("userRoles");
    if (saved) {
      const roles = JSON.parse(saved);
      return roles;
    }
    return [{ type: "player", completed: false }];
  });
  const handleRoleChange = (role) => {
    setCurrentRole(role);
    localStorage.setItem("currentRole", role);
    setShowRoleMenu(false);
    onRoleChange?.(role);
  };
  const handleDeleteRole = (role) => {
    const saved = localStorage.getItem("userRoles");
    const existing = saved ? JSON.parse(saved) : [];
    const updated = existing.filter((r) => r.type !== role);
    localStorage.setItem("userRoles", JSON.stringify(updated));
    if (currentRole === role && updated.length > 0) {
      const next = updated[0].type;
      setCurrentRole(next);
      localStorage.setItem("currentRole", next);
      onRoleChange?.(next);
    }
    setDeleteWarning(null);
    window.location.reload();
  };
  const getRoleName = (role) => {
    switch (role) {
      case "player":
        return "\u0644\u0627\u0639\u0628";
      case "coach":
        return "\u0645\u062F\u0631\u0628";
      case "venue":
        return "\u0645\u0627\u0644\u0643 \u0645\u0644\u0639\u0628";
      default:
        return "\u0644\u0627\u0639\u0628";
    }
  };
  const handleAddFriend = (friendId) => {
    setFriendRequests([...friendRequests, friendId]);
  };
  const renderPlayerDashboard = () => <>
    <div className="px-6 py-6 space-y-6">
      {
    /* بانر نظام النقاط */
  }
      <button
    onClick={() => setShowPointsPage(true)}
    className="w-full relative overflow-hidden rounded-2xl p-4 flex items-center justify-between shadow-md"
    style={{ background: "linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%)" }}
  >
        {
    /* دوائر زخرفية */
  }
        <div className="absolute -top-4 -left-4 w-20 h-20 bg-yellow-400/15 rounded-full blur-lg" />
        <div className="absolute -bottom-4 left-1/3 w-16 h-16 bg-primary/20 rounded-full blur-lg" />
        {
    /* نجوم */
  }
        {[...Array(6)].map((_, i) => <div
    key={i}
    className="absolute w-0.5 h-0.5 bg-white rounded-full opacity-70"
    style={{ top: `${15 + i * 15 % 70}%`, left: `${10 + i * 14 % 75}%` }}
  />)}
        <div className="flex items-center gap-3 relative z-10">
          <ChevronLeft className="w-5 h-5 text-white/60" />
        </div>
        <div className="flex items-center gap-3 relative z-10">
          <div className="text-right">
            <p className="text-white text-sm leading-tight">استكشف نظام النقاط</p>
            <p className="text-yellow-400 text-xs mt-0.5">اكسب نقاطاً وارتقِ للمستويات الأعلى ✨</p>
          </div>
          <div className="w-11 h-11 bg-gradient-to-br from-yellow-400 to-orange-500 rounded-xl flex items-center justify-center shadow-lg shadow-yellow-500/30 flex-shrink-0">
            <Trophy className="w-6 h-6 text-white" />
          </div>
        </div>
      </button>

      {
    /* قسم خريطة الملاعب الرياضية */
  }
      <div>
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-xl text-secondary font-medium">خريطة الملاعب الرياضية</h2>
        </div>

        {
    /* الخريطة */
  }
        <button
    onClick={() => onNavigate("courts")}
    className="w-full bg-gradient-to-br from-blue-100 via-blue-50 to-green-50 rounded-2xl h-64 overflow-hidden relative shadow-lg border-2 border-blue-200/50 hover:shadow-xl transition-all"
  >
          {
    /* خطوط الخريطة */
  }
          <div className="absolute inset-0">
            <div className="absolute top-0 left-0 right-0 h-px bg-blue-300/30" />
            <div className="absolute top-1/4 left-0 right-0 h-px bg-blue-300/30" />
            <div className="absolute top-1/2 left-0 right-0 h-px bg-blue-300/40" />
            <div className="absolute top-3/4 left-0 right-0 h-px bg-blue-300/30" />

            <div className="absolute top-0 bottom-0 left-0 w-px bg-blue-300/30" />
            <div className="absolute top-0 bottom-0 left-1/4 w-px bg-blue-300/30" />
            <div className="absolute top-0 bottom-0 left-1/2 w-px bg-blue-300/40" />
            <div className="absolute top-0 bottom-0 left-3/4 w-px bg-blue-300/30" />
          </div>

          {
    /* علامات الملاعب */
  }
          <div className="absolute top-1/3 right-1/4">
            <div className="w-8 h-8 bg-primary rounded-full border-4 border-white shadow-lg flex items-center justify-center animate-pulse">
              <MapPin className="w-4 h-4 text-white" />
            </div>
            <div className="absolute -top-8 right-1/2 transform translate-x-1/2 bg-white px-2 py-1 rounded-lg shadow-md whitespace-nowrap text-xs text-secondary">
              نادي البادل الملكي
            </div>
          </div>

          <div className="absolute top-1/2 left-1/3">
            <div className="w-7 h-7 bg-green-500 rounded-full border-4 border-white shadow-lg flex items-center justify-center">
              <MapPin className="w-3.5 h-3.5 text-white" />
            </div>
          </div>

          <div className="absolute bottom-1/4 right-1/3">
            <div className="w-7 h-7 bg-orange-500 rounded-full border-4 border-white shadow-lg flex items-center justify-center">
              <MapPin className="w-3.5 h-3.5 text-white" />
            </div>
          </div>

          <div className="absolute top-1/4 left-1/4">
            <div className="w-7 h-7 bg-purple-500 rounded-full border-4 border-white shadow-lg flex items-center justify-center">
              <MapPin className="w-3.5 h-3.5 text-white" />
            </div>
          </div>

          <div className="absolute bottom-1/3 left-1/2">
            <div className="w-7 h-7 bg-blue-500 rounded-full border-4 border-white shadow-lg flex items-center justify-center">
              <MapPin className="w-3.5 h-3.5 text-white" />
            </div>
          </div>

          {
    /* نقطة الموقع الحالي */
  }
          <div className="absolute top-1/2 right-1/2 transform -translate-x-1/2 -translate-y-1/2">
            <div className="w-4 h-4 bg-blue-600 rounded-full border-3 border-white shadow-lg relative">
              <div className="absolute inset-0 bg-blue-600 rounded-full animate-ping opacity-75" />
            </div>
          </div>

          {
    /* طبقة تدرجية */
  }
          <div className="absolute inset-0 bg-gradient-to-br from-transparent via-blue-100/20 to-green-100/30" />

          {
    /* عداد الملاعب */
  }
          <div className="absolute bottom-4 left-4 bg-white/95 backdrop-blur-sm px-4 py-2 rounded-full shadow-lg">
            <div className="flex items-center gap-2">
              <MapPin className="w-4 h-4 text-primary" />
              <span className="text-sm text-secondary font-medium">8 ملاعب قريبة</span>
            </div>
          </div>

          {
    /* زر التكبير */
  }
          <div className="absolute top-4 left-4 bg-white/95 backdrop-blur-sm p-2 rounded-lg shadow-lg">
            <Map className="w-5 h-5 text-primary" />
          </div>
        </button>
      </div>

      {
    /* قسم نبض المجتمع الرياضي */
  }
      <div>
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-xl text-secondary font-medium">نبض المجتمع الرياضي</h2>
          <button className="text-sm text-primary">عرض الكل</button>
        </div>

        <div className="space-y-3">
          {
    /* تحديث 1 */
  }
          <div className="bg-gradient-to-br from-orange-50 to-orange-100/50 border border-orange-200 rounded-2xl p-4">
            <div className="flex items-start gap-3">
              <div className="w-10 h-10 bg-orange-500 rounded-full flex items-center justify-center flex-shrink-0">
                <Flame className="w-5 h-5 text-white" />
              </div>
              <div className="flex-1">
                <p className="text-sm text-secondary mb-1">
                  <span className="font-medium">أحمد</span> وصل لمستوى <span className="font-bold text-orange-600">6</span>
                </p>
                <p className="text-xs text-muted-foreground">منذ ساعتين</p>
              </div>
            </div>
          </div>

          {
    /* تحديث 2 */
  }
          <div className="bg-gradient-to-br from-yellow-50 to-yellow-100/50 border border-yellow-200 rounded-2xl p-4">
            <div className="flex items-start gap-3">
              <div className="w-10 h-10 bg-yellow-500 rounded-full flex items-center justify-center flex-shrink-0">
                <Trophy className="w-5 h-5 text-white" />
              </div>
              <div className="flex-1">
                <p className="text-sm text-secondary mb-1">
                  <span className="font-medium">منذر</span> حقق <span className="font-bold text-yellow-600">6</span> نقاط خلال اليوم
                </p>
                <p className="text-xs text-muted-foreground">منذ 3 ساعات</p>
              </div>
            </div>
          </div>

          {
    /* تحديث 3 */
  }
          <div className="bg-gradient-to-br from-blue-50 to-blue-100/50 border border-blue-200 rounded-2xl p-4">
            <div className="flex items-start gap-3">
              <div className="w-10 h-10 bg-blue-500 rounded-full flex items-center justify-center flex-shrink-0">
                <Zap className="w-5 h-5 text-white" />
              </div>
              <div className="flex-1">
                <p className="text-sm text-secondary mb-1">
                  <span className="font-medium">محمد</span> يبحث عن شريك لمباراة الآن بعد ساعة
                </p>
                <p className="text-xs text-muted-foreground">منذ 15 دقيقة</p>
                <button className="mt-2 px-3 py-1.5 bg-blue-500 text-white text-xs rounded-lg hover:bg-blue-600 transition-colors">
                  انضم للمباراة
                </button>
              </div>
            </div>
          </div>

          {
    /* تحديث 4 */
  }
          <div className="bg-gradient-to-br from-purple-50 to-purple-100/50 border border-purple-200 rounded-2xl p-4">
            <div className="flex items-start gap-3">
              <div className="w-10 h-10 bg-purple-500 rounded-full flex items-center justify-center flex-shrink-0">
                <MessageCircle className="w-5 h-5 text-white" />
              </div>
              <div className="flex-1">
                <p className="text-sm text-secondary mb-1">
                  أكثر من <span className="font-bold text-purple-600">15</span> لاعب رفعوا مستواهم اليوم
                </p>
                <p className="text-xs text-muted-foreground">منذ 30 دقيقة</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      {
    /* قسم بطولات البادل */
  }
      <div>
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-xl text-secondary font-medium">بطولات البادل</h2>
        </div>

        {
    /* البطولات الدولية */
  }
        <div className="mb-4">
          <div className="flex items-center gap-2 mb-3">
            <Globe className="w-5 h-5 text-blue-600" />
            <h3 className="text-base text-secondary font-medium">البطولات الدولية</h3>
          </div>
          <div className="space-y-3">
            <div className="bg-gradient-to-br from-blue-50 to-blue-100/50 border border-blue-200 rounded-2xl p-4">
              <div className="flex justify-between items-start mb-2">
                <div className="flex-1">
                  <p className="text-sm text-secondary font-medium mb-1">بطولة دبي المفتوحة للبادل</p>
                  <div className="flex items-center gap-2 text-xs text-muted-foreground mb-1">
                    <Calendar className="w-3 h-3" />
                    <span>15 - 20 يوليو 2026</span>
                  </div>
                  <div className="flex items-center gap-2 text-xs text-muted-foreground">
                    <MapPin className="w-3 h-3" />
                    <span>دبي، الإمارات العربية المتحدة</span>
                  </div>
                </div>
                <Trophy className="w-8 h-8 text-blue-600" />
              </div>
              <div className="flex items-center justify-between pt-3 border-t border-blue-200">
                <span className="text-xs text-muted-foreground">الجائزة الكبرى</span>
                <span className="text-sm text-blue-600 font-medium">$100,000</span>
              </div>
            </div>

            <div className="bg-white border border-border rounded-2xl p-4">
              <div className="flex justify-between items-start mb-2">
                <div className="flex-1">
                  <p className="text-sm text-secondary font-medium mb-1">كأس العالم للبادل 2026</p>
                  <div className="flex items-center gap-2 text-xs text-muted-foreground mb-1">
                    <Calendar className="w-3 h-3" />
                    <span>10 - 18 أغسطس 2026</span>
                  </div>
                  <div className="flex items-center gap-2 text-xs text-muted-foreground">
                    <MapPin className="w-3 h-3" />
                    <span>مدريد، إسبانيا</span>
                  </div>
                </div>
                <Trophy className="w-8 h-8 text-primary" />
              </div>
              <div className="flex items-center justify-between pt-3 border-t border-border">
                <span className="text-xs text-muted-foreground">الجائزة الكبرى</span>
                <span className="text-sm text-primary font-medium">$250,000</span>
              </div>
            </div>

            <div className="bg-white border border-border rounded-2xl p-4">
              <div className="flex justify-between items-start mb-2">
                <div className="flex-1">
                  <p className="text-sm text-secondary font-medium mb-1">بطولة قطر الدولية للبادل</p>
                  <div className="flex items-center gap-2 text-xs text-muted-foreground mb-1">
                    <Calendar className="w-3 h-3" />
                    <span>5 - 10 سبتمبر 2026</span>
                  </div>
                  <div className="flex items-center gap-2 text-xs text-muted-foreground">
                    <MapPin className="w-3 h-3" />
                    <span>الدوحة، قطر</span>
                  </div>
                </div>
                <Trophy className="w-8 h-8 text-green-600" />
              </div>
              <div className="flex items-center justify-between pt-3 border-t border-border">
                <span className="text-xs text-muted-foreground">الجائزة الكبرى</span>
                <span className="text-sm text-green-600 font-medium">$75,000</span>
              </div>
            </div>
          </div>
        </div>

        {
    /* البطولات المحلية */
  }
        <div>
          <div className="flex items-center gap-2 mb-3">
            <Award className="w-5 h-5 text-green-600" />
            <h3 className="text-base text-secondary font-medium">البطولات المحلية</h3>
          </div>
          <div className="space-y-3">
            <div className="bg-gradient-to-br from-green-50 to-green-100/50 border border-green-200 rounded-2xl p-4">
              <div className="flex justify-between items-start mb-2">
                <div className="flex-1">
                  <p className="text-sm text-secondary font-medium mb-1">بطولة الرياض الكبرى للبادل</p>
                  <div className="flex items-center gap-2 text-xs text-muted-foreground mb-1">
                    <Calendar className="w-3 h-3" />
                    <span>25 - 28 يونيو 2026</span>
                  </div>
                  <div className="flex items-center gap-2 text-xs text-muted-foreground">
                    <MapPin className="w-3 h-3" />
                    <span>نادي البادل الملكي، الرياض</span>
                  </div>
                </div>
                <Trophy className="w-8 h-8 text-green-600" />
              </div>
              <div className="flex items-center justify-between pt-3 border-t border-green-200">
                <span className="text-xs text-muted-foreground">الجائزة</span>
                <span className="text-sm text-green-600 font-medium">50,000 ر.س</span>
              </div>
            </div>

            <div className="bg-white border border-border rounded-2xl p-4">
              <div className="flex justify-between items-start mb-2">
                <div className="flex-1">
                  <p className="text-sm text-secondary font-medium mb-1">كأس جدة للبادل</p>
                  <div className="flex items-center gap-2 text-xs text-muted-foreground mb-1">
                    <Calendar className="w-3 h-3" />
                    <span>10 - 12 يوليو 2026</span>
                  </div>
                  <div className="flex items-center gap-2 text-xs text-muted-foreground">
                    <MapPin className="w-3 h-3" />
                    <span>نادي الشاطئ، جدة</span>
                  </div>
                </div>
                <Trophy className="w-8 h-8 text-orange-600" />
              </div>
              <div className="flex items-center justify-between pt-3 border-t border-border">
                <span className="text-xs text-muted-foreground">الجائزة</span>
                <span className="text-sm text-orange-600 font-medium">30,000 ر.س</span>
              </div>
            </div>

            <div className="bg-white border border-border rounded-2xl p-4">
              <div className="flex justify-between items-start mb-2">
                <div className="flex-1">
                  <p className="text-sm text-secondary font-medium mb-1">بطولة الدمام المفتوحة</p>
                  <div className="flex items-center gap-2 text-xs text-muted-foreground mb-1">
                    <Calendar className="w-3 h-3" />
                    <span>20 - 22 يوليو 2026</span>
                  </div>
                  <div className="flex items-center gap-2 text-xs text-muted-foreground">
                    <MapPin className="w-3 h-3" />
                    <span>مركز الدمام الرياضي، الدمام</span>
                  </div>
                </div>
                <Trophy className="w-8 h-8 text-purple-600" />
              </div>
              <div className="flex items-center justify-between pt-3 border-t border-border">
                <span className="text-xs text-muted-foreground">الجائزة</span>
                <span className="text-sm text-purple-600 font-medium">25,000 ر.س</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {
    /* قسم نشاط الأصدقاء */
  }
      <div>
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-xl text-secondary font-medium">نشاط الأصدقاء</h2>
        </div>

        {
    /* آخر نشاطات الأصدقاء */
  }
        <div className="mb-5">
          <h3 className="text-base text-secondary font-medium mb-3">آخر أصدقائهم</h3>
          <div className="space-y-3">
            {
    /* نشاط 1 - حجز ملعب */
  }
            <div className="bg-gradient-to-br from-blue-50 to-blue-100/50 border border-blue-200 rounded-2xl p-4">
              <div className="flex items-start gap-3">
                <div className="w-10 h-10 bg-blue-500 rounded-full flex items-center justify-center flex-shrink-0">
                  <span className="text-white text-sm">أ</span>
                </div>
                <div className="flex-1">
                  <p className="text-sm text-secondary">
                    <span className="font-medium">أحمد</span> حجز ملعباً
                  </p>
                  <div className="flex items-center gap-2 mt-2 text-xs text-muted-foreground">
                    <MapPin className="w-3 h-3" />
                    <span>نادي البادل الملكي</span>
                    <span>•</span>
                    <Clock className="w-3 h-3" />
                    <span>غداً، 5:00 مساءً</span>
                  </div>
                  <p className="text-xs text-muted-foreground mt-1">منذ 10 دقائق</p>
                </div>
              </div>
            </div>

            {
    /* نشاط 2 - يبحث عن فريق */
  }
            <div className="bg-gradient-to-br from-orange-50 to-orange-100/50 border border-orange-200 rounded-2xl p-4">
              <div className="flex items-start gap-3">
                <div className="w-10 h-10 bg-orange-500 rounded-full flex items-center justify-center flex-shrink-0">
                  <span className="text-white text-sm">ن</span>
                </div>
                <div className="flex-1">
                  <p className="text-sm text-secondary">
                    <span className="font-medium">ناصر</span> يبحث عن فريق
                  </p>
                  <div className="flex items-center gap-2 mt-2">
                    <span className="px-2 py-1 bg-orange-500 text-white text-xs rounded-full">أمريكانو</span>
                    <span className="text-xs text-muted-foreground">اليوم، 7:00 مساءً</span>
                  </div>
                  <p className="text-xs text-muted-foreground mt-1">منذ 25 دقيقة</p>
                </div>
              </div>
            </div>

            {
    /* نشاط 3 - فاز في بطولة */
  }
            <div className="bg-gradient-to-br from-yellow-50 to-yellow-100/50 border border-yellow-200 rounded-2xl p-4">
              <div className="flex items-start gap-3">
                <div className="w-10 h-10 bg-yellow-500 rounded-full flex items-center justify-center flex-shrink-0">
                  <span className="text-white text-sm">س</span>
                </div>
                <div className="flex-1">
                  <p className="text-sm text-secondary">
                    <span className="font-medium">سعود</span> فاز في بطولة
                  </p>
                  <div className="flex items-center gap-2 mt-2">
                    <Trophy className="w-3 h-3 text-yellow-600" />
                    <span className="text-xs text-muted-foreground">بطولة الرياض المحلية</span>
                  </div>
                  <p className="text-xs text-muted-foreground mt-1">منذ ساعة</p>
                </div>
              </div>
            </div>

            {
    /* نشاط 4 - رفع مستوى */
  }
            <div className="bg-gradient-to-br from-green-50 to-green-100/50 border border-green-200 rounded-2xl p-4">
              <div className="flex items-start gap-3">
                <div className="w-10 h-10 bg-green-500 rounded-full flex items-center justify-center flex-shrink-0">
                  <span className="text-white text-sm">ع</span>
                </div>
                <div className="flex-1">
                  <p className="text-sm text-secondary">
                    <span className="font-medium">عبدالرحمن</span> رفع مستواه إلى <span className="font-bold text-green-600">5.0</span>
                  </p>
                  <div className="flex items-center gap-1 mt-2">
                    {[1, 2, 3, 4, 5].map((star) => <Star key={star} className="w-3 h-3 text-green-500 fill-green-500" />)}
                  </div>
                  <p className="text-xs text-muted-foreground mt-1">منذ ساعتين</p>
                </div>
              </div>
            </div>
          </div>
        </div>

        {
    /* اقتراحات الأصدقاء */
  }
        <div>
          <h3 className="text-base text-secondary font-medium mb-3">اقتراحات لك</h3>
          <div className="space-y-3">
            {
    /* اقتراح صديق 1 - بناء على المستوى */
  }
          <div className="bg-white border border-border rounded-2xl p-4">
            <div className="flex items-start gap-3">
              <div className="w-12 h-12 bg-gradient-to-br from-primary to-primary/80 rounded-full flex items-center justify-center flex-shrink-0">
                <span className="text-white text-lg">م</span>
              </div>
              <div className="flex-1">
                <div className="flex items-start justify-between mb-2">
                  <div>
                    <p className="text-sm text-secondary font-medium">محمد العتيبي</p>
                    <div className="flex items-center gap-2 mt-1">
                      <div className="flex items-center gap-1">
                        <Star className="w-3 h-3 text-yellow-500 fill-yellow-500" />
                        <span className="text-xs text-muted-foreground">مستوى 4.5</span>
                      </div>
                      <span className="text-xs text-muted-foreground">•</span>
                      <span className="text-xs text-muted-foreground">الرياض</span>
                    </div>
                    <p className="text-xs text-primary mt-1">مستوى قريب منك</p>
                  </div>
                  {friendRequests.includes(1) ? <span className="px-3 py-1.5 bg-gray-100 text-gray-600 text-xs rounded-lg">تم الإرسال</span> : <button
    onClick={() => handleAddFriend(1)}
    className="px-3 py-1.5 bg-primary text-white text-xs rounded-lg hover:bg-primary/90 transition-colors flex items-center gap-1"
  >
                      <UserPlus className="w-3 h-3" />
                      إضافة
                    </button>}
                </div>
              </div>
            </div>
          </div>

          {
    /* اقتراح صديق 2 - بناء على الموقع */
  }
          <div className="bg-white border border-border rounded-2xl p-4">
            <div className="flex items-start gap-3">
              <div className="w-12 h-12 bg-gradient-to-br from-green-500 to-green-600 rounded-full flex items-center justify-center flex-shrink-0">
                <span className="text-white text-lg">ع</span>
              </div>
              <div className="flex-1">
                <div className="flex items-start justify-between mb-2">
                  <div>
                    <p className="text-sm text-secondary font-medium">عبدالله الشمري</p>
                    <div className="flex items-center gap-2 mt-1">
                      <div className="flex items-center gap-1">
                        <Star className="w-3 h-3 text-yellow-500 fill-yellow-500" />
                        <span className="text-xs text-muted-foreground">مستوى 3.5</span>
                      </div>
                      <span className="text-xs text-muted-foreground">•</span>
                      <span className="text-xs text-muted-foreground">الرياض</span>
                    </div>
                    <p className="text-xs text-green-600 mt-1">يلعب في ملعبك المفضل</p>
                  </div>
                  {friendRequests.includes(2) ? <span className="px-3 py-1.5 bg-gray-100 text-gray-600 text-xs rounded-lg">تم الإرسال</span> : <button
    onClick={() => handleAddFriend(2)}
    className="px-3 py-1.5 bg-primary text-white text-xs rounded-lg hover:bg-primary/90 transition-colors flex items-center gap-1"
  >
                      <UserPlus className="w-3 h-3" />
                      إضافة
                    </button>}
                </div>
              </div>
            </div>
          </div>

          {
    /* اقتراح صديق 3 - أصدقاء مشتركين */
  }
          <div className="bg-white border border-border rounded-2xl p-4">
            <div className="flex items-start gap-3">
              <div className="w-12 h-12 bg-gradient-to-br from-blue-500 to-blue-600 rounded-full flex items-center justify-center flex-shrink-0">
                <span className="text-white text-lg">خ</span>
              </div>
              <div className="flex-1">
                <div className="flex items-start justify-between mb-2">
                  <div>
                    <p className="text-sm text-secondary font-medium">خالد المطيري</p>
                    <div className="flex items-center gap-2 mt-1">
                      <div className="flex items-center gap-1">
                        <Star className="w-3 h-3 text-yellow-500 fill-yellow-500" />
                        <span className="text-xs text-muted-foreground">مستوى 5.0</span>
                      </div>
                      <span className="text-xs text-muted-foreground">•</span>
                      <span className="text-xs text-muted-foreground">جدة</span>
                    </div>
                    <div className="flex items-center gap-1 mt-1">
                      <Users className="w-3 h-3 text-blue-600" />
                      <p className="text-xs text-blue-600">3 أصدقاء مشتركين</p>
                    </div>
                  </div>
                  {friendRequests.includes(3) ? <span className="px-3 py-1.5 bg-gray-100 text-gray-600 text-xs rounded-lg">تم الإرسال</span> : <button
    onClick={() => handleAddFriend(3)}
    className="px-3 py-1.5 bg-primary text-white text-xs rounded-lg hover:bg-primary/90 transition-colors flex items-center gap-1"
  >
                      <UserPlus className="w-3 h-3" />
                      إضافة
                    </button>}
                </div>
              </div>
            </div>
          </div>

          {
    /* اقتراح صديق 4 - لعب مع أصدقائك */
  }
          <div className="bg-white border border-border rounded-2xl p-4">
            <div className="flex items-start gap-3">
              <div className="w-12 h-12 bg-gradient-to-br from-orange-500 to-orange-600 rounded-full flex items-center justify-center flex-shrink-0">
                <span className="text-white text-lg">س</span>
              </div>
              <div className="flex-1">
                <div className="flex items-start justify-between mb-2">
                  <div>
                    <p className="text-sm text-secondary font-medium">سعد القحطاني</p>
                    <div className="flex items-center gap-2 mt-1">
                      <div className="flex items-center gap-1">
                        <Star className="w-3 h-3 text-yellow-500 fill-yellow-500" />
                        <span className="text-xs text-muted-foreground">مستوى 4.0</span>
                      </div>
                      <span className="text-xs text-muted-foreground">•</span>
                      <span className="text-xs text-muted-foreground">الرياض</span>
                    </div>
                    <p className="text-xs text-orange-600 mt-1">لعب مع صديقك أحمد</p>
                  </div>
                  {friendRequests.includes(4) ? <span className="px-3 py-1.5 bg-gray-100 text-gray-600 text-xs rounded-lg">تم الإرسال</span> : <button
    onClick={() => handleAddFriend(4)}
    className="px-3 py-1.5 bg-primary text-white text-xs rounded-lg hover:bg-primary/90 transition-colors flex items-center gap-1"
  >
                      <UserPlus className="w-3 h-3" />
                      إضافة
                    </button>}
                </div>
              </div>
            </div>
          </div>
          </div>
        </div>
      </div>
    </div>
    </>;
  const roleColors = {
    player: "from-primary to-primary/80",
    coach: "from-violet-600 to-violet-500",
    venue: "from-secondary to-secondary/80"
  };
  const roleColorsDark = {
    player: "from-primary/90 to-primary",
    coach: "from-violet-800 to-violet-700",
    venue: "from-secondary/90 to-secondary"
  };
  const allRoles = ["player", "coach", "venue"];
  const availableRolesToAdd = allRoles.filter((r) => !userRoles.find((u) => u.type === r));
  if (showPointsPage) {
    return <PointsSystemPage onBack={() => setShowPointsPage(false)} />;
  }
  return <div className="flex-1 overflow-y-auto bg-white">
      {
    /* Header */
  }
      <div className="bg-white px-6 pt-8 pb-4 border-b border-gray-100 sticky top-0 z-10">
        <div className="flex justify-between items-center mb-5">
          <img src={logo} alt="SPORTA Logo" className="w-20 h-auto" />
          <div className="flex items-center gap-2">
            <button className="p-2 bg-gray-100 rounded-full hover:bg-gray-200 transition-colors">
              <Bell className="w-5 h-5 text-secondary" />
            </button>
          </div>
        </div>

        {
    /* بوكس حساباتي في التطبيق */
  }
        <div className="bg-gray-50 border border-border rounded-2xl p-4">
          <div className="flex items-center justify-between mb-3">
            <h2 className="text-base text-secondary">حساباتي في التطبيق</h2>
            <div className="relative">
              <button
    onClick={() => setShowAddRoleMenu(!showAddRoleMenu)}
    disabled={availableRolesToAdd.length === 0}
    className={`p-1.5 rounded-full ${availableRolesToAdd.length > 0 ? "bg-primary text-white hover:bg-primary/90" : "bg-gray-200 text-gray-400 cursor-not-allowed"}`}
  >
                <Plus className="w-4 h-4" />
              </button>
              {showAddRoleMenu && availableRolesToAdd.length > 0 && <>
                  <div className="fixed inset-0 z-10" onClick={() => setShowAddRoleMenu(false)} />
                  <div className="absolute left-0 top-full mt-2 bg-white rounded-xl shadow-xl z-20 overflow-hidden min-w-[150px] border border-gray-200">
                    {availableRolesToAdd.map((role) => <button
    key={role}
    onClick={() => {
      const saved = localStorage.getItem("userRoles");
      const existing = saved ? JSON.parse(saved) : [];
      const updated = [...existing, { type: role, completed: false }];
      localStorage.setItem("userRoles", JSON.stringify(updated));
      setShowAddRoleMenu(false);
      onRoleChange?.(role);
      onNavigate("profile");
    }}
    className="w-full px-4 py-3 text-right hover:bg-gray-50 text-sm text-secondary transition-colors"
  >
                        إضافة {getRoleName(role)}
                      </button>)}
                  </div>
                </>}
            </div>
          </div>

          <div className="flex gap-3">
            {userRoles.map((roleObj) => {
    const role = roleObj.type;
    const completed = roleObj.completed;
    const isActive = currentRole === role && completed;
    return <div key={role} className="flex-1 relative">
                  <button
      onClick={() => {
        if (completed) {
          handleRoleChange(role);
        } else {
          onRoleChange?.(role);
          onNavigate("profile");
        }
      }}
      className={`w-full flex flex-col items-center gap-2 p-3 rounded-xl border-2 transition-all ${isActive ? "border-primary bg-primary/5" : "border-border bg-white hover:border-gray-300"}`}
    >
                    <div className={`w-12 h-12 bg-gradient-to-br ${roleColors[role]} rounded-full flex items-center justify-center shadow-sm relative transition-all ${isActive ? "ring-2 ring-offset-2 ring-primary" : ""}`}>
                      <span className="text-white">أ</span>
                      {!completed && <span className="absolute -top-1 -left-1 w-4 h-4 bg-orange-500 rounded-full flex items-center justify-center">
                          <span className="text-white text-xs">!</span>
                        </span>}
                    </div>
                    <div className="text-center">
                      <p className={`text-xs ${isActive ? "text-primary" : "text-secondary"}`}>أحمد</p>
                      <p className={`text-xs mt-0.5 ${isActive ? "text-primary/70" : "text-muted-foreground"}`}>{getRoleName(role)}</p>
                    </div>
                    {!completed ? <span className="text-xs text-orange-500">إكمال التسجيل</span> : isActive ? <span className="w-1.5 h-1.5 rounded-full bg-primary" /> : null}
                  </button>
                  {
      /* أيقونة الحذف */
    }
                  <button
      onClick={(e) => {
        e.stopPropagation();
        setDeleteWarning(role);
      }}
      className="absolute -bottom-2 -left-2 w-6 h-6 bg-white border border-red-200 rounded-full flex items-center justify-center shadow-md hover:bg-red-50 transition-colors"
    >
                    <Trash2 className="w-3 h-3 text-red-500" />
                  </button>
                </div>;
  })}
          </div>

          {
    /* مودال تحذير الحذف */
  }
          {deleteWarning && <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 px-6">
              <div className="bg-white rounded-2xl p-6 w-full max-w-sm shadow-2xl">
                <div className="flex flex-col items-center text-center gap-4">
                  <div className="w-14 h-14 bg-red-100 rounded-full flex items-center justify-center">
                    <AlertTriangle className="w-7 h-7 text-red-500" />
                  </div>
                  <div>
                    <h3 className="text-lg text-secondary mb-1">حذف حساب {getRoleName(deleteWarning)}</h3>
                    <p className="text-sm text-muted-foreground">
                      هل أنت متأكد من حذف هذا الحساب؟ سيتم فقدان جميع بياناتك المرتبطة به ولا يمكن التراجع عن هذا الإجراء.
                    </p>
                  </div>
                  <div className="flex gap-3 w-full">
                    <button
    onClick={() => setDeleteWarning(null)}
    className="flex-1 py-3 border-2 border-border text-secondary rounded-xl hover:bg-gray-50 transition-colors"
  >
                      إلغاء
                    </button>
                    <button
    onClick={() => handleDeleteRole(deleteWarning)}
    className="flex-1 py-3 bg-red-500 text-white rounded-xl hover:bg-red-600 transition-colors"
  >
                      حذف الحساب
                    </button>
                  </div>
                </div>
              </div>
            </div>}
        </div>
      </div>

      {
    /* المحتوى حسب الدور — يظهر فقط إذا الدور النشط مكتمل */
  }
      {userRoles.find((r) => r.type === currentRole)?.completed ? currentRole === "coach" ? <CoachHomePage onNavigate={onNavigate} /> : currentRole === "venue" ? <VenueHomePage onNavigate={onNavigate} /> : renderPlayerDashboard() : <div className="flex-1 flex flex-col items-center justify-center p-10 text-center gap-4">
            <div className="w-16 h-16 bg-orange-100 rounded-full flex items-center justify-center">
              <span className="text-orange-500 text-2xl">!</span>
            </div>
            <p className="text-secondary">يجب إكمال تسجيل حسابك أولاً</p>
            <button
    onClick={() => {
      const incomplete = userRoles.find((r) => !r.completed);
      if (incomplete) {
        onRoleChange?.(incomplete.type);
      }
      onNavigate("profile");
    }}
    className="px-6 py-3 bg-primary text-white rounded-xl hover:bg-primary/90 transition-colors"
  >
              إكمال التسجيل
            </button>
          </div>}
    </div>;
}
export {
  HomePage as default
};
