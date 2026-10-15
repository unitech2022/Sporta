import { useState } from "react";
import { ChevronRight, MapPin, Calendar, Clock, Users, TrendingUp, AlertCircle, CheckCircle, DollarSign, MessageCircle, UserPlus, Send, X, Search, Star } from "lucide-react";
const registeredTeams = [
  {
    id: "t1",
    player1: { name: "\u0623\u062D\u0645\u062F \u0627\u0644\u0632\u0647\u0631\u0627\u0646\u064A", level: "4.5", avatar: "\u0623.\u0632", color: "from-primary to-primary/80" },
    player2: { name: "\u0633\u0639\u062F \u0627\u0644\u0645\u0637\u064A\u0631\u064A", level: "4.2", avatar: "\u0633.\u0645", color: "from-blue-500 to-blue-600" }
  },
  {
    id: "t2",
    player1: { name: "\u0639\u0645\u0631 \u0627\u0644\u0634\u0647\u0631\u064A", level: "3.8", avatar: "\u0639.\u0634", color: "from-purple-500 to-purple-600" },
    player2: { name: "\u0641\u0647\u062F \u0627\u0644\u0633\u0628\u064A\u0639\u064A", level: "4.0", avatar: "\u0641.\u0633", color: "from-green-500 to-green-600" }
  }
];
const friendsList = [
  { id: "f1", name: "\u0633\u0639\u062F \u0627\u0644\u063A\u0627\u0645\u062F\u064A", level: "4.5", gamesPlayed: 62, winRate: 58, status: "online", avatar: "\u0633.\u063A", color: "from-primary to-primary/80" },
  { id: "f2", name: "\u0639\u0645\u0631 \u0627\u0644\u0634\u0647\u0631\u064A", level: "3.8", gamesPlayed: 38, winRate: 44, status: "online", avatar: "\u0639.\u0634", color: "from-blue-500 to-blue-600" },
  { id: "f3", name: "\u0641\u064A\u0635\u0644 \u0627\u0644\u0639\u062A\u064A\u0628\u064A", level: "5.0", gamesPlayed: 95, winRate: 63, status: "offline", avatar: "\u0641.\u0639", color: "from-purple-500 to-purple-600" },
  { id: "f4", name: "\u0645\u0627\u062C\u062F \u0627\u0644\u062F\u0648\u0633\u0631\u064A", level: "4.2", gamesPlayed: 51, winRate: 49, status: "online", avatar: "\u0645.\u062F", color: "from-green-500 to-green-600" },
  { id: "f5", name: "\u0628\u0646\u062F\u0631 \u0627\u0644\u062D\u0631\u0628\u064A", level: "4.8", gamesPlayed: 74, winRate: 55, status: "offline", avatar: "\u0628.\u062D", color: "from-orange-500 to-orange-600" },
  { id: "f6", name: "\u062A\u0631\u0643\u064A \u0627\u0644\u0632\u0647\u0631\u0627\u0646\u064A", level: "3.5", gamesPlayed: 29, winRate: 41, status: "online", avatar: "\u062A.\u0632", color: "from-teal-500 to-teal-600" }
];
const userScheduledMatches = [
  {
    id: "2",
    courtName: "\u0645\u0631\u0643\u0632 \u0628\u0627\u062F\u0644 \u0627\u0644\u0634\u0631\u0642\u064A\u0629",
    location: "\u0627\u0644\u062E\u0628\u0631",
    distance: "4.2 \u0643\u0645",
    date: "2024-06-02",
    time: "18:00",
    duration: 90,
    matchType: "\u0648\u062F\u064A\u0629 \u0641\u0631\u062F\u064A",
    minLevel: "4.0",
    maxLevel: "5.0",
    currentPlayers: 3,
    maxPlayers: 4,
    costPerPlayer: 40,
    organizerName: "\u062E\u0627\u0644\u062F \u0627\u0644\u0633\u0627\u0644\u0645",
    organizerLevel: "4.5"
  }
];
function JoinMatchPage({ onBack, onJoin, onNavigateToSelectTeammate, selectedTeammate, isAmericano = false, americanoType = "\u0641\u0631\u062F\u064A", matchType }) {
  const [showConfirmation, setShowConfirmation] = useState(false);
  const [timeConflict, setTimeConflict] = useState(null);
  const [showFriendsPicker, setShowFriendsPicker] = useState(false);
  const [invitedFriends, setInvitedFriends] = useState([]);
  const [friendSearch, setFriendSearch] = useState("");
  const toggleInvite = (id) => {
    setInvitedFriends(
      (prev) => prev.includes(id) ? prev.filter((f) => f !== id) : [...prev, id]
    );
  };
  const filteredFriends = friendsList.filter(
    (f) => f.name.includes(friendSearch) || f.level.includes(friendSearch)
  );
  const match = isAmericano ? {
    id: "a1",
    courtName: "\u0628\u0627\u062F\u0644 \u0643\u0644\u0648\u0628 \u0627\u0644\u0634\u0631\u0642\u064A\u0629",
    location: "\u0627\u0644\u062E\u0628\u0631",
    distance: "3.2 \u0643\u0645",
    date: "2024-06-04",
    time: "18:30",
    duration: 150,
    matchType: americanoType === "\u0641\u0631\u062F\u064A" ? "\u0623\u0645\u0631\u064A\u0643\u0627\u0646\u0648 \u0641\u0631\u062F\u064A" : "\u0623\u0645\u0631\u064A\u0643\u0627\u0646\u0648 \u0641\u0631\u0642",
    minLevel: "3.5",
    maxLevel: "5.0",
    currentPlayers: americanoType === "\u0641\u0631\u0642" ? 4 : 3,
    maxPlayers: americanoType === "\u0641\u0631\u0642" ? 16 : 16,
    costPerPlayer: 45,
    organizerName: "\u062E\u0627\u0644\u062F \u0627\u0644\u0633\u0627\u0644\u0645",
    organizerLevel: "4.2",
    rounds: 3,
    gender: "\u0631\u062C\u0627\u0644",
    notes: americanoType === "\u0641\u0631\u062F\u064A" ? "\u0646\u0638\u0627\u0645 \u0623\u0645\u0631\u064A\u0643\u0627\u0646\u0648 \u0641\u0631\u062F\u064A - \u0633\u064A\u062A\u0645 \u062A\u0628\u062F\u064A\u0644 \u0627\u0644\u0634\u0631\u0643\u0627\u0621 \u0641\u064A \u0643\u0644 \u062C\u0648\u0644\u0629 \u0644\u0636\u0645\u0627\u0646 \u0627\u0644\u0644\u0639\u0628 \u0645\u0639 \u062C\u0645\u064A\u0639 \u0627\u0644\u0644\u0627\u0639\u0628\u064A\u0646" : "\u0646\u0638\u0627\u0645 \u0623\u0645\u0631\u064A\u0643\u0627\u0646\u0648 \u0641\u0631\u0642 - \u0633\u062A\u0644\u0639\u0628 \u0645\u0639 \u0634\u0631\u064A\u0643\u0643 \u0641\u064A \u062C\u0645\u064A\u0639 \u0627\u0644\u062C\u0648\u0644\u0627\u062A \u0648\u0633\u064A\u062A\u0645 \u0627\u062D\u062A\u0633\u0627\u0628 \u0627\u0644\u0646\u0642\u0627\u0637 \u0644\u0644\u0641\u0631\u064A\u0642"
  } : matchType === "\u062A\u062D\u062F\u064A \u0641\u0631\u0642" ? {
    id: "1",
    courtName: "\u0646\u0627\u062F\u064A \u0627\u0644\u0628\u0627\u062F\u0644 \u0627\u0644\u0645\u0644\u0643\u064A",
    location: "\u0627\u0644\u062F\u0645\u0627\u0645",
    distance: "1.8 \u0643\u0645",
    date: "2024-06-02",
    time: "18:00",
    duration: 90,
    matchType: "\u062A\u062D\u062F\u064A \u0641\u0631\u0642",
    minLevel: "5.0",
    maxLevel: "6.0",
    currentPlayers: 2,
    maxPlayers: 4,
    costPerPlayer: 45,
    organizerName: "\u0623\u062D\u0645\u062F \u0627\u0644\u0645\u0637\u064A\u0631\u064A",
    organizerLevel: "5.5",
    notes: "\u0646\u0628\u062D\u062B \u0639\u0646 \u0644\u0627\u0639\u0628\u064A\u0646 \u0630\u0648\u064A \u062E\u0628\u0631\u0629 \u0644\u0644\u0645\u0634\u0627\u0631\u0643\u0629 \u0641\u064A \u0645\u0628\u0627\u0631\u0627\u0629 \u062A\u062D\u062F\u064A \u0642\u0648\u064A\u0629"
  } : matchType === "\u0648\u062F\u064A\u0629 \u0641\u0631\u062F\u064A" ? {
    id: "2",
    courtName: "\u0645\u0644\u0639\u0628 \u0627\u0644\u0623\u0646\u062F\u064A\u0629 \u0627\u0644\u0634\u0631\u0642\u064A\u0629",
    location: "\u0627\u0644\u062E\u0628\u0631",
    distance: "3.2 \u0643\u0645",
    date: "2024-06-03",
    time: "19:30",
    duration: 90,
    matchType: "\u0648\u062F\u064A\u0629 \u0641\u0631\u062F\u064A",
    minLevel: "4.5",
    maxLevel: "5.5",
    currentPlayers: 1,
    maxPlayers: 4,
    costPerPlayer: 40,
    organizerName: "\u0645\u062D\u0645\u062F \u0627\u0644\u0623\u062D\u0645\u062F",
    organizerLevel: "4.8",
    notes: "\u0645\u0628\u0627\u0631\u0627\u0629 \u0648\u062F\u064A\u0629 \u0641\u0631\u062F\u064A\u0629 \u0644\u0644\u0627\u0639\u0628\u064A\u0646 \u0645\u0646 \u0645\u0633\u062A\u0648\u0649 \u0645\u062A\u0648\u0633\u0637. \u0643\u0644 \u0644\u0627\u0639\u0628 \u064A\u0644\u0639\u0628 \u0644\u0648\u062D\u062F\u0647"
  } : matchType === "\u0648\u062F\u064A\u0629 \u0641\u0631\u0642" ? {
    id: "3",
    courtName: "\u0646\u0627\u062F\u064A \u0627\u0644\u0631\u064A\u0627\u0636\u0629 \u0644\u0644\u0628\u0627\u062F\u0644",
    location: "\u0627\u0644\u062F\u0645\u0627\u0645",
    distance: "4.5 \u0643\u0645",
    date: "2024-06-05",
    time: "17:30",
    duration: 90,
    matchType: "\u0648\u062F\u064A\u0629 \u0641\u0631\u0642",
    minLevel: "3.5",
    maxLevel: "4.5",
    currentPlayers: 2,
    maxPlayers: 4,
    costPerPlayer: 35,
    organizerName: "\u0639\u0628\u062F\u0627\u0644\u0644\u0647 \u0627\u0644\u0633\u0639\u064A\u062F",
    organizerLevel: "4.0",
    notes: "\u0645\u0628\u0627\u0631\u0627\u0629 \u0648\u062F\u064A\u0629 \u0644\u0644\u0641\u0631\u0642 \u0641\u064A \u062C\u0648 \u0645\u0645\u062A\u0639. \u0646\u0628\u062D\u062B \u0639\u0646 \u0641\u0631\u064A\u0642 \u0648\u0627\u062D\u062F \u0644\u0644\u0627\u0646\u0636\u0645\u0627\u0645"
  } : {
    id: "1",
    courtName: "\u0646\u0627\u062F\u064A \u0627\u0644\u0628\u0627\u062F\u0644 \u0627\u0644\u0645\u0644\u0643\u064A",
    location: "\u0627\u0644\u062F\u0645\u0627\u0645",
    distance: "1.8 \u0643\u0645",
    date: "2024-06-02",
    time: "18:00",
    duration: 90,
    matchType: "\u062A\u062D\u062F\u064A \u0641\u0631\u0642",
    minLevel: "5.0",
    maxLevel: "6.0",
    currentPlayers: 2,
    maxPlayers: 4,
    costPerPlayer: 45,
    organizerName: "\u0623\u062D\u0645\u062F \u0627\u0644\u0645\u0637\u064A\u0631\u064A",
    organizerLevel: "5.5",
    notes: "\u0646\u0628\u062D\u062B \u0639\u0646 \u0644\u0627\u0639\u0628\u064A\u0646 \u0630\u0648\u064A \u062E\u0628\u0631\u0629 \u0644\u0644\u0645\u0634\u0627\u0631\u0643\u0629 \u0641\u064A \u0645\u0628\u0627\u0631\u0627\u0629 \u062A\u062D\u062F\u064A \u0642\u0648\u064A\u0629"
  };
  const isAmericanoTeams = isAmericano && americanoType === "\u0641\u0631\u0642";
  const maxInvites = isAmericanoTeams ? Math.floor((match.maxPlayers - match.currentPlayers) / 2) - 1 : match.maxPlayers - match.currentPlayers - 1;
  const spotsLeft = Math.max(0, maxInvites);
  const getMatchTimestamp = (date, time) => {
    const [year, month, day] = date.split("-").map(Number);
    const [hour, minute] = time.split(":").map(Number);
    return new Date(year, month - 1, day, hour, minute).getTime();
  };
  const checkTimeConflict = () => {
    const matchStart = getMatchTimestamp(match.date, match.time);
    const matchEnd = matchStart + match.duration * 60 * 1e3;
    for (const scheduledMatch of userScheduledMatches) {
      const scheduledStart = getMatchTimestamp(scheduledMatch.date, scheduledMatch.time);
      const scheduledEnd = scheduledStart + scheduledMatch.duration * 60 * 1e3;
      const twoHours = 2 * 60 * 60 * 1e3;
      const bufferStart = scheduledStart - twoHours;
      const bufferEnd = scheduledEnd + twoHours;
      if (matchStart >= bufferStart && matchStart < bufferEnd || matchEnd > bufferStart && matchEnd <= bufferEnd || matchStart <= bufferStart && matchEnd >= bufferEnd) {
        setTimeConflict(`\u0644\u062F\u064A\u0643 \u0645\u0628\u0627\u0631\u0627\u0629 \u0641\u064A ${scheduledMatch.courtName} \u0627\u0644\u0633\u0627\u0639\u0629 ${scheduledMatch.time}`);
        return true;
      }
    }
    setTimeConflict(null);
    return false;
  };
  const handleJoinClick = () => {
    const hasConflict = checkTimeConflict();
    if (!hasConflict) {
      if (match.matchType.includes("\u0641\u0631\u0642") && match.matchType !== "\u0623\u0645\u0631\u064A\u0643\u0627\u0646\u0648 \u0641\u0631\u062F\u064A") {
        if (onNavigateToSelectTeammate) {
          onNavigateToSelectTeammate();
        }
      } else {
        setShowConfirmation(true);
      }
    }
  };
  const handleConfirmJoin = () => {
    if (onJoin) {
      onJoin();
    }
  };
  const formatDate = (dateStr) => {
    const date = new Date(dateStr);
    const days = ["\u0627\u0644\u0623\u062D\u062F", "\u0627\u0644\u0627\u062B\u0646\u064A\u0646", "\u0627\u0644\u062B\u0644\u0627\u062B\u0627\u0621", "\u0627\u0644\u0623\u0631\u0628\u0639\u0627\u0621", "\u0627\u0644\u062E\u0645\u064A\u0633", "\u0627\u0644\u062C\u0645\u0639\u0629", "\u0627\u0644\u0633\u0628\u062A"];
    return `${days[date.getDay()]}\u060C ${date.getDate()}/${date.getMonth() + 1}/${date.getFullYear()}`;
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
        <div className="flex items-center gap-3 mb-4">
          <button onClick={onBack} className="p-2 bg-white/20 rounded-full backdrop-blur-sm hover:bg-white/30 transition-colors">
            <ChevronRight className="w-5 h-5 text-white" />
          </button>
          <h1 className="text-2xl">{isAmericano ? "\u062A\u0641\u0627\u0635\u064A\u0644 \u0623\u0645\u0631\u064A\u0643\u0627\u0646\u0648" : "\u062A\u0641\u0627\u0635\u064A\u0644 \u0627\u0644\u0645\u0628\u0627\u0631\u0627\u0629"}</h1>
        </div>
        <p className="text-white/80 text-sm">راجع التفاصيل قبل الانضمام</p>
      </div>

      <div className="px-6 py-6 space-y-5">
        {
    /* تنبيه التعارض الزمني */
  }
        {timeConflict && <div className="bg-red-50 border-2 border-red-200 rounded-2xl p-4 flex items-start gap-3">
            <AlertCircle className="w-5 h-5 text-red-500 flex-shrink-0 mt-0.5" />
            <div>
              <h3 className="text-red-700 font-medium mb-1">تعارض في المواعيد</h3>
              <p className="text-red-600 text-sm">{timeConflict}</p>
              <p className="text-red-600 text-sm mt-1">لا يمكنك الانضمام لمباراة أخرى في نفس الوقت ± ساعتين</p>
            </div>
          </div>}

        {
    /* معلومات المباراة الأساسية */
  }
        <div className="bg-white border border-border rounded-2xl p-5 shadow-sm">
          <div className="mb-4 pb-4 border-b border-border">
            <div className="flex items-center justify-between mb-2">
              <span className="px-3 py-1 bg-primary/10 text-primary text-xs rounded-full">
                {match.matchType}
              </span>
              <span className="text-sm text-secondary">
                {match.currentPlayers}/{match.maxPlayers} لاعبين
              </span>
            </div>
            {match.matchType === "\u0648\u062F\u064A\u0629 \u0641\u0631\u062F\u064A" && <p className="text-xs text-muted-foreground mt-2 bg-blue-50 border border-blue-200 rounded-lg p-2">
                🎾 مباراة فردية - كل لاعب يلعب لوحده ضد الآخرين (4 لاعبين)
              </p>}
          </div>

          <div className="space-y-4">
            {
    /* الموقع */
  }
            <div className="flex items-start gap-3">
              <MapPin className="w-5 h-5 text-primary flex-shrink-0 mt-0.5" />
              <div className="flex-1">
                <p className="text-secondary font-medium">{match.courtName}</p>
                <p className="text-sm text-muted-foreground">{match.location} • {match.distance}</p>
              </div>
            </div>

            {
    /* التاريخ */
  }
            <div className="flex items-start gap-3">
              <Calendar className="w-5 h-5 text-primary flex-shrink-0 mt-0.5" />
              <div className="flex-1">
                <p className="text-secondary font-medium">{formatDate(match.date)}</p>
              </div>
            </div>

            {
    /* الوقت والمدة */
  }
            <div className="flex items-start gap-3">
              <Clock className="w-5 h-5 text-primary flex-shrink-0 mt-0.5" />
              <div className="flex-1">
                <p className="text-secondary font-medium">{formatTime(match.time)}</p>
                <p className="text-sm text-muted-foreground">المدة: {match.duration} دقيقة</p>
              </div>
            </div>

            {
    /* المستوى */
  }
            <div className="flex items-start gap-3">
              <TrendingUp className="w-5 h-5 text-primary flex-shrink-0 mt-0.5" />
              <div className="flex-1">
                <p className="text-secondary font-medium">المستوى المطلوب</p>
                <p className="text-sm text-muted-foreground">{match.minLevel} - {match.maxLevel}</p>
              </div>
            </div>

            {
    /* عدد اللاعبين */
  }
            <div className="flex items-start gap-3">
              <Users className="w-5 h-5 text-primary flex-shrink-0 mt-0.5" />
              <div className="flex-1">
                <p className="text-secondary font-medium">اللاعبين الحاليين</p>
                <p className="text-sm text-muted-foreground">{match.currentPlayers} من {match.maxPlayers} • متبقي {match.maxPlayers - match.currentPlayers}</p>
              </div>
            </div>

            {
    /* التكلفة */
  }
            <div className="flex items-start gap-3">
              <DollarSign className="w-5 h-5 text-primary flex-shrink-0 mt-0.5" />
              <div className="flex-1">
                <p className="text-secondary font-medium">التكلفة لكل لاعب</p>
                <p className="text-sm text-muted-foreground">{match.costPerPlayer} ر.س</p>
              </div>
            </div>

            {
    /* معلومات أمريكانو الإضافية */
  }
            {isAmericano && <>
                {match.rounds && <div className="flex items-start gap-3 pt-4 border-t border-border">
                    <TrendingUp className="w-5 h-5 text-primary flex-shrink-0 mt-0.5" />
                    <div className="flex-1">
                      <p className="text-secondary font-medium">عدد الجولات</p>
                      <p className="text-sm text-muted-foreground">{match.rounds} جولات</p>
                    </div>
                  </div>}
                {match.gender && <div className="flex items-start gap-3">
                    <Users className="w-5 h-5 text-primary flex-shrink-0 mt-0.5" />
                    <div className="flex-1">
                      <p className="text-secondary font-medium">الفئة المستهدفة</p>
                      <p className="text-sm text-muted-foreground">{match.gender}</p>
                    </div>
                  </div>}
              </>}
          </div>
        </div>

        {
    /* الفرق الحالية - أمريكانو فرق فقط */
  }
        {isAmericanoTeams && <div className="bg-white border border-border rounded-2xl overflow-hidden shadow-sm">
            <div className="px-5 py-3 bg-gray-50 border-b border-border flex items-center justify-between">
              <div className="flex items-center gap-2">
                <Users className="w-4 h-4 text-primary" />
                <p className="text-secondary text-sm">الفرق الحالية</p>
              </div>
              <span className="text-xs text-muted-foreground bg-primary/10 text-primary px-2.5 py-1 rounded-full">
                {registeredTeams.length} فريق من {match.maxPlayers / 2}
              </span>
            </div>
            <div className="divide-y divide-border">
              {registeredTeams.map((team, ti) => <div key={team.id} className="px-5 py-4 flex items-center gap-4">
                  <div className="w-6 h-6 bg-primary/10 rounded-full flex items-center justify-center flex-shrink-0">
                    <span className="text-xs text-primary">{ti + 1}</span>
                  </div>
                  {[team.player1, team.player2].map((p, pi) => <div key={pi} className="flex items-center gap-2 flex-1">
                      <div className={`w-9 h-9 bg-gradient-to-br ${p.color} rounded-full flex items-center justify-center flex-shrink-0`}>
                        <span className="text-white text-xs">{p.avatar}</span>
                      </div>
                      <div className="min-w-0">
                        <p className="text-secondary text-xs truncate">{p.name}</p>
                        <p className="text-primary text-xs">مستوى {p.level}</p>
                      </div>
                    </div>)}
                </div>)}
              {
    /* سطر "أنت + شريكك" */
  }
              <div className="px-5 py-4 flex items-center gap-4 bg-primary/5 border-t-2 border-dashed border-primary/30">
                <div className="w-6 h-6 bg-primary/20 rounded-full flex items-center justify-center flex-shrink-0">
                  <span className="text-xs text-primary">{registeredTeams.length + 1}</span>
                </div>
                <div className="flex items-center gap-2 flex-1">
                  <div className="w-9 h-9 bg-gradient-to-br from-primary to-primary/80 rounded-full flex items-center justify-center flex-shrink-0 border-2 border-primary/30">
                    <span className="text-white text-xs">أنت</span>
                  </div>
                  <p className="text-primary text-xs">أنت</p>
                </div>
                <div className="flex items-center gap-2 flex-1">
                  <div className="w-9 h-9 border-2 border-dashed border-primary/40 rounded-full flex items-center justify-center flex-shrink-0">
                    <span className="text-xs text-primary/50">+</span>
                  </div>
                  <p className="text-muted-foreground text-xs">شريكك</p>
                </div>
              </div>
            </div>
          </div>}

        {
    /* منظم المباراة */
  }
        <div className="bg-primary/5 border border-primary/20 rounded-2xl p-5">
          <h3 className="text-secondary font-medium mb-3 flex items-center gap-2">
            <span className="w-2 h-2 bg-primary rounded-full" />
            منظم المباراة
          </h3>
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="w-12 h-12 bg-gradient-to-br from-primary to-primary/80 rounded-full flex items-center justify-center">
                <span className="text-white font-medium">{match.organizerLevel}</span>
              </div>
              <div>
                <p className="text-secondary font-medium">{match.organizerName}</p>
                <p className="text-sm text-muted-foreground">مستوى {match.organizerLevel}</p>
              </div>
            </div>
            <button className="p-3 bg-primary/10 hover:bg-primary/20 rounded-xl transition-colors">
              <MessageCircle className="w-5 h-5 text-primary" />
            </button>
          </div>
        </div>

        {
    /* ملاحظات إضافية */
  }
        {match.notes && <div className="bg-white border border-border rounded-2xl p-5">
            <h3 className="text-secondary font-medium mb-2">ملاحظات المنظم</h3>
            <p className="text-sm text-muted-foreground leading-relaxed">{match.notes}</p>
          </div>}

        {
    /* عرض الزميل المختار أو تنبيه لاختيار زميل - للفرق فقط */
  }
        {match.matchType.includes("\u0641\u0631\u0642") && match.matchType !== "\u0623\u0645\u0631\u064A\u0643\u0627\u0646\u0648 \u0641\u0631\u062F\u064A" && <>
            {selectedTeammate ? <div className="bg-gradient-to-br from-green-50 to-green-100/50 border-2 border-green-300 rounded-2xl p-5">
                <div className="flex items-center gap-2 mb-3">
                  <CheckCircle className="w-5 h-5 text-green-600" />
                  <h3 className="text-secondary font-medium">زميلك في الفريق</h3>
                </div>
                <div className="flex items-center justify-between mb-3">
                  <div className="flex items-center gap-3">
                    <div className="w-14 h-14 bg-gradient-to-br from-primary to-primary/80 rounded-full flex items-center justify-center">
                      <span className="text-white text-lg font-medium">{selectedTeammate.level}</span>
                    </div>
                    <div>
                      <p className="text-secondary font-medium text-base">{selectedTeammate.name}</p>
                      <p className="text-xs text-muted-foreground">
                        مستوى {selectedTeammate.level} • {selectedTeammate.gamesPlayed} مباراة
                        {selectedTeammate.winRate && ` \u2022 \u0641\u0648\u0632 ${selectedTeammate.winRate}%`}
                      </p>
                    </div>
                  </div>
                  <button
    onClick={() => onNavigateToSelectTeammate && onNavigateToSelectTeammate()}
    className="px-4 py-2 bg-white border-2 border-primary text-primary rounded-xl text-sm hover:bg-primary hover:text-white transition-all"
  >
                    تغيير
                  </button>
                </div>
                <div className="bg-white rounded-xl p-3 text-xs text-muted-foreground flex items-center gap-2">
                  <div className="w-6 h-6 bg-green-500/10 rounded-full flex items-center justify-center flex-shrink-0">
                    <UserPlus className="w-3 h-3 text-green-600" />
                  </div>
                  <span>سيتم إرسال إشعار لـ {selectedTeammate.name} للموافقة وإكمال الدفع</span>
                </div>
              </div> : <div className="bg-gradient-to-br from-blue-50 to-blue-100/50 border-2 border-blue-200 rounded-2xl p-5">
                <div className="flex items-start gap-3">
                  <div className="w-10 h-10 bg-blue-500 rounded-full flex items-center justify-center flex-shrink-0">
                    <UserPlus className="w-5 h-5 text-white" />
                  </div>
                  <div>
                    <h3 className="text-secondary font-medium mb-2">اختيار زميل</h3>
                    <p className="text-sm text-muted-foreground leading-relaxed">
                      ستتمكن من اختيار زميلك في الفريق. سيتم إرسال إشعار له للموافقة وإكمال الدفع.
                    </p>
                  </div>
                </div>
              </div>}
          </>}

        {
    /* دعوة أصدقاء - للأمريكانو الفردي والودية فردي وأمريكانو فرق */
  }
        {(isAmericano && americanoType === "\u0641\u0631\u062F\u064A" || match.matchType === "\u0648\u062F\u064A\u0629 \u0641\u0631\u062F\u064A" || isAmericanoTeams) && <div className="bg-gradient-to-br from-primary/5 to-primary/10 border-2 border-primary/25 rounded-2xl overflow-hidden">
            {
    /* رأس القسم */
  }
            <div className="px-5 py-4 flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-primary rounded-xl flex items-center justify-center">
                  <UserPlus className="w-5 h-5 text-white" />
                </div>
                <div>
                  <p className="text-secondary text-sm">
                    {isAmericanoTeams ? "\u062F\u0639\u0648\u0629 \u0641\u0631\u064A\u0642 \u0635\u062F\u064A\u0642 \u0644\u0644\u0627\u0646\u0636\u0645\u0627\u0645" : match.matchType === "\u0648\u062F\u064A\u0629 \u0641\u0631\u062F\u064A" ? "\u062F\u0639\u0648\u0629 \u0623\u0635\u062F\u0642\u0627\u0621 \u0644\u0644\u0645\u0628\u0627\u0631\u0627\u0629" : "\u062F\u0639\u0648\u0629 \u0623\u0635\u062F\u0642\u0627\u0621 \u0644\u0644\u0623\u0645\u0631\u064A\u0643\u0627\u0646\u0648"}
                  </p>
                  <p className="text-xs text-muted-foreground">
                    {invitedFriends.length > 0 ? isAmericanoTeams ? `${invitedFriends.length} \u0644\u0627\u0639\u0628 \u0645\u062F\u0639\u0648 \u2022 \u0633\u064A\u064F\u0634\u0643\u0651\u0644\u0648\u0646 \u0641\u0631\u0642\u0627\u064B` : `${invitedFriends.length} \u0635\u062F\u064A\u0642 \u0645\u062F\u0639\u0648 \u2022 \u0645\u062A\u0628\u0642\u064A ${spotsLeft - invitedFriends.length} \u0645\u0642\u0639\u062F` : isAmericanoTeams ? `\u062D\u062A\u0649 ${spotsLeft} \u0641\u0631\u064A\u0642 \u0625\u0636\u0627\u0641\u064A \u2022 \u0627\u062E\u062A\u064A\u0627\u0631\u064A` : `\u062D\u062A\u0649 ${spotsLeft} ${spotsLeft === 1 ? "\u0645\u0642\u0639\u062F \u0645\u062A\u0627\u062D" : "\u0623\u0635\u062F\u0642\u0627\u0621"} \u2022 \u0627\u062E\u062A\u064A\u0627\u0631\u064A`}
                  </p>
                </div>
              </div>
              <button
    onClick={() => setShowFriendsPicker(true)}
    className="px-3 py-1.5 bg-primary text-white text-xs rounded-lg"
  >
                {invitedFriends.length > 0 ? "\u062A\u0639\u062F\u064A\u0644" : "\u062F\u0639\u0648\u0629"}
              </button>
            </div>

            {
    /* الأصدقاء المدعوون */
  }
            {invitedFriends.length > 0 && <div className="border-t border-primary/20 px-5 py-3 space-y-2">
                {invitedFriends.map((id) => {
    const f = friendsList.find((fr) => fr.id === id);
    return <div key={id} className="flex items-center gap-3 bg-white rounded-xl px-3 py-2.5 shadow-sm">
                      <div className={`w-9 h-9 bg-gradient-to-br ${f.color} rounded-full flex items-center justify-center flex-shrink-0`}>
                        <span className="text-white text-xs">{f.avatar}</span>
                      </div>
                      <div className="flex-1">
                        <p className="text-secondary text-sm">{f.name}</p>
                        <p className="text-xs text-muted-foreground">مستوى {f.level} • ⏳ في انتظار القبول</p>
                      </div>
                      <button onClick={() => toggleInvite(id)} className="p-1 rounded-full bg-gray-100">
                        <X className="w-3.5 h-3.5 text-muted-foreground" />
                      </button>
                    </div>;
  })}
              </div>}

            {invitedFriends.length === 0 && <div className="border-t border-primary/20 px-5 py-3">
                <p className="text-xs text-muted-foreground text-center">
                  💡 الأصدقاء المدعوون سيحصلون على إشعار فوري ويمكنهم القبول أو الرفض
                </p>
              </div>}
          </div>}

        {
    /* قواعد الانضمام */
  }
        <div className="bg-gradient-to-br from-green-50 to-green-100/50 border border-green-200 rounded-2xl p-5">
          <h3 className="text-secondary font-medium mb-3 flex items-center gap-2">
            <CheckCircle className="w-5 h-5 text-green-600" />
            قواعد الانضمام
          </h3>
          <ul className="space-y-2 text-sm text-muted-foreground">
            <li className="flex items-start gap-2">
              <span className="text-green-600 mt-1">•</span>
              <span>لا يمكنك الانضمام لمباراة أخرى في نفس الوقت ± ساعتين</span>
            </li>
            {match.matchType === "\u0648\u062F\u064A\u0629 \u0641\u0631\u062F\u064A" && <>
                <li className="flex items-start gap-2">
                  <span className="text-green-600 mt-1">•</span>
                  <span>مباراة فردية - كل لاعب يلعب لوحده (4 لاعبين)</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-green-600 mt-1">•</span>
                  <span>يمكنك دعوة أصدقاء للانضمام (اختياري)</span>
                </li>
              </>}
            {match.matchType.includes("\u0641\u0631\u0642") && match.matchType !== "\u0623\u0645\u0631\u064A\u0643\u0627\u0646\u0648 \u0641\u0631\u062F\u064A" && <li className="flex items-start gap-2">
                <span className="text-green-600 mt-1">•</span>
                <span>كل الزملاء في نفس مستوى المباراة</span>
              </li>}
            {match.matchType.includes("\u0641\u0631\u0642") && match.matchType !== "\u0623\u0645\u0631\u064A\u0643\u0627\u0646\u0648 \u0641\u0631\u062F\u064A" && <li className="flex items-start gap-2">
                <span className="text-green-600 mt-1">•</span>
                <span>يجب اختيار زميل للفريق وانتظار موافقته</span>
              </li>}
            <li className="flex items-start gap-2">
              <span className="text-green-600 mt-1">•</span>
              <span>الدفع مطلوب قبل تأكيد الانضمام</span>
            </li>
            <li className="flex items-start gap-2">
              <span className="text-green-600 mt-1">•</span>
              <span>يمكن الإلغاء قبل 24 ساعة من موعد المباراة</span>
            </li>
          </ul>
        </div>

        {
    /* أزرار الإجراءات */
  }
        <div className="flex gap-3 pt-4">
          <button
    onClick={onBack}
    className="px-6 py-3 bg-gray-100 text-secondary rounded-xl"
  >
            رجوع
          </button>
          <button
    onClick={handleJoinClick}
    disabled={timeConflict !== null}
    className={`flex-1 py-3 rounded-xl shadow-lg transition-all ${timeConflict ? "bg-gray-300 text-gray-500 cursor-not-allowed" : "bg-gradient-to-r from-primary to-primary/90 text-white hover:shadow-xl"}`}
  >
            {timeConflict ? "\u063A\u064A\u0631 \u0645\u062A\u0627\u062D" : match.matchType.includes("\u0641\u0631\u0642") && match.matchType !== "\u0623\u0645\u0631\u064A\u0643\u0627\u0646\u0648 \u0641\u0631\u062F\u064A" && !selectedTeammate ? "\u0627\u062E\u062A\u0631 \u0632\u0645\u064A\u0644 \u0644\u0644\u0645\u062A\u0627\u0628\u0639\u0629" : match.matchType === "\u0648\u062F\u064A\u0629 \u0641\u0631\u062F\u064A" ? selectedTeammate ? "\u0627\u0646\u0636\u0645 \u0648\u0623\u0631\u0633\u0644 \u0627\u0644\u062F\u0639\u0648\u0629" : "\u0627\u0646\u0636\u0645 \u0627\u0644\u0622\u0646" : "\u0627\u0646\u0636\u0645 \u0627\u0644\u0622\u0646"}
          </button>
        </div>
      </div>

      {
    /* شيت اختيار الأصدقاء */
  }
      {showFriendsPicker && <div className="fixed inset-0 z-50 flex items-end justify-center" style={{ maxWidth: "430px", margin: "0 auto", left: 0, right: 0 }}>
          <div className="absolute inset-0 bg-black/50 backdrop-blur-sm" onClick={() => setShowFriendsPicker(false)} />
          <div className="relative bg-white rounded-t-3xl w-full max-h-[85vh] flex flex-col shadow-2xl">

            {
    /* رأس ثابت */
  }
            <div className="px-5 pt-5 pb-4 border-b border-border flex-shrink-0">
              <div className="flex items-center justify-between mb-3">
                <div>
                  <h3 className="text-secondary">ادعُ أصدقاءك</h3>
                  <p className="text-xs text-muted-foreground">
                    {invitedFriends.length}/{spotsLeft} مدعو • يمكنك اختيار حتى {spotsLeft}
                  </p>
                </div>
                <button onClick={() => setShowFriendsPicker(false)} className="p-2 rounded-full bg-gray-100">
                  <X className="w-4 h-4 text-secondary" />
                </button>
              </div>

              {
    /* شريط البحث */
  }
              <div className="relative">
                <Search className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
                <input
    value={friendSearch}
    onChange={(e) => setFriendSearch(e.target.value)}
    placeholder="ابحث عن صديق..."
    className="w-full border border-border rounded-xl py-2.5 pr-10 pl-4 text-sm outline-none focus:border-primary text-secondary"
  />
              </div>

              {
    /* الأصدقاء المختارون */
  }
              {invitedFriends.length > 0 && <div className="flex gap-2 mt-3 overflow-x-auto pb-1">
                  {invitedFriends.map((id) => {
    const f = friendsList.find((fr) => fr.id === id);
    return <div key={id} className="flex-shrink-0 flex flex-col items-center gap-1">
                        <div className="relative">
                          <div className={`w-10 h-10 bg-gradient-to-br ${f.color} rounded-full flex items-center justify-center`}>
                            <span className="text-white text-xs">{f.avatar}</span>
                          </div>
                          <button
      onClick={() => toggleInvite(id)}
      className="absolute -top-1 -left-1 w-4 h-4 bg-red-500 rounded-full flex items-center justify-center"
    >
                            <X className="w-2.5 h-2.5 text-white" />
                          </button>
                        </div>
                        <span className="text-xs text-muted-foreground w-12 text-center truncate">{f.name.split(" ")[0]}</span>
                      </div>;
  })}
                </div>}
            </div>

            {
    /* قائمة الأصدقاء */
  }
            <div className="flex-1 overflow-y-auto px-5 py-3 space-y-2">
              {filteredFriends.map((f) => {
    const invited = invitedFriends.includes(f.id);
    const disabled = !invited && invitedFriends.length >= spotsLeft;
    return <button
      key={f.id}
      onClick={() => !disabled && toggleInvite(f.id)}
      disabled={disabled}
      className={`w-full flex items-center gap-3 p-3.5 rounded-2xl border-2 transition-all text-right ${invited ? "bg-primary/10 border-primary shadow-sm" : disabled ? "bg-gray-50 border-gray-200 opacity-50 cursor-not-allowed" : "bg-white border-border hover:border-primary/40"}`}
    >
                    {
      /* صورة الصديق */
    }
                    <div className="relative flex-shrink-0">
                      <div className={`w-12 h-12 bg-gradient-to-br ${f.color} rounded-full flex items-center justify-center`}>
                        <span className="text-white text-sm">{f.avatar}</span>
                      </div>
                      <div className={`absolute bottom-0 left-0 w-3 h-3 rounded-full border-2 border-white ${f.status === "online" ? "bg-green-500" : "bg-gray-400"}`} />
                    </div>

                    {
      /* معلومات الصديق */
    }
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-0.5">
                        <p className="text-secondary text-sm truncate">{f.name}</p>
                        {f.status === "online" && <span className="text-xs text-green-600 bg-green-50 px-1.5 py-0.5 rounded-full flex-shrink-0">متصل</span>}
                      </div>
                      <div className="flex items-center gap-3 text-xs text-muted-foreground">
                        <span>مستوى {f.level}</span>
                        <span>•</span>
                        <span>{f.gamesPlayed} مباراة</span>
                        <span>•</span>
                        <span className="flex items-center gap-0.5">
                          <Star className="w-3 h-3 text-yellow-400 fill-yellow-400" />{f.winRate}%
                        </span>
                      </div>
                    </div>

                    {
      /* زر الدعوة */
    }
                    <div className={`w-7 h-7 rounded-full border-2 flex-shrink-0 flex items-center justify-center transition-all ${invited ? "bg-primary border-primary" : "border-border"}`}>
                      {invited ? <CheckCircle className="w-5 h-5 text-white" /> : <UserPlus className="w-3.5 h-3.5 text-muted-foreground" />}
                    </div>
                  </button>;
  })}
            </div>

            {
    /* زر التأكيد */
  }
            <div className="flex-shrink-0 border-t border-border px-5 py-4">
              <button
    onClick={() => setShowFriendsPicker(false)}
    className={`w-full py-4 rounded-xl flex items-center justify-center gap-2 transition-all text-sm ${invitedFriends.length > 0 ? "bg-primary text-white shadow-md" : "bg-gray-100 text-secondary"}`}
  >
                <Send className="w-4 h-4" />
                {invitedFriends.length > 0 ? `\u062A\u0623\u0643\u064A\u062F \u062F\u0639\u0648\u0629 ${invitedFriends.length} ${invitedFriends.length === 1 ? "\u0635\u062F\u064A\u0642" : "\u0623\u0635\u062F\u0642\u0627\u0621"}` : "\u0645\u062A\u0627\u0628\u0639\u0629 \u0628\u062F\u0648\u0646 \u062F\u0639\u0648\u0629"}
              </button>
            </div>
          </div>
        </div>}

      {
    /* نافذة التأكيد */
  }
      {showConfirmation && <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center p-6 z-50">
          <div className="bg-white rounded-3xl p-6 max-w-sm w-full shadow-2xl">
            <div className="flex justify-center mb-4">
              <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center">
                <CheckCircle className="w-8 h-8 text-green-600" />
              </div>
            </div>

            <h3 className="text-xl text-secondary text-center mb-2">تأكيد الانضمام</h3>
            <p className="text-sm text-muted-foreground text-center mb-6">
              {(isAmericano && americanoType === "\u0641\u0631\u062F\u064A" || match.matchType === "\u0648\u062F\u064A\u0629 \u0641\u0631\u062F\u064A" || isAmericanoTeams) && invitedFriends.length > 0 ? isAmericanoTeams ? `\u0633\u064A\u062A\u0645 \u0627\u0646\u0636\u0645\u0627\u0645\u0643 \u0648\u0625\u0631\u0633\u0627\u0644 \u062F\u0639\u0648\u0629 \u0644\u0640 ${invitedFriends.length} \u0644\u0627\u0639\u0628 \u0644\u062A\u0634\u0643\u064A\u0644 \u0641\u0631\u0642` : `\u0633\u064A\u062A\u0645 \u0627\u0646\u0636\u0645\u0627\u0645\u0643 \u0648\u0625\u0631\u0633\u0627\u0644 \u062F\u0639\u0648\u0629 \u0644\u0640 ${invitedFriends.length} ${invitedFriends.length === 1 ? "\u0635\u062F\u064A\u0642" : "\u0623\u0635\u062F\u0642\u0627\u0621"}` : selectedTeammate ? `\u0647\u0644 \u0623\u0646\u062A \u0645\u062A\u0623\u0643\u062F \u0645\u0646 \u0627\u0644\u0627\u0646\u0636\u0645\u0627\u0645 \u0645\u0639 ${selectedTeammate.name}\u061F` : "\u0647\u0644 \u0623\u0646\u062A \u0645\u062A\u0623\u0643\u062F \u0645\u0646 \u0627\u0644\u0627\u0646\u0636\u0645\u0627\u0645 \u0644\u0647\u0630\u0647 \u0627\u0644\u0645\u0628\u0627\u0631\u0627\u0629\u061F"}
            </p>

            <div className="bg-gray-50 rounded-xl p-4 mb-6 space-y-2 text-sm">
              <div className="flex justify-between">
                <span className="text-muted-foreground">المباراة:</span>
                <span className="text-secondary font-medium">{match.courtName}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">التاريخ:</span>
                <span className="text-secondary">{formatDate(match.date)}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">الوقت:</span>
                <span className="text-secondary">{formatTime(match.time)}</span>
              </div>
              {(isAmericano && americanoType === "\u0641\u0631\u062F\u064A" || match.matchType === "\u0648\u062F\u064A\u0629 \u0641\u0631\u062F\u064A" || isAmericanoTeams) && invitedFriends.length > 0 && <>
                  <div className="h-px bg-gray-200 my-2" />
                  <div className="flex items-start justify-between gap-2">
                    <span className="text-muted-foreground flex-shrink-0">الأصدقاء المدعوون:</span>
                    <div className="flex flex-wrap gap-1 justify-end">
                      {invitedFriends.map((id) => {
    const f = friendsList.find((fr) => fr.id === id);
    return <span key={id} className="text-xs bg-primary/10 text-primary px-2 py-0.5 rounded-full">
                            {f.name.split(" ")[0]}
                          </span>;
  })}
                    </div>
                  </div>
                </>}
              {selectedTeammate && !(isAmericano && americanoType === "\u0641\u0631\u062F\u064A") && <>
                  <div className="h-px bg-gray-200 my-2" />
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">زميلك:</span>
                    <span className="text-primary font-medium">{selectedTeammate.name}</span>
                  </div>
                </>}
              <div className="h-px bg-gray-200 my-2" />
              <div className="flex justify-between">
                <span className="text-muted-foreground">التكلفة:</span>
                <span className="text-green-600 font-medium">{match.costPerPlayer} ر.س</span>
              </div>
              {selectedTeammate && <p className="text-xs text-muted-foreground mt-2">
                  * سيقوم {selectedTeammate.name} بدفع حصته ({match.costPerPlayer} ر.س)
                  {match.matchType === "\u0648\u062F\u064A\u0629 \u0641\u0631\u062F\u064A" ? " \u0639\u0646\u062F \u0642\u0628\u0648\u0644 \u0627\u0644\u062F\u0639\u0648\u0629 \u0648\u0627\u0644\u0627\u0646\u0636\u0645\u0627\u0645" : " \u0628\u0639\u062F \u0627\u0644\u0645\u0648\u0627\u0641\u0642\u0629"}
                </p>}
            </div>

            <div className="flex gap-3">
              <button
    onClick={() => setShowConfirmation(false)}
    className="flex-1 py-3 bg-gray-100 text-secondary rounded-xl"
  >
                إلغاء
              </button>
              <button
    onClick={handleConfirmJoin}
    className="flex-1 py-3 bg-gradient-to-r from-primary to-primary/90 text-white rounded-xl shadow-lg"
  >
                تأكيد الانضمام
              </button>
            </div>
          </div>
        </div>}
    </div>;
}
export {
  JoinMatchPage as default
};
