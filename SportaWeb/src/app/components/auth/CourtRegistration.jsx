import { useState } from "react";
import { ChevronRight, ChevronLeft, Building, Mail, Phone, MapPin, Camera, Upload, DollarSign, Clock } from "lucide-react";
function CourtRegistration({ onComplete, onBack }) {
  const [step, setStep] = useState(1);
  const [formData, setFormData] = useState({
    courtName: "",
    ownerName: "",
    email: "",
    phone: "",
    password: "",
    country: "\u0627\u0644\u0633\u0639\u0648\u062F\u064A\u0629",
    city: "",
    district: "",
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
    commercialLicense: "",
    taxNumber: ""
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
  const toggleTargetAudience = (audience) => {
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
          <h1 className="text-xl">تسجيل ملعب جديد</h1>
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
            <h2 className="text-2xl text-secondary mb-6">معلومات الملعب</h2>

            <div className="flex justify-center mb-6">
              <div className="relative">
                <div className="w-24 h-24 bg-gray-200 rounded-full flex items-center justify-center">
                  <Building className="w-12 h-12 text-gray-400" />
                </div>
                <button className="absolute bottom-0 left-0 w-8 h-8 bg-primary rounded-full flex items-center justify-center shadow-lg">
                  <Camera className="w-4 h-4 text-white" />
                </button>
              </div>
            </div>

            <div>
              <label className="block text-sm text-secondary mb-2">اسم الملعب/النادي *</label>
              <div className="relative">
                <Building className="absolute right-4 top-1/2 -translate-y-1/2 w-5 h-5 text-muted-foreground" />
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
              <label className="block text-sm text-secondary mb-2">اسم المالك/المسؤول *</label>
              <input
    type="text"
    value={formData.ownerName}
    onChange={(e) => setFormData({ ...formData, ownerName: e.target.value })}
    placeholder="الاسم الكامل"
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
          </div>}

        {step === 2 && <div className="space-y-5">
            <h2 className="text-2xl text-secondary mb-6">الموقع والعنوان</h2>

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
              <input
    type="text"
    value={formData.district}
    onChange={(e) => setFormData({ ...formData, district: e.target.value })}
    placeholder="مثال: العليا"
    className="w-full bg-white border border-border rounded-xl px-4 py-3 outline-none focus:border-primary transition-colors"
  />
            </div>

            <div>
              <label className="block text-sm text-secondary mb-2">العنوان التفصيلي *</label>
              <div className="relative">
                <MapPin className="absolute right-4 top-4 w-5 h-5 text-muted-foreground" />
                <textarea
    value={formData.address}
    onChange={(e) => setFormData({ ...formData, address: e.target.value })}
    placeholder="الشارع، رقم المبنى، معالم قريبة..."
    rows={3}
    className="w-full bg-white border border-border rounded-xl px-4 py-3 pr-12 outline-none focus:border-primary transition-colors resize-none"
  />
              </div>
            </div>

            <div className="bg-primary/5 border border-primary/20 rounded-xl p-4">
              <button className="w-full flex items-center justify-center gap-2 py-3 bg-white border border-primary/30 text-primary rounded-lg">
                <MapPin className="w-5 h-5" />
                تحديد الموقع على الخريطة
              </button>
            </div>
          </div>}

        {step === 3 && <div className="space-y-5">
            <h2 className="text-2xl text-secondary mb-6">تفاصيل الملاعب</h2>

            <div>
              <label className="block text-sm text-secondary mb-2">عدد الملاعب *</label>
              <select
    value={formData.numberOfCourts}
    onChange={(e) => setFormData({ ...formData, numberOfCourts: e.target.value })}
    className="w-full bg-white border border-border rounded-xl px-4 py-3 outline-none focus:border-primary transition-colors"
  >
                <option value="">اختر العدد</option>
                <option value="1">ملعب واحد</option>
                <option value="2">ملعبان</option>
                <option value="3">3 ملاعب</option>
                <option value="4">4 ملاعب</option>
                <option value="5+">5 ملاعب أو أكثر</option>
              </select>
            </div>

            <div>
              <label className="block text-sm text-secondary mb-3">نوع الملاعب *</label>
              <div className="grid grid-cols-2 gap-3">
                {["\u062F\u0627\u062E\u0644\u064A", "\u062E\u0627\u0631\u062C\u064A", "\u0645\u063A\u0637\u0649", "\u0645\u0643\u0634\u0648\u0641"].map((type) => <button
    key={type}
    onClick={() => toggleCourtType(type)}
    className={`py-3 rounded-xl border-2 transition-all ${formData.courtTypes.includes(type) ? "border-primary bg-primary/10 text-primary" : "border-border bg-white text-secondary"}`}
  >
                    {type}
                    {formData.courtTypes.includes(type) && " \u2713"}
                  </button>)}
              </div>
            </div>

            <div>
              <label className="block text-sm text-secondary mb-3">المرافق والخدمات *</label>
              <div className="space-y-2">
                {[
    "\u063A\u0631\u0641 \u062A\u0628\u062F\u064A\u0644 \u0645\u0644\u0627\u0628\u0633",
    "\u062F\u0648\u0631\u0627\u062A \u0645\u064A\u0627\u0647",
    "\u0645\u0648\u0627\u0642\u0641 \u0633\u064A\u0627\u0631\u0627\u062A",
    "\u0643\u0627\u0641\u064A\u062A\u0631\u064A\u0627",
    "\u0645\u062A\u062C\u0631 \u0645\u0639\u062F\u0627\u062A",
    "\u0627\u0633\u062A\u062D\u0645\u0627\u0645",
    "Wi-Fi",
    "\u062A\u0643\u064A\u064A\u0641"
  ].map((amenity) => <button
    key={amenity}
    onClick={() => toggleAmenity(amenity)}
    className={`w-full py-3 rounded-xl border-2 transition-all text-sm ${formData.amenities.includes(amenity) ? "border-primary bg-primary/10 text-primary" : "border-border bg-white text-secondary"}`}
  >
                    {amenity}
                    {formData.amenities.includes(amenity) && " \u2713"}
                  </button>)}
              </div>
            </div>

            <div>
              <label className="block text-sm text-secondary mb-3">الفئة المستهدفة *</label>
              <div className="grid grid-cols-3 gap-3">
                {["\u0631\u062C\u0627\u0644", "\u0646\u0633\u0627\u0621", "\u0639\u0627\u0626\u0644\u0627\u062A"].map((audience) => <button
    key={audience}
    onClick={() => toggleTargetAudience(audience)}
    className={`py-3 rounded-xl border-2 transition-all ${formData.targetAudience.includes(audience) ? "border-primary bg-primary/10 text-primary" : "border-border bg-white text-secondary"}`}
  >
                    {audience}
                    {formData.targetAudience.includes(audience) && " \u2713"}
                  </button>)}
              </div>
            </div>

            <div>
              <label className="block text-sm text-secondary mb-2">صور الملعب</label>
              <div className="border-2 border-dashed border-border rounded-xl p-8 text-center bg-gray-50">
                <Upload className="w-12 h-12 text-muted-foreground mx-auto mb-3" />
                <p className="text-sm text-secondary mb-1">اسحب وأفلت الصور هنا</p>
                <p className="text-xs text-muted-foreground mb-3">أو انقر لتحميل (حد أقصى 10 صور)</p>
                <button className="px-4 py-2 bg-primary text-white rounded-lg text-sm">
                  اختر الصور
                </button>
              </div>
            </div>
          </div>}

        {step === 4 && <div className="space-y-5">
            <h2 className="text-2xl text-secondary mb-6">التسعير والمواعيد</h2>

            <div>
              <label className="block text-sm text-secondary mb-2">سعر الساعة (ر.س) *</label>
              <div className="relative">
                <DollarSign className="absolute right-4 top-1/2 -translate-y-1/2 w-5 h-5 text-muted-foreground" />
                <input
    type="number"
    value={formData.hourlyRate}
    onChange={(e) => setFormData({ ...formData, hourlyRate: e.target.value })}
    placeholder="مثال: 150"
    className="w-full bg-white border border-border rounded-xl px-4 py-3 pr-12 outline-none focus:border-primary transition-colors"
  />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block text-sm text-secondary mb-2">سعر أيام الأسبوع (ر.س)</label>
                <input
    type="number"
    value={formData.weekdayRate}
    onChange={(e) => setFormData({ ...formData, weekdayRate: e.target.value })}
    placeholder="اختياري"
    className="w-full bg-white border border-border rounded-xl px-4 py-3 outline-none focus:border-primary transition-colors"
  />
              </div>
              <div>
                <label className="block text-sm text-secondary mb-2">سعر نهاية الأسبوع (ر.س)</label>
                <input
    type="number"
    value={formData.weekendRate}
    onChange={(e) => setFormData({ ...formData, weekendRate: e.target.value })}
    placeholder="اختياري"
    className="w-full bg-white border border-border rounded-xl px-4 py-3 outline-none focus:border-primary transition-colors"
  />
              </div>
            </div>

            <div>
              <label className="block text-sm text-secondary mb-3">ساعات العمل *</label>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs text-muted-foreground mb-2 flex items-center gap-1">
                    <Clock className="w-3 h-3" />
                    وقت الفتح
                  </label>
                  <input
    type="time"
    value={formData.openingTime}
    onChange={(e) => setFormData({ ...formData, openingTime: e.target.value })}
    className="w-full bg-white border border-border rounded-xl px-4 py-3 outline-none focus:border-primary transition-colors"
  />
                </div>
                <div>
                  <label className="block text-xs text-muted-foreground mb-2 flex items-center gap-1">
                    <Clock className="w-3 h-3" />
                    وقت الإغلاق
                  </label>
                  <input
    type="time"
    value={formData.closingTime}
    onChange={(e) => setFormData({ ...formData, closingTime: e.target.value })}
    className="w-full bg-white border border-border rounded-xl px-4 py-3 outline-none focus:border-primary transition-colors"
  />
                </div>
              </div>
            </div>

            <div>
              <label className="block text-sm text-secondary mb-2">رقم السجل التجاري *</label>
              <input
    type="text"
    value={formData.commercialLicense}
    onChange={(e) => setFormData({ ...formData, commercialLicense: e.target.value })}
    placeholder="1010xxxxxx"
    className="w-full bg-white border border-border rounded-xl px-4 py-3 outline-none focus:border-primary transition-colors"
  />
            </div>

            <div>
              <label className="block text-sm text-secondary mb-2">الرقم الضريبي</label>
              <input
    type="text"
    value={formData.taxNumber}
    onChange={(e) => setFormData({ ...formData, taxNumber: e.target.value })}
    placeholder="3xxxxxxxxx (اختياري)"
    className="w-full bg-white border border-border rounded-xl px-4 py-3 outline-none focus:border-primary transition-colors"
  />
            </div>

            <div className="bg-gradient-to-br from-primary/10 to-primary/5 border border-primary/30 rounded-2xl p-5">
              <h3 className="text-secondary mb-2">مزايا التسجيل في SPORTA</h3>
              <ul className="space-y-2 text-sm text-muted-foreground">
                <li className="flex items-start gap-2">
                  <span className="text-primary mt-0.5">✓</span>
                  <span>إدارة الحجوزات بشكل تلقائي</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-primary mt-0.5">✓</span>
                  <span>وصول لآلاف اللاعبين النشطين</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-primary mt-0.5">✓</span>
                  <span>تقارير وإحصاءات تفصيلية</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-primary mt-0.5">✓</span>
                  <span>دفع آمن وسريع</span>
                </li>
              </ul>
            </div>

            <div className="bg-muted border border-border rounded-xl p-4">
              <p className="text-xs text-muted-foreground">
                ℹ️ سيتم مراجعة طلبك والتحقق من المستندات خلال 2-3 أيام عمل. ستتلقى إشعاراً عند الموافقة
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
  CourtRegistration as default
};
