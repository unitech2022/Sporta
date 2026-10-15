import { useState, useRef } from "react";
import { ChevronRight, ChevronLeft, Upload, CheckCircle, X, FileImage } from "lucide-react";
function VenueProfileCompletion({ onComplete, onBack }) {
  const [step, setStep] = useState(1);
  const [formData, setFormData] = useState({
    venueName: "",
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
  });
  const [ownerIdImage, setOwnerIdImage] = useState(null);
  const [commercialRegImage, setCommercialRegImage] = useState(null);
  const ownerIdRef = useRef(null);
  const commercialRegRef = useRef(null);
  const handleImageUpload = (e, setter) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = () => setter(reader.result);
    reader.readAsDataURL(file);
  };
  const totalSteps = 3;
  const handleNext = () => {
    if (step < totalSteps) {
      setStep(step + 1);
    } else {
      onComplete({ ...formData, ownerIdImage, commercialRegImage });
    }
  };
  const handleBack = () => {
    if (step > 1) {
      setStep(step - 1);
    } else {
      onBack();
    }
  };
  const toggleCourtType = (type) => {
    if (formData.courtTypes.includes(type)) {
      setFormData({
        ...formData,
        courtTypes: formData.courtTypes.filter((t) => t !== type)
      });
    } else {
      setFormData({
        ...formData,
        courtTypes: [...formData.courtTypes, type]
      });
    }
  };
  const toggleAmenity = (amenity) => {
    if (formData.amenities.includes(amenity)) {
      setFormData({
        ...formData,
        amenities: formData.amenities.filter((a) => a !== amenity)
      });
    } else {
      setFormData({
        ...formData,
        amenities: [...formData.amenities, amenity]
      });
    }
  };
  const toggleAudience = (audience) => {
    if (formData.targetAudience.includes(audience)) {
      setFormData({
        ...formData,
        targetAudience: formData.targetAudience.filter((a) => a !== audience)
      });
    } else {
      setFormData({
        ...formData,
        targetAudience: [...formData.targetAudience, audience]
      });
    }
  };
  return <div className="h-screen flex flex-col bg-background">
      <div className="bg-gradient-to-br from-secondary to-secondary/90 text-white px-6 pt-8 pb-6">
        <div className="flex items-center justify-between mb-6">
          <button onClick={handleBack} className="p-2 bg-white/20 rounded-full backdrop-blur-sm">
            <ChevronRight className="w-5 h-5" />
          </button>
          <h1 className="text-xl">إكمال ملف الملعب</h1>
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
            <h2 className="text-2xl text-secondary mb-6">معلومات الملعب</h2>

            <div>
              <label className="block text-sm text-secondary mb-2">اسم الملعب *</label>
              <input
    type="text"
    value={formData.venueName}
    onChange={(e) => setFormData({ ...formData, venueName: e.target.value })}
    placeholder="مثال: ملعب النادي الرياضي"
    className="w-full bg-white border border-border rounded-xl px-4 py-3 outline-none focus:border-primary transition-colors"
  />
            </div>

            <div>
              <label className="block text-sm text-secondary mb-2">عدد الملاعب *</label>
              <div className="grid grid-cols-4 gap-3">
                {["1", "2", "3", "4+"].map((num) => <button
    key={num}
    onClick={() => setFormData({ ...formData, numberOfCourts: num })}
    className={`py-3 rounded-xl border-2 transition-all ${formData.numberOfCourts === num ? "border-primary bg-primary/10 text-primary" : "border-border bg-white text-secondary"}`}
  >
                    {num}
                  </button>)}
              </div>
            </div>

            <div>
              <label className="block text-sm text-secondary mb-3">نوع الملاعب *</label>
              <div className="space-y-2">
                {["\u062F\u0627\u062E\u0644\u064A", "\u062E\u0627\u0631\u062C\u064A", "\u0645\u063A\u0637\u0649", "\u0645\u0643\u0634\u0648\u0641"].map((type) => <button
    key={type}
    onClick={() => toggleCourtType(type)}
    className={`w-full py-3 px-4 rounded-xl border-2 transition-all text-right ${formData.courtTypes.includes(type) ? "border-primary bg-primary/10 text-primary" : "border-border bg-white text-secondary"}`}
  >
                    <div className="flex items-center justify-between">
                      <span>{type}</span>
                      {formData.courtTypes.includes(type) && <span className="text-primary">✓</span>}
                    </div>
                  </button>)}
              </div>
            </div>

            <div>
              <label className="block text-sm text-secondary mb-3">المرافق المتوفرة</label>
              <div className="grid grid-cols-2 gap-2">
                {[
    "\u063A\u0631\u0641 \u062A\u0628\u062F\u064A\u0644 \u0645\u0644\u0627\u0628\u0633",
    "\u062F\u0648\u0631\u0627\u062A \u0645\u064A\u0627\u0647",
    "\u0645\u0648\u0627\u0642\u0641 \u0633\u064A\u0627\u0631\u0627\u062A",
    "\u0643\u0627\u0641\u062A\u064A\u0631\u064A\u0627",
    "\u0645\u062A\u062C\u0631",
    "\u0648\u0627\u064A \u0641\u0627\u064A"
  ].map((amenity) => <button
    key={amenity}
    onClick={() => toggleAmenity(amenity)}
    className={`py-3 px-3 rounded-xl border-2 transition-all text-right text-sm ${formData.amenities.includes(amenity) ? "border-primary bg-primary/10 text-primary" : "border-border bg-white text-secondary"}`}
  >
                    {amenity}
                  </button>)}
              </div>
            </div>
          </div>}

        {step === 2 && <div className="space-y-5">
            <h2 className="text-2xl text-secondary mb-6">الأسعار والأوقات</h2>

            <div>
              <label className="block text-sm text-secondary mb-2">سعر الساعة - أيام الأسبوع (ر.س) *</label>
              <input
    type="number"
    value={formData.weekdayRate}
    onChange={(e) => setFormData({ ...formData, weekdayRate: e.target.value })}
    placeholder="مثال: 100"
    className="w-full bg-white border border-border rounded-xl px-4 py-3 outline-none focus:border-primary transition-colors"
  />
            </div>

            <div>
              <label className="block text-sm text-secondary mb-2">سعر الساعة - نهاية الأسبوع (ر.س) *</label>
              <input
    type="number"
    value={formData.weekendRate}
    onChange={(e) => setFormData({ ...formData, weekendRate: e.target.value })}
    placeholder="مثال: 150"
    className="w-full bg-white border border-border rounded-xl px-4 py-3 outline-none focus:border-primary transition-colors"
  />
            </div>

            <div>
              <label className="block text-sm text-secondary mb-2">وقت الافتتاح *</label>
              <input
    type="time"
    value={formData.openingTime}
    onChange={(e) => setFormData({ ...formData, openingTime: e.target.value })}
    className="w-full bg-white border border-border rounded-xl px-4 py-3 outline-none focus:border-primary transition-colors"
  />
            </div>

            <div>
              <label className="block text-sm text-secondary mb-2">وقت الإغلاق *</label>
              <input
    type="time"
    value={formData.closingTime}
    onChange={(e) => setFormData({ ...formData, closingTime: e.target.value })}
    className="w-full bg-white border border-border rounded-xl px-4 py-3 outline-none focus:border-primary transition-colors"
  />
            </div>

            <div className="bg-primary/5 border border-primary/20 rounded-xl p-4">
              <p className="text-sm text-secondary">
                💡 سيتم عرض هذه الأوقات للمستخدمين عند الحجز
              </p>
            </div>
          </div>}

        {step === 3 && <div className="space-y-5">
            <h2 className="text-2xl text-secondary mb-6">معلومات إضافية</h2>

            <div>
              <label className="block text-sm text-secondary mb-3">الفئة المستهدفة *</label>
              <div className="space-y-2">
                {["\u0631\u062C\u0627\u0644", "\u0646\u0633\u0627\u0621", "\u0639\u0627\u0626\u0644\u0627\u062A"].map((audience) => <button
    key={audience}
    onClick={() => toggleAudience(audience)}
    className={`w-full py-3 px-4 rounded-xl border-2 transition-all text-right ${formData.targetAudience.includes(audience) ? "border-primary bg-primary/10 text-primary" : "border-border bg-white text-secondary"}`}
  >
                    <div className="flex items-center justify-between">
                      <span>{audience}</span>
                      {formData.targetAudience.includes(audience) && <span className="text-primary">✓</span>}
                    </div>
                  </button>)}
              </div>
            </div>

            <div>
              <label className="block text-sm text-secondary mb-2">رقم السجل التجاري *</label>
              <input
    type="text"
    value={formData.commercialLicense}
    onChange={(e) => setFormData({ ...formData, commercialLicense: e.target.value })}
    placeholder="مثال: 1010123456"
    className="w-full bg-white border border-border rounded-xl px-4 py-3 outline-none focus:border-primary transition-colors"
  />
            </div>

            {
    /* رفع صورة هوية المالك */
  }
            <div>
              <label className="block text-sm text-secondary mb-2">
                صورة هوية المالك <span className="text-red-500">*</span>
              </label>
              <input
    ref={ownerIdRef}
    type="file"
    accept="image/*"
    className="hidden"
    onChange={(e) => handleImageUpload(e, setOwnerIdImage)}
  />
              {ownerIdImage ? <div className="relative rounded-xl overflow-hidden border-2 border-primary">
                  <img src={ownerIdImage} alt="هوية المالك" className="w-full h-40 object-cover" />
                  <button
    onClick={() => setOwnerIdImage(null)}
    className="absolute top-2 left-2 w-7 h-7 bg-red-500 text-white rounded-full flex items-center justify-center shadow"
  >
                    <X className="w-4 h-4" />
                  </button>
                  <div className="absolute top-2 right-2 flex items-center gap-1 bg-white/90 px-2 py-1 rounded-full">
                    <CheckCircle className="w-3.5 h-3.5 text-green-500" />
                    <span className="text-xs text-green-600">تم الرفع</span>
                  </div>
                </div> : <button
    onClick={() => ownerIdRef.current?.click()}
    className="w-full border-2 border-dashed border-border bg-gray-50 rounded-xl py-8 flex flex-col items-center gap-3 hover:border-primary hover:bg-primary/5 transition-all"
  >
                  <div className="w-12 h-12 bg-primary/10 rounded-full flex items-center justify-center">
                    <FileImage className="w-6 h-6 text-primary" />
                  </div>
                  <div className="text-center">
                    <p className="text-sm text-secondary">اضغط لرفع صورة الهوية</p>
                    <p className="text-xs text-muted-foreground mt-1">JPG, PNG — بحد أقصى 5 ميجابايت</p>
                  </div>
                  <div className="flex items-center gap-2 px-4 py-2 bg-primary text-white text-sm rounded-lg">
                    <Upload className="w-4 h-4" />
                    رفع الصورة
                  </div>
                </button>}
            </div>

            {
    /* رفع صورة السجل التجاري */
  }
            <div>
              <label className="block text-sm text-secondary mb-2">
                صورة السجل التجاري <span className="text-red-500">*</span>
              </label>
              <input
    ref={commercialRegRef}
    type="file"
    accept="image/*"
    className="hidden"
    onChange={(e) => handleImageUpload(e, setCommercialRegImage)}
  />
              {commercialRegImage ? <div className="relative rounded-xl overflow-hidden border-2 border-primary">
                  <img src={commercialRegImage} alt="السجل التجاري" className="w-full h-40 object-cover" />
                  <button
    onClick={() => setCommercialRegImage(null)}
    className="absolute top-2 left-2 w-7 h-7 bg-red-500 text-white rounded-full flex items-center justify-center shadow"
  >
                    <X className="w-4 h-4" />
                  </button>
                  <div className="absolute top-2 right-2 flex items-center gap-1 bg-white/90 px-2 py-1 rounded-full">
                    <CheckCircle className="w-3.5 h-3.5 text-green-500" />
                    <span className="text-xs text-green-600">تم الرفع</span>
                  </div>
                </div> : <button
    onClick={() => commercialRegRef.current?.click()}
    className="w-full border-2 border-dashed border-border bg-gray-50 rounded-xl py-8 flex flex-col items-center gap-3 hover:border-primary hover:bg-primary/5 transition-all"
  >
                  <div className="w-12 h-12 bg-primary/10 rounded-full flex items-center justify-center">
                    <FileImage className="w-6 h-6 text-primary" />
                  </div>
                  <div className="text-center">
                    <p className="text-sm text-secondary">اضغط لرفع صورة السجل التجاري</p>
                    <p className="text-xs text-muted-foreground mt-1">JPG, PNG — بحد أقصى 5 ميجابايت</p>
                  </div>
                  <div className="flex items-center gap-2 px-4 py-2 bg-primary text-white text-sm rounded-lg">
                    <Upload className="w-4 h-4" />
                    رفع الصورة
                  </div>
                </button>}
            </div>

            <div className="bg-primary/5 border border-primary/20 rounded-xl p-4 space-y-1">
              <p className="text-sm text-secondary">⏳ سيتم التحقق والرد عليك خلال ٤٨ ساعة كحد أقصى.</p>
              <p className="text-sm text-secondary">✅ عند الموافقة سيتم عرض ملعبك للمستخدمين، أو تبليغك بأسباب الرفض.</p>
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
  VenueProfileCompletion as default
};
