import { useState } from "react";
import { ChevronRight, Award, Calendar, Clock, MapPin, User, CheckCircle, Info } from "lucide-react";
const certifiedCoaches = [
  { id: "1", name: "\u0645\u062D\u0645\u062F \u0623\u062D\u0645\u062F", rating: 4.9, reviews: 87, avatar: "\u0645.\u0623", location: "\u0646\u0627\u062F\u064A \u0627\u0644\u0628\u0627\u062F\u0644 \u0627\u0644\u0645\u0644\u0643\u064A" },
  { id: "2", name: "\u062E\u0627\u0644\u062F \u0645\u062D\u0645\u0648\u062F", rating: 4.8, reviews: 112, avatar: "\u062E.\u0645", location: "\u0645\u0631\u0643\u0632 \u0628\u0627\u062F\u0644 \u0627\u0644\u0645\u062F\u064A\u0646\u0629" },
  { id: "3", name: "\u0623\u062D\u0645\u062F \u0627\u0644\u0633\u0627\u0644\u0645", rating: 4.9, reviews: 95, avatar: "\u0623.\u0633", location: "\u0646\u0627\u062F\u064A \u0627\u0644\u0631\u064A\u0627\u0636\u0629" }
];
const availableDates = [
  { id: "1", date: "2024-06-05", day: "\u0627\u0644\u0623\u0631\u0628\u0639\u0627\u0621", dayNum: "5" },
  { id: "2", date: "2024-06-06", day: "\u0627\u0644\u062E\u0645\u064A\u0633", dayNum: "6" },
  { id: "3", date: "2024-06-07", day: "\u0627\u0644\u062C\u0645\u0639\u0629", dayNum: "7" },
  { id: "4", date: "2024-06-08", day: "\u0627\u0644\u0633\u0628\u062A", dayNum: "8" },
  { id: "5", date: "2024-06-09", day: "\u0627\u0644\u0623\u062D\u062F", dayNum: "9" }
];
const availableTimes = [
  { id: "1", time: "09:00", period: "\u0635\u0628\u0627\u062D\u0627\u064B" },
  { id: "2", time: "11:00", period: "\u0635\u0628\u0627\u062D\u0627\u064B" },
  { id: "3", time: "02:00", period: "\u0645\u0633\u0627\u0621\u064B" },
  { id: "4", time: "04:00", period: "\u0645\u0633\u0627\u0621\u064B" },
  { id: "5", time: "06:00", period: "\u0645\u0633\u0627\u0621\u064B" },
  { id: "6", time: "08:00", period: "\u0645\u0633\u0627\u0621\u064B" }
];
function AssessmentBookingPage({ onBack, onComplete }) {
  const [selectedCoach, setSelectedCoach] = useState("");
  const [selectedDate, setSelectedDate] = useState("");
  const [selectedTime, setSelectedTime] = useState("");
  const handleBooking = () => {
    if (selectedCoach && selectedDate && selectedTime) {
      onComplete();
    }
  };
  const isFormComplete = selectedCoach && selectedDate && selectedTime;
  return <div className="flex-1 overflow-y-auto bg-background">
      {
    /* Header */
  }
      <div className="bg-gradient-to-br from-secondary to-secondary/90 text-white px-6 pt-8 pb-6">
        <div className="flex items-center gap-3 mb-4">
          <button onClick={onBack} className="p-2 bg-white/20 rounded-full backdrop-blur-sm hover:bg-white/30 transition-colors">
            <ChevronRight className="w-5 h-5 text-white" />
          </button>
          <h1 className="text-2xl">حجز جلسة التقييم</h1>
        </div>
        <p className="text-white/80 text-sm">احجز جلسة تقييم احترافية مع مدرب معتمد</p>
      </div>

      <div className="px-6 py-6 space-y-6">
        {
    /* معلومات التقييم */
  }
        <div className="bg-gradient-to-br from-primary/10 to-primary/5 border border-primary/20 rounded-2xl p-5">
          <div className="flex items-start gap-3 mb-4">
            <div className="w-10 h-10 bg-primary rounded-full flex items-center justify-center flex-shrink-0">
              <Info className="w-5 h-5 text-white" />
            </div>
            <div className="flex-1">
              <h3 className="text-secondary font-medium mb-2">ماذا يتضمن التقييم؟</h3>
              <ul className="space-y-2 text-sm text-muted-foreground">
                <li className="flex items-start gap-2">
                  <CheckCircle className="w-4 h-4 text-primary mt-0.5 flex-shrink-0" />
                  <span>جلسة تقييم شاملة مدتها 60 دقيقة</span>
                </li>
                <li className="flex items-start gap-2">
                  <CheckCircle className="w-4 h-4 text-primary mt-0.5 flex-shrink-0" />
                  <span>تحليل مهاراتك الفنية والتكتيكية</span>
                </li>
                <li className="flex items-start gap-2">
                  <CheckCircle className="w-4 h-4 text-primary mt-0.5 flex-shrink-0" />
                  <span>تحديد مستواك الرسمي (ELO Rating)</span>
                </li>
                <li className="flex items-start gap-2">
                  <CheckCircle className="w-4 h-4 text-primary mt-0.5 flex-shrink-0" />
                  <span>تقرير مفصل بنقاط القوة والضعف</span>
                </li>
                <li className="flex items-start gap-2">
                  <CheckCircle className="w-4 h-4 text-primary mt-0.5 flex-shrink-0" />
                  <span>خطة تدريبية مخصصة للتطوير</span>
                </li>
              </ul>
            </div>
          </div>
        </div>

        {
    /* اختيار المدرب */
  }
        <div>
          <h3 className="text-secondary font-medium mb-3 flex items-center gap-2">
            <User className="w-5 h-5 text-primary" />
            اختر المدرب المعتمد
          </h3>
          <div className="space-y-3">
            {certifiedCoaches.map((coach) => <div
    key={coach.id}
    onClick={() => setSelectedCoach(coach.id)}
    className={`p-4 rounded-2xl border-2 cursor-pointer transition-all ${selectedCoach === coach.id ? "bg-primary/10 border-primary shadow-md" : "bg-white border-border hover:border-primary/50"}`}
  >
                <div className="flex items-center gap-3">
                  <div className="w-14 h-14 bg-gradient-to-br from-primary to-primary/80 rounded-full flex items-center justify-center flex-shrink-0">
                    <span className="text-white text-lg">{coach.avatar}</span>
                  </div>
                  <div className="flex-1">
                    <div className="flex items-center justify-between mb-1">
                      <h4 className="text-secondary font-medium">{coach.name}</h4>
                      {selectedCoach === coach.id && <CheckCircle className="w-5 h-5 text-primary fill-primary" />}
                    </div>
                    <div className="flex items-center gap-2 text-xs text-muted-foreground mb-1">
                      <div className="flex items-center gap-1">
                        <span className="text-yellow-500">★</span>
                        <span>{coach.rating}</span>
                        <span>({coach.reviews})</span>
                      </div>
                      <span className="px-2 py-0.5 bg-primary/20 text-primary rounded-full flex items-center gap-1">
                        <Award className="w-3 h-3" />
                        معتمد
                      </span>
                    </div>
                    <div className="flex items-center gap-1 text-xs text-muted-foreground">
                      <MapPin className="w-3 h-3" />
                      <span>{coach.location}</span>
                    </div>
                  </div>
                </div>
              </div>)}
          </div>
        </div>

        {
    /* اختيار التاريخ */
  }
        <div>
          <h3 className="text-secondary font-medium mb-3 flex items-center gap-2">
            <Calendar className="w-5 h-5 text-primary" />
            اختر التاريخ
          </h3>
          <div className="flex gap-2 overflow-x-auto pb-2">
            {availableDates.map((date) => <button
    key={date.id}
    onClick={() => setSelectedDate(date.id)}
    className={`flex-shrink-0 w-20 py-3 rounded-xl border-2 transition-all ${selectedDate === date.id ? "bg-primary border-primary text-white shadow-md" : "bg-white border-border text-secondary hover:border-primary/50"}`}
  >
                <div className="text-center">
                  <p className="text-xs mb-1 opacity-80">{date.day}</p>
                  <p className="text-2xl font-bold">{date.dayNum}</p>
                  <p className="text-xs opacity-80">يونيو</p>
                </div>
              </button>)}
          </div>
        </div>

        {
    /* اختيار الوقت */
  }
        <div>
          <h3 className="text-secondary font-medium mb-3 flex items-center gap-2">
            <Clock className="w-5 h-5 text-primary" />
            اختر الوقت
          </h3>
          <div className="grid grid-cols-3 gap-3">
            {availableTimes.map((time) => <button
    key={time.id}
    onClick={() => setSelectedTime(time.id)}
    className={`py-3 rounded-xl border-2 transition-all ${selectedTime === time.id ? "bg-primary border-primary text-white shadow-md" : "bg-white border-border text-secondary hover:border-primary/50"}`}
  >
                <div className="text-center">
                  <p className="text-lg font-medium">{time.time}</p>
                  <p className="text-xs opacity-80">{time.period}</p>
                </div>
              </button>)}
          </div>
        </div>

        {
    /* ملخص الحجز */
  }
        {isFormComplete && <div className="bg-gradient-to-br from-green-50 to-green-100/50 border border-green-200 rounded-2xl p-5">
            <h3 className="text-secondary font-medium mb-3">ملخص الحجز</h3>
            <div className="space-y-2 text-sm">
              <div className="flex items-center justify-between">
                <span className="text-muted-foreground">المدرب:</span>
                <span className="text-secondary font-medium">
                  {certifiedCoaches.find((c) => c.id === selectedCoach)?.name}
                </span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-muted-foreground">التاريخ:</span>
                <span className="text-secondary font-medium">
                  {availableDates.find((d) => d.id === selectedDate)?.day} {availableDates.find((d) => d.id === selectedDate)?.dayNum} يونيو
                </span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-muted-foreground">الوقت:</span>
                <span className="text-secondary font-medium">
                  {availableTimes.find((t) => t.id === selectedTime)?.time} {availableTimes.find((t) => t.id === selectedTime)?.period}
                </span>
              </div>
              <div className="flex items-center justify-between pt-2 border-t border-green-300">
                <span className="text-muted-foreground">المدة:</span>
                <span className="text-secondary font-medium">60 دقيقة</span>
              </div>
              <div className="flex items-center justify-between pt-2 border-t border-green-300">
                <span className="text-secondary font-medium">المبلغ الإجمالي:</span>
                <span className="text-2xl font-bold text-green-600">250 ر.س</span>
              </div>
            </div>
          </div>}
      </div>

      {
    /* زر الحجز */
  }
      <div className="px-6 pb-6">
        <button
    onClick={handleBooking}
    disabled={!isFormComplete}
    className={`w-full py-4 rounded-xl shadow-lg flex items-center justify-center gap-2 transition-all ${isFormComplete ? "bg-primary text-white hover:bg-primary/90" : "bg-gray-300 text-gray-500 cursor-not-allowed"}`}
  >
          <Award className="w-5 h-5" />
          <span className="font-medium">تأكيد الحجز والدفع</span>
        </button>
      </div>
    </div>;
}
export {
  AssessmentBookingPage as default
};
