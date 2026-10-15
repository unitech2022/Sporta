import { useState } from "react";
import { ChevronRight, ChevronLeft, User, Mail, Phone, MapPin, Camera, Award, FileText, Upload } from "lucide-react";
function CoachRegistration({ onComplete, onBack }) {
  const [step, setStep] = useState(1);
  const [formData, setFormData] = useState({
    firstName: "",
    lastName: "",
    email: "",
    phone: "",
    password: "",
    country: "\u0627\u0644\u0633\u0639\u0648\u062F\u064A\u0629",
    city: "",
    district: "",
    gender: "",
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
    nationality: "\u0633\u0639\u0648\u062F\u064A",
    nationalIdFront: null,
    nationalIdBack: null,
    iqamaFront: null,
    iqamaBack: null
  });
  const totalSteps = 4;
  const handleNext = () => {
    if (step < totalSteps) {
      setStep(step + 1);
    } else {
      onComplete();
    }
  };
  const handleBack = () => {
    if (step > 1) {
      setStep(step - 1);
    } else {
      onBack();
    }
  };
  const toggleSpecialization = (spec) => {
    if (formData.specializations.includes(spec)) {
      setFormData({
        ...formData,
        specializations: formData.specializations.filter((s) => s !== spec)
      });
    } else {
      setFormData({
        ...formData,
        specializations: [...formData.specializations, spec]
      });
    }
  };
  const toggleAvailability = (time) => {
    if (formData.availability.includes(time)) {
      setFormData({
        ...formData,
        availability: formData.availability.filter((t) => t !== time)
      });
    } else {
      setFormData({
        ...formData,
        availability: [...formData.availability, time]
      });
    }
  };
  return <div className="h-screen flex flex-col bg-background">
      <div className="bg-gradient-to-br from-secondary to-secondary/90 text-white px-6 pt-8 pb-6">
        <div className="flex items-center justify-between mb-6">
          <button onClick={handleBack} className="p-2 bg-white/20 rounded-full backdrop-blur-sm">
            <ChevronRight className="w-5 h-5" />
          </button>
          <h1 className="text-xl">تسجيل مدرب جديد</h1>
          <div className="w-9" />
        </div>

        <div className="flex gap-2">
          {[1, 2, 3, 4].map((s) => <div
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
              <label className="block text-sm text-secondary mb-2">نبذة عنك *</label>
              <textarea
    value={formData.bio}
    onChange={(e) => setFormData({ ...formData, bio: e.target.value })}
    placeholder="اكتب نبذة مختصرة عن خبرتك وأسلوبك في التدريب..."
    rows={4}
    className="w-full bg-white border border-border rounded-xl px-4 py-3 outline-none focus:border-primary transition-colors resize-none"
  />
            </div>
          </div>}

        {step === 2 && <div className="space-y-5">
            <h2 className="text-2xl text-secondary mb-6">الخبرة والتخصصات</h2>

            <div>
              <label className="block text-sm text-secondary mb-2">سنوات الخبرة *</label>
              <select
    value={formData.experience}
    onChange={(e) => setFormData({ ...formData, experience: e.target.value })}
    className="w-full bg-white border border-border rounded-xl px-4 py-3 outline-none focus:border-primary transition-colors"
  >
                <option value="">اختر الخبرة</option>
                <option value="أقل من سنة">أقل من سنة</option>
                <option value="1-3 سنوات">1-3 سنوات</option>
                <option value="3-5 سنوات">3-5 سنوات</option>
                <option value="5-10 سنوات">5-10 سنوات</option>
                <option value="أكثر من 10 سنوات">أكثر من 10 سنوات</option>
              </select>
            </div>

            <div>
              <label className="block text-sm text-secondary mb-2">الشهادات والاعتمادات</label>
              <div className="relative">
                <FileText className="absolute right-4 top-4 w-5 h-5 text-muted-foreground" />
                <textarea
    value={formData.certifications}
    onChange={(e) => setFormData({ ...formData, certifications: e.target.value })}
    placeholder="اذكر شهاداتك واعتماداتك التدريبية..."
    rows={3}
    className="w-full bg-white border border-border rounded-xl px-4 py-3 pr-12 outline-none focus:border-primary transition-colors resize-none"
  />
              </div>
            </div>

            <div>
              <label className="block text-sm text-secondary mb-3">التخصصات *</label>
              <div className="space-y-2">
                {[
    "\u062A\u062F\u0631\u064A\u0628 \u0645\u0628\u062A\u062F\u0626\u064A\u0646",
    "\u062A\u0642\u0646\u064A\u0627\u062A \u0645\u062A\u0642\u062F\u0645\u0629",
    "\u0627\u0633\u062A\u0631\u0627\u062A\u064A\u062C\u064A\u0629 \u0627\u0644\u0644\u0639\u0628",
    "\u0627\u0644\u0644\u064A\u0627\u0642\u0629 \u0627\u0644\u0628\u062F\u0646\u064A\u0629",
    "\u0627\u0644\u062A\u062D\u0644\u064A\u0644 \u0627\u0644\u0641\u0646\u064A",
    "\u0625\u0639\u062F\u0627\u062F \u0627\u062D\u062A\u0631\u0627\u0641\u064A",
    "\u062A\u0643\u062A\u064A\u0643 \u0627\u0644\u0645\u0646\u0627\u0641\u0633\u0627\u062A"
  ].map((spec) => <button
    key={spec}
    onClick={() => toggleSpecialization(spec)}
    className={`w-full py-3 rounded-xl border-2 transition-all ${formData.specializations.includes(spec) ? "border-primary bg-primary/10 text-primary" : "border-border bg-white text-secondary"}`}
  >
                    {spec}
                    {formData.specializations.includes(spec) && " \u2713"}
                  </button>)}
              </div>
            </div>

            <div>
              <label className="block text-sm text-secondary mb-2">الفئة المستهدفة *</label>
              <div className="grid grid-cols-2 gap-3">
                {["\u0631\u062C\u0627\u0644", "\u0646\u0633\u0627\u0621"].map((target) => <button
    key={target}
    onClick={() => setFormData({ ...formData, targetGender: target })}
    className={`py-3 rounded-xl border-2 transition-all ${formData.targetGender === target ? "border-primary bg-primary/10 text-primary" : "border-border bg-white text-secondary"}`}
  >
                    {target}
                  </button>)}
              </div>
            </div>

            <div>
              <label className="block text-sm text-secondary mb-3">نطاق المستوى المستهدف *</label>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs text-muted-foreground mb-2">من</label>
                  <select
    value={formData.minLevel}
    onChange={(e) => setFormData({ ...formData, minLevel: e.target.value })}
    className="w-full bg-white border border-border rounded-xl px-4 py-3 outline-none focus:border-primary transition-colors"
  >
                    {["0", "1", "2", "3", "4", "5", "6"].map((level) => <option key={level} value={level}>مستوى {level}</option>)}
                  </select>
                </div>
                <div>
                  <label className="block text-xs text-muted-foreground mb-2">إلى</label>
                  <select
    value={formData.maxLevel}
    onChange={(e) => setFormData({ ...formData, maxLevel: e.target.value })}
    className="w-full bg-white border border-border rounded-xl px-4 py-3 outline-none focus:border-primary transition-colors"
  >
                    {["1", "2", "3", "4", "5", "6", "7"].map((level) => <option key={level} value={level}>مستوى {level}</option>)}
                  </select>
                </div>
              </div>
            </div>
          </div>}

        {step === 3 && <div className="space-y-5">
            <h2 className="text-2xl text-secondary mb-6">الوثائق الرسمية</h2>

            <div>
              <label className="block text-sm text-secondary mb-2">الجنسية *</label>
              <div className="grid grid-cols-2 gap-3">
                <button
    onClick={() => setFormData({ ...formData, nationality: "\u0633\u0639\u0648\u062F\u064A" })}
    className={`py-3 rounded-xl border-2 transition-all ${formData.nationality === "\u0633\u0639\u0648\u062F\u064A" ? "border-primary bg-primary/10 text-primary" : "border-border bg-white text-secondary"}`}
  >
                  سعودي
                </button>
                <button
    onClick={() => setFormData({ ...formData, nationality: "\u0645\u0642\u064A\u0645" })}
    className={`py-3 rounded-xl border-2 transition-all ${formData.nationality === "\u0645\u0642\u064A\u0645" ? "border-primary bg-primary/10 text-primary" : "border-border bg-white text-secondary"}`}
  >
                  مقيم
                </button>
              </div>
            </div>

            {formData.nationality === "\u0633\u0639\u0648\u062F\u064A" && <>
                <div>
                  <label className="block text-sm text-secondary mb-2">صورة الهوية الوطنية (الوجه الأمامي) *</label>
                  <div className="border-2 border-dashed border-border rounded-xl p-6 text-center bg-gray-50 hover:bg-gray-100 transition-colors cursor-pointer">
                    <Upload className="w-10 h-10 text-muted-foreground mx-auto mb-2" />
                    <p className="text-sm text-secondary mb-1">اسحب وأفلت الصورة هنا</p>
                    <p className="text-xs text-muted-foreground mb-3">أو انقر لتحميل (JPG, PNG - حد أقصى 5MB)</p>
                    <input
    type="file"
    accept="image/*"
    onChange={(e) => {
      const file = e.target.files?.[0];
      if (file) setFormData({ ...formData, nationalIdFront: file });
    }}
    className="hidden"
    id="nationalIdFront"
  />
                    <label
    htmlFor="nationalIdFront"
    className="inline-block px-4 py-2 bg-primary text-white rounded-lg text-sm cursor-pointer"
  >
                      {formData.nationalIdFront ? "\u062A\u0645 \u0627\u0644\u0631\u0641\u0639 \u2713" : "\u0627\u062E\u062A\u0631 \u0627\u0644\u0635\u0648\u0631\u0629"}
                    </label>
                  </div>
                </div>

                <div>
                  <label className="block text-sm text-secondary mb-2">صورة الهوية الوطنية (الوجه الخلفي) *</label>
                  <div className="border-2 border-dashed border-border rounded-xl p-6 text-center bg-gray-50 hover:bg-gray-100 transition-colors cursor-pointer">
                    <Upload className="w-10 h-10 text-muted-foreground mx-auto mb-2" />
                    <p className="text-sm text-secondary mb-1">اسحب وأفلت الصورة هنا</p>
                    <p className="text-xs text-muted-foreground mb-3">أو انقر لتحميل (JPG, PNG - حد أقصى 5MB)</p>
                    <input
    type="file"
    accept="image/*"
    onChange={(e) => {
      const file = e.target.files?.[0];
      if (file) setFormData({ ...formData, nationalIdBack: file });
    }}
    className="hidden"
    id="nationalIdBack"
  />
                    <label
    htmlFor="nationalIdBack"
    className="inline-block px-4 py-2 bg-primary text-white rounded-lg text-sm cursor-pointer"
  >
                      {formData.nationalIdBack ? "\u062A\u0645 \u0627\u0644\u0631\u0641\u0639 \u2713" : "\u0627\u062E\u062A\u0631 \u0627\u0644\u0635\u0648\u0631\u0629"}
                    </label>
                  </div>
                </div>
              </>}

            {formData.nationality === "\u0645\u0642\u064A\u0645" && <>
                <div>
                  <label className="block text-sm text-secondary mb-2">صورة الإقامة (الوجه الأمامي) *</label>
                  <div className="border-2 border-dashed border-border rounded-xl p-6 text-center bg-gray-50 hover:bg-gray-100 transition-colors cursor-pointer">
                    <Upload className="w-10 h-10 text-muted-foreground mx-auto mb-2" />
                    <p className="text-sm text-secondary mb-1">اسحب وأفلت الصورة هنا</p>
                    <p className="text-xs text-muted-foreground mb-3">أو انقر لتحميل (JPG, PNG - حد أقصى 5MB)</p>
                    <input
    type="file"
    accept="image/*"
    onChange={(e) => {
      const file = e.target.files?.[0];
      if (file) setFormData({ ...formData, iqamaFront: file });
    }}
    className="hidden"
    id="iqamaFront"
  />
                    <label
    htmlFor="iqamaFront"
    className="inline-block px-4 py-2 bg-primary text-white rounded-lg text-sm cursor-pointer"
  >
                      {formData.iqamaFront ? "\u062A\u0645 \u0627\u0644\u0631\u0641\u0639 \u2713" : "\u0627\u062E\u062A\u0631 \u0627\u0644\u0635\u0648\u0631\u0629"}
                    </label>
                  </div>
                </div>

                <div>
                  <label className="block text-sm text-secondary mb-2">صورة الإقامة (الوجه الخلفي) *</label>
                  <div className="border-2 border-dashed border-border rounded-xl p-6 text-center bg-gray-50 hover:bg-gray-100 transition-colors cursor-pointer">
                    <Upload className="w-10 h-10 text-muted-foreground mx-auto mb-2" />
                    <p className="text-sm text-secondary mb-1">اسحب وأفلت الصورة هنا</p>
                    <p className="text-xs text-muted-foreground mb-3">أو انقر لتحميل (JPG, PNG - حد أقصى 5MB)</p>
                    <input
    type="file"
    accept="image/*"
    onChange={(e) => {
      const file = e.target.files?.[0];
      if (file) setFormData({ ...formData, iqamaBack: file });
    }}
    className="hidden"
    id="iqamaBack"
  />
                    <label
    htmlFor="iqamaBack"
    className="inline-block px-4 py-2 bg-primary text-white rounded-lg text-sm cursor-pointer"
  >
                      {formData.iqamaBack ? "\u062A\u0645 \u0627\u0644\u0631\u0641\u0639 \u2713" : "\u0627\u062E\u062A\u0631 \u0627\u0644\u0635\u0648\u0631\u0629"}
                    </label>
                  </div>
                </div>
              </>}

            <div className="bg-yellow-50 border border-yellow-200 rounded-xl p-4">
              <p className="text-xs text-yellow-800">
                ⚠️ تأكد من وضوح الصور وظهور جميع البيانات بشكل واضح. سيتم التحقق من الوثائق قبل الموافقة على الحساب
              </p>
            </div>
          </div>}

        {step === 4 && <div className="space-y-5">
            <h2 className="text-2xl text-secondary mb-6">التسعير والموقع</h2>

            <div>
              <label className="block text-sm text-secondary mb-2">سعر الجلسة الواحدة (ر.س) *</label>
              <input
    type="number"
    value={formData.sessionPrice}
    onChange={(e) => setFormData({ ...formData, sessionPrice: e.target.value })}
    placeholder="مثال: 200"
    className="w-full bg-white border border-border rounded-xl px-4 py-3 outline-none focus:border-primary transition-colors"
  />
            </div>

            <div>
              <label className="block text-sm text-secondary mb-2">سعر الباقة الشهرية (ر.س)</label>
              <input
    type="number"
    value={formData.packagePrice}
    onChange={(e) => setFormData({ ...formData, packagePrice: e.target.value })}
    placeholder="مثال: 1500 (اختياري)"
    className="w-full bg-white border border-border rounded-xl px-4 py-3 outline-none focus:border-primary transition-colors"
  />
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
              <label className="block text-sm text-secondary mb-2">اسم الملعب/النادي الرئيسي *</label>
              <div className="relative">
                <MapPin className="absolute right-4 top-1/2 -translate-y-1/2 w-5 h-5 text-muted-foreground" />
                <input
    type="text"
    value={formData.courtName}
    onChange={(e) => setFormData({ ...formData, courtName: e.target.value })}
    placeholder="مثال: نادي البادل الملكي"
    className="w-full bg-white border border-border rounded-xl px-4 py-3 pr-12 outline-none focus:border-primary transition-colors"
  />
              </div>
            </div>

            <div>
              <label className="block text-sm text-secondary mb-3">الأوقات المتاحة *</label>
              <div className="grid grid-cols-2 gap-3">
                {["\u0635\u0628\u0627\u062D (6-12)", "\u0638\u0647\u0631 (12-18)", "\u0645\u0633\u0627\u0621 (18-22)", "\u0644\u064A\u0644 (22-24)"].map((time) => <button
    key={time}
    onClick={() => toggleAvailability(time)}
    className={`py-3 rounded-xl border-2 transition-all text-sm ${formData.availability.includes(time) ? "border-primary bg-primary/10 text-primary" : "border-border bg-white text-secondary"}`}
  >
                    {time}
                    {formData.availability.includes(time) && " \u2713"}
                  </button>)}
              </div>
            </div>

            <div className="bg-gradient-to-br from-primary/10 to-primary/5 border border-primary/30 rounded-2xl p-5">
              <div className="flex items-start gap-3 mb-4">
                <Award className="w-6 h-6 text-primary flex-shrink-0 mt-1" />
                <div>
                  <h3 className="text-secondary mb-2">برنامج المدرب المعتمد</h3>
                  <p className="text-sm text-muted-foreground mb-3">
                    للحصول على شارة المدرب المعتمد، يجب إكمال برنامج التدريب (3 مراحل) والحصول على شهادة رسمية
                  </p>
                  <button className="text-sm text-primary underline">تعرف على المزيد</button>
                </div>
              </div>
            </div>

            <div className="bg-muted border border-border rounded-xl p-4">
              <p className="text-xs text-muted-foreground">
                ℹ️ سيتم مراجعة طلبك خلال 24-48 ساعة. ستتلقى إشعاراً عند الموافقة على حسابك
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
    className="flex-1 py-3 bg-gradient-to-r from-primary to-primary/90 text-white rounded-xl shadow-lg flex items-center justify-center gap-2"
  >
            {step === totalSteps ? "\u0625\u0631\u0633\u0627\u0644 \u0627\u0644\u0637\u0644\u0628" : "\u0627\u0644\u062A\u0627\u0644\u064A"}
            {step < totalSteps && <ChevronLeft className="w-5 h-5" />}
          </button>
        </div>
      </div>
    </div>;
}
export {
  CoachRegistration as default
};
