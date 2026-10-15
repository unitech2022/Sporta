import { useState } from "react";
import { ChevronRight, Star, Trophy, Zap, Target, Gift, Award, BookOpen, Clock, Shield, AlertTriangle, ChevronDown, ChevronUp } from "lucide-react";
function PointsSystemPage({ onBack }) {
  const [openFaq, setOpenFaq] = useState(null);
  const levelTiers = [
    { level: "\u0628\u0631\u0648\u0646\u0632\u064A", min: 0, max: 99, color: "from-amber-700 to-amber-600", icon: "\u{1F949}", perks: ["\u062E\u0635\u0645 5% \u0639\u0644\u0649 \u0627\u0644\u062D\u062C\u0648\u0632\u0627\u062A", "\u0623\u0648\u0644\u0648\u064A\u0629 \u0641\u064A \u0627\u0644\u0642\u0648\u0627\u0626\u0645"] },
    { level: "\u0641\u0636\u064A", min: 100, max: 299, color: "from-gray-400 to-gray-300", icon: "\u{1F948}", perks: ["\u062E\u0635\u0645 10% \u0639\u0644\u0649 \u0627\u0644\u062D\u062C\u0648\u0632\u0627\u062A", "\u062D\u0635\u0629 \u062A\u062F\u0631\u064A\u0628\u064A\u0629 \u0645\u062C\u0627\u0646\u064A\u0629 \u0634\u0647\u0631\u064A\u0627\u064B", "\u0623\u0648\u0644\u0648\u064A\u0629 \u0641\u064A \u0627\u0644\u062A\u0633\u062C\u064A\u0644"] },
    { level: "\u0630\u0647\u0628\u064A", min: 300, max: 999, color: "from-yellow-500 to-yellow-400", icon: "\u{1F947}", perks: ["\u062E\u0635\u0645 15% \u0639\u0644\u0649 \u0627\u0644\u062D\u062C\u0648\u0632\u0627\u062A", "\u062D\u0635\u062A\u0627\u0646 \u0645\u062C\u0627\u0646\u064A\u062A\u0627\u0646 \u0634\u0647\u0631\u064A\u0627\u064B", "\u062F\u0639\u0648\u0629 \u0627\u0644\u0628\u0637\u0648\u0644\u0627\u062A \u0627\u0644\u062D\u0635\u0631\u064A\u0629"] },
    { level: "\u0628\u0644\u0627\u062A\u064A\u0646\u064A", min: 1e3, max: 4999, color: "from-cyan-500 to-cyan-400", icon: "\u{1F48E}", perks: ["\u062E\u0635\u0645 20% \u0639\u0644\u0649 \u0643\u0644 \u0634\u064A\u0621", "\u062C\u0644\u0633\u0627\u062A VIP", "\u0645\u062F\u0631\u0628 \u0634\u062E\u0635\u064A \u0645\u062C\u0627\u0646\u064A"] },
    { level: "\u0623\u0633\u0637\u0648\u0631\u064A", min: 5e3, max: Infinity, color: "from-purple-600 to-pink-500", icon: "\u{1F451}", perks: ["\u062C\u0645\u064A\u0639 \u0627\u0644\u0645\u0632\u0627\u064A\u0627", "\u062F\u0639\u0648\u0627\u062A \u062E\u0627\u0635\u0629", "\u0634\u0627\u0631\u0629 \u062D\u0635\u0631\u064A\u0629 \u0641\u064A \u0627\u0644\u0645\u0644\u0641 \u0627\u0644\u0634\u062E\u0635\u064A"] }
  ];
  const earningWays = [
    { icon: Trophy, label: "\u0644\u0643\u0644 \u0645\u0628\u0627\u0631\u0627\u0629 \u062A\u0644\u0639\u0628\u0647\u0627", points: "+1 \u0646\u0642\u0637\u0629", color: "bg-green-100 text-green-600" },
    { icon: Clock, label: "\u0644\u0643\u0644 \u0633\u0627\u0639\u0629 \u062A\u062F\u0631\u064A\u0628\u064A\u0629 \u062A\u062D\u0636\u0631\u0647\u0627", points: "+1 \u0646\u0642\u0637\u0629 \u062A\u062F\u0631\u064A\u0628\u064A\u0629", color: "bg-blue-100 text-blue-600" },
    { icon: BookOpen, label: "\u0644\u0643\u0644 \u062D\u062C\u0632 \u0645\u0644\u0639\u0628 \u062A\u0646\u0641\u0630\u0647", points: "+1 \u0646\u0642\u0637\u0629", color: "bg-violet-100 text-violet-600" },
    { icon: Zap, label: "\u0644\u0643\u0644 \u0628\u0637\u0648\u0644\u0629 \u062A\u0646\u0636\u0645 \u0625\u0644\u064A\u0647\u0627", points: "+5 \u0646\u0642\u0627\u0637", color: "bg-orange-100 text-orange-600" },
    { icon: Star, label: "\u062F\u0639\u0648\u0629 \u0644\u0627\u0639\u0628 \u062C\u062F\u064A\u062F \u0644\u0644\u062A\u0637\u0628\u064A\u0642", points: "+3 \u0646\u0642\u0627\u0637", color: "bg-pink-100 text-pink-600" },
    { icon: Gift, label: "\u062A\u0642\u064A\u064A\u0645 (\u0645\u062F\u0631\u0628 \u2013 \u0645\u0644\u0639\u0628 \u2013 \u0627\u0644\u062A\u0637\u0628\u064A\u0642)", points: "+2 \u0646\u0642\u0637\u062A\u0627\u0646", color: "bg-teal-100 text-teal-600" }
  ];
  const levelBonus = [
    { label: "\u0641\u0627\u0632 \u0628\u0645\u0628\u0627\u0631\u0627\u0629 \u0643\u0627\u0645\u0644\u0629 \u0639\u0644\u0649 \u0646\u0641\u0633 \u0627\u0644\u0645\u0633\u062A\u0648\u0649", points: "+3 \u0646\u0642\u0627\u0637" },
    { label: "\u0641\u0627\u0632 \u0628\u0645\u0628\u0627\u0631\u0627\u0629 \u0643\u0627\u0645\u0644\u0629 \u0628\u062E\u0635\u0645 \u0623\u0642\u0644 \u0645\u0646 \u0627\u0644\u0645\u0633\u062A\u0648\u0649", points: "+1 \u0646\u0642\u0637\u0629" },
    { label: "\u0641\u0627\u0632 \u0628\u0645\u0628\u0627\u0631\u0627\u0629 \u0643\u0627\u0645\u0644\u0629 \u0628\u062E\u0635\u0645 \u0623\u0639\u0644\u0649 \u0645\u0646 \u0627\u0644\u0645\u0633\u062A\u0648\u0649", points: "+5 \u0646\u0642\u0627\u0637" }
  ];
  const faqs = [
    { q: "\u0643\u064A\u0641 \u0623\u0633\u062A\u062E\u062F\u0645 \u0627\u0644\u0646\u0642\u0627\u0637\u061F", a: "\u064A\u0645\u0643\u0646\u0643 \u0627\u0633\u062A\u0628\u062F\u0627\u0644 \u0627\u0644\u0646\u0642\u0627\u0637 \u0628\u062E\u0635\u0648\u0645\u0627\u062A \u0639\u0644\u0649 \u0627\u0644\u062D\u062C\u0648\u0632\u0627\u062A \u0623\u0648 \u0627\u0644\u062D\u0635\u0635 \u0627\u0644\u062A\u062F\u0631\u064A\u0628\u064A\u0629 \u0645\u0628\u0627\u0634\u0631\u0629\u064B \u0639\u0646\u062F \u0627\u0644\u062F\u0641\u0639." },
    { q: "\u0647\u0644 \u0623\u062E\u0633\u0631 \u0646\u0642\u0627\u0637\u0627\u064B \u0639\u0646\u062F \u0627\u0644\u0625\u0644\u063A\u0627\u0621\u061F", a: "\u0646\u0639\u0645\u060C \u0639\u0646\u062F \u0625\u0644\u063A\u0627\u0621 \u062D\u062C\u0632 \u0628\u0639\u062F \u0627\u0646\u062A\u0647\u0627\u0621 \u0627\u0644\u0645\u062F\u0629 \u0627\u0644\u0645\u0633\u0645\u0648\u062D\u0629 \u064A\u064F\u062E\u0635\u0645 \u0646\u0642\u0637\u062A\u0627\u0646 \u0645\u0646 \u0631\u0635\u064A\u062F\u0643." },
    { q: "\u0647\u0644 \u064A\u0645\u0643\u0646 \u062A\u062D\u0648\u064A\u0644 \u0627\u0644\u0646\u0642\u0627\u0637 \u0644\u0634\u062E\u0635 \u0622\u062E\u0631\u061F", a: "\u062D\u0627\u0644\u064A\u0627\u064B \u0627\u0644\u0646\u0642\u0627\u0637 \u063A\u064A\u0631 \u0642\u0627\u0628\u0644\u0629 \u0644\u0644\u062A\u062D\u0648\u064A\u0644 \u0648\u0647\u064A \u0645\u0631\u062A\u0628\u0637\u0629 \u0628\u062D\u0633\u0627\u0628\u0643 \u0627\u0644\u0634\u062E\u0635\u064A \u0641\u0642\u0637." }
  ];
  return <div className="flex-1 overflow-y-auto bg-gray-50">
      {
    /* هيدر إبداعي */
  }
      <div className="relative bg-gradient-to-br from-[#1a1a2e] via-[#16213e] to-[#0f3460] px-6 pt-10 pb-20 overflow-hidden">
        {
    /* دوائر زخرفية */
  }
        <div className="absolute -top-10 -left-10 w-40 h-40 bg-yellow-400/10 rounded-full blur-2xl" />
        <div className="absolute top-10 right-0 w-32 h-32 bg-primary/20 rounded-full blur-2xl" />
        <div className="absolute bottom-0 left-1/3 w-24 h-24 bg-purple-500/20 rounded-full blur-xl" />

        {
    /* نجوم متناثرة */
  }
        {[...Array(12)].map((_, i) => <div
    key={i}
    className="absolute w-1 h-1 bg-white rounded-full opacity-60"
    style={{ top: `${10 + Math.sin(i * 1.3) * 40}%`, left: `${5 + i * 8.2 % 90}%` }}
  />)}

        <div className="flex items-center gap-3 mb-8 relative z-10">
          <button onClick={onBack} className="p-2 bg-white/10 backdrop-blur-sm rounded-full hover:bg-white/20 transition-colors">
            <ChevronRight className="w-5 h-5 text-white" />
          </button>
          <span className="text-white/70 text-sm">الرئيسية</span>
        </div>

        <div className="text-center relative z-10">
          <div className="w-20 h-20 mx-auto mb-4 bg-gradient-to-br from-yellow-400 to-orange-500 rounded-2xl flex items-center justify-center shadow-2xl shadow-yellow-500/30">
            <Trophy className="w-10 h-10 text-white" />
          </div>
          <h1 className="text-3xl text-white mb-2">نظام النقاط</h1>
          <p className="text-white/60 text-sm max-w-xs mx-auto leading-relaxed">
            اكسب نقاطاً مع كل نشاط وارتقِ للمستويات الأعلى للحصول على مزايا حصرية
          </p>
        </div>
      </div>

      <div className="-mt-10 px-4 pb-8 space-y-5 relative z-10">

        {
    /* مستويات اللاعب */
  }
        <div className="bg-white rounded-3xl p-5 shadow-sm">
          <div className="flex items-center gap-2 mb-4">
            <div className="w-8 h-8 bg-yellow-100 rounded-xl flex items-center justify-center">
              <Award className="w-4 h-4 text-yellow-600" />
            </div>
            <h2 className="text-secondary">مستويات اللاعب</h2>
          </div>
          <p className="text-xs text-muted-foreground mb-4">بناءً على نتائج المباريات التي تلعبها</p>
          <div className="space-y-3">
            {levelTiers.map((tier) => <div key={tier.level} className={`rounded-2xl p-4 bg-gradient-to-r ${tier.color} text-white`}>
                <div className="flex items-center justify-between mb-2">
                  <span className="text-sm opacity-80">
                    {tier.max === Infinity ? `${tier.min.toLocaleString()}+ \u0646\u0642\u0637\u0629` : `${tier.min.toLocaleString()} \u2013 ${tier.max.toLocaleString()} \u0646\u0642\u0637\u0629`}
                  </span>
                  <div className="flex items-center gap-2">
                    <span className="text-lg">{tier.icon}</span>
                    <span className="text-lg">{tier.level}</span>
                  </div>
                </div>
                <div className="flex flex-wrap gap-1 justify-end">
                  {tier.perks.map((p) => <span key={p} className="text-xs bg-white/20 rounded-full px-2 py-0.5">{p}</span>)}
                </div>
              </div>)}
          </div>
        </div>

        {
    /* مضاعفات النقاط حسب المستوى */
  }
        <div className="bg-white rounded-3xl p-5 shadow-sm">
          <div className="flex items-center gap-2 mb-4">
            <div className="w-8 h-8 bg-primary/10 rounded-xl flex items-center justify-center">
              <Target className="w-4 h-4 text-primary" />
            </div>
            <h2 className="text-secondary">مضاعفات النقاط</h2>
          </div>
          <p className="text-xs text-muted-foreground mb-4">بناءً على نتائج المباريات التي تلعبها</p>
          <div className="space-y-2">
            {levelBonus.map((b, i) => <div key={i} className="flex items-center justify-between bg-gray-50 rounded-xl p-3">
                <span className={`text-lg px-3 py-1 rounded-xl ${i === 0 ? "bg-green-100 text-green-700" : i === 1 ? "bg-blue-100 text-blue-700" : "bg-purple-100 text-purple-700"}`}>
                  {b.points}
                </span>
                <p className="text-sm text-secondary text-right flex-1 mr-3">{b.label}</p>
              </div>)}
          </div>
        </div>

        {
    /* طرق كسب النقاط */
  }
        <div className="bg-white rounded-3xl p-5 shadow-sm">
          <div className="flex items-center gap-2 mb-4">
            <div className="w-8 h-8 bg-green-100 rounded-xl flex items-center justify-center">
              <Zap className="w-4 h-4 text-green-600" />
            </div>
            <h2 className="text-secondary">نقاط نشاط اللاعب</h2>
          </div>
          <div className="grid grid-cols-2 gap-3">
            {earningWays.map((w, i) => <div key={i} className="bg-gray-50 rounded-2xl p-3 flex flex-col gap-2">
                <div className={`w-9 h-9 rounded-xl flex items-center justify-center ${w.color} self-end`}>
                  <w.icon className="w-4 h-4" />
                </div>
                <p className="text-xs text-secondary text-right leading-tight">{w.label}</p>
                <span className="text-sm text-primary self-end">{w.points}</span>
              </div>)}
          </div>
        </div>

        {
    /* تحذير الإلغاء */
  }
        <div className="bg-red-50 border border-red-100 rounded-3xl p-5 flex items-start gap-3">
          <div className="w-8 h-8 bg-red-100 rounded-xl flex items-center justify-center flex-shrink-0 mt-0.5">
            <AlertTriangle className="w-4 h-4 text-red-500" />
          </div>
          <div className="text-right">
            <p className="text-sm text-red-700 mb-1">تنبيه الإلغاء</p>
            <p className="text-xs text-red-500 leading-relaxed">
              عند إلغاء الحجز بعد انتهاء المدة المتاحة للإلغاء يُخصم نقطتان من رصيدك.
            </p>
          </div>
        </div>

        {
    /* الأسئلة الشائعة */
  }
        <div className="bg-white rounded-3xl p-5 shadow-sm">
          <div className="flex items-center gap-2 mb-4">
            <div className="w-8 h-8 bg-blue-100 rounded-xl flex items-center justify-center">
              <Shield className="w-4 h-4 text-blue-600" />
            </div>
            <h2 className="text-secondary">الأسئلة الشائعة</h2>
          </div>
          <div className="space-y-2">
            {faqs.map((f, i) => <div key={i} className="border border-border rounded-2xl overflow-hidden">
                <button
    onClick={() => setOpenFaq(openFaq === i ? null : i)}
    className="w-full flex items-center justify-between p-4 text-right hover:bg-gray-50 transition-colors"
  >
                  <div className={`w-5 h-5 rounded-full flex items-center justify-center flex-shrink-0 transition-colors ${openFaq === i ? "bg-primary text-white" : "bg-gray-100 text-muted-foreground"}`}>
                    {openFaq === i ? <ChevronUp className="w-3 h-3" /> : <ChevronDown className="w-3 h-3" />}
                  </div>
                  <span className="text-sm text-secondary flex-1 mr-3">{f.q}</span>
                </button>
                {openFaq === i && <div className="px-4 pb-4 text-right">
                    <p className="text-xs text-muted-foreground leading-relaxed">{f.a}</p>
                  </div>}
              </div>)}
          </div>
        </div>

      </div>
    </div>;
}
export {
  PointsSystemPage as default
};
