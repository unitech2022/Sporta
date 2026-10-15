import { useState } from "react";
import { ChevronRight, MapPin, Calendar, Clock, Users, TrendingUp, DollarSign, UserPlus, X, CheckCircle } from "lucide-react";
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
function CreateMatchPage({ onBack, onComplete }) {
  const [formData, setFormData] = useState({
    courtName: "",
    date: "",
    time: "",
    duration: "90",
    matchType: "",
    minLevel: "",
    maxLevel: "",
    playersNeeded: "2",
    costPerPlayer: "",
    notes: "",
    paymentType: ""
    // 'full' أو 'share'
  });
  const [invitedPlayers, setInvitedPlayers] = useState([]);
  const [showInviteSection, setShowInviteSection] = useState(false);
  const [inviteDuration, setInviteDuration] = useState(24);
  const [showCustomDuration, setShowCustomDuration] = useState(false);
  const [customDuration, setCustomDuration] = useState("");
  const courtPrices = {
    "\u0646\u0627\u062F\u064A \u0627\u0644\u0628\u0627\u062F\u0644 \u0627\u0644\u0645\u0644\u0643\u064A": 120,
    "\u0645\u0644\u0639\u0628 \u0627\u0644\u0623\u0646\u062F\u064A\u0629 \u0627\u0644\u0634\u0631\u0642\u064A\u0629": 100,
    "\u0628\u0627\u062F\u0644 \u0643\u0644\u0648\u0628 \u0627\u0644\u0634\u0631\u0642\u064A\u0629": 110,
    "\u0645\u0644\u0639\u0628 \u0627\u0644\u0646\u0627\u062F\u064A \u0627\u0644\u0631\u064A\u0627\u0636\u064A": 95
  };
  const calculateTotalCost = () => {
    if (!formData.courtName || !formData.duration) return 0;
    const pricePerHour = courtPrices[formData.courtName] || 0;
    const hours = parseInt(formData.duration) / 60;
    return Math.round(pricePerHour * hours);
  };
  const calculatePlayerShare = () => {
    const totalCost2 = calculateTotalCost();
    const totalPlayers = parseInt(formData.playersNeeded) + 1;
    return Math.round(totalCost2 / totalPlayers);
  };
  const totalCost = calculateTotalCost();
  const playerShare = calculatePlayerShare();
  const handleSubmit = () => {
    if (onComplete) {
      onComplete();
    }
  };
  const isFormValid = () => {
    return formData.courtName && formData.date && formData.time && formData.matchType && formData.minLevel && formData.maxLevel;
  };
  return <div className="flex-1 overflow-y-auto bg-background">
      <div className="bg-gradient-to-br from-secondary to-secondary/90 text-white px-6 pt-8 pb-6">
        <div className="flex items-center gap-3 mb-4">
          <button onClick={onBack} className="p-2 bg-white/20 rounded-full backdrop-blur-sm hover:bg-white/30 transition-colors">
            <ChevronRight className="w-5 h-5" />
          </button>
          <h1 className="text-2xl">إنشاء مباراة جديدة</h1>
        </div>
        <p className="text-white/80 text-sm">املأ التفاصيل لإنشاء مباراة مفتوحة</p>
      </div>

      <div className="px-6 py-6 space-y-5">
        {
    /* اختيار الملعب */
  }
        <div>
          <label className="block text-sm text-secondary mb-2 flex items-center gap-2">
            <MapPin className="w-4 h-4 text-primary" />
            اسم الملعب *
          </label>
          <select
    value={formData.courtName}
    onChange={(e) => setFormData({ ...formData, courtName: e.target.value })}
    className="w-full bg-white border border-border rounded-xl px-4 py-3 outline-none focus:border-primary transition-colors text-secondary"
  >
            <option value="">اختر الملعب</option>
            <option value="نادي البادل الملكي">نادي البادل الملكي</option>
            <option value="ملعب الأندية الشرقية">ملعب الأندية الشرقية</option>
            <option value="بادل كلوب الشرقية">بادل كلوب الشرقية</option>
            <option value="ملعب النادي الرياضي">ملعب النادي الرياضي</option>
          </select>
        </div>

        {
    /* التاريخ والوقت */
  }
        <div className="grid grid-cols-2 gap-3">
          <div>
            <label className="block text-sm text-secondary mb-2 flex items-center gap-2">
              <Calendar className="w-4 h-4 text-primary" />
              التاريخ *
            </label>
            <input
    type="date"
    value={formData.date}
    onChange={(e) => setFormData({ ...formData, date: e.target.value })}
    className="w-full bg-white border border-border rounded-xl px-4 py-3 outline-none focus:border-primary transition-colors text-secondary"
  />
          </div>
          <div>
            <label className="block text-sm text-secondary mb-2 flex items-center gap-2">
              <Clock className="w-4 h-4 text-primary" />
              الوقت *
            </label>
            <input
    type="time"
    value={formData.time}
    onChange={(e) => setFormData({ ...formData, time: e.target.value })}
    className="w-full bg-white border border-border rounded-xl px-4 py-3 outline-none focus:border-primary transition-colors text-secondary"
  />
          </div>
        </div>

        {
    /* المدة */
  }
        <div>
          <label className="block text-sm text-secondary mb-2">مدة المباراة</label>
          <div className="grid grid-cols-3 gap-3">
            {["60", "90", "120"].map((duration) => <button
    key={duration}
    onClick={() => setFormData({ ...formData, duration })}
    className={`py-3 rounded-xl border-2 transition-all ${formData.duration === duration ? "border-primary bg-primary/10 text-primary" : "border-border bg-white text-secondary"}`}
  >
                {duration} دقيقة
              </button>)}
          </div>
        </div>

        {
    /* نوع المباراة */
  }
        <div>
          <label className="block text-sm text-secondary mb-2">نوع المباراة *</label>
          <div className="grid grid-cols-2 gap-3">
            <button
    onClick={() => setFormData({ ...formData, matchType: "challenge-team" })}
    className={`py-3 rounded-xl border-2 transition-all ${formData.matchType === "challenge-team" ? "border-primary bg-primary/10 text-primary" : "border-border bg-white text-secondary"}`}
  >
              تحدي فرق
            </button>
            <button
    onClick={() => setFormData({ ...formData, matchType: "friendly-individual" })}
    className={`py-3 rounded-xl border-2 transition-all ${formData.matchType === "friendly-individual" ? "border-primary bg-primary/10 text-primary" : "border-border bg-white text-secondary"}`}
  >
              ودية فردي
            </button>
          </div>
        </div>

        {
    /* المستوى المطلوب */
  }
        <div>
          <label className="block text-sm text-secondary mb-2 flex items-center gap-2">
            <TrendingUp className="w-4 h-4 text-primary" />
            المستوى المطلوب *
          </label>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs text-muted-foreground mb-1">الحد الأدنى</label>
              <select
    value={formData.minLevel}
    onChange={(e) => setFormData({ ...formData, minLevel: e.target.value })}
    className="w-full bg-white border border-border rounded-xl px-4 py-3 outline-none focus:border-primary transition-colors text-secondary"
  >
                <option value="">اختر</option>
                <option value="3.0">3.0 - مبتدئ</option>
                <option value="3.5">3.5 - مبتدئ متقدم</option>
                <option value="4.0">4.0 - متوسط</option>
                <option value="4.5">4.5 - متوسط متقدم</option>
                <option value="5.0">5.0 - متقدم</option>
                <option value="5.5">5.5 - متقدم جداً</option>
                <option value="6.0">6.0 - محترف</option>
                <option value="6.5">6.5 - محترف متقدم</option>
                <option value="7.0">7.0 - نخبة</option>
              </select>
            </div>
            <div>
              <label className="block text-xs text-muted-foreground mb-1">الحد الأقصى</label>
              <select
    value={formData.maxLevel}
    onChange={(e) => setFormData({ ...formData, maxLevel: e.target.value })}
    className="w-full bg-white border border-border rounded-xl px-4 py-3 outline-none focus:border-primary transition-colors text-secondary"
  >
                <option value="">اختر</option>
                <option value="3.0">3.0 - مبتدئ</option>
                <option value="3.5">3.5 - مبتدئ متقدم</option>
                <option value="4.0">4.0 - متوسط</option>
                <option value="4.5">4.5 - متوسط متقدم</option>
                <option value="5.0">5.0 - متقدم</option>
                <option value="5.5">5.5 - متقدم جداً</option>
                <option value="6.0">6.0 - محترف</option>
                <option value="6.5">6.5 - محترف متقدم</option>
                <option value="7.0">7.0 - نخبة</option>
              </select>
            </div>
          </div>
        </div>

        {
    /* عدد اللاعبين المطلوبين */
  }
        <div>
          <label className="block text-sm text-secondary mb-2 flex items-center gap-2">
            <Users className="w-4 h-4 text-primary" />
            عدد اللاعبين المطلوبين
          </label>
          <div className="grid grid-cols-4 gap-3">
            {["1", "2", "3", "4"].map((count) => <button
    key={count}
    onClick={() => setFormData({ ...formData, playersNeeded: count })}
    className={`py-3 rounded-xl border-2 transition-all ${formData.playersNeeded === count ? "border-primary bg-primary/10 text-primary" : "border-border bg-white text-secondary"}`}
  >
                {count}
              </button>)}
          </div>
        </div>

        {
    /* ملخص التكلفة */
  }
        {formData.courtName && formData.duration && <div className="bg-gradient-to-br from-green-50 to-green-100/50 border border-green-200 rounded-2xl p-4">
            <div className="flex items-center gap-2 mb-3">
              <DollarSign className="w-5 h-5 text-green-600" />
              <h3 className="text-secondary font-medium">ملخص التكلفة</h3>
            </div>

            <div className="space-y-2 mb-4">
              <div className="flex justify-between items-center">
                <span className="text-sm text-muted-foreground">تكلفة الملعب الإجمالية:</span>
                <span className="text-lg font-medium text-secondary">{totalCost} ر.س</span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-sm text-muted-foreground">عدد اللاعبين الكلي:</span>
                <span className="text-sm text-secondary">{parseInt(formData.playersNeeded) + 1} لاعبين</span>
              </div>
              <div className="h-px bg-green-200 my-2" />
              <div className="flex justify-between items-center">
                <span className="text-sm text-muted-foreground">حصة اللاعب الواحد:</span>
                <span className="text-lg font-medium text-green-600">{playerShare} ر.س</span>
              </div>
            </div>

            <div>
              <label className="block text-sm text-secondary mb-2">طريقة الدفع *</label>
              <div className="grid grid-cols-2 gap-3">
                <button
    onClick={() => setFormData({ ...formData, paymentType: "full" })}
    className={`p-4 rounded-xl border-2 transition-all ${formData.paymentType === "full" ? "border-green-500 bg-green-50 text-green-700" : "border-border bg-white text-secondary"}`}
  >
                  <div className="text-center">
                    <p className="text-sm font-medium mb-1">دفع المبلغ كاملاً</p>
                    <p className="text-xs opacity-75">{totalCost} ر.س</p>
                  </div>
                </button>
                <button
    onClick={() => setFormData({ ...formData, paymentType: "share" })}
    className={`p-4 rounded-xl border-2 transition-all ${formData.paymentType === "share" ? "border-green-500 bg-green-50 text-green-700" : "border-border bg-white text-secondary"}`}
  >
                  <div className="text-center">
                    <p className="text-sm font-medium mb-1">دفع حصتي فقط</p>
                    <p className="text-xs opacity-75">{playerShare} ر.س</p>
                  </div>
                </button>
              </div>
            </div>
          </div>}

        {
    /* ملاحظات */
  }
        <div>
          <label className="block text-sm text-secondary mb-2">ملاحظات إضافية</label>
          <textarea
    value={formData.notes}
    onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
    placeholder="أي تفاصيل إضافية تريد إضافتها..."
    rows={3}
    className="w-full bg-white border border-border rounded-xl px-4 py-3 outline-none focus:border-primary transition-colors resize-none text-secondary"
  />
        </div>

        {
    /* دعوة لاعبين محددين */
  }
        <div className="bg-white border-2 border-border rounded-2xl p-4">
          <div className="flex items-center justify-between mb-3">
            <Tooltip content="دعوة لاعبين محددين للانضمام للمباراة" position="top">
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
    /* معاينة المباراة */
  }
        {isFormValid() && <div className="bg-primary/5 border border-primary/20 rounded-2xl p-4">
            <h3 className="text-secondary mb-3 flex items-center gap-2">
              <span className="w-2 h-2 bg-primary rounded-full" />
              معاينة المباراة
            </h3>
            <div className="space-y-2 text-sm">
              <div className="flex justify-between">
                <span className="text-muted-foreground">الملعب:</span>
                <span className="text-secondary">{formData.courtName}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">التاريخ:</span>
                <span className="text-secondary">{formData.date}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">الوقت:</span>
                <span className="text-secondary">{formData.time}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">النوع:</span>
                <span className="text-secondary">
                  {formData.matchType === "challenge-team" && "\u062A\u062D\u062F\u064A \u0641\u0631\u0642"}
                  {formData.matchType === "friendly-individual" && "\u0648\u062F\u064A\u0629 \u0641\u0631\u062F\u064A"}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">المستوى:</span>
                <span className="text-secondary">{formData.minLevel} - {formData.maxLevel}</span>
              </div>
              {formData.costPerPlayer && <div className="flex justify-between">
                  <span className="text-muted-foreground">التكلفة:</span>
                  <span className="text-secondary">{formData.costPerPlayer} ر.س</span>
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
    className={`flex-1 py-3 rounded-xl shadow-lg ${isFormValid() ? "bg-gradient-to-r from-primary to-primary/90 text-white" : "bg-gray-300 text-gray-500 cursor-not-allowed"}`}
  >
            إنشاء المباراة
          </button>
        </div>
      </div>
    </div>;
}
export {
  CreateMatchPage as default
};
