import { useState } from "react";
import { ChevronRight, ChevronLeft, Upload } from "lucide-react";
function CoachProfileCompletion({ onComplete, onBack }) {
  const [step, setStep] = useState(1);
  const [formData, setFormData] = useState({
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
    nationalIdBack: null
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
  const toggleAvailability = (day) => {
    if (formData.availability.includes(day)) {
      setFormData({
        ...formData,
        availability: formData.availability.filter((d) => d !== day)
      });
    } else {
      setFormData({
        ...formData,
        availability: [...formData.availability, day]
      });
    }
  };
  const handleFileUpload = (field, file) => {
    setFormData({ ...formData, [field]: file });
  };
  return <div className="h-screen flex flex-col bg-background">
      <div className="bg-gradient-to-br from-secondary to-secondary/90 text-white px-6 pt-8 pb-6">
        <div className="flex items-center justify-between mb-6">
          <button onClick={handleBack} className="p-2 bg-white/20 rounded-full backdrop-blur-sm">
            <ChevronRight className="w-5 h-5" />
          </button>
          <h1 className="text-xl">إكمال ملف المدرب</h1>
          <div className="w-9" />
        </div>

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
            <h2 className="text-2xl text-secondary mb-6">معلومات مهنية</h2>

            <div>
              <label className="block text-sm text-secondary mb-2">نبذة عنك كمدرب *</label>
              <textarea
    value={formData.bio}
    onChange={(e) => setFormData({ ...formData, bio: e.target.value })}
    placeholder="اكتب نبذة مختصرة عن خبرتك وأسلوبك التدريبي"
    rows={4}
    className="w-full bg-white border border-border rounded-xl px-4 py-3 outline-none focus:border-primary transition-colors resize-none"
  />
            </div>

            <div>
              <label className="block text-sm text-secondary mb-2">سنوات الخبرة *</label>
              <div className="grid grid-cols-2 gap-3">
                {["\u0623\u0642\u0644 \u0645\u0646 \u0633\u0646\u0629", "1-3 \u0633\u0646\u0648\u0627\u062A", "3-5 \u0633\u0646\u0648\u0627\u062A", "\u0623\u0643\u062B\u0631 \u0645\u0646 5 \u0633\u0646\u0648\u0627\u062A"].map((exp) => <button
    key={exp}
    onClick={() => setFormData({ ...formData, experience: exp })}
    className={`py-3 rounded-xl border-2 transition-all ${formData.experience === exp ? "border-primary bg-primary/10 text-primary" : "border-border bg-white text-secondary"}`}
  >
                    {exp}
                  </button>)}
              </div>
            </div>

            <div>
              <label className="block text-sm text-secondary mb-2">الشهادات والمؤهلات</label>
              <textarea
    value={formData.certifications}
    onChange={(e) => setFormData({ ...formData, certifications: e.target.value })}
    placeholder="مثال: مدرب معتمد من الاتحاد السعودي للبادل"
    rows={3}
    className="w-full bg-white border border-border rounded-xl px-4 py-3 outline-none focus:border-primary transition-colors resize-none"
  />
            </div>

            <div>
              <label className="block text-sm text-secondary mb-3">التخصصات *</label>
              <div className="space-y-2">
                {[
    "\u062A\u062F\u0631\u064A\u0628 \u0627\u0644\u0645\u0628\u062A\u062F\u0626\u064A\u0646",
    "\u062A\u0637\u0648\u064A\u0631 \u0627\u0644\u0645\u0647\u0627\u0631\u0627\u062A \u0627\u0644\u0645\u062A\u0642\u062F\u0645\u0629",
    "\u0627\u0644\u0644\u064A\u0627\u0642\u0629 \u0627\u0644\u0628\u062F\u0646\u064A\u0629",
    "\u0627\u0644\u0627\u0633\u062A\u0631\u0627\u062A\u064A\u062C\u064A\u0627\u062A \u0627\u0644\u062A\u0643\u062A\u064A\u0643\u064A\u0629",
    "\u062A\u062F\u0631\u064A\u0628 \u0627\u0644\u0646\u0627\u0634\u0626\u064A\u0646",
    "\u0627\u0644\u062A\u062D\u0636\u064A\u0631 \u0644\u0644\u0628\u0637\u0648\u0644\u0627\u062A"
  ].map((spec) => <button
    key={spec}
    onClick={() => toggleSpecialization(spec)}
    className={`w-full py-3 px-4 rounded-xl border-2 transition-all text-right ${formData.specializations.includes(spec) ? "border-primary bg-primary/10 text-primary" : "border-border bg-white text-secondary"}`}
  >
                    <div className="flex items-center justify-between">
                      <span>{spec}</span>
                      {formData.specializations.includes(spec) && <span className="text-primary">✓</span>}
                    </div>
                  </button>)}
              </div>
            </div>
          </div>}

        {step === 2 && <div className="space-y-5">
            <h2 className="text-2xl text-secondary mb-6">التفضيلات والأسعار</h2>

            <div>
              <label className="block text-sm text-secondary mb-2">الفئة المستهدفة *</label>
              <div className="grid grid-cols-2 gap-3">
                {["\u0631\u062C\u0627\u0644", "\u0646\u0633\u0627\u0621"].map((gender) => <button
    key={gender}
    onClick={() => setFormData({ ...formData, targetGender: gender })}
    className={`py-3 rounded-xl border-2 transition-all ${formData.targetGender === gender ? "border-primary bg-primary/10 text-primary" : "border-border bg-white text-secondary"}`}
  >
                    {gender}
                  </button>)}
              </div>
            </div>

            <div>
              <label className="block text-sm text-secondary mb-2">سعر الحصة الفردية (ر.س) *</label>
              <input
    type="number"
    value={formData.sessionPrice}
    onChange={(e) => setFormData({ ...formData, sessionPrice: e.target.value })}
    placeholder="مثال: 150"
    className="w-full bg-white border border-border rounded-xl px-4 py-3 outline-none focus:border-primary transition-colors"
  />
            </div>

            <div>
              <label className="block text-sm text-secondary mb-2">سعر الباقة (8 حصص) (ر.س)</label>
              <input
    type="number"
    value={formData.packagePrice}
    onChange={(e) => setFormData({ ...formData, packagePrice: e.target.value })}
    placeholder="مثال: 1000"
    className="w-full bg-white border border-border rounded-xl px-4 py-3 outline-none focus:border-primary transition-colors"
  />
            </div>

            <div>
              <label className="block text-sm text-secondary mb-2">الملعب الذي تدرب فيه</label>
              <input
    type="text"
    value={formData.courtName}
    onChange={(e) => setFormData({ ...formData, courtName: e.target.value })}
    placeholder="اسم الملعب"
    className="w-full bg-white border border-border rounded-xl px-4 py-3 outline-none focus:border-primary transition-colors"
  />
            </div>

            <div>
              <label className="block text-sm text-secondary mb-3">الأيام المتاحة للتدريب *</label>
              <div className="grid grid-cols-2 gap-2">
                {["\u0627\u0644\u0633\u0628\u062A", "\u0627\u0644\u0623\u062D\u062F", "\u0627\u0644\u0627\u062B\u0646\u064A\u0646", "\u0627\u0644\u062B\u0644\u0627\u062B\u0627\u0621", "\u0627\u0644\u0623\u0631\u0628\u0639\u0627\u0621", "\u0627\u0644\u062E\u0645\u064A\u0633", "\u0627\u0644\u062C\u0645\u0639\u0629"].map((day) => <button
    key={day}
    onClick={() => toggleAvailability(day)}
    className={`py-3 rounded-xl border-2 transition-all ${formData.availability.includes(day) ? "border-primary bg-primary/10 text-primary" : "border-border bg-white text-secondary"}`}
  >
                    {day}
                  </button>)}
              </div>
            </div>
          </div>}

        {step === 3 && <div className="space-y-5">
            <h2 className="text-2xl text-secondary mb-6">رفع الوثائق</h2>

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

            <div className="bg-primary/5 border border-primary/20 rounded-xl p-4">
              <p className="text-sm text-secondary">
                💡 {formData.nationality === "\u0633\u0639\u0648\u062F\u064A" ? "\u064A\u0631\u062C\u0649 \u0631\u0641\u0639 \u0635\u0648\u0631\u0629 \u0627\u0644\u0647\u0648\u064A\u0629 \u0627\u0644\u0648\u0637\u0646\u064A\u0629" : "\u064A\u0631\u062C\u0649 \u0631\u0641\u0639 \u0635\u0648\u0631\u0629 \u0627\u0644\u0625\u0642\u0627\u0645\u0629"}
              </p>
            </div>

            <div>
              <label className="block text-sm text-secondary mb-2">
                {formData.nationality === "\u0633\u0639\u0648\u062F\u064A" ? "\u0627\u0644\u0647\u0648\u064A\u0629 \u0627\u0644\u0648\u0637\u0646\u064A\u0629 (\u0627\u0644\u0648\u062C\u0647 \u0627\u0644\u0623\u0645\u0627\u0645\u064A)" : "\u0627\u0644\u0625\u0642\u0627\u0645\u0629 (\u0627\u0644\u0648\u062C\u0647 \u0627\u0644\u0623\u0645\u0627\u0645\u064A)"} *
              </label>
              <div className="border-2 border-dashed border-border rounded-xl p-6 text-center bg-white hover:bg-gray-50 transition-colors cursor-pointer">
                <Upload className="w-8 h-8 text-muted-foreground mx-auto mb-2" />
                <p className="text-sm text-secondary mb-1">اضغط لرفع الصورة</p>
                <p className="text-xs text-muted-foreground">PNG, JPG حتى 5MB</p>
                <input
    type="file"
    accept="image/*"
    onChange={(e) => handleFileUpload("nationalIdFront", e.target.files?.[0] || null)}
    className="hidden"
  />
              </div>
              {formData.nationalIdFront && <p className="text-sm text-primary mt-2">✓ تم رفع الصورة</p>}
            </div>

            <div>
              <label className="block text-sm text-secondary mb-2">
                {formData.nationality === "\u0633\u0639\u0648\u062F\u064A" ? "\u0627\u0644\u0647\u0648\u064A\u0629 \u0627\u0644\u0648\u0637\u0646\u064A\u0629 (\u0627\u0644\u0648\u062C\u0647 \u0627\u0644\u062E\u0644\u0641\u064A)" : "\u0627\u0644\u0625\u0642\u0627\u0645\u0629 (\u0627\u0644\u0648\u062C\u0647 \u0627\u0644\u062E\u0644\u0641\u064A)"} *
              </label>
              <div className="border-2 border-dashed border-border rounded-xl p-6 text-center bg-white hover:bg-gray-50 transition-colors cursor-pointer">
                <Upload className="w-8 h-8 text-muted-foreground mx-auto mb-2" />
                <p className="text-sm text-secondary mb-1">اضغط لرفع الصورة</p>
                <p className="text-xs text-muted-foreground">PNG, JPG حتى 5MB</p>
                <input
    type="file"
    accept="image/*"
    onChange={(e) => handleFileUpload("nationalIdBack", e.target.files?.[0] || null)}
    className="hidden"
  />
              </div>
              {formData.nationalIdBack && <p className="text-sm text-primary mt-2">✓ تم رفع الصورة</p>}
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
            {step === totalSteps ? "\u0625\u0643\u0645\u0627\u0644 \u0627\u0644\u062A\u0633\u062C\u064A\u0644" : "\u0627\u0644\u062A\u0627\u0644\u064A"}
            {step < totalSteps && <ChevronLeft className="w-5 h-5" />}
          </button>
        </div>
      </div>
    </div>;
}
export {
  CoachProfileCompletion as default
};
