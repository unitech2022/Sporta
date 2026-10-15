import { Bell, Calendar, DollarSign, Clock, ChevronDown, BarChart3, MapPin, AlertCircle } from "lucide-react";
import { useState } from "react";
import logo from "../../imports/new_logo.png";
function VenueHomePage({ onNavigate }) {
  const [showRoleMenu, setShowRoleMenu] = useState(false);
  const handleRoleChange = (role) => {
    localStorage.setItem("currentRole", role);
    window.location.reload();
  };
  const userRoles = (() => {
    const saved = localStorage.getItem("userRoles");
    if (saved) {
      const roles = JSON.parse(saved);
      return roles.filter((r) => r.completed).map((r) => r.type);
    }
    return ["venue"];
  })();
  const getRoleName = (role) => {
    switch (role) {
      case "player":
        return "\u0644\u0627\u0639\u0628";
      case "coach":
        return "\u0645\u062F\u0631\u0628";
      case "venue":
        return "\u0645\u0627\u0644\u0643 \u0645\u0644\u0639\u0628";
      default:
        return "\u0645\u0627\u0644\u0643 \u0645\u0644\u0639\u0628";
    }
  };
  return <div className="flex-1 overflow-y-auto bg-white">
      {
    /* Header */
  }
      <div className="bg-gradient-to-br from-blue-600 to-blue-700 text-white px-6 pt-8 pb-6">
        <div className="flex justify-between items-start mb-6">
          <div className="flex items-center gap-3 flex-1">
            <img
    src={logo}
    alt="SPORTA Logo"
    className="w-20 h-auto"
    style={{ filter: "brightness(0) invert(1)" }}
  />
            <div className="flex-1">
              {userRoles.length > 1 ? <div className="relative">
                  <button
    onClick={() => setShowRoleMenu(!showRoleMenu)}
    className="flex items-center gap-2 mt-1 text-white/90 hover:text-white transition-colors"
  >
                    <span className="text-sm">أحمد السعيد</span>
                    <ChevronDown className="w-4 h-4" />
                  </button>
                  <span className="text-xs text-white/70 block mt-1">مالك ملعب</span>

                  {showRoleMenu && <>
                      <div className="fixed inset-0 z-10" onClick={() => setShowRoleMenu(false)} />
                      <div className="absolute top-full right-0 mt-2 bg-white rounded-xl shadow-xl z-20 overflow-hidden min-w-[180px]">
                        {userRoles.map((role) => <button
    key={role}
    onClick={() => handleRoleChange(role)}
    className="w-full px-4 py-3 text-right text-secondary hover:bg-gray-50 transition-colors"
  >
                            {getRoleName(role)}
                          </button>)}
                      </div>
                    </>}
                </div> : <div className="mt-1">
                  <p className="text-sm text-white/90">أحمد السعيد</p>
                  <span className="text-xs text-white/70">مالك ملعب</span>
                </div>}
            </div>
          </div>
          <button className="p-2 bg-white/20 rounded-full backdrop-blur-sm hover:bg-white/30 transition-colors">
            <Bell className="w-5 h-5" />
          </button>
        </div>

        {
    /* إحصائيات سريعة */
  }
        <div className="grid grid-cols-3 gap-3">
          <div className="bg-white/20 backdrop-blur-sm rounded-xl p-3 text-center">
            <p className="text-2xl font-bold mb-1">6</p>
            <p className="text-xs text-white/80">ملاعب</p>
          </div>
          <div className="bg-white/20 backdrop-blur-sm rounded-xl p-3 text-center">
            <p className="text-2xl font-bold mb-1">89%</p>
            <p className="text-xs text-white/80">نسبة الحجز</p>
          </div>
          <div className="bg-white/20 backdrop-blur-sm rounded-xl p-3 text-center">
            <p className="text-2xl font-bold mb-1">4.6</p>
            <p className="text-xs text-white/80">التقييم</p>
          </div>
        </div>
      </div>

      <div className="px-6 py-6 space-y-6">
        {
    /* نظرة عامة */
  }
        <div>
          <h2 className="text-xl text-secondary font-medium mb-4">نظرة عامة</h2>
          <div className="grid grid-cols-2 gap-3">
            <div className="bg-gradient-to-br from-green-50 to-green-100/50 border border-green-200 rounded-2xl p-4 text-center">
              <DollarSign className="w-8 h-8 text-green-600 mx-auto mb-2" />
              <p className="text-2xl text-green-600 font-bold mb-1">8,400 ر.س</p>
              <p className="text-xs text-muted-foreground">إيرادات هذا الأسبوع</p>
            </div>
            <div className="bg-gradient-to-br from-blue-50 to-blue-100/50 border border-blue-200 rounded-2xl p-4 text-center">
              <Calendar className="w-8 h-8 text-blue-600 mx-auto mb-2" />
              <p className="text-2xl text-blue-600 font-bold mb-1">42</p>
              <p className="text-xs text-muted-foreground">حجوزات اليوم</p>
            </div>
          </div>
        </div>

        {
    /* حالة الملاعب الآن */
  }
        <div>
          <div className="flex justify-between items-center mb-4">
            <h2 className="text-xl text-secondary font-medium">حالة الملاعب الآن</h2>
            <span className="text-xs text-muted-foreground">تحديث مباشر</span>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div className="bg-gradient-to-br from-green-50 to-green-100/50 border-2 border-green-300 rounded-2xl p-4">
              <div className="flex items-center justify-between mb-2">
                <span className="text-sm text-secondary font-medium">ملعب 1</span>
                <span className="px-2 py-1 bg-green-500 text-white text-xs rounded-full">محجوز</span>
              </div>
              <div className="flex items-center gap-2 text-xs text-muted-foreground">
                <Clock className="w-3 h-3" />
                <span>4:00 - 5:30 مساءً</span>
              </div>
            </div>

            <div className="bg-gradient-to-br from-green-50 to-green-100/50 border-2 border-green-300 rounded-2xl p-4">
              <div className="flex items-center justify-between mb-2">
                <span className="text-sm text-secondary font-medium">ملعب 2</span>
                <span className="px-2 py-1 bg-green-500 text-white text-xs rounded-full">محجوز</span>
              </div>
              <div className="flex items-center gap-2 text-xs text-muted-foreground">
                <Clock className="w-3 h-3" />
                <span>6:00 - 7:30 مساءً</span>
              </div>
            </div>

            <div className="bg-white border-2 border-gray-200 rounded-2xl p-4">
              <div className="flex items-center justify-between mb-2">
                <span className="text-sm text-secondary font-medium">ملعب 3</span>
                <span className="px-2 py-1 bg-gray-200 text-gray-600 text-xs rounded-full">متاح</span>
              </div>
              <div className="flex items-center gap-2 text-xs text-muted-foreground">
                <Clock className="w-3 h-3" />
                <span>متاح للحجز</span>
              </div>
            </div>

            <div className="bg-gradient-to-br from-orange-50 to-orange-100/50 border-2 border-orange-300 rounded-2xl p-4">
              <div className="flex items-center justify-between mb-2">
                <span className="text-sm text-secondary font-medium">ملعب 4</span>
                <span className="px-2 py-1 bg-orange-500 text-white text-xs rounded-full">صيانة</span>
              </div>
              <div className="flex items-center gap-2 text-xs text-muted-foreground">
                <AlertCircle className="w-3 h-3" />
                <span>قيد الصيانة</span>
              </div>
            </div>

            <div className="bg-gradient-to-br from-green-50 to-green-100/50 border-2 border-green-300 rounded-2xl p-4">
              <div className="flex items-center justify-between mb-2">
                <span className="text-sm text-secondary font-medium">ملعب 5</span>
                <span className="px-2 py-1 bg-green-500 text-white text-xs rounded-full">محجوز</span>
              </div>
              <div className="flex items-center gap-2 text-xs text-muted-foreground">
                <Clock className="w-3 h-3" />
                <span>7:00 - 8:30 مساءً</span>
              </div>
            </div>

            <div className="bg-white border-2 border-gray-200 rounded-2xl p-4">
              <div className="flex items-center justify-between mb-2">
                <span className="text-sm text-secondary font-medium">ملعب 6</span>
                <span className="px-2 py-1 bg-gray-200 text-gray-600 text-xs rounded-full">متاح</span>
              </div>
              <div className="flex items-center gap-2 text-xs text-muted-foreground">
                <Clock className="w-3 h-3" />
                <span>متاح للحجز</span>
              </div>
            </div>
          </div>
        </div>

        {
    /* الحجوزات القادمة */
  }
        <div>
          <div className="flex justify-between items-center mb-4">
            <h2 className="text-xl text-secondary font-medium">الحجوزات القادمة</h2>
            <button className="text-sm text-primary">عرض الكل</button>
          </div>
          <div className="space-y-3">
            <div className="bg-white border border-border rounded-2xl p-4">
              <div className="flex justify-between items-start mb-3">
                <div className="flex-1">
                  <div className="flex items-center gap-2 mb-1">
                    <span className="text-sm text-secondary font-medium">ملعب 1</span>
                    <span className="text-xs text-muted-foreground">• محمد وأحمد</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <MapPin className="w-3 h-3 text-muted-foreground" />
                    <p className="text-xs text-muted-foreground">ملعب داخلي</p>
                  </div>
                </div>
                <span className="px-3 py-1 bg-blue-100 text-blue-600 text-xs rounded-full">مؤكدة</span>
              </div>
              <div className="flex justify-between items-center pt-3 border-t border-border">
                <div className="flex items-center gap-2">
                  <Clock className="w-4 h-4 text-muted-foreground" />
                  <span className="text-sm text-secondary">غداً، 5:00 - 6:30 مساءً</span>
                </div>
                <span className="text-sm text-primary font-medium">120 ر.س</span>
              </div>
            </div>

            <div className="bg-white border border-border rounded-2xl p-4">
              <div className="flex justify-between items-start mb-3">
                <div className="flex-1">
                  <div className="flex items-center gap-2 mb-1">
                    <span className="text-sm text-secondary font-medium">ملعب 3</span>
                    <span className="text-xs text-muted-foreground">• خالد وسعد</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <MapPin className="w-3 h-3 text-muted-foreground" />
                    <p className="text-xs text-muted-foreground">ملعب خارجي</p>
                  </div>
                </div>
                <span className="px-3 py-1 bg-blue-100 text-blue-600 text-xs rounded-full">مؤكدة</span>
              </div>
              <div className="flex justify-between items-center pt-3 border-t border-border">
                <div className="flex items-center gap-2">
                  <Clock className="w-4 h-4 text-muted-foreground" />
                  <span className="text-sm text-secondary">غداً، 7:00 - 8:30 مساءً</span>
                </div>
                <span className="text-sm text-primary font-medium">100 ر.س</span>
              </div>
            </div>
          </div>
        </div>

        {
    /* إحصائيات الأسبوع */
  }
        <div>
          <h2 className="text-xl text-secondary font-medium mb-4">إحصائيات هذا الأسبوع</h2>
          <div className="bg-gradient-to-br from-blue-50 to-blue-100/50 border border-blue-200 rounded-2xl p-4">
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <span className="text-sm text-muted-foreground">إجمالي الحجوزات</span>
                <span className="text-sm text-secondary font-medium">156 حجز</span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-sm text-muted-foreground">ساعات اللعب</span>
                <span className="text-sm text-secondary font-medium">234 ساعة</span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-sm text-muted-foreground">متوسط سعر الساعة</span>
                <span className="text-sm text-secondary font-medium">80 ر.س</span>
              </div>
              <div className="flex items-center justify-between pt-3 border-t border-blue-300">
                <span className="text-sm text-secondary font-medium">الإيرادات الإجمالية</span>
                <span className="text-lg text-green-600 font-bold">8,400 ر.س</span>
              </div>
            </div>
          </div>
        </div>

        {
    /* إجراءات سريعة */
  }
        <div className="grid grid-cols-2 gap-3">
          <button className="bg-gradient-to-br from-primary to-primary/90 text-white rounded-2xl p-4 hover:shadow-lg transition-all">
            <Calendar className="w-8 h-8 mx-auto mb-2" />
            <p className="text-sm font-medium">إدارة الحجوزات</p>
          </button>
          <button className="bg-white border-2 border-border rounded-2xl p-4 hover:border-primary transition-all">
            <BarChart3 className="w-8 h-8 text-primary mx-auto mb-2" />
            <p className="text-sm text-secondary font-medium">التقارير المالية</p>
          </button>
        </div>
      </div>
    </div>;
}
export {
  VenueHomePage as default
};
