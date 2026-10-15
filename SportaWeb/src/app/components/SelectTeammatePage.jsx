import { useState } from "react";
import { ChevronRight, UserPlus, Search, CheckCircle, Users, Star, TrendingUp, X, Clock } from "lucide-react";
import Tooltip from "./Tooltip";
const availablePlayers = [
  { id: "1", name: "\u0645\u062D\u0645\u062F \u0627\u0644\u0639\u062A\u064A\u0628\u064A", level: "5.2", gamesPlayed: 45, winRate: 68, status: "online" },
  { id: "2", name: "\u0641\u0647\u062F \u0627\u0644\u062F\u0648\u0633\u0631\u064A", level: "5.8", gamesPlayed: 62, winRate: 72, status: "online" },
  { id: "3", name: "\u0633\u0639\u0648\u062F \u0627\u0644\u0642\u062D\u0637\u0627\u0646\u064A", level: "5.5", gamesPlayed: 38, winRate: 65, status: "offline" },
  { id: "4", name: "\u0639\u0628\u062F\u0627\u0644\u0644\u0647 \u0627\u0644\u0633\u0627\u0644\u0645", level: "6.0", gamesPlayed: 71, winRate: 75, status: "online" },
  { id: "5", name: "\u062E\u0627\u0644\u062F \u0627\u0644\u0645\u0637\u064A\u0631\u064A", level: "5.3", gamesPlayed: 29, winRate: 61, status: "offline" },
  { id: "6", name: "\u0646\u0627\u0635\u0631 \u0627\u0644\u0634\u0645\u0631\u064A", level: "5.7", gamesPlayed: 54, winRate: 70, status: "online" },
  { id: "7", name: "\u0639\u0644\u064A \u0627\u0644\u063A\u0627\u0645\u062F\u064A", level: "5.4", gamesPlayed: 33, winRate: 63, status: "offline" },
  { id: "8", name: "\u0633\u0644\u0637\u0627\u0646 \u0627\u0644\u0639\u0646\u0632\u064A", level: "5.9", gamesPlayed: 58, winRate: 74, status: "online" }
];
function SelectTeammatePage({ onBack, onComplete, matchDetails, matchType }) {
  const isFriendlyIndividual = matchType === "\u0648\u062F\u064A\u0629 \u0641\u0631\u062F\u064A";
  const [selectedTeammate, setSelectedTeammate] = useState(null);
  const [searchQuery, setSearchQuery] = useState("");
  const [showConfirmation, setShowConfirmation] = useState(false);
  const [filterOnlineOnly, setFilterOnlineOnly] = useState(false);
  const [sortBy, setSortBy] = useState("level");
  const [requestDuration, setRequestDuration] = useState(24);
  const [showCustomInput, setShowCustomInput] = useState(false);
  const [customDuration, setCustomDuration] = useState("");
  const handleTeammateSelect = (player) => {
    setSelectedTeammate(player);
  };
  const handleSendInvitation = () => {
    if (selectedTeammate) {
      setShowConfirmation(true);
      setTimeout(() => {
        if (onComplete) {
          onComplete(selectedTeammate, requestDuration);
        }
      }, 2e3);
    }
  };
  const filteredPlayers = availablePlayers.filter((player) => {
    const playerLevel = parseFloat(player.level);
    const minLevel = matchDetails ? parseFloat(matchDetails.minLevel) : 0;
    const maxLevel = matchDetails ? parseFloat(matchDetails.maxLevel) : 10;
    const matchesSearch = player.name.includes(searchQuery) || player.level.includes(searchQuery);
    const matchesOnlineFilter = !filterOnlineOnly || player.status === "online";
    const matchesLevelRange = playerLevel >= minLevel && playerLevel <= maxLevel;
    return matchesSearch && matchesOnlineFilter && matchesLevelRange;
  }).sort((a, b) => {
    if (sortBy === "level") return parseFloat(b.level) - parseFloat(a.level);
    if (sortBy === "winRate") return b.winRate - a.winRate;
    if (sortBy === "games") return b.gamesPlayed - a.gamesPlayed;
    return 0;
  });
  return <div className="flex-1 overflow-y-auto bg-background">
      {
    /* Header */
  }
      <div className="bg-gradient-to-br from-secondary to-secondary/90 text-white px-6 pt-8 pb-6">
        <div className="flex items-center gap-3 mb-4">
          <button onClick={onBack} className="p-2 bg-white/20 rounded-full backdrop-blur-sm hover:bg-white/30 transition-colors">
            <ChevronRight className="w-5 h-5 text-white" />
          </button>
          <h1 className="text-2xl">
            {isFriendlyIndividual ? "\u062F\u0639\u0648\u0629 \u0635\u062F\u064A\u0642 \u0644\u0644\u0627\u0646\u0636\u0645\u0627\u0645" : "\u0627\u062E\u062A\u0631 \u0632\u0645\u064A\u0644 \u0644\u0644\u0645\u062A\u0627\u0628\u0639\u0629"}
          </h1>
        </div>
        <p className="text-white/80 text-sm">
          {isFriendlyIndividual ? "\u0627\u062E\u062A\u0631 \u0635\u062F\u064A\u0642 \u0644\u0625\u0631\u0633\u0627\u0644 \u062F\u0639\u0648\u0629 \u0644\u0644\u0627\u0646\u0636\u0645\u0627\u0645 \u0644\u0644\u0645\u0628\u0627\u0631\u0627\u0629" : "\u0627\u062E\u062A\u0631 \u0632\u0645\u064A\u0644\u0643 \u0641\u064A \u0627\u0644\u0641\u0631\u064A\u0642 \u0648\u0623\u0631\u0633\u0644 \u0644\u0647 \u062F\u0639\u0648\u0629"}
        </p>
      </div>

      <div className="px-6 py-6 space-y-5">
        {
    /* تعليمات سريعة */
  }
        <div className="bg-gradient-to-br from-primary/10 to-primary/5 border-2 border-primary/30 rounded-2xl p-4">
          <div className="flex items-start gap-3">
            <div className="w-10 h-10 bg-primary rounded-full flex items-center justify-center flex-shrink-0">
              <UserPlus className="w-5 h-5 text-white" />
            </div>
            <div className="flex-1">
              <h3 className="text-secondary font-medium mb-2">
                {isFriendlyIndividual ? "\u062F\u0639\u0648\u0629 \u0627\u062E\u062A\u064A\u0627\u0631\u064A\u0629 \u0644\u0644\u0623\u0635\u062F\u0642\u0627\u0621" : "\u0643\u0644 \u0627\u0644\u0632\u0645\u0644\u0627\u0621 \u0641\u064A \u0646\u0641\u0633 \u0645\u0633\u062A\u0648\u0649 \u0627\u0644\u0645\u0628\u0627\u0631\u0627\u0629"}
              </h3>
              <p className="text-sm text-muted-foreground mb-3">
                {matchDetails && `\u0627\u0644\u0645\u0633\u062A\u0648\u0649 \u0627\u0644\u0645\u0637\u0644\u0648\u0628: ${matchDetails.minLevel} - ${matchDetails.maxLevel}`}
              </p>
              <ul className="space-y-1 text-sm text-muted-foreground">
                <li className="flex items-start gap-2">
                  <span className="text-primary mt-0.5">•</span>
                  <span>
                    {isFriendlyIndividual ? "\u0627\u062E\u062A\u0631 \u0635\u062F\u064A\u0642 \u0645\u0646 \u0627\u0644\u0642\u0627\u0626\u0645\u0629 \u0644\u062F\u0639\u0648\u062A\u0647" : "\u0627\u062E\u062A\u0631 \u0632\u0645\u064A\u0644\u0643 \u0645\u0646 \u0627\u0644\u0642\u0627\u0626\u0645\u0629 \u0623\u062F\u0646\u0627\u0647"}
                  </span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-primary mt-0.5">•</span>
                  <span>سيتم إرسال إشعار له فوراً</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-primary mt-0.5">•</span>
                  <span>يجب أن يوافق خلال المدة المحددة ويكمل الدفع</span>
                </li>
              </ul>
            </div>
          </div>
        </div>

        {
    /* اختيار مدة العرض */
  }
        <div className="bg-white border-2 border-border rounded-2xl p-4">
          <Tooltip content="المدة التي يجب على الزميل الموافقة خلالها" position="top">
            <h3 className="text-secondary font-medium mb-3 flex items-center gap-2 cursor-help">
              <Clock className="w-5 h-5 text-primary" />
              مدة العرض للموافقة
            </h3>
          </Tooltip>

          {
    /* الخيارات السريعة */
  }
          <div className="grid grid-cols-5 gap-2 mb-3">
            {[1, 6, 12, 24, 48].map((hours) => <button
    key={hours}
    onClick={() => {
      setRequestDuration(hours);
      setShowCustomInput(false);
      setCustomDuration("");
    }}
    className={`py-2.5 px-2 rounded-xl border-2 transition-all text-center ${requestDuration === hours && !showCustomInput ? "border-primary bg-primary text-white" : "border-border bg-white text-secondary hover:border-primary/50"}`}
  >
                <div className="text-sm font-medium">{hours}</div>
                <div className="text-xs mt-0.5 opacity-80">
                  {hours === 1 ? "\u0633\u0627\u0639\u0629" : "\u0633"}
                </div>
              </button>)}
          </div>

          {
    /* زر الإدخال المخصص */
  }
          {!showCustomInput ? <button
    onClick={() => setShowCustomInput(true)}
    className="w-full py-2.5 border-2 border-dashed border-primary/30 rounded-xl text-primary text-sm hover:bg-primary/5 transition-all"
  >
              + مدة مخصصة
            </button> : <div className="space-y-2">
              <div className="flex gap-2">
                <input
    type="number"
    min="1"
    max="48"
    value={customDuration}
    onChange={(e) => {
      const value = e.target.value;
      setCustomDuration(value);
      if (value && parseInt(value) >= 1 && parseInt(value) <= 48) {
        setRequestDuration(parseInt(value));
      }
    }}
    placeholder="أدخل عدد الساعات"
    className="flex-1 px-4 py-2.5 border-2 border-primary rounded-xl outline-none text-secondary text-center"
  />
                <button
    onClick={() => {
      setShowCustomInput(false);
      setCustomDuration("");
      setRequestDuration(24);
    }}
    className="px-4 py-2.5 bg-gray-100 text-secondary rounded-xl hover:bg-gray-200 transition-colors"
  >
                  <X className="w-4 h-4" />
                </button>
              </div>
              <p className="text-xs text-muted-foreground text-center">
                من 1 إلى 48 ساعة
              </p>
            </div>}

          <p className="text-xs text-muted-foreground mt-3 text-center">
            سيتلقى زميلك إشعاراً ويجب عليه الموافقة خلال {requestDuration} {requestDuration === 1 ? "\u0633\u0627\u0639\u0629" : "\u0633\u0627\u0639\u0627\u062A"}
          </p>
        </div>

        {
    /* البحث والفلترة */
  }
        <div className="space-y-3">
          {
    /* البحث */
  }
          <div className="relative">
            <Search className="absolute right-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
            <input
    type="text"
    placeholder="ابحث بالاسم أو المستوى..."
    value={searchQuery}
    onChange={(e) => setSearchQuery(e.target.value)}
    className="w-full bg-white border border-border rounded-xl py-3 pr-11 pl-4 outline-none focus:border-primary transition-colors"
  />
            {searchQuery && <button
    onClick={() => setSearchQuery("")}
    className="absolute left-3 top-1/2 -translate-y-1/2 p-1 hover:bg-gray-100 rounded-full"
  >
                <X className="w-4 h-4 text-gray-400" />
              </button>}
          </div>

          {
    /* الفلاتر */
  }
          <div className="flex gap-2 overflow-x-auto pb-1">
            <Tooltip content="إظهار اللاعبين المتصلين فقط" position="bottom">
              <button
    onClick={() => setFilterOnlineOnly(!filterOnlineOnly)}
    className={`px-4 py-2 rounded-full text-sm whitespace-nowrap flex-shrink-0 border-2 transition-all ${filterOnlineOnly ? "border-primary bg-primary text-white" : "border-border bg-white text-secondary"}`}
  >
                <span className={`inline-block w-2 h-2 rounded-full ml-2 ${filterOnlineOnly ? "bg-white" : "bg-green-500"}`} />
                متصل فقط
              </button>
            </Tooltip>
            <Tooltip content="ترتيب حسب المستوى الأعلى" position="bottom">
              <button
    onClick={() => setSortBy("level")}
    className={`px-4 py-2 rounded-full text-sm whitespace-nowrap flex-shrink-0 border-2 transition-all ${sortBy === "level" ? "border-primary bg-primary text-white" : "border-border bg-white text-secondary"}`}
  >
                <TrendingUp className="w-4 h-4 inline ml-1" />
                أعلى مستوى
              </button>
            </Tooltip>
            <Tooltip content="ترتيب حسب نسبة الفوز الأعلى" position="bottom">
              <button
    onClick={() => setSortBy("winRate")}
    className={`px-4 py-2 rounded-full text-sm whitespace-nowrap flex-shrink-0 border-2 transition-all ${sortBy === "winRate" ? "border-primary bg-primary text-white" : "border-border bg-white text-secondary"}`}
  >
                <Star className="w-4 h-4 inline ml-1" />
                أعلى فوز
              </button>
            </Tooltip>
            <Tooltip content="ترتيب حسب عدد المباريات" position="bottom">
              <button
    onClick={() => setSortBy("games")}
    className={`px-4 py-2 rounded-full text-sm whitespace-nowrap flex-shrink-0 border-2 transition-all ${sortBy === "games" ? "border-primary bg-primary text-white" : "border-border bg-white text-secondary"}`}
  >
                <Users className="w-4 h-4 inline ml-1" />
                الأكثر لعباً
              </button>
            </Tooltip>
          </div>
        </div>

        {
    /* عداد النتائج */
  }
        <div className="flex items-center justify-between">
          <h3 className="text-secondary font-medium">
            اللاعبين المتاحين ({filteredPlayers.length})
          </h3>
          {selectedTeammate && <span className="text-xs text-primary bg-primary/10 px-3 py-1 rounded-full">
              تم الاختيار
            </span>}
        </div>

        {
    /* قائمة اللاعبين */
  }
        <div className="space-y-3">
          {filteredPlayers.map((player) => <button
    key={player.id}
    onClick={() => handleTeammateSelect(player)}
    className={`w-full p-4 rounded-2xl border-2 transition-all text-right relative overflow-hidden ${selectedTeammate?.id === player.id ? "border-primary bg-primary/5 shadow-lg scale-[1.02]" : "border-border bg-white hover:border-primary/50 hover:shadow-md"}`}
  >
              {
    /* حالة الاتصال */
  }
              {player.status === "online" && <Tooltip content="اللاعب متصل الآن ويمكنه الرد بسرعة" position="left">
                  <div className="absolute top-2 left-2">
                    <div className="flex items-center gap-1 bg-green-100 text-green-600 px-2 py-1 rounded-full text-xs cursor-help">
                      <span className="w-1.5 h-1.5 bg-green-500 rounded-full animate-pulse" />
                      متصل
                    </div>
                  </div>
                </Tooltip>}

              <div className="flex items-center gap-3 mb-3">
                <div className="relative">
                  <div className="w-16 h-16 bg-gradient-to-br from-primary to-primary/80 rounded-full flex items-center justify-center">
                    <span className="text-white text-xl font-medium">{player.level}</span>
                  </div>
                  {selectedTeammate?.id === player.id && <div className="absolute -bottom-1 -right-1 w-6 h-6 bg-primary rounded-full flex items-center justify-center border-2 border-white">
                      <CheckCircle className="w-4 h-4 text-white" />
                    </div>}
                </div>
                <div className="flex-1 text-right">
                  <p className="text-secondary font-medium text-base">{player.name}</p>
                  <div className="flex items-center gap-2 mt-1 text-xs text-muted-foreground">
                    <span className="flex items-center gap-1">
                      <TrendingUp className="w-3 h-3" />
                      مستوى {player.level}
                    </span>
                    <span>•</span>
                    <span>{player.gamesPlayed} مباراة</span>
                  </div>
                </div>
              </div>

              {
    /* الإحصائيات */
  }
              <div className="bg-gray-50 rounded-xl p-2 flex items-center justify-around">
                <Tooltip content="نسبة المباريات المكسوبة" position="top">
                  <div className="text-center cursor-help">
                    <p className="text-xs text-muted-foreground">نسبة الفوز</p>
                    <p className="text-sm font-medium text-green-600">{player.winRate}%</p>
                  </div>
                </Tooltip>
                <div className="w-px h-8 bg-border" />
                <Tooltip content="تقييم اللاعب من المباريات السابقة" position="top">
                  <div className="text-center cursor-help">
                    <p className="text-xs text-muted-foreground">التقييم</p>
                    <div className="flex items-center gap-0.5">
                      <Star className="w-3 h-3 text-yellow-400 fill-yellow-400" />
                      <p className="text-sm font-medium text-secondary">{(Math.random() * 2 + 3).toFixed(1)}</p>
                    </div>
                  </div>
                </Tooltip>
                <div className="w-px h-8 bg-border" />
                <Tooltip content="عدد المباريات التي شارك فيها" position="top">
                  <div className="text-center cursor-help">
                    <p className="text-xs text-muted-foreground">المباريات</p>
                    <p className="text-sm font-medium text-secondary">{player.gamesPlayed}</p>
                  </div>
                </Tooltip>
              </div>
            </button>)}

          {filteredPlayers.length === 0 && <div className="text-center py-16">
              <Users className="w-20 h-20 text-gray-300 mx-auto mb-4" />
              <p className="text-base text-secondary mb-1">لا يوجد لاعبين</p>
              <p className="text-sm text-muted-foreground">جرب تغيير الفلاتر أو البحث</p>
            </div>}
        </div>

        {
    /* اللاعب المختار */
  }
        {selectedTeammate && <div className="bg-gradient-to-br from-green-50 to-green-100/50 border-2 border-green-300 rounded-2xl p-5 sticky bottom-20">
            <div className="flex items-center gap-2 mb-3">
              <CheckCircle className="w-5 h-5 text-green-600" />
              <h3 className="text-secondary font-medium">الزميل المختار</h3>
            </div>
            <div className="flex items-center gap-3 mb-3">
              <div className="w-12 h-12 bg-gradient-to-br from-primary to-primary/80 rounded-full flex items-center justify-center">
                <span className="text-white font-medium">{selectedTeammate.level}</span>
              </div>
              <div className="flex-1">
                <p className="text-secondary font-medium">{selectedTeammate.name}</p>
                <p className="text-xs text-muted-foreground">مستوى {selectedTeammate.level} • نسبة فوز {selectedTeammate.winRate}%</p>
              </div>
              <button
    onClick={() => setSelectedTeammate(null)}
    className="p-2 hover:bg-white rounded-lg transition-colors"
  >
                <X className="w-4 h-4 text-muted-foreground" />
              </button>
            </div>
            <div className="bg-white rounded-xl p-3 space-y-2">
              <div className="flex items-center gap-2 text-xs text-muted-foreground">
                <div className="w-5 h-5 bg-primary/10 rounded-full flex items-center justify-center flex-shrink-0">
                  <UserPlus className="w-3 h-3 text-primary" />
                </div>
                <span>سيتم إرسال إشعار لـ {selectedTeammate.name} للموافقة وإكمال الدفع</span>
              </div>
              <div className="flex items-center gap-2 text-xs text-muted-foreground">
                <div className="w-5 h-5 bg-primary/10 rounded-full flex items-center justify-center flex-shrink-0">
                  <Clock className="w-3 h-3 text-primary" />
                </div>
                <span>مدة العرض: {requestDuration} {requestDuration === 1 ? "\u0633\u0627\u0639\u0629" : "\u0633\u0627\u0639\u0627\u062A"}</span>
              </div>
            </div>
          </div>}

        {
    /* الأزرار */
  }
        <div className="flex gap-3 pt-4 pb-6">
          <button
    onClick={onBack}
    className="px-6 py-3 bg-gray-100 text-secondary rounded-xl hover:bg-gray-200 transition-colors"
  >
            رجوع
          </button>
          <button
    onClick={handleSendInvitation}
    disabled={!selectedTeammate}
    className={`flex-1 py-3 rounded-xl shadow-lg transition-all ${selectedTeammate ? "bg-gradient-to-r from-primary to-primary/90 text-white hover:shadow-xl" : "bg-gray-300 text-gray-500 cursor-not-allowed"}`}
  >
            {selectedTeammate ? "\u0625\u0631\u0633\u0627\u0644 \u0627\u0644\u062F\u0639\u0648\u0629 \u0648\u0627\u0644\u0645\u062A\u0627\u0628\u0639\u0629" : "\u0627\u062E\u062A\u0631 \u0632\u0645\u064A\u0644 \u0644\u0644\u0645\u062A\u0627\u0628\u0639\u0629"}
          </button>
        </div>
      </div>

      {
    /* نافذة التأكيد */
  }
      {showConfirmation && selectedTeammate && <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center p-6 z-50">
          <div className="bg-white rounded-3xl p-8 max-w-sm w-full shadow-2xl text-center">
            <div className="flex justify-center mb-4">
              <div className="w-20 h-20 bg-green-100 rounded-full flex items-center justify-center animate-pulse">
                <CheckCircle className="w-12 h-12 text-green-600" />
              </div>
            </div>

            <h3 className="text-2xl text-secondary mb-2">تم إرسال الدعوة!</h3>
            <p className="text-sm text-muted-foreground mb-6">
              تم إرسال إشعار لـ <span className="text-primary font-medium">{selectedTeammate.name}</span> للموافقة وإكمال الدفع
            </p>

            <div className="bg-gray-50 rounded-xl p-4 space-y-2 text-sm">
              <div className="flex justify-between">
                <span className="text-muted-foreground">زميلك:</span>
                <span className="text-secondary font-medium">{selectedTeammate.name}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">المستوى:</span>
                <span className="text-secondary">{selectedTeammate.level}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">نسبة الفوز:</span>
                <span className="text-green-600 font-medium">{selectedTeammate.winRate}%</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">مدة العرض:</span>
                <span className="text-primary font-medium">{requestDuration} {requestDuration === 1 ? "\u0633\u0627\u0639\u0629" : "\u0633\u0627\u0639\u0627\u062A"}</span>
              </div>
              <div className="h-px bg-gray-200 my-2" />
              <p className="text-xs text-muted-foreground text-center">
                سيتم تأكيد الانضمام بعد موافقة زميلك خلال {requestDuration} {requestDuration === 1 ? "\u0633\u0627\u0639\u0629" : "\u0633\u0627\u0639\u0627\u062A"}
              </p>
            </div>
          </div>
        </div>}
    </div>;
}
export {
  SelectTeammatePage as default
};
