import { useState } from "react";
import { ChevronRight, MapPin, Clock, Users, Trophy, CheckCircle, Star, Shield, Swords, Plus, Trash2, RefreshCw, Layers, Timer, Hash, ChevronDown, ChevronUp, Info } from "lucide-react";
const americanoTeams = [
  {
    id: "at1",
    label: "\u0627\u0644\u0635\u0642\u0648\u0631",
    avgLevel: 4.75,
    players: [
      { name: "\u0623\u062D\u0645\u062F \u0627\u0644\u0632\u0647\u0631\u0627\u0646\u064A", avatar: "\u0623.\u0632", color: "from-primary to-primary/80" },
      { name: "\u0633\u0639\u062F \u0627\u0644\u0645\u0637\u064A\u0631\u064A", avatar: "\u0633.\u0645", color: "from-blue-500 to-blue-600" }
    ]
  },
  {
    id: "at2",
    label: "\u0627\u0644\u0646\u0633\u0648\u0631",
    avgLevel: 4.65,
    players: [
      { name: "\u062E\u0627\u0644\u062F \u0627\u0644\u0639\u0645\u0631\u064A", avatar: "\u062E.\u0639", color: "from-purple-500 to-purple-600" },
      { name: "\u0639\u0645\u0631 \u0627\u0644\u0634\u0647\u0631\u064A", avatar: "\u0639.\u0634", color: "from-indigo-500 to-indigo-600" }
    ]
  },
  {
    id: "at3",
    label: "\u0627\u0644\u0623\u0633\u0648\u062F",
    avgLevel: 4.6,
    players: [
      { name: "\u0641\u064A\u0635\u0644 \u0627\u0644\u0639\u062A\u064A\u0628\u064A", avatar: "\u0641.\u0639", color: "from-orange-500 to-orange-600" },
      { name: "\u0645\u062D\u0645\u062F \u0627\u0644\u0633\u0627\u0644\u0645", avatar: "\u0645.\u0633", color: "from-red-500 to-red-600" }
    ]
  },
  {
    id: "at4",
    label: "\u0627\u0644\u0646\u0645\u0648\u0631",
    avgLevel: 4.7,
    players: [
      { name: "\u0628\u0646\u062F\u0631 \u0627\u0644\u062D\u0631\u0628\u064A", avatar: "\u0628.\u062D", color: "from-teal-500 to-teal-600" },
      { name: "\u0641\u0647\u062F \u0627\u0644\u062F\u0648\u0633\u0631\u064A", avatar: "\u0641.\u062F", color: "from-green-500 to-green-600" }
    ]
  }
];
const teamHeaderColor = {
  at1: "from-primary to-blue-600",
  at2: "from-purple-600 to-indigo-600",
  at3: "from-orange-500 to-red-500",
  at4: "from-teal-500 to-green-600"
};
const teamAccent = {
  at1: "bg-blue-100 text-blue-700 border-blue-200",
  at2: "bg-purple-100 text-purple-700 border-purple-200",
  at3: "bg-orange-100 text-orange-700 border-orange-200",
  at4: "bg-teal-100 text-teal-700 border-teal-200"
};
function buildFairSchedule(teams) {
  const s = [...teams].sort((a, b) => b.avgLevel - a.avgLevel);
  return [
    [s[0].id, s[3].id, s[1].id, s[2].id],
    [s[0].id, s[2].id, s[3].id, s[1].id],
    [s[0].id, s[1].id, s[2].id, s[3].id]
  ];
}
function addMinutes(time, mins) {
  const [h, m] = time.split(":").map(Number);
  const total = h * 60 + m + mins;
  const nh = Math.floor(total / 60) % 24;
  const nm = total % 60;
  return `${nh.toString().padStart(2, "0")}:${nm.toString().padStart(2, "0")}`;
}
function fmtTime(t) {
  const [h, m] = t.split(":").map(Number);
  const per = h >= 12 ? "\u0645" : "\u0635";
  const h12 = h > 12 ? h - 12 : h === 0 ? 12 : h;
  return `${h12}:${m.toString().padStart(2, "0")} ${per}`;
}
function makeAMatch(id, tA, tB, setsCount) {
  return { id, teamA: tA, teamB: tB, scoreA: "", scoreB: "", sets: Array.from({ length: setsCount }, () => ({ sA: "", sB: "" })) };
}
function generateSchedule(mode, startTime, timePerRound, setsCount) {
  const pairings = buildFairSchedule(americanoTeams);
  return pairings.map(([c1a, c1b, c2a, c2b], ri) => {
    const slotStart = addMinutes(startTime, ri * (mode === "time" ? timePerRound + 2 : 0));
    const slotEnd = addMinutes(slotStart, timePerRound);
    return {
      id: `ar${ri}`,
      roundNum: ri + 1,
      court1: makeAMatch(`m${ri}c1`, c1a, c1b, setsCount),
      court2: makeAMatch(`m${ri}c2`, c2a, c2b, setsCount),
      timeSlot: mode === "time" ? `${fmtTime(slotStart)} \u2013 ${fmtTime(slotEnd)}` : `\u062C\u0648\u0644\u0629 ${ri + 1}`
    };
  });
}
function calcSchedulePoints(schedule, mode) {
  const pts = { at1: 0, at2: 0, at3: 0, at4: 0 };
  schedule.forEach((r) => {
    [r.court1, r.court2].forEach((m) => {
      if (mode === "time") {
        pts[m.teamA] = (pts[m.teamA] || 0) + (parseInt(m.scoreA) || 0);
        pts[m.teamB] = (pts[m.teamB] || 0) + (parseInt(m.scoreB) || 0);
      } else {
        m.sets.forEach((s) => {
          pts[m.teamA] = (pts[m.teamA] || 0) + (parseInt(s.sA) || 0);
          pts[m.teamB] = (pts[m.teamB] || 0) + (parseInt(s.sB) || 0);
        });
      }
    });
  });
  return pts;
}
function isScheduleComplete(schedule, mode) {
  return schedule.every(
    (r) => [r.court1, r.court2].every(
      (m) => mode === "time" ? m.scoreA !== "" && m.scoreB !== "" : m.sets.every((s) => s.sA !== "" && s.sB !== "")
    )
  );
}
function TeamChip({ team, size = "sm" }) {
  const sz = size === "md" ? { av: "w-8 h-8", txt: "text-xs", lbl: "text-sm" } : { av: "w-6 h-6", txt: "text-[10px]", lbl: "text-xs" };
  return <div className="flex items-center gap-1.5">
      <div className="flex -space-x-1.5">
        {team.players.map((p, i) => <div key={i} className={`${sz.av} bg-gradient-to-br ${p.color} rounded-full border-2 border-white flex items-center justify-center flex-shrink-0`}>
            <span className={`text-white ${sz.txt}`}>{p.avatar}</span>
          </div>)}
      </div>
      <span className={`${sz.lbl} text-secondary`}>{team.label}</span>
    </div>;
}
const americanoSoloPlayers = [
  { id: "as1", name: "\u0623\u062D\u0645\u062F \u0627\u0644\u0632\u0647\u0631\u0627\u0646\u064A", level: 5.2, avatar: "\u0623.\u0632", color: "from-primary to-primary/80", short: "\u0623\u062D\u0645\u062F" },
  { id: "as2", name: "\u0633\u0639\u062F \u0627\u0644\u0645\u0637\u064A\u0631\u064A", level: 4.8, avatar: "\u0633.\u0645", color: "from-blue-500 to-blue-600", short: "\u0633\u0639\u062F" },
  { id: "as3", name: "\u0639\u0645\u0631 \u0627\u0644\u0634\u0647\u0631\u064A", level: 4.5, avatar: "\u0639.\u0634", color: "from-purple-500 to-purple-600", short: "\u0639\u0645\u0631" },
  { id: "as4", name: "\u0641\u0647\u062F \u0627\u0644\u0633\u0628\u064A\u0639\u064A", level: 4.3, avatar: "\u0641.\u0633", color: "from-green-500 to-green-600", short: "\u0641\u0647\u062F" },
  { id: "as5", name: "\u062E\u0627\u0644\u062F \u0627\u0644\u0639\u0645\u0631\u064A", level: 4.1, avatar: "\u062E.\u0639", color: "from-orange-500 to-orange-600", short: "\u062E\u0627\u0644\u062F" },
  { id: "as6", name: "\u0645\u062D\u0645\u062F \u0627\u0644\u0633\u0627\u0644\u0645", level: 3.9, avatar: "\u0645.\u0633", color: "from-teal-500 to-teal-600", short: "\u0645\u062D\u0645\u062F" },
  { id: "as7", name: "\u0641\u064A\u0635\u0644 \u0627\u0644\u0639\u062A\u064A\u0628\u064A", level: 3.7, avatar: "\u0641.\u0639", color: "from-red-400 to-red-500", short: "\u0641\u064A\u0635\u0644" },
  { id: "as8", name: "\u0628\u0646\u062F\u0631 \u0627\u0644\u062D\u0631\u0628\u064A", level: 3.5, avatar: "\u0628.\u062D", color: "from-indigo-500 to-indigo-600", short: "\u0628\u0646\u062F\u0631" }
];
const soloSchedulePairings = [
  [["as1", "as8"], ["as2", "as7"], ["as3", "as6"], ["as4", "as5"]],
  [["as1", "as5"], ["as3", "as7"], ["as2", "as6"], ["as4", "as8"]],
  [["as1", "as6"], ["as4", "as7"], ["as2", "as5"], ["as3", "as8"]]
];
function makeASSoloMatch(id, tA, tB, setsCount) {
  return { id, teamA: tA, teamB: tB, scoreA: "", scoreB: "", sets: Array.from({ length: setsCount }, () => ({ sA: "", sB: "" })) };
}
function generateSoloSchedule(mode, startTime, timePerRound, setsCount) {
  return soloSchedulePairings.map(([c1a, c1b, c2a, c2b], ri) => {
    const slotStart = addMinutes(startTime, ri * (mode === "time" ? timePerRound + 2 : 0));
    const slotEnd = addMinutes(slotStart, timePerRound);
    return {
      id: `asr${ri}`,
      roundNum: ri + 1,
      court1: makeASSoloMatch(`asm${ri}c1`, c1a, c1b, setsCount),
      court2: makeASSoloMatch(`asm${ri}c2`, c2a, c2b, setsCount),
      timeSlot: mode === "time" ? `${fmtTime(slotStart)} \u2013 ${fmtTime(slotEnd)}` : `\u062C\u0648\u0644\u0629 ${ri + 1}`
    };
  });
}
function calcSoloPoints(schedule, mode) {
  const pts = {};
  americanoSoloPlayers.forEach((p) => {
    pts[p.id] = 0;
  });
  schedule.forEach((r) => {
    [r.court1, r.court2].forEach((m) => {
      let sA = 0, sB = 0;
      if (mode === "time") {
        sA = parseInt(m.scoreA) || 0;
        sB = parseInt(m.scoreB) || 0;
      } else {
        m.sets.forEach((s) => {
          sA += parseInt(s.sA) || 0;
          sB += parseInt(s.sB) || 0;
        });
      }
      m.teamA.forEach((id) => {
        pts[id] = (pts[id] || 0) + sA;
      });
      m.teamB.forEach((id) => {
        pts[id] = (pts[id] || 0) + sB;
      });
    });
  });
  return pts;
}
function isSoloScheduleComplete(schedule, mode) {
  return schedule.every(
    (r) => [r.court1, r.court2].every(
      (m) => mode === "time" ? m.scoreA !== "" && m.scoreB !== "" : m.sets.every((s) => s.sA !== "" && s.sB !== "")
    )
  );
}
const soloPlayers = [
  { id: "p1", name: "\u0645\u062D\u0645\u062F \u0623\u062D\u0645\u062F", level: "5.0", avatar: "\u0645.\u0623", color: "from-primary to-primary/80", short: "\u0645\u062D\u0645\u062F" },
  { id: "p2", name: "\u0639\u0645\u0631 \u0627\u0644\u0633\u0627\u0644\u0645", level: "4.8", avatar: "\u0639.\u0633", color: "from-blue-500 to-blue-600", short: "\u0639\u0645\u0631" },
  { id: "p3", name: "\u0641\u064A\u0635\u0644 \u0627\u0644\u0639\u062A\u064A\u0628\u064A", level: "5.2", avatar: "\u0641.\u0639", color: "from-purple-500 to-purple-600", short: "\u0641\u064A\u0635\u0644" },
  { id: "p4", name: "\u0628\u0646\u062F\u0631 \u0627\u0644\u062D\u0631\u0628\u064A", level: "4.6", avatar: "\u0628.\u062D", color: "from-orange-500 to-orange-600", short: "\u0628\u0646\u062F\u0631" }
];
const team1 = [
  { id: "p1", name: "\u0623\u062D\u0645\u062F \u0627\u0644\u0632\u0647\u0631\u0627\u0646\u064A", level: "5.5", avatar: "\u0623.\u0632", color: "from-primary to-primary/80" },
  { id: "p2", name: "\u0633\u0639\u062F \u0627\u0644\u0645\u0637\u064A\u0631\u064A", level: "5.0", avatar: "\u0633.\u0645", color: "from-blue-500 to-blue-600" }
];
const team2 = [
  { id: "p3", name: "\u062E\u0627\u0644\u062F \u0627\u0644\u0639\u0645\u0631\u064A", level: "5.2", avatar: "\u062E.\u0639", color: "from-secondary to-secondary/80" },
  { id: "p4", name: "\u0641\u0647\u062F \u0627\u0644\u0633\u0628\u064A\u0639\u064A", level: "5.8", avatar: "\u0641.\u0633", color: "from-purple-500 to-purple-600" }
];
const defaultPairings = [
  [["p1", "p2"], ["p3", "p4"]],
  [["p1", "p3"], ["p2", "p4"]],
  [["p1", "p4"], ["p2", "p3"]]
];
function makeRound(idx) {
  const [a, b] = defaultPairings[idx % 3];
  return { id: `r${Date.now()}-${idx}`, teamA: [...a], teamB: [...b], scoreA: "", scoreB: "" };
}
function MatchResultPage({ onBack, matchType }) {
  const isSolo = matchType === "\u0648\u062F\u064A\u0629 \u0641\u0631\u062F\u064A";
  const isAmericanoTeams = matchType === "\u0623\u0645\u0631\u064A\u0643\u0627\u0646\u0648 \u0641\u0631\u0642";
  const isAmericanoSolo = matchType === "\u0623\u0645\u0631\u064A\u0643\u0627\u0646\u0648 \u0641\u0631\u062F\u064A";
  const [rounds, setRounds] = useState([makeRound(0)]);
  const [submitted, setSubmitted] = useState(false);
  const [ratings, setRatings] = useState({});
  const [sets, setSets] = useState([{ t1: "", t2: "" }]);
  const [winner, setWinner] = useState(null);
  const [asSetupDone, setAsSetupDone] = useState(false);
  const [asMode, setAsMode] = useState("sets");
  const [asTimePerRound, setAsTimePerRound] = useState(15);
  const [asSetsCount, setAsSetsCount] = useState(1);
  const [asStartTime, setAsStartTime] = useState("18:00");
  const [asSchedule, setAsSchedule] = useState([]);
  const [asExpandedRound, setAsExpandedRound] = useState(null);
  const handleGenerateSoloSchedule = () => {
    setAsSchedule(generateSoloSchedule(asMode, asStartTime, asTimePerRound, asSetsCount));
    setAsSetupDone(true);
    setAsExpandedRound(0);
  };
  const updateAsScore = (roundIdx, court, field, val) => {
    setAsSchedule((prev) => prev.map(
      (r, ri) => ri !== roundIdx ? r : { ...r, [court]: { ...r[court], [field]: val } }
    ));
  };
  const updateAsSet = (roundIdx, court, setIdx, side, val) => {
    setAsSchedule((prev) => prev.map((r, ri) => {
      if (ri !== roundIdx) return r;
      const m = { ...r[court] };
      m.sets = m.sets.map((s, si) => si === setIdx ? { ...s, [side]: val } : s);
      return { ...r, [court]: m };
    }));
  };
  const asSoloPoints = calcSoloPoints(asSchedule, asMode);
  const asSoloRanked = [...americanoSoloPlayers].sort((a, b) => (asSoloPoints[b.id] || 0) - (asSoloPoints[a.id] || 0));
  const asAnyScore = asSchedule.some(
    (r) => [r.court1, r.court2].some(
      (m) => asMode === "time" ? m.scoreA !== "" || m.scoreB !== "" : m.sets.some((s) => s.sA !== "" || s.sB !== "")
    )
  );
  const asComplete = asSetupDone && isSoloScheduleComplete(asSchedule, asMode);
  const [aSetupDone, setASetupDone] = useState(false);
  const [aMode, setAMode] = useState("sets");
  const [aTimePerRound, setATimePerRound] = useState(15);
  const [aSetsCount, setASetsCount] = useState(1);
  const [aStartTime, setAStartTime] = useState("18:00");
  const [aSchedule, setASchedule] = useState([]);
  const [expandedRound, setExpandedRound] = useState(null);
  const handleGenerateSchedule = () => {
    const sched = generateSchedule(aMode, aStartTime, aTimePerRound, aSetsCount);
    setASchedule(sched);
    setASetupDone(true);
    setExpandedRound(0);
  };
  const updateAScore = (roundIdx, court, field, val) => {
    setASchedule((prev) => prev.map(
      (r, ri) => ri !== roundIdx ? r : { ...r, [court]: { ...r[court], [field]: val } }
    ));
  };
  const updateASet = (roundIdx, court, setIdx, side, val) => {
    setASchedule((prev) => prev.map((r, ri) => {
      if (ri !== roundIdx) return r;
      const m = { ...r[court] };
      m.sets = m.sets.map((s, si) => si === setIdx ? { ...s, [side]: val } : s);
      return { ...r, [court]: m };
    }));
  };
  const aPoints = calcSchedulePoints(aSchedule, aMode);
  const aRanked = [...americanoTeams].sort((a, b) => (aPoints[b.id] || 0) - (aPoints[a.id] || 0));
  const anyScoreEntered = aSchedule.some(
    (r) => [r.court1, r.court2].some(
      (m) => aMode === "time" ? m.scoreA !== "" || m.scoreB !== "" : m.sets.some((s) => s.sA !== "" || s.sB !== "")
    )
  );
  const updateRound = (id, field, value) => setRounds((rs) => rs.map((r) => r.id === id ? { ...r, [field]: value } : r));
  const addRound = () => setRounds((rs) => [...rs, makeRound(rs.length)]);
  const removeRound = (id) => setRounds((rs) => rs.filter((r) => r.id !== id));
  const swapPlayer = (roundId, pid) => {
    setRounds((rs) => rs.map((r) => {
      if (r.id !== roundId) return r;
      return r.teamA.includes(pid) ? { ...r, teamA: r.teamA.filter((x) => x !== pid), teamB: [...r.teamB, pid] } : { ...r, teamA: [...r.teamA, pid], teamB: r.teamB.filter((x) => x !== pid) };
    }));
  };
  const calcPoints = () => {
    const pts = { p1: 0, p2: 0, p3: 0, p4: 0 };
    rounds.forEach((r) => {
      const a = parseInt(r.scoreA) || 0, b = parseInt(r.scoreB) || 0;
      r.teamA.forEach((id) => {
        pts[id] = (pts[id] || 0) + a;
      });
      r.teamB.forEach((id) => {
        pts[id] = (pts[id] || 0) + b;
      });
    });
    return pts;
  };
  const points = calcPoints();
  const ranked = [...soloPlayers].sort((a, b) => (points[b.id] || 0) - (points[a.id] || 0));
  const roundsComplete = rounds.length > 0 && rounds.every(
    (r) => r.teamA.length === 2 && r.teamB.length === 2 && r.scoreA !== "" && r.scoreB !== ""
  );
  const teamComplete = sets.every((s) => s.t1 !== "" && s.t2 !== "") && winner !== null;
  const aComplete = aSetupDone && isScheduleComplete(aSchedule, aMode);
  const canSubmit = isAmericanoTeams ? aComplete : isAmericanoSolo ? asComplete : isSolo ? roundsComplete : teamComplete;
  const headerGrad = isAmericanoTeams ? "bg-gradient-to-br from-purple-700 to-purple-900" : isAmericanoSolo ? "bg-gradient-to-br from-teal-700 to-cyan-900" : isSolo ? "bg-gradient-to-br from-blue-700 to-blue-900" : "bg-gradient-to-br from-secondary to-secondary/90";
  if (submitted) {
    if (isAmericanoTeams) {
      const totalPts = americanoTeams.reduce((s, t) => s + (aPoints[t.id] || 0), 0);
      const champion = aRanked[0];
      const podium = [aRanked[1], aRanked[0], aRanked[2]];
      const podiumH = ["h-20", "h-28", "h-16"];
      const podiumLabel = ["\u{1F948}", "\u{1F947}", "\u{1F949}"];
      return <div className="flex-1 overflow-y-auto bg-background">

          {
        /* ── بانر الفائز ── */
      }
          <div className="relative bg-gradient-to-br from-purple-700 via-indigo-700 to-purple-900 px-6 pt-8 pb-10 overflow-hidden">
            {
        /* دوائر زخرفية */
      }
            <div className="absolute -top-8 -left-8 w-40 h-40 bg-white/5 rounded-full" />
            <div className="absolute top-4 -right-6 w-24 h-24 bg-white/5 rounded-full" />
            <div className="absolute bottom-0 left-1/2 -translate-x-1/2 w-64 h-64 bg-white/5 rounded-full" />

            <div className="relative">
              <button onClick={onBack} className="p-2 bg-white/20 rounded-full mb-4 inline-flex">
                <ChevronRight className="w-5 h-5 text-white" />
              </button>

              {
        /* النجمة والعنوان */
      }
              <div className="text-center mb-5">
                <div className="text-5xl mb-2">🏆</div>
                <p className="text-purple-200 text-xs tracking-widest mb-1">الفائز بالأمريكانو</p>
                <h2 className="text-white text-3xl">{champion.label}</h2>
              </div>

              {
        /* لاعبو الفريق الأول */
      }
              <div className="flex justify-center gap-4 mb-4">
                {champion.players.map((p, pi) => <div key={pi} className="flex flex-col items-center gap-2">
                    <div className={`w-16 h-16 bg-gradient-to-br ${p.color} rounded-full border-4 border-yellow-400/70 flex items-center justify-center shadow-xl`}>
                      <span className="text-white text-sm">{p.avatar}</span>
                    </div>
                    <span className="text-white/90 text-xs">{p.name.split(" ")[0]}</span>
                  </div>)}
              </div>

              {
        /* نقاط الفائز */
      }
              <div className="flex justify-center gap-6 bg-white/10 backdrop-blur-sm rounded-2xl p-3 border border-white/20">
                <div className="text-center">
                  <p className="text-yellow-300 text-xl">{aPoints[champion.id] || 0}</p>
                  <p className="text-purple-200 text-xs">نقطة</p>
                </div>
                <div className="w-px bg-white/20" />
                <div className="text-center">
                  <p className="text-yellow-300 text-xl">{totalPts > 0 ? Math.round((aPoints[champion.id] || 0) / totalPts * 100) : 0}%</p>
                  <p className="text-purple-200 text-xs">من المجموع</p>
                </div>
                <div className="w-px bg-white/20" />
                <div className="text-center">
                  <p className="text-yellow-300 text-xl">{aSchedule.length * 2}</p>
                  <p className="text-purple-200 text-xs">مباراة</p>
                </div>
              </div>
            </div>
          </div>

          <div className="px-5 py-5 space-y-5 pb-8">

            {
        /* ── منصة التتويج ── */
      }
            <div className="bg-white border border-border rounded-2xl p-5 shadow-sm">
              <p className="text-secondary text-xs text-center mb-6 flex items-center justify-center gap-2">
                <Trophy className="w-3.5 h-3.5 text-yellow-500" />المنصة
              </p>
              <div className="flex items-end justify-center gap-2 mb-4">
                {podium.map((team, pi) => <div key={team.id} className="flex flex-col items-center gap-2 flex-1">
                    {
        /* الفريق */
      }
                    <div className="flex -space-x-2 justify-center mb-1">
                      {team.players.map((p, i) => <div key={i} className={`w-9 h-9 bg-gradient-to-br ${p.color} rounded-full border-2 border-white flex items-center justify-center`}>
                          <span className="text-white text-[10px]">{p.avatar}</span>
                        </div>)}
                    </div>
                    <p className="text-secondary text-xs text-center">{team.label}</p>
                    <p className={`text-xs text-center ${pi === 1 ? "text-yellow-600" : "text-muted-foreground"}`}>
                      {aPoints[team.id] || 0} نقطة
                    </p>
                    {
        /* الكتلة */
      }
                    <div className={`w-full ${podiumH[pi]} rounded-t-xl flex items-start justify-center pt-2 ${pi === 1 ? "bg-gradient-to-b from-yellow-400 to-yellow-500" : pi === 0 ? "bg-gradient-to-b from-gray-300 to-gray-400" : "bg-gradient-to-b from-orange-300 to-orange-400"}`}>
                      <span className="text-xl">{podiumLabel[pi]}</span>
                    </div>
                  </div>)}
              </div>
            </div>

            {
        /* ── الترتيب الكامل ── */
      }
            <div className="bg-white border border-border rounded-2xl overflow-hidden shadow-sm">
              <div className="px-5 py-3 bg-purple-50 border-b border-purple-100 flex items-center gap-2">
                <Layers className="w-4 h-4 text-purple-600" />
                <p className="text-secondary text-sm">الترتيب النهائي</p>
                <span className="mr-auto text-xs text-muted-foreground">{aSchedule.length} جولة × 2 ملعب</span>
              </div>

              <div className="divide-y divide-border">
                {aRanked.map((team, i) => {
        const pts = aPoints[team.id] || 0;
        const maxPts = aPoints[aRanked[0].id] || 1;
        const pct = totalPts > 0 ? Math.round(pts / totalPts * 100) : 0;
        const rankBg = i === 0 ? "bg-gradient-to-r from-yellow-50 to-white" : "";
        return <div key={team.id} className={`px-4 py-4 ${rankBg}`}>
                      <div className="flex items-center gap-3 mb-2.5">
                        {
          /* الرتبة */
        }
                        <div className={`w-9 h-9 rounded-xl flex items-center justify-center flex-shrink-0 ${i === 0 ? "bg-gradient-to-br from-yellow-400 to-yellow-500 shadow-md" : i === 1 ? "bg-gradient-to-br from-gray-300 to-gray-400" : i === 2 ? "bg-gradient-to-br from-orange-300 to-orange-400" : "bg-gray-100"}`}>
                          <span className={`text-lg leading-none ${i < 3 ? "" : "text-sm text-muted-foreground"}`}>
                            {i < 3 ? ["\u{1F947}", "\u{1F948}", "\u{1F949}"][i] : `${i + 1}`}
                          </span>
                        </div>

                        {
          /* اللاعبون */
        }
                        <div className="flex -space-x-2 flex-shrink-0">
                          {team.players.map((p, pi) => <div key={pi} className={`w-10 h-10 bg-gradient-to-br ${p.color} rounded-full border-2 border-white flex items-center justify-center shadow-sm`}>
                              <span className="text-white text-xs">{p.avatar}</span>
                            </div>)}
                        </div>

                        {
          /* المعلومات */
        }
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-2">
                            <p className="text-secondary text-sm">{team.label}</p>
                            <span className={`text-[10px] px-1.5 py-0.5 rounded-full border ${teamAccent[team.id]}`}>
                              {team.avgLevel}
                            </span>
                            {i === 0 && <span className="text-[10px] text-yellow-600 bg-yellow-100 px-1.5 py-0.5 rounded-full">الفائز 🏆</span>}
                          </div>
                          <p className="text-xs text-muted-foreground mt-0.5">
                            {team.players.map((p) => p.name.split(" ")[0]).join(" & ")}
                          </p>
                        </div>

                        {
          /* النقاط */
        }
                        <div className="text-left flex-shrink-0">
                          <p className={`text-lg leading-none ${i === 0 ? "text-yellow-600" : "text-secondary"}`}>{pts}</p>
                          <p className="text-xs text-muted-foreground">{pct}%</p>
                        </div>
                      </div>

                      {
          /* شريط النقاط */
        }
                      <div className="h-2 bg-gray-100 rounded-full overflow-hidden mr-12">
                        <div
          className={`h-full rounded-full transition-all duration-700 ${i === 0 ? "bg-gradient-to-r from-yellow-400 to-yellow-500" : i === 1 ? "bg-gradient-to-r from-gray-400 to-gray-500" : i === 2 ? "bg-gradient-to-r from-orange-400 to-orange-500" : "bg-purple-300"}`}
          style={{ width: `${maxPts > 0 ? pts / maxPts * 100 : 0}%` }}
        />
                      </div>
                    </div>;
      })}
              </div>

              {
        /* ملخص */
      }
              <div className="px-4 py-3 bg-gray-50 border-t border-border">
                <div className="grid grid-cols-3 gap-3 text-center">
                  <div>
                    <p className="text-secondary text-sm">{totalPts}</p>
                    <p className="text-xs text-muted-foreground">إجمالي النقاط</p>
                  </div>
                  <div>
                    <p className="text-secondary text-sm">{aSchedule.length}</p>
                    <p className="text-xs text-muted-foreground">جولات</p>
                  </div>
                  <div>
                    <p className="text-secondary text-sm">{aSchedule.length * 2}</p>
                    <p className="text-xs text-muted-foreground">مباريات</p>
                  </div>
                </div>
              </div>
            </div>

            {
        /* ── تقييم اللاعبين ── */
      }
            <div className="bg-white border border-border rounded-2xl overflow-hidden shadow-sm">
              <div className="px-5 py-3 bg-gray-50 border-b border-border flex items-center gap-2">
                <Star className="w-4 h-4 text-yellow-500" />
                <p className="text-secondary text-sm">قيّم اللاعبين</p>
              </div>
              <div className="divide-y divide-border">
                {aRanked.map((team, ti) => <div key={team.id} className="px-4 py-3">
                    <p className="text-xs text-muted-foreground mb-2 flex items-center gap-1.5">
                      <span className="text-base">{["\u{1F947}", "\u{1F948}", "\u{1F949}", "4\uFE0F\u20E3"][ti]}</span>
                      {team.label}
                    </p>
                    <div className="space-y-2">
                      {team.players.map((p) => {
        const rid = `${team.id}-${p.avatar}`;
        return <div key={rid} className="flex items-center gap-3">
                            <div className={`w-8 h-8 bg-gradient-to-br ${p.color} rounded-full flex items-center justify-center flex-shrink-0`}>
                              <span className="text-white text-[10px]">{p.avatar}</span>
                            </div>
                            <span className="flex-1 text-secondary text-xs">{p.name}</span>
                            <div className="flex gap-0.5">
                              {[1, 2, 3, 4, 5].map((s) => <button key={s} onClick={() => setRatings((r) => ({ ...r, [rid]: s }))}>
                                  <Star className={`w-5 h-5 ${ratings[rid] >= s ? "text-yellow-400 fill-yellow-400" : "text-gray-200"}`} />
                                </button>)}
                            </div>
                          </div>;
      })}
                    </div>
                  </div>)}
              </div>
            </div>

            <button onClick={onBack} className="w-full py-4 bg-gradient-to-r from-purple-600 to-indigo-600 text-white rounded-xl text-sm shadow-md">
              العودة للمباريات
            </button>
          </div>
        </div>;
    }
    if (isAmericanoSolo) {
      const totalPts = americanoSoloPlayers.reduce((s, p) => s + (asSoloPoints[p.id] || 0), 0);
      const champion = asSoloRanked[0];
      const podium = [asSoloRanked[1], asSoloRanked[0], asSoloRanked[2]];
      const podiumH = ["h-20", "h-28", "h-16"];
      const podiumLbl = ["\u{1F948}", "\u{1F947}", "\u{1F949}"];
      return <div className="flex-1 overflow-y-auto bg-background">

          {
        /* بانر الفائز */
      }
          <div className="relative bg-gradient-to-br from-teal-700 via-cyan-700 to-teal-900 px-6 pt-8 pb-10 overflow-hidden">
            <div className="absolute -top-8 -left-8 w-40 h-40 bg-white/5 rounded-full" />
            <div className="absolute top-4 -right-6 w-24 h-24 bg-white/5 rounded-full" />
            <div className="absolute bottom-0 left-1/2 -translate-x-1/2 w-64 h-64 bg-white/5 rounded-full" />

            <div className="relative">
              <button onClick={onBack} className="p-2 bg-white/20 rounded-full mb-4 inline-flex">
                <ChevronRight className="w-5 h-5 text-white" />
              </button>

              <div className="text-center mb-5">
                <div className="text-5xl mb-2">🏆</div>
                <p className="text-teal-200 text-xs tracking-widest mb-1">الفائز بأمريكانو فردي</p>
                <h2 className="text-white text-3xl">{champion.name.split(" ")[0]}</h2>
                <p className="text-teal-200 text-sm mt-0.5">{champion.name}</p>
              </div>

              <div className="flex justify-center mb-4">
                <div className={`w-20 h-20 bg-gradient-to-br ${champion.color} rounded-full border-4 border-yellow-400/70 flex items-center justify-center shadow-xl`}>
                  <span className="text-white text-sm">{champion.avatar}</span>
                </div>
              </div>

              <div className="flex justify-center gap-6 bg-white/10 backdrop-blur-sm rounded-2xl p-3 border border-white/20">
                <div className="text-center">
                  <p className="text-yellow-300 text-xl">{asSoloPoints[champion.id] || 0}</p>
                  <p className="text-teal-200 text-xs">نقطة</p>
                </div>
                <div className="w-px bg-white/20" />
                <div className="text-center">
                  <p className="text-yellow-300 text-xl">{totalPts > 0 ? Math.round((asSoloPoints[champion.id] || 0) / totalPts * 100) : 0}%</p>
                  <p className="text-teal-200 text-xs">من المجموع</p>
                </div>
                <div className="w-px bg-white/20" />
                <div className="text-center">
                  <p className="text-yellow-300 text-xl">{asSchedule.length * 2}</p>
                  <p className="text-teal-200 text-xs">مباراة</p>
                </div>
              </div>
            </div>
          </div>

          <div className="px-5 py-5 space-y-5 pb-8">

            {
        /* منصة التتويج */
      }
            <div className="bg-white border border-border rounded-2xl p-5 shadow-sm">
              <p className="text-secondary text-xs text-center mb-6 flex items-center justify-center gap-2">
                <Trophy className="w-3.5 h-3.5 text-yellow-500" />المنصة
              </p>
              <div className="flex items-end justify-center gap-2 mb-4">
                {podium.map((player, pi) => <div key={player.id} className="flex flex-col items-center gap-2 flex-1">
                    <div className={`w-12 h-12 bg-gradient-to-br ${player.color} rounded-full border-2 border-white flex items-center justify-center shadow-md`}>
                      <span className="text-white text-xs">{player.avatar}</span>
                    </div>
                    <p className="text-secondary text-xs text-center">{player.short}</p>
                    <p className={`text-xs text-center ${pi === 1 ? "text-yellow-600" : "text-muted-foreground"}`}>
                      {asSoloPoints[player.id] || 0} نقطة
                    </p>
                    <div className={`w-full ${podiumH[pi]} rounded-t-xl flex items-start justify-center pt-2 ${pi === 1 ? "bg-gradient-to-b from-yellow-400 to-yellow-500" : pi === 0 ? "bg-gradient-to-b from-gray-300 to-gray-400" : "bg-gradient-to-b from-orange-300 to-orange-400"}`}>
                      <span className="text-xl">{podiumLbl[pi]}</span>
                    </div>
                  </div>)}
              </div>
            </div>

            {
        /* الترتيب الكامل */
      }
            <div className="bg-white border border-border rounded-2xl overflow-hidden shadow-sm">
              <div className="px-5 py-3 bg-teal-50 border-b border-teal-100 flex items-center gap-2">
                <Layers className="w-4 h-4 text-teal-600" />
                <p className="text-secondary text-sm">الترتيب النهائي</p>
                <span className="mr-auto text-xs text-muted-foreground">8 لاعبين</span>
              </div>
              <div className="divide-y divide-border">
                {asSoloRanked.map((player, i) => {
        const pts = asSoloPoints[player.id] || 0;
        const maxPts = asSoloPoints[asSoloRanked[0].id] || 1;
        const pct = totalPts > 0 ? Math.round(pts / totalPts * 100) : 0;
        const medal = ["\u{1F947}", "\u{1F948}", "\u{1F949}", "4\uFE0F\u20E3", "5\uFE0F\u20E3", "6\uFE0F\u20E3", "7\uFE0F\u20E3", "8\uFE0F\u20E3"][i];
        return <div key={player.id} className={`px-4 py-3 ${i === 0 ? "bg-gradient-to-r from-yellow-50 to-white" : ""}`}>
                      <div className="flex items-center gap-3 mb-2">
                        <div className={`w-8 h-8 rounded-xl flex items-center justify-center flex-shrink-0 ${i === 0 ? "bg-gradient-to-br from-yellow-400 to-yellow-500 shadow-md" : i === 1 ? "bg-gradient-to-br from-gray-300 to-gray-400" : i === 2 ? "bg-gradient-to-br from-orange-300 to-orange-400" : "bg-gray-100"}`}>
                          <span className={`${i < 3 ? "text-lg leading-none" : "text-sm text-muted-foreground"}`}>
                            {i < 3 ? medal : `${i + 1}`}
                          </span>
                        </div>
                        <div className={`w-10 h-10 bg-gradient-to-br ${player.color} rounded-full border-2 border-white flex items-center justify-center shadow-sm flex-shrink-0`}>
                          <span className="text-white text-xs">{player.avatar}</span>
                        </div>
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-2">
                            <p className="text-secondary text-sm truncate">{player.name}</p>
                            <span className="text-[10px] px-1.5 py-0.5 rounded-full border bg-teal-50 text-teal-700 border-teal-200 flex-shrink-0">
                              {player.level}
                            </span>
                            {i === 0 && <span className="text-[10px] text-yellow-600 bg-yellow-100 px-1.5 py-0.5 rounded-full flex-shrink-0">الفائز 🏆</span>}
                          </div>
                          <div className="mt-1.5 h-1.5 bg-gray-100 rounded-full overflow-hidden">
                            <div
          className={`h-full rounded-full transition-all duration-700 ${i === 0 ? "bg-gradient-to-r from-yellow-400 to-yellow-500" : i === 1 ? "bg-gradient-to-r from-gray-400 to-gray-500" : i === 2 ? "bg-gradient-to-r from-orange-400 to-orange-500" : "bg-teal-300"}`}
          style={{ width: `${maxPts > 0 ? pts / maxPts * 100 : 0}%` }}
        />
                          </div>
                        </div>
                        <div className="text-left flex-shrink-0">
                          <p className={`text-base leading-none ${i === 0 ? "text-yellow-600" : "text-secondary"}`}>{pts}</p>
                          <p className="text-xs text-muted-foreground">{pct}%</p>
                        </div>
                      </div>
                    </div>;
      })}
              </div>
              <div className="px-4 py-3 bg-gray-50 border-t border-border">
                <div className="grid grid-cols-3 gap-3 text-center">
                  <div>
                    <p className="text-secondary text-sm">{totalPts}</p>
                    <p className="text-xs text-muted-foreground">إجمالي النقاط</p>
                  </div>
                  <div>
                    <p className="text-secondary text-sm">{asSchedule.length}</p>
                    <p className="text-xs text-muted-foreground">جولات</p>
                  </div>
                  <div>
                    <p className="text-secondary text-sm">{asSchedule.length * 2}</p>
                    <p className="text-xs text-muted-foreground">مباريات</p>
                  </div>
                </div>
              </div>
            </div>

            {
        /* تقييم اللاعبين */
      }
            <div className="bg-white border border-border rounded-2xl overflow-hidden shadow-sm">
              <div className="px-5 py-3 bg-gray-50 border-b border-border flex items-center gap-2">
                <Star className="w-4 h-4 text-yellow-500" />
                <p className="text-secondary text-sm">قيّم اللاعبين</p>
              </div>
              <div className="divide-y divide-border">
                {asSoloRanked.map((player, i) => <div key={player.id} className="flex items-center gap-3 px-4 py-3">
                    <span className="text-base w-7 text-center">{["\u{1F947}", "\u{1F948}", "\u{1F949}", "4\uFE0F\u20E3", "5\uFE0F\u20E3", "6\uFE0F\u20E3", "7\uFE0F\u20E3", "8\uFE0F\u20E3"][i]}</span>
                    <div className={`w-9 h-9 bg-gradient-to-br ${player.color} rounded-full flex items-center justify-center flex-shrink-0`}>
                      <span className="text-white text-[10px]">{player.avatar}</span>
                    </div>
                    <span className="flex-1 text-secondary text-xs">{player.name}</span>
                    <div className="flex gap-0.5">
                      {[1, 2, 3, 4, 5].map((s) => <button key={s} onClick={() => setRatings((r) => ({ ...r, [player.id]: s }))}>
                          <Star className={`w-5 h-5 ${ratings[player.id] >= s ? "text-yellow-400 fill-yellow-400" : "text-gray-200"}`} />
                        </button>)}
                    </div>
                  </div>)}
              </div>
            </div>

            <button onClick={onBack} className="w-full py-4 bg-gradient-to-r from-teal-600 to-cyan-600 text-white rounded-xl text-sm shadow-md">
              العودة للمباريات
            </button>
          </div>
        </div>;
    }
    return <div className="flex-1 flex flex-col bg-background overflow-y-auto">
        <div className={`text-white px-6 pt-8 pb-6 ${headerGrad}`}>
          <div className="flex items-center gap-3">
            <button onClick={onBack} className="p-2 bg-white/20 rounded-full"><ChevronRight className="w-5 h-5" /></button>
            <h1 className="text-2xl">نتيجة المباراة</h1>
          </div>
        </div>

        <div className="px-5 py-6 space-y-5">
          <div className={`rounded-2xl p-5 border ${isSolo ? "bg-gradient-to-br from-blue-50 to-blue-100 border-blue-300" : "bg-gradient-to-br from-yellow-50 to-yellow-100 border-yellow-300"}`}>
            <div className="text-center mb-4">
              <div className="text-4xl mb-1">🏆</div>
              <p className="text-secondary text-sm">الترتيب النهائي</p>
            </div>
            {isSolo ? <div className="space-y-2">
                {ranked.map((p, i) => <div key={p.id} className={`flex items-center gap-3 px-3 py-2.5 rounded-xl ${i === 0 ? "bg-yellow-100 border border-yellow-300" : i === 1 ? "bg-gray-100" : "bg-white/60"}`}>
                    <span className="text-xl w-7 text-center">{["\u{1F947}", "\u{1F948}", "\u{1F949}", "4\uFE0F\u20E3"][i]}</span>
                    <div className={`w-9 h-9 bg-gradient-to-br ${p.color} rounded-full flex items-center justify-center`}>
                      <span className="text-white text-xs">{p.avatar}</span>
                    </div>
                    <span className="flex-1 text-secondary text-sm">{p.name}</span>
                    <span className={`text-sm ${i === 0 ? "text-yellow-600" : "text-muted-foreground"}`}>{points[p.id] || 0} نقطة</span>
                  </div>)}
              </div> : <div className="flex justify-center gap-4">
                {(winner === "team1" ? team1 : team2).map((p) => <div key={p.id} className="flex flex-col items-center gap-1">
                    <div className={`w-12 h-12 bg-gradient-to-br ${p.color} rounded-full flex items-center justify-center`}>
                      <span className="text-white text-sm">{p.avatar}</span>
                    </div>
                    <span className="text-xs text-secondary">{p.name.split(" ")[0]}</span>
                  </div>)}
              </div>}
          </div>

          <div className="bg-white border border-border rounded-2xl p-5">
            <h3 className="text-secondary text-sm mb-4 flex items-center gap-2">
              <Star className="w-4 h-4 text-yellow-500" />قيّم اللاعبين
            </h3>
            <div className="space-y-3">
              {(isSolo ? soloPlayers : [...team1, ...team2]).map((p) => <div key={p.id} className="flex items-center gap-3">
                  <div className={`w-9 h-9 bg-gradient-to-br ${p.color} rounded-full flex items-center justify-center`}>
                    <span className="text-white text-xs">{p.avatar}</span>
                  </div>
                  <span className="flex-1 text-secondary text-xs">{p.name}</span>
                  <div className="flex gap-1">
                    {[1, 2, 3, 4, 5].map((s) => <button key={s} onClick={() => setRatings((r) => ({ ...r, [p.id]: s }))}>
                        <Star className={`w-5 h-5 ${ratings[p.id] >= s ? "text-yellow-400 fill-yellow-400" : "text-gray-200"}`} />
                      </button>)}
                  </div>
                </div>)}
            </div>
          </div>

          <button onClick={onBack} className={`w-full py-4 text-white rounded-xl text-sm ${isSolo ? "bg-blue-500" : "bg-primary"}`}>
            العودة للمباريات
          </button>
        </div>
      </div>;
  }
  return <div className="flex-1 overflow-y-auto bg-background">

      {
    /* Header */
  }
      <div className={`text-white px-6 pt-8 pb-6 ${headerGrad}`}>
        <div className="flex items-center gap-3 mb-3">
          <button onClick={onBack} className="p-2 bg-white/20 rounded-full backdrop-blur-sm">
            <ChevronRight className="w-5 h-5" />
          </button>
          <div>
            <h1 className="text-2xl">تفاصيل المباراة</h1>
            <p className="text-white/70 text-xs mt-0.5">
              {isAmericanoTeams ? "\u0623\u0645\u0631\u064A\u0643\u0627\u0646\u0648 \u0641\u0631\u0642" : isAmericanoSolo ? "\u0623\u0645\u0631\u064A\u0643\u0627\u0646\u0648 \u0641\u0631\u062F\u064A" : isSolo ? "\u0648\u062F\u064A\u0629 \u0641\u0631\u062F\u064A" : "\u062A\u062D\u062F\u064A \u0641\u0631\u0642"}
            </p>
          </div>
        </div>
        <span className="inline-flex items-center gap-1.5 px-3 py-1 bg-white/20 text-white text-sm rounded-full">
          <CheckCircle className="w-3.5 h-3.5" />مكتمل — أدخل النتائج
        </span>
      </div>

      <div className="px-5 py-5 space-y-4 pb-8">

        {
    /* بطاقة المعلومات */
  }
        <div className="bg-white border border-border rounded-2xl p-4 shadow-sm">
          <div className="flex items-center gap-2 mb-3 flex-wrap">
            <span className={`px-3 py-1 text-white text-xs rounded-full ${isAmericanoTeams ? "bg-purple-600" : isAmericanoSolo ? "bg-teal-600" : isSolo ? "bg-blue-500" : "bg-green-500"}`}>
              {isAmericanoTeams ? "\u0645\u0643\u062A\u0645\u0644 8/8" : isAmericanoSolo ? "\u0645\u0643\u062A\u0645\u0644 8/8" : "\u0645\u0643\u062A\u0645\u0644\u0629 4/4"}
            </span>
            <span className={`px-3 py-1 text-xs rounded-full ${isAmericanoTeams ? "bg-purple-100 text-purple-600" : isAmericanoSolo ? "bg-teal-100 text-teal-700" : isSolo ? "bg-blue-100 text-blue-600" : "bg-purple-100 text-purple-600"}`}>
              {isAmericanoTeams ? "\u0623\u0645\u0631\u064A\u0643\u0627\u0646\u0648 \u0641\u0631\u0642" : isAmericanoSolo ? "\u0623\u0645\u0631\u064A\u0643\u0627\u0646\u0648 \u0641\u0631\u062F\u064A" : isSolo ? "\u0648\u062F\u064A\u0629 \u0641\u0631\u062F\u064A" : "\u062A\u062D\u062F\u064A \u0641\u0631\u0642"}
            </span>
          </div>
          <div className="space-y-2 text-sm">
            <div className="flex items-center gap-2 text-secondary">
              <MapPin className={`w-4 h-4 ${isAmericanoTeams ? "text-purple-600" : isAmericanoSolo ? "text-teal-600" : isSolo ? "text-blue-500" : "text-primary"}`} />
              <span>{isAmericanoTeams ? "\u0646\u0627\u062F\u064A \u0627\u0644\u0628\u0627\u062F\u0644 \u0627\u0644\u0645\u0644\u0643\u064A \u2022 \u0645\u0644\u0639\u0628\u0627\u0646" : isAmericanoSolo ? "\u0646\u0627\u062F\u064A \u0627\u0644\u0646\u062E\u0628\u0629 \u0644\u0644\u0628\u0627\u062F\u0644 \u2022 \u0645\u0644\u0639\u0628\u0627\u0646" : isSolo ? "\u0645\u0644\u0639\u0628 \u0627\u0644\u0623\u0646\u062F\u064A\u0629 \u0627\u0644\u0634\u0631\u0642\u064A\u0629" : "\u0646\u0627\u062F\u064A \u0627\u0644\u0646\u062E\u0628\u0629 \u0644\u0644\u0628\u0627\u062F\u0644"}</span>
            </div>
            <div className="flex items-center gap-2 text-secondary">
              <Clock className={`w-4 h-4 ${isAmericanoTeams ? "text-purple-600" : isAmericanoSolo ? "text-teal-600" : isSolo ? "text-blue-500" : "text-primary"}`} />
              <span>اليوم، السبت 6 يونيو • {isAmericanoTeams ? "6:00 \u0645\u0633\u0627\u0621\u064B" : isAmericanoSolo ? "4:00 \u0645\u0633\u0627\u0621\u064B" : isSolo ? "7:30 \u0645\u0633\u0627\u0621\u064B" : "5:00 \u0645\u0633\u0627\u0621\u064B"}</span>
            </div>
          </div>
        </div>

        {
    /* ══════════════════════════════
        ═══ أمريكانو فرق ═══
    ══════════════════════════════ */
  }
        {isAmericanoTeams && <>
            {
    /* الفرق الأربعة */
  }
            <div className="bg-white border border-border rounded-2xl overflow-hidden shadow-sm">
              <div className="px-5 py-3 bg-purple-50 border-b border-purple-100 flex items-center gap-2">
                <Layers className="w-4 h-4 text-purple-600" />
                <p className="text-secondary text-sm">الفرق المشاركة</p>
                <span className="mr-auto text-xs text-purple-600 bg-purple-100 px-2 py-0.5 rounded-full">4 فرق</span>
              </div>
              <div className="grid grid-cols-2 gap-px bg-border">
                {americanoTeams.map((team) => <div key={team.id} className="bg-white p-4">
                    <div className={`h-1.5 rounded-full bg-gradient-to-r ${teamHeaderColor[team.id]} mb-3`} />
                    <div className="flex items-center justify-between mb-2">
                      <p className="text-secondary text-sm">{team.label}</p>
                      <span className={`text-[10px] px-1.5 py-0.5 rounded-full border ${teamAccent[team.id]}`}>
                        {team.avgLevel}
                      </span>
                    </div>
                    <div className="space-y-2">
                      {team.players.map((p, pi) => <div key={pi} className="flex items-center gap-2">
                          <div className={`w-7 h-7 bg-gradient-to-br ${p.color} rounded-full flex items-center justify-center flex-shrink-0`}>
                            <span className="text-white text-[10px]">{p.avatar}</span>
                          </div>
                          <p className="text-secondary text-xs">{p.name}</p>
                        </div>)}
                    </div>
                  </div>)}
              </div>
            </div>

            {
    /* ── إعداد الجدول (قبل التوليد) ── */
  }
            {!aSetupDone && <div className="bg-white border-2 border-purple-200 rounded-2xl overflow-hidden shadow-sm">
                <div className="px-5 py-4 bg-gradient-to-r from-purple-600 to-indigo-600">
                  <h3 className="text-white text-sm flex items-center gap-2">
                    <Trophy className="w-4 h-4" />
                    إعداد جدول المباريات
                  </h3>
                  <p className="text-purple-200 text-xs mt-1">سيتم توزيع الفرق تلقائياً بشكل عادل</p>
                </div>

                <div className="p-5 space-y-5">
                  {
    /* اختيار النوع */
  }
                  <div>
                    <p className="text-secondary text-xs mb-3 flex items-center gap-1.5">
                      <Info className="w-3.5 h-3.5 text-purple-500" />
                      نوع الجولة
                    </p>
                    <div className="grid grid-cols-2 gap-3">
                      <button
    onClick={() => setAMode("time")}
    className={`flex flex-col items-center gap-2 p-4 rounded-2xl border-2 transition-all ${aMode === "time" ? "bg-purple-600 border-purple-600 text-white shadow-md" : "bg-white border-border text-secondary hover:border-purple-300"}`}
  >
                        <Timer className={`w-6 h-6 ${aMode === "time" ? "text-white" : "text-purple-500"}`} />
                        <div className="text-center">
                          <p className="text-sm">بالوقت</p>
                          <p className={`text-xs mt-0.5 ${aMode === "time" ? "text-purple-200" : "text-muted-foreground"}`}>
                            دقائق لكل جولة
                          </p>
                        </div>
                      </button>
                      <button
    onClick={() => setAMode("sets")}
    className={`flex flex-col items-center gap-2 p-4 rounded-2xl border-2 transition-all ${aMode === "sets" ? "bg-purple-600 border-purple-600 text-white shadow-md" : "bg-white border-border text-secondary hover:border-purple-300"}`}
  >
                        <Hash className={`w-6 h-6 ${aMode === "sets" ? "text-white" : "text-purple-500"}`} />
                        <div className="text-center">
                          <p className="text-sm">بالأشواط</p>
                          <p className={`text-xs mt-0.5 ${aMode === "sets" ? "text-purple-200" : "text-muted-foreground"}`}>
                            أشواط لكل مباراة
                          </p>
                        </div>
                      </button>
                    </div>
                  </div>

                  {
    /* إعدادات الوقت */
  }
                  {aMode === "time" && <div className="space-y-4">
                      <div>
                        <label className="text-secondary text-xs mb-2 block">مدة الجولة (دقيقة)</label>
                        <div className="flex items-center gap-3">
                          {[10, 12, 15, 20].map((v) => <button
    key={v}
    onClick={() => setATimePerRound(v)}
    className={`flex-1 py-2.5 rounded-xl border-2 text-sm transition-all ${aTimePerRound === v ? "bg-purple-600 border-purple-600 text-white" : "border-border text-secondary hover:border-purple-300"}`}
  >
                              {v}
                            </button>)}
                        </div>
                      </div>
                      <div>
                        <label className="text-secondary text-xs mb-2 block">وقت البداية</label>
                        <input
    type="time"
    value={aStartTime}
    onChange={(e) => setAStartTime(e.target.value)}
    className="w-full border-2 border-border rounded-xl px-4 py-3 text-secondary text-sm outline-none focus:border-purple-400"
  />
                      </div>
                    </div>}

                  {
    /* إعدادات الأشواط */
  }
                  {aMode === "sets" && <div>
                      <label className="text-secondary text-xs mb-3 block">عدد الأشواط لكل مباراة</label>
                      {
    /* اختصارات سريعة */
  }
                      <div className="flex gap-2 mb-3 overflow-x-auto pb-1">
                        {[1, 2, 3, 4, 5, 6].map((v) => <button
    key={v}
    onClick={() => setASetsCount(v)}
    className={`flex-shrink-0 w-11 h-11 rounded-xl border-2 text-sm transition-all ${aSetsCount === v ? "bg-purple-600 border-purple-600 text-white shadow-md" : "border-border text-secondary hover:border-purple-300 bg-white"}`}
  >
                            {v}
                          </button>)}
                      </div>
                      {
    /* عداد مخصص */
  }
                      <div className="flex items-center gap-3 bg-gray-50 rounded-xl p-3 border border-border">
                        <button
    onClick={() => setASetsCount((c) => Math.max(1, c - 1))}
    className="w-9 h-9 bg-white border-2 border-border rounded-lg flex items-center justify-center text-secondary hover:border-purple-400 transition-colors"
  >
                          −
                        </button>
                        <div className="flex-1 text-center">
                          <p className="text-secondary text-xl">{aSetsCount}</p>
                          <p className="text-xs text-muted-foreground">
                            {aSetsCount === 1 ? "\u0634\u0648\u0637 \u0648\u0627\u062D\u062F" : aSetsCount === 2 ? "\u0634\u0648\u0637\u0627\u0646" : `${aSetsCount} \u0623\u0634\u0648\u0627\u0637`}
                          </p>
                        </div>
                        <button
    onClick={() => setASetsCount((c) => Math.min(20, c + 1))}
    className="w-9 h-9 bg-purple-600 text-white rounded-lg flex items-center justify-center hover:bg-purple-700 transition-colors"
  >
                          +
                        </button>
                      </div>
                    </div>}

                  {
    /* مبادئ التوزيع العادل */
  }
                  <div className="bg-purple-50 border border-purple-200 rounded-xl p-4">
                    <p className="text-purple-700 text-xs mb-2">✦ مبادئ التوزيع العادل</p>
                    <div className="space-y-1.5 text-xs text-purple-600">
                      <p className="flex items-center gap-1.5"><CheckCircle className="w-3 h-3 flex-shrink-0" /> توازن المستويات: الأقوى يلعب ضد الأضعف أولاً</p>
                      <p className="flex items-center gap-1.5"><CheckCircle className="w-3 h-3 flex-shrink-0" /> تنوع الخصوم: كل فريق يلعب ضد فرق مختلفة</p>
                      <p className="flex items-center gap-1.5"><CheckCircle className="w-3 h-3 flex-shrink-0" /> عدم التكرار: 3 جولات × 2 ملاعب = 6 مباريات فريدة</p>
                    </div>
                  </div>

                  <button
    onClick={handleGenerateSchedule}
    className="w-full py-4 bg-gradient-to-r from-purple-600 to-indigo-600 text-white rounded-xl shadow-md flex items-center justify-center gap-2 text-sm"
  >
                    <Trophy className="w-4 h-4" />
                    توليد جدول المباريات
                  </button>
                </div>
              </div>}

            {
    /* ── جدول المباريات (بعد التوليد) ── */
  }
            {aSetupDone && <>
                {
    /* رأس الجدول */
  }
                <div className="bg-gradient-to-r from-purple-600 to-indigo-600 rounded-2xl p-4 shadow-md">
                  <div className="flex items-center justify-between mb-3">
                    <div>
                      <h3 className="text-white text-sm">جدول المباريات</h3>
                      <p className="text-purple-200 text-xs mt-0.5">
                        {aMode === "time" ? `${aTimePerRound} \u062F\u0642\u064A\u0642\u0629 \u0644\u0643\u0644 \u062C\u0648\u0644\u0629 \u2022 \u0627\u0628\u062A\u062F\u0627\u0621\u064B ${fmtTime(aStartTime)}` : `${aSetsCount === 1 ? "\u0634\u0648\u0637 \u0648\u0627\u062D\u062F" : aSetsCount === 2 ? "\u0634\u0648\u0637\u0627\u0646" : "3 \u0623\u0634\u0648\u0627\u0637"} \u0644\u0643\u0644 \u0645\u0628\u0627\u0631\u0627\u0629`}
                      </p>
                    </div>
                    <button
    onClick={() => setASetupDone(false)}
    className="text-xs text-purple-200 bg-white/20 px-3 py-1.5 rounded-lg hover:bg-white/30"
  >
                      تعديل
                    </button>
                  </div>
                  {
    /* ملخص الجولات */
  }
                  <div className="grid grid-cols-3 gap-2">
                    {aSchedule.map((r, ri) => {
    const done = [r.court1, r.court2].every(
      (m) => aMode === "time" ? m.scoreA !== "" && m.scoreB !== "" : m.sets.every((s) => s.sA !== "" && s.sB !== "")
    );
    return <button
      key={r.id}
      onClick={() => setExpandedRound(expandedRound === ri ? null : ri)}
      className={`p-2.5 rounded-xl text-center transition-all border ${done ? "bg-green-500/30 border-green-400/50 text-white" : expandedRound === ri ? "bg-white/30 border-white/50 text-white" : "bg-white/10 border-white/20 text-purple-200 hover:bg-white/20"}`}
    >
                          <p className="text-xs">جولة {r.roundNum}</p>
                          {aMode === "time" && <p className="text-[10px] mt-0.5 opacity-80">{r.timeSlot}</p>}
                          {done && <CheckCircle className="w-3 h-3 mx-auto mt-1 text-green-300" />}
                        </button>;
  })}
                  </div>
                </div>

                {
    /* تفاصيل الجولات */
  }
                <div className="space-y-3">
                  {aSchedule.map((round, ri) => {
    const isOpen = expandedRound === ri;
    const roundDone = [round.court1, round.court2].every(
      (m) => aMode === "time" ? m.scoreA !== "" && m.scoreB !== "" : m.sets.every((s) => s.sA !== "" && s.sB !== "")
    );
    return <div key={round.id} className={`bg-white rounded-2xl overflow-hidden shadow-sm border-2 transition-all ${roundDone ? "border-green-300" : isOpen ? "border-purple-400" : "border-border"}`}>
                        {
      /* رأس الجولة */
    }
                        <button
      onClick={() => setExpandedRound(isOpen ? null : ri)}
      className={`w-full flex items-center justify-between px-4 py-3.5 ${roundDone ? "bg-green-50" : isOpen ? "bg-purple-50" : "bg-gray-50"}`}
    >
                          <div className="flex items-center gap-3">
                            <div className={`w-7 h-7 rounded-full flex items-center justify-center flex-shrink-0 ${roundDone ? "bg-green-500" : "bg-purple-600"}`}>
                              {roundDone ? <CheckCircle className="w-4 h-4 text-white" /> : <span className="text-white text-xs">{round.roundNum}</span>}
                            </div>
                            <div className="text-right">
                              <p className={`text-sm ${roundDone ? "text-green-700" : "text-secondary"}`}>
                                الجولة {round.roundNum}
                              </p>
                              <p className="text-xs text-muted-foreground">{round.timeSlot}</p>
                            </div>
                          </div>
                          <div className="flex items-center gap-2">
                            {roundDone && <span className="text-xs text-green-600 bg-green-100 px-2 py-0.5 rounded-full">مكتملة</span>}
                            {isOpen ? <ChevronUp className="w-4 h-4 text-muted-foreground" /> : <ChevronDown className="w-4 h-4 text-muted-foreground" />}
                          </div>
                        </button>

                        {
      /* تفاصيل المباريات */
    }
                        {isOpen && <div className="p-4 space-y-4">
                            {[
      { label: "\u0645\u0644\u0639\u0628 1", courtKey: "court1", m: round.court1 },
      { label: "\u0645\u0644\u0639\u0628 2", courtKey: "court2", m: round.court2 }
    ].map(({ label, courtKey, m }) => {
      const tA = americanoTeams.find((t) => t.id === m.teamA);
      const tB = americanoTeams.find((t) => t.id === m.teamB);
      const levelDiff = Math.abs(tA.avgLevel - tB.avgLevel).toFixed(2);
      return <div key={label} className="border border-border rounded-2xl overflow-hidden">
                                  {
        /* رأس الملعب */
      }
                                  <div className="flex items-center justify-between px-3 py-2 bg-gray-50 border-b border-border">
                                    <span className="text-xs text-muted-foreground">{label}</span>
                                    <span className="text-[10px] text-muted-foreground bg-white border border-border px-2 py-0.5 rounded-full">
                                      فرق المستوى: {levelDiff}
                                    </span>
                                  </div>

                                  <div className="p-3">
                                    {
        /* وضع الوقت */
      }
                                    {aMode === "time" && <div className="flex items-center gap-2">
                                        <div className="flex-1 text-center">
                                          <div className="mb-2">
                                            <TeamChip team={tA} size="sm" />
                                            <p className="text-[10px] text-muted-foreground mt-0.5">مستوى {tA.avgLevel}</p>
                                          </div>
                                          <input
        type="text"
        inputMode="numeric"
        value={m.scoreA}
        onChange={(e) => updateAScore(ri, courtKey, "scoreA", e.target.value.replace(/\D/g, "").slice(0, 3))}
        placeholder="0"
        className={`w-full border-2 rounded-xl py-3 text-center text-3xl outline-none transition-colors ${m.scoreA && m.scoreB ? parseInt(m.scoreA) > parseInt(m.scoreB) ? "border-purple-400 bg-purple-50 text-purple-700" : parseInt(m.scoreA) < parseInt(m.scoreB) ? "border-gray-200 text-gray-400" : "border-gray-200 text-secondary" : "border-border text-secondary focus:border-purple-400"}`}
      />
                                        </div>
                                        <div className="flex flex-col items-center gap-1 flex-shrink-0">
                                          <Swords className="w-4 h-4 text-muted-foreground" />
                                          <span className="text-muted-foreground text-xs">vs</span>
                                        </div>
                                        <div className="flex-1 text-center">
                                          <div className="mb-2">
                                            <TeamChip team={tB} size="sm" />
                                            <p className="text-[10px] text-muted-foreground mt-0.5">مستوى {tB.avgLevel}</p>
                                          </div>
                                          <input
        type="text"
        inputMode="numeric"
        value={m.scoreB}
        onChange={(e) => updateAScore(ri, courtKey, "scoreB", e.target.value.replace(/\D/g, "").slice(0, 3))}
        placeholder="0"
        className={`w-full border-2 rounded-xl py-3 text-center text-3xl outline-none transition-colors ${m.scoreA && m.scoreB ? parseInt(m.scoreB) > parseInt(m.scoreA) ? "border-orange-400 bg-orange-50 text-orange-700" : parseInt(m.scoreB) < parseInt(m.scoreA) ? "border-gray-200 text-gray-400" : "border-gray-200 text-secondary" : "border-border text-secondary focus:border-orange-400"}`}
      />
                                        </div>
                                      </div>}

                                    {
        /* وضع الأشواط */
      }
                                    {aMode === "sets" && <div>
                                        {
        /* أسماء الفريقين */
      }
                                        <div className="grid grid-cols-3 gap-2 mb-3 items-center">
                                          <div className="text-center">
                                            <TeamChip team={tA} size="sm" />
                                            <p className="text-[10px] text-muted-foreground mt-1">مستوى {tA.avgLevel}</p>
                                          </div>
                                          <div className="text-center">
                                            <Swords className="w-4 h-4 text-muted-foreground mx-auto" />
                                          </div>
                                          <div className="text-center">
                                            <TeamChip team={tB} size="sm" />
                                            <p className="text-[10px] text-muted-foreground mt-1">مستوى {tB.avgLevel}</p>
                                          </div>
                                        </div>

                                        {
        /* الأشواط */
      }
                                        <div className="space-y-2">
                                          {m.sets.map((s, si) => {
        const aWin = s.sA !== "" && s.sB !== "" && parseInt(s.sA) > parseInt(s.sB);
        const bWin = s.sA !== "" && s.sB !== "" && parseInt(s.sB) > parseInt(s.sA);
        return <div key={si} className={`grid grid-cols-3 gap-2 items-center rounded-xl p-2 transition-colors ${aWin ? "bg-purple-50" : bWin ? "bg-orange-50" : "bg-gray-50"}`}>
                                                <input
          type="text"
          inputMode="numeric"
          value={s.sA}
          onChange={(e) => updateASet(ri, courtKey, si, "sA", e.target.value.replace(/\D/g, "").slice(0, 2))}
          placeholder="0"
          className={`w-full border-2 rounded-lg py-2 text-center text-xl outline-none transition-colors ${aWin ? "border-purple-400 bg-white text-purple-700" : "border-border bg-white text-secondary focus:border-purple-400"}`}
        />
                                                <div className="text-center">
                                                  <span className="text-xs text-muted-foreground bg-white border border-border px-1.5 py-0.5 rounded-lg">ش {si + 1}</span>
                                                </div>
                                                <input
          type="text"
          inputMode="numeric"
          value={s.sB}
          onChange={(e) => updateASet(ri, courtKey, si, "sB", e.target.value.replace(/\D/g, "").slice(0, 2))}
          placeholder="0"
          className={`w-full border-2 rounded-lg py-2 text-center text-xl outline-none transition-colors ${bWin ? "border-orange-400 bg-white text-orange-700" : "border-border bg-white text-secondary focus:border-orange-400"}`}
        />
                                              </div>;
      })}
                                        </div>
                                      </div>}

                                    {
        /* الفائز في هذا الملعب */
      }
                                    {(() => {
        let aTotal = 0, bTotal = 0;
        if (aMode === "time") {
          aTotal = parseInt(m.scoreA) || 0;
          bTotal = parseInt(m.scoreB) || 0;
        } else {
          m.sets.forEach((s) => {
            aTotal += parseInt(s.sA) || 0;
            bTotal += parseInt(s.sB) || 0;
          });
        }
        const hasScores = aMode === "time" ? m.scoreA !== "" && m.scoreB !== "" : m.sets.some((s) => s.sA !== "" && s.sB !== "");
        if (!hasScores) return null;
        return <div className={`mt-2 text-center text-xs px-3 py-1.5 rounded-lg font-medium ${aTotal > bTotal ? "bg-purple-100 text-purple-700" : bTotal > aTotal ? "bg-orange-100 text-orange-700" : "bg-gray-100 text-muted-foreground"}`}>
                                          {aTotal > bTotal ? `\u{1F3C6} \u0641\u0627\u0632 ${tA.label} (${aTotal} \u2013 ${bTotal})` : bTotal > aTotal ? `\u{1F3C6} \u0641\u0627\u0632 ${tB.label} (${bTotal} \u2013 ${aTotal})` : `\u062A\u0639\u0627\u062F\u0644 (${aTotal} \u2013 ${bTotal})`}
                                        </div>;
      })()}
                                  </div>
                                </div>;
    })}

                            {
      /* الانتقال للجولة التالية */
    }
                            {ri < aSchedule.length - 1 && <button
      onClick={() => setExpandedRound(ri + 1)}
      className="w-full py-2 text-xs text-purple-600 bg-purple-50 border border-purple-200 rounded-xl hover:bg-purple-100 transition-colors"
    >
                                الانتقال للجولة {ri + 2} ←
                              </button>}
                          </div>}
                      </div>;
  })}
                </div>

                {
    /* ── ترتيب الفرق (دائماً ظاهر بعد أول نقطة) ── */
  }
                {anyScoreEntered && <div className="bg-white border-2 border-purple-200 rounded-2xl overflow-hidden shadow-sm">
                    <div className="px-5 py-3 bg-purple-50 border-b border-purple-200 flex items-center gap-2">
                      <Trophy className="w-4 h-4 text-purple-600" />
                      <p className="text-secondary text-sm">ترتيب الفرق</p>
                      <span className="mr-auto text-xs text-muted-foreground">يتحدث تلقائياً</span>
                    </div>

                    <div className="divide-y divide-border">
                      {aRanked.map((team, i) => {
    const total = aPoints[team.id] || 0;
    const maxPts = Math.max(...americanoTeams.map((t) => aPoints[t.id] || 0)) || 1;
    const medal = ["\u{1F947}", "\u{1F948}", "\u{1F949}", "4\uFE0F\u20E3"][i];
    return <div key={team.id} className={`flex items-center gap-3 px-4 py-3.5 transition-all ${i === 0 && total > 0 ? "bg-yellow-50" : ""}`}>
                            <span className="text-xl w-8 text-center">{total > 0 ? medal : <span className="text-muted-foreground text-sm">{i + 1}</span>}</span>
                            <div className="flex -space-x-1.5 flex-shrink-0">
                              {team.players.map((p, pi) => <div key={pi} className={`w-9 h-9 bg-gradient-to-br ${p.color} rounded-full border-2 border-white flex items-center justify-center`}>
                                  <span className="text-white text-[10px]">{p.avatar}</span>
                                </div>)}
                            </div>
                            <div className="flex-1 min-w-0">
                              <div className="flex items-center gap-2 mb-1">
                                <p className="text-secondary text-sm">{team.label}</p>
                                <span className={`text-[10px] px-1.5 py-0.5 rounded-full border ${teamAccent[team.id]}`}>
                                  {team.avgLevel}
                                </span>
                              </div>
                              <div className="h-2 bg-gray-100 rounded-full overflow-hidden">
                                <div
      className={`h-full rounded-full transition-all duration-500 ${i === 0 && total > 0 ? "bg-gradient-to-r from-yellow-400 to-yellow-500" : i === 1 ? "bg-gradient-to-r from-purple-400 to-purple-500" : i === 2 ? "bg-gradient-to-r from-indigo-400 to-indigo-500" : "bg-gray-300"}`}
      style={{ width: `${total > 0 ? total / maxPts * 100 : 0}%` }}
    />
                              </div>
                            </div>
                            <span className={`text-sm flex-shrink-0 ${i === 0 && total > 0 ? "text-yellow-600" : "text-secondary"}`}>
                              {total}
                              <span className="text-xs text-muted-foreground"> نقطة</span>
                            </span>
                          </div>;
  })}
                    </div>

                    {
    /* إحصائيات إضافية */
  }
                    {aComplete && <div className="px-4 py-3 bg-purple-50 border-t border-purple-200">
                        <p className="text-xs text-purple-700 flex items-center gap-1.5">
                          <CheckCircle className="w-3.5 h-3.5" />
                          اكتملت جميع المباريات — جاهز لتسجيل النتيجة النهائية
                        </p>
                      </div>}
                  </div>}
              </>}
          </>}

        {
    /* ═══ أمريكانو فردي ═══ */
  }
        {isAmericanoSolo && <>
            {
    /* اللاعبون الثمانية */
  }
            <div className="bg-white border border-border rounded-2xl overflow-hidden shadow-sm">
              <div className="px-5 py-3 bg-teal-50 border-b border-teal-100 flex items-center gap-2">
                <Users className="w-4 h-4 text-teal-600" />
                <p className="text-secondary text-sm">اللاعبون</p>
                <span className="mr-auto text-xs text-teal-600 bg-teal-100 px-2 py-0.5 rounded-full">8 لاعبين</span>
              </div>
              <div className="grid grid-cols-2 gap-px bg-border">
                {americanoSoloPlayers.map((p) => <div key={p.id} className="bg-white p-3 flex items-center gap-2">
                    <div className={`w-9 h-9 bg-gradient-to-br ${p.color} rounded-full flex items-center justify-center flex-shrink-0`}>
                      <span className="text-white text-xs">{p.avatar}</span>
                    </div>
                    <div>
                      <p className="text-secondary text-xs">{p.name}</p>
                      <p className="text-teal-600 text-xs">مستوى {p.level}</p>
                    </div>
                  </div>)}
              </div>
            </div>

            {
    /* إعداد الجدول */
  }
            {!asSetupDone && <div className="bg-white border-2 border-teal-200 rounded-2xl overflow-hidden shadow-sm">
                <div className="px-5 py-4 bg-gradient-to-r from-teal-600 to-cyan-600">
                  <h3 className="text-white text-sm flex items-center gap-2">
                    <Trophy className="w-4 h-4" />إعداد جدول المباريات
                  </h3>
                  <p className="text-teal-200 text-xs mt-1">3 جولات × 2 ملاعب — لا تكرار للشريك</p>
                </div>
                <div className="p-5 space-y-5">
                  <div>
                    <p className="text-secondary text-xs mb-3 flex items-center gap-1.5">
                      <Info className="w-3.5 h-3.5 text-teal-500" />نوع الجولة
                    </p>
                    <div className="grid grid-cols-2 gap-3">
                      {["time", "sets"].map((mode) => <button
    key={mode}
    onClick={() => setAsMode(mode)}
    className={`flex flex-col items-center gap-2 p-4 rounded-2xl border-2 transition-all ${asMode === mode ? "bg-teal-600 border-teal-600 text-white shadow-md" : "bg-white border-border text-secondary hover:border-teal-300"}`}
  >
                          {mode === "time" ? <Timer className={`w-6 h-6 ${asMode === "time" ? "text-white" : "text-teal-500"}`} /> : <Hash className={`w-6 h-6 ${asMode === "sets" ? "text-white" : "text-teal-500"}`} />}
                          <div className="text-center">
                            <p className="text-sm">{mode === "time" ? "\u0628\u0627\u0644\u0648\u0642\u062A" : "\u0628\u0627\u0644\u0623\u0634\u0648\u0627\u0637"}</p>
                            <p className={`text-xs mt-0.5 ${asMode === mode ? "text-teal-200" : "text-muted-foreground"}`}>
                              {mode === "time" ? "\u062F\u0642\u0627\u0626\u0642 \u0644\u0643\u0644 \u062C\u0648\u0644\u0629" : "\u0623\u0634\u0648\u0627\u0637 \u0644\u0643\u0644 \u0645\u0628\u0627\u0631\u0627\u0629"}
                            </p>
                          </div>
                        </button>)}
                    </div>
                  </div>

                  {asMode === "time" && <div className="space-y-4">
                      <div>
                        <label className="text-secondary text-xs mb-2 block">مدة الجولة (دقيقة)</label>
                        <div className="flex items-center gap-3">
                          {[10, 12, 15, 20].map((v) => <button
    key={v}
    onClick={() => setAsTimePerRound(v)}
    className={`flex-1 py-2.5 rounded-xl border-2 text-sm transition-all ${asTimePerRound === v ? "bg-teal-600 border-teal-600 text-white" : "border-border text-secondary hover:border-teal-300"}`}
  >
                              {v}
                            </button>)}
                        </div>
                      </div>
                      <div>
                        <label className="text-secondary text-xs mb-2 block">وقت البداية</label>
                        <input
    type="time"
    value={asStartTime}
    onChange={(e) => setAsStartTime(e.target.value)}
    className="w-full border-2 border-border rounded-xl px-4 py-3 text-secondary text-sm outline-none focus:border-teal-400"
  />
                      </div>
                    </div>}

                  {asMode === "sets" && <div>
                      <label className="text-secondary text-xs mb-3 block">عدد الأشواط لكل مباراة</label>
                      <div className="flex gap-2 mb-3 overflow-x-auto pb-1">
                        {[1, 2, 3, 4, 5, 6].map((v) => <button
    key={v}
    onClick={() => setAsSetsCount(v)}
    className={`flex-shrink-0 w-11 h-11 rounded-xl border-2 text-sm transition-all ${asSetsCount === v ? "bg-teal-600 border-teal-600 text-white shadow-md" : "border-border text-secondary hover:border-teal-300 bg-white"}`}
  >
                            {v}
                          </button>)}
                      </div>
                      <div className="flex items-center gap-3 bg-gray-50 rounded-xl p-3 border border-border">
                        <button
    onClick={() => setAsSetsCount((c) => Math.max(1, c - 1))}
    className="w-9 h-9 bg-white border-2 border-border rounded-lg flex items-center justify-center text-secondary hover:border-teal-400 transition-colors"
  >−</button>
                        <div className="flex-1 text-center">
                          <p className="text-secondary text-xl">{asSetsCount}</p>
                          <p className="text-xs text-muted-foreground">
                            {asSetsCount === 1 ? "\u0634\u0648\u0637 \u0648\u0627\u062D\u062F" : asSetsCount === 2 ? "\u0634\u0648\u0637\u0627\u0646" : `${asSetsCount} \u0623\u0634\u0648\u0627\u0637`}
                          </p>
                        </div>
                        <button
    onClick={() => setAsSetsCount((c) => Math.min(20, c + 1))}
    className="w-9 h-9 bg-teal-600 text-white rounded-lg flex items-center justify-center hover:bg-teal-700 transition-colors"
  >+</button>
                      </div>
                    </div>}

                  <div className="bg-teal-50 border border-teal-200 rounded-xl p-4">
                    <p className="text-teal-700 text-xs mb-2">✦ مبادئ التوزيع العادل</p>
                    <div className="space-y-1.5 text-xs text-teal-600">
                      <p className="flex items-center gap-1.5"><CheckCircle className="w-3 h-3 flex-shrink-0" /> توازن المستويات: الأقوى يلعب مع الأضعف</p>
                      <p className="flex items-center gap-1.5"><CheckCircle className="w-3 h-3 flex-shrink-0" /> تنوع الشركاء: لا تكرار للشريك في 3 جولات</p>
                      <p className="flex items-center gap-1.5"><CheckCircle className="w-3 h-3 flex-shrink-0" /> توزيع عادل: 8 لاعبين × 3 جولات = 6 مباريات</p>
                    </div>
                  </div>

                  <button
    onClick={handleGenerateSoloSchedule}
    className="w-full py-4 bg-gradient-to-r from-teal-600 to-cyan-600 text-white rounded-xl shadow-md flex items-center justify-center gap-2 text-sm"
  >
                    <Trophy className="w-4 h-4" />توليد جدول المباريات
                  </button>
                </div>
              </div>}

            {
    /* الجدول بعد التوليد */
  }
            {asSetupDone && <>
                <div className="bg-gradient-to-r from-teal-600 to-cyan-600 rounded-2xl p-4 shadow-md">
                  <div className="flex items-center justify-between mb-3">
                    <div>
                      <h3 className="text-white text-sm">جدول المباريات</h3>
                      <p className="text-teal-200 text-xs mt-0.5">
                        {asMode === "time" ? `${asTimePerRound} \u062F\u0642\u064A\u0642\u0629 \u0644\u0643\u0644 \u062C\u0648\u0644\u0629 \u2022 \u0627\u0628\u062A\u062F\u0627\u0621\u064B ${fmtTime(asStartTime)}` : `${asSetsCount === 1 ? "\u0634\u0648\u0637 \u0648\u0627\u062D\u062F" : asSetsCount === 2 ? "\u0634\u0648\u0637\u0627\u0646" : `${asSetsCount} \u0623\u0634\u0648\u0627\u0637`} \u0644\u0643\u0644 \u0645\u0628\u0627\u0631\u0627\u0629`}
                      </p>
                    </div>
                    <button
    onClick={() => setAsSetupDone(false)}
    className="text-xs text-teal-200 bg-white/20 px-3 py-1.5 rounded-lg hover:bg-white/30"
  >
                      تعديل
                    </button>
                  </div>
                  <div className="grid grid-cols-3 gap-2">
                    {asSchedule.map((r, ri) => {
    const done = [r.court1, r.court2].every(
      (m) => asMode === "time" ? m.scoreA !== "" && m.scoreB !== "" : m.sets.every((s) => s.sA !== "" && s.sB !== "")
    );
    return <button
      key={r.id}
      onClick={() => setAsExpandedRound(asExpandedRound === ri ? null : ri)}
      className={`p-2.5 rounded-xl text-center transition-all border ${done ? "bg-green-500/30 border-green-400/50 text-white" : asExpandedRound === ri ? "bg-white/30 border-white/50 text-white" : "bg-white/10 border-white/20 text-teal-200 hover:bg-white/20"}`}
    >
                          <p className="text-xs">جولة {r.roundNum}</p>
                          {asMode === "time" && <p className="text-[10px] mt-0.5 opacity-80">{r.timeSlot}</p>}
                          {done && <CheckCircle className="w-3 h-3 mx-auto mt-1 text-green-300" />}
                        </button>;
  })}
                  </div>
                </div>

                <div className="space-y-3">
                  {asSchedule.map((round, ri) => {
    const isOpen = asExpandedRound === ri;
    const roundDone = [round.court1, round.court2].every(
      (m) => asMode === "time" ? m.scoreA !== "" && m.scoreB !== "" : m.sets.every((s) => s.sA !== "" && s.sB !== "")
    );
    return <div key={round.id} className={`bg-white rounded-2xl overflow-hidden shadow-sm border-2 transition-all ${roundDone ? "border-green-300" : isOpen ? "border-teal-400" : "border-border"}`}>
                        <button
      onClick={() => setAsExpandedRound(isOpen ? null : ri)}
      className={`w-full flex items-center justify-between px-4 py-3.5 ${roundDone ? "bg-green-50" : isOpen ? "bg-teal-50" : "bg-gray-50"}`}
    >
                          <div className="flex items-center gap-3">
                            <div className={`w-7 h-7 rounded-full flex items-center justify-center flex-shrink-0 ${roundDone ? "bg-green-500" : "bg-teal-600"}`}>
                              {roundDone ? <CheckCircle className="w-4 h-4 text-white" /> : <span className="text-white text-xs">{round.roundNum}</span>}
                            </div>
                            <div className="text-right">
                              <p className={`text-sm ${roundDone ? "text-green-700" : "text-secondary"}`}>الجولة {round.roundNum}</p>
                              <p className="text-xs text-muted-foreground">{round.timeSlot}</p>
                            </div>
                          </div>
                          <div className="flex items-center gap-2">
                            {roundDone && <span className="text-xs text-green-600 bg-green-100 px-2 py-0.5 rounded-full">مكتملة</span>}
                            {isOpen ? <ChevronUp className="w-4 h-4 text-muted-foreground" /> : <ChevronDown className="w-4 h-4 text-muted-foreground" />}
                          </div>
                        </button>

                        {isOpen && <div className="p-4 space-y-4">
                            {[
      { label: "\u0645\u0644\u0639\u0628 1", courtKey: "court1", m: round.court1 },
      { label: "\u0645\u0644\u0639\u0628 2", courtKey: "court2", m: round.court2 }
    ].map(({ label, courtKey, m }) => {
      const pA1 = americanoSoloPlayers.find((p) => p.id === m.teamA[0]);
      const pA2 = americanoSoloPlayers.find((p) => p.id === m.teamA[1]);
      const pB1 = americanoSoloPlayers.find((p) => p.id === m.teamB[0]);
      const pB2 = americanoSoloPlayers.find((p) => p.id === m.teamB[1]);
      const avgA = ((pA1.level + pA2.level) / 2).toFixed(1);
      const avgB = ((pB1.level + pB2.level) / 2).toFixed(1);
      const TeamSide = ({ players, side }) => <div className="text-center">
                                  <div className="flex justify-center -space-x-1.5 mb-1">
                                    {players.map((p) => <div key={p.id} className={`w-8 h-8 bg-gradient-to-br ${p.color} rounded-full border-2 border-white flex items-center justify-center`}>
                                        <span className="text-white text-[9px]">{p.avatar}</span>
                                      </div>)}
                                  </div>
                                  <p className="text-[10px] text-secondary">{players.map((p) => p.short).join(" & ")}</p>
                                  <p className="text-[10px] text-muted-foreground">متوسط {side === "A" ? avgA : avgB}</p>
                                </div>;
      return <div key={label} className="border border-border rounded-2xl overflow-hidden">
                                  <div className="flex items-center justify-between px-3 py-2 bg-gray-50 border-b border-border">
                                    <span className="text-xs text-muted-foreground">{label}</span>
                                    <span className="text-[10px] text-muted-foreground bg-white border border-border px-2 py-0.5 rounded-full">
                                      فرق المستوى: {Math.abs(parseFloat(avgA) - parseFloat(avgB)).toFixed(1)}
                                    </span>
                                  </div>
                                  <div className="p-3">
                                    {asMode === "time" && <div className="flex items-center gap-2">
                                        <div className="flex-1 text-center">
                                          <TeamSide players={[pA1, pA2]} side="A" />
                                          <input
        type="text"
        inputMode="numeric"
        value={m.scoreA}
        onChange={(e) => updateAsScore(ri, courtKey, "scoreA", e.target.value.replace(/\D/g, "").slice(0, 3))}
        placeholder="0"
        className={`w-full mt-2 border-2 rounded-xl py-3 text-center text-3xl outline-none transition-colors ${m.scoreA && m.scoreB ? parseInt(m.scoreA) > parseInt(m.scoreB) ? "border-teal-400 bg-teal-50 text-teal-700" : "border-gray-200 text-gray-400" : "border-border text-secondary focus:border-teal-400"}`}
      />
                                        </div>
                                        <div className="flex flex-col items-center gap-1 flex-shrink-0">
                                          <Swords className="w-4 h-4 text-muted-foreground" />
                                          <span className="text-muted-foreground text-xs">vs</span>
                                        </div>
                                        <div className="flex-1 text-center">
                                          <TeamSide players={[pB1, pB2]} side="B" />
                                          <input
        type="text"
        inputMode="numeric"
        value={m.scoreB}
        onChange={(e) => updateAsScore(ri, courtKey, "scoreB", e.target.value.replace(/\D/g, "").slice(0, 3))}
        placeholder="0"
        className={`w-full mt-2 border-2 rounded-xl py-3 text-center text-3xl outline-none transition-colors ${m.scoreA && m.scoreB ? parseInt(m.scoreB) > parseInt(m.scoreA) ? "border-orange-400 bg-orange-50 text-orange-700" : "border-gray-200 text-gray-400" : "border-border text-secondary focus:border-orange-400"}`}
      />
                                        </div>
                                      </div>}
                                    {asMode === "sets" && <div>
                                        <div className="grid grid-cols-3 gap-2 mb-3 items-center">
                                          <TeamSide players={[pA1, pA2]} side="A" />
                                          <div className="text-center"><Swords className="w-4 h-4 text-muted-foreground mx-auto" /></div>
                                          <TeamSide players={[pB1, pB2]} side="B" />
                                        </div>
                                        <div className="space-y-2">
                                          {m.sets.map((s, si) => {
        const aWin = s.sA !== "" && s.sB !== "" && parseInt(s.sA) > parseInt(s.sB);
        const bWin = s.sA !== "" && s.sB !== "" && parseInt(s.sB) > parseInt(s.sA);
        return <div key={si} className={`grid grid-cols-3 gap-2 items-center rounded-xl p-2 transition-colors ${aWin ? "bg-teal-50" : bWin ? "bg-orange-50" : "bg-gray-50"}`}>
                                                <input
          type="text"
          inputMode="numeric"
          value={s.sA}
          onChange={(e) => updateAsSet(ri, courtKey, si, "sA", e.target.value.replace(/\D/g, "").slice(0, 2))}
          placeholder="0"
          className={`w-full border-2 rounded-lg py-2 text-center text-xl outline-none ${aWin ? "border-teal-400 bg-white text-teal-700" : "border-border bg-white text-secondary focus:border-teal-400"}`}
        />
                                                <div className="text-center">
                                                  <span className="text-xs text-muted-foreground bg-white border border-border px-1.5 py-0.5 rounded-lg">ش {si + 1}</span>
                                                </div>
                                                <input
          type="text"
          inputMode="numeric"
          value={s.sB}
          onChange={(e) => updateAsSet(ri, courtKey, si, "sB", e.target.value.replace(/\D/g, "").slice(0, 2))}
          placeholder="0"
          className={`w-full border-2 rounded-lg py-2 text-center text-xl outline-none ${bWin ? "border-orange-400 bg-white text-orange-700" : "border-border bg-white text-secondary focus:border-orange-400"}`}
        />
                                              </div>;
      })}
                                        </div>
                                      </div>}
                                    {(() => {
        let aTotal = 0, bTotal = 0;
        if (asMode === "time") {
          aTotal = parseInt(m.scoreA) || 0;
          bTotal = parseInt(m.scoreB) || 0;
        } else {
          m.sets.forEach((s) => {
            aTotal += parseInt(s.sA) || 0;
            bTotal += parseInt(s.sB) || 0;
          });
        }
        const hasScores = asMode === "time" ? m.scoreA !== "" && m.scoreB !== "" : m.sets.some((s) => s.sA !== "" && s.sB !== "");
        if (!hasScores) return null;
        return <div className={`mt-2 text-center text-xs px-3 py-1.5 rounded-lg font-medium ${aTotal > bTotal ? "bg-teal-100 text-teal-700" : bTotal > aTotal ? "bg-orange-100 text-orange-700" : "bg-gray-100 text-muted-foreground"}`}>
                                          {aTotal > bTotal ? `\u{1F3C6} \u0641\u0627\u0632 ${pA1.short} & ${pA2.short} (${aTotal} \u2013 ${bTotal})` : bTotal > aTotal ? `\u{1F3C6} \u0641\u0627\u0632 ${pB1.short} & ${pB2.short} (${bTotal} \u2013 ${aTotal})` : `\u062A\u0639\u0627\u062F\u0644 (${aTotal} \u2013 ${bTotal})`}
                                        </div>;
      })()}
                                  </div>
                                </div>;
    })}
                            {ri < asSchedule.length - 1 && <button
      onClick={() => setAsExpandedRound(ri + 1)}
      className="w-full py-2 text-xs text-teal-600 bg-teal-50 border border-teal-200 rounded-xl hover:bg-teal-100 transition-colors"
    >
                                الانتقال للجولة {ri + 2} ←
                              </button>}
                          </div>}
                      </div>;
  })}
                </div>

                {
    /* ترتيب اللاعبين الحي */
  }
                {asAnyScore && <div className="bg-white border-2 border-teal-200 rounded-2xl overflow-hidden shadow-sm">
                    <div className="px-5 py-3 bg-teal-50 border-b border-teal-200 flex items-center gap-2">
                      <Trophy className="w-4 h-4 text-teal-600" />
                      <p className="text-secondary text-sm">ترتيب اللاعبين</p>
                      <span className="mr-auto text-xs text-muted-foreground">يتحدث تلقائياً</span>
                    </div>
                    <div className="divide-y divide-border">
                      {asSoloRanked.map((player, i) => {
    const total = asSoloPoints[player.id] || 0;
    const maxPts = Math.max(...americanoSoloPlayers.map((p) => asSoloPoints[p.id] || 0)) || 1;
    const medals = ["\u{1F947}", "\u{1F948}", "\u{1F949}", "4\uFE0F\u20E3", "5\uFE0F\u20E3", "6\uFE0F\u20E3", "7\uFE0F\u20E3", "8\uFE0F\u20E3"];
    return <div key={player.id} className={`flex items-center gap-3 px-4 py-3 transition-all ${i === 0 && total > 0 ? "bg-yellow-50" : ""}`}>
                            <span className="text-lg w-8 text-center">{total > 0 ? medals[i] : <span className="text-muted-foreground text-sm">{i + 1}</span>}</span>
                            <div className={`w-9 h-9 bg-gradient-to-br ${player.color} rounded-full border-2 border-white flex items-center justify-center flex-shrink-0`}>
                              <span className="text-white text-[10px]">{player.avatar}</span>
                            </div>
                            <div className="flex-1 min-w-0">
                              <div className="flex items-center gap-2 mb-1">
                                <p className="text-secondary text-xs">{player.name}</p>
                                <span className="text-[10px] px-1.5 py-0.5 rounded-full border bg-teal-50 text-teal-700 border-teal-200">{player.level}</span>
                              </div>
                              <div className="h-1.5 bg-gray-100 rounded-full overflow-hidden">
                                <div className={`h-full rounded-full transition-all duration-500 ${i === 0 && total > 0 ? "bg-gradient-to-r from-yellow-400 to-yellow-500" : i < 3 ? "bg-gradient-to-r from-teal-400 to-teal-500" : "bg-gray-300"}`} style={{ width: `${total > 0 ? total / maxPts * 100 : 0}%` }} />
                              </div>
                            </div>
                            <span className={`text-sm flex-shrink-0 ${i === 0 && total > 0 ? "text-yellow-600" : "text-secondary"}`}>
                              {total}<span className="text-xs text-muted-foreground"> نقطة</span>
                            </span>
                          </div>;
  })}
                    </div>
                    {asComplete && <div className="px-4 py-3 bg-teal-50 border-t border-teal-200">
                        <p className="text-xs text-teal-700 flex items-center gap-1.5">
                          <CheckCircle className="w-3.5 h-3.5" />اكتملت جميع المباريات — جاهز لتسجيل النتيجة النهائية
                        </p>
                      </div>}
                  </div>}
              </>}
          </>}

        {
    /* ═══ ودية فردي ═══ */
  }
        {isSolo && <>
            <div className="bg-white border border-border rounded-2xl p-4 shadow-sm">
              <p className="text-secondary text-sm mb-3 flex items-center gap-2">
                <Users className="w-4 h-4 text-blue-500" />اللاعبون
              </p>
              <div className="grid grid-cols-2 gap-2">
                {soloPlayers.map((p) => <div key={p.id} className="flex items-center gap-2 p-2.5 bg-gray-50 rounded-xl border border-border">
                    <div className={`w-9 h-9 bg-gradient-to-br ${p.color} rounded-full flex items-center justify-center flex-shrink-0`}>
                      <span className="text-white text-xs">{p.avatar}</span>
                    </div>
                    <div>
                      <p className="text-secondary text-xs">{p.name}</p>
                      <p className="text-blue-500 text-xs">مستوى {p.level}</p>
                    </div>
                  </div>)}
              </div>
            </div>

            <div className="space-y-3">
              {rounds.map((round, ri) => <div key={round.id} className="bg-white border border-border rounded-2xl overflow-hidden shadow-sm">
                  <div className="flex items-center justify-between px-4 py-3 bg-blue-50 border-b border-blue-100">
                    <div className="flex items-center gap-2">
                      <div className="w-6 h-6 bg-blue-500 rounded-full flex items-center justify-center">
                        <span className="text-white text-xs">{ri + 1}</span>
                      </div>
                      <span className="text-secondary text-sm">جولة {ri + 1}</span>
                    </div>
                    {rounds.length > 1 && <button onClick={() => removeRound(round.id)} className="p-1 text-red-400 hover:text-red-600">
                        <Trash2 className="w-4 h-4" />
                      </button>}
                  </div>
                  <div className="p-4">
                    <div className="grid grid-cols-3 gap-2 mb-4 items-center">
                      <div className="bg-blue-50 border border-blue-200 rounded-xl p-2 min-h-[64px]">
                        <p className="text-xs text-blue-500 mb-1.5 text-center">الفريق أ</p>
                        <div className="flex flex-col gap-1">
                          {round.teamA.map((pid) => <button
    key={pid}
    onClick={() => swapPlayer(round.id, pid)}
    className="flex items-center gap-1 bg-white rounded-lg px-2 py-1 border border-blue-200 w-full hover:bg-blue-50 transition-colors"
  >
                              <div className={`w-5 h-5 bg-gradient-to-br ${soloPlayers.find((p) => p.id === pid).color} rounded-full flex-shrink-0`} />
                              <span className="text-xs text-secondary truncate">{soloPlayers.find((p) => p.id === pid).short}</span>
                              <RefreshCw className="w-3 h-3 text-muted-foreground mr-auto" />
                            </button>)}
                        </div>
                      </div>
                      <div className="flex flex-col items-center gap-2">
                        <Swords className="w-5 h-5 text-muted-foreground" />
                        <span className="text-xs text-muted-foreground">اضغط للتبديل</span>
                      </div>
                      <div className="bg-orange-50 border border-orange-200 rounded-xl p-2 min-h-[64px]">
                        <p className="text-xs text-orange-500 mb-1.5 text-center">الفريق ب</p>
                        <div className="flex flex-col gap-1">
                          {round.teamB.map((pid) => <button
    key={pid}
    onClick={() => swapPlayer(round.id, pid)}
    className="flex items-center gap-1 bg-white rounded-lg px-2 py-1 border border-orange-200 w-full hover:bg-orange-50 transition-colors"
  >
                              <div className={`w-5 h-5 bg-gradient-to-br ${soloPlayers.find((p) => p.id === pid).color} rounded-full flex-shrink-0`} />
                              <span className="text-xs text-secondary truncate">{soloPlayers.find((p) => p.id === pid).short}</span>
                              <RefreshCw className="w-3 h-3 text-muted-foreground mr-auto" />
                            </button>)}
                        </div>
                      </div>
                    </div>
                    <div className="flex items-center gap-3">
                      <div className="flex-1">
                        <p className="text-xs text-blue-500 mb-1 text-center">الفريق أ</p>
                        <input
    type="text"
    inputMode="numeric"
    value={round.scoreA}
    onChange={(e) => updateRound(round.id, "scoreA", e.target.value.replace(/\D/g, "").slice(0, 2))}
    placeholder="0"
    className={`w-full border-2 rounded-xl py-3 text-center text-2xl outline-none transition-colors ${round.scoreA && round.scoreB ? parseInt(round.scoreA) > parseInt(round.scoreB) ? "border-blue-400 bg-blue-50 text-blue-600" : "border-border text-secondary" : "border-border text-secondary focus:border-blue-400"}`}
  />
                      </div>
                      <div className="text-muted-foreground text-xl pt-4">—</div>
                      <div className="flex-1">
                        <p className="text-xs text-orange-500 mb-1 text-center">الفريق ب</p>
                        <input
    type="text"
    inputMode="numeric"
    value={round.scoreB}
    onChange={(e) => updateRound(round.id, "scoreB", e.target.value.replace(/\D/g, "").slice(0, 2))}
    placeholder="0"
    className={`w-full border-2 rounded-xl py-3 text-center text-2xl outline-none transition-colors ${round.scoreA && round.scoreB ? parseInt(round.scoreB) > parseInt(round.scoreA) ? "border-orange-400 bg-orange-50 text-orange-600" : "border-border text-secondary" : "border-border text-secondary focus:border-orange-400"}`}
  />
                      </div>
                    </div>
                    {round.scoreA !== "" && round.scoreB !== "" && <div className={`mt-2 text-center text-xs px-3 py-1.5 rounded-lg ${parseInt(round.scoreA) > parseInt(round.scoreB) ? "bg-blue-50 text-blue-600" : parseInt(round.scoreB) > parseInt(round.scoreA) ? "bg-orange-50 text-orange-600" : "bg-gray-50 text-muted-foreground"}`}>
                        {parseInt(round.scoreA) > parseInt(round.scoreB) ? `\u{1F3C6} \u0641\u0627\u0632 \u0627\u0644\u0641\u0631\u064A\u0642 \u0623 (${round.teamA.map((id) => soloPlayers.find((p) => p.id === id).short).join(" & ")})` : parseInt(round.scoreB) > parseInt(round.scoreA) ? `\u{1F3C6} \u0641\u0627\u0632 \u0627\u0644\u0641\u0631\u064A\u0642 \u0628 (${round.teamB.map((id) => soloPlayers.find((p) => p.id === id).short).join(" & ")})` : "\u062A\u0639\u0627\u062F\u0644"}
                      </div>}
                  </div>
                </div>)}
            </div>
            <button onClick={addRound} className="w-full py-3 border-2 border-dashed border-blue-300 text-blue-500 text-sm rounded-2xl hover:bg-blue-50 flex items-center justify-center gap-2 transition-colors">
              <Plus className="w-4 h-4" />إضافة جولة جديدة
            </button>
            {rounds.some((r) => r.scoreA !== "" || r.scoreB !== "") && <div className="bg-white border border-border rounded-2xl p-5 shadow-sm">
                <h3 className="text-secondary text-sm mb-4 flex items-center gap-2">
                  <Trophy className="w-4 h-4 text-blue-500" />الترتيب الحالي
                  <span className="text-xs text-muted-foreground mr-auto">يتحدث تلقائياً</span>
                </h3>
                <div className="space-y-2">
                  {ranked.map((p, i) => {
    const total = points[p.id] || 0;
    const maxPts = Math.max(...soloPlayers.map((x) => points[x.id] || 0)) || 1;
    return <div key={p.id} className={`flex items-center gap-3 p-3 rounded-xl transition-all ${i === 0 && total > 0 ? "bg-yellow-50 border border-yellow-200" : "bg-gray-50"}`}>
                        <span className="text-lg w-7 text-center">{total > 0 ? ["\u{1F947}", "\u{1F948}", "\u{1F949}", "4\uFE0F\u20E3"][i] : "\u2014"}</span>
                        <div className={`w-8 h-8 bg-gradient-to-br ${p.color} rounded-full flex items-center justify-center flex-shrink-0`}>
                          <span className="text-white text-xs">{p.avatar}</span>
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className="text-secondary text-xs">{p.name}</p>
                          <div className="mt-1 h-1.5 bg-gray-200 rounded-full overflow-hidden">
                            <div
      className={`h-full rounded-full transition-all ${i === 0 ? "bg-yellow-400" : "bg-blue-300"}`}
      style={{ width: `${total > 0 ? total / maxPts * 100 : 0}%` }}
    />
                          </div>
                        </div>
                        <span className={`text-sm flex-shrink-0 ${i === 0 && total > 0 ? "text-yellow-600" : "text-secondary"}`}>
                          {total} نقطة
                        </span>
                      </div>;
  })}
                </div>
              </div>}
          </>}

        {
    /* ═══ تحدي فرق ═══ */
  }
        {!isSolo && !isAmericanoTeams && <>
            <div className="bg-white border border-border rounded-2xl overflow-hidden shadow-sm">
              <div className="px-5 py-3 bg-gray-50 border-b border-border flex items-center gap-2">
                <Swords className="w-4 h-4 text-primary" /><p className="text-secondary text-sm">اللاعبون</p>
              </div>
              <div className="grid grid-cols-2 divide-x divide-x-reverse divide-border">
                {[team1, team2].map((team, ti) => <div key={ti} className="p-4">
                    <p className="text-xs text-muted-foreground mb-3 flex items-center gap-1">
                      <Shield className={`w-3 h-3 ${ti === 0 ? "text-primary" : "text-secondary"}`} />
                      {ti === 0 ? "\u0627\u0644\u0641\u0631\u064A\u0642 \u0627\u0644\u0623\u0648\u0644" : "\u0627\u0644\u0641\u0631\u064A\u0642 \u0627\u0644\u062B\u0627\u0646\u064A"}
                    </p>
                    <div className="space-y-3">
                      {team.map((p) => <div key={p.id} className="flex items-center gap-2">
                          <div className={`w-9 h-9 bg-gradient-to-br ${p.color} rounded-full flex items-center justify-center`}>
                            <span className="text-white text-xs">{p.avatar}</span>
                          </div>
                          <div>
                            <p className="text-secondary text-xs">{p.name}</p>
                            <p className="text-primary text-xs">{p.level}</p>
                          </div>
                        </div>)}
                    </div>
                  </div>)}
              </div>
            </div>
            <div className="bg-white border border-border rounded-2xl p-5 shadow-sm">
              <h3 className="text-secondary text-sm mb-4 flex items-center gap-2">
                <Trophy className="w-4 h-4 text-primary" />نتيجة الأشواط
              </h3>
              <div className="grid grid-cols-3 gap-3 mb-3 text-center text-xs text-muted-foreground">
                <span>الفريق 1</span><span>الشوط</span><span>الفريق 2</span>
              </div>
              <div className="space-y-3">
                {sets.map((s, i) => <div key={i} className="grid grid-cols-3 gap-3 items-center">
                    <input
    type="text"
    value={s.t1}
    onChange={(e) => setSets((p) => p.map((x, idx) => idx === i ? { ...x, t1: e.target.value.replace(/\D/g, "").slice(0, 2) } : x))}
    placeholder="0"
    inputMode="numeric"
    className="w-full border-2 border-border rounded-xl py-3 text-center text-xl text-secondary outline-none focus:border-primary"
  />
                    <div className="text-center"><span className="text-xs text-muted-foreground bg-gray-100 px-2 py-1 rounded-lg">شوط {i + 1}</span></div>
                    <input
    type="text"
    value={s.t2}
    onChange={(e) => setSets((p) => p.map((x, idx) => idx === i ? { ...x, t2: e.target.value.replace(/\D/g, "").slice(0, 2) } : x))}
    placeholder="0"
    inputMode="numeric"
    className="w-full border-2 border-border rounded-xl py-3 text-center text-xl text-secondary outline-none focus:border-primary"
  />
                  </div>)}
              </div>
              {sets.length < 3 && <button onClick={() => setSets((p) => [...p, { t1: "", t2: "" }])} className="mt-3 w-full py-2.5 border-2 border-dashed border-primary/40 text-primary text-sm rounded-xl hover:bg-primary/5">
                  + إضافة شوط {sets.length + 1}
                </button>}
            </div>
            <div className="bg-white border border-border rounded-2xl p-5 shadow-sm">
              <h3 className="text-secondary text-sm mb-4 flex items-center gap-2">
                <Trophy className="w-4 h-4 text-yellow-500" />الفريق الفائز
              </h3>
              <div className="grid grid-cols-2 gap-3">
                {["team1", "team2"].map((t) => {
    const players = t === "team1" ? team1 : team2;
    const sel = winner === t;
    return <button
      key={t}
      onClick={() => setWinner(t)}
      className={`p-4 rounded-2xl border-2 text-center transition-all ${sel ? t === "team1" ? "bg-primary/10 border-primary" : "bg-secondary/10 border-secondary" : "bg-white border-border hover:border-primary/30"}`}
    >
                      <div className="flex justify-center gap-1 mb-2">
                        {players.map((p) => <div key={p.id} className={`w-8 h-8 bg-gradient-to-br ${p.color} rounded-full flex items-center justify-center`}><span className="text-white text-xs">{p.avatar}</span></div>)}
                      </div>
                      <p className="text-sm text-secondary">{t === "team1" ? "\u0627\u0644\u0641\u0631\u064A\u0642 \u0627\u0644\u0623\u0648\u0644" : "\u0627\u0644\u0641\u0631\u064A\u0642 \u0627\u0644\u062B\u0627\u0646\u064A"}</p>
                      {sel && <p className="text-xs text-primary mt-1">🏆 فائز</p>}
                    </button>;
  })}
              </div>
            </div>
          </>}

        {
    /* زر الحفظ */
  }
        <div className="pb-2">
          <button
    onClick={() => canSubmit && setSubmitted(true)}
    disabled={!canSubmit}
    className={`w-full py-4 rounded-xl shadow-lg flex items-center justify-center gap-2 text-sm transition-all ${canSubmit ? isAmericanoTeams ? "bg-gradient-to-r from-purple-600 to-indigo-600 hover:from-purple-700 hover:to-indigo-700 text-white" : isAmericanoSolo ? "bg-gradient-to-r from-teal-600 to-cyan-600 hover:from-teal-700 hover:to-cyan-700 text-white" : isSolo ? "bg-blue-500 hover:bg-blue-600 text-white" : "bg-primary hover:bg-primary/90 text-white" : "bg-gray-200 text-gray-400 cursor-not-allowed"}`}
  >
            <CheckCircle className="w-5 h-5" />
            {isAmericanoTeams && !aSetupDone || isAmericanoSolo && !asSetupDone ? "\u0623\u0646\u0634\u0626 \u062C\u062F\u0648\u0644 \u0627\u0644\u0645\u0628\u0627\u0631\u064A\u0627\u062A \u0623\u0648\u0644\u0627\u064B" : "\u062A\u0633\u062C\u064A\u0644 \u0627\u0644\u0646\u062A\u064A\u062C\u0629 \u0627\u0644\u0646\u0647\u0627\u0626\u064A\u0629"}
          </button>
        </div>
      </div>
    </div>;
}
export {
  MatchResultPage as default
};
