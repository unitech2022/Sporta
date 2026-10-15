import { useState } from "react";
import { ChevronRight, CreditCard, CheckCircle, Lock, Wallet, Tag, Shield, ChevronDown, ChevronUp, Copy } from "lucide-react";
function PaymentPage({ onBack, onComplete, bookingDetails }) {
  const [selectedMethod, setSelectedMethod] = useState("");
  const [cardNumber, setCardNumber] = useState("");
  const [cardName, setCardName] = useState("");
  const [expiryDate, setExpiryDate] = useState("");
  const [cvv, setCvv] = useState("");
  const [showCvv, setShowCvv] = useState(false);
  const [saveCard, setSaveCard] = useState(false);
  const [promoCode, setPromoCode] = useState("");
  const [promoApplied, setPromoApplied] = useState(false);
  const [promoError, setPromoError] = useState("");
  const [showBreakdown, setShowBreakdown] = useState(false);
  const [showSuccess, setShowSuccess] = useState(false);
  const [isProcessing, setIsProcessing] = useState(false);
  const [bookingRef] = useState(`SP${Math.floor(1e5 + Math.random() * 9e5)}`);
  const booking = bookingDetails || {
    courtName: "\u0646\u0627\u062F\u064A \u0627\u0644\u0628\u0627\u062F\u0644 \u0627\u0644\u0645\u0644\u0643\u064A",
    date: "\u0627\u0644\u0633\u0628\u062A\u060C 6 \u064A\u0648\u0646\u064A\u0648",
    time: "04:00 \u0645\u0633\u0627\u0621\u064B",
    duration: "60 \u062F\u0642\u064A\u0642\u0629",
    totalPrice: 280
  };
  const walletBalance = 150;
  const subtotal = booking.totalPrice;
  const vat = Math.round(subtotal * 0.15);
  const discount = promoApplied ? Math.round(subtotal * 0.1) : 0;
  const total = subtotal + vat - discount;
  const fmtCard = (v) => {
    const n = v.replace(/\D/g, "").slice(0, 16);
    return n.match(/.{1,4}/g)?.join(" ") ?? n;
  };
  const fmtExpiry = (v) => {
    const n = v.replace(/\D/g, "").slice(0, 4);
    return n.length > 2 ? `${n.slice(0, 2)}/${n.slice(2)}` : n;
  };
  const applyPromo = () => {
    if (promoCode.trim().toUpperCase() === "SPORTA10") {
      setPromoApplied(true);
      setPromoError("");
    } else {
      setPromoError("\u0643\u0648\u062F \u0627\u0644\u062E\u0635\u0645 \u063A\u064A\u0631 \u0635\u062D\u064A\u062D \u0623\u0648 \u0645\u0646\u062A\u0647\u064A \u0627\u0644\u0635\u0644\u0627\u062D\u064A\u0629");
      setPromoApplied(false);
    }
  };
  const isFormValid = () => {
    if (!selectedMethod) return false;
    if (selectedMethod === "applepay") return true;
    if (selectedMethod === "wallet") return walletBalance >= total;
    return cardNumber.replace(/\s/g, "").length === 16 && cardName.trim() !== "" && expiryDate.length === 5 && cvv.length === 3;
  };
  const handlePayment = () => {
    if (!isFormValid()) return;
    setIsProcessing(true);
    setTimeout(() => {
      setIsProcessing(false);
      setShowSuccess(true);
      setTimeout(() => {
        onComplete && onComplete();
      }, 3e3);
    }, 2e3);
  };
  const cardBg = selectedMethod === "mada" ? "from-purple-700 to-purple-900" : selectedMethod === "visa" ? "from-blue-700 to-blue-900" : "from-gray-700 to-gray-900";
  const maskedCard = cardNumber ? cardNumber.replace(/\d(?=(?:\D*\d){4})/g, "\u2022") : "\u2022\u2022\u2022\u2022 \u2022\u2022\u2022\u2022 \u2022\u2022\u2022\u2022 \u2022\u2022\u2022\u2022";
  return <div className="flex-1 overflow-y-auto bg-background">

      {
    /* Header */
  }
      <div className="bg-gradient-to-br from-secondary to-secondary/90 text-white px-6 pt-8 pb-6">
        <div className="flex items-center gap-3 mb-1">
          <button onClick={onBack} className="p-2 bg-white/20 rounded-full backdrop-blur-sm">
            <ChevronRight className="w-5 h-5 text-white" />
          </button>
          <h1 className="text-2xl">إتمام الدفع</h1>
        </div>
        <p className="text-white/70 text-sm pr-11">آمن ومشفر بالكامل</p>
      </div>

      <div className="px-5 py-5 space-y-4 pb-10">

        {
    /* ── ملخص الحجز ── */
  }
        <div className="bg-white border border-border rounded-2xl shadow-sm overflow-hidden">
          <button
    onClick={() => setShowBreakdown((v) => !v)}
    className="w-full flex items-center justify-between px-5 py-4"
  >
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-primary/10 rounded-xl flex items-center justify-center">
                <CreditCard className="w-5 h-5 text-primary" />
              </div>
              <div className="text-right">
                <p className="text-secondary text-sm">{booking.courtName}</p>
                <p className="text-xs text-muted-foreground">{booking.date} • {booking.time}</p>
              </div>
            </div>
            <div className="flex items-center gap-2">
              <span className="text-primary text-lg">{total} ر.س</span>
              {showBreakdown ? <ChevronUp className="w-4 h-4 text-muted-foreground" /> : <ChevronDown className="w-4 h-4 text-muted-foreground" />}
            </div>
          </button>

          {showBreakdown && <div className="border-t border-border px-5 py-4 space-y-2.5 text-sm bg-gray-50">
              <div className="flex justify-between">
                <span className="text-muted-foreground">سعر الجلسة</span>
                <span className="text-secondary">{subtotal} ر.س</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">ضريبة القيمة المضافة (15٪)</span>
                <span className="text-secondary">+{vat} ر.س</span>
              </div>
              {promoApplied && <div className="flex justify-between text-green-600">
                  <span>خصم كود SPORTA10 (10٪)</span>
                  <span>-{discount} ر.س</span>
                </div>}
              <div className="flex justify-between pt-2 border-t border-border">
                <span className="text-secondary">الإجمالي</span>
                <span className="text-primary text-base">{total} ر.س</span>
              </div>
            </div>}
        </div>

        {
    /* ── كود الخصم ── */
  }
        <div className="bg-white border border-border rounded-2xl p-4 shadow-sm">
          <p className="text-secondary text-sm mb-3 flex items-center gap-2">
            <Tag className="w-4 h-4 text-primary" />
            كود الخصم
          </p>
          <div className="flex gap-2">
            <input
    value={promoCode}
    onChange={(e) => {
      setPromoCode(e.target.value.toUpperCase());
      setPromoError("");
    }}
    placeholder="أدخل الكود هنا..."
    disabled={promoApplied}
    className={`flex-1 border rounded-xl px-4 py-2.5 text-sm outline-none transition-colors ${promoApplied ? "border-green-400 bg-green-50 text-green-700" : "border-border focus:border-primary text-secondary"}`}
    dir="ltr"
  />
            <button
    onClick={promoApplied ? () => {
      setPromoApplied(false);
      setPromoCode("");
    } : applyPromo}
    className={`px-4 py-2.5 rounded-xl text-sm transition-all ${promoApplied ? "bg-green-100 text-green-700 border border-green-300" : "bg-primary text-white"}`}
  >
              {promoApplied ? "\u0625\u0632\u0627\u0644\u0629" : "\u062A\u0637\u0628\u064A\u0642"}
            </button>
          </div>
          {promoApplied && <p className="text-green-600 text-xs mt-2 flex items-center gap-1">
              <CheckCircle className="w-3.5 h-3.5" /> تم تطبيق الخصم — وفّرت {discount} ر.س
            </p>}
          {promoError && <p className="text-red-500 text-xs mt-2">{promoError}</p>}
          {!promoApplied && !promoError && <p className="text-xs text-muted-foreground mt-1.5">جرّب: <span className="text-primary font-mono">SPORTA10</span></p>}
        </div>

        {
    /* ── طرق الدفع ── */
  }
        <div>
          <p className="text-secondary text-sm mb-3">اختر طريقة الدفع</p>
          <div className="space-y-2.5">

            {
    /* المحفظة */
  }
            <button
    onClick={() => setSelectedMethod("wallet")}
    className={`w-full p-4 rounded-2xl border-2 transition-all flex items-center justify-between ${selectedMethod === "wallet" ? "border-primary bg-primary/5" : "border-border bg-white"}`}
  >
              <div className="flex items-center gap-3">
                <div className={`w-12 h-12 rounded-xl flex items-center justify-center ${selectedMethod === "wallet" ? "bg-primary text-white" : "bg-amber-50 text-amber-500"}`}>
                  <Wallet className="w-6 h-6" />
                </div>
                <div className="text-right">
                  <p className={`text-sm ${selectedMethod === "wallet" ? "text-primary" : "text-secondary"}`}>المحفظة الرقمية</p>
                  <p className="text-xs text-muted-foreground">رصيد متاح: <span className={walletBalance >= total ? "text-green-600" : "text-red-500"}>{walletBalance} ر.س</span></p>
                </div>
              </div>
              <div className="flex items-center gap-2">
                {walletBalance < total && <span className="text-xs text-red-500 bg-red-50 px-2 py-1 rounded-lg">رصيد غير كافٍ</span>}
                <div className={`w-5 h-5 rounded-full border-2 flex items-center justify-center transition-all ${selectedMethod === "wallet" ? "bg-primary border-primary" : "border-border"}`}>
                  {selectedMethod === "wallet" && <CheckCircle className="w-4 h-4 text-white" />}
                </div>
              </div>
            </button>

            {
    /* فيزا */
  }
            <button
    onClick={() => setSelectedMethod("visa")}
    className={`w-full p-4 rounded-2xl border-2 transition-all flex items-center justify-between ${selectedMethod === "visa" ? "border-primary bg-primary/5" : "border-border bg-white"}`}
  >
              <div className="flex items-center gap-3">
                <div className={`w-12 h-12 rounded-xl flex items-center justify-center ${selectedMethod === "visa" ? "bg-blue-600 text-white" : "bg-blue-50"}`}>
                  <span className={`font-bold text-sm italic ${selectedMethod === "visa" ? "text-white" : "text-blue-600"}`}>VISA</span>
                </div>
                <div className="text-right">
                  <p className={`text-sm ${selectedMethod === "visa" ? "text-primary" : "text-secondary"}`}>بطاقة فيزا</p>
                  <p className="text-xs text-muted-foreground">Visa Credit / Debit</p>
                </div>
              </div>
              <div className={`w-5 h-5 rounded-full border-2 flex items-center justify-center transition-all ${selectedMethod === "visa" ? "bg-primary border-primary" : "border-border"}`}>
                {selectedMethod === "visa" && <CheckCircle className="w-4 h-4 text-white" />}
              </div>
            </button>

            {
    /* مدى */
  }
            <button
    onClick={() => setSelectedMethod("mada")}
    className={`w-full p-4 rounded-2xl border-2 transition-all flex items-center justify-between ${selectedMethod === "mada" ? "border-primary bg-primary/5" : "border-border bg-white"}`}
  >
              <div className="flex items-center gap-3">
                <div className={`w-12 h-12 rounded-xl flex items-center justify-center ${selectedMethod === "mada" ? "bg-purple-600 text-white" : "bg-purple-50"}`}>
                  <span className={`font-bold text-sm ${selectedMethod === "mada" ? "text-white" : "text-purple-600"}`}>مدى</span>
                </div>
                <div className="text-right">
                  <p className={`text-sm ${selectedMethod === "mada" ? "text-primary" : "text-secondary"}`}>بطاقة مدى</p>
                  <p className="text-xs text-muted-foreground">Mada Debit Card</p>
                </div>
              </div>
              <div className={`w-5 h-5 rounded-full border-2 flex items-center justify-center transition-all ${selectedMethod === "mada" ? "bg-primary border-primary" : "border-border"}`}>
                {selectedMethod === "mada" && <CheckCircle className="w-4 h-4 text-white" />}
              </div>
            </button>

            {
    /* أبل باي */
  }
            <button
    onClick={() => setSelectedMethod("applepay")}
    className={`w-full p-4 rounded-2xl border-2 transition-all flex items-center justify-between ${selectedMethod === "applepay" ? "border-primary bg-primary/5" : "border-border bg-white"}`}
  >
              <div className="flex items-center gap-3">
                <div className={`w-12 h-12 rounded-xl flex items-center justify-center ${selectedMethod === "applepay" ? "bg-black" : "bg-gray-100"}`}>
                  <span className={`text-lg ${selectedMethod === "applepay" ? "text-white" : "text-gray-800"}`} />
                </div>
                <div className="text-right">
                  <p className={`text-sm ${selectedMethod === "applepay" ? "text-primary" : "text-secondary"}`}>Apple Pay</p>
                  <p className="text-xs text-muted-foreground">ادفع ببصمتك أو وجهك</p>
                </div>
              </div>
              <div className={`w-5 h-5 rounded-full border-2 flex items-center justify-center transition-all ${selectedMethod === "applepay" ? "bg-primary border-primary" : "border-border"}`}>
                {selectedMethod === "applepay" && <CheckCircle className="w-4 h-4 text-white" />}
              </div>
            </button>
          </div>
        </div>

        {
    /* ── بطاقة مرئية + نموذج ── */
  }
        {(selectedMethod === "visa" || selectedMethod === "mada") && <div className="space-y-4">
            {
    /* بطاقة مرئية */
  }
            <div className={`relative w-full h-44 rounded-2xl bg-gradient-to-br ${cardBg} p-5 shadow-lg overflow-hidden`}>
              {
    /* زخرفة */
  }
              <div className="absolute -top-10 -left-10 w-40 h-40 bg-white/10 rounded-full" />
              <div className="absolute -bottom-8 -right-8 w-32 h-32 bg-white/10 rounded-full" />

              <div className="relative flex flex-col justify-between h-full">
                <div className="flex items-start justify-between">
                  <div className="w-10 h-7 bg-yellow-300/90 rounded-md flex items-center justify-center">
                    <div className="grid grid-cols-2 gap-0.5">
                      {[0, 1, 2, 3].map((i) => <div key={i} className="w-2 h-1.5 bg-yellow-500/60 rounded-sm" />)}
                    </div>
                  </div>
                  <span className="text-white/80 text-sm italic font-bold">
                    {selectedMethod === "mada" ? "\u0645\u062F\u0649" : "VISA"}
                  </span>
                </div>
                <div>
                  <p className="text-white/60 text-xs mb-1 tracking-widest font-mono">{maskedCard}</p>
                  <div className="flex items-end justify-between">
                    <div>
                      <p className="text-white/50 text-xs">حامل البطاقة</p>
                      <p className="text-white text-sm tracking-wide">{cardName || "FULL NAME"}</p>
                    </div>
                    <div className="text-right">
                      <p className="text-white/50 text-xs">تنتهي في</p>
                      <p className="text-white text-sm font-mono">{expiryDate || "MM/YY"}</p>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {
    /* النموذج */
  }
            <div className="bg-white border border-border rounded-2xl p-5 shadow-sm space-y-4">
              <p className="text-secondary text-sm">بيانات البطاقة</p>

              {
    /* رقم البطاقة */
  }
              <div>
                <label className="block text-xs text-muted-foreground mb-1.5">رقم البطاقة *</label>
                <div className="relative">
                  <input
    type="text"
    value={cardNumber}
    onChange={(e) => setCardNumber(fmtCard(e.target.value))}
    placeholder="1234 5678 9012 3456"
    className="w-full border border-border rounded-xl px-4 py-3 pr-11 outline-none focus:border-primary text-secondary text-sm transition-colors"
    dir="ltr"
    inputMode="numeric"
  />
                  <CreditCard className="absolute right-3 top-1/2 -translate-y-1/2 w-5 h-5 text-primary/60" />
                </div>
              </div>

              {
    /* اسم حامل البطاقة */
  }
              <div>
                <label className="block text-xs text-muted-foreground mb-1.5">اسم حامل البطاقة *</label>
                <input
    type="text"
    value={cardName}
    onChange={(e) => setCardName(e.target.value.toUpperCase())}
    placeholder="FULL NAME"
    className="w-full border border-border rounded-xl px-4 py-3 outline-none focus:border-primary text-secondary text-sm transition-colors tracking-widest"
    dir="ltr"
  />
              </div>

              {
    /* تاريخ الانتهاء & CVV */
  }
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs text-muted-foreground mb-1.5">تاريخ الانتهاء *</label>
                  <input
    type="text"
    value={expiryDate}
    onChange={(e) => setExpiryDate(fmtExpiry(e.target.value))}
    placeholder="MM/YY"
    className="w-full border border-border rounded-xl px-4 py-3 outline-none focus:border-primary text-secondary text-sm transition-colors"
    dir="ltr"
    inputMode="numeric"
  />
                </div>
                <div>
                  <label className="block text-xs text-muted-foreground mb-1.5">CVV *</label>
                  <div className="relative">
                    <input
    type={showCvv ? "text" : "password"}
    value={cvv}
    onChange={(e) => setCvv(e.target.value.replace(/\D/g, "").slice(0, 3))}
    placeholder="•••"
    className="w-full border border-border rounded-xl px-4 py-3 pr-10 outline-none focus:border-primary text-secondary text-sm transition-colors"
    dir="ltr"
    inputMode="numeric"
  />
                    <button
    type="button"
    onClick={() => setShowCvv((v) => !v)}
    className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground"
  >
                      <Shield className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              </div>

              {
    /* حفظ البطاقة */
  }
              <button
    onClick={() => setSaveCard((v) => !v)}
    className="flex items-center gap-3 w-full"
  >
                <div className={`w-5 h-5 rounded-md border-2 flex items-center justify-center transition-all ${saveCard ? "bg-primary border-primary" : "border-border"}`}>
                  {saveCard && <CheckCircle className="w-3.5 h-3.5 text-white" />}
                </div>
                <span className="text-sm text-secondary">حفظ البطاقة للمرة القادمة</span>
              </button>
            </div>
          </div>}

        {
    /* رصيد غير كافٍ */
  }
        {selectedMethod === "wallet" && walletBalance < total && <div className="bg-red-50 border border-red-200 rounded-2xl p-4 text-center">
            <p className="text-red-600 text-sm mb-1">رصيد المحفظة غير كافٍ</p>
            <p className="text-xs text-red-400">الرصيد المتاح {walletBalance} ر.س • المطلوب {total} ر.س</p>
            <button className="mt-3 px-5 py-2 bg-red-500 text-white text-sm rounded-xl">
              شحن المحفظة
            </button>
          </div>}

        {
    /* Apple Pay */
  }
        {selectedMethod === "applepay" && <div className="bg-black rounded-2xl p-6 text-center">
            <span className="text-white text-4xl block mb-2" />
            <p className="text-white text-sm mb-1">Apple Pay</p>
            <p className="text-white/60 text-xs">اضغط "إتمام الدفع" ثم تحقق بالبصمة أو Face ID</p>
          </div>}

        {
    /* أمان */
  }
        <div className="bg-green-50 border border-green-200 rounded-2xl p-4 flex items-center gap-3">
          <Lock className="w-5 h-5 text-green-600 flex-shrink-0" />
          <div>
            <p className="text-green-700 text-sm">دفع آمن ومشفر بـ SSL 256-bit</p>
            <p className="text-green-500 text-xs">بياناتك محمية ولن تُشارَك مع أي طرف ثالث</p>
          </div>
        </div>

        {
    /* زر الدفع */
  }
        <div className="flex gap-3 pt-1">
          <button
    onClick={onBack}
    disabled={isProcessing}
    className="px-5 py-4 bg-gray-100 text-secondary rounded-xl text-sm disabled:opacity-50"
  >
            رجوع
          </button>
          <button
    onClick={handlePayment}
    disabled={!isFormValid() || isProcessing}
    className={`flex-1 py-4 rounded-xl shadow-lg transition-all text-sm flex items-center justify-center gap-2 ${isFormValid() && !isProcessing ? "bg-primary text-white hover:bg-primary/90" : "bg-gray-200 text-gray-400 cursor-not-allowed"}`}
  >
            {isProcessing ? <>
                <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                جاري المعالجة...
              </> : <>
                <Lock className="w-4 h-4" />
                إتمام الدفع — {total} ر.س
              </>}
          </button>
        </div>
      </div>

      {
    /* ── شاشة النجاح ── */
  }
      {showSuccess && <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-end justify-center z-50" style={{ maxWidth: "430px", margin: "0 auto", left: 0, right: 0 }}>
          <div className="bg-white rounded-t-3xl w-full p-7 shadow-2xl">
            {
    /* أيقونة النجاح */
  }
            <div className="flex justify-center mb-5">
              <div className="relative">
                <div className="w-24 h-24 bg-green-100 rounded-full flex items-center justify-center">
                  <CheckCircle className="w-14 h-14 text-green-500" />
                </div>
                <div className="absolute -top-1 -right-1 w-8 h-8 bg-primary rounded-full flex items-center justify-center">
                  <span className="text-white text-xs">🎾</span>
                </div>
              </div>
            </div>

            <h2 className="text-2xl text-secondary text-center mb-1">تم الدفع بنجاح!</h2>
            <p className="text-muted-foreground text-sm text-center mb-6">تم تأكيد حجزك وإرسال التفاصيل على واتساب</p>

            {
    /* تفاصيل الحجز */
  }
            <div className="bg-gray-50 rounded-2xl p-4 space-y-3 mb-5">
              <div className="flex items-center justify-between text-sm">
                <span className="text-muted-foreground">رقم الحجز</span>
                <div className="flex items-center gap-2">
                  <span className="text-secondary font-mono">#{bookingRef}</span>
                  <button className="p-1 bg-gray-200 rounded-md">
                    <Copy className="w-3 h-3 text-secondary" />
                  </button>
                </div>
              </div>
              <div className="flex items-center justify-between text-sm">
                <span className="text-muted-foreground">الملعب</span>
                <span className="text-secondary">{booking.courtName}</span>
              </div>
              <div className="flex items-center justify-between text-sm">
                <span className="text-muted-foreground">الموعد</span>
                <span className="text-secondary">{booking.date} — {booking.time}</span>
              </div>
              <div className="flex items-center justify-between text-sm pt-2 border-t border-border">
                <span className="text-muted-foreground">المبلغ المدفوع</span>
                <span className="text-green-600">{total} ر.س</span>
              </div>
            </div>

            {
    /* شريط الأيقونات */
  }
            <div className="grid grid-cols-3 gap-3 mb-5">
              {[
    { icon: "\u{1F4C5}", label: "\u0623\u0636\u0641 \u0644\u0644\u062A\u0642\u0648\u064A\u0645" },
    { icon: "\u{1F4CD}", label: "\u0627\u0644\u0627\u062A\u062C\u0627\u0647\u0627\u062A" },
    { icon: "\u{1F4F2}", label: "\u0634\u0627\u0631\u0643 \u0627\u0644\u062D\u062C\u0632" }
  ].map((item) => <button key={item.label} className="flex flex-col items-center gap-1.5 py-3 bg-gray-50 rounded-xl border border-border hover:border-primary/40 transition-colors">
                  <span className="text-xl">{item.icon}</span>
                  <span className="text-xs text-muted-foreground">{item.label}</span>
                </button>)}
            </div>

            <button
    onClick={() => {
      onComplete && onComplete();
    }}
    className="w-full py-4 bg-primary text-white rounded-xl text-sm"
  >
              العودة للرئيسية
            </button>
          </div>
        </div>}
    </div>;
}
export {
  PaymentPage as default
};
