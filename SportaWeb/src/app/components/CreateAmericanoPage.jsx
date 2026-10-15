import { useState } from "react";
import { ChevronRight, MapPin, Calendar, Clock, Users, TrendingUp, AlertCircle, CheckCircle, Hash, UserPlus, X } from "lucide-react";
import Tooltip from "./Tooltip";
const availablePlayers = [
  { id: "1", name: "\u0645\u062D\u0645\u062F \u0627\u0644\u0639\u062A\u064A\u0628\u064A", level: "5.2" },
  { id: "2", name: "\u0641\u0647\u062F \u0627\u0644\u062F\u0648\u0633\u0631\u064A", level: "5.8" },
  { id: "3", name: "\u0633\u0639\u0648\u062F \u0627\u0644\u0642\u062D\u0637\u0627\u0646\u064A", level: "5.5" },
  { id: "4", name: "\u0639\u0628\u062F\u0627\u0644\u0644\u0647 \u0627\u0644\u0633\u0627\u0644\u0645", level: "6.0" },
  { id: "5", name: "\u062E\u0627\u0644\u062F \u0627\u0644\u0645\u0637\u064A\u0631\u064A", level: "5.3" },
  { id: "6", name: "\u0646\u0627\u0635\u0631 \u0627\u0644\u0634\u0645\u0631\u064A", level: "5.7" },
  { id: "7", name: "\u0639\u0644\u064A \u0627\u0644\u063A\u0627\u0645\u062F\u064A", level: "5.4" },
  { id: "8", name: "\u0633\u0644\u0637\u0627\u0646 \u0627\u0644\u0639\u0646\u0632\u064A", level: "5.9" }
];
function CreateAmericanoPage({ onBack, onComplete }) {
  const [formData, setFormData] = useState({
    courtName: "",
    courtNumbers: [],
    type: "",
    playersCount: "",
    date: "",
    time: "",
    duration: "",
    minLevel: "",
    maxLevel: "",
    gender: "\u0631\u062C\u0627\u0644",
    notes: ""
  });
  const [showConfirmation, setShowConfirmation] = useState(false);
  const [invitedPlayers, setInvitedPlayers] = useState([]);
  const [showInviteSection, setShowInviteSection] = useState(false);
  const [inviteDuration, setInviteDuration] = useState(24);
  const [showCustomDuration, setShowCustomDuration] = useState(false);
  const [customDuration, setCustomDuration] = useState("");
  const courts = [
    "\u0646\u0627\u062F\u064A \u0627\u0644\u0628\u0627\u062F\u0644 \u0627\u0644\u0645\u0644\u0643\u064A",
    "\u0628\u0627\u062F\u0644 \u0643\u0644\u0648\u0628 \u0627\u0644\u0634\u0631\u0642\u064A\u0629",
    "\u0645\u0631\u0643\u0632 \u0628\u0627\u062F\u0644 \u0627\u0644\u0645\u062F\u064A\u0646\u0629",
    "\u0645\u0644\u0639\u0628 \u0627\u0644\u0623\u0646\u062F\u064A\u0629 \u0627\u0644\u0634\u0631\u0642\u064A\u0629",
    "\u0646\u0627\u062F\u064A \u0627\u0644\u0646\u062E\u0628\u0629",
    "\u0645\u0644\u0627\u0639\u0628 \u0627\u0644\u0648\u0627\u062D\u0629"
  ];
  const levels = ["3.0", "3.5", "4.0", "4.5", "5.0", "5.5", "6.0", "6.5", "7.0"];
  const handleCourtNumberToggle = (number) => {
    setFormData((prev) => ({
      ...prev,
      courtNumbers: prev.courtNumbers.includes(number) ? prev.courtNumbers.filter((n) => n !== number) : [...prev.courtNumbers, number].sort((a, b) => a - b)
    }));
  };
  const isFormValid = () => {
    return formData.courtName !== "" && formData.courtNumbers.length > 0 && formData.type !== "" && formData.playersCount !== "" && parseInt(formData.playersCount) >= 1 && parseInt(formData.playersCount) <= 20 && formData.date !== "" && formData.time !== "" && formData.duration !== "" && formData.minLevel !== "" && formData.maxLevel !== "";
  };
  const handleSubmit = () => {
    if (isFormValid()) {
      setShowConfirmation(true);
      setTimeout(() => {
        if (onComplete) {
          onComplete();
        }
      }, 2e3);
    }
  };
  const formatDate = (dateStr) => {
    if (!dateStr) return "";
    const date = new Date(dateStr);
    const days = ["\u0627\u0644\u0623\u062D\u062F", "\u0627\u0644\u0627\u062B\u0646\u064A\u0646", "\u0627\u0644\u062B\u0644\u0627\u062B\u0627\u0621", "\u0627\u0644\u0623\u0631\u0628\u0639\u0627\u0621", "\u0627\u0644\u062E\u0645\u064A\u0633", "\u0627\u0644\u062C\u0645\u0639\u0629", "\u0627\u0644\u0633\u0628\u062A"];
    const months = ["\u064A\u0646\u0627\u064A\u0631", "\u0641\u0628\u0631\u0627\u064A\u0631", "\u0645\u0627\u0631\u0633", "\u0623\u0628\u0631\u064A\u0644", "\u0645\u0627\u064A\u0648", "\u064A\u0648\u0646\u064A\u0648", "\u064A\u0648\u0644\u064A\u0648", "\u0623\u063A\u0633\u0637\u0633", "\u0633\u0628\u062A\u0645\u0628\u0631", "\u0623\u0643\u062A\u0648\u0628\u0631", "\u0646\u0648\u0641\u0645\u0628\u0631", "\u062F\u064A\u0633\u0645\u0628\u0631"];
    return `${days[date.getDay()]}\u060C ${date.getDate()} ${months[date.getMonth()]}`;
  };
  const formatTime = (timeStr) => {
    if (!timeStr) return "";
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
          <h1 className="text-2xl">إنشاء أمريكانو</h1>
        </div>
        <p className="text-white/80 text-sm">املأ التفاصيل لإنشاء أمريكانو</p>
      </div>

      <div className="px-6 py-6 space-y-5">
        {
    /* اختيار الملعب */
  }
        <div>
          <label className="block text-sm text-secondary mb-3 flex items-center gap-2">
            <MapPin className="w-4 h-4 text-primary" />
            اختر الملعب *
          </label>
          <select
    value={formData.courtName}
    onChange={(e) => setFormData({ ...formData, courtName: e.target.value })}
    className="w-full bg-white border border-border rounded-xl px-4 py-3 text-secondary outline-none focus:border-primary transition-colors"
  >
            <option value="">اختر الملعب</option>
            {courts.map((court) => <option key={court} value={court}>{court}</option>)}
          </select>
        </div>

        {
    /* اختيار أرقام الملاعب */
  }
        <div>
          <label className="block text-sm text-secondary mb-3 flex items-center gap-2">
            <Hash className="w-4 h-4 text-primary" />
            أرقام الملاعب المستخدمة *
          </label>
          <p className="text-xs text-muted-foreground mb-3">اختر الملاعب التي ستستخدم في الأمريكانو (يمكن اختيار عدة ملاعب)</p>
          <div className="grid grid-cols-5 gap-2">
            {Array.from({ length: 10 }, (_, i) => i + 1).map((number) => <button
    key={number}
    onClick={() => handleCourtNumberToggle(number)}
    className={`py-3 rounded-xl border-2 transition-all ${formData.courtNumbers.includes(number) ? "border-primary bg-primary/10 text-primary" : "border-border bg-white text-secondary"}`}
  >
                <div className="text-sm font-medium">{number}</div>
              </button>)}
          </div>
          {formData.courtNumbers.length > 0 && <p className="text-xs text-primary mt-2">
              تم اختيار {formData.courtNumbers.length} ملعب: {formData.courtNumbers.join(", ")}
            </p>}
        </div>

        {
    /* نوع الأمريكانو */
  }
        <div>
          <label className="block text-sm text-secondary mb-3 flex items-center gap-2">
            <TrendingUp className="w-4 h-4 text-primary" />
            نوع الأمريكانو *
          </label>
          <div className="grid grid-cols-2 gap-3">
            <button
    onClick={() => setFormData({ ...formData, type: "\u0641\u0631\u062F\u064A" })}
    className={`py-4 rounded-xl border-2 transition-all ${formData.type === "\u0641\u0631\u062F\u064A" ? "border-primary bg-primary/10 text-primary" : "border-border bg-white text-secondary"}`}
  >
              <div className="font-medium">أمريكانو فردي</div>
              <div className="text-xs mt-1 opacity-70">كل لاعب لوحده</div>
            </button>
            <button
    onClick={() => setFormData({ ...formData, type: "\u0641\u0631\u0642" })}
    className={`py-4 rounded-xl border-2 transition-all ${formData.type === "\u0641\u0631\u0642" ? "border-primary bg-primary/10 text-primary" : "border-border bg-white text-secondary"}`}
  >
              <div className="font-medium">أمريكانو فرق</div>
              <div className="text-xs mt-1 opacity-70">فرق ثابتة</div>
            </button>
          </div>
        </div>

        {
    /* عدد اللاعبين */
  }
        <div>
          <label className="block text-sm text-secondary mb-3 flex items-center gap-2">
            <Users className="w-4 h-4 text-primary" />
            عدد اللاعبين المطلوبين *
          </label>
          <div className="relative">
            <input
    type="number"
    min="1"
    max="20"
    value={formData.playersCount}
    onChange={(e) => setFormData({ ...formData, playersCount: e.target.value })}
    placeholder="أدخل عدد اللاعبين (1-20)"
    className="w-full bg-white border border-border rounded-xl px-4 py-3 pr-12 text-secondary outline-none focus:border-primary transition-colors"
  />
            <Users className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-primary" />
          </div>
          {formData.playersCount && (parseInt(formData.playersCount) < 1 || parseInt(formData.playersCount) > 20) && <p className="text-xs text-red-500 mt-2 flex items-center gap-1">
              <AlertCircle className="w-3 h-3" />
              يجب أن يكون العدد بين 1 و 20 لاعب
            </p>}
        </div>

        {
    /* الجنس */
  }
        <div>
          <label className="block text-sm text-secondary mb-3">الجنس *</label>
          <div className="grid grid-cols-2 gap-3">
            <button
    onClick={() => setFormData({ ...formData, gender: "\u0631\u062C\u0627\u0644" })}
    className={`py-3 rounded-xl border-2 transition-all ${formData.gender === "\u0631\u062C\u0627\u0644" ? "border-primary bg-primary/10 text-primary" : "border-border bg-white text-secondary"}`}
  >
              رجال
            </button>
            <button
    onClick={() => setFormData({ ...formData, gender: "\u0646\u0633\u0627\u0621" })}
    className={`py-3 rounded-xl border-2 transition-all ${formData.gender === "\u0646\u0633\u0627\u0621" ? "border-primary bg-primary/10 text-primary" : "border-border bg-white text-secondary"}`}
  >
              نساء
            </button>
          </div>
        </div>

        {
    /* التاريخ والوقت */
  }
        <div className="grid grid-cols-2 gap-3">
          <div>
            <label className="block text-sm text-secondary mb-3 flex items-center gap-2">
              <Calendar className="w-4 h-4 text-primary" />
              التاريخ *
            </label>
            <input
    type="date"
    value={formData.date}
    onChange={(e) => setFormData({ ...formData, date: e.target.value })}
    className="w-full bg-white border border-border rounded-xl px-4 py-3 text-secondary outline-none focus:border-primary transition-colors"
  />
          </div>
          <div>
            <label className="block text-sm text-secondary mb-3 flex items-center gap-2">
              <Clock className="w-4 h-4 text-primary" />
              الوقت *
            </label>
            <input
    type="time"
    value={formData.time}
    onChange={(e) => setFormData({ ...formData, time: e.target.value })}
    className="w-full bg-white border border-border rounded-xl px-4 py-3 text-secondary outline-none focus:border-primary transition-colors"
  />
          </div>
        </div>

        {
    /* المدة */
  }
        <div>
          <label className="block text-sm text-secondary mb-3 flex items-center gap-2">
            <Clock className="w-4 h-4 text-primary" />
            المدة (دقيقة) *
          </label>
          <div className="relative">
            <input
    type="number"
    min="30"
    max="300"
    value={formData.duration}
    onChange={(e) => setFormData({ ...formData, duration: e.target.value })}
    placeholder="أدخل المدة بالدقائق"
    className="w-full bg-white border border-border rounded-xl px-4 py-3 pr-12 text-secondary outline-none focus:border-primary transition-colors"
  />
            <Clock className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-primary" />
          </div>
        </div>

        {
    /* المستوى */
  }
        <div>
          <label className="block text-sm text-secondary mb-3 flex items-center gap-2">
            <TrendingUp className="w-4 h-4 text-primary" />
            المستوى المطلوب *
          </label>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs text-muted-foreground mb-2">من</label>
              <select
    value={formData.minLevel}
    onChange={(e) => setFormData({ ...formData, minLevel: e.target.value })}
    className="w-full bg-white border border-border rounded-xl px-4 py-3 text-secondary outline-none focus:border-primary transition-colors"
  >
                <option value="">اختر المستوى</option>
                {levels.map((level) => <option key={level} value={level}>{level}</option>)}
              </select>
            </div>
            <div>
              <label className="block text-xs text-muted-foreground mb-2">إلى</label>
              <select
    value={formData.maxLevel}
    onChange={(e) => setFormData({ ...formData, maxLevel: e.target.value })}
    className="w-full bg-white border border-border rounded-xl px-4 py-3 text-secondary outline-none focus:border-primary transition-colors"
  >
                <option value="">اختر المستوى</option>
                {levels.map((level) => <option key={level} value={level}>{level}</option>)}
              </select>
            </div>
          </div>
        </div>

        {
    /* ملاحظات */
  }
        <div>
          <label className="block text-sm text-secondary mb-3">ملاحظات (اختياري)</label>
          <textarea
    value={formData.notes}
    onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
    placeholder="أضف أي ملاحظات أو تعليمات للاعبين..."
    rows={4}
    className="w-full bg-white border border-border rounded-xl px-4 py-3 text-secondary outline-none focus:border-primary transition-colors resize-none"
  />
        </div>

        {
    /* دعوة لاعبين محددين */
  }
        <div className="bg-white border-2 border-border rounded-2xl p-4">
          <div className="flex items-center justify-between mb-3">
            <Tooltip content="دعوة لاعبين محددين للانضمام للأمريكانو" position="top">
              <h3 className="text-secondary font-medium flex items-center gap-2 cursor-help">
                <UserPlus className="w-5 h-5 text-primary" />
                دعوة لاعبين (اختياري)
              </h3>
            </Tooltip>
            <button
    onClick={() => setShowInviteSection(!showInviteSection)}
    className="text-sm text-primary hover:underline"
  >
              {showInviteSection ? "\u0625\u062E\u0641\u0627\u0621" : "\u0625\u0636\u0627\u0641\u0629 \u062F\u0639\u0648\u0627\u062A"}
            </button>
          </div>

          {showInviteSection && <div className="space-y-4">
              {
    /* قائمة اللاعبين المدعوين */
  }
              {invitedPlayers.length > 0 && <div className="space-y-2">
                  <p className="text-xs text-muted-foreground">اللاعبين المدعوين ({invitedPlayers.length})</p>
                  {invitedPlayers.map((player) => <div key={player.id} className="flex items-center justify-between p-3 bg-primary/5 border border-primary/20 rounded-xl">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 bg-gradient-to-br from-primary to-primary/80 rounded-full flex items-center justify-center">
                          <span className="text-white text-sm font-medium">{player.level}</span>
                        </div>
                        <div>
                          <p className="text-sm text-secondary font-medium">{player.name}</p>
                          <p className="text-xs text-muted-foreground">مستوى {player.level}</p>
                        </div>
                      </div>
                      <button
    onClick={() => setInvitedPlayers(invitedPlayers.filter((p) => p.id !== player.id))}
    className="p-2 hover:bg-red-50 rounded-lg transition-colors"
  >
                        <X className="w-4 h-4 text-red-500" />
                      </button>
                    </div>)}
                </div>}

              {
    /* اختيار اللاعبين */
  }
              <div>
                <p className="text-xs text-muted-foreground mb-2">اختر اللاعبين</p>
                <div className="max-h-48 overflow-y-auto space-y-2">
                  {availablePlayers.filter((p) => !invitedPlayers.find((ip) => ip.id === p.id)).map((player) => <button
    key={player.id}
    onClick={() => setInvitedPlayers([...invitedPlayers, player])}
    className="w-full flex items-center gap-3 p-3 bg-white border border-border rounded-xl hover:border-primary/50 hover:bg-primary/5 transition-all text-right"
  >
                        <div className="w-10 h-10 bg-gradient-to-br from-secondary to-secondary/80 rounded-full flex items-center justify-center">
                          <span className="text-white text-sm font-medium">{player.level}</span>
                        </div>
                        <div className="flex-1">
                          <p className="text-sm text-secondary font-medium">{player.name}</p>
                          <p className="text-xs text-muted-foreground">مستوى {player.level}</p>
                        </div>
                        <CheckCircle className="w-5 h-5 text-primary opacity-0 group-hover:opacity-100" />
                      </button>)}
                </div>
              </div>

              {
    /* مدة العرض */
  }
              {invitedPlayers.length > 0 && <div>
                  <p className="text-sm text-secondary mb-2">مدة العرض للموافقة</p>
                  <div className="grid grid-cols-5 gap-2 mb-2">
                    {[1, 6, 12, 24, 48].map((hours) => <button
    key={hours}
    onClick={() => {
      setInviteDuration(hours);
      setShowCustomDuration(false);
      setCustomDuration("");
    }}
    className={`py-2 px-2 rounded-xl border-2 transition-all text-center ${inviteDuration === hours && !showCustomDuration ? "border-primary bg-primary text-white" : "border-border bg-white text-secondary hover:border-primary/50"}`}
  >
                        <div className="text-sm font-medium">{hours}</div>
                        <div className="text-xs mt-0.5 opacity-80">{hours === 1 ? "\u0633\u0627\u0639\u0629" : "\u0633"}</div>
                      </button>)}
                  </div>

                  {!showCustomDuration ? <button
    onClick={() => setShowCustomDuration(true)}
    className="w-full py-2 border-2 border-dashed border-primary/30 rounded-xl text-primary text-sm hover:bg-primary/5 transition-all"
  >
                      + مدة مخصصة
                    </button> : <div className="flex gap-2">
                      <input
    type="number"
    min="1"
    max="48"
    value={customDuration}
    onChange={(e) => {
      const value = e.target.value;
      setCustomDuration(value);
      if (value && parseInt(value) >= 1 && parseInt(value) <= 48) {
        setInviteDuration(parseInt(value));
      }
    }}
    placeholder="أدخل عدد الساعات"
    className="flex-1 px-4 py-2 border-2 border-primary rounded-xl outline-none text-secondary text-center"
  />
                      <button
    onClick={() => {
      setShowCustomDuration(false);
      setCustomDuration("");
      setInviteDuration(24);
    }}
    className="px-4 py-2 bg-gray-100 text-secondary rounded-xl hover:bg-gray-200 transition-colors"
  >
                        <X className="w-4 h-4" />
                      </button>
                    </div>}

                  <p className="text-xs text-muted-foreground mt-2 text-center">
                    سيتلقى اللاعبون إشعاراً ويجب عليهم الموافقة خلال {inviteDuration} {inviteDuration === 1 ? "\u0633\u0627\u0639\u0629" : "\u0633\u0627\u0639\u0627\u062A"}
                  </p>
                </div>}
            </div>}
        </div>

        {
    /* ملخص */
  }
        {formData.courtName && formData.type && formData.playersCount && <div className="bg-gradient-to-br from-green-50 to-green-100/50 border border-green-200 rounded-2xl p-5">
            <div className="flex items-center gap-2 mb-3">
              <CheckCircle className="w-5 h-5 text-green-600" />
              <h3 className="text-secondary font-medium">ملخص الأمريكانو</h3>
            </div>
            <div className="space-y-2 text-sm">
              <div className="flex justify-between">
                <span className="text-muted-foreground">النوع:</span>
                <span className="text-secondary font-medium">أمريكانو {formData.type}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">الملعب:</span>
                <span className="text-secondary">{formData.courtName}</span>
              </div>
              {formData.courtNumbers.length > 0 && <div className="flex justify-between">
                  <span className="text-muted-foreground">أرقام الملاعب:</span>
                  <span className="text-secondary">{formData.courtNumbers.join(", ")}</span>
                </div>}
              <div className="flex justify-between">
                <span className="text-muted-foreground">عدد اللاعبين:</span>
                <span className="text-secondary">{formData.playersCount} لاعب</span>
              </div>
              {formData.date && <div className="flex justify-between">
                  <span className="text-muted-foreground">التاريخ:</span>
                  <span className="text-secondary">{formatDate(formData.date)}</span>
                </div>}
              {formData.time && <div className="flex justify-between">
                  <span className="text-muted-foreground">الوقت:</span>
                  <span className="text-secondary">{formatTime(formData.time)}</span>
                </div>}
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
    onClick={handleSubmit}
    disabled={!isFormValid()}
    className={`flex-1 py-3 rounded-xl shadow-lg transition-all ${isFormValid() ? "bg-gradient-to-r from-green-500 to-green-600 text-white hover:shadow-xl" : "bg-gray-300 text-gray-500 cursor-not-allowed"}`}
  >
            إنشاء الأمريكانو
          </button>
        </div>
      </div>

      {
    /* نافذة التأكيد */
  }
      {showConfirmation && <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center p-6 z-50">
          <div className="bg-white rounded-3xl p-8 max-w-sm w-full shadow-2xl text-center">
            <div className="flex justify-center mb-4">
              <div className="w-20 h-20 bg-green-100 rounded-full flex items-center justify-center animate-pulse">
                <CheckCircle className="w-12 h-12 text-green-600" />
              </div>
            </div>

            <h3 className="text-2xl text-secondary mb-2">تم إنشاء الأمريكانو!</h3>
            <p className="text-sm text-muted-foreground mb-6">
              تم نشر الأمريكانو وإرسال الإشعارات للاعبين المهتمين
            </p>

            <div className="bg-gray-50 rounded-xl p-4 space-y-2 text-sm">
              <div className="flex justify-between">
                <span className="text-muted-foreground">النوع:</span>
                <span className="text-secondary font-medium">أمريكانو {formData.type}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">اللاعبين:</span>
                <span className="text-green-600 font-medium">0/{formData.playersCount}</span>
              </div>
            </div>
          </div>
        </div>}
    </div>;
}
export {
  CreateAmericanoPage as default
};
