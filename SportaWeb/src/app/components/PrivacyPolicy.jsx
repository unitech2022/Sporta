import { ChevronRight, Shield } from "lucide-react";
function PrivacyPolicy({ onBack }) {
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
            <h1 className="text-xl">سياسة الخصوصية</h1>
          </div>
          <div className="w-9" />
        </div>
      </div>

      <div className="px-6 py-6 space-y-4">
        <div className="bg-blue-50 border border-blue-200 rounded-2xl p-4 mb-4">
          <div className="flex items-start gap-3">
            <Shield className="w-5 h-5 text-blue-600 mt-0.5" />
            <div>
              <p className="text-sm text-secondary mb-1 font-medium">نحن نحترم خصوصيتك</p>
              <p className="text-xs text-muted-foreground">آخر تحديث: 1 يونيو 2026</p>
            </div>
          </div>
        </div>

        <div className="bg-white border border-border rounded-2xl p-5 shadow-sm space-y-5">
          <section>
            <h2 className="text-base text-secondary font-medium mb-3">1. المقدمة</h2>
            <p className="text-sm text-muted-foreground leading-relaxed">
              في SPORTA، نلتزم بحماية خصوصيتك. توضح هذه السياسة كيفية جمع واستخدام وحماية معلوماتك الشخصية عند استخدامك لتطبيقنا.
            </p>
          </section>

          <section>
            <h2 className="text-base text-secondary font-medium mb-3">2. المعلومات التي نجمعها</h2>
            <p className="text-sm text-muted-foreground leading-relaxed mb-2">
              نقوم بجمع عدة أنواع من المعلومات:
            </p>
            <ul className="text-sm text-muted-foreground space-y-2 mr-5">
              <li>• <span className="font-medium">معلومات الحساب:</span> الاسم، البريد الإلكتروني، رقم الهاتف</li>
              <li>• <span className="font-medium">معلومات الملف الشخصي:</span> الصورة الشخصية، المستوى الرياضي، التفضيلات</li>
              <li>• <span className="font-medium">معلومات الحجز:</span> تفاصيل الحجوزات والمباريات والدفعات</li>
              <li>• <span className="font-medium">معلومات الموقع:</span> لإظهار الملاعب القريبة (بإذنك)</li>
              <li>• <span className="font-medium">معلومات الاستخدام:</span> كيفية تفاعلك مع التطبيق</li>
            </ul>
          </section>

          <section>
            <h2 className="text-base text-secondary font-medium mb-3">3. كيف نستخدم معلوماتك</h2>
            <p className="text-sm text-muted-foreground leading-relaxed mb-2">
              نستخدم معلوماتك للأغراض التالية:
            </p>
            <ul className="text-sm text-muted-foreground space-y-2 mr-5">
              <li>• تقديم وتحسين خدماتنا</li>
              <li>• معالجة الحجوزات والدفعات</li>
              <li>• التواصل معك بشأن حسابك وحجوزاتك</li>
              <li>• تخصيص تجربتك في التطبيق</li>
              <li>• إرسال إشعارات مهمة وتحديثات</li>
              <li>• تحليل الاستخدام لتحسين التطبيق</li>
              <li>• منع الاحتيال وضمان الأمان</li>
            </ul>
          </section>

          <section>
            <h2 className="text-base text-secondary font-medium mb-3">4. مشاركة المعلومات</h2>
            <p className="text-sm text-muted-foreground leading-relaxed mb-2">
              لن نبيع معلوماتك الشخصية. قد نشارك معلوماتك فقط في الحالات التالية:
            </p>
            <ul className="text-sm text-muted-foreground space-y-2 mr-5">
              <li>• <span className="font-medium">مع الملاعب والمدربين:</span> لإتمام حجوزاتك</li>
              <li>• <span className="font-medium">مع اللاعبين الآخرين:</span> معلومات الملف الشخصي الأساسية للتواصل</li>
              <li>• <span className="font-medium">مع مزودي الخدمة:</span> لمعالجة الدفعات وإرسال الإشعارات</li>
              <li>• <span className="font-medium">للامتثال القانوني:</span> عند الطلب من الجهات المختصة</li>
            </ul>
          </section>

          <section>
            <h2 className="text-base text-secondary font-medium mb-3">5. أمان المعلومات</h2>
            <p className="text-sm text-muted-foreground leading-relaxed">
              نستخدم إجراءات أمنية متقدمة لحماية معلوماتك، بما في ذلك التشفير، وجدران الحماية، والوصول المحدود. ومع ذلك، لا يمكن ضمان أمان أي نظام بنسبة 100%.
            </p>
          </section>

          <section>
            <h2 className="text-base text-secondary font-medium mb-3">6. حقوقك</h2>
            <p className="text-sm text-muted-foreground leading-relaxed mb-2">
              لديك الحق في:
            </p>
            <ul className="text-sm text-muted-foreground space-y-2 mr-5">
              <li>• الوصول إلى معلوماتك الشخصية</li>
              <li>• تصحيح أو تحديث معلوماتك</li>
              <li>• حذف حسابك ومعلوماتك</li>
              <li>• الاعتراض على معالجة معلوماتك</li>
              <li>• تصدير بياناتك</li>
              <li>• سحب موافقتك في أي وقت</li>
            </ul>
          </section>

          <section>
            <h2 className="text-base text-secondary font-medium mb-3">7. ملفات تعريف الارتباط (Cookies)</h2>
            <p className="text-sm text-muted-foreground leading-relaxed">
              نستخدم ملفات تعريف الارتباط وتقنيات مشابهة لتحسين تجربتك، وتذكر تفضيلاتك، وتحليل استخدام التطبيق. يمكنك التحكم في ملفات تعريف الارتباط من خلال إعدادات المتصفح.
            </p>
          </section>

          <section>
            <h2 className="text-base text-secondary font-medium mb-3">8. خصوصية الأطفال</h2>
            <p className="text-sm text-muted-foreground leading-relaxed">
              تطبيقنا غير موجه للأطفال دون سن 13 عاماً. لا نجمع عن قصد معلومات شخصية من الأطفال. إذا علمنا أننا جمعنا معلومات من طفل، سنقوم بحذفها فوراً.
            </p>
          </section>

          <section>
            <h2 className="text-base text-secondary font-medium mb-3">9. الاحتفاظ بالبيانات</h2>
            <p className="text-sm text-muted-foreground leading-relaxed">
              نحتفظ بمعلوماتك طالما كان حسابك نشطاً أو حسب الحاجة لتقديم الخدمات. بعد حذف حسابك، قد نحتفظ ببعض المعلومات للامتثال القانوني أو لأغراض مشروعة.
            </p>
          </section>

          <section>
            <h2 className="text-base text-secondary font-medium mb-3">10. التعديلات على السياسة</h2>
            <p className="text-sm text-muted-foreground leading-relaxed">
              قد نقوم بتحديث هذه السياسة من وقت لآخر. سنخطرك بأي تغييرات مهمة عبر البريد الإلكتروني أو إشعار في التطبيق. استمرارك في استخدام التطبيق بعد التغييرات يعني قبولك للسياسة المحدثة.
            </p>
          </section>

          <section>
            <h2 className="text-base text-secondary font-medium mb-3">11. الاتصال بنا</h2>
            <p className="text-sm text-muted-foreground leading-relaxed">
              إذا كان لديك أي أسئلة أو مخاوف بشأن خصوصيتك، يرجى الاتصال بنا:<br />
              البريد الإلكتروني: privacy@sporta.sa<br />
              الهاتف: +966 50 123 4567
            </p>
          </section>
        </div>

        <div className="bg-gradient-to-br from-gray-50 to-gray-100/50 border border-gray-200 rounded-2xl p-4">
          <p className="text-xs text-center text-muted-foreground">
            © 2026 SPORTA. جميع الحقوق محفوظة.
          </p>
        </div>
      </div>
    </div>;
}
export {
  PrivacyPolicy as default
};
