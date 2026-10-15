import { useState, useEffect } from "react";
import { ChevronRight, Users, Trophy, Clock, Hash, Play, Pause, CheckCircle, ChevronLeft, Target, BarChart3, TrendingUp, Medal, Crown, Settings } from "lucide-react";
import Tooltip from "./Tooltip";
function AmericanoExecutionPage({ onBack }) {
  const [activeTab, setActiveTab] = useState("matches");
  const [americanoData, setAmericanoData] = useState({
    name: "\u0623\u0645\u0631\u064A\u0643\u0627\u0646\u0648 \u0627\u0644\u0628\u0627\u062F\u0644 \u0627\u0644\u0645\u0644\u0643\u064A",
    type: "\u0641\u0631\u062F\u064A",
    courtName: "\u0646\u0627\u062F\u064A \u0627\u0644\u0628\u0627\u062F\u0644 \u0627\u0644\u0645\u0644\u0643\u064A",
    courtNumbers: [1, 2, 3],
    totalPlayers: 12,
    currentRound: 1,
    totalRounds: 6,
    roundType: "time",
    timePerRound: 12,
    setsPerRound: 1
  });
  const [showSettings, setShowSettings] = useState(false);
  const [roundTimer, setRoundTimer] = useState(0);
  const [isTimerRunning, setIsTimerRunning] = useState(false);
  const [players, setPlayers] = useState([
    { id: "1", name: "\u0645\u062D\u0645\u062F \u0627\u0644\u0639\u062A\u064A\u0628\u064A", level: "5.2", points: 15, wins: 3, losses: 0, gamesPlayed: 3, pointsFor: 36, pointsAgainst: 24 },
    { id: "2", name: "\u0641\u0647\u062F \u0627\u0644\u062F\u0648\u0633\u0631\u064A", level: "5.8", points: 12, wins: 2, losses: 1, gamesPlayed: 3, pointsFor: 34, pointsAgainst: 28 },
    { id: "3", name: "\u0633\u0639\u0648\u062F \u0627\u0644\u0642\u062D\u0637\u0627\u0646\u064A", level: "5.5", points: 12, wins: 2, losses: 1, gamesPlayed: 3, pointsFor: 32, pointsAgainst: 26 },
    { id: "4", name: "\u0639\u0628\u062F\u0627\u0644\u0644\u0647 \u0627\u0644\u0633\u0627\u0644\u0645", level: "6.0", points: 10, wins: 2, losses: 1, gamesPlayed: 3, pointsFor: 30, pointsAgainst: 28 },
    { id: "5", name: "\u062E\u0627\u0644\u062F \u0627\u0644\u0645\u0637\u064A\u0631\u064A", level: "5.3", points: 9, wins: 1, losses: 2, gamesPlayed: 3, pointsFor: 28, pointsAgainst: 32 },
    { id: "6", name: "\u0646\u0627\u0635\u0631 \u0627\u0644\u0634\u0645\u0631\u064A", level: "5.7", points: 8, wins: 1, losses: 2, gamesPlayed: 3, pointsFor: 26, pointsAgainst: 30 },
    { id: "7", name: "\u0639\u0644\u064A \u0627\u0644\u063A\u0627\u0645\u062F\u064A", level: "5.4", points: 6, wins: 1, losses: 2, gamesPlayed: 3, pointsFor: 24, pointsAgainst: 34 },
    { id: "8", name: "\u0633\u0644\u0637\u0627\u0646 \u0627\u0644\u0639\u0646\u0632\u064A", level: "5.9", points: 6, wins: 0, losses: 3, gamesPlayed: 3, pointsFor: 22, pointsAgainst: 36 },
    { id: "9", name: "\u0623\u062D\u0645\u062F \u0627\u0644\u063A\u0627\u0645\u062F\u064A", level: "5.1", points: 5, wins: 1, losses: 2, gamesPlayed: 3, pointsFor: 20, pointsAgainst: 32 },
    { id: "10", name: "\u064A\u0648\u0633\u0641 \u0627\u0644\u0642\u0631\u0646\u064A", level: "5.6", points: 4, wins: 0, losses: 3, gamesPlayed: 3, pointsFor: 18, pointsAgainst: 36 },
    { id: "11", name: "\u0639\u0645\u0631 \u0627\u0644\u0632\u0647\u0631\u0627\u0646\u064A", level: "5.2", points: 3, wins: 0, losses: 3, gamesPlayed: 3, pointsFor: 16, pointsAgainst: 34 },
    { id: "12", name: "\u0633\u0627\u0645\u064A \u0627\u0644\u0639\u0645\u0631\u064A", level: "5.5", points: 2, wins: 0, losses: 3, gamesPlayed: 3, pointsFor: 14, pointsAgainst: 36 }
  ]);
  const [currentMatches, setCurrentMatches] = useState([
    {
      id: "m1",
      courtNumber: 1,
      team1: [players[0], players[3]],
      team2: [players[1], players[2]],
      score1: 8,
      score2: 6,
      status: "playing",
      round: 4
    },
    {
      id: "m2",
      courtNumber: 2,
      team1: [players[4], players[7]],
      team2: [players[5], players[6]],
      score1: 4,
      score2: 4,
      status: "playing",
      round: 4
    },
    {
      id: "m3",
      courtNumber: 3,
      team1: [players[8], players[11]],
      team2: [players[9], players[10]],
      score1: 0,
      score2: 0,
      status: "waiting",
      round: 4
    }
  ]);
  useEffect(() => {
    let interval;
    if (isTimerRunning && roundTimer > 0) {
      interval = setInterval(() => {
        setRoundTimer((prev) => {
          if (prev <= 1) {
            setIsTimerRunning(false);
            return 0;
          }
          return prev - 1;
        });
      }, 1e3);
    }
    return () => clearInterval(interval);
  }, [isTimerRunning, roundTimer]);
  const startRound = () => {
    setRoundTimer(americanoData.timePerRound * 60);
    setIsTimerRunning(true);
    setCurrentMatches(
      (matches) => matches.map((m) => ({ ...m, status: "playing" }))
    );
  };
  const pauseRound = () => {
    setIsTimerRunning(false);
  };
  const completeRound = () => {
    setAmericanoData((prev) => ({
      ...prev,
      currentRound: prev.currentRound + 1
    }));
    setRoundTimer(0);
    setIsTimerRunning(false);
  };
  const updateMatchScore = (matchId, team, increment) => {
    setCurrentMatches(
      (matches) => matches.map((match) => {
        if (match.id === matchId) {
          const newScore = team === 1 ? Math.max(0, match.score1 + increment) : Math.max(0, match.score2 + increment);
          return {
            ...match,
            ...team === 1 ? { score1: newScore } : { score2: newScore }
          };
        }
        return match;
      })
    );
  };
  const completeMatch = (matchId) => {
    setCurrentMatches(
      (matches) => matches.map((match) => {
        if (match.id === matchId) {
          return { ...match, status: "completed" };
        }
        return match;
      })
    );
  };
  const formatTime = (seconds) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins.toString().padStart(2, "0")}:${secs.toString().padStart(2, "0")}`;
  };
  const sortedPlayers = [...players].sort((a, b) => {
    if (b.points !== a.points) return b.points - a.points;
    const diffA = a.pointsFor - a.pointsAgainst;
    const diffB = b.pointsFor - b.pointsAgainst;
    return diffB - diffA;
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
          <div className="flex-1">
            <h1 className="text-2xl">{americanoData.name}</h1>
            <p className="text-white/80 text-sm">أمريكانو {americanoData.type}</p>
          </div>
        </div>

        {
    /* معلومات سريعة */
  }
        <div className="grid grid-cols-3 gap-3 mb-4">
          <div className="bg-white/10 backdrop-blur-sm rounded-xl p-3 text-center">
            <Users className="w-5 h-5 mx-auto mb-1" />
            <p className="text-xs opacity-80">اللاعبين</p>
            <p className="text-lg font-medium">{americanoData.totalPlayers}</p>
          </div>
          <div className="bg-white/10 backdrop-blur-sm rounded-xl p-3 text-center">
            <Target className="w-5 h-5 mx-auto mb-1" />
            <p className="text-xs opacity-80">الجولة</p>
            <p className="text-lg font-medium">{americanoData.currentRound}/{americanoData.totalRounds}</p>
          </div>
          <div className="bg-white/10 backdrop-blur-sm rounded-xl p-3 text-center">
            <Hash className="w-5 h-5 mx-auto mb-1" />
            <p className="text-xs opacity-80">الملاعب</p>
            <p className="text-lg font-medium">{americanoData.courtNumbers.length}</p>
          </div>
        </div>

        {
    /* زر إعدادات الجولة */
  }
        <button
    onClick={() => setShowSettings(!showSettings)}
    className="w-full bg-white/10 backdrop-blur-sm rounded-xl p-3 flex items-center justify-between hover:bg-white/20 transition-colors"
  >
          <div className="flex items-center gap-2">
            <Settings className="w-5 h-5" />
            <span className="text-sm font-medium">إعدادات الجولة</span>
          </div>
          <ChevronRight className={`w-5 h-5 transition-transform ${showSettings ? "rotate-90" : ""}`} />
        </button>

        {
    /* قسم الإعدادات */
  }
        {showSettings && <div className="mt-3 bg-white/10 backdrop-blur-sm rounded-xl p-4 space-y-4">
            {
    /* اختيار نوع الجولة */
  }
            <div>
              <label className="block text-sm font-medium mb-3">نوع الجولة</label>
              <div className="grid grid-cols-2 gap-3">
                <button
    onClick={() => setAmericanoData({ ...americanoData, roundType: "time" })}
    className={`p-3 rounded-xl flex items-center justify-center gap-2 transition-all ${americanoData.roundType === "time" ? "bg-white text-primary border-2 border-white" : "bg-white/20 text-white border-2 border-white/30"}`}
  >
                  <Clock className="w-5 h-5" />
                  <span className="text-sm font-medium">بالوقت</span>
                </button>
                <button
    onClick={() => setAmericanoData({ ...americanoData, roundType: "sets" })}
    className={`p-3 rounded-xl flex items-center justify-center gap-2 transition-all ${americanoData.roundType === "sets" ? "bg-white text-primary border-2 border-white" : "bg-white/20 text-white border-2 border-white/30"}`}
  >
                  <Hash className="w-5 h-5" />
                  <span className="text-sm font-medium">بعدد الأشواط</span>
                </button>
              </div>
            </div>

            {
    /* إدخال الوقت */
  }
            {americanoData.roundType === "time" && <div>
                <label className="block text-sm font-medium mb-2">مدة الجولة (بالدقائق)</label>
                <input
    type="number"
    min="1"
    max="60"
    value={americanoData.timePerRound}
    onChange={(e) => setAmericanoData({ ...americanoData, timePerRound: parseInt(e.target.value) || 1 })}
    className="w-full bg-white/90 text-secondary px-4 py-3 rounded-xl outline-none border-2 border-white/50 focus:border-white"
    placeholder="مثال: 12"
  />
                <p className="text-xs text-white/70 mt-1">أدخل المدة من 1 إلى 60 دقيقة</p>
              </div>}

            {
    /* إدخال عدد الأشواط */
  }
            {americanoData.roundType === "sets" && <div>
                <label className="block text-sm font-medium mb-2">عدد الأشواط لكل جولة</label>
                <input
    type="number"
    min="1"
    max="5"
    value={americanoData.setsPerRound}
    onChange={(e) => setAmericanoData({ ...americanoData, setsPerRound: parseInt(e.target.value) || 1 })}
    className="w-full bg-white/90 text-secondary px-4 py-3 rounded-xl outline-none border-2 border-white/50 focus:border-white"
    placeholder="مثال: 1"
  />
                <p className="text-xs text-white/70 mt-1">أدخل عدد الأشواط من 1 إلى 5</p>
              </div>}
          </div>}
      </div>

      {
    /* Timer and Controls */
  }
      {americanoData.roundType === "time" && <div className="px-6 py-4 bg-gradient-to-r from-primary/10 to-primary/5 border-b-2 border-primary/20">
          <div className="flex items-center justify-between mb-3">
            <div className="flex items-center gap-2">
              <Clock className="w-5 h-5 text-primary" />
              <span className="text-sm text-secondary font-medium">وقت الجولة</span>
            </div>
            <div className="text-3xl font-bold text-primary font-mono">
              {formatTime(roundTimer)}
            </div>
          </div>

          <div className="flex gap-2">
            {!isTimerRunning && roundTimer === 0 && <button
    onClick={startRound}
    className="flex-1 py-2.5 bg-gradient-to-r from-green-500 to-green-600 text-white rounded-xl flex items-center justify-center gap-2 shadow-lg hover:shadow-xl transition-all"
  >
                <Play className="w-5 h-5" />
                بدء الجولة
              </button>}
            {isTimerRunning && <button
    onClick={pauseRound}
    className="flex-1 py-2.5 bg-gradient-to-r from-orange-500 to-orange-600 text-white rounded-xl flex items-center justify-center gap-2 shadow-lg hover:shadow-xl transition-all"
  >
                <Pause className="w-5 h-5" />
                إيقاف مؤقت
              </button>}
            {!isTimerRunning && roundTimer > 0 && <button
    onClick={() => setIsTimerRunning(true)}
    className="flex-1 py-2.5 bg-gradient-to-r from-green-500 to-green-600 text-white rounded-xl flex items-center justify-center gap-2 shadow-lg hover:shadow-xl transition-all"
  >
                <Play className="w-5 h-5" />
                استئناف
              </button>}
            {roundTimer === 0 && americanoData.currentRound < americanoData.totalRounds && <button
    onClick={completeRound}
    className="flex-1 py-2.5 bg-gradient-to-r from-primary to-primary/90 text-white rounded-xl flex items-center justify-center gap-2 shadow-lg hover:shadow-xl transition-all"
  >
                <ChevronLeft className="w-5 h-5" />
                الجولة التالية
              </button>}
          </div>
        </div>}

      {
    /* Sets Info and Controls */
  }
      {americanoData.roundType === "sets" && <div className="px-6 py-4 bg-gradient-to-r from-purple-500/10 to-purple-500/5 border-b-2 border-purple-500/20">
          <div className="flex items-center justify-between mb-3">
            <div className="flex items-center gap-2">
              <Hash className="w-5 h-5 text-purple-600" />
              <span className="text-sm text-secondary font-medium">عدد الأشواط لكل مباراة</span>
            </div>
            <div className="px-4 py-2 bg-purple-100 rounded-xl">
              <span className="text-2xl font-bold text-purple-600">{americanoData.setsPerRound}</span>
              <span className="text-sm text-purple-600 mr-1">شوط</span>
            </div>
          </div>

          <div className="flex gap-2">
            {americanoData.currentRound < americanoData.totalRounds && <button
    onClick={completeRound}
    className="flex-1 py-2.5 bg-gradient-to-r from-primary to-primary/90 text-white rounded-xl flex items-center justify-center gap-2 shadow-lg hover:shadow-xl transition-all"
  >
                <ChevronLeft className="w-5 h-5" />
                الجولة التالية
              </button>}
          </div>
          <p className="text-xs text-muted-foreground mt-2 text-center">
            عند الانتهاء من جميع المباريات، انتقل للجولة التالية
          </p>
        </div>}

      {
    /* Tabs */
  }
      <div className="px-6 py-4 border-b border-border bg-white sticky top-0 z-10">
        <div className="flex gap-2">
          <button
    onClick={() => setActiveTab("matches")}
    className={`flex-1 py-2.5 rounded-xl transition-all ${activeTab === "matches" ? "bg-primary text-white shadow-md" : "bg-gray-100 text-secondary hover:bg-gray-200"}`}
  >
            <div className="flex items-center justify-center gap-2">
              <Target className="w-4 h-4" />
              <span className="text-sm font-medium">المباريات</span>
            </div>
          </button>
          <button
    onClick={() => setActiveTab("leaderboard")}
    className={`flex-1 py-2.5 rounded-xl transition-all ${activeTab === "leaderboard" ? "bg-primary text-white shadow-md" : "bg-gray-100 text-secondary hover:bg-gray-200"}`}
  >
            <div className="flex items-center justify-center gap-2">
              <Trophy className="w-4 h-4" />
              <span className="text-sm font-medium">الترتيب</span>
            </div>
          </button>
          <button
    onClick={() => setActiveTab("schedule")}
    className={`flex-1 py-2.5 rounded-xl transition-all ${activeTab === "schedule" ? "bg-primary text-white shadow-md" : "bg-gray-100 text-secondary hover:bg-gray-200"}`}
  >
            <div className="flex items-center justify-center gap-2">
              <BarChart3 className="w-4 h-4" />
              <span className="text-sm font-medium">الجدول</span>
            </div>
          </button>
        </div>
      </div>

      <div className="px-6 py-6">
        {
    /* المباريات الحالية */
  }
        {activeTab === "matches" && <div className="space-y-4">
            {currentMatches.map((match) => <div
    key={match.id}
    className={`bg-white border-2 rounded-2xl p-4 ${match.status === "playing" ? "border-green-300 bg-green-50/50" : match.status === "completed" ? "border-gray-300 bg-gray-50 opacity-75" : "border-border"}`}
  >
                {
    /* رقم الملعب وحالة المباراة */
  }
                <div className="flex items-center justify-between mb-4">
                  <div className="flex items-center gap-2">
                    <div className="w-8 h-8 bg-primary rounded-full flex items-center justify-center">
                      <span className="text-white text-sm font-medium">{match.courtNumber}</span>
                    </div>
                    <span className="text-sm text-secondary font-medium">ملعب {match.courtNumber}</span>
                  </div>
                  <div className="flex items-center gap-2">
                    {match.status === "playing" && <span className="px-3 py-1 bg-green-100 text-green-600 text-xs rounded-full flex items-center gap-1">
                        <span className="w-2 h-2 bg-green-500 rounded-full animate-pulse" />
                        جارية
                      </span>}
                    {match.status === "completed" && <span className="px-3 py-1 bg-gray-200 text-gray-600 text-xs rounded-full">
                        منتهية
                      </span>}
                    {match.status === "waiting" && <span className="px-3 py-1 bg-blue-100 text-blue-600 text-xs rounded-full">
                        في الانتظار
                      </span>}
                  </div>
                </div>

                {
    /* الفريقين والنتيجة */
  }
                <div className="space-y-3">
                  {
    /* الفريق الأول */
  }
                  <div className="flex items-center justify-between p-3 bg-white rounded-xl border border-border">
                    <div className="flex items-center gap-3 flex-1">
                      {match.team1.map((player, idx) => <div key={player.id} className="flex items-center gap-2">
                          {idx > 0 && <span className="text-gray-300">+</span>}
                          <div className="w-8 h-8 bg-gradient-to-br from-blue-500 to-blue-600 rounded-full flex items-center justify-center">
                            <span className="text-white text-xs font-medium">{player.level}</span>
                          </div>
                          <span className="text-sm text-secondary">{player.name}</span>
                        </div>)}
                    </div>
                    <div className="flex items-center gap-2">
                      {match.status !== "completed" && <>
                          <button
    onClick={() => updateMatchScore(match.id, 1, -1)}
    className="w-8 h-8 bg-red-100 hover:bg-red-200 text-red-600 rounded-lg transition-colors"
  >
                            -
                          </button>
                          <button
    onClick={() => updateMatchScore(match.id, 1, 1)}
    className="w-8 h-8 bg-green-100 hover:bg-green-200 text-green-600 rounded-lg transition-colors"
  >
                            +
                          </button>
                        </>}
                      <div className="w-12 h-12 bg-primary/10 rounded-xl flex items-center justify-center">
                        <span className="text-2xl font-bold text-primary">{match.score1}</span>
                      </div>
                    </div>
                  </div>

                  {
    /* VS */
  }
                  <div className="text-center">
                    <span className="text-xs text-muted-foreground">ضد</span>
                  </div>

                  {
    /* الفريق الثاني */
  }
                  <div className="flex items-center justify-between p-3 bg-white rounded-xl border border-border">
                    <div className="flex items-center gap-3 flex-1">
                      {match.team2.map((player, idx) => <div key={player.id} className="flex items-center gap-2">
                          {idx > 0 && <span className="text-gray-300">+</span>}
                          <div className="w-8 h-8 bg-gradient-to-br from-orange-500 to-orange-600 rounded-full flex items-center justify-center">
                            <span className="text-white text-xs font-medium">{player.level}</span>
                          </div>
                          <span className="text-sm text-secondary">{player.name}</span>
                        </div>)}
                    </div>
                    <div className="flex items-center gap-2">
                      {match.status !== "completed" && <>
                          <button
    onClick={() => updateMatchScore(match.id, 2, -1)}
    className="w-8 h-8 bg-red-100 hover:bg-red-200 text-red-600 rounded-lg transition-colors"
  >
                            -
                          </button>
                          <button
    onClick={() => updateMatchScore(match.id, 2, 1)}
    className="w-8 h-8 bg-green-100 hover:bg-green-200 text-green-600 rounded-lg transition-colors"
  >
                            +
                          </button>
                        </>}
                      <div className="w-12 h-12 bg-primary/10 rounded-xl flex items-center justify-center">
                        <span className="text-2xl font-bold text-primary">{match.score2}</span>
                      </div>
                    </div>
                  </div>
                </div>

                {
    /* زر إنهاء المباراة */
  }
                {match.status !== "completed" && <button
    onClick={() => completeMatch(match.id)}
    className="w-full mt-4 py-2.5 bg-gradient-to-r from-green-500 to-green-600 text-white rounded-xl flex items-center justify-center gap-2 shadow-md hover:shadow-lg transition-all"
  >
                    <CheckCircle className="w-5 h-5" />
                    إنهاء المباراة
                  </button>}
              </div>)}
          </div>}

        {
    /* جدول الترتيب */
  }
        {activeTab === "leaderboard" && <div className="space-y-3">
            {sortedPlayers.map((player, index) => <div
    key={player.id}
    className={`p-4 rounded-2xl border-2 transition-all ${index === 0 ? "bg-gradient-to-br from-yellow-50 to-yellow-100/50 border-yellow-300" : index === 1 ? "bg-gradient-to-br from-gray-50 to-gray-100/50 border-gray-300" : index === 2 ? "bg-gradient-to-br from-orange-50 to-orange-100/50 border-orange-300" : "bg-white border-border"}`}
  >
                <div className="flex items-center gap-3 mb-3">
                  {
    /* الترتيب */
  }
                  <div className="relative">
                    {index === 0 && <div className="w-12 h-12 bg-gradient-to-br from-yellow-400 to-yellow-500 rounded-full flex items-center justify-center shadow-lg">
                        <Crown className="w-6 h-6 text-white" />
                      </div>}
                    {index === 1 && <div className="w-12 h-12 bg-gradient-to-br from-gray-300 to-gray-400 rounded-full flex items-center justify-center shadow-lg">
                        <Medal className="w-6 h-6 text-white" />
                      </div>}
                    {index === 2 && <div className="w-12 h-12 bg-gradient-to-br from-orange-400 to-orange-500 rounded-full flex items-center justify-center shadow-lg">
                        <Medal className="w-6 h-6 text-white" />
                      </div>}
                    {index > 2 && <div className="w-12 h-12 bg-gradient-to-br from-primary to-primary/80 rounded-full flex items-center justify-center">
                        <span className="text-white text-xl font-bold">{index + 1}</span>
                      </div>}
                  </div>

                  {
    /* اسم اللاعب */
  }
                  <div className="flex-1">
                    <p className="text-base font-medium text-secondary">{player.name}</p>
                    <div className="flex items-center gap-3 mt-1">
                      <span className="text-xs text-muted-foreground">مستوى {player.level}</span>
                      <span className="text-xs text-muted-foreground">•</span>
                      <span className="text-xs text-green-600">{player.wins} فوز</span>
                      <span className="text-xs text-red-600">{player.losses} خسارة</span>
                    </div>
                  </div>

                  {
    /* النقاط */
  }
                  <div className="text-center">
                    <Tooltip content="إجمالي النقاط المكتسبة" position="left">
                      <div className="w-16 h-16 bg-gradient-to-br from-green-500 to-green-600 rounded-xl flex items-center justify-center shadow-lg cursor-help">
                        <div>
                          <p className="text-2xl font-bold text-white">{player.points}</p>
                          <p className="text-xs text-white/80">نقطة</p>
                        </div>
                      </div>
                    </Tooltip>
                  </div>
                </div>

                {
    /* الإحصائيات التفصيلية */
  }
                <div className="grid grid-cols-3 gap-2 pt-3 border-t border-gray-200">
                  <Tooltip content="عدد المباريات المكتملة" position="top">
                    <div className="text-center p-2 bg-white/50 rounded-lg cursor-help">
                      <p className="text-xs text-muted-foreground">مباريات</p>
                      <p className="text-sm font-medium text-secondary">{player.gamesPlayed}</p>
                    </div>
                  </Tooltip>
                  <Tooltip content="مجموع النقاط المحرزة في جميع المباريات" position="top">
                    <div className="text-center p-2 bg-white/50 rounded-lg cursor-help">
                      <p className="text-xs text-muted-foreground">نقاط له</p>
                      <p className="text-sm font-medium text-green-600">{player.pointsFor}</p>
                    </div>
                  </Tooltip>
                  <Tooltip content="مجموع النقاط المحرزة ضده" position="top">
                    <div className="text-center p-2 bg-white/50 rounded-lg cursor-help">
                      <p className="text-xs text-muted-foreground">نقاط عليه</p>
                      <p className="text-sm font-medium text-red-600">{player.pointsAgainst}</p>
                    </div>
                  </Tooltip>
                </div>
              </div>)}
          </div>}

        {
    /* جدول التوزيع */
  }
        {activeTab === "schedule" && <div className="space-y-4">
            <div className="bg-gradient-to-br from-blue-50 to-blue-100/50 border border-blue-200 rounded-2xl p-4">
              <div className="flex items-start gap-3">
                <div className="w-10 h-10 bg-blue-500 rounded-full flex items-center justify-center flex-shrink-0">
                  <BarChart3 className="w-5 h-5 text-white" />
                </div>
                <div className="flex-1">
                  <h3 className="text-secondary font-medium mb-2">نظام التوزيع العادل</h3>
                  <p className="text-sm text-muted-foreground leading-relaxed">
                    يتم توزيع اللاعبين بطريقة عادلة حسب خوارزمية الأمريكانو:
                  </p>
                  <ul className="mt-2 space-y-1 text-sm text-muted-foreground">
                    <li className="flex items-start gap-2">
                      <span className="text-blue-500 mt-0.5">•</span>
                      <span>كل لاعب يلعب مع ومقابل جميع اللاعبين الآخرين</span>
                    </li>
                    <li className="flex items-start gap-2">
                      <span className="text-blue-500 mt-0.5">•</span>
                      <span>التوزيع يضمن عدالة الفرص لجميع اللاعبين</span>
                    </li>
                    <li className="flex items-start gap-2">
                      <span className="text-blue-500 mt-0.5">•</span>
                      <span>يتم تدوير الفرق في كل جولة تلقائياً</span>
                    </li>
                  </ul>
                </div>
              </div>
            </div>

            {
    /* الجولات القادمة */
  }
            <div className="bg-white border border-border rounded-2xl p-4">
              <h3 className="text-secondary font-medium mb-3 flex items-center gap-2">
                <Clock className="w-5 h-5 text-primary" />
                الجولات المتبقية
              </h3>
              <div className="space-y-2">
                {Array.from({ length: americanoData.totalRounds - americanoData.currentRound }, (_, i) => <div
    key={i}
    className="flex items-center justify-between p-3 bg-gray-50 rounded-xl"
  >
                    <span className="text-sm text-secondary">الجولة {americanoData.currentRound + i + 1}</span>
                    <span className="text-xs text-muted-foreground">
                      {americanoData.roundType === "time" ? `${americanoData.timePerRound} \u062F\u0642\u064A\u0642\u0629` : `${americanoData.setsPerRound} \u0634\u0648\u0637`}
                    </span>
                  </div>)}
              </div>
            </div>

            {
    /* معلومات النقاط */
  }
            <div className="bg-gradient-to-br from-green-50 to-green-100/50 border border-green-200 rounded-2xl p-4">
              <div className="flex items-start gap-3">
                <div className="w-10 h-10 bg-green-500 rounded-full flex items-center justify-center flex-shrink-0">
                  <TrendingUp className="w-5 h-5 text-white" />
                </div>
                <div className="flex-1">
                  <h3 className="text-secondary font-medium mb-2">نظام احتساب النقاط</h3>
                  <ul className="space-y-1 text-sm text-muted-foreground">
                    <li className="flex items-start gap-2">
                      <span className="text-green-500 mt-0.5">•</span>
                      <span>الفوز: 5 نقاط</span>
                    </li>
                    <li className="flex items-start gap-2">
                      <span className="text-green-500 mt-0.5">•</span>
                      <span>التعادل: 2 نقطة لكل فريق</span>
                    </li>
                    <li className="flex items-start gap-2">
                      <span className="text-green-500 mt-0.5">•</span>
                      <span>الخسارة: 0 نقطة</span>
                    </li>
                    <li className="flex items-start gap-2">
                      <span className="text-green-500 mt-0.5">•</span>
                      <span>في حالة التعادل بالنقاط: يتم الاعتماد على فارق النقاط (المحرزة - المستقبلة)</span>
                    </li>
                  </ul>
                </div>
              </div>
            </div>
          </div>}
      </div>
    </div>;
}
export {
  AmericanoExecutionPage as default
};
