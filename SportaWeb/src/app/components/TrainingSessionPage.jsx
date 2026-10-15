import { useState } from "react";
import { ChevronRight, Award, Calendar, Clock, MapPin, User, CheckCircle, Star, TrendingUp, MessageSquare } from "lucide-react";
const defaultSession = {
  coachName: "\u0645\u062D\u0645\u062F \u0623\u062D\u0645\u062F",
  coachAvatar: "\u0645.\u0623",
  coachRating: 4.9,
  date: "\u0627\u0644\u062E\u0645\u064A\u0633 6 \u064A\u0648\u0646\u064A\u0648",
  time: "04:00 \u0645\u0633\u0627\u0621\u064B",
  location: "\u0646\u0627\u062F\u064A \u0627\u0644\u0628\u0627\u062F\u0644 \u0627\u0644\u0645\u0644\u0643\u064A",
  duration: "60 \u062F\u0642\u064A\u0642\u0629",
  price: 250
};
const skillItems = [
  {
    id: "attack",
    label: "\u0627\u0644\u0645\u0647\u0627\u0631\u0627\u062A \u0627\u0644\u0647\u062C\u0648\u0645\u064A\u0629",
    sublabel: "Attack",
    description: "\u0627\u0644\u0636\u0631\u0628\u0627\u062A \u0627\u0644\u0633\u0627\u062D\u0642\u0629 \u2022 \u0627\u0644\u0641\u0648\u0644\u064A \u2022 Bandeja \u2022 Vibora \u2022 \u0625\u0646\u0647\u0627\u0621 \u0627\u0644\u0646\u0642\u0627\u0637",
    icon: "\u2694\uFE0F"
  },
  {
    id: "defense",
    label: "\u0627\u0644\u0645\u0647\u0627\u0631\u0627\u062A \u0627\u0644\u062F\u0641\u0627\u0639\u064A\u0629",
    sublabel: "Defense",
    description: "\u0627\u0644\u0644\u0639\u0628 \u0628\u0639\u062F \u0627\u0631\u062A\u062F\u0627\u062F \u0627\u0644\u0632\u062C\u0627\u062C \u2022 \u0627\u0644\u0643\u0631\u0627\u062A \u0627\u0644\u0645\u0646\u062E\u0641\u0636\u0629 \u2022 \u0627\u0644\u0635\u0628\u0631 \u0623\u062B\u0646\u0627\u0621 \u0627\u0644\u062A\u0628\u0627\u062F\u0644",
    icon: "\u{1F6E1}\uFE0F"
  },
  {
    id: "control",
    label: "\u0627\u0644\u062A\u062D\u0643\u0645 \u0648\u0627\u0644\u062F\u0642\u0629",
    sublabel: "Control",
    description: "\u0627\u0644\u062A\u062D\u0643\u0645 \u0628\u0627\u0644\u0627\u062A\u062C\u0627\u0647 \u0648\u0627\u0644\u0633\u0631\u0639\u0629 \u2022 \u0627\u0644\u0644\u0639\u0628 \u0639\u0644\u0649 \u0627\u0644\u0632\u0648\u0627\u064A\u0627 \u2022 \u062A\u0642\u0644\u064A\u0644 \u0627\u0644\u0623\u062E\u0637\u0627\u0621",
    icon: "\u{1F3AF}"
  },
  {
    id: "movement",
    label: "\u0627\u0644\u062D\u0631\u0643\u0629 \u0648\u0627\u0644\u0644\u064A\u0627\u0642\u0629",
    sublabel: "Movement",
    description: "\u0633\u0631\u0639\u0629 \u0627\u0644\u062D\u0631\u0643\u0629 \u2022 \u0627\u0644\u062A\u063A\u0637\u064A\u0629 \u2022 \u0627\u0644\u062A\u0648\u0627\u0632\u0646 \u2022 \u0627\u0644\u0644\u064A\u0627\u0642\u0629 \u0627\u0644\u0628\u062F\u0646\u064A\u0629",
    icon: "\u{1F3C3}"
  },
  {
    id: "gameiq",
    label: "\u0627\u0644\u062A\u0643\u062A\u064A\u0643 \u0648\u0642\u0631\u0627\u0621\u0629 \u0627\u0644\u0644\u0639\u0628",
    sublabel: "Game IQ",
    description: "\u0627\u062E\u062A\u064A\u0627\u0631 \u0627\u0644\u0636\u0631\u0628\u0629 \u2022 \u0642\u0631\u0627\u0621\u0629 \u0627\u0644\u062E\u0635\u0645 \u2022 \u0628\u0646\u0627\u0621 \u0627\u0644\u0646\u0642\u0637\u0629 \u2022 \u0627\u062A\u062E\u0627\u0630 \u0627\u0644\u0642\u0631\u0627\u0631",
    icon: "\u{1F9E0}"
  },
  {
    id: "teamplay",
    label: "\u0627\u0644\u0644\u0639\u0628 \u0627\u0644\u0632\u0648\u062C\u064A",
    sublabel: "Team Play",
    description: "\u0627\u0644\u062A\u0648\u0627\u0635\u0644 \u0645\u0639 \u0627\u0644\u0634\u0631\u064A\u0643 \u2022 \u0627\u0644\u062A\u063A\u0637\u064A\u0629 \u0627\u0644\u0645\u0634\u062A\u0631\u0643\u0629 \u2022 \u0627\u0644\u062A\u062D\u0631\u0643 \u0627\u0644\u0645\u062A\u0632\u0627\u0645\u0646",
    icon: "\u{1F91D}"
  },
  {
    id: "serve",
    label: "\u0627\u0644\u0625\u0631\u0633\u0627\u0644 \u0648\u0627\u0644\u0627\u0633\u062A\u0642\u0628\u0627\u0644",
    sublabel: "Serve & Return",
    description: "\u062C\u0648\u062F\u0629 \u0627\u0644\u0625\u0631\u0633\u0627\u0644 \u2022 \u062F\u0642\u0629 \u0627\u0644\u0625\u0631\u0633\u0627\u0644 \u2022 \u0627\u0633\u062A\u0642\u0628\u0627\u0644 \u0627\u0644\u0625\u0631\u0633\u0627\u0644 \u2022 \u0628\u062F\u0621 \u0627\u0644\u0647\u062C\u0645\u0629",
    icon: "\u{1F3BE}"
  }
];
function TrainingSessionPage({ onBack, sessionData }) {
  const session = sessionData || defaultSession;
  const [ratings, setRatings] = useState({});
  const [notes, setNotes] = useState("");
  const [submitted, setSubmitted] = useState(false);
  const handleRating = (skillId, value) => {
    setRatings((prev) => ({ ...prev, [skillId]: value }));
  };
  const ratedCount = Object.keys(ratings).length;
  const allRated = ratedCount === skillItems.length;
  const averageRating = allRated ? Object.values(ratings).reduce((a, b) => a + b, 0) / skillItems.length : null;
  const handleSubmit = () => {
    if (allRated) {
      setSubmitted(true);
    }
  };
  if (submitted) {
    return <div className="flex-1 flex flex-col items-center justify-center bg-background px-6 text-center">
        <div className="w-24 h-24 bg-green-100 rounded-full flex items-center justify-center mb-6">
          <CheckCircle className="w-14 h-14 text-green-500" />
        </div>
        <h2 className="text-2xl text-secondary mb-2">تم تسجيل نتيجة التمرين</h2>
        <p className="text-muted-foreground mb-2">تم حفظ نتائج الجلسة التدريبية بنجاح</p>
        <div className="mt-4 px-6 py-3 bg-primary/10 border border-primary/30 rounded-2xl mb-6">
          <p className="text-sm text-muted-foreground mb-1">متوسط التقييم الكلي</p>
          <p className="text-3xl text-primary">{averageRating?.toFixed(1)} <span className="text-base text-muted-foreground">/ 7</span></p>
        </div>
        <button
      onClick={onBack}
      className="w-full py-4 bg-primary text-white rounded-xl"
    >
          العودة للمدربين
        </button>
      </div>;
  }
  return <div className="flex-1 overflow-y-auto bg-background">
      {
    /* Header */
  }
      <div className="bg-gradient-to-br from-secondary to-secondary/90 text-white px-6 pt-8 pb-6">
        <div className="flex items-center gap-3 mb-4">
          <button onClick={onBack} className="p-2 bg-white/20 rounded-full backdrop-blur-sm hover:bg-white/30 transition-colors">
            <ChevronRight className="w-5 h-5 text-white" />
          </button>
          <h1 className="text-2xl">تفاصيل التمرين</h1>
        </div>
        <div className="flex items-center gap-2">
          <span className="px-3 py-1 bg-green-400/30 text-green-200 text-sm rounded-full flex items-center gap-1">
            <CheckCircle className="w-3 h-3" />
            حجز مكتمل
          </span>
        </div>
      </div>

      <div className="px-6 py-6 space-y-6">
        {
    /* بطاقة المدرب */
  }
        <div className="bg-white border border-border rounded-2xl p-4 shadow-sm">
          <div className="flex items-center gap-4">
            <div className="w-16 h-16 bg-gradient-to-br from-primary to-primary/80 rounded-full flex items-center justify-center flex-shrink-0">
              <span className="text-white text-xl">{session.coachAvatar}</span>
            </div>
            <div className="flex-1">
              <div className="flex items-center gap-2 mb-1">
                <h3 className="text-secondary">{session.coachName}</h3>
                <span className="px-2 py-0.5 bg-primary/20 text-primary text-xs rounded-full flex items-center gap-1">
                  <Award className="w-3 h-3" />
                  معتمد
                </span>
              </div>
              <div className="flex items-center gap-1 text-sm text-yellow-500 mb-1">
                <Star className="w-4 h-4 fill-yellow-400" />
                <span className="text-secondary">{session.coachRating}</span>
              </div>
            </div>
          </div>
        </div>

        {
    /* تفاصيل الجلسة */
  }
        <div className="bg-gradient-to-br from-primary/5 to-primary/10 border border-primary/20 rounded-2xl p-5 space-y-3">
          <h3 className="text-secondary mb-3 flex items-center gap-2">
            <Calendar className="w-5 h-5 text-primary" />
            تفاصيل الجلسة
          </h3>
          <div className="flex items-center gap-3 text-sm">
            <Calendar className="w-4 h-4 text-primary" />
            <span className="text-muted-foreground">التاريخ:</span>
            <span className="text-secondary">{session.date}</span>
          </div>
          <div className="flex items-center gap-3 text-sm">
            <Clock className="w-4 h-4 text-primary" />
            <span className="text-muted-foreground">الوقت:</span>
            <span className="text-secondary">{session.time}</span>
          </div>
          <div className="flex items-center gap-3 text-sm">
            <MapPin className="w-4 h-4 text-primary" />
            <span className="text-muted-foreground">الملعب:</span>
            <span className="text-secondary">{session.location}</span>
          </div>
          <div className="flex items-center gap-3 text-sm">
            <Clock className="w-4 h-4 text-primary" />
            <span className="text-muted-foreground">المدة:</span>
            <span className="text-secondary">{session.duration}</span>
          </div>
          <div className="flex items-center gap-3 text-sm pt-2 border-t border-primary/20">
            <User className="w-4 h-4 text-primary" />
            <span className="text-muted-foreground">المبلغ المدفوع:</span>
            <span className="text-primary">{session.price} ر.س</span>
          </div>
        </div>

        {
    /* إدخال نتيجة التمرين */
  }
        <div>
          <h3 className="text-secondary mb-4 flex items-center gap-2">
            <TrendingUp className="w-5 h-5 text-primary" />
            إدخال نتيجة التمرين
          </h3>

          {
    /* تقييم المهارات */
  }
          <div className="space-y-4 mb-5">
            {skillItems.map((skill) => <div key={skill.id} className="bg-white border border-border rounded-xl p-4 shadow-sm">
                <div className="flex items-start justify-between mb-1">
                  <div className="flex items-center gap-2">
                    <span className="text-xl">{skill.icon}</span>
                    <div>
                      <p className="text-secondary text-sm">{skill.label}</p>
                      <p className="text-xs text-primary">{skill.sublabel}</p>
                    </div>
                  </div>
                  <span className={`text-sm px-2 py-0.5 rounded-full ${ratings[skill.id] ? "bg-primary/10 text-primary" : "bg-gray-100 text-muted-foreground"}`}>
                    {ratings[skill.id] ? `${ratings[skill.id]}/7` : "\u2014"}
                  </span>
                </div>
                <p className="text-xs text-muted-foreground mb-3 pr-8">{skill.description}</p>
                <div className="flex gap-1.5">
                  {[1, 2, 3, 4, 5, 6, 7].map((val) => <button
    key={val}
    onClick={() => handleRating(skill.id, val)}
    className={`flex-1 py-2 rounded-lg border-2 transition-all text-xs font-medium ${ratings[skill.id] === val ? "bg-primary border-primary text-white shadow-md scale-105" : ratings[skill.id] && ratings[skill.id] > val ? "bg-primary/20 border-primary/40 text-primary" : "bg-white border-border text-muted-foreground hover:border-primary/50"}`}
  >
                      {val}
                    </button>)}
                </div>
              </div>)}
          </div>

          {
    /* المعدل الكلي */
  }
          {ratedCount > 0 && <div className="bg-gradient-to-br from-primary/10 to-primary/5 border border-primary/20 rounded-xl p-4 mb-5">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-xs text-muted-foreground mb-1">متوسط التقييم الكلي</p>
                  <p className="text-2xl text-primary">
                    {(Object.values(ratings).reduce((a, b) => a + b, 0) / ratedCount).toFixed(1)}
                    <span className="text-sm text-muted-foreground"> / 7</span>
                  </p>
                </div>
                <div className="text-left">
                  <p className="text-xs text-muted-foreground mb-1">المهارات المقيّمة</p>
                  <p className="text-secondary">{ratedCount} / {skillItems.length}</p>
                </div>
              </div>
              {allRated && <div className="mt-2 h-2 bg-primary/20 rounded-full overflow-hidden">
                  <div
    className="h-full bg-primary rounded-full transition-all"
    style={{ width: `${Object.values(ratings).reduce((a, b) => a + b, 0) / skillItems.length / 7 * 100}%` }}
  />
                </div>}
            </div>}

          {
    /* ملاحظات */
  }
          <div className="bg-white border border-border rounded-xl p-4 mb-6">
            <h4 className="text-secondary mb-2 flex items-center gap-2">
              <MessageSquare className="w-4 h-4 text-primary" />
              ملاحظات التمرين
            </h4>
            <textarea
    value={notes}
    onChange={(e) => setNotes(e.target.value)}
    placeholder="أضف ملاحظاتك حول الجلسة التدريبية..."
    rows={3}
    className="w-full border border-border rounded-lg p-3 text-sm text-secondary placeholder-muted-foreground outline-none focus:border-primary resize-none"
  />
          </div>
        </div>
      </div>

      {
    /* زر الحفظ */
  }
      <div className="px-6 pb-6">
        <button
    onClick={handleSubmit}
    disabled={!allRated}
    className={`w-full py-4 rounded-xl shadow-lg flex items-center justify-center gap-2 transition-all ${allRated ? "bg-primary text-white hover:bg-primary/90" : "bg-gray-300 text-gray-500 cursor-not-allowed"}`}
  >
          <CheckCircle className="w-5 h-5" />
          <span>حفظ نتيجة التمرين</span>
        </button>
      </div>
    </div>;
}
export {
  TrainingSessionPage as default
};
