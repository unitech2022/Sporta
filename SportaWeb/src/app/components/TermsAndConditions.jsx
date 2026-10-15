import { ChevronRight, FileText } from "lucide-react";
function TermsAndConditions({ onBack }) {
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
            <h1 className="text-xl">الشروط والأحكام</h1>
          </div>
          <div className="w-9" />
        </div>
      </div>

      <div className="px-6 py-6 space-y-4">
        <div className="bg-blue-50 border border-blue-200 rounded-2xl p-4 mb-4">
          <div className="flex items-start gap-3">
            <FileText className="w-5 h-5 text-blue-600 mt-0.5" />
            <div>
              <p className="text-sm text-secondary mb-1 font-medium">اقرأ الشروط والأحكام بعناية</p>
              <p className="text-xs text-muted-foreground">آخر تحديث: 1 يونيو 2026</p>
            </div>
          </div>
        </div>

        <div className="bg-white border border-border rounded-2xl p-5 shadow-sm space-y-5">
          <section>
            <h2 className="text-base text-secondary font-medium mb-3">1. القبول بالشروط</h2>
            <p className="text-sm text-muted-foreground leading-relaxed">
              باستخدامك لتطبيق SPORTA، فإنك توافق على الالتزام بهذه الشروط والأحكام. إذا كنت لا توافق على أي من هذه الشروط، يرجى عدم استخدام التطبيق.
            </p>
          </section>

          <section>
            <h2 className="text-base text-secondary font-medium mb-3">2. استخدام الخدمة</h2>
            <p className="text-sm text-muted-foreground leading-relaxed mb-2">
              يجب عليك استخدام التطبيق بطريقة قانونية ومسؤولة. يُحظر عليك:
            </p>
            <ul className="text-sm text-muted-foreground space-y-2 mr-5">
              <li>• انتهاك أي قوانين محلية أو دولية</li>
              <li>• التعدي على حقوق الآخرين أو إساءة استخدامهم</li>
              <li>• نشر محتوى غير لائق أو مسيء</li>
              <li>• محاولة اختراق أو إتلاف النظام</li>
              <li>• استخدام التطبيق لأغراض تجارية غير مصرح بها</li>
            </ul>
          </section>

          <section>
            <h2 className="text-base text-secondary font-medium mb-3">3. الحسابات والتسجيل</h2>
            <p className="text-sm text-muted-foreground leading-relaxed">
              يجب عليك تقديم معلومات دقيقة وحديثة عند التسجيل. أنت مسؤول عن الحفاظ على سرية حسابك وكلمة المرور، وعن جميع الأنشطة التي تحدث تحت حسابك.
            </p>
          </section>

          <section>
            <h2 className="text-base text-secondary font-medium mb-3">4. الحجوزات والدفع</h2>
            <p className="text-sm text-muted-foreground leading-relaxed mb-2">
              جميع الحجوزات تخضع للتوافر والتأكيد. الأسعار قابلة للتغيير دون إشعار مسبق. عند إتمام الحجز:
            </p>
            <ul className="text-sm text-muted-foreground space-y-2 mr-5">
              <li>• يجب الدفع المسبق لتأكيد الحجز</li>
              <li>• الإلغاء قبل 24 ساعة يستحق استرداد كامل</li>
              <li>• الإلغاء خلال 24 ساعة قد يخضع لرسوم</li>
              <li>• عدم الحضور يؤدي لفقدان كامل المبلغ</li>
            </ul>
          </section>

          <section>
            <h2 className="text-base text-secondary font-medium mb-3">5. المحتوى والملكية الفكرية</h2>
            <p className="text-sm text-muted-foreground leading-relaxed">
              جميع المحتويات والمواد المتوفرة في التطبيق، بما في ذلك النصوص والصور والشعارات، محمية بحقوق النشر والملكية الفكرية الخاصة بـ SPORTA. لا يجوز نسخها أو توزيعها دون إذن كتابي.
            </p>
          </section>

          <section>
            <h2 className="text-base text-secondary font-medium mb-3">6. المسؤولية</h2>
            <p className="text-sm text-muted-foreground leading-relaxed">
              SPORTA غير مسؤولة عن أي إصابات أو أضرار قد تحدث أثناء استخدام المرافق الرياضية. المستخدمون مسؤولون عن صحتهم وسلامتهم الشخصية.
            </p>
          </section>

          <section>
            <h2 className="text-base text-secondary font-medium mb-3">7. التعديلات على الشروط</h2>
            <p className="text-sm text-muted-foreground leading-relaxed">
              نحتفظ بالحق في تعديل هذه الشروط في أي وقت. سيتم إخطار المستخدمين بأي تغييرات جوهرية. استمرارك في استخدام التطبيق بعد التعديلات يعني قبولك للشروط الجديدة.
            </p>
          </section>

          <section>
            <h2 className="text-base text-secondary font-medium mb-3">8. إنهاء الحساب</h2>
            <p className="text-sm text-muted-foreground leading-relaxed">
              نحتفظ بالحق في تعليق أو إنهاء حسابك في حالة انتهاك هذه الشروط. يمكنك أيضاً إنهاء حسابك في أي وقت من خلال إعدادات التطبيق.
            </p>
          </section>

          <section>
            <h2 className="text-base text-secondary font-medium mb-3">9. القانون الحاكم</h2>
            <p className="text-sm text-muted-foreground leading-relaxed">
              تخضع هذه الشروط لقوانين المملكة العربية السعودية. أي نزاع ينشأ عن استخدام التطبيق يخضع للاختصاص القضائي للمحاكم السعودية.
            </p>
          </section>

          <section>
            <h2 className="text-base text-secondary font-medium mb-3">10. الاتصال بنا</h2>
            <p className="text-sm text-muted-foreground leading-relaxed">
              إذا كان لديك أي أسئلة حول هذه الشروط، يرجى الاتصال بنا عبر البريد الإلكتروني: legal@sporta.sa
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
  TermsAndConditions as default
};
