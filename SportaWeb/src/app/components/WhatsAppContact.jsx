import { ChevronRight, MessageCircle, Phone, Clock, CheckCircle } from "lucide-react";
import { useState } from "react";
function WhatsAppContact({ onBack }) {
  const [selectedMessage, setSelectedMessage] = useState("");
  const phoneNumber = "966561883558";
  const quickMessages = [
    { id: 1, text: "\u0645\u0631\u062D\u0628\u0627\u064B\u060C \u0623\u0631\u063A\u0628 \u0641\u064A \u0627\u0644\u0627\u0633\u062A\u0641\u0633\u0627\u0631 \u0639\u0646 \u062D\u062C\u0632 \u0645\u0644\u0639\u0628" },
    { id: 2, text: "\u0644\u062F\u064A \u0633\u0624\u0627\u0644 \u0639\u0646 \u062D\u0635\u0635 \u0627\u0644\u062A\u062F\u0631\u064A\u0628" },
    { id: 3, text: "\u0623\u0631\u064A\u062F \u0645\u0639\u0631\u0641\u0629 \u0627\u0644\u0645\u0632\u064A\u062F \u0639\u0646 \u0627\u0644\u0628\u0637\u0648\u0644\u0627\u062A \u0627\u0644\u0642\u0627\u062F\u0645\u0629" },
    { id: 4, text: "\u0644\u062F\u064A \u0645\u0634\u0643\u0644\u0629 \u0641\u064A \u0627\u0644\u062A\u0637\u0628\u064A\u0642 \u0648\u0623\u062D\u062A\u0627\u062C \u0627\u0644\u0645\u0633\u0627\u0639\u062F\u0629" },
    { id: 5, text: "\u0627\u0633\u062A\u0641\u0633\u0627\u0631 \u0639\u0646 \u0627\u0644\u062F\u0641\u0639 \u0648\u0627\u0644\u0645\u062D\u0641\u0638\u0629 \u0627\u0644\u0625\u0644\u0643\u062A\u0631\u0648\u0646\u064A\u0629" }
  ];
  const handleOpenWhatsApp = (message) => {
    const text = message || selectedMessage || "\u0645\u0631\u062D\u0628\u0627\u064B\u060C \u0623\u062D\u062A\u0627\u062C \u0625\u0644\u0649 \u0627\u0644\u0645\u0633\u0627\u0639\u062F\u0629";
    const encodedText = encodeURIComponent(text);
    const whatsappUrl = `https://wa.me/${phoneNumber}?text=${encodedText}`;
    window.open(whatsappUrl, "_blank");
  };
  return <div className="flex-1 overflow-y-auto bg-background">
      {
    /* Header */
  }
      <div className="bg-gradient-to-br from-green-500 to-green-600 text-white px-6 pt-8 pb-6">
        <div className="flex justify-between items-start mb-4">
          <button onClick={onBack} className="p-2 bg-white/20 rounded-full backdrop-blur-sm hover:bg-white/30 transition-colors">
            <ChevronRight className="w-5 h-5" />
          </button>
          <div className="text-center flex-1">
            <h1 className="text-xl">تواصل عبر واتساب</h1>
          </div>
          <div className="w-9" />
        </div>
      </div>

      <div className="px-6 py-6 space-y-5">
        {
    /* WhatsApp Card */
  }
        <div className="bg-gradient-to-br from-green-50 to-green-100/50 border-2 border-green-200 rounded-2xl p-5 shadow-sm">
          <div className="flex items-center justify-center mb-4">
            <div className="w-20 h-20 bg-gradient-to-br from-green-500 to-green-600 rounded-full flex items-center justify-center shadow-lg">
              <MessageCircle className="w-10 h-10 text-white" />
            </div>
          </div>

          <h2 className="text-lg text-secondary font-medium text-center mb-2">
            دعم SPORTA على واتساب
          </h2>
          <p className="text-sm text-muted-foreground text-center mb-4">
            تواصل معنا مباشرة عبر الواتساب للحصول على إجابات سريعة
          </p>

          <div className="bg-white rounded-xl p-4 mb-4">
            <div className="flex items-center justify-center gap-2 mb-2">
              <Phone className="w-4 h-4 text-green-600" />
              <p className="text-base text-secondary font-medium text-center" dir="ltr">
                +966 56 188 3558
              </p>
            </div>
            <p className="text-xs text-muted-foreground text-center">
              انقر على الزر أدناه للبدء في المحادثة
            </p>
          </div>

          <button
    onClick={() => handleOpenWhatsApp()}
    className="w-full py-4 bg-gradient-to-br from-green-500 to-green-600 text-white rounded-xl hover:shadow-lg transition-all font-medium flex items-center justify-center gap-2"
  >
            <MessageCircle className="w-5 h-5" />
            <span>فتح محادثة واتساب</span>
          </button>
        </div>

        {
    /* Working Hours */
  }
        <div className="bg-white border border-border rounded-2xl p-4 shadow-sm">
          <div className="flex items-center gap-3 mb-3">
            <div className="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center">
              <Clock className="w-5 h-5 text-blue-600" />
            </div>
            <h3 className="text-base text-secondary font-medium">أوقات العمل</h3>
          </div>
          <div className="space-y-2 mr-13">
            <div className="flex items-center justify-between py-2 border-b border-border">
              <span className="text-sm text-muted-foreground">السبت - الخميس</span>
              <span className="text-sm text-secondary font-medium">9:00 ص - 6:00 م</span>
            </div>
            <div className="flex items-center justify-between py-2">
              <span className="text-sm text-muted-foreground">الجمعة</span>
              <span className="text-sm text-red-600 font-medium">مغلق</span>
            </div>
          </div>
        </div>

        {
    /* Quick Messages */
  }
        <div className="bg-white border border-border rounded-2xl p-4 shadow-sm">
          <h3 className="text-base text-secondary font-medium mb-4">رسائل سريعة</h3>
          <p className="text-xs text-muted-foreground mb-3">اختر موضوع الاستفسار:</p>

          <div className="space-y-2">
            {quickMessages.map((msg) => <button
    key={msg.id}
    onClick={() => handleOpenWhatsApp(msg.text)}
    className="w-full text-right p-3 bg-gray-50 rounded-lg hover:bg-green-50 hover:border-green-200 border border-transparent transition-all group"
  >
                <div className="flex items-center justify-between">
                  <p className="text-sm text-secondary group-hover:text-green-600 transition-colors">
                    {msg.text}
                  </p>
                  <MessageCircle className="w-4 h-4 text-gray-400 group-hover:text-green-600 transition-colors" />
                </div>
              </button>)}
          </div>
        </div>

        {
    /* Features */
  }
        <div className="bg-gradient-to-br from-blue-50 to-blue-100/50 border border-blue-200 rounded-2xl p-5 shadow-sm">
          <h3 className="text-base text-secondary font-medium mb-4 text-center">
            لماذا التواصل عبر واتساب؟
          </h3>
          <div className="space-y-3">
            <div className="flex items-start gap-3">
              <div className="mt-1">
                <CheckCircle className="w-5 h-5 text-green-600" />
              </div>
              <div>
                <p className="text-sm text-secondary font-medium">ردود سريعة</p>
                <p className="text-xs text-muted-foreground">احصل على إجابات خلال دقائق</p>
              </div>
            </div>
            <div className="flex items-start gap-3">
              <div className="mt-1">
                <CheckCircle className="w-5 h-5 text-green-600" />
              </div>
              <div>
                <p className="text-sm text-secondary font-medium">تواصل مباشر</p>
                <p className="text-xs text-muted-foreground">تحدث مع فريق الدعم مباشرةً</p>
              </div>
            </div>
            <div className="flex items-start gap-3">
              <div className="mt-1">
                <CheckCircle className="w-5 h-5 text-green-600" />
              </div>
              <div>
                <p className="text-sm text-secondary font-medium">إرسال الملفات</p>
                <p className="text-xs text-muted-foreground">شارك الصور والمستندات بسهولة</p>
              </div>
            </div>
            <div className="flex items-start gap-3">
              <div className="mt-1">
                <CheckCircle className="w-5 h-5 text-green-600" />
              </div>
              <div>
                <p className="text-sm text-secondary font-medium">رسائل صوتية</p>
                <p className="text-xs text-muted-foreground">اشرح مشكلتك بالصوت</p>
              </div>
            </div>
          </div>
        </div>

        {
    /* Custom Message Input */
  }
        <div className="bg-white border border-border rounded-2xl p-4 shadow-sm">
          <h3 className="text-base text-secondary font-medium mb-3">أو اكتب رسالتك الخاصة</h3>
          <textarea
    value={selectedMessage}
    onChange={(e) => setSelectedMessage(e.target.value)}
    placeholder="اكتب رسالتك هنا..."
    className="w-full bg-gray-50 border border-border rounded-lg px-4 py-3 text-sm text-secondary placeholder:text-muted-foreground resize-none outline-none focus:border-primary transition-colors"
    rows={4}
  />
          <button
    onClick={() => handleOpenWhatsApp(selectedMessage)}
    disabled={!selectedMessage.trim()}
    className={`w-full mt-3 py-3 rounded-xl font-medium transition-all ${selectedMessage.trim() ? "bg-gradient-to-br from-green-500 to-green-600 text-white hover:shadow-lg" : "bg-gray-200 text-gray-400 cursor-not-allowed"}`}
  >
            إرسال عبر واتساب
          </button>
        </div>

        {
    /* Info Note */
  }
        <div className="bg-yellow-50 border border-yellow-200 rounded-2xl p-4">
          <p className="text-xs text-center text-muted-foreground leading-relaxed">
            عند النقر على أي من الأزرار أعلاه، سيتم فتح تطبيق واتساب على جهازك تلقائياً
          </p>
        </div>
      </div>
    </div>;
}
export {
  WhatsAppContact as default
};
