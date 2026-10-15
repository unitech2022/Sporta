import { ChevronRight, DollarSign, Clock, XCircle, CheckCircle } from "lucide-react";
function RefundPolicy({ onBack }) {
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
            <h1 className="text-xl">سياسة الاسترجاع</h1>
          </div>
          <div className="w-9" />
        </div>
      </div>

      <div className="px-6 py-6 space-y-4">
        <div className="bg-blue-50 border border-blue-200 rounded-2xl p-4 mb-4">
          <div className="flex items-start gap-3">
            <DollarSign className="w-5 h-5 text-blue-600 mt-0.5" />
            <div>
              <p className="text-sm text-secondary mb-1 font-medium">سياسة واضحة وعادلة للاسترجاع</p>
              <p className="text-xs text-muted-foreground">آخر تحديث: 1 يونيو 2026</p>
            </div>
          </div>
        </div>

        <div className="bg-white border border-border rounded-2xl p-5 shadow-sm space-y-5">
          <section>
            <h2 className="text-base text-secondary font-medium mb-3">1. نظرة عامة</h2>
            <p className="text-sm text-muted-foreground leading-relaxed">
              نسعى في SPORTA لتوفير تجربة مرضية لجميع مستخدمينا. توضح هذه السياسة شروط وأحكام استرجاع المبالغ المدفوعة للحجوزات والخدمات المختلفة.
            </p>
          </section>

          <section>
            <h2 className="text-base text-secondary font-medium mb-3">2. حجوزات الملاعب</h2>

            <div className="bg-green-50 border-2 border-green-200 rounded-xl p-4 mb-3">
              <div className="flex items-start gap-3">
                <CheckCircle className="w-5 h-5 text-green-600 mt-0.5 flex-shrink-0" />
                <div>
                  <p className="text-sm text-secondary font-medium mb-2">الإلغاء قبل 24 ساعة أو أكثر</p>
                  <p className="text-xs text-muted-foreground">استرجاع كامل المبلغ (100%)</p>
                </div>
              </div>
            </div>

            <div className="bg-yellow-50 border-2 border-yellow-200 rounded-xl p-4 mb-3">
              <div className="flex items-start gap-3">
                <Clock className="w-5 h-5 text-yellow-600 mt-0.5 flex-shrink-0" />
                <div>
                  <p className="text-sm text-secondary font-medium mb-2">الإلغاء قبل 12-24 ساعة</p>
                  <p className="text-xs text-muted-foreground">استرجاع 50% من المبلغ</p>
                </div>
              </div>
            </div>

            <div className="bg-red-50 border-2 border-red-200 rounded-xl p-4">
              <div className="flex items-start gap-3">
                <XCircle className="w-5 h-5 text-red-600 mt-0.5 flex-shrink-0" />
                <div>
                  <p className="text-sm text-secondary font-medium mb-2">الإلغاء قبل أقل من 12 ساعة أو عدم الحضور</p>
                  <p className="text-xs text-muted-foreground">لا يوجد استرجاع (0%)</p>
                </div>
              </div>
            </div>
          </section>

          <section>
            <h2 className="text-base text-secondary font-medium mb-3">3. حصص التدريب</h2>
            <ul className="text-sm text-muted-foreground space-y-3">
              <li className="flex items-start gap-2">
                <span className="text-primary mt-1">•</span>
                <span><span className="font-medium">الحصص الفردية:</span> الإلغاء قبل 48 ساعة يستحق استرجاع 100%، قبل 24 ساعة 50%، وبعد ذلك لا يوجد استرجاع.</span>
              </li>
              <li className="flex items-start gap-2">
                <span className="text-primary mt-1">•</span>
                <span><span className="font-medium">الحصص الجماعية:</span> الإلغاء قبل 72 ساعة يستحق استرجاع 100%، قبل 48 ساعة 50%، وبعد ذلك لا يوجد استرجاع.</span>
              </li>
              <li className="flex items-start gap-2">
                <span className="text-primary mt-1">•</span>
                <span><span className="font-medium">الباقات التدريبية:</span> يمكن استرجاع الباقة غير المستخدمة خلال 7 أيام من الشراء بنسبة 80%.</span>
              </li>
            </ul>
          </section>

          <section>
            <h2 className="text-base text-secondary font-medium mb-3">4. البطولات والفعاليات</h2>
            <ul className="text-sm text-muted-foreground space-y-3">
              <li className="flex items-start gap-2">
                <span className="text-primary mt-1">•</span>
                <span>الإلغاء قبل أسبوع من البطولة: استرجاع 90%</span>
              </li>
              <li className="flex items-start gap-2">
                <span className="text-primary mt-1">•</span>
                <span>الإلغاء قبل 3-7 أيام: استرجاع 50%</span>
              </li>
              <li className="flex items-start gap-2">
                <span className="text-primary mt-1">•</span>
                <span>الإلغاء قبل أقل من 3 أيام: لا يوجد استرجاع</span>
              </li>
              <li className="flex items-start gap-2">
                <span className="text-primary mt-1">•</span>
                <span>في حالة إلغاء البطولة من المنظم: استرجاع كامل 100%</span>
              </li>
            </ul>
          </section>

          <section>
            <h2 className="text-base text-secondary font-medium mb-3">5. الحالات الاستثنائية</h2>
            <p className="text-sm text-muted-foreground leading-relaxed mb-2">
              قد نوافق على استرجاع كامل في الحالات التالية:
            </p>
            <ul className="text-sm text-muted-foreground space-y-2 mr-5">
              <li>• حالات طوارئ طبية موثقة</li>
              <li>• ظروف جوية قاهرة تمنع اللعب</li>
              <li>• إلغاء الخدمة من قبل الملعب أو المدرب</li>
              <li>• مشاكل فنية في التطبيق منعت الاستخدام</li>
              <li>• أخطاء في الحجز من جانبنا</li>
            </ul>
            <p className="text-sm text-muted-foreground leading-relaxed mt-3">
              يجب تقديم الوثائق اللازمة (تقرير طبي، إثبات إلغاء، إلخ) للموافقة على الاسترجاع.
            </p>
          </section>

          <section>
            <h2 className="text-base text-secondary font-medium mb-3">6. طريقة الاسترجاع</h2>
            <ul className="text-sm text-muted-foreground space-y-2 mr-5">
              <li>• سيتم استرجاع المبلغ إلى نفس وسيلة الدفع المستخدمة</li>
              <li>• الاسترجاع إلى المحفظة الإلكترونية يتم فوراً</li>
              <li>• الاسترجاع إلى البطاقة البنكية يستغرق 3-7 أيام عمل</li>
              <li>• سيتم إرسال إشعار بتأكيد الاسترجاع</li>
            </ul>
          </section>

          <section>
            <h2 className="text-base text-secondary font-medium mb-3">7. كيفية طلب الاسترجاع</h2>
            <p className="text-sm text-muted-foreground leading-relaxed mb-2">
              لطلب استرجاع المبلغ:
            </p>
            <ol className="text-sm text-muted-foreground space-y-2 mr-5">
              <li>1. انتقل إلى "حجوزاتي" في التطبيق</li>
              <li>2. اختر الحجز الذي تريد إلغاءه</li>
              <li>3. اضغط على "إلغاء الحجز"</li>
              <li>4. اختر سبب الإلغاء</li>
              <li>5. أرفق أي وثائق داعمة إن وجدت</li>
              <li>6. أكد طلب الإلغاء</li>
            </ol>
            <p className="text-sm text-muted-foreground leading-relaxed mt-3">
              أو تواصل مع فريق الدعم عبر: support@sporta.sa
            </p>
          </section>

          <section>
            <h2 className="text-base text-secondary font-medium mb-3">8. المبالغ غير القابلة للاسترجاع</h2>
            <ul className="text-sm text-muted-foreground space-y-2 mr-5">
              <li>• رسوم الخدمة الإدارية (إن وجدت)</li>
              <li>• الخصومات والعروض الخاصة المستخدمة</li>
              <li>• الاشتراكات الشهرية بعد استخدامها</li>
              <li>• البطاقات الهدية والكوبونات</li>
            </ul>
          </section>

          <section>
            <h2 className="text-base text-secondary font-medium mb-3">9. النزاعات</h2>
            <p className="text-sm text-muted-foreground leading-relaxed">
              إذا كنت غير راضٍ عن قرار الاسترجاع، يمكنك تقديم طعن خلال 14 يوماً من تاريخ القرار. سيتم مراجعة طلبك من قبل فريق متخصص والرد خلال 5 أيام عمل.
            </p>
          </section>

          <section>
            <h2 className="text-base text-secondary font-medium mb-3">10. الاتصال بنا</h2>
            <p className="text-sm text-muted-foreground leading-relaxed">
              لأي استفسارات حول سياسة الاسترجاع:<br />
              البريد الإلكتروني: refunds@sporta.sa<br />
              الهاتف: +966 50 123 4567<br />
              أوقات العمل: السبت - الخميس، 9:00 صباحاً - 6:00 مساءً
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
  RefundPolicy as default
};
