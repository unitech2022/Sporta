import { Search, Filter, MapPin, Clock, TrendingUp, ChevronRight, Plus, Calendar, DollarSign } from "lucide-react";
import Tooltip from "./Tooltip";
const americanoEvents = [
  {
    id: "1",
    type: "\u0641\u0631\u0642",
    courtName: "\u0646\u0627\u062F\u064A \u0627\u0644\u0628\u0627\u062F\u0644 \u0627\u0644\u0645\u0644\u0643\u064A",
    location: "\u0627\u0644\u062F\u0645\u0627\u0645",
    distance: "1.8 \u0643\u0645",
    date: "2024-06-03",
    time: "17:00",
    duration: 180,
    minLevel: "4.5",
    maxLevel: "6.0",
    currentPlayers: 10,
    totalPlayers: 16,
    costPerPlayer: 60,
    organizerName: "\u0623\u062D\u0645\u062F \u0627\u0644\u0645\u0637\u064A\u0631\u064A",
    gender: "\u0631\u062C\u0627\u0644",
    rounds: 4
  },
  {
    id: "2",
    type: "\u0641\u0631\u062F\u064A",
    courtName: "\u0628\u0627\u062F\u0644 \u0643\u0644\u0648\u0628 \u0627\u0644\u0634\u0631\u0642\u064A\u0629",
    location: "\u0627\u0644\u062E\u0628\u0631",
    distance: "3.2 \u0643\u0645",
    date: "2024-06-04",
    time: "18:30",
    duration: 150,
    minLevel: "3.5",
    maxLevel: "5.0",
    currentPlayers: 6,
    totalPlayers: 8,
    costPerPlayer: 45,
    organizerName: "\u062E\u0627\u0644\u062F \u0627\u0644\u0633\u0627\u0644\u0645",
    gender: "\u0631\u062C\u0627\u0644",
    rounds: 3
  },
  {
    id: "3",
    type: "\u0641\u0631\u0642",
    courtName: "\u0645\u0631\u0643\u0632 \u0628\u0627\u062F\u0644 \u0627\u0644\u0645\u062F\u064A\u0646\u0629",
    location: "\u0627\u0644\u062F\u0645\u0627\u0645",
    distance: "5.4 \u0643\u0645",
    date: "2024-06-05",
    time: "16:00",
    duration: 200,
    minLevel: "5.0",
    maxLevel: "7.0",
    currentPlayers: 12,
    totalPlayers: 12,
    costPerPlayer: 70,
    organizerName: "\u0633\u0627\u0631\u0629 \u0627\u0644\u0639\u062A\u064A\u0628\u064A",
    gender: "\u0646\u0633\u0627\u0621",
    rounds: 5
  },
  {
    id: "4",
    type: "\u0641\u0631\u062F\u064A",
    courtName: "\u0646\u0627\u062F\u064A \u0627\u0644\u0646\u062E\u0628\u0629",
    location: "\u0627\u0644\u062E\u0628\u0631",
    distance: "2.3 \u0643\u0645",
    date: "2024-06-06",
    time: "19:00",
    duration: 120,
    minLevel: "4.0",
    maxLevel: "5.5",
    currentPlayers: 4,
    totalPlayers: 8,
    costPerPlayer: 50,
    organizerName: "\u0641\u0647\u062F \u0627\u0644\u062F\u0648\u0633\u0631\u064A",
    gender: "\u0631\u062C\u0627\u0644",
    rounds: 3
  }
];
function AmericanoPage({ onBack, onNavigate }) {
  const formatDate = (dateStr) => {
    const date = new Date(dateStr);
    const days = ["\u0627\u0644\u0623\u062D\u062F", "\u0627\u0644\u0627\u062B\u0646\u064A\u0646", "\u0627\u0644\u062B\u0644\u0627\u062B\u0627\u0621", "\u0627\u0644\u0623\u0631\u0628\u0639\u0627\u0621", "\u0627\u0644\u062E\u0645\u064A\u0633", "\u0627\u0644\u062C\u0645\u0639\u0629", "\u0627\u0644\u0633\u0628\u062A"];
    const months = ["\u064A\u0646\u0627\u064A\u0631", "\u0641\u0628\u0631\u0627\u064A\u0631", "\u0645\u0627\u0631\u0633", "\u0623\u0628\u0631\u064A\u0644", "\u0645\u0627\u064A\u0648", "\u064A\u0648\u0646\u064A\u0648", "\u064A\u0648\u0644\u064A\u0648", "\u0623\u063A\u0633\u0637\u0633", "\u0633\u0628\u062A\u0645\u0628\u0631", "\u0623\u0643\u062A\u0648\u0628\u0631", "\u0646\u0648\u0641\u0645\u0628\u0631", "\u062F\u064A\u0633\u0645\u0628\u0631"];
    return `${days[date.getDay()]}\u060C ${date.getDate()} ${months[date.getMonth()]}`;
  };
  const formatTime = (timeStr) => {
    const [hour, minute] = timeStr.split(":");
    const hourNum = parseInt(hour);
    const period = hourNum >= 12 ? "\u0645\u0633\u0627\u0621\u064B" : "\u0635\u0628\u0627\u062D\u0627\u064B";
    const hour12 = hourNum > 12 ? hourNum - 12 : hourNum === 0 ? 12 : hourNum;
    return `${hour12}:${minute} ${period}`;
  };
  return <div className="flex-1 overflow-y-auto bg-background">
      {
    /* Header */
  }
      <div className="bg-gradient-to-br from-secondary to-secondary/90 text-white px-6 pt-8 pb-6">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-3">
            {onBack && <button onClick={onBack} className="p-2 bg-white/20 rounded-full backdrop-blur-sm hover:bg-white/30 transition-colors">
                <ChevronRight className="w-5 h-5" />
              </button>}
            <h1 className="text-2xl">أمريكانو</h1>
          </div>
          <button
    onClick={() => onNavigate && onNavigate("create-americano")}
    className="flex items-center gap-2 px-4 py-2 bg-primary text-white rounded-xl shadow-lg hover:bg-primary/90 transition-colors"
  >
            <Plus className="w-5 h-5" />
            <span className="text-sm">إنشاء أمريكانو</span>
          </button>
        </div>

        <p className="text-white/80 text-sm mb-4">نظام المباريات الدوري مع تبديل الشركاء</p>

        <div className="relative">
          <Search className="absolute right-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
          <input
    type="text"
    placeholder="ابحث عن أمريكانو..."
    className="w-full bg-white/95 backdrop-blur-sm text-gray-800 placeholder-gray-400 rounded-xl py-3 pr-11 pl-4 outline-none"
  />
        </div>
      </div>

      <div className="px-6 py-4">
        {
    /* الفلاتر */
  }
        <div className="flex gap-2 mb-5 overflow-x-auto pb-2">
          <button className="px-4 py-2 bg-primary text-white rounded-full text-sm whitespace-nowrap flex-shrink-0">
            الكل
          </button>
          <Tooltip content="فلترة حسب نوع الأمريكانو (فردي/فرق)" position="bottom">
            <button className="px-4 py-2 bg-white border border-border text-secondary rounded-full text-sm whitespace-nowrap flex-shrink-0">
              <Filter className="w-4 h-4 inline ml-1 text-primary" />
              النوع
            </button>
          </Tooltip>
          <Tooltip content="فلترة حسب المستوى" position="bottom">
            <button className="px-4 py-2 bg-white border border-border text-secondary rounded-full text-sm whitespace-nowrap flex-shrink-0">
              المستوى
            </button>
          </Tooltip>
          <Tooltip content="فلترة حسب التاريخ" position="bottom">
            <button className="px-4 py-2 bg-white border border-border text-secondary rounded-full text-sm whitespace-nowrap flex-shrink-0">
              التاريخ
            </button>
          </Tooltip>
          <Tooltip content="فلترة حسب الموقع القريب" position="bottom">
            <button className="px-4 py-2 bg-white border border-border text-secondary rounded-full text-sm whitespace-nowrap flex-shrink-0">
              الموقع
            </button>
          </Tooltip>
        </div>

        {
    /* شرح مختصر عن الأمريكانو */
  }
        <div className="bg-gradient-to-br from-green-50 to-green-100/50 border border-green-200 rounded-2xl p-4 mb-5">
          <div className="flex items-start gap-3">
            <div className="w-10 h-10 bg-green-500 rounded-full flex items-center justify-center flex-shrink-0">
              <TrendingUp className="w-5 h-5 text-white" />
            </div>
            <div>
              <h3 className="text-secondary font-medium mb-1">ما هو الأمريكانو؟</h3>
              <p className="text-sm text-muted-foreground leading-relaxed">
                نظام مباريات دوري حيث يلعب كل لاعب مع شركاء مختلفين في كل جولة. يتم احتساب النقاط الفردية لتحديد الفائز النهائي.
              </p>
            </div>
          </div>
        </div>

        {
    /* قائمة الأمريكانو */
  }
        <div className="space-y-4">
          {americanoEvents.map((event) => {
    const isFull = event.currentPlayers >= event.totalPlayers;
    const spotsLeft = event.totalPlayers - event.currentPlayers;
    return <div
      key={event.id}
      className={`bg-white border-2 rounded-2xl p-4 shadow-sm transition-all ${isFull ? "opacity-60 border-border" : "border-primary/30 hover:border-primary/50"}`}
    >
                {
      /* Header */
    }
                <div className="flex justify-between items-start mb-4">
                  <div className="flex items-center gap-2">
                    <span className={`px-3 py-1 text-xs rounded-full ${event.type === "\u0641\u0631\u062F\u064A" ? "bg-blue-100 text-blue-600" : "bg-purple-100 text-purple-600"}`}>
                      أمريكانو {event.type}
                    </span>
                    <span className="px-3 py-1 bg-gray-100 text-gray-600 text-xs rounded-full">
                      {event.gender}
                    </span>
                  </div>
                  {isFull ? <span className="px-3 py-1 bg-red-100 text-red-600 text-xs rounded-full">مكتمل</span> : <span className="px-3 py-1 bg-green-100 text-green-600 text-xs rounded-full">
                      متبقي {spotsLeft}
                    </span>}
                </div>

                {
      /* معلومات الملعب */
    }
                <div className="mb-4">
                  <div className="flex items-center gap-2 mb-2">
                    <MapPin className="w-4 h-4 text-primary" />
                    <p className="text-sm text-secondary font-medium">{event.courtName}</p>
                  </div>
                  <p className="text-xs text-muted-foreground mr-6">{event.location} • {event.distance}</p>
                </div>

                {
      /* التاريخ والوقت */
    }
                <div className="grid grid-cols-2 gap-3 mb-4">
                  <div className="flex items-center gap-2">
                    <Calendar className="w-4 h-4 text-primary" />
                    <div>
                      <p className="text-xs text-muted-foreground">التاريخ</p>
                      <p className="text-sm text-secondary">{formatDate(event.date)}</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    <Clock className="w-4 h-4 text-primary" />
                    <div>
                      <p className="text-xs text-muted-foreground">الوقت</p>
                      <p className="text-sm text-secondary">{formatTime(event.time)}</p>
                    </div>
                  </div>
                </div>

                {
      /* تفاصيل إضافية */
    }
                <div className="bg-gray-50 rounded-xl p-3 mb-4 space-y-2">
                  <div className="flex justify-between items-center text-sm">
                    <span className="text-muted-foreground">المستوى:</span>
                    <span className="text-secondary font-medium">{event.minLevel} - {event.maxLevel}</span>
                  </div>
                  <div className="flex justify-between items-center text-sm">
                    <span className="text-muted-foreground">عدد الجولات:</span>
                    <span className="text-secondary font-medium">{event.rounds} جولات</span>
                  </div>
                  <div className="flex justify-between items-center text-sm">
                    <span className="text-muted-foreground">المدة المتوقعة:</span>
                    <span className="text-secondary font-medium">{event.duration} دقيقة</span>
                  </div>
                  <div className="flex justify-between items-center text-sm">
                    <span className="text-muted-foreground">اللاعبين:</span>
                    <span className="text-secondary font-medium">{event.currentPlayers}/{event.totalPlayers}</span>
                  </div>
                </div>

                {
      /* اللاعبين المسجلين */
    }
                <div className="flex items-center gap-3 mb-4 pb-4 border-b border-border">
                  <div className="flex -space-x-2">
                    {Array.from({ length: Math.min(event.currentPlayers, 5) }).map((_, i) => <div
      key={i}
      className="w-8 h-8 bg-gradient-to-br from-primary to-primary/80 rounded-full border-2 border-white flex items-center justify-center"
    >
                        <span className="text-white text-xs">{(Math.random() * 3 + 3).toFixed(1)}</span>
                      </div>)}
                    {event.currentPlayers > 5 && <div className="w-8 h-8 bg-gray-200 rounded-full border-2 border-white flex items-center justify-center">
                        <span className="text-xs text-gray-600">+{event.currentPlayers - 5}</span>
                      </div>}
                  </div>
                  <div className="text-xs text-muted-foreground">
                    {event.currentPlayers} لاعب مسجل
                  </div>
                </div>

                {
      /* السعر وزر الانضمام */
    }
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <DollarSign className="w-4 h-4 text-green-600" />
                    <div>
                      <p className="text-xs text-muted-foreground">التكلفة</p>
                      <p className="text-lg font-medium text-green-600">{event.costPerPlayer} ر.س</p>
                    </div>
                  </div>
                  {isFull ? <button
      onClick={() => onNavigate && onNavigate("americano-execution")}
      className="px-6 py-2.5 rounded-xl shadow-md bg-gradient-to-r from-green-500 to-green-600 text-white hover:shadow-lg transition-all"
    >
                      إدارة الأمريكانو
                    </button> : <button
      onClick={() => onNavigate && onNavigate("join-americano", event.type)}
      className="px-6 py-2.5 rounded-xl shadow-md bg-gradient-to-r from-primary to-primary/90 text-white hover:shadow-lg transition-all"
    >
                      انضم الآن
                    </button>}
                </div>
              </div>;
  })}
        </div>

        {
    /* زر إنشاء أمريكانو جديد */
  }
        <div className="mt-6 pb-6">
          <button
    onClick={() => onNavigate && onNavigate("create-americano")}
    className="w-full py-4 bg-gradient-to-r from-green-500 to-green-600 text-white rounded-xl shadow-lg flex items-center justify-center gap-2 hover:shadow-xl transition-all"
  >
            <TrendingUp className="w-5 h-5" />
            أنشئ أمريكانو جديد
          </button>
        </div>
      </div>
    </div>;
}
export {
  AmericanoPage as default
};
