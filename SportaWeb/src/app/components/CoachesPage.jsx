import { useState } from "react";
import { Search, Star, MapPin, Users, Award, TrendingUp, ChevronRight, CheckCircle, X, Calendar, Clock } from "lucide-react";
const trainingDomains = [
  { id: "attack", label: "\u0627\u0644\u0645\u0647\u0627\u0631\u0627\u062A \u0627\u0644\u0647\u062C\u0648\u0645\u064A\u0629", sublabel: "Attack", icon: "\u2694\uFE0F", desc: "\u0627\u0644\u0636\u0631\u0628\u0627\u062A \u0627\u0644\u0633\u0627\u062D\u0642\u0629 \u2022 \u0627\u0644\u0641\u0648\u0644\u064A \u2022 Bandeja \u2022 Vibora" },
  { id: "defense", label: "\u0627\u0644\u0645\u0647\u0627\u0631\u0627\u062A \u0627\u0644\u062F\u0641\u0627\u0639\u064A\u0629", sublabel: "Defense", icon: "\u{1F6E1}\uFE0F", desc: "\u0627\u0631\u062A\u062F\u0627\u062F \u0627\u0644\u0632\u062C\u0627\u062C \u2022 \u0627\u0644\u0643\u0631\u0627\u062A \u0627\u0644\u0645\u0646\u062E\u0641\u0636\u0629 \u2022 \u0627\u0644\u0635\u0628\u0631" },
  { id: "control", label: "\u0627\u0644\u062A\u062D\u0643\u0645 \u0648\u0627\u0644\u062F\u0642\u0629", sublabel: "Control", icon: "\u{1F3AF}", desc: "\u0627\u0644\u0627\u062A\u062C\u0627\u0647 \u2022 \u0627\u0644\u0633\u0631\u0639\u0629 \u2022 \u0627\u0644\u0632\u0648\u0627\u064A\u0627 \u2022 \u062A\u0642\u0644\u064A\u0644 \u0627\u0644\u0623\u062E\u0637\u0627\u0621" },
  { id: "movement", label: "\u0627\u0644\u062D\u0631\u0643\u0629 \u0648\u0627\u0644\u0644\u064A\u0627\u0642\u0629", sublabel: "Movement", icon: "\u{1F3C3}", desc: "\u0633\u0631\u0639\u0629 \u0627\u0644\u062D\u0631\u0643\u0629 \u2022 \u0627\u0644\u062A\u063A\u0637\u064A\u0629 \u2022 \u0627\u0644\u062A\u0648\u0627\u0632\u0646 \u2022 \u0627\u0644\u0644\u064A\u0627\u0642\u0629" },
  { id: "gameiq", label: "\u0627\u0644\u062A\u0643\u062A\u064A\u0643 \u0648\u0642\u0631\u0627\u0621\u0629 \u0627\u0644\u0644\u0639\u0628", sublabel: "Game IQ", icon: "\u{1F9E0}", desc: "\u0642\u0631\u0627\u0621\u0629 \u0627\u0644\u062E\u0635\u0645 \u2022 \u0628\u0646\u0627\u0621 \u0627\u0644\u0646\u0642\u0637\u0629 \u2022 \u0627\u062A\u062E\u0627\u0630 \u0627\u0644\u0642\u0631\u0627\u0631" },
  { id: "teamplay", label: "\u0627\u0644\u0644\u0639\u0628 \u0627\u0644\u0632\u0648\u062C\u064A", sublabel: "Team Play", icon: "\u{1F91D}", desc: "\u0627\u0644\u062A\u0648\u0627\u0635\u0644 \u2022 \u0627\u0644\u062A\u063A\u0637\u064A\u0629 \u0627\u0644\u0645\u0634\u062A\u0631\u0643\u0629 \u2022 \u062F\u0639\u0645 \u0627\u0644\u0634\u0631\u064A\u0643" },
  { id: "serve", label: "\u0627\u0644\u0625\u0631\u0633\u0627\u0644 \u0648\u0627\u0644\u0627\u0633\u062A\u0642\u0628\u0627\u0644", sublabel: "Serve & Return", icon: "\u{1F3BE}", desc: "\u062C\u0648\u062F\u0629 \u0627\u0644\u0625\u0631\u0633\u0627\u0644 \u2022 \u062F\u0642\u0629 \u0627\u0644\u0625\u0631\u0633\u0627\u0644 \u2022 \u0627\u0633\u062A\u0642\u0628\u0627\u0644 \u0627\u0644\u0625\u0631\u0633\u0627\u0644" }
];
const availableDates = [
  { id: "d1", day: "\u0627\u0644\u0633\u0628\u062A", num: "6", month: "\u064A\u0648\u0646\u064A\u0648" },
  { id: "d2", day: "\u0627\u0644\u0623\u062D\u062F", num: "7", month: "\u064A\u0648\u0646\u064A\u0648" },
  { id: "d3", day: "\u0627\u0644\u0627\u062B\u0646\u064A\u0646", num: "8", month: "\u064A\u0648\u0646\u064A\u0648" },
  { id: "d4", day: "\u0627\u0644\u062B\u0644\u0627\u062B\u0627\u0621", num: "9", month: "\u064A\u0648\u0646\u064A\u0648" },
  { id: "d5", day: "\u0627\u0644\u0623\u0631\u0628\u0639\u0627\u0621", num: "10", month: "\u064A\u0648\u0646\u064A\u0648" }
];
const availableTimes = [
  { id: "t1", time: "08:00", period: "\u0635\u0628\u0627\u062D\u0627\u064B" },
  { id: "t2", time: "10:00", period: "\u0635\u0628\u0627\u062D\u0627\u064B" },
  { id: "t3", time: "12:00", period: "\u0638\u0647\u0631\u0627\u064B" },
  { id: "t4", time: "04:00", period: "\u0645\u0633\u0627\u0621\u064B" },
  { id: "t5", time: "06:00", period: "\u0645\u0633\u0627\u0621\u064B" },
  { id: "t6", time: "08:00", period: "\u0645\u0633\u0627\u0621\u064B" }
];
const locations = [
  { id: "l1", name: "\u0645\u0631\u0643\u0632 \u0628\u0627\u062F\u0644 \u0627\u0644\u0645\u062F\u064A\u0646\u0629", distance: "5.4 \u0643\u0645", courts: 4 },
  { id: "l2", name: "\u0646\u0627\u062F\u064A \u0627\u0644\u0628\u0627\u062F\u0644 \u0627\u0644\u0645\u0644\u0643\u064A", distance: "1.8 \u0643\u0645", courts: 6 },
  { id: "l3", name: "\u0628\u0627\u062F\u0644 \u0643\u0644\u0648\u0628 \u0627\u0644\u0634\u0631\u0642\u064A\u0629", distance: "3.2 \u0643\u0645", courts: 3 }
];
function CoachesPage({ onBack, onNavigate, onGoToPayment }) {
  const [bookedCoaches, setBookedCoaches] = useState(/* @__PURE__ */ new Set(["coach-1"]));
  const [showSheet, setShowSheet] = useState(false);
  const [bookingStep, setBookingStep] = useState(1);
  const [selectedDomains, setSelectedDomains] = useState(/* @__PURE__ */ new Set());
  const [selectedDate, setSelectedDate] = useState("");
  const [selectedTime, setSelectedTime] = useState("");
  const [selectedLocation, setSelectedLocation] = useState("");
  const resetSheet = () => {
    setBookingStep(1);
    setSelectedDomains(/* @__PURE__ */ new Set());
    setSelectedDate("");
    setSelectedTime("");
    setSelectedLocation("");
    setShowSheet(false);
  };
  const handleCoachBook = (coachId) => {
    if (bookedCoaches.has(coachId)) {
      onNavigate && onNavigate("training-session", coachId);
    } else if (coachId === "coach-3") {
      setShowSheet(true);
    } else {
      setBookedCoaches((prev) => /* @__PURE__ */ new Set([...prev, coachId]));
    }
  };
  const toggleDomain = (id) => {
    setSelectedDomains((prev) => {
      const next = new Set(prev);
      next.has(id) ? next.delete(id) : next.add(id);
      return next;
    });
  };
  const confirmBooking = () => {
    const dateObj = availableDates.find((d) => d.id === selectedDate);
    const timeObj = availableTimes.find((t) => t.id === selectedTime);
    const locObj = locations.find((l) => l.id === selectedLocation);
    const details = {
      courtName: locObj?.name ?? "\u0645\u0631\u0643\u0632 \u0628\u0627\u062F\u0644 \u0627\u0644\u0645\u062F\u064A\u0646\u0629",
      date: dateObj ? `${dateObj.day} ${dateObj.num} ${dateObj.month}` : "",
      time: timeObj ? `${timeObj.time} ${timeObj.period}` : "",
      duration: "60 \u062F\u0642\u064A\u0642\u0629",
      totalPrice: 280
    };
    resetSheet();
    setBookedCoaches((prev) => /* @__PURE__ */ new Set([...prev, "coach-3"]));
    onGoToPayment && onGoToPayment(details);
  };
  const stepTitles = {
    1: "\u0627\u062E\u062A\u0631 \u0645\u062C\u0627\u0644 \u0627\u0644\u062A\u062F\u0631\u064A\u0628",
    2: "\u0627\u062E\u062A\u0631 \u0627\u0644\u062A\u0627\u0631\u064A\u062E \u0648\u0627\u0644\u0648\u0642\u062A",
    3: "\u0627\u062E\u062A\u0631 \u0627\u0644\u0645\u0643\u0627\u0646",
    4: "\u0645\u0644\u062E\u0635 \u0627\u0644\u062D\u062C\u0632"
  };
  const canProceed = {
    1: selectedDomains.size > 0,
    2: !!selectedDate && !!selectedTime,
    3: !!selectedLocation,
    4: true
  };
  return <div className="flex-1 overflow-y-auto bg-background">
      <div className="bg-gradient-to-br from-secondary to-secondary/90 text-white px-6 pt-8 pb-6">
        <div className="flex items-center gap-3 mb-4">
          <h1 className="text-2xl">طور مستواك</h1>
        </div>

        <div className="relative mb-4">
          <Search className="absolute right-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
          <input
    type="text"
    placeholder="ابحث عن مدرب..."
    className="w-full bg-white/95 backdrop-blur-sm text-gray-800 placeholder-gray-400 rounded-xl py-3 pr-11 pl-4 outline-none"
  />
        </div>

        <div className="flex gap-2 overflow-x-auto pb-2">
          <button className="px-4 py-2 bg-white/20 backdrop-blur-sm text-white rounded-full text-sm whitespace-nowrap flex-shrink-0">
            الكل
          </button>
          <button className="px-4 py-2 bg-white/10 backdrop-blur-sm text-white rounded-full text-sm whitespace-nowrap flex-shrink-0">
            مبتدئ
          </button>
          <button className="px-4 py-2 bg-white/10 backdrop-blur-sm text-white rounded-full text-sm whitespace-nowrap flex-shrink-0">
            متوسط
          </button>
          <button className="px-4 py-2 bg-white/10 backdrop-blur-sm text-white rounded-full text-sm whitespace-nowrap flex-shrink-0">
            متقدم
          </button>
        </div>
      </div>

      <div className="px-6 py-4 space-y-4">
        <div className="bg-gradient-to-br from-primary/10 to-primary/5 border border-primary/20 rounded-2xl p-5">
          <div className="flex items-start gap-4">
            <div className="w-12 h-12 bg-primary rounded-full flex items-center justify-center flex-shrink-0">
              <Award className="w-6 h-6 text-white" />
            </div>
            <div className="flex-1">
              <h3 className="text-secondary mb-2">تقييم مستواي عند مدرب معتمد</h3>
              <p className="text-sm text-muted-foreground mb-3">احصل على جلسة تقييم شاملة مع مدرب معتمد</p>
              <div className="flex items-center justify-between">
                <span className="text-lg text-secondary">250 ر.س</span>
                <button
    onClick={() => onNavigate && onNavigate("assessment-booking")}
    className="px-4 py-2 bg-primary text-white text-sm rounded-lg hover:bg-primary/90 transition-colors"
  >
                  احجز التقييم
                </button>
              </div>
            </div>
          </div>
        </div>

        <div className="bg-gradient-to-br from-primary/5 to-primary/10 border border-primary/30 rounded-2xl p-4">
          <div className="flex gap-4 mb-4">
            <div className="w-20 h-20 bg-gradient-to-br from-primary to-primary/80 rounded-full flex items-center justify-center flex-shrink-0">
              <span className="text-white text-2xl">م.أ</span>
            </div>
            <div className="flex-1">
              <div className="flex items-start justify-between mb-2">
                <div>
                  <h3 className="text-secondary mb-1">محمد أحمد</h3>
                  <div className="flex items-center gap-1 mb-2">
                    <Star className="w-4 h-4 text-yellow-400 fill-yellow-400" />
                    <span className="text-sm text-secondary">4.9</span>
                    <span className="text-xs text-muted-foreground">(87 تقييم)</span>
                  </div>
                </div>
                <span className="px-2 py-1 bg-primary text-white text-xs rounded-full flex items-center gap-1">
                  <Award className="w-3 h-3" />
                  معتمد
                </span>
              </div>
              <div className="flex items-center gap-2 text-xs text-muted-foreground mb-2">
                <Users className="w-3 h-3" />
                <span>152 طالب</span>
                <span>•</span>
                <span>مستوى: 0 - 7</span>
              </div>
            </div>
          </div>

          <div className="flex items-center gap-2 mb-3 text-xs text-muted-foreground">
            <MapPin className="w-3 h-3" />
            <span>نادي البادل الملكي • 1.8 كم</span>
          </div>

          <div className="bg-white/50 backdrop-blur-sm rounded-lg p-3 mb-3">
            <p className="text-xs text-secondary mb-2">التخصص:</p>
            <div className="flex gap-2 flex-wrap">
              <span className="px-2 py-1 bg-primary/20 text-primary text-xs rounded">تقنيات متقدمة</span>
              <span className="px-2 py-1 bg-primary/20 text-primary text-xs rounded">استراتيجية اللعب</span>
              <span className="px-2 py-1 bg-primary/20 text-primary text-xs rounded">التحليل الفني</span>
            </div>
          </div>

          <div className="flex items-center justify-between pt-3 border-t border-primary/20">
            <div>
              <p className="text-xs text-muted-foreground mb-1">سعر الجلسة</p>
              <p className="text-lg text-secondary">200 ر.س</p>
            </div>
            <button
    onClick={() => handleCoachBook("coach-1")}
    className={`px-5 py-2 rounded-lg shadow-md flex items-center gap-1 transition-all ${bookedCoaches.has("coach-1") ? "bg-green-500 text-white" : "bg-primary text-white"}`}
  >
              {bookedCoaches.has("coach-1") && <CheckCircle className="w-4 h-4" />}
              {bookedCoaches.has("coach-1") ? "\u062D\u062C\u0632 \u0645\u0643\u062A\u0645\u0644" : "\u0627\u062D\u062C\u0632 \u0627\u0644\u0622\u0646"}
            </button>
          </div>
        </div>

        <div className="bg-white border border-border rounded-2xl p-4 shadow-sm">
          <div className="flex gap-4 mb-4">
            <div className="w-20 h-20 bg-gradient-to-br from-secondary to-secondary/80 rounded-full flex items-center justify-center flex-shrink-0">
              <span className="text-white text-2xl">س.ع</span>
            </div>
            <div className="flex-1">
              <div className="flex items-start justify-between mb-2">
                <div>
                  <h3 className="text-secondary mb-1">سارة عبدالله</h3>
                  <div className="flex items-center gap-1 mb-2">
                    <Star className="w-4 h-4 text-yellow-400 fill-yellow-400" />
                    <span className="text-sm text-secondary">4.7</span>
                    <span className="text-xs text-muted-foreground">(64 تقييم)</span>
                  </div>
                </div>
                <span className="px-2 py-1 bg-pink-100 text-pink-600 text-xs rounded-full">نساء</span>
              </div>
              <div className="flex items-center gap-2 text-xs text-muted-foreground mb-2">
                <Users className="w-3 h-3" />
                <span>98 طالبة</span>
                <span>•</span>
                <span>مستوى: 0 - 5</span>
              </div>
            </div>
          </div>

          <div className="flex items-center gap-2 mb-3 text-xs text-muted-foreground">
            <MapPin className="w-3 h-3" />
            <span>بادل كلوب الشرقية • 3.2 كم</span>
          </div>

          <div className="bg-gray-50 rounded-lg p-3 mb-3">
            <p className="text-xs text-secondary mb-2">التخصص:</p>
            <div className="flex gap-2 flex-wrap">
              <span className="px-2 py-1 bg-gray-200 text-secondary text-xs rounded">تدريب مبتدئين</span>
              <span className="px-2 py-1 bg-gray-200 text-secondary text-xs rounded">الأساسيات</span>
              <span className="px-2 py-1 bg-gray-200 text-secondary text-xs rounded">اللياقة البدنية</span>
            </div>
          </div>

          <div className="flex items-center justify-between pt-3 border-t border-border">
            <div>
              <p className="text-xs text-muted-foreground mb-1">سعر الجلسة</p>
              <p className="text-lg text-secondary">150 ر.س</p>
            </div>
            <button
    onClick={() => handleCoachBook("coach-2")}
    className={`px-5 py-2 rounded-lg flex items-center gap-1 transition-all ${bookedCoaches.has("coach-2") ? "bg-green-500 text-white" : "bg-primary text-white"}`}
  >
              {bookedCoaches.has("coach-2") && <CheckCircle className="w-4 h-4" />}
              {bookedCoaches.has("coach-2") ? "\u062D\u062C\u0632 \u0645\u0643\u062A\u0645\u0644" : "\u0627\u062D\u062C\u0632 \u0627\u0644\u0622\u0646"}
            </button>
          </div>
        </div>

        <div className="bg-white border border-border rounded-2xl p-4 shadow-sm">
          <div className="flex gap-4 mb-4">
            <div className="w-20 h-20 bg-gradient-to-br from-green-500 to-green-600 rounded-full flex items-center justify-center flex-shrink-0">
              <span className="text-white text-2xl">خ.م</span>
            </div>
            <div className="flex-1">
              <div className="flex items-start justify-between mb-2">
                <div>
                  <h3 className="text-secondary mb-1">خالد محمود</h3>
                  <div className="flex items-center gap-1 mb-2">
                    <Star className="w-4 h-4 text-yellow-400 fill-yellow-400" />
                    <span className="text-sm text-secondary">4.8</span>
                    <span className="text-xs text-muted-foreground">(112 تقييم)</span>
                  </div>
                </div>
                <span className="px-2 py-1 bg-green-100 text-green-700 text-xs rounded-full flex items-center gap-1">
                  <TrendingUp className="w-3 h-3" />
                  محترف
                </span>
              </div>
              <div className="flex items-center gap-2 text-xs text-muted-foreground mb-2">
                <Users className="w-3 h-3" />
                <span>203 طالب</span>
                <span>•</span>
                <span>مستوى: 3 - 7</span>
              </div>
            </div>
          </div>

          <div className="flex items-center gap-2 mb-3 text-xs text-muted-foreground">
            <MapPin className="w-3 h-3" />
            <span>مركز بادل المدينة • 5.4 كم</span>
          </div>

          <div className="bg-green-50 rounded-lg p-3 mb-3">
            <p className="text-xs text-secondary mb-2">التخصص:</p>
            <div className="flex gap-2 flex-wrap">
              <span className="px-2 py-1 bg-green-100 text-green-700 text-xs rounded">إعداد احترافي</span>
              <span className="px-2 py-1 bg-green-100 text-green-700 text-xs rounded">المنافسات</span>
              <span className="px-2 py-1 bg-green-100 text-green-700 text-xs rounded">التكتيك المتقدم</span>
            </div>
          </div>

          <div className="flex items-center justify-between pt-3 border-t border-border">
            <div>
              <p className="text-xs text-muted-foreground mb-1">سعر الجلسة</p>
              <p className="text-lg text-secondary">280 ر.س</p>
            </div>
            <button
    onClick={() => handleCoachBook("coach-3")}
    className={`px-5 py-2 rounded-lg flex items-center gap-1 transition-all ${bookedCoaches.has("coach-3") ? "bg-green-500 text-white" : "bg-primary text-white"}`}
  >
              {bookedCoaches.has("coach-3") && <CheckCircle className="w-4 h-4" />}
              {bookedCoaches.has("coach-3") ? "\u062D\u062C\u0632 \u0645\u0643\u062A\u0645\u0644" : "\u0627\u062D\u062C\u0632 \u0627\u0644\u0622\u0646"}
            </button>
          </div>
        </div>
      </div>

      {
    /* شيت الحجز - خالد محمود */
  }
      {showSheet && <div className="fixed inset-0 z-50 flex items-end justify-center" style={{ maxWidth: "430px", margin: "0 auto", left: 0, right: 0 }}>
          <div className="absolute inset-0 bg-black/50 backdrop-blur-sm" onClick={resetSheet} />
          <div className="relative bg-white rounded-t-3xl w-full max-h-[90vh] flex flex-col shadow-2xl">

            {
    /* رأس ثابت */
  }
            <div className="px-6 pt-5 pb-4 border-b border-border flex-shrink-0">
              <div className="flex items-center justify-between mb-3">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-gradient-to-br from-green-500 to-green-600 rounded-full flex items-center justify-center flex-shrink-0">
                    <span className="text-white text-sm">خ.م</span>
                  </div>
                  <div>
                    <h3 className="text-secondary text-sm">خالد محمود — حجز جلسة</h3>
                    <p className="text-xs text-muted-foreground">{stepTitles[bookingStep]}</p>
                  </div>
                </div>
                <button onClick={resetSheet} className="p-2 rounded-full bg-gray-100 hover:bg-gray-200 transition-colors">
                  <X className="w-4 h-4 text-secondary" />
                </button>
              </div>
              {
    /* مؤشر الخطوات */
  }
              <div className="flex gap-1.5">
                {[1, 2, 3, 4].map((s) => <div key={s} className={`h-1.5 flex-1 rounded-full transition-all ${bookingStep >= s ? "bg-primary" : "bg-gray-200"}`} />)}
              </div>
              <p className="text-xs text-muted-foreground mt-1.5">الخطوة {bookingStep} من 4</p>
            </div>

            {
    /* المحتوى القابل للتمرير */
  }
            <div className="flex-1 overflow-y-auto px-5 py-4">

              {
    /* خطوة 1: المجالات */
  }
              {bookingStep === 1 && <div className="space-y-3">
                  <p className="text-xs text-muted-foreground mb-2">اختر مجالاً أو أكثر للتدرب عليه</p>
                  {trainingDomains.map((domain) => {
    const sel = selectedDomains.has(domain.id);
    return <button
      key={domain.id}
      onClick={() => toggleDomain(domain.id)}
      className={`w-full flex items-center gap-3 p-4 rounded-2xl border-2 transition-all text-right ${sel ? "bg-primary/10 border-primary shadow-sm" : "bg-white border-border hover:border-primary/40"}`}
    >
                        <span className="text-2xl flex-shrink-0">{domain.icon}</span>
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-2 mb-0.5 flex-wrap">
                            <span className="text-secondary text-sm">{domain.label}</span>
                            <span className="text-xs text-primary bg-primary/10 px-2 py-0.5 rounded-full">{domain.sublabel}</span>
                          </div>
                          <p className="text-xs text-muted-foreground">{domain.desc}</p>
                        </div>
                        <div className={`w-5 h-5 rounded-full border-2 flex-shrink-0 flex items-center justify-center transition-all ${sel ? "bg-primary border-primary" : "border-border"}`}>
                          {sel && <CheckCircle className="w-4 h-4 text-white" />}
                        </div>
                      </button>;
  })}
                </div>}

              {
    /* خطوة 2: التاريخ والوقت */
  }
              {bookingStep === 2 && <div className="space-y-5">
                  <div>
                    <p className="text-secondary text-sm mb-3 flex items-center gap-2">
                      <Calendar className="w-4 h-4 text-primary" />اختر اليوم والتاريخ
                    </p>
                    <div className="flex gap-2 overflow-x-auto pb-1">
                      {availableDates.map((d) => <button
    key={d.id}
    onClick={() => setSelectedDate(d.id)}
    className={`flex-shrink-0 w-[72px] py-3 rounded-xl border-2 text-center transition-all ${selectedDate === d.id ? "bg-primary border-primary text-white shadow-md" : "bg-white border-border text-secondary hover:border-primary/50"}`}
  >
                          <p className="text-xs mb-0.5 opacity-80">{d.day}</p>
                          <p className="text-xl">{d.num}</p>
                          <p className="text-xs opacity-80">{d.month}</p>
                        </button>)}
                    </div>
                  </div>
                  <div>
                    <p className="text-secondary text-sm mb-3 flex items-center gap-2">
                      <Clock className="w-4 h-4 text-primary" />اختر الوقت
                    </p>
                    <div className="grid grid-cols-3 gap-2">
                      {availableTimes.map((t) => <button
    key={t.id}
    onClick={() => setSelectedTime(t.id)}
    className={`py-3 rounded-xl border-2 text-center transition-all ${selectedTime === t.id ? "bg-primary border-primary text-white shadow-md" : "bg-white border-border text-secondary hover:border-primary/50"}`}
  >
                          <p className="text-sm">{t.time}</p>
                          <p className="text-xs opacity-80">{t.period}</p>
                        </button>)}
                    </div>
                  </div>
                </div>}

              {
    /* خطوة 3: المكان */
  }
              {bookingStep === 3 && <div className="space-y-3">
                  <p className="text-xs text-muted-foreground mb-2">اختر الملعب المناسب لك</p>
                  {locations.map((loc) => {
    const sel = selectedLocation === loc.id;
    return <button
      key={loc.id}
      onClick={() => setSelectedLocation(loc.id)}
      className={`w-full flex items-center gap-4 p-4 rounded-2xl border-2 transition-all text-right ${sel ? "bg-primary/10 border-primary shadow-sm" : "bg-white border-border hover:border-primary/40"}`}
    >
                        <div className={`w-11 h-11 rounded-xl flex items-center justify-center flex-shrink-0 ${sel ? "bg-primary" : "bg-gray-100"}`}>
                          <MapPin className={`w-5 h-5 ${sel ? "text-white" : "text-muted-foreground"}`} />
                        </div>
                        <div className="flex-1">
                          <p className="text-secondary text-sm mb-0.5">{loc.name}</p>
                          <div className="flex items-center gap-3 text-xs text-muted-foreground">
                            <span>📍 {loc.distance}</span>
                            <span>🎾 {loc.courts} ملاعب</span>
                          </div>
                        </div>
                        <div className={`w-5 h-5 rounded-full border-2 flex-shrink-0 flex items-center justify-center transition-all ${sel ? "bg-primary border-primary" : "border-border"}`}>
                          {sel && <CheckCircle className="w-4 h-4 text-white" />}
                        </div>
                      </button>;
  })}
                </div>}

              {
    /* خطوة 4: الملخص */
  }
              {bookingStep === 4 && <div className="space-y-4">
                  <div className="bg-gradient-to-br from-green-50 to-green-100/50 border border-green-200 rounded-2xl p-5">
                    <h4 className="text-secondary mb-4 flex items-center gap-2">
                      <CheckCircle className="w-5 h-5 text-green-500" />ملخص الحجز
                    </h4>
                    <div className="space-y-3 text-sm">
                      <div className="flex items-start justify-between gap-2">
                        <span className="text-muted-foreground flex-shrink-0">المدرب:</span>
                        <span className="text-secondary text-left">خالد محمود</span>
                      </div>
                      <div className="flex items-start justify-between gap-2">
                        <span className="text-muted-foreground flex-shrink-0">مجالات التدريب:</span>
                        <div className="flex flex-wrap gap-1 justify-end">
                          {[...selectedDomains].map((id) => {
    const d = trainingDomains.find((x) => x.id === id);
    return d ? <span key={id} className="px-2 py-0.5 bg-primary/10 text-primary text-xs rounded-full">
                                {d.icon} {d.sublabel}
                              </span> : null;
  })}
                        </div>
                      </div>
                      <div className="flex items-center justify-between gap-2 pt-2 border-t border-green-200">
                        <span className="text-muted-foreground">اليوم والتاريخ:</span>
                        <span className="text-secondary">
                          {availableDates.find((d) => d.id === selectedDate)?.day} {availableDates.find((d) => d.id === selectedDate)?.num} {availableDates.find((d) => d.id === selectedDate)?.month}
                        </span>
                      </div>
                      <div className="flex items-center justify-between gap-2">
                        <span className="text-muted-foreground">الوقت:</span>
                        <span className="text-secondary">
                          {availableTimes.find((t) => t.id === selectedTime)?.time} {availableTimes.find((t) => t.id === selectedTime)?.period}
                        </span>
                      </div>
                      <div className="flex items-center justify-between gap-2">
                        <span className="text-muted-foreground">المكان:</span>
                        <span className="text-secondary">{locations.find((l) => l.id === selectedLocation)?.name}</span>
                      </div>
                      <div className="flex items-center justify-between gap-2 pt-3 border-t border-green-300">
                        <span className="text-secondary">السعر:</span>
                        <span className="text-2xl text-green-600">280 ر.س</span>
                      </div>
                    </div>
                  </div>
                </div>}
            </div>

            {
    /* أزرار التنقل الثابتة */
  }
            <div className="flex-shrink-0 border-t border-border px-5 py-4 flex gap-3">
              {bookingStep > 1 && <button
    onClick={() => setBookingStep((prev) => prev - 1)}
    className="flex-1 py-3.5 rounded-xl border-2 border-border text-secondary hover:border-primary/40 transition-all text-sm"
  >
                  رجوع
                </button>}
              <button
    onClick={() => bookingStep < 4 ? setBookingStep((prev) => prev + 1) : confirmBooking()}
    disabled={!canProceed[bookingStep]}
    className={`flex-[2] py-3.5 rounded-xl flex items-center justify-center gap-2 transition-all text-sm ${canProceed[bookingStep] ? "bg-primary text-white shadow-md hover:bg-primary/90" : "bg-gray-200 text-gray-400 cursor-not-allowed"}`}
  >
                {bookingStep === 4 ? <><CheckCircle className="w-4 h-4" />تأكيد الحجز والدفع</> : <>التالي<ChevronRight className="w-4 h-4 rotate-180" /></>}
              </button>
            </div>
          </div>
        </div>}
    </div>;
}
export {
  CoachesPage as default
};
