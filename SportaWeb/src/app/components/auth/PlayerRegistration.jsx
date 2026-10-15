import { useState } from "react";
import { ChevronRight, ChevronLeft, User, Mail, Phone, MapPin, Camera } from "lucide-react";
const calculateLevel = (formData) => {
  const answers = [
    formData.rallyAbility,
    formData.glassUsage,
    formData.skillDescription,
    formData.netPlay,
    formData.comparisonLevel
  ];
  let score = 0;
  answers.forEach((answer, index) => {
    const options = [
      [
        "\u0623\u0642\u0644 \u0645\u0646 5 \u0636\u0631\u0628\u0627\u062A \u0645\u062A\u062A\u0627\u0644\u064A\u0629",
        "5 \u0625\u0644\u0649 10 \u0636\u0631\u0628\u0627\u062A",
        "10 \u0625\u0644\u0649 20 \u0636\u0631\u0628\u0629",
        "\u0623\u0643\u062B\u0631 \u0645\u0646 20 \u0636\u0631\u0628\u0629 \u0628\u0633\u0647\u0648\u0644\u0629"
      ],
      [
        "\u0644\u0627 \u0623\u0633\u062A\u062E\u062F\u0645 \u0627\u0644\u0632\u062C\u0627\u062C \u0623\u0648 \u0644\u0627 \u0623\u0639\u0631\u0641 \u0643\u064A\u0641\u064A\u0629 \u0627\u0644\u0644\u0639\u0628 \u0628\u0647",
        "\u0623\u062A\u0639\u0627\u0645\u0644 \u0645\u0639 \u0627\u0644\u0643\u0631\u0627\u062A \u0627\u0644\u0633\u0647\u0644\u0629 \u0628\u0639\u062F \u0627\u0644\u0627\u0631\u062A\u062F\u0627\u062F",
        "\u0623\u0633\u062A\u062E\u062F\u0645 \u0627\u0644\u0632\u062C\u0627\u062C \u0628\u0634\u0643\u0644 \u062C\u064A\u062F \u062F\u0641\u0627\u0639\u064A\u0627\u064B",
        "\u0623\u0633\u062A\u062E\u062F\u0645 \u0627\u0644\u0632\u062C\u0627\u062C \u0628\u0645\u0647\u0627\u0631\u0629 \u062F\u0641\u0627\u0639\u064A\u0627\u064B \u0648\u0647\u062C\u0648\u0645\u064A\u0627\u064B"
      ],
      [
        "\u0645\u0627 \u0632\u0644\u062A \u0623\u062A\u0639\u0644\u0645 \u0623\u0633\u0627\u0633\u064A\u0627\u062A \u0627\u0644\u0644\u0639\u0628\u0629",
        "\u0623\u0644\u0639\u0628 \u0645\u0628\u0627\u0631\u064A\u0627\u062A \u062A\u0631\u0641\u064A\u0647\u064A\u0629 \u0628\u0634\u0643\u0644 \u0645\u0646\u062A\u0638\u0645",
        "\u0623\u0641\u0648\u0632 \u063A\u0627\u0644\u0628\u0627\u064B \u0639\u0644\u0649 \u0627\u0644\u0644\u0627\u0639\u0628\u064A\u0646 \u0627\u0644\u0645\u062A\u0648\u0633\u0637\u064A\u0646",
        "\u0623\u0634\u0627\u0631\u0643 \u0623\u0648 \u0623\u0633\u062A\u0637\u064A\u0639 \u0627\u0644\u0645\u0646\u0627\u0641\u0633\u0629 \u0641\u064A \u0627\u0644\u0628\u0637\u0648\u0644\u0627\u062A"
      ],
      [
        "\u0623\u0641\u0636\u0644 \u0627\u0644\u0628\u0642\u0627\u0621 \u0641\u064A \u0627\u0644\u062E\u0644\u0641",
        "\u0623\u062A\u0642\u062F\u0645 \u0644\u0644\u0634\u0628\u0643\u0629 \u0623\u062D\u064A\u0627\u0646\u0627\u064B",
        "\u0623\u062A\u062D\u0643\u0645 \u0641\u064A \u0627\u0644\u0634\u0628\u0643\u0629 \u0645\u0639\u0638\u0645 \u0627\u0644\u0648\u0642\u062A",
        "\u0623\u062C\u064A\u062F \u0625\u0646\u0647\u0627\u0621 \u0627\u0644\u0646\u0642\u0627\u0637 \u0645\u0646 \u0627\u0644\u0634\u0628\u0643\u0629 \u0648\u0623\u062A\u062D\u0643\u0645 \u0628\u0627\u0644\u0645\u0628\u0627\u0631\u0627\u0629"
      ],
      [
        "\u0623\u0642\u0644 \u0645\u0646 \u0627\u0644\u0645\u062A\u0648\u0633\u0637",
        "\u0645\u062A\u0648\u0633\u0637",
        "\u0641\u0648\u0642 \u0627\u0644\u0645\u062A\u0648\u0633\u0637",
        "\u0645\u0646 \u0623\u0641\u0636\u0644 \u0627\u0644\u0644\u0627\u0639\u0628\u064A\u0646 \u0627\u0644\u0630\u064A\u0646 \u0623\u0644\u0639\u0628 \u0645\u0639\u0647\u0645"
      ]
    ];
    const answerIndex = options[index].indexOf(answer);
    if (answerIndex !== -1) {
      score += answerIndex + 1;
    }
  });
  const averageScore = score / 5;
  if (averageScore <= 1.5) return { level: "3.5", range: "3.0 - 4.0", name: "\u0645\u0628\u062A\u062F\u0626" };
  if (averageScore <= 2.5) return { level: "4.5", range: "4.0 - 5.0", name: "\u0645\u062A\u0648\u0633\u0637" };
  if (averageScore <= 3.5) return { level: "5.5", range: "5.0 - 6.0", name: "\u0645\u062A\u0642\u062F\u0645" };
  return { level: "6.5", range: "6.0 - 7.0", name: "\u0645\u062D\u062A\u0631\u0641" };
};
function PlayerRegistration({ onComplete, onBack }) {
  const [step, setStep] = useState(1);
  const [calculatedLevel, setCalculatedLevel] = useState(null);
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
    dominantHand: "",
    courtPosition: "",
    matchType: "",
    preferredTime: "",
    startYear: "",
    experience: "",
    frequency: "",
    competition: "",
    levelKnown: false,
    selectedLevel: "",
    rallyAbility: "",
    glassUsage: "",
    skillDescription: "",
    netPlay: "",
    comparisonLevel: ""
  });
  const totalSteps = 4;
  const handleNext = () => {
    if (step < totalSteps) {
      setStep(step + 1);
    } else {
      let level;
      if (formData.levelKnown && formData.selectedLevel) {
        level = {
          level: formData.selectedLevel,
          range: `${formData.selectedLevel}.0`,
          name: getLevelName(formData.selectedLevel),
          elo: 1e3 + parseInt(formData.selectedLevel) * 200
        };
      } else {
        level = calculateLevel(formData);
      }
      setCalculatedLevel(level);
      onComplete({ ...formData, calculatedLevel: level });
    }
  };
  const getLevelName = (level) => {
    const levelNum = parseFloat(level);
    if (levelNum < 4) return "\u0645\u0628\u062A\u062F\u0626";
    if (levelNum < 5) return "\u0645\u062A\u0648\u0633\u0637";
    if (levelNum < 6) return "\u0645\u062A\u0642\u062F\u0645";
    if (levelNum < 7) return "\u0645\u062D\u062A\u0631\u0641";
    return "\u0646\u062E\u0628\u0629";
  };
  const handleBack = () => {
    if (step > 1) {
      setStep(step - 1);
    } else {
      onBack();
    }
  };
  return <div className="h-screen flex flex-col bg-background">
      <div className="bg-gradient-to-br from-secondary to-secondary/90 text-white px-6 pt-8 pb-6">
        <div className="flex items-center justify-between mb-6">
          <button onClick={handleBack} className="p-2 bg-white/20 rounded-full backdrop-blur-sm">
            <ChevronRight className="w-5 h-5" />
          </button>
          <h1 className="text-xl">تسجيل لاعب جديد</h1>
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
          </div>}

        {step === 2 && <div className="space-y-5">
            <h2 className="text-2xl text-secondary mb-6">الموقع الجغرافي</h2>

            <div>
              <label className="block text-sm text-secondary mb-2">البلد *</label>
              <select
    value={formData.country}
    onChange={(e) => setFormData({ ...formData, country: e.target.value })}
    className="w-full bg-white border border-border rounded-xl px-4 py-3 outline-none focus:border-primary transition-colors"
  >
                <option value="السعودية">السعودية</option>
                <option value="الإمارات">الإمارات</option>
                <option value="الكويت">الكويت</option>
                <option value="قطر">قطر</option>
              </select>
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
              <p className="text-sm text-secondary">
                💡 سنستخدم موقعك لاقتراح الملاعب والمباريات القريبة منك
              </p>
            </div>
          </div>}

        {step === 3 && <div className="space-y-5">
            <h2 className="text-2xl text-secondary mb-6">تفضيلات اللعب</h2>

            <div>
              <label className="block text-sm text-secondary mb-2">اليد المفضلة *</label>
              <div className="grid grid-cols-2 gap-3">
                <button
    onClick={() => setFormData({ ...formData, dominantHand: "right" })}
    className={`py-3 rounded-xl border-2 transition-all ${formData.dominantHand === "right" ? "border-primary bg-primary/10 text-primary" : "border-border bg-white text-secondary"}`}
  >
                  يمين
                </button>
                <button
    onClick={() => setFormData({ ...formData, dominantHand: "left" })}
    className={`py-3 rounded-xl border-2 transition-all ${formData.dominantHand === "left" ? "border-primary bg-primary/10 text-primary" : "border-border bg-white text-secondary"}`}
  >
                  يسار
                </button>
              </div>
            </div>

            <div>
              <label className="block text-sm text-secondary mb-2">موقعك المفضل في الملعب *</label>
              <div className="grid grid-cols-3 gap-3">
                {["\u064A\u0645\u064A\u0646", "\u064A\u0633\u0627\u0631", "\u0643\u0644\u0627\u0647\u0645\u0627"].map((pos) => <button
    key={pos}
    onClick={() => setFormData({ ...formData, courtPosition: pos })}
    className={`py-3 rounded-xl border-2 transition-all ${formData.courtPosition === pos ? "border-primary bg-primary/10 text-primary" : "border-border bg-white text-secondary"}`}
  >
                    {pos}
                  </button>)}
              </div>
            </div>

            <div>
              <label className="block text-sm text-secondary mb-2">نوع المباراة المفضل *</label>
              <div className="grid grid-cols-2 gap-3">
                {["\u062A\u062D\u062F\u064A \u0641\u0631\u0642", "\u0648\u062F\u064A\u0629 \u0641\u0631\u062F\u064A"].map((type) => <button
    key={type}
    onClick={() => setFormData({ ...formData, matchType: type })}
    className={`py-3 rounded-xl border-2 transition-all ${formData.matchType === type ? "border-primary bg-primary/10 text-primary" : "border-border bg-white text-secondary"}`}
  >
                    {type}
                  </button>)}
              </div>
            </div>

            <div>
              <label className="block text-sm text-secondary mb-2">الوقت المفضل للعب *</label>
              <div className="grid grid-cols-2 gap-3">
                {["\u0635\u0628\u0627\u062D", "\u0638\u0647\u0631", "\u0645\u0633\u0627\u0621", "\u0644\u0627 \u0641\u0631\u0642"].map((time) => <button
    key={time}
    onClick={() => setFormData({ ...formData, preferredTime: time })}
    className={`py-3 rounded-xl border-2 transition-all ${formData.preferredTime === time ? "border-primary bg-primary/10 text-primary" : "border-border bg-white text-secondary"}`}
  >
                    {time}
                  </button>)}
              </div>
            </div>
          </div>}

        {step === 4 && <div className="space-y-5">
            <h2 className="text-2xl text-secondary mb-6">تقييم المستوى</h2>

            <div className="bg-gradient-to-br from-primary/10 to-primary/5 border border-primary/30 rounded-2xl p-5 mb-4">
              <div className="flex items-start gap-3 mb-4">
                <input
    type="checkbox"
    checked={formData.levelKnown}
    onChange={(e) => {
      setFormData({ ...formData, levelKnown: e.target.checked });
      if (!e.target.checked) {
        setFormData({ ...formData, selectedLevel: "", levelKnown: false });
      }
    }}
    className="mt-1 w-4 h-4 accent-primary"
  />
                <label className="text-sm text-secondary cursor-pointer" onClick={() => setFormData({ ...formData, levelKnown: !formData.levelKnown })}>
                  أعرف مستواي بالفعل وأريد تحديده مباشرة (تخطي الأسئلة)
                </label>
              </div>

              {formData.levelKnown && <div>
                  <p className="text-xs text-muted-foreground mb-3">اختر مستواك من 1 إلى 7:</p>
                  <div className="grid grid-cols-7 gap-2">
                    {["1", "2", "3", "4", "5", "6", "7"].map((level) => <button
    key={level}
    onClick={() => setFormData({ ...formData, selectedLevel: level })}
    className={`py-3 rounded-xl border-2 transition-all ${formData.selectedLevel === level ? "border-primary bg-primary text-white" : "border-primary/30 bg-white text-primary"}`}
  >
                        {level}
                      </button>)}
                  </div>
                </div>}
            </div>

            {!formData.levelKnown && <>
                <div className="bg-primary/5 border border-primary/20 rounded-xl p-4 mb-4">
                  <p className="text-sm text-secondary">
                    💡 أجب على الأسئلة التالية بصدق لتحديد مستواك الأولي بدقة
                  </p>
                </div>

                <div>
              <label className="block text-sm text-secondary mb-3">
                1. ما مدى قدرتك على الحفاظ على تبادل الكرات (Rally) مع لاعبين من مستواك؟ *
              </label>
              <div className="space-y-2">
                {[
    "\u0623\u0642\u0644 \u0645\u0646 5 \u0636\u0631\u0628\u0627\u062A \u0645\u062A\u062A\u0627\u0644\u064A\u0629",
    "5 \u0625\u0644\u0649 10 \u0636\u0631\u0628\u0627\u062A",
    "10 \u0625\u0644\u0649 20 \u0636\u0631\u0628\u0629",
    "\u0623\u0643\u062B\u0631 \u0645\u0646 20 \u0636\u0631\u0628\u0629 \u0628\u0633\u0647\u0648\u0644\u0629"
  ].map((option) => <button
    key={option}
    onClick={() => setFormData({ ...formData, rallyAbility: option })}
    className={`w-full py-3 px-4 rounded-xl border-2 transition-all text-sm text-right ${formData.rallyAbility === option ? "border-primary bg-primary/10 text-primary" : "border-border bg-white text-secondary"}`}
  >
                    {option}
                  </button>)}
              </div>
            </div>

            <div>
              <label className="block text-sm text-secondary mb-3">
                2. ما مدى استخدامك للزجاج (Glass) أثناء اللعب؟ *
              </label>
              <div className="space-y-2">
                {[
    "\u0644\u0627 \u0623\u0633\u062A\u062E\u062F\u0645 \u0627\u0644\u0632\u062C\u0627\u062C \u0623\u0648 \u0644\u0627 \u0623\u0639\u0631\u0641 \u0643\u064A\u0641\u064A\u0629 \u0627\u0644\u0644\u0639\u0628 \u0628\u0647",
    "\u0623\u062A\u0639\u0627\u0645\u0644 \u0645\u0639 \u0627\u0644\u0643\u0631\u0627\u062A \u0627\u0644\u0633\u0647\u0644\u0629 \u0628\u0639\u062F \u0627\u0644\u0627\u0631\u062A\u062F\u0627\u062F",
    "\u0623\u0633\u062A\u062E\u062F\u0645 \u0627\u0644\u0632\u062C\u0627\u062C \u0628\u0634\u0643\u0644 \u062C\u064A\u062F \u062F\u0641\u0627\u0639\u064A\u0627\u064B",
    "\u0623\u0633\u062A\u062E\u062F\u0645 \u0627\u0644\u0632\u062C\u0627\u062C \u0628\u0645\u0647\u0627\u0631\u0629 \u062F\u0641\u0627\u0639\u064A\u0627\u064B \u0648\u0647\u062C\u0648\u0645\u064A\u0627\u064B"
  ].map((option) => <button
    key={option}
    onClick={() => setFormData({ ...formData, glassUsage: option })}
    className={`w-full py-3 px-4 rounded-xl border-2 transition-all text-sm text-right ${formData.glassUsage === option ? "border-primary bg-primary/10 text-primary" : "border-border bg-white text-secondary"}`}
  >
                    {option}
                  </button>)}
              </div>
            </div>

            <div>
              <label className="block text-sm text-secondary mb-3">
                3. أي وصف ينطبق عليك أكثر؟ *
              </label>
              <div className="space-y-2">
                {[
    "\u0645\u0627 \u0632\u0644\u062A \u0623\u062A\u0639\u0644\u0645 \u0623\u0633\u0627\u0633\u064A\u0627\u062A \u0627\u0644\u0644\u0639\u0628\u0629",
    "\u0623\u0644\u0639\u0628 \u0645\u0628\u0627\u0631\u064A\u0627\u062A \u062A\u0631\u0641\u064A\u0647\u064A\u0629 \u0628\u0634\u0643\u0644 \u0645\u0646\u062A\u0638\u0645",
    "\u0623\u0641\u0648\u0632 \u063A\u0627\u0644\u0628\u0627\u064B \u0639\u0644\u0649 \u0627\u0644\u0644\u0627\u0639\u0628\u064A\u0646 \u0627\u0644\u0645\u062A\u0648\u0633\u0637\u064A\u0646",
    "\u0623\u0634\u0627\u0631\u0643 \u0623\u0648 \u0623\u0633\u062A\u0637\u064A\u0639 \u0627\u0644\u0645\u0646\u0627\u0641\u0633\u0629 \u0641\u064A \u0627\u0644\u0628\u0637\u0648\u0644\u0627\u062A"
  ].map((option) => <button
    key={option}
    onClick={() => setFormData({ ...formData, skillDescription: option })}
    className={`w-full py-3 px-4 rounded-xl border-2 transition-all text-sm text-right ${formData.skillDescription === option ? "border-primary bg-primary/10 text-primary" : "border-border bg-white text-secondary"}`}
  >
                    {option}
                  </button>)}
              </div>
            </div>

            <div>
              <label className="block text-sm text-secondary mb-3">
                4. ما مدى قدرتك على اللعب بالقرب من الشبكة (Net Play)؟ *
              </label>
              <div className="space-y-2">
                {[
    "\u0623\u0641\u0636\u0644 \u0627\u0644\u0628\u0642\u0627\u0621 \u0641\u064A \u0627\u0644\u062E\u0644\u0641",
    "\u0623\u062A\u0642\u062F\u0645 \u0644\u0644\u0634\u0628\u0643\u0629 \u0623\u062D\u064A\u0627\u0646\u0627\u064B",
    "\u0623\u062A\u062D\u0643\u0645 \u0641\u064A \u0627\u0644\u0634\u0628\u0643\u0629 \u0645\u0639\u0638\u0645 \u0627\u0644\u0648\u0642\u062A",
    "\u0623\u062C\u064A\u062F \u0625\u0646\u0647\u0627\u0621 \u0627\u0644\u0646\u0642\u0627\u0637 \u0645\u0646 \u0627\u0644\u0634\u0628\u0643\u0629 \u0648\u0623\u062A\u062D\u0643\u0645 \u0628\u0627\u0644\u0645\u0628\u0627\u0631\u0627\u0629"
  ].map((option) => <button
    key={option}
    onClick={() => setFormData({ ...formData, netPlay: option })}
    className={`w-full py-3 px-4 rounded-xl border-2 transition-all text-sm text-right ${formData.netPlay === option ? "border-primary bg-primary/10 text-primary" : "border-border bg-white text-secondary"}`}
  >
                    {option}
                  </button>)}
              </div>
            </div>

            <div>
              <label className="block text-sm text-secondary mb-3">
                5. كيف تقيّم مستواك مقارنة بأصدقائك أو اللاعبين الذين تلعب معهم؟ *
              </label>
              <div className="space-y-2">
                {[
    "\u0623\u0642\u0644 \u0645\u0646 \u0627\u0644\u0645\u062A\u0648\u0633\u0637",
    "\u0645\u062A\u0648\u0633\u0637",
    "\u0641\u0648\u0642 \u0627\u0644\u0645\u062A\u0648\u0633\u0637",
    "\u0645\u0646 \u0623\u0641\u0636\u0644 \u0627\u0644\u0644\u0627\u0639\u0628\u064A\u0646 \u0627\u0644\u0630\u064A\u0646 \u0623\u0644\u0639\u0628 \u0645\u0639\u0647\u0645"
  ].map((option) => <button
    key={option}
    onClick={() => setFormData({ ...formData, comparisonLevel: option })}
    className={`w-full py-3 px-4 rounded-xl border-2 transition-all text-sm text-right ${formData.comparisonLevel === option ? "border-primary bg-primary/10 text-primary" : "border-border bg-white text-secondary"}`}
  >
                    {option}
                  </button>)}
              </div>
            </div>

            <div className="bg-muted border border-border rounded-xl p-4">
              <p className="text-xs text-muted-foreground">
                ℹ️ سيتم تحديد مستواك الأولي بناءً على إجاباتك. المستوى سيتطور تلقائياً بناءً على نتائج المباريات ونظام ELO
              </p>
            </div>
              </>}
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
            {step === totalSteps ? "\u0625\u0646\u0634\u0627\u0621 \u0627\u0644\u062D\u0633\u0627\u0628" : "\u0627\u0644\u062A\u0627\u0644\u064A"}
            {step < totalSteps && <ChevronLeft className="w-5 h-5" />}
          </button>
        </div>
      </div>
    </div>;
}
export {
  PlayerRegistration as default
};
