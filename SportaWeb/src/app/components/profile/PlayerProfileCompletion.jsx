import { useState } from "react";
import { ChevronRight, ChevronLeft } from "lucide-react";
const calculateLevel = (formData) => {
  const answers = [
    formData.rallyAbility,
    formData.glassUsage,
    formData.skillDescription,
    formData.netPlay,
    formData.comparisonLevel
  ];
  let score = 0;
  const options = [
    ["\u0623\u0642\u0644 \u0645\u0646 5 \u0636\u0631\u0628\u0627\u062A \u0645\u062A\u062A\u0627\u0644\u064A\u0629", "5 \u0625\u0644\u0649 10 \u0636\u0631\u0628\u0627\u062A", "10 \u0625\u0644\u0649 20 \u0636\u0631\u0628\u0629", "\u0623\u0643\u062B\u0631 \u0645\u0646 20 \u0636\u0631\u0628\u0629 \u0628\u0633\u0647\u0648\u0644\u0629"],
    ["\u0644\u0627 \u0623\u0633\u062A\u062E\u062F\u0645 \u0627\u0644\u0632\u062C\u0627\u062C \u0623\u0648 \u0644\u0627 \u0623\u0639\u0631\u0641 \u0643\u064A\u0641\u064A\u0629 \u0627\u0644\u0644\u0639\u0628 \u0628\u0647", "\u0623\u062A\u0639\u0627\u0645\u0644 \u0645\u0639 \u0627\u0644\u0643\u0631\u0627\u062A \u0627\u0644\u0633\u0647\u0644\u0629 \u0628\u0639\u062F \u0627\u0644\u0627\u0631\u062A\u062F\u0627\u062F", "\u0623\u0633\u062A\u062E\u062F\u0645 \u0627\u0644\u0632\u062C\u0627\u062C \u0628\u0634\u0643\u0644 \u062C\u064A\u062F \u062F\u0641\u0627\u0639\u064A\u0627\u064B", "\u0623\u0633\u062A\u062E\u062F\u0645 \u0627\u0644\u0632\u062C\u0627\u062C \u0628\u0645\u0647\u0627\u0631\u0629 \u062F\u0641\u0627\u0639\u064A\u0627\u064B \u0648\u0647\u062C\u0648\u0645\u064A\u0627\u064B"],
    ["\u0645\u0627 \u0632\u0644\u062A \u0623\u062A\u0639\u0644\u0645 \u0623\u0633\u0627\u0633\u064A\u0627\u062A \u0627\u0644\u0644\u0639\u0628\u0629", "\u0623\u0644\u0639\u0628 \u0645\u0628\u0627\u0631\u064A\u0627\u062A \u062A\u0631\u0641\u064A\u0647\u064A\u0629 \u0628\u0634\u0643\u0644 \u0645\u0646\u062A\u0638\u0645", "\u0623\u0641\u0648\u0632 \u063A\u0627\u0644\u0628\u0627\u064B \u0639\u0644\u0649 \u0627\u0644\u0644\u0627\u0639\u0628\u064A\u0646 \u0627\u0644\u0645\u062A\u0648\u0633\u0637\u064A\u0646", "\u0623\u0634\u0627\u0631\u0643 \u0623\u0648 \u0623\u0633\u062A\u0637\u064A\u0639 \u0627\u0644\u0645\u0646\u0627\u0641\u0633\u0629 \u0641\u064A \u0627\u0644\u0628\u0637\u0648\u0644\u0627\u062A"],
    ["\u0623\u0641\u0636\u0644 \u0627\u0644\u0628\u0642\u0627\u0621 \u0641\u064A \u0627\u0644\u062E\u0644\u0641", "\u0623\u062A\u0642\u062F\u0645 \u0644\u0644\u0634\u0628\u0643\u0629 \u0623\u062D\u064A\u0627\u0646\u0627\u064B", "\u0623\u062A\u062D\u0643\u0645 \u0641\u064A \u0627\u0644\u0634\u0628\u0643\u0629 \u0645\u0639\u0638\u0645 \u0627\u0644\u0648\u0642\u062A", "\u0623\u062C\u064A\u062F \u0625\u0646\u0647\u0627\u0621 \u0627\u0644\u0646\u0642\u0627\u0637 \u0645\u0646 \u0627\u0644\u0634\u0628\u0643\u0629 \u0648\u0623\u062A\u062D\u0643\u0645 \u0628\u0627\u0644\u0645\u0628\u0627\u0631\u0627\u0629"],
    ["\u0623\u0642\u0644 \u0645\u0646 \u0627\u0644\u0645\u062A\u0648\u0633\u0637", "\u0645\u062A\u0648\u0633\u0637", "\u0641\u0648\u0642 \u0627\u0644\u0645\u062A\u0648\u0633\u0637", "\u0645\u0646 \u0623\u0641\u0636\u0644 \u0627\u0644\u0644\u0627\u0639\u0628\u064A\u0646 \u0627\u0644\u0630\u064A\u0646 \u0623\u0644\u0639\u0628 \u0645\u0639\u0647\u0645"]
  ];
  answers.forEach((answer, index) => {
    const answerIndex = options[index].indexOf(answer);
    if (answerIndex !== -1) {
      score += answerIndex + 1;
    }
  });
  const averageScore = score / 5;
  if (averageScore <= 1.5) return { level: "3.5", range: "3.0 - 4.0", name: "\u0645\u0628\u062A\u062F\u0626", elo: 1200 };
  if (averageScore <= 2.5) return { level: "4.5", range: "4.0 - 5.0", name: "\u0645\u062A\u0648\u0633\u0637", elo: 1400 };
  if (averageScore <= 3.5) return { level: "5.5", range: "5.0 - 6.0", name: "\u0645\u062A\u0642\u062F\u0645", elo: 1600 };
  return { level: "6.5", range: "6.0 - 7.0", name: "\u0645\u062D\u062A\u0631\u0641", elo: 1800 };
};
function PlayerProfileCompletion({ onComplete, onBack }) {
  const [step, setStep] = useState(1);
  const [formData, setFormData] = useState({
    dominantHand: "",
    courtPosition: "",
    matchType: "",
    preferredTime: "",
    frequency: "",
    levelKnown: false,
    selectedLevel: "",
    rallyAbility: "",
    glassUsage: "",
    skillDescription: "",
    netPlay: "",
    comparisonLevel: ""
  });
  const totalSteps = 2;
  const handleNext = () => {
    if (step < totalSteps) {
      setStep(step + 1);
    } else {
      const level = formData.levelKnown && formData.selectedLevel ? {
        level: formData.selectedLevel,
        range: `${formData.selectedLevel}.0`,
        name: getLevelName(formData.selectedLevel),
        elo: 1e3 + parseInt(formData.selectedLevel) * 200
      } : calculateLevel(formData);
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
          <h1 className="text-xl">إكمال ملف اللاعب</h1>
          <div className="w-9" />
        </div>

        <div className="flex gap-2">
          {[1, 2].map((s) => <div
    key={s}
    className={`flex-1 h-1 rounded-full transition-all ${s <= step ? "bg-primary" : "bg-white/30"}`}
  />)}
        </div>
        <p className="text-center text-sm text-white/80 mt-2">خطوة {step} من {totalSteps}</p>
      </div>

      <div className="flex-1 overflow-y-auto px-6 py-6">
        {step === 1 && <div className="space-y-5">
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
              <label className="block text-sm text-secondary mb-2">الموقع المفضل في الملعب *</label>
              <div className="grid grid-cols-2 gap-3">
                <button
    onClick={() => setFormData({ ...formData, courtPosition: "right" })}
    className={`py-3 rounded-xl border-2 transition-all ${formData.courtPosition === "right" ? "border-primary bg-primary/10 text-primary" : "border-border bg-white text-secondary"}`}
  >
                  يمين
                </button>
                <button
    onClick={() => setFormData({ ...formData, courtPosition: "left" })}
    className={`py-3 rounded-xl border-2 transition-all ${formData.courtPosition === "left" ? "border-primary bg-primary/10 text-primary" : "border-border bg-white text-secondary"}`}
  >
                  يسار
                </button>
              </div>
            </div>

            <div>
              <label className="block text-sm text-secondary mb-2">نوع المباراة المفضل *</label>
              <div className="grid grid-cols-2 gap-3">
                <button
    onClick={() => setFormData({ ...formData, matchType: "challenge-team" })}
    className={`py-3 rounded-xl border-2 transition-all ${formData.matchType === "challenge-team" ? "border-primary bg-primary/10 text-primary" : "border-border bg-white text-secondary"}`}
  >
                  تحدي فرق
                </button>
                <button
    onClick={() => setFormData({ ...formData, matchType: "friendly-individual" })}
    className={`py-3 rounded-xl border-2 transition-all ${formData.matchType === "friendly-individual" ? "border-primary bg-primary/10 text-primary" : "border-border bg-white text-secondary"}`}
  >
                  ودية فردي
                </button>
              </div>
            </div>

            <div>
              <label className="block text-sm text-secondary mb-2">الوقت المفضل للعب *</label>
              <div className="grid grid-cols-2 gap-3">
                {["\u0635\u0628\u0627\u062D\u0627\u064B", "\u0638\u0647\u0631\u0627\u064B", "\u0645\u0633\u0627\u0621\u064B", "\u0644\u064A\u0644\u0627\u064B"].map((time) => <button
    key={time}
    onClick={() => setFormData({ ...formData, preferredTime: time })}
    className={`py-3 rounded-xl border-2 transition-all ${formData.preferredTime === time ? "border-primary bg-primary/10 text-primary" : "border-border bg-white text-secondary"}`}
  >
                    {time}
                  </button>)}
              </div>
            </div>

            <div>
              <label className="block text-sm text-secondary mb-2">كم مرة تلعب أسبوعياً؟ *</label>
              <div className="grid grid-cols-2 gap-3">
                {["\u0645\u0631\u0629 \u0648\u0627\u062D\u062F\u0629", "2-3 \u0645\u0631\u0627\u062A", "4-5 \u0645\u0631\u0627\u062A", "\u064A\u0648\u0645\u064A\u0627\u064B"].map((freq) => <button
    key={freq}
    onClick={() => setFormData({ ...formData, frequency: freq })}
    className={`py-3 rounded-xl border-2 transition-all ${formData.frequency === freq ? "border-primary bg-primary/10 text-primary" : "border-border bg-white text-secondary"}`}
  >
                    {freq}
                  </button>)}
              </div>
            </div>
          </div>}

        {step === 2 && <div className="space-y-5">
            <h2 className="text-2xl text-secondary mb-6">تحديد مستواك</h2>

            <div className="bg-primary/5 border border-primary/20 rounded-xl p-4 mb-4">
              <p className="text-sm text-secondary">
                💡 سنساعدك في تحديد مستواك من خلال بعض الأسئلة
              </p>
            </div>

            <div>
              <label className="block text-sm text-secondary mb-3">
                1. كم ضربة متتالية تستطيع أن تلعبها مع شريكك بدون أخطاء؟ *
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
    className={`w-full py-3 px-4 rounded-xl border-2 transition-all text-right ${formData.rallyAbility === option ? "border-primary bg-primary/10 text-primary" : "border-border bg-white text-secondary"}`}
  >
                    {option}
                  </button>)}
              </div>
            </div>

            <div>
              <label className="block text-sm text-secondary mb-3">
                2. كيف تتعامل مع الكرات المرتدة من الزجاج؟ *
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
    className={`w-full py-3 px-4 rounded-xl border-2 transition-all text-right ${formData.glassUsage === option ? "border-primary bg-primary/10 text-primary" : "border-border bg-white text-secondary"}`}
  >
                    {option}
                  </button>)}
              </div>
            </div>

            <div>
              <label className="block text-sm text-secondary mb-3">
                3. كيف تصف مستواك في اللعب؟ *
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
    className={`w-full py-3 px-4 rounded-xl border-2 transition-all text-right ${formData.skillDescription === option ? "border-primary bg-primary/10 text-primary" : "border-border bg-white text-secondary"}`}
  >
                    {option}
                  </button>)}
              </div>
            </div>

            <div>
              <label className="block text-sm text-secondary mb-3">
                4. ما مدى مهارتك في اللعب عند الشبكة؟ *
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
    className={`w-full py-3 px-4 rounded-xl border-2 transition-all text-right ${formData.netPlay === option ? "border-primary bg-primary/10 text-primary" : "border-border bg-white text-secondary"}`}
  >
                    {option}
                  </button>)}
              </div>
            </div>

            <div>
              <label className="block text-sm text-secondary mb-3">
                5. بالمقارنة مع اللاعبين الذين تلعب معهم، كيف تقيّم مستواك؟ *
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
    className={`w-full py-3 px-4 rounded-xl border-2 transition-all text-right ${formData.comparisonLevel === option ? "border-primary bg-primary/10 text-primary" : "border-border bg-white text-secondary"}`}
  >
                    {option}
                  </button>)}
              </div>
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
  PlayerProfileCompletion as default
};
