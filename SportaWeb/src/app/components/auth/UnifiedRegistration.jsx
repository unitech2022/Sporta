import { useState } from "react";
import { ChevronRight, ChevronLeft, User, Mail, Phone, Camera, MapPin } from "lucide-react";
import logo from "../../../imports/new_logo.png";
function UnifiedRegistration({ onComplete, onBack }) {
  const [step, setStep] = useState(1);
  const [formData, setFormData] = useState({
    // البيانات الأساسية
    firstName: "",
    lastName: "",
    email: "",
    phone: "",
    password: "",
    country: "\u0627\u0644\u0633\u0639\u0648\u062F\u064A\u0629",
    city: "",
    district: "",
    gender: "",
    // الأدوار المختارة
    roles: [],
    // بيانات اللاعب
    playerData: {
      dominantHand: "",
      courtPosition: "",
      matchType: "",
      preferredTime: "",
      rallyAbility: "",
      glassUsage: "",
      skillDescription: "",
      netPlay: "",
      comparisonLevel: "",
      levelKnown: false,
      selectedLevel: ""
    },
    // بيانات المدرب
    coachData: {
      bio: "",
      experience: "",
      certifications: "",
      specializations: [],
      targetGender: "",
      minLevel: "0",
      maxLevel: "7",
      sessionPrice: "",
      packagePrice: "",
      courtName: "",
      availability: [],
      nationality: "\u0633\u0639\u0648\u062F\u064A"
    },
    // بيانات الملعب
    venueData: {
      venueName: "",
      ownerName: "",
      address: "",
      numberOfCourts: "",
      courtTypes: [],
      amenities: [],
      targetAudience: [],
      hourlyRate: "",
      weekdayRate: "",
      weekendRate: "",
      openingTime: "06:00",
      closingTime: "23:00",
      commercialLicense: ""
    }
  });
  const totalSteps = 3;
  const handleNext = () => {
    if (step < totalSteps) {
      setStep(step + 1);
    } else {
      onComplete(formData);
    }
  };
  const handleBack = () => {
    if (step > 1) {
      setStep(step - 1);
    } else {
      onBack();
    }
  };
  const toggleRole = (role) => {
    if (formData.roles.includes(role)) {
      setFormData({
        ...formData,
        roles: formData.roles.filter((r) => r !== role)
      });
    } else {
      setFormData({
        ...formData,
        roles: [...formData.roles, role]
      });
    }
  };
  return <div className="h-screen flex flex-col bg-background">
      <div className="bg-gradient-to-br from-secondary to-secondary/90 text-white px-6 pt-8 pb-6">
        <div className="flex items-center justify-between mb-4">
          <button onClick={handleBack} className="p-2 bg-white/20 rounded-full backdrop-blur-sm">
            <ChevronRight className="w-5 h-5" />
          </button>
          <img
    src={logo}
    alt="SPORTA Logo"
    className="w-16 h-auto"
    style={{ filter: "brightness(0) invert(1)" }}
  />
          <div className="w-9" />
        </div>
        <h1 className="text-lg text-center mb-4">إنشاء حساب جديد</h1>

        <div className="flex gap-2">
          {[1, 2, 3].map((s) => <div
    key={s}
    className={`flex-1 h-1 rounded-full transition-all ${s <= step ? "bg-primary" : "bg-white/30"}`}
  />)}
        </div>
        <p className="text-center text-sm text-white/80 mt-2">خطوة {step} من {totalSteps}</p>
      </div>

      <div className="flex-1 overflow-y-auto px-6 py-6">
        {step === 1 && <div className="space-y-5">
            <h2 className="text-2xl text-secondary mb-6">المعلومات الأساسية</h2>

            <div className="flex justify-center mb-6">
              <div className="relative">
                <div className="w-24 h-24 bg-gray-200 rounded-full flex items-center justify-center">
                  <User className="w-12 h-12 text-gray-400" />
                </div>
                <button className="absolute bottom-0 left-0 w-8 h-8 bg-primary rounded-full flex items-center justify-center shadow-lg">
                  <Camera className="w-4 h-4 text-white" />
                </button>
              </div>
            </div>

            <div>
              <label className="block text-sm text-secondary mb-2">الاسم الأول *</label>
              <input
    type="text"
    value={formData.firstName}
    onChange={(e) => setFormData({ ...formData, firstName: e.target.value })}
    placeholder="أدخل اسمك الأول"
    className="w-full bg-white border border-border rounded-xl px-4 py-3 outline-none focus:border-primary transition-colors"
  />
            </div>

            <div>
              <label className="block text-sm text-secondary mb-2">الاسم الأخير *</label>
              <input
    type="text"
    value={formData.lastName}
    onChange={(e) => setFormData({ ...formData, lastName: e.target.value })}
    placeholder="أدخل اسمك الأخير"
    className="w-full bg-white border border-border rounded-xl px-4 py-3 outline-none focus:border-primary transition-colors"
  />
            </div>

            <div>
              <label className="block text-sm text-secondary mb-2">البريد الإلكتروني *</label>
              <div className="relative">
                <Mail className="absolute right-4 top-1/2 -translate-y-1/2 w-5 h-5 text-muted-foreground" />
                <input
    type="email"
    value={formData.email}
    onChange={(e) => setFormData({ ...formData, email: e.target.value })}
    placeholder="example@email.com"
    className="w-full bg-white border border-border rounded-xl px-4 py-3 pr-12 outline-none focus:border-primary transition-colors"
  />
              </div>
            </div>

            <div>
              <label className="block text-sm text-secondary mb-2">رقم الجوال *</label>
              <div className="relative">
                <Phone className="absolute right-4 top-1/2 -translate-y-1/2 w-5 h-5 text-muted-foreground" />
                <input
    type="tel"
    value={formData.phone}
    onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
    placeholder="05xxxxxxxx"
    className="w-full bg-white border border-border rounded-xl px-4 py-3 pr-12 outline-none focus:border-primary transition-colors"
  />
              </div>
            </div>

            <div>
              <label className="block text-sm text-secondary mb-2">كلمة السر *</label>
              <input
    type="password"
    value={formData.password}
    onChange={(e) => setFormData({ ...formData, password: e.target.value })}
    placeholder="••••••••"
    className="w-full bg-white border border-border rounded-xl px-4 py-3 outline-none focus:border-primary transition-colors"
  />
            </div>

            <div>
              <label className="block text-sm text-secondary mb-2">الجنس *</label>
              <div className="grid grid-cols-2 gap-3">
                <button
    onClick={() => setFormData({ ...formData, gender: "male" })}
    className={`py-3 rounded-xl border-2 transition-all ${formData.gender === "male" ? "border-primary bg-primary/10 text-primary" : "border-border bg-white text-secondary"}`}
  >
                  ذكر
                </button>
                <button
    onClick={() => setFormData({ ...formData, gender: "female" })}
    className={`py-3 rounded-xl border-2 transition-all ${formData.gender === "female" ? "border-primary bg-primary/10 text-primary" : "border-border bg-white text-secondary"}`}
  >
                  أنثى
                </button>
              </div>
            </div>

            <div>
              <label className="block text-sm text-secondary mb-2">المدينة *</label>
              <input
    type="text"
    value={formData.city}
    onChange={(e) => setFormData({ ...formData, city: e.target.value })}
    placeholder="مثال: الرياض"
    className="w-full bg-white border border-border rounded-xl px-4 py-3 outline-none focus:border-primary transition-colors"
  />
            </div>

            <div>
              <label className="block text-sm text-secondary mb-2">الحي *</label>
              <div className="relative">
                <MapPin className="absolute right-4 top-1/2 -translate-y-1/2 w-5 h-5 text-muted-foreground" />
                <input
    type="text"
    value={formData.district}
    onChange={(e) => setFormData({ ...formData, district: e.target.value })}
    placeholder="مثال: العليا"
    className="w-full bg-white border border-border rounded-xl px-4 py-3 pr-12 outline-none focus:border-primary transition-colors"
  />
              </div>
            </div>

            <div className="bg-primary/5 border border-primary/20 rounded-xl p-4 mt-6">
              <p className="text-sm text-secondary text-center">
                💡 يمكنك بعد التسجيل الأولي من صفحتك أن تنضم كلاعب أو مدرب أو ملعب
              </p>
            </div>
          </div>}

        {step === 2 && <div className="space-y-5">
            <h2 className="text-2xl text-secondary mb-6">اختر أدوارك في التطبيق</h2>

            <div className="bg-primary/5 border border-primary/20 rounded-xl p-4 mb-6">
              <p className="text-sm text-secondary">
                💡 يمكنك اختيار أكثر من دور واحد. ستتمكن من التبديل بينهم في أي وقت
              </p>
            </div>

            <div className="space-y-3">
              <button
    onClick={() => toggleRole("player")}
    className={`w-full rounded-2xl p-5 flex items-center gap-4 transition-all border-2 ${formData.roles.includes("player") ? "border-primary bg-primary/10" : "border-border bg-white"}`}
  >
                <div className={`w-14 h-14 rounded-full flex items-center justify-center flex-shrink-0 ${formData.roles.includes("player") ? "bg-primary/20" : "bg-gray-100"}`}>
                  <User className={`w-7 h-7 ${formData.roles.includes("player") ? "text-primary" : "text-gray-400"}`} />
                </div>
                <div className="flex-1 text-right">
                  <h3 className={`text-lg mb-1 ${formData.roles.includes("player") ? "text-primary" : "text-secondary"}`}>
                    لاعب
                  </h3>
                  <p className="text-sm text-muted-foreground">احجز ملاعب، انضم للمباريات، وتتبع تقدمك</p>
                </div>
                {formData.roles.includes("player") && <div className="w-6 h-6 bg-primary rounded-full flex items-center justify-center">
                    <span className="text-white text-sm">✓</span>
                  </div>}
              </button>

              <button
    onClick={() => toggleRole("coach")}
    className={`w-full rounded-2xl p-5 flex items-center gap-4 transition-all border-2 ${formData.roles.includes("coach") ? "border-primary bg-primary/10" : "border-border bg-white"}`}
  >
                <div className={`w-14 h-14 rounded-full flex items-center justify-center flex-shrink-0 ${formData.roles.includes("coach") ? "bg-primary/20" : "bg-gray-100"}`}>
                  <User className={`w-7 h-7 ${formData.roles.includes("coach") ? "text-primary" : "text-gray-400"}`} />
                </div>
                <div className="flex-1 text-right">
                  <h3 className={`text-lg mb-1 ${formData.roles.includes("coach") ? "text-primary" : "text-secondary"}`}>
                    مدرب
                  </h3>
                  <p className="text-sm text-muted-foreground">قدم دروس تدريبية وطور مهارات اللاعبين</p>
                </div>
                {formData.roles.includes("coach") && <div className="w-6 h-6 bg-primary rounded-full flex items-center justify-center">
                    <span className="text-white text-sm">✓</span>
                  </div>}
              </button>

              <button
    onClick={() => toggleRole("venue")}
    className={`w-full rounded-2xl p-5 flex items-center gap-4 transition-all border-2 ${formData.roles.includes("venue") ? "border-primary bg-primary/10" : "border-border bg-white"}`}
  >
                <div className={`w-14 h-14 rounded-full flex items-center justify-center flex-shrink-0 ${formData.roles.includes("venue") ? "bg-primary/20" : "bg-gray-100"}`}>
                  <User className={`w-7 h-7 ${formData.roles.includes("venue") ? "text-primary" : "text-gray-400"}`} />
                </div>
                <div className="flex-1 text-right">
                  <h3 className={`text-lg mb-1 ${formData.roles.includes("venue") ? "text-primary" : "text-secondary"}`}>
                    مالك ملعب
                  </h3>
                  <p className="text-sm text-muted-foreground">أدر ملعبك، استقبل الحجوزات، ونظم البطولات</p>
                </div>
                {formData.roles.includes("venue") && <div className="w-6 h-6 bg-primary rounded-full flex items-center justify-center">
                    <span className="text-white text-sm">✓</span>
                  </div>}
              </button>
            </div>

            {formData.roles.length === 0 && <div className="bg-yellow-50 border border-yellow-200 rounded-xl p-4 mt-4">
                <p className="text-sm text-yellow-800">
                  ⚠️ يجب اختيار دور واحد على الأقل للمتابعة
                </p>
              </div>}
          </div>}

        {step === 3 && <div className="space-y-5">
            <h2 className="text-2xl text-secondary mb-6">معلومات إضافية</h2>

            <div className="bg-gradient-to-br from-primary/10 to-primary/5 border border-primary/30 rounded-2xl p-5 text-center">
              <p className="text-secondary mb-2">الأدوار المختارة:</p>
              <div className="flex justify-center gap-2 flex-wrap">
                {formData.roles.map((role) => <span key={role} className="px-4 py-2 bg-primary text-white rounded-full text-sm">
                    {role === "player" ? "\u0644\u0627\u0639\u0628" : role === "coach" ? "\u0645\u062F\u0631\u0628" : "\u0645\u0627\u0644\u0643 \u0645\u0644\u0639\u0628"}
                  </span>)}
              </div>
            </div>

            <div className="bg-white border border-border rounded-2xl p-5">
              <p className="text-secondary mb-3">
                ستتمكن من إكمال المعلومات التفصيلية لكل دور بعد إنشاء الحساب
              </p>
              <ul className="space-y-2 text-sm text-muted-foreground">
                {formData.roles.includes("player") && <li className="flex items-start gap-2">
                    <span className="text-primary">•</span>
                    <span>تفضيلات اللعب وتحديد المستوى (لاعب)</span>
                  </li>}
                {formData.roles.includes("coach") && <li className="flex items-start gap-2">
                    <span className="text-primary">•</span>
                    <span>الشهادات والتخصصات والتسعير (مدرب)</span>
                  </li>}
                {formData.roles.includes("venue") && <li className="flex items-start gap-2">
                    <span className="text-primary">•</span>
                    <span>تفاصيل الملعب والمرافق والأسعار (ملعب)</span>
                  </li>}
              </ul>
            </div>

            <div className="bg-muted border border-border rounded-xl p-4">
              <p className="text-xs text-muted-foreground">
                ℹ️ يمكنك التبديل بين الأدوار في أي وقت من القائمة الرئيسية
              </p>
            </div>
          </div>}
      </div>

      <div className="px-6 pb-6 pt-4 border-t border-border bg-white">
        <div className="flex gap-3">
          {step > 1 && <button
    onClick={handleBack}
    className="px-6 py-3 bg-gray-100 text-secondary rounded-xl flex items-center gap-2"
  >
              <ChevronRight className="w-5 h-5" />
              رجوع
            </button>}
          <button
    onClick={handleNext}
    disabled={step === 2 && formData.roles.length === 0}
    className={`flex-1 py-3 rounded-xl shadow-lg flex items-center justify-center gap-2 ${step === 2 && formData.roles.length === 0 ? "bg-gray-300 text-gray-500 cursor-not-allowed" : "bg-gradient-to-r from-primary to-primary/90 text-white"}`}
  >
            {step === totalSteps ? "\u0625\u0646\u0634\u0627\u0621 \u0627\u0644\u062D\u0633\u0627\u0628" : "\u0627\u0644\u062A\u0627\u0644\u064A"}
            {step < totalSteps && <ChevronLeft className="w-5 h-5" />}
          </button>
        </div>
      </div>
    </div>;
}
export {
  UnifiedRegistration as default
};
