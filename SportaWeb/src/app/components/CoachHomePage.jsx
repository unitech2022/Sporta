import { Bell, Calendar, DollarSign, Users, BookOpen, ChevronDown, CheckCircle, XCircle, Star, TrendingUp, Clock } from "lucide-react";
import { useState } from "react";
import logo from "../../imports/new_logo.png";
function CoachHomePage({ onNavigate }) {
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
    return ["coach"];
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
        return "\u0645\u062F\u0631\u0628";
    }
  };
  return <div className="flex-1 overflow-y-auto bg-white">
      {
    /* Header */
  }
      <div className="bg-gradient-to-br from-green-500 to-green-600 text-white px-6 pt-8 pb-6">
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
                  <span className="text-xs text-white/70 block mt-1">مدرب</span>

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
                  <span className="text-xs text-white/70">مدرب</span>
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
            <p className="text-2xl font-bold mb-1">24</p>
            <p className="text-xs text-white/80">طلاب نشطين</p>
          </div>
          <div className="bg-white/20 backdrop-blur-sm rounded-xl p-3 text-center">
            <p className="text-2xl font-bold mb-1">4.8</p>
            <p className="text-xs text-white/80">التقييم</p>
          </div>
          <div className="bg-white/20 backdrop-blur-sm rounded-xl p-3 text-center">
            <p className="text-2xl font-bold mb-1">156</p>
            <p className="text-xs text-white/80">حصة مكتملة</p>
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
              <p className="text-2xl text-green-600 font-bold mb-1">3,200 ر.س</p>
              <p className="text-xs text-muted-foreground">إيرادات هذا الشهر</p>
            </div>
            <div className="bg-gradient-to-br from-blue-50 to-blue-100/50 border border-blue-200 rounded-2xl p-4 text-center">
              <BookOpen className="w-8 h-8 text-blue-600 mx-auto mb-2" />
              <p className="text-2xl text-blue-600 font-bold mb-1">8</p>
              <p className="text-xs text-muted-foreground">حصص هذا الأسبوع</p>
            </div>
          </div>
        </div>

        {
    /* طلبات جديدة */
  }
        <div>
          <div className="flex justify-between items-center mb-4">
            <h2 className="text-xl text-secondary font-medium">طلبات جديدة</h2>
            <span className="px-3 py-1 bg-red-100 text-red-600 text-xs rounded-full">3 طلبات</span>
          </div>
          <div className="space-y-3">
            <div className="bg-white border-2 border-orange-200 rounded-2xl p-4">
              <div className="flex items-center justify-between mb-3">
                <div className="flex items-center gap-3">
                  <div className="w-12 h-12 bg-gradient-to-br from-primary to-primary/80 rounded-full flex items-center justify-center">
                    <span className="text-white text-lg">س</span>
                  </div>
                  <div>
                    <p className="text-sm text-secondary font-medium">سعد أحمد</p>
                    <p className="text-xs text-muted-foreground">يريد حصة تدريبية</p>
                  </div>
                </div>
                <div className="flex gap-2">
                  <button className="p-2 bg-green-100 rounded-lg hover:bg-green-200 transition-colors">
                    <CheckCircle className="w-5 h-5 text-green-600" />
                  </button>
                  <button className="p-2 bg-red-100 rounded-lg hover:bg-red-200 transition-colors">
                    <XCircle className="w-5 h-5 text-red-600" />
                  </button>
                </div>
              </div>
              <div className="flex items-center justify-between pt-3 border-t border-gray-200">
                <div className="flex items-center gap-2">
                  <Calendar className="w-4 h-4 text-muted-foreground" />
                  <span className="text-xs text-muted-foreground">غداً، 5:00 مساءً</span>
                </div>
                <span className="text-sm text-primary font-medium">150 ر.س</span>
              </div>
            </div>

            <div className="bg-white border border-border rounded-2xl p-4">
              <div className="flex items-center justify-between mb-3">
                <div className="flex items-center gap-3">
                  <div className="w-12 h-12 bg-gradient-to-br from-green-500 to-green-600 rounded-full flex items-center justify-center">
                    <span className="text-white text-lg">م</span>
                  </div>
                  <div>
                    <p className="text-sm text-secondary font-medium">محمد علي</p>
                    <p className="text-xs text-muted-foreground">يريد حصة جماعية</p>
                  </div>
                </div>
                <div className="flex gap-2">
                  <button className="p-2 bg-green-100 rounded-lg hover:bg-green-200 transition-colors">
                    <CheckCircle className="w-5 h-5 text-green-600" />
                  </button>
                  <button className="p-2 bg-red-100 rounded-lg hover:bg-red-200 transition-colors">
                    <XCircle className="w-5 h-5 text-red-600" />
                  </button>
                </div>
              </div>
              <div className="flex items-center justify-between pt-3 border-t border-gray-200">
                <div className="flex items-center gap-2">
                  <Calendar className="w-4 h-4 text-muted-foreground" />
                  <span className="text-xs text-muted-foreground">الجمعة، 7:00 مساءً</span>
                </div>
                <span className="text-sm text-primary font-medium">100 ر.س</span>
              </div>
            </div>
          </div>
        </div>

        {
    /* الحصص القادمة */
  }
        <div>
          <div className="flex justify-between items-center mb-4">
            <h2 className="text-xl text-secondary font-medium">الحصص القادمة</h2>
            <button className="text-sm text-primary">عرض الكل</button>
          </div>
          <div className="space-y-3">
            <div className="bg-gradient-to-br from-green-50 to-green-100/50 border-2 border-green-200 rounded-2xl p-4">
              <div className="flex justify-between items-start mb-3">
                <div className="flex-1">
                  <p className="text-sm text-secondary font-medium mb-1">حصة تدريبية خاصة</p>
                  <p className="text-xs text-muted-foreground">مع أحمد محمد</p>
                </div>
                <span className="px-3 py-1 bg-green-500 text-white text-xs rounded-full">مؤكدة</span>
              </div>
              <div className="flex justify-between items-center pt-3 border-t border-green-200">
                <div className="flex items-center gap-2">
                  <Clock className="w-4 h-4 text-muted-foreground" />
                  <span className="text-sm text-secondary">اليوم، 5:00 مساءً</span>
                </div>
                <span className="text-sm text-green-600 font-medium">150 ر.س</span>
              </div>
            </div>

            <div className="bg-white border border-border rounded-2xl p-4">
              <div className="flex justify-between items-start mb-3">
                <div className="flex-1">
                  <p className="text-sm text-secondary font-medium mb-1">حصة جماعية</p>
                  <p className="text-xs text-muted-foreground">4 طلاب</p>
                </div>
                <span className="px-3 py-1 bg-blue-100 text-blue-600 text-xs rounded-full">مؤكدة</span>
              </div>
              <div className="flex justify-between items-center pt-3 border-t border-border">
                <div className="flex items-center gap-2">
                  <Clock className="w-4 h-4 text-muted-foreground" />
                  <span className="text-sm text-secondary">غداً، 7:00 مساءً</span>
                </div>
                <span className="text-sm text-primary font-medium">400 ر.س</span>
              </div>
            </div>
          </div>
        </div>

        {
    /* التقييمات الأخيرة */
  }
        <div>
          <div className="flex justify-between items-center mb-4">
            <h2 className="text-xl text-secondary font-medium">آخر التقييمات</h2>
          </div>
          <div className="space-y-3">
            <div className="bg-yellow-50 border border-yellow-200 rounded-2xl p-4">
              <div className="flex items-center justify-between mb-2">
                <div className="flex items-center gap-2">
                  <div className="w-10 h-10 bg-yellow-500 rounded-full flex items-center justify-center">
                    <span className="text-white text-sm">أ</span>
                  </div>
                  <div>
                    <p className="text-sm text-secondary font-medium">أحمد عبدالله</p>
                    <div className="flex gap-1">
                      {[1, 2, 3, 4, 5].map((star) => <Star key={star} className="w-3 h-3 text-yellow-500 fill-yellow-500" />)}
                    </div>
                  </div>
                </div>
                <span className="text-xs text-muted-foreground">منذ يومين</span>
              </div>
              <p className="text-xs text-secondary">"مدرب ممتاز، استفدت كثيراً من الحصص معه"</p>
            </div>

            <div className="bg-white border border-border rounded-2xl p-4">
              <div className="flex items-center justify-between mb-2">
                <div className="flex items-center gap-2">
                  <div className="w-10 h-10 bg-blue-500 rounded-full flex items-center justify-center">
                    <span className="text-white text-sm">م</span>
                  </div>
                  <div>
                    <p className="text-sm text-secondary font-medium">محمد سعد</p>
                    <div className="flex gap-1">
                      {[1, 2, 3, 4].map((star) => <Star key={star} className="w-3 h-3 text-yellow-500 fill-yellow-500" />)}
                      <Star className="w-3 h-3 text-gray-300" />
                    </div>
                  </div>
                </div>
                <span className="text-xs text-muted-foreground">منذ 3 أيام</span>
              </div>
              <p className="text-xs text-secondary">"تجربة جيدة وتطور ملحوظ"</p>
            </div>
          </div>
        </div>

        {
    /* إجراءات سريعة */
  }
        <div className="grid grid-cols-2 gap-3">
          <button className="bg-gradient-to-br from-primary to-primary/90 text-white rounded-2xl p-4 hover:shadow-lg transition-all">
            <Users className="w-8 h-8 mx-auto mb-2" />
            <p className="text-sm font-medium">إدارة الطلاب</p>
          </button>
          <button className="bg-white border-2 border-border rounded-2xl p-4 hover:border-primary transition-all">
            <TrendingUp className="w-8 h-8 text-primary mx-auto mb-2" />
            <p className="text-sm text-secondary font-medium">التقارير</p>
          </button>
        </div>
      </div>
    </div>;
}
export {
  CoachHomePage as default
};
