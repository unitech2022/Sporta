import { useState } from "react";
import { ChevronRight, Calendar, Clock, DollarSign, MapPin, Star } from "lucide-react";
import Tooltip from "./Tooltip";
function BookCourtPage({ courtId, onBack, onComplete }) {
  const [selectedDate, setSelectedDate] = useState("");
  const [selectedCourtNumber, setSelectedCourtNumber] = useState("");
  const [selectedDuration, setSelectedDuration] = useState(0);
  const [selectedTime, setSelectedTime] = useState("");
  const allCourts = [
    {
      id: "1",
      name: "\u0646\u0627\u062F\u064A \u0627\u0644\u0628\u0627\u062F\u0644 \u0627\u0644\u0645\u0644\u0643\u064A",
      rating: 4.8,
      reviews: 124,
      distance: "1.8 \u0643\u0645",
      city: "\u0627\u0644\u062F\u0645\u0627\u0645",
      type: "\u0645\u0644\u0639\u0628 \u062F\u0627\u062E\u0644\u064A",
      basePrice: 100,
      peakHourPrice: 150,
      bookedSlots: {
        "2024-06-02": ["14:00-60", "15:00-90", "19:00-120"],
        "2024-06-03": ["10:00-60", "18:00-90"]
      }
    },
    {
      id: "2",
      name: "\u0628\u0627\u062F\u0644 \u0643\u0644\u0648\u0628 \u0627\u0644\u0634\u0631\u0642\u064A\u0629",
      rating: 4.6,
      reviews: 89,
      distance: "3.2 \u0643\u0645",
      city: "\u0627\u0644\u062E\u0628\u0631",
      type: "\u0645\u0644\u0639\u0628 \u062E\u0627\u0631\u062C\u064A",
      basePrice: 80,
      peakHourPrice: 120,
      bookedSlots: {
        "2024-06-02": ["12:00-90", "16:00-60"]
      }
    },
    {
      id: "3",
      name: "\u0645\u0631\u0643\u0632 \u0628\u0627\u062F\u0644 \u0627\u0644\u0645\u062F\u064A\u0646\u0629",
      rating: 4.9,
      reviews: 201,
      distance: "5.4 \u0643\u0645",
      city: "\u0627\u0644\u062F\u0645\u0627\u0645",
      type: "\u0645\u0644\u0639\u0628 \u062F\u0627\u062E\u0644\u064A",
      basePrice: 120,
      peakHourPrice: 180,
      bookedSlots: {
        "2024-06-02": ["08:00-120", "20:00-90"]
      }
    },
    {
      id: "4",
      name: "\u0645\u0644\u0627\u0639\u0628 \u0627\u0644\u0648\u0627\u062D\u0629",
      rating: 4.3,
      reviews: 56,
      distance: "4.1 \u0643\u0645",
      city: "\u0627\u0644\u0642\u0637\u064A\u0641",
      type: "\u0645\u0644\u0639\u0628 \u062E\u0627\u0631\u062C\u064A",
      basePrice: 70,
      peakHourPrice: 100,
      bookedSlots: {}
    },
    {
      id: "5",
      name: "\u0646\u0627\u062F\u064A \u0627\u0644\u0646\u062E\u0628\u0629",
      rating: 4.7,
      reviews: 145,
      distance: "2.3 \u0643\u0645",
      city: "\u0627\u0644\u062E\u0628\u0631",
      type: "\u0645\u0644\u0639\u0628 \u062F\u0627\u062E\u0644\u064A",
      basePrice: 110,
      peakHourPrice: 160,
      bookedSlots: {
        "2024-06-02": ["17:00-60", "21:00-90"]
      }
    }
  ];
  const court = allCourts.find((c) => c.id === courtId) || allCourts[0];
  const generateDates = () => {
    const dates2 = [];
    const today = /* @__PURE__ */ new Date();
    for (let i = 0; i < 15; i++) {
      const date = new Date(today);
      date.setDate(today.getDate() + i);
      dates2.push({
        dateStr: date.toISOString().split("T")[0],
        dayName: getDayName(date.getDay()),
        dayNum: date.getDate(),
        monthName: getMonthName(date.getMonth())
      });
    }
    return dates2;
  };
  const getDayName = (dayIndex) => {
    const days = ["\u0627\u0644\u0623\u062D\u062F", "\u0627\u0644\u0627\u062B\u0646\u064A\u0646", "\u0627\u0644\u062B\u0644\u0627\u062B\u0627\u0621", "\u0627\u0644\u0623\u0631\u0628\u0639\u0627\u0621", "\u0627\u0644\u062E\u0645\u064A\u0633", "\u0627\u0644\u062C\u0645\u0639\u0629", "\u0627\u0644\u0633\u0628\u062A"];
    return days[dayIndex];
  };
  const getMonthName = (monthIndex) => {
    const months = ["\u064A\u0646\u0627\u064A\u0631", "\u0641\u0628\u0631\u0627\u064A\u0631", "\u0645\u0627\u0631\u0633", "\u0623\u0628\u0631\u064A\u0644", "\u0645\u0627\u064A\u0648", "\u064A\u0648\u0646\u064A\u0648", "\u064A\u0648\u0644\u064A\u0648", "\u0623\u063A\u0633\u0637\u0633", "\u0633\u0628\u062A\u0645\u0628\u0631", "\u0623\u0643\u062A\u0648\u0628\u0631", "\u0646\u0648\u0641\u0645\u0628\u0631", "\u062F\u064A\u0633\u0645\u0628\u0631"];
    return months[monthIndex];
  };
  const isPeakHour = (time) => {
    const hour = parseInt(time.split(":")[0]);
    return hour >= 16 && hour <= 23;
  };
  const isTimeBooked = (time, duration) => {
    if (!selectedDate || !court.bookedSlots[selectedDate]) return false;
    const slotKey = `${time}-${duration}`;
    return court.bookedSlots[selectedDate].includes(slotKey);
  };
  const getAvailableTimes = () => {
    const times = [
      "06:00",
      "07:00",
      "08:00",
      "09:00",
      "10:00",
      "11:00",
      "12:00",
      "13:00",
      "14:00",
      "15:00",
      "16:00",
      "17:00",
      "18:00",
      "19:00",
      "20:00",
      "21:00",
      "22:00",
      "23:00"
    ];
    return times.map((time) => {
      const isPeak = isPeakHour(time);
      const hours = selectedDuration / 60;
      const price = Math.round((isPeak ? court.peakHourPrice : court.basePrice) * hours);
      return {
        time,
        isBooked: isTimeBooked(time, selectedDuration),
        isPeakHour: isPeak,
        price
      };
    });
  };
  const calculateTotalPrice = () => {
    if (!selectedTime || !selectedDuration) return 0;
    const isPeak = isPeakHour(selectedTime);
    const hours = selectedDuration / 60;
    const price = isPeak ? court.peakHourPrice : court.basePrice;
    return Math.round(price * hours);
  };
  const handleBooking = () => {
    if (onComplete) {
      onComplete();
    }
  };
  const isFormValid = () => {
    return selectedDate !== "" && selectedCourtNumber !== "" && selectedDuration > 0 && selectedTime !== "";
  };
  const dates = generateDates();
  const availableTimes = selectedDate && selectedCourtNumber && selectedDuration > 0 ? getAvailableTimes() : [];
  const totalPrice = calculateTotalPrice();
  return <div className="flex-1 overflow-y-auto bg-background">
      {
    /* Header */
  }
      <div className="bg-gradient-to-br from-secondary to-secondary/90 text-white px-6 pt-8 pb-6">
        <div className="flex items-center gap-3 mb-4">
          <button onClick={onBack} className="p-2 bg-white/20 rounded-full backdrop-blur-sm hover:bg-white/30 transition-colors">
            <ChevronRight className="w-5 h-5 text-white" />
          </button>
          <h1 className="text-2xl">حجز الملعب</h1>
        </div>
        <p className="text-white/80 text-sm">اختر التاريخ والوقت المناسب لك</p>
      </div>

      <div className="px-6 py-6 space-y-5">
        {
    /* معلومات الملعب */
  }
        <div className="bg-white border border-border rounded-2xl p-5 shadow-sm">
          <div className="flex items-start justify-between mb-3">
            <div>
              <h3 className="text-secondary font-medium mb-2">{court.name}</h3>
              <div className="flex items-center gap-1 mb-2">
                <Star className="w-4 h-4 text-yellow-400 fill-yellow-400" />
                <span className="text-sm text-secondary">{court.rating}</span>
                <span className="text-xs text-muted-foreground">({court.reviews} تقييم)</span>
              </div>
              <div className="flex items-center gap-2 text-xs text-muted-foreground">
                <MapPin className="w-3 h-3 text-primary" />
                <span>{court.distance}</span>
                <span>•</span>
                <span>{court.type}</span>
              </div>
            </div>
          </div>

          <div className="bg-primary/5 rounded-xl p-3 text-sm">
            <div className="flex justify-between items-center">
              <span className="text-muted-foreground">السعر الأساسي:</span>
              <span className="text-secondary font-medium">{court.basePrice} ر.س/ساعة</span>
            </div>
            <div className="flex justify-between items-center mt-1">
              <span className="text-muted-foreground">وقت الذروة (4م-11م):</span>
              <span className="text-secondary font-medium">{court.peakHourPrice} ر.س/ساعة</span>
            </div>
          </div>
        </div>

        {
    /* اختيار التاريخ */
  }
        <div>
          <label className="block text-sm text-secondary mb-3 flex items-center gap-2">
            <Calendar className="w-4 h-4 text-primary" />
            اختر التاريخ *
          </label>
          <div className="flex gap-3 overflow-x-auto pb-3">
            {dates.map((date) => <button
    key={date.dateStr}
    onClick={() => {
      setSelectedDate(date.dateStr);
      setSelectedTime("");
      setSelectedDuration(0);
    }}
    className={`flex-shrink-0 w-20 py-3 px-2 rounded-xl border-2 transition-all text-center ${selectedDate === date.dateStr ? "border-primary bg-primary/10" : "border-border bg-white"}`}
  >
                <div className={`text-xs mb-1 ${selectedDate === date.dateStr ? "text-primary" : "text-muted-foreground"}`}>
                  {date.dayName}
                </div>
                <div className={`text-lg font-medium ${selectedDate === date.dateStr ? "text-primary" : "text-secondary"}`}>
                  {date.dayNum}
                </div>
                <div className={`text-xs ${selectedDate === date.dateStr ? "text-primary" : "text-muted-foreground"}`}>
                  {date.monthName}
                </div>
              </button>)}
          </div>
        </div>

        {
    /* اختيار رقم الملعب */
  }
        {selectedDate && <div>
            <label className="block text-sm text-secondary mb-3 flex items-center gap-2">
              <MapPin className="w-4 h-4 text-primary" />
              اختر رقم الملعب *
            </label>
            <div className="grid grid-cols-5 gap-2">
              {Array.from({ length: 10 }, (_, i) => i + 1).map((number) => <button
    key={number}
    onClick={() => {
      setSelectedCourtNumber(number.toString());
      setSelectedTime("");
      setSelectedDuration(0);
    }}
    className={`py-3 rounded-xl border-2 transition-all ${selectedCourtNumber === number.toString() ? "border-primary bg-primary/10 text-primary" : "border-border bg-white text-secondary"}`}
  >
                  <div className="text-sm font-medium">{number}</div>
                </button>)}
            </div>
          </div>}

        {
    /* اختيار المدة */
  }
        {selectedDate && selectedCourtNumber && <div>
            <label className="block text-sm text-secondary mb-3">مدة الحجز *</label>
            <div className="grid grid-cols-3 gap-3">
              {[60, 90, 120].map((duration) => <button
    key={duration}
    onClick={() => {
      setSelectedDuration(duration);
      setSelectedTime("");
    }}
    className={`py-3 rounded-xl border-2 transition-all ${selectedDuration === duration ? "border-primary bg-primary/10 text-primary" : "border-border bg-white text-secondary"}`}
  >
                  {duration} دقيقة
                </button>)}
            </div>
          </div>}

        {
    /* اختيار الوقت */
  }
        {selectedDate && selectedCourtNumber && selectedDuration > 0 && <div>
            <label className="block text-sm text-secondary mb-3 flex items-center gap-2">
              <Clock className="w-4 h-4 text-primary" />
              اختر الوقت *
            </label>

            {
    /* دليل الألوان */
  }
            <div className="flex gap-3 mb-3 text-xs">
              <div className="flex items-center gap-1">
                <div className="w-3 h-3 bg-green-100 border border-green-300 rounded" />
                <span className="text-muted-foreground">متاح</span>
              </div>
              <div className="flex items-center gap-1">
                <div className="w-3 h-3 bg-gray-200 border border-gray-300 rounded" />
                <span className="text-muted-foreground">محجوز</span>
              </div>
              <div className="flex items-center gap-1">
                <div className="w-2 h-2 bg-orange-400 rounded-full" />
                <span className="text-muted-foreground">وقت ذروة</span>
              </div>
            </div>

            <div className="grid grid-cols-3 gap-2">
              {availableTimes.map((slot) => <button
    key={slot.time}
    onClick={() => !slot.isBooked && setSelectedTime(slot.time)}
    disabled={slot.isBooked}
    className={`py-3 rounded-xl border-2 transition-all relative ${selectedTime === slot.time ? "border-primary bg-primary/10 text-primary" : slot.isBooked ? "border-gray-300 bg-gray-100 cursor-not-allowed opacity-60" : "border-border bg-green-50 hover:border-green-400"}`}
  >
                  <div className="text-sm font-medium">{slot.time}</div>
                  {slot.isPeakHour && !slot.isBooked && <Tooltip content="وقت ذروة - سعر مرتفع (4م - 11م)" position="top">
                      <div className="absolute top-1 left-1 w-2 h-2 bg-orange-400 rounded-full cursor-help" />
                    </Tooltip>}
                  <div className="text-xs mt-1">
                    {slot.isBooked ? "\u0645\u062D\u062C\u0648\u0632" : `${slot.price} \u0631.\u0633`}
                  </div>
                </button>)}
            </div>
          </div>}

        {
    /* ملخص السعر */
  }
        {selectedDate && selectedCourtNumber && selectedTime && selectedDuration > 0 && <div className="bg-gradient-to-br from-green-50 to-green-100/50 border border-green-200 rounded-2xl p-5">
            <div className="flex items-center gap-2 mb-4">
              <DollarSign className="w-5 h-5 text-green-600" />
              <h3 className="text-secondary font-medium">ملخص الحجز</h3>
            </div>

            <div className="space-y-2 mb-4 text-sm">
              <div className="flex justify-between items-center">
                <span className="text-muted-foreground">التاريخ:</span>
                <span className="text-secondary">
                  {dates.find((d) => d.dateStr === selectedDate)?.dayName}، {dates.find((d) => d.dateStr === selectedDate)?.dayNum} {dates.find((d) => d.dateStr === selectedDate)?.monthName}
                </span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-muted-foreground">رقم الملعب:</span>
                <span className="text-secondary">الملعب {selectedCourtNumber}</span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-muted-foreground">الوقت:</span>
                <span className="text-secondary">{selectedTime}</span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-muted-foreground">المدة:</span>
                <span className="text-secondary">{selectedDuration} دقيقة</span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-muted-foreground">نوع السعر:</span>
                <span className={`text-sm ${isPeakHour(selectedTime) ? "text-orange-600" : "text-green-600"}`}>
                  {isPeakHour(selectedTime) ? "\u0648\u0642\u062A \u0627\u0644\u0630\u0631\u0648\u0629" : "\u0648\u0642\u062A \u0639\u0627\u062F\u064A"}
                </span>
              </div>
              <div className="h-px bg-green-200 my-2" />
              <div className="flex justify-between items-center">
                <span className="text-secondary font-medium">المبلغ الإجمالي:</span>
                <span className="text-xl font-medium text-green-600">{totalPrice} ر.س</span>
              </div>
            </div>
          </div>}

        {
    /* أزرار الإجراءات */
  }
        <div className="flex gap-3 pt-4">
          <button
    onClick={onBack}
    className="px-6 py-3 bg-gray-100 text-secondary rounded-xl"
  >
            إلغاء
          </button>
          <button
    onClick={handleBooking}
    disabled={!isFormValid()}
    className={`flex-1 py-3 rounded-xl shadow-lg ${isFormValid() ? "bg-gradient-to-r from-primary to-primary/90 text-white" : "bg-gray-300 text-gray-500 cursor-not-allowed"}`}
  >
            تأكيد الحجز
          </button>
        </div>
      </div>
    </div>;
}
export {
  BookCourtPage as default
};
