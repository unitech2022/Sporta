import { ChevronRight, MessageCircle, Mail, ChevronLeft } from "lucide-react";
import { useState } from "react";
function ContactUs({ onBack, onNavigateToWhatsApp, onNavigateToChat }) {
  const [message, setMessage] = useState("");
  const [subject, setSubject] = useState("");
  const [emailSent, setEmailSent] = useState(false);
  const handleSendEmail = () => {
    setEmailSent(true);
    setTimeout(() => {
      setEmailSent(false);
      setMessage("");
      setSubject("");
    }, 3e3);
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
            <h1 className="text-xl">اتصل بنا</h1>
          </div>
          <div className="w-9" />
        </div>
      </div>

      <div className="px-6 py-6 space-y-4">
        <div className="bg-blue-50 border border-blue-200 rounded-2xl p-4 mb-4">
          <p className="text-sm text-secondary text-center">نحن هنا لمساعدتك! اختر طريقة التواصل المفضلة</p>
        </div>

        {
    /* طرق التواصل */
  }
        <div className="space-y-3">
          {
    /* واتساب */
  }
          <button
    onClick={onNavigateToWhatsApp}
    className="w-full bg-white border-2 border-border hover:border-green-500 rounded-2xl p-4 transition-all group"
  >
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-4">
                <div className="w-14 h-14 bg-gradient-to-br from-green-500 to-green-600 rounded-2xl flex items-center justify-center">
                  <MessageCircle className="w-7 h-7 text-white" />
                </div>
                <div className="text-right">
                  <p className="text-sm text-secondary font-medium mb-1">واتساب</p>
                  <p className="text-xs text-muted-foreground">تواصل معنا عبر الواتساب</p>
                  <p className="text-xs text-green-600 mt-1" dir="ltr">+966 56 188 3558</p>
                </div>
              </div>
              <ChevronLeft className="w-5 h-5 text-muted-foreground group-hover:text-green-500 transition-colors" />
            </div>
          </button>

          {
    /* البريد الإلكتروني */
  }
          <div className="bg-white border-2 border-border rounded-2xl p-4">
            <div className="flex items-center gap-4 mb-4">
              <div className="w-14 h-14 bg-gradient-to-br from-blue-500 to-blue-600 rounded-2xl flex items-center justify-center">
                <Mail className="w-7 h-7 text-white" />
              </div>
              <div className="flex-1 text-right">
                <p className="text-sm text-secondary font-medium mb-1">البريد الإلكتروني</p>
                <p className="text-xs text-muted-foreground">أرسل لنا رسالة عبر البريد</p>
                <p className="text-xs text-blue-600 mt-1">support@sporta.sa</p>
              </div>
            </div>

            {emailSent ? <div className="bg-green-50 border border-green-200 rounded-xl p-4 text-center">
                <p className="text-sm text-green-600 font-medium">تم إرسال رسالتك بنجاح!</p>
                <p className="text-xs text-muted-foreground mt-1">سنرد عليك في أقرب وقت</p>
              </div> : <div className="space-y-3">
                <div>
                  <label className="block text-xs text-muted-foreground mb-2">الموضوع</label>
                  <input
    type="text"
    value={subject}
    onChange={(e) => setSubject(e.target.value)}
    placeholder="اكتب موضوع الرسالة"
    className="w-full px-4 py-3 bg-gray-50 border border-border rounded-xl text-sm text-secondary placeholder:text-muted-foreground focus:outline-none focus:border-primary transition-colors"
  />
                </div>

                <div>
                  <label className="block text-xs text-muted-foreground mb-2">الرسالة</label>
                  <textarea
    value={message}
    onChange={(e) => setMessage(e.target.value)}
    placeholder="اكتب رسالتك هنا..."
    rows={4}
    className="w-full px-4 py-3 bg-gray-50 border border-border rounded-xl text-sm text-secondary placeholder:text-muted-foreground focus:outline-none focus:border-primary transition-colors resize-none"
  />
                </div>

                <button
    onClick={handleSendEmail}
    disabled={!subject.trim() || !message.trim()}
    className={`w-full py-3 rounded-xl transition-all ${subject.trim() && message.trim() ? "bg-gradient-to-br from-blue-500 to-blue-600 text-white hover:shadow-lg" : "bg-gray-200 text-gray-400 cursor-not-allowed"}`}
  >
                  إرسال الرسالة
                </button>
              </div>}
          </div>

          {
    /* الدردشة المباشرة */
  }
          <button
    onClick={onNavigateToChat}
    className="w-full bg-white border-2 border-border hover:border-primary rounded-2xl p-4 transition-all group"
  >
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-4">
                <div className="w-14 h-14 bg-gradient-to-br from-primary to-primary/90 rounded-2xl flex items-center justify-center">
                  <MessageCircle className="w-7 h-7 text-white" />
                </div>
                <div className="text-right">
                  <p className="text-sm text-secondary font-medium mb-1">الدردشة المباشرة</p>
                  <p className="text-xs text-muted-foreground">تحدث مع فريق الدعم مباشرة</p>
                  <div className="flex items-center gap-2 mt-1">
                    <div className="w-2 h-2 bg-green-500 rounded-full" />
                    <p className="text-xs text-green-600">متصل الآن</p>
                  </div>
                </div>
              </div>
              <ChevronLeft className="w-5 h-5 text-muted-foreground group-hover:text-primary transition-colors" />
            </div>
          </button>
        </div>

        {
    /* معلومات إضافية */
  }
        <div className="bg-gradient-to-br from-gray-50 to-gray-100/50 border border-gray-200 rounded-2xl p-4">
          <h3 className="text-sm text-secondary font-medium mb-3">أوقات العمل</h3>
          <div className="space-y-2 text-xs text-muted-foreground">
            <p>السبت - الخميس: 9:00 صباحاً - 6:00 مساءً</p>
            <p>الجمعة: مغلق</p>
          </div>
        </div>
      </div>
    </div>;
}
export {
  ContactUs as default
};
