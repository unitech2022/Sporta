import { ChevronRight, Phone, Mail, Lock, AlertCircle, Check } from "lucide-react";
import { useState } from "react";
function AccountSettings({ onBack }) {
  const [showPhoneModal, setShowPhoneModal] = useState(false);
  const [showEmailModal, setShowEmailModal] = useState(false);
  const [showPasswordModal, setShowPasswordModal] = useState(false);
  const [requestSent, setRequestSent] = useState(false);
  const handlePhoneChangeRequest = () => {
    setRequestSent(true);
    setTimeout(() => {
      setShowPhoneModal(false);
      setRequestSent(false);
    }, 2e3);
  };
  return <div className="flex-1 overflow-y-auto bg-background">
      {
    /* Header */
  }
      <div className="bg-gradient-to-br from-primary to-primary/90 text-white px-6 pt-8 pb-6">
        <div className="flex justify-between items-start mb-4">
          <button onClick={onBack} className="p-2 bg-white/20 rounded-full backdrop-blur-sm hover:bg-white/30 transition-colors">
            <ChevronRight className="w-5 h-5" />
          </button>
          <div className="text-center flex-1">
            <h1 className="text-xl">إعدادات الحساب</h1>
          </div>
          <div className="w-9" />
        </div>
      </div>

      <div className="px-6 py-6 space-y-4">
        <div className="bg-blue-50 border border-blue-200 rounded-2xl p-4 mb-4">
          <p className="text-sm text-secondary text-center">إدارة معلومات حسابك وكلمة المرور</p>
        </div>

        {
    /* معلومات الحساب الحالية */
  }
        <div className="bg-white border border-border rounded-2xl p-5 shadow-sm">
          <h2 className="text-sm text-secondary font-medium mb-4">المعلومات الحالية</h2>
          <div className="space-y-3">
            <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
              <div className="flex items-center gap-3">
                <Phone className="w-5 h-5 text-primary" />
                <div>
                  <p className="text-xs text-muted-foreground mb-1">رقم الجوال</p>
                  <p className="text-sm text-secondary" dir="ltr">+966 50 123 4567</p>
                </div>
              </div>
            </div>
            <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
              <div className="flex items-center gap-3">
                <Mail className="w-5 h-5 text-primary" />
                <div>
                  <p className="text-xs text-muted-foreground mb-1">البريد الإلكتروني</p>
                  <p className="text-sm text-secondary">ahmad@email.com</p>
                </div>
              </div>
            </div>
          </div>
        </div>

        {
    /* خيارات التغيير */
  }
        <div className="bg-white border border-border rounded-2xl overflow-hidden shadow-sm">
          <button
    onClick={() => setShowPhoneModal(true)}
    className="w-full px-5 py-4 flex items-center justify-between border-b border-border hover:bg-gray-50 transition-colors"
  >
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-blue-100 rounded-xl flex items-center justify-center">
                <Phone className="w-5 h-5 text-blue-600" />
              </div>
              <div className="text-right">
                <p className="text-sm text-secondary font-medium">تغيير رقم الجوال</p>
                <p className="text-xs text-muted-foreground">يتطلب موافقة الإدارة</p>
              </div>
            </div>
            <ChevronRight className="w-5 h-5 text-muted-foreground rotate-180" />
          </button>

          <button
    onClick={() => setShowEmailModal(true)}
    className="w-full px-5 py-4 flex items-center justify-between border-b border-border hover:bg-gray-50 transition-colors"
  >
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-green-100 rounded-xl flex items-center justify-center">
                <Mail className="w-5 h-5 text-green-600" />
              </div>
              <div className="text-right">
                <p className="text-sm text-secondary font-medium">تغيير البريد الإلكتروني</p>
                <p className="text-xs text-muted-foreground">تحديث فوري</p>
              </div>
            </div>
            <ChevronRight className="w-5 h-5 text-muted-foreground rotate-180" />
          </button>

          <button
    onClick={() => setShowPasswordModal(true)}
    className="w-full px-5 py-4 flex items-center justify-between hover:bg-gray-50 transition-colors"
  >
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-orange-100 rounded-xl flex items-center justify-center">
                <Lock className="w-5 h-5 text-orange-600" />
              </div>
              <div className="text-right">
                <p className="text-sm text-secondary font-medium">تغيير كلمة المرور</p>
                <p className="text-xs text-muted-foreground">آخر تغيير: منذ 3 أشهر</p>
              </div>
            </div>
            <ChevronRight className="w-5 h-5 text-muted-foreground rotate-180" />
          </button>
        </div>

        {
    /* ملاحظة أمنية */
  }
        <div className="bg-yellow-50 border border-yellow-200 rounded-2xl p-4">
          <div className="flex items-start gap-3">
            <AlertCircle className="w-5 h-5 text-yellow-600 mt-0.5 flex-shrink-0" />
            <div>
              <p className="text-xs text-secondary">
                <span className="font-medium">ملاحظة أمنية:</span> تأكد من استخدام كلمة مرور قوية وعدم مشاركتها مع أي شخص.
              </p>
            </div>
          </div>
        </div>
      </div>

      {
    /* Phone Change Modal */
  }
      {showPhoneModal && <div className="fixed inset-0 z-50 flex items-center justify-center p-6">
          <div className="absolute inset-0 bg-black/50 backdrop-blur-sm" onClick={() => setShowPhoneModal(false)} />
          <div className="relative bg-white rounded-2xl max-w-md w-full shadow-2xl">
            <div className="bg-gradient-to-br from-blue-500 to-blue-600 text-white px-6 py-4 rounded-t-2xl">
              <div className="flex items-center gap-3">
                <Phone className="w-6 h-6" />
                <h2 className="text-lg font-medium">تغيير رقم الجوال</h2>
              </div>
            </div>

            {!requestSent ? <div className="px-6 py-6">
                <div className="bg-orange-50 border border-orange-200 rounded-xl p-4 mb-4">
                  <div className="flex items-start gap-3">
                    <AlertCircle className="w-5 h-5 text-orange-600 mt-0.5" />
                    <p className="text-xs text-secondary">
                      تغيير رقم الجوال يتطلب موافقة إدارة التطبيق. سيتم مراجعة طلبك خلال 24-48 ساعة.
                    </p>
                  </div>
                </div>

                <div className="mb-4">
                  <label className="block text-xs text-muted-foreground mb-2">رقم الجوال الجديد</label>
                  <input
    type="tel"
    placeholder="05XXXXXXXX"
    dir="ltr"
    className="w-full px-4 py-3 bg-gray-50 border border-border rounded-xl text-sm text-secondary placeholder:text-muted-foreground focus:outline-none focus:border-primary transition-colors"
  />
                </div>

                <div className="mb-6">
                  <label className="block text-xs text-muted-foreground mb-2">سبب التغيير</label>
                  <textarea
    placeholder="اذكر سبب تغيير رقم الجوال..."
    rows={3}
    className="w-full px-4 py-3 bg-gray-50 border border-border rounded-xl text-sm text-secondary placeholder:text-muted-foreground focus:outline-none focus:border-primary transition-colors resize-none"
  />
                </div>

                <div className="flex gap-3">
                  <button
    onClick={() => setShowPhoneModal(false)}
    className="flex-1 py-3 bg-gray-100 text-secondary rounded-xl hover:bg-gray-200 transition-colors"
  >
                    إلغاء
                  </button>
                  <button
    onClick={handlePhoneChangeRequest}
    className="flex-1 py-3 bg-gradient-to-br from-primary to-primary/90 text-white rounded-xl hover:shadow-lg transition-all"
  >
                    إرسال الطلب
                  </button>
                </div>
              </div> : <div className="px-6 py-8 text-center">
                <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
                  <Check className="w-8 h-8 text-green-600" />
                </div>
                <h3 className="text-lg text-secondary font-medium mb-2">تم إرسال الطلب بنجاح</h3>
                <p className="text-sm text-muted-foreground">سيتم مراجعة طلبك قريباً</p>
              </div>}
          </div>
        </div>}

      {
    /* Email Change Modal */
  }
      {showEmailModal && <div className="fixed inset-0 z-50 flex items-center justify-center p-6">
          <div className="absolute inset-0 bg-black/50 backdrop-blur-sm" onClick={() => setShowEmailModal(false)} />
          <div className="relative bg-white rounded-2xl max-w-md w-full shadow-2xl">
            <div className="bg-gradient-to-br from-green-500 to-green-600 text-white px-6 py-4 rounded-t-2xl">
              <div className="flex items-center gap-3">
                <Mail className="w-6 h-6" />
                <h2 className="text-lg font-medium">تغيير البريد الإلكتروني</h2>
              </div>
            </div>

            <div className="px-6 py-6">
              <div className="mb-4">
                <label className="block text-xs text-muted-foreground mb-2">البريد الإلكتروني الجديد</label>
                <input
    type="email"
    placeholder="example@email.com"
    className="w-full px-4 py-3 bg-gray-50 border border-border rounded-xl text-sm text-secondary placeholder:text-muted-foreground focus:outline-none focus:border-primary transition-colors"
  />
              </div>

              <div className="mb-6">
                <label className="block text-xs text-muted-foreground mb-2">تأكيد كلمة المرور</label>
                <input
    type="password"
    placeholder="••••••••"
    className="w-full px-4 py-3 bg-gray-50 border border-border rounded-xl text-sm text-secondary placeholder:text-muted-foreground focus:outline-none focus:border-primary transition-colors"
  />
              </div>

              <div className="flex gap-3">
                <button
    onClick={() => setShowEmailModal(false)}
    className="flex-1 py-3 bg-gray-100 text-secondary rounded-xl hover:bg-gray-200 transition-colors"
  >
                  إلغاء
                </button>
                <button className="flex-1 py-3 bg-gradient-to-br from-primary to-primary/90 text-white rounded-xl hover:shadow-lg transition-all">
                  تأكيد التغيير
                </button>
              </div>
            </div>
          </div>
        </div>}

      {
    /* Password Change Modal */
  }
      {showPasswordModal && <div className="fixed inset-0 z-50 flex items-center justify-center p-6">
          <div className="absolute inset-0 bg-black/50 backdrop-blur-sm" onClick={() => setShowPasswordModal(false)} />
          <div className="relative bg-white rounded-2xl max-w-md w-full shadow-2xl">
            <div className="bg-gradient-to-br from-orange-500 to-orange-600 text-white px-6 py-4 rounded-t-2xl">
              <div className="flex items-center gap-3">
                <Lock className="w-6 h-6" />
                <h2 className="text-lg font-medium">تغيير كلمة المرور</h2>
              </div>
            </div>

            <div className="px-6 py-6">
              <div className="mb-4">
                <label className="block text-xs text-muted-foreground mb-2">كلمة المرور الحالية</label>
                <input
    type="password"
    placeholder="••••••••"
    className="w-full px-4 py-3 bg-gray-50 border border-border rounded-xl text-sm text-secondary placeholder:text-muted-foreground focus:outline-none focus:border-primary transition-colors"
  />
              </div>

              <div className="mb-4">
                <label className="block text-xs text-muted-foreground mb-2">كلمة المرور الجديدة</label>
                <input
    type="password"
    placeholder="••••••••"
    className="w-full px-4 py-3 bg-gray-50 border border-border rounded-xl text-sm text-secondary placeholder:text-muted-foreground focus:outline-none focus:border-primary transition-colors"
  />
              </div>

              <div className="mb-4">
                <label className="block text-xs text-muted-foreground mb-2">تأكيد كلمة المرور الجديدة</label>
                <input
    type="password"
    placeholder="••••••••"
    className="w-full px-4 py-3 bg-gray-50 border border-border rounded-xl text-sm text-secondary placeholder:text-muted-foreground focus:outline-none focus:border-primary transition-colors"
  />
              </div>

              <div className="bg-blue-50 border border-blue-200 rounded-xl p-3 mb-6">
                <p className="text-xs text-secondary">كلمة المرور يجب أن تحتوي على 8 أحرف على الأقل، حرف كبير، حرف صغير، ورقم.</p>
              </div>

              <div className="flex gap-3">
                <button
    onClick={() => setShowPasswordModal(false)}
    className="flex-1 py-3 bg-gray-100 text-secondary rounded-xl hover:bg-gray-200 transition-colors"
  >
                  إلغاء
                </button>
                <button className="flex-1 py-3 bg-gradient-to-br from-primary to-primary/90 text-white rounded-xl hover:shadow-lg transition-all">
                  تغيير كلمة المرور
                </button>
              </div>
            </div>
          </div>
        </div>}
    </div>;
}
export {
  AccountSettings as default
};
