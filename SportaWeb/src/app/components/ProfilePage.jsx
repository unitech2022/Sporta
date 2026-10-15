import { useState } from "react";
import { Settings, Trophy, Calendar, TrendingUp, Users, ChevronLeft, Wallet, ChevronRight, LogOut, Plus, Trash2, MapPin, Clock, Languages, MessageCircle, Bell, UserCheck, Star, AlertTriangle, X, Heart, FileText, Shield, Tag, Percent, Gift, ChevronDown, ChevronUp, BarChart2, ArrowUpRight, ArrowDownRight, Filter, Download } from "lucide-react";
import PlayerProfileCompletion from "./profile/PlayerProfileCompletion";
import CoachProfileCompletion from "./profile/CoachProfileCompletion";
import VenueProfileCompletion from "./profile/VenueProfileCompletion";
import LanguageSettings from "./LanguageSettings";
import ContactUs from "./ContactUs";
import AccountSettings from "./AccountSettings";
import TermsAndConditions from "./TermsAndConditions";
import PrivacyPolicy from "./PrivacyPolicy";
import RefundPolicy from "./RefundPolicy";
import WhatsAppContact from "./WhatsAppContact";
import LiveChat from "./LiveChat";
import TopUpWalletPage from "./TopUpWalletPage";
const initialNotifs = [
  {
    id: "n1",
    type: "friend",
    read: false,
    time: "\u0645\u0646\u0630 5 \u062F\u0642\u0627\u0626\u0642",
    senderName: "\u0645\u062D\u0645\u062F \u0627\u0644\u0639\u062A\u064A\u0628\u064A",
    senderAvatar: "\u0645.\u0639",
    senderColor: "from-primary to-primary/80",
    senderLevel: "4.8"
  },
  {
    id: "n2",
    type: "match-invite",
    read: false,
    time: "\u0645\u0646\u0630 20 \u062F\u0642\u064A\u0642\u0629",
    senderName: "\u0633\u0639\u062F \u0627\u0644\u0642\u062D\u0637\u0627\u0646\u064A",
    senderAvatar: "\u0633.\u0642",
    senderColor: "from-green-500 to-green-600",
    matchType: "\u0648\u062F\u064A\u0629 \u0641\u0631\u0642",
    venueName: "\u0646\u0627\u062F\u064A \u0627\u0644\u0628\u0627\u062F\u0644 \u0627\u0644\u0645\u0644\u0643\u064A",
    matchTime: "\u0627\u0644\u064A\u0648\u0645 7:00 \u0645\u0633\u0627\u0621\u064B"
  },
  {
    id: "n3",
    type: "teammate-invite",
    read: false,
    time: "\u0645\u0646\u0630 \u0633\u0627\u0639\u0629",
    inviterName: "\u062E\u0627\u0644\u062F \u0627\u0644\u0645\u0637\u064A\u0631\u064A",
    inviterAvatar: "\u062E.\u0645",
    inviterColor: "from-purple-500 to-purple-600",
    matchType: "\u0623\u0645\u0631\u064A\u0643\u0627\u0646\u0648 \u0641\u0631\u062F\u064A",
    venueName: "\u0645\u0644\u0639\u0628 \u0627\u0644\u0623\u0646\u062F\u064A\u0629 \u0627\u0644\u0634\u0631\u0642\u064A\u0629",
    matchTime: "\u063A\u062F\u0627\u064B 5:00 \u0645\u0633\u0627\u0621\u064B"
  },
  {
    id: "n4",
    type: "app",
    read: true,
    time: "\u0645\u0646\u0630 3 \u0633\u0627\u0639\u0627\u062A",
    appTitle: "\u062A\u0645 \u062A\u0623\u0643\u064A\u062F \u062D\u062C\u0632\u0643",
    appBody: "\u062A\u0645 \u062A\u0623\u0643\u064A\u062F \u062D\u062C\u0632 \u0627\u0644\u0645\u0644\u0639\u0628 \u0631\u0642\u0645 3 \u0641\u064A \u0646\u0627\u062F\u064A \u0627\u0644\u0628\u0627\u062F\u0644 \u0627\u0644\u0645\u0644\u0643\u064A \u063A\u062F\u0627\u064B \u0627\u0644\u0633\u0627\u0639\u0629 5:00 \u0645\u0633\u0627\u0621\u064B."
  },
  {
    id: "n5",
    type: "app",
    read: true,
    time: "\u0645\u0646\u0630 \u064A\u0648\u0645",
    appTitle: "\u0639\u0631\u0636 \u062D\u0635\u0631\u064A! \u{1F389}",
    appBody: "\u0627\u062D\u0635\u0644 \u0639\u0644\u0649 \u062E\u0635\u0645 20% \u0639\u0644\u0649 \u062D\u062C\u0632 \u0627\u0644\u0645\u0644\u0627\u0639\u0628 \u062E\u0644\u0627\u0644 \u0623\u0648\u0642\u0627\u062A \u0627\u0644\u0630\u0631\u0648\u0629 \u0647\u0630\u0627 \u0627\u0644\u0623\u0633\u0628\u0648\u0639."
  }
];
function PlayerNotificationsSection() {
  const [notifs, setNotifs] = useState(initialNotifs);
  const [showAll, setShowAll] = useState(false);
  const unread = notifs.filter((n) => !n.read).length;
  const displayed = showAll ? notifs : notifs.slice(0, 4);
  const markRead = (id) => setNotifs((prev) => prev.map((n) => n.id === id ? { ...n, read: true } : n));
  const dismiss = (id) => setNotifs((prev) => prev.filter((n) => n.id !== id));
  const markAllRead = () => setNotifs((prev) => prev.map((n) => ({ ...n, read: true })));
  const AcceptDenyBtns = ({ id, acceptLabel = "\u0642\u0628\u0648\u0644", denyLabel = "\u0631\u0641\u0636" }) => <div className="flex gap-2 mt-3">
      <button
    onClick={() => dismiss(id)}
    className="flex-1 py-2 bg-primary text-white text-xs rounded-xl hover:bg-primary/90 transition-colors"
  >
        {acceptLabel}
      </button>
      <button
    onClick={() => dismiss(id)}
    className="flex-1 py-2 bg-gray-100 text-secondary text-xs rounded-xl hover:bg-gray-200 transition-colors"
  >
        {denyLabel}
      </button>
    </div>;
  return <div className="bg-white border border-border rounded-2xl overflow-hidden shadow-sm">
      {
    /* الرأس */
  }
      <div className="flex items-center justify-between px-5 py-4 border-b border-border">
        <h2 className="text-lg text-secondary flex items-center gap-2">
          <Bell className="w-5 h-5 text-primary" />
          الإشعارات
          {unread > 0 && <span className="px-2 py-0.5 bg-red-500 text-white text-xs rounded-full">{unread}</span>}
        </h2>
        {unread > 0 && <button onClick={markAllRead} className="text-xs text-primary hover:text-primary/80 transition-colors">
            تحديد الكل كمقروء
          </button>}
      </div>

      <div className="divide-y divide-border">
        {notifs.length === 0 && <p className="text-sm text-muted-foreground text-center py-8">لا توجد إشعارات</p>}
        {displayed.map((n) => <div key={n.id} className={`px-4 py-4 transition-colors ${!n.read ? "bg-blue-50/40" : "bg-white"}`}>

            {
    /* ── طلب صداقة ── */
  }
            {n.type === "friend" && <div>
                <div className="flex items-start gap-3">
                  {!n.read && <div className="w-2 h-2 bg-blue-500 rounded-full mt-1.5 flex-shrink-0" />}
                  <div className={`w-10 h-10 bg-gradient-to-br ${n.senderColor} rounded-full flex items-center justify-center flex-shrink-0`}>
                    <span className="text-white text-xs">{n.senderAvatar}</span>
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-start justify-between gap-2">
                      <div>
                        <p className="text-sm text-secondary">
                          <span className="font-medium">{n.senderName}</span> أرسل لك طلب صداقة
                        </p>
                        <div className="flex items-center gap-2 mt-0.5">
                          <span className="text-[10px] px-1.5 py-0.5 bg-blue-100 text-blue-700 rounded-full">مستوى {n.senderLevel}</span>
                          <span className="text-xs text-muted-foreground">{n.time}</span>
                        </div>
                      </div>
                      <button onClick={() => dismiss(n.id)} className="text-muted-foreground hover:text-secondary p-1">
                        <X className="w-4 h-4" />
                      </button>
                    </div>
                    <AcceptDenyBtns id={n.id} acceptLabel="قبول الصداقة" denyLabel="رفض" />
                  </div>
                </div>
              </div>}

            {
    /* ── دعوة لمباراة ── */
  }
            {n.type === "match-invite" && <div>
                <div className="flex items-start gap-3">
                  {!n.read && <div className="w-2 h-2 bg-green-500 rounded-full mt-1.5 flex-shrink-0" />}
                  <div className={`w-10 h-10 bg-gradient-to-br ${n.senderColor} rounded-full flex items-center justify-center flex-shrink-0`}>
                    <span className="text-white text-xs">{n.senderAvatar}</span>
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-start justify-between gap-2">
                      <div>
                        <p className="text-sm text-secondary">
                          <span className="font-medium">{n.senderName}</span> دعاك للانضمام لمباراة
                        </p>
                        <div className="flex items-center gap-1.5 mt-0.5 flex-wrap">
                          <span className="text-[10px] px-1.5 py-0.5 bg-green-100 text-green-700 rounded-full">{n.matchType}</span>
                          <span className="text-xs text-muted-foreground">{n.time}</span>
                        </div>
                      </div>
                      <button onClick={() => dismiss(n.id)} className="text-muted-foreground hover:text-secondary p-1">
                        <X className="w-4 h-4" />
                      </button>
                    </div>
                    <div className="mt-2 bg-white border border-border rounded-xl px-3 py-2 text-xs text-secondary space-y-1">
                      <div className="flex items-center gap-1.5">
                        <MapPin className="w-3 h-3 text-primary flex-shrink-0" />
                        <span>{n.venueName}</span>
                      </div>
                      <div className="flex items-center gap-1.5">
                        <Clock className="w-3 h-3 text-primary flex-shrink-0" />
                        <span>{n.matchTime}</span>
                      </div>
                    </div>
                    <AcceptDenyBtns id={n.id} acceptLabel="انضمام للمباراة" denyLabel="رفض الدعوة" />
                  </div>
                </div>
              </div>}

            {
    /* ── دعوة زميل ── */
  }
            {n.type === "teammate-invite" && <div>
                <div className="flex items-start gap-3">
                  {!n.read && <div className="w-2 h-2 bg-purple-500 rounded-full mt-1.5 flex-shrink-0" />}
                  <div className={`w-10 h-10 bg-gradient-to-br ${n.inviterColor} rounded-full flex items-center justify-center flex-shrink-0`}>
                    <span className="text-white text-xs">{n.inviterAvatar}</span>
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-start justify-between gap-2">
                      <div>
                        <p className="text-sm text-secondary">
                          <span className="font-medium">{n.inviterName}</span> يريدك شريكاً معه
                        </p>
                        <div className="flex items-center gap-1.5 mt-0.5 flex-wrap">
                          <span className="text-[10px] px-1.5 py-0.5 bg-purple-100 text-purple-700 rounded-full">{n.matchType}</span>
                          <span className="text-xs text-muted-foreground">{n.time}</span>
                        </div>
                      </div>
                      <button onClick={() => dismiss(n.id)} className="text-muted-foreground hover:text-secondary p-1">
                        <X className="w-4 h-4" />
                      </button>
                    </div>
                    <div className="mt-2 bg-white border border-border rounded-xl px-3 py-2 text-xs text-secondary space-y-1">
                      <div className="flex items-center gap-1.5">
                        <MapPin className="w-3 h-3 text-purple-500 flex-shrink-0" />
                        <span>{n.venueName}</span>
                      </div>
                      <div className="flex items-center gap-1.5">
                        <Clock className="w-3 h-3 text-purple-500 flex-shrink-0" />
                        <span>{n.matchTime}</span>
                      </div>
                    </div>
                    <AcceptDenyBtns id={n.id} acceptLabel="قبول الشراكة" denyLabel="رفض" />
                  </div>
                </div>
              </div>}

            {
    /* ── إشعار من التطبيق ── */
  }
            {n.type === "app" && <div className="flex items-start gap-3" onClick={() => markRead(n.id)}>
                {!n.read && <div className="w-2 h-2 bg-primary rounded-full mt-1.5 flex-shrink-0" />}
                <div className="w-10 h-10 bg-gradient-to-br from-primary/20 to-primary/30 rounded-full flex items-center justify-center flex-shrink-0">
                  <Bell className="w-5 h-5 text-primary" />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-start justify-between gap-2">
                    <div className="flex-1">
                      <p className="text-sm text-secondary font-medium">{n.appTitle}</p>
                      <p className="text-xs text-muted-foreground mt-0.5 leading-relaxed">{n.appBody}</p>
                      <p className="text-xs text-muted-foreground mt-1">{n.time}</p>
                    </div>
                    <button onClick={() => dismiss(n.id)} className="text-muted-foreground hover:text-secondary p-1 flex-shrink-0">
                      <X className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              </div>}
          </div>)}
      </div>

      {notifs.length > 4 && <div className="px-5 py-3 border-t border-border">
          <button
    onClick={() => setShowAll(!showAll)}
    className="w-full py-2 text-sm text-primary hover:text-primary/80 transition-colors"
  >
            {showAll ? "\u0639\u0631\u0636 \u0623\u0642\u0644" : `\u0639\u0631\u0636 \u062C\u0645\u064A\u0639 \u0627\u0644\u0625\u0634\u0639\u0627\u0631\u0627\u062A (${notifs.length})`}
          </button>
        </div>}
    </div>;
}
const DAYS = [
  { key: "sat", label: "\u0627\u0644\u0633\u0628\u062A" },
  { key: "sun", label: "\u0627\u0644\u0623\u062D\u062F" },
  { key: "mon", label: "\u0627\u0644\u0627\u062B\u0646\u064A\u0646" },
  { key: "tue", label: "\u0627\u0644\u062B\u0644\u0627\u062B\u0627\u0621" },
  { key: "wed", label: "\u0627\u0644\u0623\u0631\u0628\u0639\u0627\u0621" },
  { key: "thu", label: "\u0627\u0644\u062E\u0645\u064A\u0633" },
  { key: "fri", label: "\u0627\u0644\u062C\u0645\u0639\u0629" }
];
const initialCourts = [
  {
    id: "c1",
    name: "\u0645\u0644\u0639\u0628 1",
    type: "indoor",
    active: true,
    availableDays: ["sat", "sun", "mon", "tue", "wed", "thu"],
    timeSlots: [
      { id: "s1", from: "06:00", to: "12:00", price: "100", label: "\u0635\u0628\u0627\u062D\u064A" },
      { id: "s2", from: "12:00", to: "17:00", price: "120", label: "\u0638\u0647\u0631\u064A" },
      { id: "s3", from: "17:00", to: "23:00", price: "150", label: "\u0645\u0633\u0627\u0626\u064A" }
    ]
  },
  {
    id: "c2",
    name: "\u0645\u0644\u0639\u0628 2",
    type: "outdoor",
    active: true,
    availableDays: ["sat", "sun", "mon", "tue", "wed", "thu", "fri"],
    timeSlots: [
      { id: "s4", from: "07:00", to: "12:00", price: "80", label: "\u0635\u0628\u0627\u062D\u064A" },
      { id: "s5", from: "16:00", to: "23:00", price: "130", label: "\u0645\u0633\u0627\u0626\u064A" }
    ]
  }
];
function VenueCourtsSection() {
  const [courts, setCourts] = useState(initialCourts);
  const [editingId, setEditingId] = useState(null);
  const [showAddForm, setShowAddForm] = useState(false);
  const [expandedId, setExpandedId] = useState("c1");
  const emptyForm = () => ({
    id: `c${Date.now()}`,
    name: "",
    type: "indoor",
    active: true,
    availableDays: ["sat", "sun", "mon", "tue", "wed", "thu"],
    timeSlots: [{ id: `s${Date.now()}`, from: "06:00", to: "12:00", price: "", label: "\u0635\u0628\u0627\u062D\u064A" }]
  });
  const [form, setForm] = useState(emptyForm());
  const startEdit = (c) => {
    setForm({ ...c, timeSlots: c.timeSlots.map((s) => ({ ...s })) });
    setEditingId(c.id);
    setShowAddForm(false);
  };
  const startAdd = () => {
    setForm(emptyForm());
    setShowAddForm(true);
    setEditingId(null);
  };
  const cancelForm = () => {
    setShowAddForm(false);
    setEditingId(null);
  };
  const saveForm = () => {
    if (!form.name) return;
    if (editingId) {
      setCourts((prev) => prev.map((c) => c.id === editingId ? { ...form } : c));
    } else {
      setCourts((prev) => [...prev, { ...form }]);
    }
    cancelForm();
  };
  const removeCourt = (id) => setCourts((prev) => prev.filter((c) => c.id !== id));
  const toggleActive = (id) => setCourts((prev) => prev.map((c) => c.id === id ? { ...c, active: !c.active } : c));
  const toggleDay = (day) => setForm((p) => ({
    ...p,
    availableDays: p.availableDays.includes(day) ? p.availableDays.filter((d) => d !== day) : [...p.availableDays, day]
  }));
  const addSlot = () => setForm((p) => ({ ...p, timeSlots: [...p.timeSlots, { id: `s${Date.now()}`, from: "08:00", to: "14:00", price: "", label: "\u0641\u062A\u0631\u0629 \u062C\u062F\u064A\u062F\u0629" }] }));
  const removeSlot = (sid) => setForm((p) => ({ ...p, timeSlots: p.timeSlots.filter((s) => s.id !== sid) }));
  const updateSlot = (sid, field, val) => setForm((p) => ({ ...p, timeSlots: p.timeSlots.map((s) => s.id === sid ? { ...s, [field]: val } : s) }));
  const CourtForm = () => <div className="border-2 border-dashed border-primary/40 rounded-2xl p-4 space-y-4 bg-primary/5">
      <p className="text-sm text-secondary flex items-center gap-2">
        <MapPin className="w-4 h-4 text-primary" />
        {editingId ? "\u062A\u0639\u062F\u064A\u0644 \u0627\u0644\u0645\u0644\u0639\u0628" : "\u0625\u0636\u0627\u0641\u0629 \u0645\u0644\u0639\u0628 \u062C\u062F\u064A\u062F"}
      </p>

      {
    /* الاسم + النوع */
  }
      <div className="grid grid-cols-2 gap-3">
        <div>
          <label className="text-xs text-muted-foreground block mb-1">اسم الملعب</label>
          <input
    value={form.name}
    onChange={(e) => setForm((p) => ({ ...p, name: e.target.value }))}
    placeholder="مثال: ملعب 3"
    className="w-full border-2 border-border rounded-xl px-3 py-2.5 text-sm text-secondary outline-none focus:border-primary"
  />
        </div>
        <div>
          <label className="text-xs text-muted-foreground block mb-1">نوع الملعب</label>
          <select
    value={form.type}
    onChange={(e) => setForm((p) => ({ ...p, type: e.target.value }))}
    className="w-full border-2 border-border rounded-xl px-3 py-2.5 text-sm text-secondary outline-none focus:border-primary bg-white"
  >
            <option value="indoor">داخلي</option>
            <option value="outdoor">خارجي</option>
          </select>
        </div>
      </div>

      {
    /* الأيام المتاحة */
  }
      <div>
        <label className="text-xs text-muted-foreground block mb-2">الأيام المتاحة</label>
        <div className="flex flex-wrap gap-2">
          {DAYS.map((d) => <button
    key={d.key}
    type="button"
    onClick={() => toggleDay(d.key)}
    className={`px-3 py-1.5 rounded-xl text-xs border-2 transition-all ${form.availableDays.includes(d.key) ? "bg-primary border-primary text-white" : "border-border text-secondary hover:border-primary/50 bg-white"}`}
  >
              {d.label}
            </button>)}
        </div>
      </div>

      {
    /* الفترات والأسعار */
  }
      <div>
        <div className="flex items-center justify-between mb-2">
          <label className="text-xs text-muted-foreground">الفترات والأسعار</label>
          <button onClick={addSlot} className="text-xs text-primary flex items-center gap-1 hover:text-primary/80">
            <Plus className="w-3 h-3" />إضافة فترة
          </button>
        </div>
        <div className="space-y-2">
          {form.timeSlots.map((s) => <div key={s.id} className="bg-white border border-border rounded-xl p-3 space-y-2">
              <div className="grid grid-cols-3 gap-2">
                <div>
                  <label className="text-[10px] text-muted-foreground block mb-1">اسم الفترة</label>
                  <input
    value={s.label}
    onChange={(e) => updateSlot(s.id, "label", e.target.value)}
    className="w-full border border-border rounded-lg px-2 py-1.5 text-xs text-secondary outline-none focus:border-primary"
  />
                </div>
                <div>
                  <label className="text-[10px] text-muted-foreground block mb-1">من</label>
                  <input
    type="time"
    value={s.from}
    onChange={(e) => updateSlot(s.id, "from", e.target.value)}
    className="w-full border border-border rounded-lg px-2 py-1.5 text-xs text-secondary outline-none focus:border-primary"
  />
                </div>
                <div>
                  <label className="text-[10px] text-muted-foreground block mb-1">إلى</label>
                  <input
    type="time"
    value={s.to}
    onChange={(e) => updateSlot(s.id, "to", e.target.value)}
    className="w-full border border-border rounded-lg px-2 py-1.5 text-xs text-secondary outline-none focus:border-primary"
  />
                </div>
              </div>
              <div className="flex items-center gap-2">
                <div className="flex-1 relative">
                  <label className="text-[10px] text-muted-foreground block mb-1">السعر (ر.س / ساعة)</label>
                  <input
    type="number"
    value={s.price}
    onChange={(e) => updateSlot(s.id, "price", e.target.value)}
    placeholder="0"
    className="w-full border border-border rounded-lg px-2 py-1.5 text-xs text-secondary outline-none focus:border-primary"
  />
                </div>
                {form.timeSlots.length > 1 && <button onClick={() => removeSlot(s.id)} className="mt-4 p-1.5 hover:bg-red-50 rounded-lg group">
                    <Trash2 className="w-3.5 h-3.5 text-gray-400 group-hover:text-red-500" />
                  </button>}
              </div>
            </div>)}
        </div>
      </div>

      <div className="flex gap-3 pt-1">
        <button
    onClick={cancelForm}
    className="flex-1 py-2.5 border-2 border-border text-secondary rounded-xl text-sm hover:bg-gray-100 transition-colors"
  >
          إلغاء
        </button>
        <button
    onClick={saveForm}
    disabled={!form.name || form.availableDays.length === 0}
    className="flex-1 py-2.5 bg-primary text-white rounded-xl text-sm hover:bg-primary/90 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
  >
          {editingId ? "\u062D\u0641\u0638 \u0627\u0644\u062A\u0639\u062F\u064A\u0644\u0627\u062A" : "\u0625\u0636\u0627\u0641\u0629 \u0627\u0644\u0645\u0644\u0639\u0628"}
        </button>
      </div>
    </div>;
  return <div className="bg-white border border-border rounded-2xl overflow-hidden shadow-sm">
      <div className="flex items-center justify-between px-5 py-4 border-b border-border">
        <h2 className="text-lg text-secondary flex items-center gap-2">
          <MapPin className="w-5 h-5 text-primary" />
          إدارة الملاعب
          <span className="text-xs text-muted-foreground bg-gray-100 px-2 py-0.5 rounded-full">{courts.length} ملاعب</span>
        </h2>
        {!showAddForm && !editingId && <button
    onClick={startAdd}
    className="flex items-center gap-1.5 px-3 py-1.5 bg-primary text-white text-xs rounded-xl hover:bg-primary/90 transition-colors"
  >
            <Plus className="w-3.5 h-3.5" />إضافة ملعب
          </button>}
      </div>

      <div className="p-4 space-y-3">
        {(showAddForm || editingId) && <CourtForm />}

        {courts.map((court) => {
    const isOpen = expandedId === court.id;
    const isEditing = editingId === court.id;
    return <div key={court.id} className={`border-2 rounded-2xl overflow-hidden transition-all ${court.active ? "border-primary/20" : "border-border opacity-60"}`}>
              {
      /* رأس الملعب */
    }
              <button
      onClick={() => setExpandedId(isOpen ? null : court.id)}
      className="w-full flex items-center justify-between px-4 py-3 bg-gray-50 hover:bg-gray-100 transition-colors"
    >
                <div className="flex items-center gap-3">
                  <div className="w-9 h-9 bg-gradient-to-br from-primary to-primary/80 rounded-xl flex items-center justify-center flex-shrink-0">
                    <span className="text-white text-xs">{court.name.split(" ")[1] || "1"}</span>
                  </div>
                  <div className="text-right">
                    <p className="text-sm text-secondary">{court.name}</p>
                    <p className="text-xs text-muted-foreground">{court.type === "indoor" ? "\u062F\u0627\u062E\u0644\u064A" : "\u062E\u0627\u0631\u062C\u064A"} • {court.availableDays.length} أيام</p>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <span className={`text-[10px] px-2 py-0.5 rounded-full ${court.active ? "bg-green-100 text-green-700" : "bg-gray-200 text-gray-500"}`}>
                    {court.active ? "\u0646\u0634\u0637" : "\u0645\u0639\u0637\u0651\u0644"}
                  </span>
                  {isOpen ? <ChevronUp className="w-4 h-4 text-muted-foreground" /> : <ChevronDown className="w-4 h-4 text-muted-foreground" />}
                </div>
              </button>

              {
      /* تفاصيل الملعب */
    }
              {isOpen && !isEditing && <div className="px-4 pb-4 pt-3 space-y-3">
                  {
      /* الأيام */
    }
                  <div>
                    <p className="text-xs text-muted-foreground mb-1.5">الأيام المتاحة</p>
                    <div className="flex flex-wrap gap-1.5">
                      {DAYS.map((d) => <span key={d.key} className={`px-2.5 py-1 rounded-lg text-xs ${court.availableDays.includes(d.key) ? "bg-primary/10 text-primary border border-primary/20" : "bg-gray-100 text-gray-400 line-through"}`}>
                          {d.label}
                        </span>)}
                    </div>
                  </div>

                  {
      /* الفترات والأسعار */
    }
                  <div>
                    <p className="text-xs text-muted-foreground mb-1.5">الفترات والأسعار</p>
                    <div className="space-y-1.5">
                      {court.timeSlots.map((s) => <div key={s.id} className="flex items-center justify-between bg-gray-50 rounded-xl px-3 py-2">
                          <div className="flex items-center gap-2">
                            <Clock className="w-3.5 h-3.5 text-primary" />
                            <span className="text-xs text-secondary">{s.label}</span>
                            <span className="text-xs text-muted-foreground">{s.from} – {s.to}</span>
                          </div>
                          <span className="text-sm text-primary">{s.price} ر.س<span className="text-xs text-muted-foreground">/س</span></span>
                        </div>)}
                    </div>
                  </div>

                  {
      /* أزرار الإجراءات */
    }
                  <div className="flex gap-2 pt-1">
                    <button
      onClick={() => startEdit(court)}
      className="flex-1 flex items-center justify-center gap-1.5 py-2 bg-primary/10 text-primary text-xs rounded-xl hover:bg-primary/20 transition-colors"
    >
                      <Settings className="w-3.5 h-3.5" />تعديل
                    </button>
                    <button
      onClick={() => toggleActive(court.id)}
      className={`flex-1 py-2 text-xs rounded-xl transition-colors ${court.active ? "bg-orange-50 text-orange-600 hover:bg-orange-100" : "bg-green-50 text-green-600 hover:bg-green-100"}`}
    >
                      {court.active ? "\u062A\u0639\u0637\u064A\u0644 \u0645\u0624\u0642\u062A" : "\u062A\u0641\u0639\u064A\u0644"}
                    </button>
                    <button
      onClick={() => removeCourt(court.id)}
      className="p-2 hover:bg-red-50 rounded-xl group transition-colors"
    >
                      <Trash2 className="w-4 h-4 text-gray-400 group-hover:text-red-500" />
                    </button>
                  </div>
                </div>}
            </div>;
  })}

        {courts.length === 0 && !showAddForm && <div className="text-center py-6">
            <MapPin className="w-10 h-10 text-gray-300 mx-auto mb-2" />
            <p className="text-sm text-muted-foreground">لا توجد ملاعب مضافة بعد</p>
            <button onClick={startAdd} className="mt-3 text-sm text-primary hover:text-primary/80">أضف أول ملعب</button>
          </div>}
      </div>
    </div>;
}
function VenueOffersSection({ courtNames }) {
  const [expanded, setExpanded] = useState(false);
  const [showForm, setShowForm] = useState(false);
  const [offers, setOffers] = useState([
    { id: "vo1", title: "\u062E\u0635\u0645 \u0627\u0644\u0635\u0628\u0627\u062D \u0627\u0644\u0628\u0627\u0643\u0631", discount: 25, courtId: "all", period: "\u0635\u0628\u0627\u062D\u064A (6 \u0635 \u2013 12 \u0645)", active: true, expiryDate: "2026-07-31" },
    { id: "vo2", title: "\u0639\u0631\u0636 \u0646\u0647\u0627\u064A\u0629 \u0627\u0644\u0623\u0633\u0628\u0648\u0639", discount: 15, courtId: "\u0645\u0644\u0639\u0628 1", period: "\u0645\u0633\u0627\u0626\u064A (5 \u0645 \u2013 11 \u0645)", active: false, expiryDate: "2026-06-30" }
  ]);
  const [newOffer, setNewOffer] = useState({ title: "", discount: "", courtId: "all", period: "", expiryDate: "" });
  const addOffer = () => {
    if (!newOffer.title || !newOffer.discount) return;
    setOffers((p) => [...p, { id: `vo${Date.now()}`, title: newOffer.title, discount: parseInt(newOffer.discount), courtId: newOffer.courtId, period: newOffer.period, active: true, expiryDate: newOffer.expiryDate || "2026-12-31" }]);
    setNewOffer({ title: "", discount: "", courtId: "all", period: "", expiryDate: "" });
    setShowForm(false);
  };
  const toggleOffer = (id) => setOffers((p) => p.map((o) => o.id === id ? { ...o, active: !o.active } : o));
  const removeOffer = (id) => setOffers((p) => p.filter((o) => o.id !== id));
  return <div className="bg-white border border-border rounded-2xl overflow-hidden shadow-sm">
      <button
    onClick={() => setExpanded(!expanded)}
    className="w-full flex items-center justify-between px-5 py-4 hover:bg-gray-50 transition-colors"
  >
        <div className="flex items-center gap-2">
          <Tag className="w-5 h-5 text-orange-500" />
          <h2 className="text-lg text-secondary">العروض والخصومات</h2>
          <span className="px-2 py-0.5 bg-orange-100 text-orange-600 text-xs rounded-full">{offers.filter((o) => o.active).length} نشطة</span>
        </div>
        {expanded ? <ChevronUp className="w-5 h-5 text-muted-foreground" /> : <ChevronDown className="w-5 h-5 text-muted-foreground" />}
      </button>

      {expanded && <div className="px-5 pb-5 space-y-3 border-t border-border pt-4">
          {offers.map((o) => <div key={o.id} className={`rounded-2xl border-2 p-4 transition-all ${o.active ? "border-orange-200 bg-orange-50" : "border-border bg-gray-50 opacity-60"}`}>
              <div className="flex items-start justify-between gap-2 mb-2">
                <div className="flex-1">
                  <p className="text-sm text-secondary">{o.title}</p>
                  <div className="flex items-center gap-2 mt-0.5 flex-wrap">
                    <span className="text-[10px] px-1.5 py-0.5 bg-blue-100 text-blue-700 rounded-full">{o.courtId === "all" ? "\u062C\u0645\u064A\u0639 \u0627\u0644\u0645\u0644\u0627\u0639\u0628" : o.courtId}</span>
                    {o.period && <span className="text-[10px] text-muted-foreground">{o.period}</span>}
                    <span className="text-[10px] text-muted-foreground">ينتهي: {o.expiryDate}</span>
                  </div>
                </div>
                <div className="flex items-center gap-1.5 bg-white border-2 border-orange-300 rounded-xl px-2.5 py-1.5 flex-shrink-0">
                  <Percent className="w-3 h-3 text-orange-500" />
                  <span className="text-orange-600 text-sm">{o.discount}%</span>
                </div>
              </div>
              <div className="flex items-center justify-between pt-2 border-t border-orange-100">
                <button
    onClick={() => toggleOffer(o.id)}
    className={`flex items-center gap-1.5 px-3 py-1 rounded-lg text-xs transition-colors ${o.active ? "bg-green-100 text-green-700 hover:bg-green-200" : "bg-gray-200 text-gray-500 hover:bg-gray-300"}`}
  >
                  <div className={`w-1.5 h-1.5 rounded-full ${o.active ? "bg-green-500" : "bg-gray-400"}`} />
                  {o.active ? "\u0646\u0634\u0637" : "\u0645\u0639\u0637\u0651\u0644"}
                </button>
                <button onClick={() => removeOffer(o.id)} className="p-1.5 hover:bg-red-50 rounded-lg group">
                  <Trash2 className="w-3.5 h-3.5 text-gray-400 group-hover:text-red-500" />
                </button>
              </div>
            </div>)}

          {showForm ? <div className="bg-gray-50 border-2 border-dashed border-orange-300 rounded-2xl p-4 space-y-3">
              <p className="text-sm text-secondary flex items-center gap-1.5"><Gift className="w-4 h-4 text-orange-500" />عرض جديد</p>
              <input
    value={newOffer.title}
    onChange={(e) => setNewOffer((p) => ({ ...p, title: e.target.value }))}
    placeholder="اسم العرض"
    className="w-full border-2 border-border rounded-xl px-3 py-2.5 text-sm outline-none focus:border-orange-400"
  />
              <div className="grid grid-cols-2 gap-3">
                <div className="relative">
                  <input
    type="number"
    min="1"
    max="100"
    value={newOffer.discount}
    onChange={(e) => setNewOffer((p) => ({ ...p, discount: e.target.value }))}
    placeholder="نسبة الخصم"
    className="w-full border-2 border-border rounded-xl px-3 py-2.5 pl-7 text-sm outline-none focus:border-orange-400"
  />
                  <Percent className="absolute left-2 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
                </div>
                <select
    value={newOffer.courtId}
    onChange={(e) => setNewOffer((p) => ({ ...p, courtId: e.target.value }))}
    className="w-full border-2 border-border rounded-xl px-3 py-2.5 text-sm outline-none focus:border-orange-400 bg-white"
  >
                  <option value="all">جميع الملاعب</option>
                  {courtNames.map((n) => <option key={n} value={n}>{n}</option>)}
                </select>
              </div>
              <input
    value={newOffer.period}
    onChange={(e) => setNewOffer((p) => ({ ...p, period: e.target.value }))}
    placeholder="الفترة (مثال: مسائي 5م – 11م) — اختياري"
    className="w-full border-2 border-border rounded-xl px-3 py-2.5 text-sm outline-none focus:border-orange-400"
  />
              <div>
                <label className="text-xs text-muted-foreground block mb-1">تاريخ الانتهاء</label>
                <input
    type="date"
    value={newOffer.expiryDate}
    onChange={(e) => setNewOffer((p) => ({ ...p, expiryDate: e.target.value }))}
    className="w-full border-2 border-border rounded-xl px-3 py-2.5 text-sm outline-none focus:border-orange-400"
  />
              </div>
              <div className="flex gap-3">
                <button onClick={() => setShowForm(false)} className="flex-1 py-2.5 border-2 border-border text-secondary rounded-xl text-sm hover:bg-gray-100 transition-colors">إلغاء</button>
                <button
    onClick={addOffer}
    disabled={!newOffer.title || !newOffer.discount}
    className="flex-1 py-2.5 bg-orange-500 text-white rounded-xl text-sm hover:bg-orange-600 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
  >
                  إضافة العرض
                </button>
              </div>
            </div> : <button
    onClick={() => setShowForm(true)}
    className="w-full py-3 border-2 border-dashed border-orange-300 text-orange-500 text-sm rounded-2xl hover:bg-orange-50 flex items-center justify-center gap-2 transition-colors"
  >
              <Plus className="w-4 h-4" />إضافة عرض أو خصم
            </button>}
        </div>}
    </div>;
}
function CoachOffersSection() {
  const [expanded, setExpanded] = useState(false);
  const [showAddForm, setShowAddForm] = useState(false);
  const [offers, setOffers] = useState([
    { id: "o1", title: "\u062E\u0635\u0645 \u0627\u0644\u062D\u062C\u0632 \u0627\u0644\u0623\u0648\u0644", discount: 30, type: "individual", active: true, expiryDate: "2026-07-01" },
    { id: "o2", title: "\u0628\u0627\u0642\u0629 \u0627\u0644\u062D\u0635\u0635 \u0627\u0644\u062C\u0645\u0627\u0639\u064A\u0629", discount: 20, type: "group", active: true, expiryDate: "2026-06-30" }
  ]);
  const [newOffer, setNewOffer] = useState({ title: "", discount: "", type: "individual", expiryDate: "" });
  const typeLabel = (t) => t === "individual" ? "\u0641\u0631\u062F\u064A\u0629" : t === "group" ? "\u062C\u0645\u0627\u0639\u064A\u0629" : "\u0628\u0627\u0642\u0629";
  const typeColor = (t) => t === "individual" ? "bg-blue-100 text-blue-700" : t === "group" ? "bg-green-100 text-green-700" : "bg-purple-100 text-purple-700";
  const handleAdd = () => {
    if (!newOffer.title || !newOffer.discount) return;
    setOffers((prev) => [...prev, {
      id: `o${Date.now()}`,
      title: newOffer.title,
      discount: parseInt(newOffer.discount),
      type: newOffer.type,
      active: true,
      expiryDate: newOffer.expiryDate || "2026-12-31"
    }]);
    setNewOffer({ title: "", discount: "", type: "individual", expiryDate: "" });
    setShowAddForm(false);
  };
  const toggleActive = (id) => setOffers((prev) => prev.map((o) => o.id === id ? { ...o, active: !o.active } : o));
  const removeOffer = (id) => setOffers((prev) => prev.filter((o) => o.id !== id));
  return <div className="bg-white border border-border rounded-2xl overflow-hidden shadow-sm">
      <button
    onClick={() => setExpanded(!expanded)}
    className="w-full flex items-center justify-between px-5 py-4 hover:bg-gray-50 transition-colors"
  >
        <div className="flex items-center gap-2">
          <Tag className="w-5 h-5 text-orange-500" />
          <h2 className="text-lg text-secondary">العروض والخصومات</h2>
          <span className="px-2 py-0.5 bg-orange-100 text-orange-600 text-xs rounded-full">
            {offers.filter((o) => o.active).length} نشطة
          </span>
        </div>
        {expanded ? <ChevronUp className="w-5 h-5 text-muted-foreground" /> : <ChevronDown className="w-5 h-5 text-muted-foreground" />}
      </button>

      {expanded && <div className="px-5 pb-5 space-y-4 border-t border-border pt-4">

          {
    /* قائمة العروض */
  }
          <div className="space-y-3">
            {offers.length === 0 && <p className="text-sm text-muted-foreground text-center py-3">لا توجد عروض حالياً</p>}
            {offers.map((offer) => <div key={offer.id} className={`rounded-xl border-2 p-4 transition-all ${offer.active ? "border-orange-200 bg-orange-50" : "border-border bg-gray-50 opacity-60"}`}>
                <div className="flex items-start justify-between gap-2 mb-2">
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 mb-1 flex-wrap">
                      <p className="text-sm text-secondary">{offer.title}</p>
                      <span className={`text-[10px] px-1.5 py-0.5 rounded-full ${typeColor(offer.type)}`}>
                        {typeLabel(offer.type)}
                      </span>
                    </div>
                    <p className="text-xs text-muted-foreground">تنتهي: {offer.expiryDate}</p>
                  </div>
                  <div className="flex items-center gap-2 flex-shrink-0">
                    <div className="flex items-center gap-1 bg-white border-2 border-orange-300 rounded-xl px-3 py-1.5">
                      <Percent className="w-3.5 h-3.5 text-orange-500" />
                      <span className="text-orange-600 text-sm">{offer.discount}%</span>
                    </div>
                  </div>
                </div>
                <div className="flex items-center justify-between pt-2 border-t border-orange-200/60">
                  <button
    onClick={() => toggleActive(offer.id)}
    className={`flex items-center gap-1.5 px-3 py-1 rounded-lg text-xs transition-colors ${offer.active ? "bg-green-100 text-green-700 hover:bg-green-200" : "bg-gray-200 text-gray-500 hover:bg-gray-300"}`}
  >
                    <div className={`w-2 h-2 rounded-full ${offer.active ? "bg-green-500" : "bg-gray-400"}`} />
                    {offer.active ? "\u0646\u0634\u0637" : "\u0645\u0639\u0637\u0651\u0644"}
                  </button>
                  <button
    onClick={() => removeOffer(offer.id)}
    className="p-1.5 hover:bg-red-50 rounded-lg transition-colors group"
  >
                    <Trash2 className="w-4 h-4 text-gray-400 group-hover:text-red-500 transition-colors" />
                  </button>
                </div>
              </div>)}
          </div>

          {
    /* نموذج إضافة عرض */
  }
          {showAddForm ? <div className="bg-gray-50 border-2 border-dashed border-orange-300 rounded-xl p-4 space-y-3">
              <p className="text-sm text-secondary flex items-center gap-1.5">
                <Gift className="w-4 h-4 text-orange-500" />
                إضافة عرض جديد
              </p>
              <input
    type="text"
    placeholder="عنوان العرض"
    value={newOffer.title}
    onChange={(e) => setNewOffer((p) => ({ ...p, title: e.target.value }))}
    className="w-full border-2 border-border rounded-xl px-4 py-2.5 text-sm text-secondary outline-none focus:border-orange-400"
  />
              <div className="grid grid-cols-2 gap-3">
                <div className="relative">
                  <input
    type="number"
    placeholder="نسبة الخصم"
    min="1"
    max="100"
    value={newOffer.discount}
    onChange={(e) => setNewOffer((p) => ({ ...p, discount: e.target.value }))}
    className="w-full border-2 border-border rounded-xl px-4 py-2.5 pl-8 text-sm text-secondary outline-none focus:border-orange-400"
  />
                  <Percent className="absolute left-2.5 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
                </div>
                <select
    value={newOffer.type}
    onChange={(e) => setNewOffer((p) => ({ ...p, type: e.target.value }))}
    className="w-full border-2 border-border rounded-xl px-3 py-2.5 text-sm text-secondary outline-none focus:border-orange-400 bg-white"
  >
                  <option value="individual">حصة فردية</option>
                  <option value="group">حصة جماعية</option>
                  <option value="package">باقة حصص</option>
                </select>
              </div>
              <div>
                <label className="text-xs text-muted-foreground block mb-1">تاريخ انتهاء العرض</label>
                <input
    type="date"
    value={newOffer.expiryDate}
    onChange={(e) => setNewOffer((p) => ({ ...p, expiryDate: e.target.value }))}
    className="w-full border-2 border-border rounded-xl px-4 py-2.5 text-sm text-secondary outline-none focus:border-orange-400"
  />
              </div>
              <div className="flex gap-3">
                <button
    onClick={() => setShowAddForm(false)}
    className="flex-1 py-2.5 border-2 border-border text-secondary rounded-xl text-sm hover:bg-gray-100 transition-colors"
  >
                  إلغاء
                </button>
                <button
    onClick={handleAdd}
    disabled={!newOffer.title || !newOffer.discount}
    className="flex-1 py-2.5 bg-orange-500 text-white rounded-xl text-sm hover:bg-orange-600 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
  >
                  إضافة العرض
                </button>
              </div>
            </div> : <button
    onClick={() => setShowAddForm(true)}
    className="w-full py-3 border-2 border-dashed border-orange-300 text-orange-500 text-sm rounded-xl hover:bg-orange-50 flex items-center justify-center gap-2 transition-colors"
  >
              <Plus className="w-4 h-4" />
              إضافة عرض أو خصم جديد
            </button>}
        </div>}
    </div>;
}
function ProfilePage({ onBack, onLogout, activeRole }) {
  const [currentView, setCurrentView] = useState(() => {
    if (activeRole) {
      const saved = localStorage.getItem("userRoles");
      const roles = saved ? JSON.parse(saved) : [];
      const roleObj = roles.find((r) => r.type === activeRole);
      if (roleObj?.completed) {
        if (activeRole === "player") return "player-dashboard";
        if (activeRole === "coach") return "coach-dashboard";
        if (activeRole === "venue") return "venue-dashboard";
      } else if (roleObj) {
        if (activeRole === "player") return "player-complete";
        if (activeRole === "coach") return "coach-complete";
        if (activeRole === "venue") return "venue-complete";
      }
    }
    return "roles";
  });
  const [showAddRoleMenu, setShowAddRoleMenu] = useState(false);
  const [showDeleteWarning, setShowDeleteWarning] = useState(false);
  const [roleToDelete, setRoleToDelete] = useState(null);
  const [revPeriodType, setRevPeriodType] = useState("month");
  const [revSelectedMonth, setRevSelectedMonth] = useState("jun");
  const [revSelectedWeek, setRevSelectedWeek] = useState("w1");
  const [revShowPeriodPicker, setRevShowPeriodPicker] = useState(false);
  const [coachRevPeriodType, setCoachRevPeriodType] = useState("month");
  const [coachRevSelectedMonth, setCoachRevSelectedMonth] = useState("jun");
  const [coachRevSelectedWeek, setCoachRevSelectedWeek] = useState("w1");
  const [coachRevShowPeriodPicker, setCoachRevShowPeriodPicker] = useState(false);
  const [traineeSearchQuery, setTraineeSearchQuery] = useState("");
  const [traineeStatusFilter, setTraineeStatusFilter] = useState("\u0627\u0644\u0643\u0644");
  const [selectedTrainee, setSelectedTrainee] = useState(null);
  const [withdrawAmount, setWithdrawAmount] = useState("");
  const [withdrawSelectedMethod, setWithdrawSelectedMethod] = useState("b1");
  const [withdrawStep, setWithdrawStep] = useState("form");
  const [ibanInput, setIbanInput] = useState("");
  const [showAddBank, setShowAddBank] = useState(false);
  const [userRoles, setUserRoles] = useState(() => {
    const saved = localStorage.getItem("userRoles");
    if (saved) {
      return JSON.parse(saved);
    }
    return [{ type: "player", completed: false }];
  });
  const getRoleName = (role) => {
    switch (role) {
      case "player":
        return "\u0644\u0627\u0639\u0628";
      case "coach":
        return "\u0645\u062F\u0631\u0628";
      case "venue":
        return "\u0645\u0644\u0639\u0628";
    }
  };
  const userName = "\u0623\u062D\u0645\u062F \u0627\u0644\u0633\u0639\u064A\u062F";
  const handleAddRole = (role) => {
    if (!userRoles.find((r) => r.type === role)) {
      const updatedRoles = [...userRoles, { type: role, completed: false }];
      setUserRoles(updatedRoles);
      localStorage.setItem("userRoles", JSON.stringify(updatedRoles));
    }
    setShowAddRoleMenu(false);
  };
  const handleDeleteRole = (role) => {
    setRoleToDelete(role);
    setShowDeleteWarning(true);
  };
  const confirmDelete = () => {
    if (roleToDelete) {
      const updatedRoles = userRoles.filter((r) => r.type !== roleToDelete);
      setUserRoles(updatedRoles);
      localStorage.setItem("userRoles", JSON.stringify(updatedRoles));
    }
    setShowDeleteWarning(false);
    setRoleToDelete(null);
  };
  const cancelDelete = () => {
    setShowDeleteWarning(false);
    setRoleToDelete(null);
  };
  const handleRoleClick = (role) => {
    const userRole = userRoles.find((r) => r.type === role);
    if (!userRole) return;
    if (role === "player") {
      setCurrentView(userRole.completed ? "player-dashboard" : "player-complete");
    } else if (role === "coach") {
      setCurrentView(userRole.completed ? "coach-dashboard" : "coach-complete");
    } else if (role === "venue") {
      setCurrentView(userRole.completed ? "venue-dashboard" : "venue-complete");
    }
  };
  const handleCompleteRole = (roleType) => {
    const updatedRoles = userRoles.map(
      (r) => r.type === roleType ? { ...r, completed: true } : r
    );
    setUserRoles(updatedRoles);
    localStorage.setItem("userRoles", JSON.stringify(updatedRoles));
    if (roleType === "player") {
      setCurrentView("player-dashboard");
    } else if (roleType === "coach") {
      setCurrentView("coach-dashboard");
    } else if (roleType === "venue") {
      setCurrentView("venue-dashboard");
    }
  };
  const availableRolesToAdd = ["player", "coach", "venue"].filter(
    (role) => !userRoles.find((r) => r.type === role)
  );
  if (currentView === "player-complete") {
    return <PlayerProfileCompletion
      onComplete={() => handleCompleteRole("player")}
      onBack={() => setCurrentView("roles")}
    />;
  }
  if (currentView === "coach-complete") {
    return <CoachProfileCompletion
      onComplete={() => handleCompleteRole("coach")}
      onBack={() => setCurrentView("roles")}
    />;
  }
  if (currentView === "venue-complete") {
    return <VenueProfileCompletion
      onComplete={() => handleCompleteRole("venue")}
      onBack={() => setCurrentView("roles")}
    />;
  }
  if (currentView === "player-dashboard") {
    return <div className="flex-1 overflow-y-auto bg-background">
        <div className="bg-gradient-to-br from-secondary to-secondary/90 text-white px-6 pt-8 pb-6">
          <div className="flex justify-center items-start mb-6">
            <div className="text-center">
              <h1 className="text-xl">صفحتي</h1>
              <p className="text-xs text-white/70 mt-1">اللاعب {userName.split(" ")[0]}</p>
            </div>
          </div>

          <div className="bg-white/95 backdrop-blur-sm rounded-2xl p-4 shadow-lg">
            <div className="flex items-center justify-between mb-3">
              <div className="flex items-center gap-3">
                <div className="w-14 h-14 bg-gradient-to-br from-primary to-primary/80 rounded-full flex items-center justify-center">
                  <span className="text-white text-xl">4.5</span>
                </div>
                <div>
                  <p className="text-sm text-gray-600">مستواك الحالي</p>
                  <p className="text-lg text-secondary">متقدم</p>
                </div>
              </div>
              <div className="text-left">
                <p className="text-sm text-gray-600">نقاط ELO</p>
                <p className="text-lg text-secondary">1845</p>
              </div>
            </div>
            <div className="h-2 bg-gray-200 rounded-full overflow-hidden">
              <div className="h-full bg-gradient-to-r from-primary to-primary/80 rounded-full" style={{ width: "65%" }} />
            </div>
            <p className="text-xs text-gray-500 mt-2 text-center">350 نقطة للمستوى التالي</p>
          </div>
        </div>

        <div className="px-6 py-6 space-y-5">
          {
      /* الإحصائيات الرئيسية */
    }
          <div className="bg-white border border-border rounded-2xl p-5 shadow-sm">
            <h2 className="text-lg text-secondary mb-4 flex items-center gap-2">
              <Trophy className="w-5 h-5 text-primary" />
              إحصائياتي
            </h2>
            <div className="space-y-3">
              <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                <p className="text-sm text-muted-foreground">المباريات التي لعبتها</p>
                <p className="text-lg text-secondary font-medium">42</p>
              </div>
              <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                <p className="text-sm text-muted-foreground">نسبة الفوز</p>
                <p className="text-lg text-green-600 font-medium">68%</p>
              </div>
              <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                <p className="text-sm text-muted-foreground">ترتيبك في التطبيق</p>
                <p className="text-lg text-primary font-medium">#123</p>
              </div>
              <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                <p className="text-sm text-muted-foreground">ترتيبك على مستوى مدينة الرياض</p>
                <p className="text-lg text-primary font-medium">#18</p>
              </div>
              <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                <p className="text-sm text-muted-foreground">ساعات اللعب</p>
                <p className="text-lg text-secondary font-medium">87</p>
              </div>
            </div>

            {
      /* إحصائيات اللاعبين */
    }
            <div className="mt-4 pt-4 border-t border-border space-y-3">
              <p className="text-xs text-muted-foreground mb-2">إحصائيات اللاعبين</p>

              {
      /* أكثر لاعب فاز عليك */
    }
              <div className="flex items-center gap-3 p-3 bg-red-50 border border-red-100 rounded-xl">
                <div className="w-10 h-10 bg-gradient-to-br from-red-500 to-red-600 rounded-full flex items-center justify-center flex-shrink-0">
                  <span className="text-white text-sm">خ</span>
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-xs text-muted-foreground">أكثر لاعب فاز عليك</p>
                  <p className="text-sm text-secondary">خالد المطيري</p>
                </div>
                <div className="text-left flex-shrink-0">
                  <p className="text-sm text-red-600">8 مرات</p>
                </div>
              </div>

              {
      /* أكثر لاعب فزت عليه */
    }
              <div className="flex items-center gap-3 p-3 bg-green-50 border border-green-100 rounded-xl">
                <div className="w-10 h-10 bg-gradient-to-br from-green-500 to-green-600 rounded-full flex items-center justify-center flex-shrink-0">
                  <span className="text-white text-sm">ف</span>
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-xs text-muted-foreground">أكثر لاعب فزت عليه</p>
                  <p className="text-sm text-secondary">فهد العتيبي</p>
                </div>
                <div className="text-left flex-shrink-0">
                  <p className="text-sm text-green-600">11 مرات</p>
                </div>
              </div>

              {
      /* أكثر لاعب لعبت معه */
    }
              <div className="flex items-center gap-3 p-3 bg-blue-50 border border-blue-100 rounded-xl">
                <div className="w-10 h-10 bg-gradient-to-br from-blue-500 to-blue-600 rounded-full flex items-center justify-center flex-shrink-0">
                  <span className="text-white text-sm">س</span>
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-xs text-muted-foreground">أكثر لاعب لعبت معه</p>
                  <p className="text-sm text-secondary">سعود القحطاني</p>
                </div>
                <div className="text-left flex-shrink-0">
                  <p className="text-sm text-blue-600">15 مباراة</p>
                </div>
              </div>

              {
      /* أكثر لاعب لعبت ضده */
    }
              <div className="flex items-center gap-3 p-3 bg-orange-50 border border-orange-100 rounded-xl">
                <div className="w-10 h-10 bg-gradient-to-br from-orange-500 to-orange-600 rounded-full flex items-center justify-center flex-shrink-0">
                  <span className="text-white text-sm">م</span>
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-xs text-muted-foreground">أكثر لاعب لعبت ضده</p>
                  <p className="text-sm text-secondary">محمد الشمري</p>
                </div>
                <div className="text-left flex-shrink-0">
                  <p className="text-sm text-orange-600">12 مباراة</p>
                </div>
              </div>
            </div>
          </div>

          {
      /* الحجوزات الحالية */
    }
          <div className="bg-white border border-border rounded-2xl p-5 shadow-sm">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg text-secondary flex items-center gap-2">
                <Calendar className="w-5 h-5 text-primary" />
                حجوزاتي الحالية
              </h2>
              <span className="px-3 py-1 bg-primary/10 text-primary text-xs rounded-full">3 حجوزات</span>
            </div>
            <div className="space-y-3">
              {
      /* حجز 1 */
    }
              <div className="p-4 bg-gradient-to-br from-primary/5 to-primary/10 border-2 border-primary/30 rounded-xl">
                <div className="flex items-start justify-between mb-3">
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-2">
                      <MapPin className="w-4 h-4 text-primary" />
                      <p className="text-sm text-secondary font-medium">نادي البادل الملكي</p>
                    </div>
                    <p className="text-xs text-muted-foreground mr-6">الملعب رقم 3 • الدمام</p>
                  </div>
                  <span className="px-2 py-1 bg-green-100 text-green-600 text-xs rounded-full whitespace-nowrap">مؤكدة</span>
                </div>
                <div className="flex items-center justify-between pt-3 border-t border-primary/20">
                  <div className="flex items-center gap-4 text-xs text-muted-foreground">
                    <div className="flex items-center gap-1">
                      <Calendar className="w-3 h-3" />
                      <span>اليوم</span>
                    </div>
                    <div className="flex items-center gap-1">
                      <Clock className="w-3 h-3" />
                      <span>6:00 مساءً</span>
                    </div>
                    <div className="flex items-center gap-1">
                      <Users className="w-3 h-3" />
                      <span>90 دقيقة</span>
                    </div>
                  </div>
                  <p className="text-sm text-primary font-medium">150 ر.س</p>
                </div>
              </div>

              {
      /* حجز 2 */
    }
              <div className="p-4 bg-gray-50 border border-border rounded-xl">
                <div className="flex items-start justify-between mb-3">
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-2">
                      <MapPin className="w-4 h-4 text-primary" />
                      <p className="text-sm text-secondary font-medium">بادل كلوب الشرقية</p>
                    </div>
                    <p className="text-xs text-muted-foreground mr-6">الملعب رقم 1 • الخبر</p>
                  </div>
                  <span className="px-2 py-1 bg-green-100 text-green-600 text-xs rounded-full whitespace-nowrap">مؤكدة</span>
                </div>
                <div className="flex items-center justify-between pt-3 border-t border-border">
                  <div className="flex items-center gap-4 text-xs text-muted-foreground">
                    <div className="flex items-center gap-1">
                      <Calendar className="w-3 h-3" />
                      <span>غداً</span>
                    </div>
                    <div className="flex items-center gap-1">
                      <Clock className="w-3 h-3" />
                      <span>5:00 مساءً</span>
                    </div>
                    <div className="flex items-center gap-1">
                      <Users className="w-3 h-3" />
                      <span>60 دقيقة</span>
                    </div>
                  </div>
                  <p className="text-sm text-secondary font-medium">80 ر.س</p>
                </div>
              </div>

              {
      /* حجز 3 */
    }
              <div className="p-4 bg-gray-50 border border-border rounded-xl">
                <div className="flex items-start justify-between mb-3">
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-2">
                      <MapPin className="w-4 h-4 text-primary" />
                      <p className="text-sm text-secondary font-medium">مركز بادل المدينة</p>
                    </div>
                    <p className="text-xs text-muted-foreground mr-6">الملعب رقم 5 • الدمام</p>
                  </div>
                  <span className="px-2 py-1 bg-green-100 text-green-600 text-xs rounded-full whitespace-nowrap">مؤكدة</span>
                </div>
                <div className="flex items-center justify-between pt-3 border-t border-border">
                  <div className="flex items-center gap-4 text-xs text-muted-foreground">
                    <div className="flex items-center gap-1">
                      <Calendar className="w-3 h-3" />
                      <span>الجمعة، 4 يونيو</span>
                    </div>
                    <div className="flex items-center gap-1">
                      <Clock className="w-3 h-3" />
                      <span>7:30 مساءً</span>
                    </div>
                    <div className="flex items-center gap-1">
                      <Users className="w-3 h-3" />
                      <span>120 دقيقة</span>
                    </div>
                  </div>
                  <p className="text-sm text-secondary font-medium">200 ر.س</p>
                </div>
              </div>
            </div>
          </div>

          {
      /* المباريات القادمة */
    }
          <div className="bg-white border border-border rounded-2xl p-5 shadow-sm">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg text-secondary flex items-center gap-2">
                <Trophy className="w-5 h-5 text-primary" />
                مبارياتي القادمة
              </h2>
              <span className="px-3 py-1 bg-green-100 text-green-600 text-xs rounded-full">2 مباريات</span>
            </div>
            <div className="space-y-3">
              {
      /* مباراة 1 */
    }
              <div className="p-4 bg-gradient-to-br from-green-50 to-green-100/50 border-2 border-green-200 rounded-xl">
                <div className="flex items-start justify-between mb-3">
                  <div>
                    <div className="flex items-center gap-2 mb-2">
                      <span className="px-2 py-1 bg-green-500 text-white text-xs rounded-full">أمريكانو فرق</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <MapPin className="w-4 h-4 text-green-600" />
                      <p className="text-sm text-secondary font-medium">نادي البادل الملكي</p>
                    </div>
                  </div>
                </div>
                <div className="flex items-center justify-between pt-3 border-t border-green-200">
                  <div className="flex items-center gap-4 text-xs text-muted-foreground">
                    <div className="flex items-center gap-1">
                      <Calendar className="w-3 h-3" />
                      <span>السبت، 5 يونيو</span>
                    </div>
                    <div className="flex items-center gap-1">
                      <Clock className="w-3 h-3" />
                      <span>4:00 مساءً</span>
                    </div>
                    <div className="flex items-center gap-1">
                      <Users className="w-3 h-3" />
                      <span>10/12 لاعب</span>
                    </div>
                  </div>
                </div>
              </div>

              {
      /* مباراة 2 */
    }
              <div className="p-4 bg-gray-50 border border-border rounded-xl">
                <div className="flex items-start justify-between mb-3">
                  <div>
                    <div className="flex items-center gap-2 mb-2">
                      <span className="px-2 py-1 bg-blue-100 text-blue-600 text-xs rounded-full">ودية فردي</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <MapPin className="w-4 h-4 text-primary" />
                      <p className="text-sm text-secondary font-medium">ملعب الأندية الشرقية</p>
                    </div>
                  </div>
                </div>
                <div className="flex items-center justify-between pt-3 border-t border-border">
                  <div className="flex items-center gap-4 text-xs text-muted-foreground">
                    <div className="flex items-center gap-1">
                      <Calendar className="w-3 h-3" />
                      <span>الأحد، 6 يونيو</span>
                    </div>
                    <div className="flex items-center gap-1">
                      <Clock className="w-3 h-3" />
                      <span>6:30 مساءً</span>
                    </div>
                    <div className="flex items-center gap-1">
                      <Users className="w-3 h-3" />
                      <span>3/4 لاعبين</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {
      /* السجل الأخير */
    }
          <div className="bg-white border border-border rounded-2xl p-5 shadow-sm">
            <h2 className="text-lg text-secondary mb-4 flex items-center gap-2">
              <TrendingUp className="w-5 h-5 text-primary" />
              آخر النتائج
            </h2>
            <div className="space-y-2">
              <div className="flex items-center justify-between p-3 bg-green-50 border border-green-200 rounded-lg">
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 bg-green-500 rounded-full flex items-center justify-center">
                    <span className="text-white text-xs font-bold">W</span>
                  </div>
                  <div>
                    <p className="text-sm text-secondary">فوز 6-4, 6-3</p>
                    <p className="text-xs text-muted-foreground">أمس، نادي البادل</p>
                  </div>
                </div>
                <span className="text-xs text-green-600 font-medium">+15</span>
              </div>
              <div className="flex items-center justify-between p-3 bg-green-50 border border-green-200 rounded-lg">
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 bg-green-500 rounded-full flex items-center justify-center">
                    <span className="text-white text-xs font-bold">W</span>
                  </div>
                  <div>
                    <p className="text-sm text-secondary">فوز 7-5, 6-2</p>
                    <p className="text-xs text-muted-foreground">منذ يومين، بادل كلوب</p>
                  </div>
                </div>
                <span className="text-xs text-green-600 font-medium">+12</span>
              </div>
              <div className="flex items-center justify-between p-3 bg-red-50 border border-red-200 rounded-lg">
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 bg-red-500 rounded-full flex items-center justify-center">
                    <span className="text-white text-xs font-bold">L</span>
                  </div>
                  <div>
                    <p className="text-sm text-secondary">خسارة 4-6, 3-6</p>
                    <p className="text-xs text-muted-foreground">منذ 3 أيام، مركز المدينة</p>
                  </div>
                </div>
                <span className="text-xs text-red-600 font-medium">-8</span>
              </div>
            </div>
          </div>

          {
      /* الإشعارات */
    }
          <PlayerNotificationsSection />

          {
      /* قائمة الأصدقاء */
    }
          <div className="bg-white border border-border rounded-2xl p-5 shadow-sm">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg text-secondary flex items-center gap-2">
                <UserCheck className="w-5 h-5 text-primary" />
                قائمة الأصدقاء
              </h2>
              <span className="text-sm text-muted-foreground">42 صديق</span>
            </div>
            <div className="space-y-3">
              <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors">
                <div className="flex items-center gap-3 flex-1">
                  <div className="w-10 h-10 bg-gradient-to-br from-primary to-primary/80 rounded-full flex items-center justify-center">
                    <span className="text-white text-sm">م</span>
                  </div>
                  <div>
                    <p className="text-sm text-secondary font-medium">محمد أحمد</p>
                    <p className="text-xs text-muted-foreground">مستوى 4.5</p>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <button className="p-2 hover:bg-red-50 rounded-lg transition-colors group">
                    <Trash2 className="w-4 h-4 text-gray-400 group-hover:text-red-500 transition-colors" />
                  </button>
                  <button className="p-2 hover:bg-pink-50 rounded-lg transition-colors group">
                    <Heart className="w-4 h-4 text-gray-400 group-hover:text-pink-500 group-hover:fill-pink-500 transition-colors" />
                  </button>
                  <ChevronLeft className="w-5 h-5 text-muted-foreground" />
                </div>
              </div>
              <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors">
                <div className="flex items-center gap-3 flex-1">
                  <div className="w-10 h-10 bg-gradient-to-br from-green-500 to-green-600 rounded-full flex items-center justify-center">
                    <span className="text-white text-sm">ع</span>
                  </div>
                  <div>
                    <p className="text-sm text-secondary font-medium">عبدالله سعد</p>
                    <p className="text-xs text-muted-foreground">مستوى 5.0</p>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <button className="p-2 hover:bg-red-50 rounded-lg transition-colors group">
                    <Trash2 className="w-4 h-4 text-gray-400 group-hover:text-red-500 transition-colors" />
                  </button>
                  <button className="p-2 hover:bg-pink-50 rounded-lg transition-colors group">
                    <Heart className="w-4 h-4 text-gray-400 group-hover:text-pink-500 group-hover:fill-pink-500 transition-colors" />
                  </button>
                  <ChevronLeft className="w-5 h-5 text-muted-foreground" />
                </div>
              </div>
              <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors">
                <div className="flex items-center gap-3 flex-1">
                  <div className="w-10 h-10 bg-gradient-to-br from-blue-500 to-blue-600 rounded-full flex items-center justify-center">
                    <span className="text-white text-sm">خ</span>
                  </div>
                  <div>
                    <p className="text-sm text-secondary font-medium">خالد المطيري</p>
                    <p className="text-xs text-muted-foreground">مستوى 4.0</p>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <button className="p-2 hover:bg-red-50 rounded-lg transition-colors group">
                    <Trash2 className="w-4 h-4 text-gray-400 group-hover:text-red-500 transition-colors" />
                  </button>
                  <button className="p-2 hover:bg-pink-50 rounded-lg transition-colors group">
                    <Heart className="w-4 h-4 text-gray-400 group-hover:text-pink-500 group-hover:fill-pink-500 transition-colors" />
                  </button>
                  <ChevronLeft className="w-5 h-5 text-muted-foreground" />
                </div>
              </div>
            </div>
            <button className="w-full mt-3 py-2 text-sm text-primary hover:text-primary/80 transition-colors">
              عرض جميع الأصدقاء
            </button>
          </div>

          {
      /* القائمة المفضلة */
    }
          <div className="bg-white border border-border rounded-2xl p-5 shadow-sm">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg text-secondary flex items-center gap-2">
                <Star className="w-5 h-5 text-yellow-500 fill-yellow-500" />
                القائمة المفضلة
              </h2>
              <span className="text-sm text-muted-foreground">8 مفضلين</span>
            </div>
            <div className="space-y-3">
              <div className="flex items-center justify-between p-3 bg-gradient-to-br from-yellow-50 to-yellow-100/50 border border-yellow-200 rounded-lg">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-gradient-to-br from-yellow-500 to-yellow-600 rounded-full flex items-center justify-center">
                    <span className="text-white text-sm">س</span>
                  </div>
                  <div>
                    <p className="text-sm text-secondary font-medium">سعود القحطاني</p>
                    <p className="text-xs text-muted-foreground">مستوى 5.5 • شريكك المفضل</p>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <button className="p-2 hover:bg-red-50 rounded-lg transition-colors group">
                    <Trash2 className="w-4 h-4 text-gray-400 group-hover:text-red-500 transition-colors" />
                  </button>
                  <ChevronLeft className="w-5 h-5 text-muted-foreground" />
                </div>
              </div>
              <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-gradient-to-br from-orange-500 to-orange-600 rounded-full flex items-center justify-center">
                    <span className="text-white text-sm">ن</span>
                  </div>
                  <div>
                    <p className="text-sm text-secondary font-medium">ناصر العمري</p>
                    <p className="text-xs text-muted-foreground">مستوى 4.5</p>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <button className="p-2 hover:bg-red-50 rounded-lg transition-colors group">
                    <Trash2 className="w-4 h-4 text-gray-400 group-hover:text-red-500 transition-colors" />
                  </button>
                  <ChevronLeft className="w-5 h-5 text-muted-foreground" />
                </div>
              </div>
            </div>
            <button className="w-full mt-3 py-2 text-sm text-primary hover:text-primary/80 transition-colors">
              عرض جميع المفضلين
            </button>
          </div>

          {
      /* المحفظة */
    }
          <div className="bg-white border border-border rounded-2xl p-5 shadow-sm">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg text-secondary flex items-center gap-2">
                <Wallet className="w-5 h-5 text-primary" />
                المحفظة
              </h2>
            </div>
            <div className="bg-gradient-to-br from-primary/5 to-primary/10 rounded-xl p-4 mb-4">
              <p className="text-sm text-muted-foreground mb-1">الرصيد المتاح</p>
              <p className="text-3xl text-primary font-bold">250 ر.س</p>
            </div>
            <div className="grid grid-cols-2 gap-3">
              <button
      onClick={() => setCurrentView("top-up-wallet")}
      className="py-3 bg-primary text-white rounded-xl hover:bg-primary/90 transition-colors"
    >
                شحن الرصيد
              </button>
              <button onClick={() => setCurrentView("withdraw")} className="py-3 bg-white border-2 border-border text-secondary rounded-xl hover:border-primary transition-colors">
                سحب الرصيد
              </button>
            </div>
          </div>

          {
      /* الإعدادات العامة */
    }
          <div className="bg-white border border-border rounded-2xl p-4 shadow-sm">
            <h2 className="text-lg text-secondary mb-4">الإعدادات العامة</h2>
            <div className="space-y-2">
              <button onClick={() => setCurrentView("language")} className="w-full flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center"><Languages className="w-5 h-5 text-primary" /></div>
                  <div className="text-right"><p className="text-sm text-secondary">تغيير اللغة</p><p className="text-xs text-muted-foreground">العربية</p></div>
                </div>
                <ChevronLeft className="w-5 h-5 text-muted-foreground" />
              </button>
              <button onClick={() => setCurrentView("contact")} className="w-full flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center"><MessageCircle className="w-5 h-5 text-primary" /></div>
                  <div className="text-right"><p className="text-sm text-secondary">اتصل بنا</p><p className="text-xs text-muted-foreground">واتساب، إيميل، دردشة</p></div>
                </div>
                <ChevronLeft className="w-5 h-5 text-muted-foreground" />
              </button>
              <button onClick={() => setCurrentView("account-settings")} className="w-full flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center"><Settings className="w-5 h-5 text-primary" /></div>
                  <div className="text-right"><p className="text-sm text-secondary">إعدادات الحساب</p><p className="text-xs text-muted-foreground">الجوال، الإيميل، كلمة المرور</p></div>
                </div>
                <ChevronLeft className="w-5 h-5 text-muted-foreground" />
              </button>
              <button onClick={() => setCurrentView("terms")} className="w-full flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center"><FileText className="w-5 h-5 text-primary" /></div>
                  <div className="text-right"><p className="text-sm text-secondary">الشروط والأحكام</p><p className="text-xs text-muted-foreground">الشروط القانونية للاستخدام</p></div>
                </div>
                <ChevronLeft className="w-5 h-5 text-muted-foreground" />
              </button>
              <button onClick={() => setCurrentView("privacy")} className="w-full flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center"><Shield className="w-5 h-5 text-primary" /></div>
                  <div className="text-right"><p className="text-sm text-secondary">سياسة الخصوصية</p><p className="text-xs text-muted-foreground">حماية البيانات والخصوصية</p></div>
                </div>
                <ChevronLeft className="w-5 h-5 text-muted-foreground" />
              </button>
              <button onClick={() => setCurrentView("refund")} className="w-full flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center"><Wallet className="w-5 h-5 text-primary" /></div>
                  <div className="text-right"><p className="text-sm text-secondary">سياسة الاسترجاع</p><p className="text-xs text-muted-foreground">شروط استرجاع المبالغ</p></div>
                </div>
                <ChevronLeft className="w-5 h-5 text-muted-foreground" />
              </button>
              {onLogout && <button onClick={onLogout} className="w-full flex items-center justify-between p-3 bg-red-50 rounded-lg hover:bg-red-100 transition-colors border border-red-200">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 bg-red-100 rounded-full flex items-center justify-center"><LogOut className="w-5 h-5 text-red-600" /></div>
                    <div className="text-right"><p className="text-sm text-red-600">تسجيل الخروج</p><p className="text-xs text-red-500">الخروج من الحساب</p></div>
                  </div>
                  <ChevronLeft className="w-5 h-5 text-red-400" />
                </button>}
            </div>
          </div>
        </div>
      </div>;
  }
  if (currentView === "coach-dashboard") {
    return <div className="flex-1 overflow-y-auto bg-background">
        <div className="bg-gradient-to-br from-secondary to-secondary/90 text-white px-6 pt-8 pb-6">
          <div className="flex justify-center items-start mb-6">
            <div className="text-center">
              <h1 className="text-xl">صفحتي</h1>
              <p className="text-xs text-white/70 mt-1">المدرب {userName.split(" ")[0]}</p>
            </div>
          </div>

          <div className="grid grid-cols-3 gap-3">
            <div className="bg-white/10 backdrop-blur-sm rounded-xl p-3 text-center">
              <p className="text-2xl mb-1">24</p>
              <p className="text-xs text-white/80">متدرب</p>
            </div>
            <div className="bg-white/10 backdrop-blur-sm rounded-xl p-3 text-center">
              <p className="text-2xl mb-1">4.8</p>
              <p className="text-xs text-white/80">التقييم</p>
            </div>
            <div className="bg-white/10 backdrop-blur-sm rounded-xl p-3 text-center">
              <p className="text-2xl mb-1">156</p>
              <p className="text-xs text-white/80">حصة تدريبية</p>
            </div>
          </div>
        </div>

        <div className="px-6 py-6 space-y-4">
          {
      /* إدارة المتدربين والتقارير */
    }
          <button
      onClick={() => setCurrentView("coach-trainees")}
      className="w-full bg-gradient-to-r from-violet-600 to-violet-500 text-white rounded-2xl p-4 flex items-center justify-between shadow-md hover:shadow-lg transition-all"
    >
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-white/20 rounded-xl flex items-center justify-center">
                <Users className="w-5 h-5" />
              </div>
              <div className="text-right">
                <p className="text-sm">إدارة المتدربين والتقارير</p>
                <p className="text-xs text-white/70">24 متدرب نشط</p>
              </div>
            </div>
            <ChevronLeft className="w-5 h-5 text-white/80" />
          </button>

          <div className="bg-white border border-border rounded-2xl p-4 shadow-sm">
            <h2 className="text-lg text-secondary mb-4">الحصص التدريبية القادمة</h2>
            <div className="space-y-3">
              <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                <div>
                  <p className="text-sm text-secondary">حصة تدريبية فردية</p>
                  <p className="text-xs text-muted-foreground">غداً، 5:00 مساءً</p>
                </div>
                <span className="px-3 py-1 bg-primary/10 text-primary text-xs rounded-full">مؤكدة</span>
              </div>
              <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                <div>
                  <p className="text-sm text-secondary">حصة تدريبية جماعية</p>
                  <p className="text-xs text-muted-foreground">الجمعة، 7:00 مساءً</p>
                </div>
                <span className="px-3 py-1 bg-primary/10 text-primary text-xs rounded-full">مؤكدة</span>
              </div>
            </div>
          </div>

          {
      /* العروض والخصومات */
    }
          <CoachOffersSection />

          <div className="bg-white border border-border rounded-2xl p-4 shadow-sm">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg text-secondary flex items-center gap-2">
                <TrendingUp className="w-5 h-5 text-primary" />
                الإيرادات
              </h2>
              <button
      onClick={() => setCurrentView("coach-revenue")}
      className="text-xs text-primary flex items-center gap-1 hover:underline"
    >
                تفاصيل الإيرادات
                <ChevronLeft className="w-4 h-4" />
              </button>
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div className="text-center p-3 bg-gray-50 rounded-lg">
                <p className="text-xl text-secondary mb-1">3,200 ر.س</p>
                <p className="text-xs text-muted-foreground">هذا الشهر</p>
              </div>
              <div className="text-center p-3 bg-gray-50 rounded-lg">
                <p className="text-xl text-secondary mb-1">18,500 ر.س</p>
                <p className="text-xs text-muted-foreground">الإجمالي</p>
              </div>
            </div>
          </div>

          {
      /* الإشعارات */
    }
          <div className="bg-white border border-border rounded-2xl p-5 shadow-sm">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg text-secondary flex items-center gap-2">
                <Bell className="w-5 h-5 text-primary" />
                الإشعارات
              </h2>
              <span className="px-2 py-1 bg-red-500 text-white text-xs rounded-full">2</span>
            </div>
            <div className="space-y-3">
              <div className="p-3 bg-blue-50 border border-blue-200 rounded-lg">
                <div className="flex items-start gap-3">
                  <div className="w-2 h-2 bg-blue-500 rounded-full mt-2 flex-shrink-0" />
                  <div className="flex-1">
                    <p className="text-sm text-secondary mb-1">طلب حصة جديد من <span className="font-medium">سعد أحمد</span></p>
                    <p className="text-xs text-muted-foreground">منذ 10 دقائق</p>
                  </div>
                </div>
              </div>
              <div className="p-3 bg-gray-50 rounded-lg">
                <div className="flex items-start gap-3">
                  <div className="w-2 h-2 bg-gray-300 rounded-full mt-2 flex-shrink-0" />
                  <div className="flex-1">
                    <p className="text-sm text-secondary mb-1">تقييم جديد من <span className="font-medium">أحمد عبدالله</span> - 5 نجوم</p>
                    <p className="text-xs text-muted-foreground">منذ ساعتين</p>
                  </div>
                </div>
              </div>
            </div>
            <button className="w-full mt-3 py-2 text-sm text-primary hover:text-primary/80 transition-colors">
              عرض جميع الإشعارات
            </button>
          </div>

          {
      /* المحفظة */
    }
          <div className="bg-white border border-border rounded-2xl p-5 shadow-sm">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg text-secondary flex items-center gap-2">
                <Wallet className="w-5 h-5 text-primary" />
                المحفظة
              </h2>
            </div>
            <div className="bg-gradient-to-br from-primary/5 to-primary/10 rounded-xl p-4 mb-4">
              <p className="text-sm text-muted-foreground mb-1">الرصيد المتاح</p>
              <p className="text-3xl text-primary font-bold">3,200 ر.س</p>
            </div>
            <div className="grid grid-cols-2 gap-3">
              <button
      onClick={() => setCurrentView("top-up-wallet")}
      className="py-3 bg-primary text-white rounded-xl hover:bg-primary/90 transition-colors"
    >
                شحن الرصيد
              </button>
              <button onClick={() => setCurrentView("withdraw")} className="py-3 bg-white border-2 border-border text-secondary rounded-xl hover:border-primary transition-colors">
                سحب الرصيد
              </button>
            </div>
          </div>

          {
      /* الإعدادات العامة */
    }
          <div className="bg-white border border-border rounded-2xl p-4 shadow-sm">
            <h2 className="text-lg text-secondary mb-4">الإعدادات العامة</h2>
            <div className="space-y-2">
              <button onClick={() => setCurrentView("language")} className="w-full flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center"><Languages className="w-5 h-5 text-primary" /></div>
                  <div className="text-right"><p className="text-sm text-secondary">تغيير اللغة</p><p className="text-xs text-muted-foreground">العربية</p></div>
                </div>
                <ChevronLeft className="w-5 h-5 text-muted-foreground" />
              </button>
              <button onClick={() => setCurrentView("contact")} className="w-full flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center"><MessageCircle className="w-5 h-5 text-primary" /></div>
                  <div className="text-right"><p className="text-sm text-secondary">اتصل بنا</p><p className="text-xs text-muted-foreground">واتساب، إيميل، دردشة</p></div>
                </div>
                <ChevronLeft className="w-5 h-5 text-muted-foreground" />
              </button>
              <button onClick={() => setCurrentView("account-settings")} className="w-full flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center"><Settings className="w-5 h-5 text-primary" /></div>
                  <div className="text-right"><p className="text-sm text-secondary">إعدادات الحساب</p><p className="text-xs text-muted-foreground">الجوال، الإيميل، كلمة المرور</p></div>
                </div>
                <ChevronLeft className="w-5 h-5 text-muted-foreground" />
              </button>
              <button onClick={() => setCurrentView("terms")} className="w-full flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center"><FileText className="w-5 h-5 text-primary" /></div>
                  <div className="text-right"><p className="text-sm text-secondary">الشروط والأحكام</p><p className="text-xs text-muted-foreground">الشروط القانونية للاستخدام</p></div>
                </div>
                <ChevronLeft className="w-5 h-5 text-muted-foreground" />
              </button>
              <button onClick={() => setCurrentView("privacy")} className="w-full flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center"><Shield className="w-5 h-5 text-primary" /></div>
                  <div className="text-right"><p className="text-sm text-secondary">سياسة الخصوصية</p><p className="text-xs text-muted-foreground">حماية البيانات والخصوصية</p></div>
                </div>
                <ChevronLeft className="w-5 h-5 text-muted-foreground" />
              </button>
              <button onClick={() => setCurrentView("refund")} className="w-full flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center"><Wallet className="w-5 h-5 text-primary" /></div>
                  <div className="text-right"><p className="text-sm text-secondary">سياسة الاسترجاع</p><p className="text-xs text-muted-foreground">شروط استرجاع المبالغ</p></div>
                </div>
                <ChevronLeft className="w-5 h-5 text-muted-foreground" />
              </button>
              {onLogout && <button onClick={onLogout} className="w-full flex items-center justify-between p-3 bg-red-50 rounded-lg hover:bg-red-100 transition-colors border border-red-200">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 bg-red-100 rounded-full flex items-center justify-center"><LogOut className="w-5 h-5 text-red-600" /></div>
                    <div className="text-right"><p className="text-sm text-red-600">تسجيل الخروج</p><p className="text-xs text-red-500">الخروج من الحساب</p></div>
                  </div>
                  <ChevronLeft className="w-5 h-5 text-red-400" />
                </button>}
            </div>
          </div>
        </div>
      </div>;
  }
  if (currentView === "coach-revenue") {
    const CMONTHS = [
      { key: "jun", label: "\u064A\u0648\u0646\u064A\u0648 2026" },
      { key: "may", label: "\u0645\u0627\u064A\u0648 2026" },
      { key: "apr", label: "\u0623\u0628\u0631\u064A\u0644 2026" },
      { key: "mar", label: "\u0645\u0627\u0631\u0633 2026" }
    ];
    const CWEEKS = [
      { key: "w1", label: "\u0627\u0644\u0623\u0633\u0628\u0648\u0639 1 - 1-7 \u064A\u0648\u0646\u064A\u0648" },
      { key: "w2", label: "\u0627\u0644\u0623\u0633\u0628\u0648\u0639 2 - 8-14 \u064A\u0648\u0646\u064A\u0648" },
      { key: "w3", label: "\u0627\u0644\u0623\u0633\u0628\u0648\u0639 3 - 15-21 \u064A\u0648\u0646\u064A\u0648" },
      { key: "w4", label: "\u0627\u0644\u0623\u0633\u0628\u0648\u0639 4 - 22-30 \u064A\u0648\u0646\u064A\u0648" }
    ];
    const coachMonthData = {
      jun: {
        total: "3,200",
        sub: "+14% \u0639\u0646 \u0645\u0627\u064A\u0648",
        up: true,
        sessionRevenue: [
          { type: "\u062D\u0635\u0629 \u0641\u0631\u062F\u064A\u0629", total: "1,800", pct: 56, sessions: 12 },
          { type: "\u062D\u0635\u0629 \u062C\u0645\u0627\u0639\u064A\u0629", total: "900", pct: 28, sessions: 6 },
          { type: "\u0628\u0627\u0642\u0629 \u062A\u062F\u0631\u064A\u0628\u064A\u0629", total: "500", pct: 16, sessions: 3 }
        ],
        bars: [
          { label: "\u0627\u0644\u0623\u0633\u0628\u0648\u0639 1", val: 900 },
          { label: "\u0627\u0644\u0623\u0633\u0628\u0648\u0639 2", val: 1100 },
          { label: "\u0627\u0644\u0623\u0633\u0628\u0648\u0639 3", val: 700 },
          { label: "\u0627\u0644\u0623\u0633\u0628\u0648\u0639 4", val: 500 }
        ],
        txs: [
          { id: "c1", trainee: "\u0633\u0639\u062F \u0623\u062D\u0645\u062F", sessionType: "\u062D\u0635\u0629 \u0641\u0631\u062F\u064A\u0629", amount: 300, type: "\u0645\u062F\u0641\u0648\u0639\u0629", date: "6 \u064A\u0648\u0646\u064A\u0648" },
          { id: "c2", trainee: "\u0645\u062D\u0645\u062F \u0627\u0644\u0639\u0645\u0631\u064A", sessionType: "\u062D\u0635\u0629 \u062C\u0645\u0627\u0639\u064A\u0629", amount: 150, type: "\u0645\u062F\u0641\u0648\u0639\u0629", date: "5 \u064A\u0648\u0646\u064A\u0648" },
          { id: "c3", trainee: "\u0641\u064A\u0635\u0644 \u0627\u0644\u0634\u0647\u0631\u064A", sessionType: "\u062D\u0635\u0629 \u0641\u0631\u062F\u064A\u0629", amount: -300, type: "\u0625\u0644\u063A\u0627\u0621", date: "4 \u064A\u0648\u0646\u064A\u0648" },
          { id: "c4", trainee: "\u0639\u0628\u062F\u0627\u0644\u0644\u0647 \u0627\u0644\u063A\u0627\u0645\u062F\u064A", sessionType: "\u0628\u0627\u0642\u0629 \u062A\u062F\u0631\u064A\u0628\u064A\u0629", amount: 500, type: "\u0645\u062F\u0641\u0648\u0639\u0629", date: "3 \u064A\u0648\u0646\u064A\u0648" },
          { id: "c5", trainee: "\u062A\u0631\u0643\u064A \u0627\u0644\u062D\u0631\u0628\u064A", sessionType: "\u062D\u0635\u0629 \u0641\u0631\u062F\u064A\u0629", amount: 300, type: "\u0645\u062F\u0641\u0648\u0639\u0629", date: "2 \u064A\u0648\u0646\u064A\u0648" }
        ]
      },
      may: {
        total: "2,800",
        sub: "+7% \u0639\u0646 \u0623\u0628\u0631\u064A\u0644",
        up: true,
        sessionRevenue: [
          { type: "\u062D\u0635\u0629 \u0641\u0631\u062F\u064A\u0629", total: "1,500", pct: 54, sessions: 10 },
          { type: "\u062D\u0635\u0629 \u062C\u0645\u0627\u0639\u064A\u0629", total: "850", pct: 30, sessions: 5 },
          { type: "\u0628\u0627\u0642\u0629 \u062A\u062F\u0631\u064A\u0628\u064A\u0629", total: "450", pct: 16, sessions: 2 }
        ],
        bars: [
          { label: "\u0627\u0644\u0623\u0633\u0628\u0648\u0639 1", val: 700 },
          { label: "\u0627\u0644\u0623\u0633\u0628\u0648\u0639 2", val: 900 },
          { label: "\u0627\u0644\u0623\u0633\u0628\u0648\u0639 3", val: 650 },
          { label: "\u0627\u0644\u0623\u0633\u0628\u0648\u0639 4", val: 550 }
        ],
        txs: [
          { id: "m1", trainee: "\u0631\u0627\u0634\u062F \u0627\u0644\u0623\u062D\u0645\u062F\u064A", sessionType: "\u062D\u0635\u0629 \u0641\u0631\u062F\u064A\u0629", amount: 300, type: "\u0645\u062F\u0641\u0648\u0639\u0629", date: "31 \u0645\u0627\u064A\u0648" },
          { id: "m2", trainee: "\u062C\u0627\u0633\u0645 \u0627\u0644\u0634\u0645\u0631\u064A", sessionType: "\u062D\u0635\u0629 \u062C\u0645\u0627\u0639\u064A\u0629", amount: 150, type: "\u0645\u062F\u0641\u0648\u0639\u0629", date: "28 \u0645\u0627\u064A\u0648" },
          { id: "m3", trainee: "\u0648\u0644\u064A\u062F \u0627\u0644\u0645\u0637\u064A\u0631\u064A", sessionType: "\u0628\u0627\u0642\u0629 \u062A\u062F\u0631\u064A\u0628\u064A\u0629", amount: 450, type: "\u0645\u062F\u0641\u0648\u0639\u0629", date: "25 \u0645\u0627\u064A\u0648" },
          { id: "m4", trainee: "\u0646\u0648\u0627\u0641 \u0627\u0644\u0633\u0628\u064A\u0639\u064A", sessionType: "\u062D\u0635\u0629 \u0641\u0631\u062F\u064A\u0629", amount: -300, type: "\u0625\u0644\u063A\u0627\u0621", date: "20 \u0645\u0627\u064A\u0648" }
        ]
      },
      apr: {
        total: "2,620",
        sub: "-5% \u0639\u0646 \u0645\u0627\u0631\u0633",
        up: false,
        sessionRevenue: [
          { type: "\u062D\u0635\u0629 \u0641\u0631\u062F\u064A\u0629", total: "1,400", pct: 53, sessions: 9 },
          { type: "\u062D\u0635\u0629 \u062C\u0645\u0627\u0639\u064A\u0629", total: "820", pct: 31, sessions: 5 },
          { type: "\u0628\u0627\u0642\u0629 \u062A\u062F\u0631\u064A\u0628\u064A\u0629", total: "400", pct: 16, sessions: 2 }
        ],
        bars: [
          { label: "\u0627\u0644\u0623\u0633\u0628\u0648\u0639 1", val: 620 },
          { label: "\u0627\u0644\u0623\u0633\u0628\u0648\u0639 2", val: 850 },
          { label: "\u0627\u0644\u0623\u0633\u0628\u0648\u0639 3", val: 600 },
          { label: "\u0627\u0644\u0623\u0633\u0628\u0648\u0639 4", val: 550 }
        ],
        txs: [
          { id: "a1", trainee: "\u0628\u062F\u0631 \u0627\u0644\u0642\u0631\u0646\u064A", sessionType: "\u062D\u0635\u0629 \u0641\u0631\u062F\u064A\u0629", amount: 300, type: "\u0645\u062F\u0641\u0648\u0639\u0629", date: "30 \u0623\u0628\u0631\u064A\u0644" },
          { id: "a2", trainee: "\u062D\u0645\u062F \u0627\u0644\u0631\u0648\u064A\u0644\u064A", sessionType: "\u062D\u0635\u0629 \u062C\u0645\u0627\u0639\u064A\u0629", amount: 150, type: "\u0645\u062F\u0641\u0648\u0639\u0629", date: "27 \u0623\u0628\u0631\u064A\u0644" },
          { id: "a3", trainee: "\u0645\u0627\u062C\u062F \u0627\u0644\u0639\u0633\u064A\u0631\u064A", sessionType: "\u062D\u0635\u0629 \u0641\u0631\u062F\u064A\u0629", amount: -300, type: "\u0625\u0644\u063A\u0627\u0621", date: "22 \u0623\u0628\u0631\u064A\u0644" }
        ]
      },
      mar: {
        total: "2,760",
        sub: "+20% \u0639\u0646 \u0641\u0628\u0631\u0627\u064A\u0631",
        up: true,
        sessionRevenue: [
          { type: "\u062D\u0635\u0629 \u0641\u0631\u062F\u064A\u0629", total: "1,560", pct: 57, sessions: 10 },
          { type: "\u062D\u0635\u0629 \u062C\u0645\u0627\u0639\u064A\u0629", total: "800", pct: 29, sessions: 5 },
          { type: "\u0628\u0627\u0642\u0629 \u062A\u062F\u0631\u064A\u0628\u064A\u0629", total: "400", pct: 14, sessions: 2 }
        ],
        bars: [
          { label: "\u0627\u0644\u0623\u0633\u0628\u0648\u0639 1", val: 680 },
          { label: "\u0627\u0644\u0623\u0633\u0628\u0648\u0639 2", val: 900 },
          { label: "\u0627\u0644\u0623\u0633\u0628\u0648\u0639 3", val: 680 },
          { label: "\u0627\u0644\u0623\u0633\u0628\u0648\u0639 4", val: 500 }
        ],
        txs: [
          { id: "r1", trainee: "\u0635\u0627\u0644\u062D \u0627\u0644\u0639\u062A\u064A\u0628\u064A", sessionType: "\u0628\u0627\u0642\u0629 \u062A\u062F\u0631\u064A\u0628\u064A\u0629", amount: 400, type: "\u0645\u062F\u0641\u0648\u0639\u0629", date: "31 \u0645\u0627\u0631\u0633" },
          { id: "r2", trainee: "\u064A\u0648\u0633\u0641 \u0627\u0644\u062D\u0631\u0628\u064A", sessionType: "\u062D\u0635\u0629 \u0641\u0631\u062F\u064A\u0629", amount: 300, type: "\u0645\u062F\u0641\u0648\u0639\u0629", date: "28 \u0645\u0627\u0631\u0633" },
          { id: "r3", trainee: "\u0645\u0646\u0635\u0648\u0631 \u0627\u0644\u0632\u0647\u0631\u0627\u0646\u064A", sessionType: "\u062D\u0635\u0629 \u062C\u0645\u0627\u0639\u064A\u0629", amount: 150, type: "\u0645\u062F\u0641\u0648\u0639\u0629", date: "25 \u0645\u0627\u0631\u0633" }
        ]
      }
    };
    const coachWeekData = {
      w1: {
        total: "900",
        sub: "+10% \u0639\u0646 \u0627\u0644\u0623\u0633\u0628\u0648\u0639 \u0627\u0644\u0645\u0627\u0636\u064A",
        up: true,
        sessionRevenue: [
          { type: "\u062D\u0635\u0629 \u0641\u0631\u062F\u064A\u0629", total: "500", pct: 56, sessions: 3 },
          { type: "\u062D\u0635\u0629 \u062C\u0645\u0627\u0639\u064A\u0629", total: "250", pct: 28, sessions: 2 },
          { type: "\u0628\u0627\u0642\u0629 \u062A\u062F\u0631\u064A\u0628\u064A\u0629", total: "150", pct: 16, sessions: 1 }
        ],
        bars: [
          { label: "\u0633\u0628\u062A", val: 300 },
          { label: "\u0623\u062D\u062F", val: 0 },
          { label: "\u0627\u062B\u0646", val: 150 },
          { label: "\u062B\u0644\u0627", val: 0 },
          { label: "\u0623\u0631\u0628", val: 300 },
          { label: "\u062E\u0645\u064A", val: 150 },
          { label: "\u062C\u0645\u0639", val: 0 }
        ],
        txs: [
          { id: "w1c1", trainee: "\u0633\u0639\u062F \u0623\u062D\u0645\u062F", sessionType: "\u062D\u0635\u0629 \u0641\u0631\u062F\u064A\u0629", amount: 300, type: "\u0645\u062F\u0641\u0648\u0639\u0629", date: "\u0627\u0644\u0633\u0628\u062A" },
          { id: "w1c2", trainee: "\u0645\u062D\u0645\u062F \u0627\u0644\u0639\u0645\u0631\u064A", sessionType: "\u062D\u0635\u0629 \u062C\u0645\u0627\u0639\u064A\u0629", amount: 250, type: "\u0645\u062F\u0641\u0648\u0639\u0629", date: "\u0627\u0644\u0623\u0631\u0628\u0639\u0627\u0621" },
          { id: "w1c3", trainee: "\u062A\u0631\u0643\u064A \u0627\u0644\u062D\u0631\u0628\u064A", sessionType: "\u0628\u0627\u0642\u0629 \u062A\u062F\u0631\u064A\u0628\u064A\u0629", amount: 150, type: "\u0645\u062F\u0641\u0648\u0639\u0629", date: "\u0627\u0644\u062E\u0645\u064A\u0633" }
        ]
      },
      w2: {
        total: "1,100",
        sub: "+22% \u0639\u0646 \u0627\u0644\u0623\u0633\u0628\u0648\u0639 \u0627\u0644\u0633\u0627\u0628\u0642",
        up: true,
        sessionRevenue: [
          { type: "\u062D\u0635\u0629 \u0641\u0631\u062F\u064A\u0629", total: "600", pct: 55, sessions: 4 },
          { type: "\u062D\u0635\u0629 \u062C\u0645\u0627\u0639\u064A\u0629", total: "300", pct: 27, sessions: 2 },
          { type: "\u0628\u0627\u0642\u0629 \u062A\u062F\u0631\u064A\u0628\u064A\u0629", total: "200", pct: 18, sessions: 1 }
        ],
        bars: [
          { label: "\u0633\u0628\u062A", val: 300 },
          { label: "\u0623\u062D\u062F", val: 200 },
          { label: "\u0627\u062B\u0646", val: 0 },
          { label: "\u062B\u0644\u0627", val: 300 },
          { label: "\u0623\u0631\u0628", val: 0 },
          { label: "\u062E\u0645\u064A", val: 300 },
          { label: "\u062C\u0645\u0639", val: 0 }
        ],
        txs: [
          { id: "w2c1", trainee: "\u0641\u064A\u0635\u0644 \u0627\u0644\u0634\u0647\u0631\u064A", sessionType: "\u062D\u0635\u0629 \u0641\u0631\u062F\u064A\u0629", amount: 300, type: "\u0645\u062F\u0641\u0648\u0639\u0629", date: "\u0627\u0644\u0633\u0628\u062A" },
          { id: "w2c2", trainee: "\u0639\u0628\u062F\u0627\u0644\u0644\u0647 \u0627\u0644\u063A\u0627\u0645\u062F\u064A", sessionType: "\u062D\u0635\u0629 \u062C\u0645\u0627\u0639\u064A\u0629", amount: 300, type: "\u0645\u062F\u0641\u0648\u0639\u0629", date: "\u0627\u0644\u062B\u0644\u0627\u062B\u0627\u0621" },
          { id: "w2c3", trainee: "\u0646\u0648\u0627\u0641 \u0627\u0644\u0633\u0628\u064A\u0639\u064A", sessionType: "\u062D\u0635\u0629 \u0641\u0631\u062F\u064A\u0629", amount: -300, type: "\u0625\u0644\u063A\u0627\u0621", date: "\u0627\u0644\u0623\u062D\u062F" },
          { id: "w2c4", trainee: "\u0631\u0627\u0634\u062F \u0627\u0644\u0623\u062D\u0645\u062F\u064A", sessionType: "\u0628\u0627\u0642\u0629 \u062A\u062F\u0631\u064A\u0628\u064A\u0629", amount: 200, type: "\u0645\u062F\u0641\u0648\u0639\u0629", date: "\u0627\u0644\u062E\u0645\u064A\u0633" }
        ]
      },
      w3: {
        total: "700",
        sub: "-36% \u0639\u0646 \u0627\u0644\u0623\u0633\u0628\u0648\u0639 \u0627\u0644\u0633\u0627\u0628\u0642",
        up: false,
        sessionRevenue: [
          { type: "\u062D\u0635\u0629 \u0641\u0631\u062F\u064A\u0629", total: "400", pct: 57, sessions: 2 },
          { type: "\u062D\u0635\u0629 \u062C\u0645\u0627\u0639\u064A\u0629", total: "200", pct: 29, sessions: 1 },
          { type: "\u0628\u0627\u0642\u0629 \u062A\u062F\u0631\u064A\u0628\u064A\u0629", total: "100", pct: 14, sessions: 1 }
        ],
        bars: [
          { label: "\u0633\u0628\u062A", val: 0 },
          { label: "\u0623\u062D\u062F", val: 300 },
          { label: "\u0627\u062B\u0646", val: 0 },
          { label: "\u062B\u0644\u0627", val: 200 },
          { label: "\u0623\u0631\u0628", val: 200 },
          { label: "\u062E\u0645\u064A", val: 0 },
          { label: "\u062C\u0645\u0639", val: 0 }
        ],
        txs: [
          { id: "w3c1", trainee: "\u062C\u0627\u0633\u0645 \u0627\u0644\u0634\u0645\u0631\u064A", sessionType: "\u062D\u0635\u0629 \u0641\u0631\u062F\u064A\u0629", amount: 300, type: "\u0645\u062F\u0641\u0648\u0639\u0629", date: "\u0627\u0644\u0623\u062D\u062F" },
          { id: "w3c2", trainee: "\u0648\u0644\u064A\u062F \u0627\u0644\u0645\u0637\u064A\u0631\u064A", sessionType: "\u062D\u0635\u0629 \u062C\u0645\u0627\u0639\u064A\u0629", amount: 200, type: "\u0645\u062F\u0641\u0648\u0639\u0629", date: "\u0627\u0644\u062B\u0644\u0627\u062B\u0627\u0621" }
        ]
      },
      w4: {
        total: "500",
        sub: "-29% \u0639\u0646 \u0627\u0644\u0623\u0633\u0628\u0648\u0639 \u0627\u0644\u0633\u0627\u0628\u0642",
        up: false,
        sessionRevenue: [
          { type: "\u062D\u0635\u0629 \u0641\u0631\u062F\u064A\u0629", total: "300", pct: 60, sessions: 2 },
          { type: "\u062D\u0635\u0629 \u062C\u0645\u0627\u0639\u064A\u0629", total: "150", pct: 30, sessions: 1 },
          { type: "\u0628\u0627\u0642\u0629 \u062A\u062F\u0631\u064A\u0628\u064A\u0629", total: "50", pct: 10, sessions: 1 }
        ],
        bars: [
          { label: "\u0633\u0628\u062A", val: 300 },
          { label: "\u0623\u062D\u062F", val: 0 },
          { label: "\u0627\u062B\u0646", val: 0 },
          { label: "\u062B\u0644\u0627", val: 150 },
          { label: "\u0623\u0631\u0628", val: 0 },
          { label: "\u062E\u0645\u064A", val: 50 },
          { label: "\u062C\u0645\u0639", val: 0 }
        ],
        txs: [
          { id: "w4c1", trainee: "\u0628\u062F\u0631 \u0627\u0644\u0642\u0631\u0646\u064A", sessionType: "\u062D\u0635\u0629 \u0641\u0631\u062F\u064A\u0629", amount: 300, type: "\u0645\u062F\u0641\u0648\u0639\u0629", date: "\u0627\u0644\u0633\u0628\u062A" },
          { id: "w4c2", trainee: "\u062D\u0645\u062F \u0627\u0644\u0631\u0648\u064A\u0644\u064A", sessionType: "\u062D\u0635\u0629 \u062C\u0645\u0627\u0639\u064A\u0629", amount: 150, type: "\u0645\u062F\u0641\u0648\u0639\u0629", date: "\u0627\u0644\u062B\u0644\u0627\u062B\u0627\u0621" }
        ]
      }
    };
    const cActivePeriod = coachRevPeriodType === "month" ? coachMonthData[coachRevSelectedMonth] : coachWeekData[coachRevSelectedWeek];
    const cActivePeriodLabel = coachRevPeriodType === "month" ? CMONTHS.find((m) => m.key === coachRevSelectedMonth).label : CWEEKS.find((w) => w.key === coachRevSelectedWeek).label;
    const cMaxBar = Math.max(...cActivePeriod.bars.map((b) => b.val), 1);
    const sessionColors = ["bg-violet-500", "bg-blue-500", "bg-amber-500"];
    const sessionDots = ["bg-violet-500", "bg-blue-500", "bg-amber-500"];
    return <div className="flex-1 overflow-y-auto bg-background">
        {
      /* Header */
    }
        <div className="bg-gradient-to-br from-violet-700 to-violet-600 text-white px-6 pt-8 pb-6">
          <div className="flex justify-between items-start mb-5">
            <button onClick={() => setCurrentView("coach-dashboard")} className="p-2 bg-white/20 rounded-full backdrop-blur-sm hover:bg-white/30 transition-colors">
              <ChevronRight className="w-5 h-5" />
            </button>
            <div className="text-center">
              <h1 className="text-xl">تفاصيل الإيرادات</h1>
              <p className="text-xs text-white/70 mt-1">مدرب بادل</p>
            </div>
            <button className="p-2 bg-white/20 rounded-full backdrop-blur-sm hover:bg-white/30 transition-colors">
              <Download className="w-5 h-5" />
            </button>
          </div>

          {
      /* Period Type Tabs */
    }
          <div className="flex bg-white/10 backdrop-blur-sm rounded-xl p-1 mb-4">
            {["month", "week"].map((t) => <button
      key={t}
      onClick={() => {
        setCoachRevPeriodType(t);
        setCoachRevShowPeriodPicker(false);
      }}
      className={`flex-1 py-2 rounded-lg text-sm transition-all ${coachRevPeriodType === t ? "bg-white text-violet-700" : "text-white/80 hover:text-white"}`}
    >
                {t === "month" ? "\u0634\u0647\u0631\u064A" : "\u0623\u0633\u0628\u0648\u0639\u064A"}
              </button>)}
          </div>

          {
      /* Period Selector Button */
    }
          <button
      onClick={() => setCoachRevShowPeriodPicker(!coachRevShowPeriodPicker)}
      className="w-full flex items-center justify-between bg-white/10 backdrop-blur-sm rounded-xl px-4 py-3 mb-4 hover:bg-white/20 transition-colors"
    >
            <ChevronDown className={`w-4 h-4 transition-transform ${coachRevShowPeriodPicker ? "rotate-180" : ""}`} />
            <span className="text-sm">{cActivePeriodLabel}</span>
            <Calendar className="w-4 h-4 text-white/70" />
          </button>

          {
      /* Dropdown */
    }
          {coachRevShowPeriodPicker && <div className="bg-white rounded-xl overflow-hidden mb-4 shadow-lg">
              {(coachRevPeriodType === "month" ? CMONTHS : CWEEKS).map((item) => {
      const isActive = coachRevPeriodType === "month" ? coachRevSelectedMonth === item.key : coachRevSelectedWeek === item.key;
      return <button
        key={item.key}
        onClick={() => {
          if (coachRevPeriodType === "month") setCoachRevSelectedMonth(item.key);
          else setCoachRevSelectedWeek(item.key);
          setCoachRevShowPeriodPicker(false);
        }}
        className={`w-full text-right px-4 py-3 text-sm border-b border-gray-100 last:border-0 transition-colors ${isActive ? "bg-violet-50 text-violet-700" : "text-secondary hover:bg-gray-50"}`}
      >
                    {item.label}
                  </button>;
    })}
            </div>}

          {
      /* Total Hero */
    }
          <div className="bg-white/10 backdrop-blur-sm rounded-2xl p-5 text-center">
            <p className="text-white/70 text-sm mb-1">
              إجمالي إيرادات {coachRevPeriodType === "month" ? "\u0627\u0644\u0634\u0647\u0631" : "\u0627\u0644\u0623\u0633\u0628\u0648\u0639"}
            </p>
            <p className="text-4xl mb-1">{cActivePeriod.total}</p>
            <p className="text-white/80 text-sm">ريال سعودي</p>
            <div className="flex items-center justify-center gap-1 mt-2">
              {cActivePeriod.up ? <ArrowUpRight className="w-4 h-4 text-violet-300" /> : <ArrowDownRight className="w-4 h-4 text-red-300" />}
              <span className={`text-sm ${cActivePeriod.up ? "text-violet-300" : "text-red-300"}`}>{cActivePeriod.sub}</span>
            </div>
          </div>
        </div>

        <div className="px-6 py-6 space-y-5">

          {
      /* Quick Stats */
    }
          <div className="grid grid-cols-3 gap-3">
            {[
      { label: "\u0627\u0644\u062D\u0635\u0635 \u0627\u0644\u0645\u0646\u062C\u0632\u0629", value: String(cActivePeriod.sessionRevenue.reduce((a, s) => a + s.sessions, 0)) },
      { label: "\u0645\u062A\u0648\u0633\u0637 \u0627\u0644\u062D\u0635\u0629", value: String(Math.round(parseInt(cActivePeriod.total.replace(",", "")) / cActivePeriod.sessionRevenue.reduce((a, s) => a + s.sessions, 0))) + " \u0631.\u0633" },
      { label: "\u0646\u0633\u0628\u0629 \u0627\u0644\u0625\u0644\u063A\u0627\u0621", value: cActivePeriod.txs.filter((t) => t.amount < 0).length > 0 ? Math.round(cActivePeriod.txs.filter((t) => t.amount < 0).length / cActivePeriod.txs.length * 100) + "%" : "0%" }
    ].map((s) => <div key={s.label} className="bg-white border border-border rounded-xl p-3 text-center shadow-sm">
                <p className="text-base text-secondary mb-1">{s.value}</p>
                <p className="text-xs text-muted-foreground">{s.label}</p>
              </div>)}
          </div>

          {
      /* Bar Chart */
    }
          <div className="bg-white border border-border rounded-2xl p-5 shadow-sm">
            <h2 className="text-base text-secondary flex items-center gap-2 mb-4">
              <BarChart2 className="w-5 h-5 text-violet-600" />
              الإيرادات التفصيلية · {cActivePeriodLabel}
            </h2>
            <div className="flex items-end gap-2" style={{ height: "120px" }}>
              {cActivePeriod.bars.map((b) => {
      const h = b.val === 0 ? 4 : Math.round(b.val / cMaxBar * 100);
      return <div key={b.label} className="flex-1 flex flex-col items-center gap-1">
                    <span className="text-xs text-muted-foreground leading-none">
                      {b.val > 0 ? b.val >= 1e3 ? (b.val / 1e3).toFixed(1) + "k" : b.val : ""}
                    </span>
                    <div className="w-full relative bg-violet-100 rounded-t-lg" style={{ height: "80px" }}>
                      <div
        className={`absolute bottom-0 w-full rounded-t-lg transition-all duration-500 ${b.val > 0 ? "bg-violet-500" : "bg-gray-200"}`}
        style={{ height: `${h}%` }}
      />
                    </div>
                    <span className="text-xs text-muted-foreground leading-none">{b.label}</span>
                  </div>;
    })}
            </div>
          </div>

          {
      /* Revenue by Session Type */
    }
          <div className="bg-white border border-border rounded-2xl p-5 shadow-sm">
            <h2 className="text-base text-secondary flex items-center gap-2 mb-4">
              <TrendingUp className="w-5 h-5 text-violet-600" />
              الإيرادات حسب نوع الحصة
            </h2>
            <div className="space-y-4">
              {cActivePeriod.sessionRevenue.map((s, i) => <div key={s.type}>
                  <div className="flex items-center justify-between mb-1">
                    <div className="flex items-center gap-2">
                      <div className={`w-2 h-2 rounded-full ${sessionDots[i]}`} />
                      <span className="text-sm text-secondary">{s.type}</span>
                    </div>
                    <div className="text-left">
                      <span className="text-sm text-secondary">{s.total} ر.س</span>
                      <span className="text-xs text-muted-foreground mr-2">({s.sessions} حصص)</span>
                    </div>
                  </div>
                  <div className="w-full bg-gray-100 rounded-full h-2">
                    <div
      className={`h-2 rounded-full transition-all duration-500 ${sessionColors[i]}`}
      style={{ width: `${s.pct}%` }}
    />
                  </div>
                  <p className="text-xs text-muted-foreground mt-1">{s.pct}% من الإجمالي</p>
                </div>)}
            </div>
          </div>

          {
      /* Transactions */
    }
          <div className="bg-white border border-border rounded-2xl p-5 shadow-sm">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-base text-secondary flex items-center gap-2">
                <Filter className="w-5 h-5 text-violet-600" />
                المعاملات · {cActivePeriodLabel}
              </h2>
              <span className="text-xs text-muted-foreground">{cActivePeriod.txs.length} معاملة</span>
            </div>
            <div className="space-y-3">
              {cActivePeriod.txs.map((tx) => <div key={tx.id} className={`flex items-center justify-between p-3 rounded-xl border ${tx.amount < 0 ? "bg-red-50 border-red-200" : "bg-gray-50 border-border"}`}>
                  <div className="flex items-center gap-3">
                    <div className={`w-10 h-10 rounded-full flex items-center justify-center flex-shrink-0 ${tx.amount < 0 ? "bg-red-100" : "bg-violet-100"}`}>
                      {tx.amount < 0 ? <ArrowDownRight className="w-5 h-5 text-red-600" /> : <ArrowUpRight className="w-5 h-5 text-violet-600" />}
                    </div>
                    <div>
                      <p className="text-sm text-secondary">{tx.trainee}</p>
                      <p className="text-xs text-muted-foreground">{tx.sessionType} · {tx.date}</p>
                    </div>
                  </div>
                  <div className="text-left">
                    <p className={`text-sm font-medium ${tx.amount < 0 ? "text-red-600" : "text-violet-600"}`}>
                      {tx.amount < 0 ? "-" : "+"}{Math.abs(tx.amount)} ر.س
                    </p>
                    <span className={`text-xs px-2 py-0.5 rounded-full ${tx.amount < 0 ? "bg-red-100 text-red-600" : "bg-violet-100 text-violet-700"}`}>{tx.type}</span>
                  </div>
                </div>)}
            </div>
          </div>
        </div>
      </div>;
  }
  if (currentView === "venue-dashboard") {
    return <div className="flex-1 overflow-y-auto bg-background">
        <div className="bg-gradient-to-br from-secondary to-secondary/90 text-white px-6 pt-8 pb-6">
          <div className="flex justify-center items-start mb-6">
            <div className="text-center">
              <h1 className="text-xl">صفحتي</h1>
              <p className="text-xs text-white/70 mt-1">الملعب {userName.split(" ")[0]}</p>
            </div>
          </div>

          <div className="grid grid-cols-3 gap-3">
            <div className="bg-white/10 backdrop-blur-sm rounded-xl p-3 text-center">
              <p className="text-2xl mb-1">6</p>
              <p className="text-xs text-white/80">ملاعب</p>
            </div>
            <div className="bg-white/10 backdrop-blur-sm rounded-xl p-3 text-center">
              <p className="text-2xl mb-1">4.6</p>
              <p className="text-xs text-white/80">التقييم</p>
            </div>
            <div className="bg-white/10 backdrop-blur-sm rounded-xl p-3 text-center">
              <p className="text-2xl mb-1">89%</p>
              <p className="text-xs text-white/80">نسبة الحجز</p>
            </div>
          </div>
        </div>

        <div className="px-6 py-6 space-y-4">
          <VenueCourtsSection />
          <VenueOffersSection courtNames={["\u0645\u0644\u0639\u0628 1 - \u062F\u0627\u062E\u0644\u064A", "\u0645\u0644\u0639\u0628 2 - \u062E\u0627\u0631\u062C\u064A"]} />

          <div className="bg-white border border-border rounded-2xl p-4 shadow-sm">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg text-secondary flex items-center gap-2">
                <TrendingUp className="w-5 h-5 text-primary" />
                الإيرادات
              </h2>
              <button
      onClick={() => setCurrentView("venue-revenue")}
      className="text-xs text-primary flex items-center gap-1 hover:underline"
    >
                تفاصيل الإيرادات
                <ChevronLeft className="w-4 h-4" />
              </button>
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div className="text-center p-3 bg-gray-50 rounded-lg">
                <p className="text-xl text-secondary mb-1">8,400 ر.س</p>
                <p className="text-xs text-muted-foreground">هذا الأسبوع</p>
              </div>
              <div className="text-center p-3 bg-gray-50 rounded-lg">
                <p className="text-xl text-secondary mb-1">32,800 ر.س</p>
                <p className="text-xs text-muted-foreground">هذا الشهر</p>
              </div>
            </div>
          </div>

          {
      /* الإشعارات */
    }
          <div className="bg-white border border-border rounded-2xl p-5 shadow-sm">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg text-secondary flex items-center gap-2">
                <Bell className="w-5 h-5 text-primary" />
                الإشعارات
              </h2>
              <span className="px-2 py-1 bg-red-500 text-white text-xs rounded-full">4</span>
            </div>
            <div className="space-y-3">
              <div className="p-3 bg-blue-50 border border-blue-200 rounded-lg">
                <div className="flex items-start gap-3">
                  <div className="w-2 h-2 bg-blue-500 rounded-full mt-2 flex-shrink-0" />
                  <div className="flex-1">
                    <p className="text-sm text-secondary mb-1">حجز جديد لملعب 1 - غداً 5:00 مساءً</p>
                    <p className="text-xs text-muted-foreground">منذ 15 دقيقة</p>
                  </div>
                </div>
              </div>
              <div className="p-3 bg-gray-50 rounded-lg">
                <div className="flex items-start gap-3">
                  <div className="w-2 h-2 bg-gray-300 rounded-full mt-2 flex-shrink-0" />
                  <div className="flex-1">
                    <p className="text-sm text-secondary mb-1">إلغاء حجز ملعب 3 - اليوم 7:00 مساءً</p>
                    <p className="text-xs text-muted-foreground">منذ ساعة</p>
                  </div>
                </div>
              </div>
              <div className="p-3 bg-gray-50 rounded-lg">
                <div className="flex items-start gap-3">
                  <div className="w-2 h-2 bg-gray-300 rounded-full mt-2 flex-shrink-0" />
                  <div className="flex-1">
                    <p className="text-sm text-secondary mb-1">تقييم جديد - 5 نجوم من أحمد</p>
                    <p className="text-xs text-muted-foreground">منذ 3 ساعات</p>
                  </div>
                </div>
              </div>
            </div>
            <button className="w-full mt-3 py-2 text-sm text-primary hover:text-primary/80 transition-colors">
              عرض جميع الإشعارات
            </button>
          </div>

          {
      /* المحفظة */
    }
          <div className="bg-white border border-border rounded-2xl p-5 shadow-sm">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg text-secondary flex items-center gap-2">
                <Wallet className="w-5 h-5 text-primary" />
                المحفظة
              </h2>
            </div>
            <div className="bg-gradient-to-br from-primary/5 to-primary/10 rounded-xl p-4 mb-4">
              <p className="text-sm text-muted-foreground mb-1">الرصيد المتاح</p>
              <p className="text-3xl text-primary font-bold">8,400 ر.س</p>
            </div>
            <div className="grid grid-cols-2 gap-3">
              <button
      onClick={() => setCurrentView("top-up-wallet")}
      className="py-3 bg-primary text-white rounded-xl hover:bg-primary/90 transition-colors"
    >
                شحن الرصيد
              </button>
              <button onClick={() => setCurrentView("withdraw")} className="py-3 bg-white border-2 border-border text-secondary rounded-xl hover:border-primary transition-colors">
                سحب الرصيد
              </button>
            </div>
          </div>

          {
      /* الإعدادات العامة */
    }
          <div className="bg-white border border-border rounded-2xl p-4 shadow-sm">
            <h2 className="text-lg text-secondary mb-4">الإعدادات العامة</h2>
            <div className="space-y-2">
              <button onClick={() => setCurrentView("language")} className="w-full flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center"><Languages className="w-5 h-5 text-primary" /></div>
                  <div className="text-right"><p className="text-sm text-secondary">تغيير اللغة</p><p className="text-xs text-muted-foreground">العربية</p></div>
                </div>
                <ChevronLeft className="w-5 h-5 text-muted-foreground" />
              </button>
              <button onClick={() => setCurrentView("contact")} className="w-full flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center"><MessageCircle className="w-5 h-5 text-primary" /></div>
                  <div className="text-right"><p className="text-sm text-secondary">اتصل بنا</p><p className="text-xs text-muted-foreground">واتساب، إيميل، دردشة</p></div>
                </div>
                <ChevronLeft className="w-5 h-5 text-muted-foreground" />
              </button>
              <button onClick={() => setCurrentView("account-settings")} className="w-full flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center"><Settings className="w-5 h-5 text-primary" /></div>
                  <div className="text-right"><p className="text-sm text-secondary">إعدادات الحساب</p><p className="text-xs text-muted-foreground">الجوال، الإيميل، كلمة المرور</p></div>
                </div>
                <ChevronLeft className="w-5 h-5 text-muted-foreground" />
              </button>
              <button onClick={() => setCurrentView("terms")} className="w-full flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center"><FileText className="w-5 h-5 text-primary" /></div>
                  <div className="text-right"><p className="text-sm text-secondary">الشروط والأحكام</p><p className="text-xs text-muted-foreground">الشروط القانونية للاستخدام</p></div>
                </div>
                <ChevronLeft className="w-5 h-5 text-muted-foreground" />
              </button>
              <button onClick={() => setCurrentView("privacy")} className="w-full flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center"><Shield className="w-5 h-5 text-primary" /></div>
                  <div className="text-right"><p className="text-sm text-secondary">سياسة الخصوصية</p><p className="text-xs text-muted-foreground">حماية البيانات والخصوصية</p></div>
                </div>
                <ChevronLeft className="w-5 h-5 text-muted-foreground" />
              </button>
              <button onClick={() => setCurrentView("refund")} className="w-full flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center"><Wallet className="w-5 h-5 text-primary" /></div>
                  <div className="text-right"><p className="text-sm text-secondary">سياسة الاسترجاع</p><p className="text-xs text-muted-foreground">شروط استرجاع المبالغ</p></div>
                </div>
                <ChevronLeft className="w-5 h-5 text-muted-foreground" />
              </button>
              {onLogout && <button onClick={onLogout} className="w-full flex items-center justify-between p-3 bg-red-50 rounded-lg hover:bg-red-100 transition-colors border border-red-200">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 bg-red-100 rounded-full flex items-center justify-center"><LogOut className="w-5 h-5 text-red-600" /></div>
                    <div className="text-right"><p className="text-sm text-red-600">تسجيل الخروج</p><p className="text-xs text-red-500">الخروج من الحساب</p></div>
                  </div>
                  <ChevronLeft className="w-5 h-5 text-red-400" />
                </button>}
            </div>
          </div>
        </div>
      </div>;
  }
  if (currentView === "withdraw") {
    const balanceMap = { player: 250, coach: 3200, venue: 8400 };
    const currentBalance = balanceMap[activeRole || "player"];
    const bankMethods = [
      { id: "b1", name: "\u0627\u0644\u0628\u0646\u0643 \u0627\u0644\u0623\u0647\u0644\u064A \u0627\u0644\u0633\u0639\u0648\u062F\u064A", icon: "\u{1F3E6}", last4: "4521", type: "bank" },
      { id: "b2", name: "\u0628\u0646\u0643 \u0627\u0644\u0631\u0627\u062C\u062D\u064A", icon: "\u{1F3E6}", last4: "8834", type: "bank" }
    ];
    const walletMethods = [
      { id: "w1", name: "STC Pay", icon: "\u{1F4F1}", last4: "0512", type: "wallet" },
      { id: "w2", name: "Apple Pay", icon: "\u{1F34E}", last4: "1234", type: "wallet" }
    ];
    const step = withdrawStep;
    const setStep = setWithdrawStep;
    const selectedMethod = withdrawSelectedMethod;
    const setSelectedMethod = setWithdrawSelectedMethod;
    const quickAmounts = activeRole === "player" ? [50, 100, 200] : activeRole === "coach" ? [500, 1e3, 2e3] : [1e3, 3e3, 5e3];
    const maxAmount = currentBalance;
    const numericAmount = parseFloat(withdrawAmount) || 0;
    const isValid = numericAmount >= 50 && numericAmount <= maxAmount && selectedMethod;
    const fee = numericAmount > 0 ? Math.min(numericAmount * 0.01, 15) : 0;
    const netAmount = numericAmount - fee;
    const goBack = () => {
      if (step === "confirm") {
        setStep("form");
        return;
      }
      const dashMap = { player: "player-dashboard", coach: "coach-dashboard", venue: "venue-dashboard" };
      setCurrentView(dashMap[activeRole || "player"]);
    };
    if (step === "success") {
      return <div className="flex-1 overflow-y-auto bg-gray-50 flex flex-col items-center justify-center px-6 text-center">
          <div className="w-24 h-24 bg-gradient-to-br from-green-400 to-green-500 rounded-full flex items-center justify-center mb-6 shadow-lg">
            <span className="text-4xl">✓</span>
          </div>
          <h2 className="text-2xl text-secondary mb-2">تم طلب السحب</h2>
          <p className="text-muted-foreground text-sm mb-2">سيتم تحويل المبلغ خلال 1-3 أيام عمل</p>
          <div className="bg-white rounded-2xl p-6 shadow-sm w-full max-w-sm mt-6 space-y-3 text-right">
            <div className="flex justify-between text-sm">
              <span className="text-green-600">{netAmount.toFixed(2)} ر.س</span>
              <span className="text-muted-foreground">المبلغ الصافي</span>
            </div>
            <div className="flex justify-between text-sm">
              <span className="text-red-500">-{fee.toFixed(2)} ر.س</span>
              <span className="text-muted-foreground">رسوم التحويل</span>
            </div>
            <div className="border-t border-border pt-3 flex justify-between">
              <span className="text-secondary">{numericAmount.toFixed(2)} ر.س</span>
              <span className="text-muted-foreground">المبلغ المطلوب</span>
            </div>
          </div>
          <button
        onClick={() => {
          const dashMap = { player: "player-dashboard", coach: "coach-dashboard", venue: "venue-dashboard" };
          setCurrentView(dashMap[activeRole || "player"]);
          setWithdrawStep("form");
          setWithdrawAmount("");
        }}
        className="mt-8 w-full max-w-sm py-4 bg-gradient-to-r from-primary to-primary/90 text-white rounded-2xl shadow-lg"
      >
            العودة للمحفظة
          </button>
        </div>;
    }
    if (step === "confirm") {
      const method = [...bankMethods, ...walletMethods].find((m) => m.id === selectedMethod);
      return <div className="flex-1 overflow-y-auto bg-gray-50">
          <div className="bg-gradient-to-br from-secondary to-secondary/90 text-white px-6 pt-8 pb-10">
            <div className="flex items-center gap-3 mb-6">
              <button onClick={goBack} className="p-2 bg-white/20 rounded-full backdrop-blur-sm hover:bg-white/30 transition-colors">
                <ChevronRight className="w-5 h-5" />
              </button>
              <h1 className="text-lg">تأكيد السحب</h1>
            </div>
            <div className="text-center">
              <p className="text-white/70 text-sm mb-1">المبلغ الذي سيُسحب</p>
              <p className="text-4xl">{numericAmount.toFixed(2)} <span className="text-2xl text-white/80">ر.س</span></p>
            </div>
          </div>

          <div className="-mt-4 px-4 space-y-4 pb-6">
            <div className="bg-white rounded-2xl p-5 shadow-sm space-y-4">
              <div className="flex justify-between text-sm">
                <span className="text-muted-foreground">المبلغ المطلوب</span>
                <span className="text-secondary">{numericAmount.toFixed(2)} ر.س</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-muted-foreground">رسوم التحويل (1%)</span>
                <span className="text-red-500">-{fee.toFixed(2)} ر.س</span>
              </div>
              <div className="border-t border-border pt-4 flex justify-between">
                <span className="text-muted-foreground">المبلغ الصافي</span>
                <span className="text-green-600 text-lg">{netAmount.toFixed(2)} ر.س</span>
              </div>
            </div>

            <div className="bg-white rounded-2xl p-5 shadow-sm">
              <p className="text-sm text-muted-foreground mb-2">وجهة التحويل</p>
              <div className="flex items-center gap-3">
                <span className="text-2xl">{method?.icon}</span>
                <div>
                  <p className="text-sm text-secondary">{method?.name}</p>
                  <p className="text-xs text-muted-foreground">****{method?.last4}</p>
                </div>
              </div>
            </div>

            <div className="bg-amber-50 border border-amber-200 rounded-2xl p-4">
              <p className="text-xs text-amber-700">سيتم التحويل خلال 1-3 أيام عمل. الحد الأدنى للسحب 50 ر.س والحد الأقصى لرسوم التحويل 15 ر.س.</p>
            </div>

            <button
        onClick={() => setStep("success")}
        className="w-full py-4 bg-gradient-to-r from-primary to-primary/90 text-white rounded-2xl shadow-lg"
      >
              تأكيد السحب
            </button>
          </div>
        </div>;
    }
    return <div className="flex-1 overflow-y-auto bg-gray-50">
        {
      /* هيدر */
    }
        <div className="bg-gradient-to-br from-secondary to-secondary/90 text-white px-6 pt-8 pb-12">
          <div className="flex items-center gap-3 mb-6">
            <button onClick={goBack} className="p-2 bg-white/20 rounded-full backdrop-blur-sm hover:bg-white/30 transition-colors">
              <ChevronRight className="w-5 h-5" />
            </button>
            <h1 className="text-lg">سحب الرصيد</h1>
          </div>
          <div className="bg-white/10 backdrop-blur-sm rounded-2xl p-4 text-center">
            <p className="text-white/70 text-sm mb-1">الرصيد المتاح للسحب</p>
            <p className="text-4xl mb-1">{currentBalance.toLocaleString()} <span className="text-2xl text-white/80">ر.س</span></p>
            <p className="text-xs text-white/60">الحد الأدنى للسحب 50 ر.س</p>
          </div>
        </div>

        <div className="-mt-4 px-4 pb-6 space-y-4">
          {
      /* حقل المبلغ */
    }
          <div className="bg-white rounded-2xl p-5 shadow-sm">
            <p className="text-sm text-secondary mb-3">أدخل المبلغ المراد سحبه</p>
            <div className="relative mb-4">
              <input
      type="number"
      value={withdrawAmount}
      onChange={(e) => setWithdrawAmount(e.target.value)}
      placeholder="0"
      className="w-full text-3xl text-center py-4 bg-gray-50 border-2 border-border rounded-xl focus:border-primary focus:outline-none transition-colors"
    />
              <span className="absolute left-4 top-1/2 -translate-y-1/2 text-muted-foreground">ر.س</span>
            </div>
            {
      /* مبالغ سريعة */
    }
            <div className="grid grid-cols-3 gap-2">
              {quickAmounts.map((amt) => <button
      key={amt}
      onClick={() => setWithdrawAmount(String(amt))}
      className={`py-2 rounded-xl text-sm border-2 transition-colors ${withdrawAmount === String(amt) ? "border-primary bg-primary/5 text-primary" : "border-border text-muted-foreground hover:border-primary/50"}`}
    >
                  {amt.toLocaleString()} ر.س
                </button>)}
            </div>
            <button
      onClick={() => setWithdrawAmount(String(maxAmount))}
      className="mt-3 w-full py-2 text-xs text-primary hover:underline"
    >
              سحب كامل الرصيد ({maxAmount.toLocaleString()} ر.س)
            </button>

            {numericAmount > 0 && <div className="mt-3 bg-gray-50 rounded-xl p-3 space-y-1">
                <div className="flex justify-between text-xs">
                  <span className="text-muted-foreground">رسوم التحويل (1%، بحد أقصى 15 ر.س)</span>
                  <span className="text-red-500">-{fee.toFixed(2)} ر.س</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-secondary">المبلغ الصافي</span>
                  <span className="text-green-600">{netAmount.toFixed(2)} ر.س</span>
                </div>
              </div>}

            {numericAmount > maxAmount && <p className="mt-2 text-xs text-red-500">المبلغ يتجاوز رصيدك المتاح</p>}
            {numericAmount > 0 && numericAmount < 50 && <p className="mt-2 text-xs text-red-500">الحد الأدنى للسحب 50 ر.س</p>}
          </div>

          {
      /* طرق الاستلام */
    }
          <div className="bg-white rounded-2xl p-5 shadow-sm">
            <div className="flex items-center justify-between mb-4">
              <button onClick={() => setShowAddBank(!showAddBank)} className="text-xs text-primary flex items-center gap-1">
                <Plus className="w-4 h-4" /> إضافة حساب
              </button>
              <p className="text-sm text-secondary">طريقة الاستلام</p>
            </div>

            {showAddBank && <div className="mb-4 p-3 bg-gray-50 rounded-xl space-y-2">
                <p className="text-xs text-muted-foreground text-right">رقم الآيبان (SA…)</p>
                <input
      type="text"
      value={ibanInput}
      onChange={(e) => setIbanInput(e.target.value)}
      placeholder="SA0000000000000000000000"
      className="w-full text-sm px-3 py-2 border border-border rounded-lg focus:border-primary focus:outline-none text-right"
      dir="ltr"
    />
                <button className="w-full py-2 bg-primary text-white text-sm rounded-lg">إضافة</button>
              </div>}

            <div className="space-y-2">
              <p className="text-xs text-muted-foreground mb-2">الحسابات البنكية</p>
              {bankMethods.map((m) => <button
      key={m.id}
      onClick={() => setSelectedMethod(m.id)}
      className={`w-full flex items-center justify-between p-3 rounded-xl border-2 transition-colors ${selectedMethod === m.id ? "border-primary bg-primary/5" : "border-border hover:border-primary/30"}`}
    >
                  <div className={`w-5 h-5 rounded-full border-2 flex items-center justify-center ${selectedMethod === m.id ? "border-primary" : "border-gray-300"}`}>
                    {selectedMethod === m.id && <div className="w-2.5 h-2.5 rounded-full bg-primary" />}
                  </div>
                  <div className="flex items-center gap-3">
                    <span className="text-xl">{m.icon}</span>
                    <div className="text-right">
                      <p className="text-sm text-secondary">{m.name}</p>
                      <p className="text-xs text-muted-foreground">****{m.last4}</p>
                    </div>
                  </div>
                </button>)}

              <p className="text-xs text-muted-foreground mt-3 mb-2">المحافظ الرقمية</p>
              {walletMethods.map((m) => <button
      key={m.id}
      onClick={() => setSelectedMethod(m.id)}
      className={`w-full flex items-center justify-between p-3 rounded-xl border-2 transition-colors ${selectedMethod === m.id ? "border-primary bg-primary/5" : "border-border hover:border-primary/30"}`}
    >
                  <div className={`w-5 h-5 rounded-full border-2 flex items-center justify-center ${selectedMethod === m.id ? "border-primary" : "border-gray-300"}`}>
                    {selectedMethod === m.id && <div className="w-2.5 h-2.5 rounded-full bg-primary" />}
                  </div>
                  <div className="flex items-center gap-3">
                    <span className="text-xl">{m.icon}</span>
                    <div className="text-right">
                      <p className="text-sm text-secondary">{m.name}</p>
                      <p className="text-xs text-muted-foreground">****{m.last4}</p>
                    </div>
                  </div>
                </button>)}
            </div>
          </div>

          {
      /* زر المتابعة */
    }
          <button
      onClick={() => isValid && setStep("confirm")}
      disabled={!isValid}
      className={`w-full py-4 rounded-2xl text-white shadow-lg transition-all ${isValid ? "bg-gradient-to-r from-primary to-primary/90 hover:shadow-xl" : "bg-gray-300 cursor-not-allowed"}`}
    >
            متابعة
          </button>
        </div>
      </div>;
  }
  if (currentView === "coach-trainees") {
    const allTrainees = [
      { id: "t1", name: "\u0623\u062D\u0645\u062F \u0627\u0644\u063A\u0627\u0645\u062F\u064A", avatar: "\u0623.\u063A", color: "from-blue-500 to-blue-600", level: "3.5", sessions: 12, status: "\u0646\u0634\u0637", progress: 78, nextSession: "\u063A\u062F\u0627\u064B 5:00 \u0645", joinDate: "\u0645\u0627\u0631\u0633 2026" },
      { id: "t2", name: "\u0633\u0644\u0637\u0627\u0646 \u0627\u0644\u062D\u0627\u0631\u062B\u064A", avatar: "\u0633.\u062D", color: "from-green-500 to-green-600", level: "4.0", sessions: 8, status: "\u0646\u0634\u0637", progress: 62, nextSession: "\u0627\u0644\u062C\u0645\u0639\u0629 7:00 \u0645", joinDate: "\u0623\u0628\u0631\u064A\u0644 2026" },
      { id: "t3", name: "\u0641\u064A\u0635\u0644 \u0627\u0644\u0645\u0627\u0644\u0643\u064A", avatar: "\u0641.\u0645", color: "from-orange-500 to-orange-600", level: "2.5", sessions: 20, status: "\u0646\u0634\u0637", progress: 90, nextSession: "\u0627\u0644\u062E\u0645\u064A\u0633 6:00 \u0645", joinDate: "\u064A\u0646\u0627\u064A\u0631 2026" },
      { id: "t4", name: "\u0646\u0627\u0635\u0631 \u0627\u0644\u0642\u0631\u0646\u064A", avatar: "\u0646.\u0642", color: "from-purple-500 to-purple-600", level: "3.0", sessions: 5, status: "\u0645\u0648\u0642\u0648\u0641 \u0645\u0624\u0642\u062A\u0627\u064B", progress: 35, nextSession: "\u2014", joinDate: "\u0645\u0627\u064A\u0648 2026" },
      { id: "t5", name: "\u0639\u0645\u0631 \u0627\u0644\u0634\u0647\u0631\u064A", avatar: "\u0639.\u0634", color: "from-red-500 to-red-600", level: "4.5", sessions: 30, status: "\u0646\u0634\u0637", progress: 95, nextSession: "\u0627\u0644\u0633\u0628\u062A 8:00 \u0645", joinDate: "\u062F\u064A\u0633\u0645\u0628\u0631 2025" },
      { id: "t6", name: "\u064A\u0648\u0633\u0641 \u0627\u0644\u0628\u0642\u0645\u064A", avatar: "\u064A.\u0628", color: "from-teal-500 to-teal-600", level: "3.5", sessions: 3, status: "\u062C\u062F\u064A\u062F", progress: 15, nextSession: "\u0627\u0644\u0627\u062B\u0646\u064A\u0646 4:00 \u0645", joinDate: "\u064A\u0648\u0646\u064A\u0648 2026" }
    ];
    const filtered = allTrainees.filter((t) => {
      const matchSearch = t.name.includes(traineeSearchQuery);
      const matchStatus = traineeStatusFilter === "\u0627\u0644\u0643\u0644" || t.status === traineeStatusFilter;
      return matchSearch && matchStatus;
    });
    const traineeDetail = allTrainees.find((t) => t.id === selectedTrainee);
    if (traineeDetail) {
      const sessionHistory = [
        { date: "2 \u064A\u0648\u0646\u064A\u0648 2026", type: "\u0641\u0631\u062F\u064A\u0629", duration: "60 \u062F\u0642\u064A\u0642\u0629", notes: "\u062A\u062D\u0633\u0646 \u0645\u0644\u062D\u0648\u0638 \u0641\u064A \u0627\u0644\u0636\u0631\u0628\u0629 \u0627\u0644\u062E\u0644\u0641\u064A\u0629", rating: 4 },
        { date: "28 \u0645\u0627\u064A\u0648 2026", type: "\u0641\u0631\u062F\u064A\u0629", duration: "60 \u062F\u0642\u064A\u0642\u0629", notes: "\u0627\u0644\u062A\u0631\u0643\u064A\u0632 \u0639\u0644\u0649 \u0627\u0644\u062E\u062F\u0645\u0629 \u0648\u0627\u0644\u0625\u0631\u062C\u0627\u0639", rating: 5 },
        { date: "24 \u0645\u0627\u064A\u0648 2026", type: "\u062C\u0645\u0627\u0639\u064A\u0629", duration: "90 \u062F\u0642\u064A\u0642\u0629", notes: "\u0623\u062F\u0627\u0621 \u062C\u064A\u062F \u0641\u064A \u0627\u0644\u062A\u0645\u0627\u0631\u064A\u0646 \u0627\u0644\u062C\u0645\u0627\u0639\u064A\u0629", rating: 4 },
        { date: "20 \u0645\u0627\u064A\u0648 2026", type: "\u0641\u0631\u062F\u064A\u0629", duration: "60 \u062F\u0642\u064A\u0642\u0629", notes: "\u062A\u0645\u0627\u0631\u064A\u0646 \u0639\u0644\u0649 \u0627\u0644\u062A\u062D\u0643\u0645 \u0641\u064A \u0627\u0644\u0643\u0631\u0629", rating: 3 }
      ];
      return <div className="flex-1 overflow-y-auto bg-gray-50">
          <div className="bg-gradient-to-br from-violet-700 to-violet-500 px-6 pt-8 pb-16">
            <div className="flex items-center gap-3 mb-6">
              <button onClick={() => setSelectedTrainee(null)} className="p-2 bg-white/20 rounded-full backdrop-blur-sm hover:bg-white/30 transition-colors">
                <ChevronRight className="w-5 h-5 text-white" />
              </button>
              <h1 className="text-white text-lg">تفاصيل المتدرب</h1>
            </div>
            <div className="flex items-center gap-4">
              <div className={`w-16 h-16 rounded-2xl bg-gradient-to-br ${traineeDetail.color} flex items-center justify-center text-white text-xl shadow-lg`}>
                {traineeDetail.avatar}
              </div>
              <div className="text-white">
                <p className="text-xl">{traineeDetail.name}</p>
                <p className="text-sm text-white/70">انضم {traineeDetail.joinDate}</p>
                <span className={`mt-1 inline-block px-3 py-0.5 text-xs rounded-full ${traineeDetail.status === "\u0646\u0634\u0637" ? "bg-green-400/30 text-green-100" : traineeDetail.status === "\u062C\u062F\u064A\u062F" ? "bg-blue-400/30 text-blue-100" : "bg-yellow-400/30 text-yellow-100"}`}>
                  {traineeDetail.status}
                </span>
              </div>
            </div>
          </div>

          <div className="-mt-8 px-4 pb-6 space-y-4">
            <div className="grid grid-cols-3 gap-3">
              {[
        { label: "\u0627\u0644\u062D\u0635\u0635", value: String(traineeDetail.sessions) },
        { label: "\u0627\u0644\u0645\u0633\u062A\u0648\u0649", value: traineeDetail.level },
        { label: "\u0627\u0644\u062A\u0642\u062F\u0645", value: `${traineeDetail.progress}%` }
      ].map((s) => <div key={s.label} className="bg-white rounded-2xl p-4 text-center shadow-sm">
                  <p className="text-2xl text-violet-600">{s.value}</p>
                  <p className="text-xs text-muted-foreground mt-1">{s.label}</p>
                </div>)}
            </div>

            <div className="bg-white rounded-2xl p-4 shadow-sm">
              <div className="flex items-center justify-between mb-2">
                <span className="text-sm text-secondary">مستوى التقدم</span>
                <span className="text-sm text-violet-600">{traineeDetail.progress}%</span>
              </div>
              <div className="h-3 bg-gray-100 rounded-full overflow-hidden">
                <div className="h-full bg-gradient-to-r from-violet-500 to-violet-400 rounded-full" style={{ width: `${traineeDetail.progress}%` }} />
              </div>
            </div>

            <div className="bg-white rounded-2xl p-4 shadow-sm flex items-center justify-between">
              <div>
                <p className="text-xs text-muted-foreground">الحصة القادمة</p>
                <p className="text-sm text-secondary mt-1">{traineeDetail.nextSession}</p>
              </div>
              <Calendar className="w-5 h-5 text-violet-500" />
            </div>

            <div className="bg-white rounded-2xl p-4 shadow-sm">
              <h3 className="text-sm text-secondary mb-3">سجل الحصص التدريبية</h3>
              <div className="space-y-3">
                {sessionHistory.map((s, i) => <div key={i} className="border-b border-border last:border-0 pb-3 last:pb-0">
                    <div className="flex items-center justify-between mb-1">
                      <span className="text-xs text-muted-foreground">{s.date}</span>
                      <div className="flex gap-0.5">
                        {[1, 2, 3, 4, 5].map((star) => <Star key={star} className={`w-3 h-3 ${star <= s.rating ? "text-yellow-400 fill-yellow-400" : "text-gray-200"}`} />)}
                      </div>
                    </div>
                    <div className="flex items-center gap-2 mb-1">
                      <span className="px-2 py-0.5 bg-violet-100 text-violet-600 text-xs rounded-full">حصة {s.type}</span>
                      <span className="text-xs text-muted-foreground">{s.duration}</span>
                    </div>
                    <p className="text-xs text-muted-foreground">{s.notes}</p>
                  </div>)}
              </div>
            </div>

            <div className="grid grid-cols-2 gap-3">
              <button className="bg-violet-600 text-white rounded-2xl p-4 flex flex-col items-center gap-2 shadow-sm">
                <Calendar className="w-5 h-5" />
                <span className="text-xs">جدولة حصة</span>
              </button>
              <button className="bg-white border border-border text-secondary rounded-2xl p-4 flex flex-col items-center gap-2 shadow-sm">
                <FileText className="w-5 h-5" />
                <span className="text-xs">تقرير تفصيلي</span>
              </button>
            </div>
          </div>
        </div>;
    }
    return <div className="flex-1 overflow-y-auto bg-gray-50">
        <div className="bg-gradient-to-br from-violet-700 to-violet-500 px-6 pt-8 pb-6">
          <div className="flex justify-between items-center mb-6">
            <button onClick={() => setCurrentView("coach-dashboard")} className="p-2 bg-white/20 rounded-full backdrop-blur-sm hover:bg-white/30 transition-colors">
              <ChevronRight className="w-5 h-5 text-white" />
            </button>
            <h1 className="text-white text-lg">إدارة المتدربين والتقارير</h1>
            <div className="w-9" />
          </div>

          <div className="grid grid-cols-3 gap-3">
            {[
      { label: "\u0625\u062C\u0645\u0627\u0644\u064A \u0627\u0644\u0645\u062A\u062F\u0631\u0628\u064A\u0646", value: "24" },
      { label: "\u0645\u062A\u062F\u0631\u0628\u0648\u0646 \u0646\u0634\u0637\u0648\u0646", value: "20" },
      { label: "\u0645\u062A\u062F\u0631\u0628\u0648\u0646 \u062C\u062F\u062F", value: "4" }
    ].map((stat) => <div key={stat.label} className="bg-white/10 backdrop-blur-sm rounded-xl p-3 text-center text-white">
                <p className="text-xl">{stat.value}</p>
                <p className="text-xs text-white/70 leading-tight mt-1">{stat.label}</p>
              </div>)}
          </div>
        </div>

        <div className="px-4 pt-4 pb-6 space-y-4">
          <div className="flex gap-2">
            <div className="flex-1">
              <input
      type="text"
      placeholder="ابحث عن متدرب..."
      value={traineeSearchQuery}
      onChange={(e) => setTraineeSearchQuery(e.target.value)}
      className="w-full bg-white border border-border rounded-xl px-4 py-2.5 text-sm shadow-sm"
    />
            </div>
            <div className="relative">
              <select
      value={traineeStatusFilter}
      onChange={(e) => setTraineeStatusFilter(e.target.value)}
      className="bg-white border border-border rounded-xl px-3 py-2.5 text-sm shadow-sm appearance-none pl-8"
    >
                {["\u0627\u0644\u0643\u0644", "\u0646\u0634\u0637", "\u0645\u0648\u0642\u0648\u0641 \u0645\u0624\u0642\u062A\u0627\u064B", "\u062C\u062F\u064A\u062F"].map((s) => <option key={s} value={s}>{s}</option>)}
              </select>
              <Filter className="w-4 h-4 text-muted-foreground absolute top-1/2 -translate-y-1/2 left-2 pointer-events-none" />
            </div>
          </div>

          <div className="bg-white rounded-2xl p-4 shadow-sm">
            <h3 className="text-sm text-secondary mb-3">ملخص التقارير — يونيو 2026</h3>
            <div className="grid grid-cols-2 gap-3">
              {[
      { label: "\u0625\u062C\u0645\u0627\u0644\u064A \u0627\u0644\u062D\u0635\u0635", value: "87", color: "text-violet-600" },
      { label: "\u0645\u0639\u062F\u0644 \u0627\u0644\u062D\u0636\u0648\u0631", value: "91%", color: "text-green-600" },
      { label: "\u0645\u062A\u0648\u0633\u0637 \u0627\u0644\u062A\u0642\u062F\u0645", value: "62%", color: "text-blue-600" },
      { label: "\u062D\u0635\u0635 \u0645\u0644\u063A\u0627\u0629", value: "8", color: "text-red-500" }
    ].map((item) => <div key={item.label} className="bg-gray-50 rounded-xl p-3">
                  <p className={`text-xl ${item.color}`}>{item.value}</p>
                  <p className="text-xs text-muted-foreground mt-0.5">{item.label}</p>
                </div>)}
            </div>
            <button className="mt-3 w-full flex items-center justify-center gap-2 py-2.5 border border-violet-200 text-violet-600 rounded-xl text-sm">
              <Download className="w-4 h-4" />
              تصدير التقرير الشهري
            </button>
          </div>

          <div className="space-y-3">
            <h3 className="text-sm text-secondary">قائمة المتدربين ({filtered.length})</h3>
            {filtered.map((trainee) => <button
      key={trainee.id}
      onClick={() => setSelectedTrainee(trainee.id)}
      className="w-full bg-white rounded-2xl p-4 shadow-sm flex items-center gap-3 text-right"
    >
                <div className={`w-12 h-12 rounded-xl bg-gradient-to-br ${trainee.color} flex items-center justify-center text-white text-sm flex-shrink-0`}>
                  {trainee.avatar}
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between mb-1">
                    <span className="text-sm text-secondary">{trainee.name}</span>
                    <span className={`text-xs px-2 py-0.5 rounded-full ${trainee.status === "\u0646\u0634\u0637" ? "bg-green-100 text-green-600" : trainee.status === "\u062C\u062F\u064A\u062F" ? "bg-blue-100 text-blue-600" : "bg-yellow-100 text-yellow-600"}`}>
                      {trainee.status}
                    </span>
                  </div>
                  <div className="flex items-center gap-3 text-xs text-muted-foreground mb-2">
                    <span>المستوى {trainee.level}</span>
                    <span>·</span>
                    <span>{trainee.sessions} حصة</span>
                    <span>·</span>
                    <span>{trainee.nextSession}</span>
                  </div>
                  <div className="h-1.5 bg-gray-100 rounded-full overflow-hidden">
                    <div className="h-full bg-gradient-to-r from-violet-500 to-violet-400 rounded-full" style={{ width: `${trainee.progress}%` }} />
                  </div>
                </div>
                <ChevronLeft className="w-4 h-4 text-muted-foreground flex-shrink-0" />
              </button>)}
            {filtered.length === 0 && <div className="text-center py-10 text-muted-foreground text-sm">لا يوجد متدربون مطابقون</div>}
          </div>
        </div>
      </div>;
  }
  if (currentView === "venue-revenue") {
    const MONTHS = [
      { key: "jun", label: "\u064A\u0648\u0646\u064A\u0648 2026" },
      { key: "may", label: "\u0645\u0627\u064A\u0648 2026" },
      { key: "apr", label: "\u0623\u0628\u0631\u064A\u0644 2026" },
      { key: "mar", label: "\u0645\u0627\u0631\u0633 2026" }
    ];
    const WEEKS = [
      { key: "w1", label: "\u0627\u0644\u0623\u0633\u0628\u0648\u0639 1 - 1-7 \u064A\u0648\u0646\u064A\u0648" },
      { key: "w2", label: "\u0627\u0644\u0623\u0633\u0628\u0648\u0639 2 - 8-14 \u064A\u0648\u0646\u064A\u0648" },
      { key: "w3", label: "\u0627\u0644\u0623\u0633\u0628\u0648\u0639 3 - 15-21 \u064A\u0648\u0646\u064A\u0648" },
      { key: "w4", label: "\u0627\u0644\u0623\u0633\u0628\u0648\u0639 4 - 22-30 \u064A\u0648\u0646\u064A\u0648" }
    ];
    const monthData = {
      jun: {
        total: "32,800",
        totalNum: 32800,
        sub: "+12% \u0639\u0646 \u0645\u0627\u064A\u0648",
        up: true,
        courtRevenue: [
          { name: "\u0645\u0644\u0639\u0628 1 - \u062F\u0627\u062E\u0644\u064A", total: "14,200", pct: 43, bookings: 38 },
          { name: "\u0645\u0644\u0639\u0628 2 - \u062E\u0627\u0631\u062C\u064A", total: "11,600", pct: 35, bookings: 31 },
          { name: "\u0645\u0644\u0639\u0628 3 - \u062F\u0627\u062E\u0644\u064A", total: "7,000", pct: 22, bookings: 19 }
        ],
        bars: [
          { label: "\u0627\u0644\u0623\u0633\u0628\u0648\u0639 1", val: 8400 },
          { label: "\u0627\u0644\u0623\u0633\u0628\u0648\u0639 2", val: 9200 },
          { label: "\u0627\u0644\u0623\u0633\u0628\u0648\u0639 3", val: 7600 },
          { label: "\u0627\u0644\u0623\u0633\u0628\u0648\u0639 4", val: 7600 }
        ],
        txs: [
          { id: "t1", court: "\u0645\u0644\u0639\u0628 1", time: "4:00 - 5:30 \u0645", player: "\u0623\u062D\u0645\u062F \u0627\u0644\u0632\u0647\u0631\u0627\u0646\u064A", amount: 180, type: "\u062D\u062C\u0632", date: "6 \u064A\u0648\u0646\u064A\u0648" },
          { id: "t2", court: "\u0645\u0644\u0639\u0628 2", time: "6:00 - 7:30 \u0645", player: "\u0633\u0639\u062F \u0627\u0644\u0645\u0637\u064A\u0631\u064A", amount: 150, type: "\u062D\u062C\u0632", date: "6 \u064A\u0648\u0646\u064A\u0648" },
          { id: "t3", court: "\u0645\u0644\u0639\u0628 1", time: "2:00 - 3:30 \u0645", player: "\u0641\u0647\u062F \u0627\u0644\u0642\u062D\u0637\u0627\u0646\u064A", amount: -180, type: "\u0625\u0644\u063A\u0627\u0621", date: "5 \u064A\u0648\u0646\u064A\u0648" },
          { id: "t4", court: "\u0645\u0644\u0639\u0628 3", time: "8:00 - 9:30 \u0645", player: "\u062E\u0627\u0644\u062F \u0627\u0644\u0639\u062A\u064A\u0628\u064A", amount: 200, type: "\u062D\u062C\u0632", date: "5 \u064A\u0648\u0646\u064A\u0648" },
          { id: "t5", court: "\u0645\u0644\u0639\u0628 2", time: "10:00 - 11:30 \u0635", player: "\u0645\u062D\u0645\u062F \u0627\u0644\u062F\u0648\u0633\u0631\u064A", amount: 130, type: "\u062D\u062C\u0632", date: "4 \u064A\u0648\u0646\u064A\u0648" }
        ]
      },
      may: {
        total: "29,300",
        totalNum: 29300,
        sub: "+5% \u0639\u0646 \u0623\u0628\u0631\u064A\u0644",
        up: true,
        courtRevenue: [
          { name: "\u0645\u0644\u0639\u0628 1 - \u062F\u0627\u062E\u0644\u064A", total: "12,400", pct: 42, bookings: 34 },
          { name: "\u0645\u0644\u0639\u0628 2 - \u062E\u0627\u0631\u062C\u064A", total: "10,100", pct: 34, bookings: 28 },
          { name: "\u0645\u0644\u0639\u0628 3 - \u062F\u0627\u062E\u0644\u064A", total: "6,800", pct: 24, bookings: 18 }
        ],
        bars: [
          { label: "\u0627\u0644\u0623\u0633\u0628\u0648\u0639 1", val: 7200 },
          { label: "\u0627\u0644\u0623\u0633\u0628\u0648\u0639 2", val: 8100 },
          { label: "\u0627\u0644\u0623\u0633\u0628\u0648\u0639 3", val: 6800 },
          { label: "\u0627\u0644\u0623\u0633\u0628\u0648\u0639 4", val: 7200 }
        ],
        txs: [
          { id: "m1", court: "\u0645\u0644\u0639\u0628 3", time: "5:00 - 6:30 \u0645", player: "\u0639\u0628\u062F\u0627\u0644\u0644\u0647 \u0627\u0644\u0633\u0628\u064A\u0639\u064A", amount: 200, type: "\u062D\u062C\u0632", date: "31 \u0645\u0627\u064A\u0648" },
          { id: "m2", court: "\u0645\u0644\u0639\u0628 1", time: "7:00 - 8:30 \u0645", player: "\u064A\u0648\u0633\u0641 \u0627\u0644\u062D\u0631\u0628\u064A", amount: 180, type: "\u062D\u062C\u0632", date: "30 \u0645\u0627\u064A\u0648" },
          { id: "m3", court: "\u0645\u0644\u0639\u0628 2", time: "4:00 - 5:30 \u0645", player: "\u0646\u0648\u0627\u0641 \u0627\u0644\u0639\u0645\u0631\u064A", amount: -150, type: "\u0625\u0644\u063A\u0627\u0621", date: "29 \u0645\u0627\u064A\u0648" },
          { id: "m4", court: "\u0645\u0644\u0639\u0628 1", time: "9:00 - 10:30 \u0635", player: "\u062A\u0631\u0643\u064A \u0627\u0644\u0634\u0647\u0631\u064A", amount: 180, type: "\u062D\u062C\u0632", date: "28 \u0645\u0627\u064A\u0648" }
        ]
      },
      apr: {
        total: "27,800",
        totalNum: 27800,
        sub: "-3% \u0639\u0646 \u0645\u0627\u0631\u0633",
        up: false,
        courtRevenue: [
          { name: "\u0645\u0644\u0639\u0628 1 - \u062F\u0627\u062E\u0644\u064A", total: "11,900", pct: 43, bookings: 32 },
          { name: "\u0645\u0644\u0639\u0628 2 - \u062E\u0627\u0631\u062C\u064A", total: "9,500", pct: 34, bookings: 26 },
          { name: "\u0645\u0644\u0639\u0628 3 - \u062F\u0627\u062E\u0644\u064A", total: "6,400", pct: 23, bookings: 17 }
        ],
        bars: [
          { label: "\u0627\u0644\u0623\u0633\u0628\u0648\u0639 1", val: 6500 },
          { label: "\u0627\u0644\u0623\u0633\u0628\u0648\u0639 2", val: 7400 },
          { label: "\u0627\u0644\u0623\u0633\u0628\u0648\u0639 3", val: 6900 },
          { label: "\u0627\u0644\u0623\u0633\u0628\u0648\u0639 4", val: 7e3 }
        ],
        txs: [
          { id: "a1", court: "\u0645\u0644\u0639\u0628 2", time: "6:00 - 7:30 \u0645", player: "\u0628\u062F\u0631 \u0627\u0644\u063A\u0627\u0645\u062F\u064A", amount: 150, type: "\u062D\u062C\u0632", date: "30 \u0623\u0628\u0631\u064A\u0644" },
          { id: "a2", court: "\u0645\u0644\u0639\u0628 1", time: "3:00 - 4:30 \u0645", player: "\u0635\u0627\u0644\u062D \u0627\u0644\u0645\u0627\u0644\u0643\u064A", amount: 180, type: "\u062D\u062C\u0632", date: "29 \u0623\u0628\u0631\u064A\u0644" },
          { id: "a3", court: "\u0645\u0644\u0639\u0628 3", time: "8:00 - 9:30 \u0645", player: "\u0645\u0627\u062C\u062F \u0627\u0644\u0639\u0633\u064A\u0631\u064A", amount: -200, type: "\u0625\u0644\u063A\u0627\u0621", date: "28 \u0623\u0628\u0631\u064A\u0644" }
        ]
      },
      mar: {
        total: "28,700",
        totalNum: 28700,
        sub: "+18% \u0639\u0646 \u0641\u0628\u0631\u0627\u064A\u0631",
        up: true,
        courtRevenue: [
          { name: "\u0645\u0644\u0639\u0628 1 - \u062F\u0627\u062E\u0644\u064A", total: "12,800", pct: 45, bookings: 35 },
          { name: "\u0645\u0644\u0639\u0628 2 - \u062E\u0627\u0631\u062C\u064A", total: "9,800", pct: 34, bookings: 27 },
          { name: "\u0645\u0644\u0639\u0628 3 - \u062F\u0627\u062E\u0644\u064A", total: "6,100", pct: 21, bookings: 16 }
        ],
        bars: [
          { label: "\u0627\u0644\u0623\u0633\u0628\u0648\u0639 1", val: 7100 },
          { label: "\u0627\u0644\u0623\u0633\u0628\u0648\u0639 2", val: 7900 },
          { label: "\u0627\u0644\u0623\u0633\u0628\u0648\u0639 3", val: 6500 },
          { label: "\u0627\u0644\u0623\u0633\u0628\u0648\u0639 4", val: 7200 }
        ],
        txs: [
          { id: "r1", court: "\u0645\u0644\u0639\u0628 1", time: "5:00 - 6:30 \u0645", player: "\u0648\u0644\u064A\u062F \u0627\u0644\u0632\u064A\u062F", amount: 180, type: "\u062D\u062C\u0632", date: "31 \u0645\u0627\u0631\u0633" },
          { id: "r2", court: "\u0645\u0644\u0639\u0628 3", time: "7:00 - 8:30 \u0645", player: "\u062D\u0645\u062F \u0627\u0644\u0631\u0648\u064A\u0644\u064A", amount: 200, type: "\u062D\u062C\u0632", date: "30 \u0645\u0627\u0631\u0633" },
          { id: "r3", court: "\u0645\u0644\u0639\u0628 2", time: "4:00 - 5:30 \u0645", player: "\u0641\u064A\u0635\u0644 \u0627\u0644\u0633\u0644\u0645\u064A", amount: -150, type: "\u0625\u0644\u063A\u0627\u0621", date: "29 \u0645\u0627\u0631\u0633" }
        ]
      }
    };
    const weekData = {
      w1: {
        total: "8,400",
        totalNum: 8400,
        sub: "+12% \u0639\u0646 \u0627\u0644\u0623\u0633\u0628\u0648\u0639 \u0627\u0644\u0645\u0627\u0636\u064A",
        up: true,
        courtRevenue: [
          { name: "\u0645\u0644\u0639\u0628 1 - \u062F\u0627\u062E\u0644\u064A", total: "3,600", pct: 43, bookings: 10 },
          { name: "\u0645\u0644\u0639\u0628 2 - \u062E\u0627\u0631\u062C\u064A", total: "2,940", pct: 35, bookings: 8 },
          { name: "\u0645\u0644\u0639\u0628 3 - \u062F\u0627\u062E\u0644\u064A", total: "1,860", pct: 22, bookings: 5 }
        ],
        bars: [
          { label: "\u0633\u0628\u062A", val: 1900 },
          { label: "\u0623\u062D\u062F", val: 1200 },
          { label: "\u0627\u062B\u0646", val: 980 },
          { label: "\u062B\u0644\u0627", val: 1450 },
          { label: "\u0623\u0631\u0628", val: 820 },
          { label: "\u062E\u0645\u064A", val: 1560 },
          { label: "\u062C\u0645\u0639", val: 490 }
        ],
        txs: [
          { id: "w1t1", court: "\u0645\u0644\u0639\u0628 1", time: "4:00 - 5:30 \u0645", player: "\u0623\u062D\u0645\u062F \u0627\u0644\u0632\u0647\u0631\u0627\u0646\u064A", amount: 180, type: "\u062D\u062C\u0632", date: "\u0627\u0644\u0633\u0628\u062A" },
          { id: "w1t2", court: "\u0645\u0644\u0639\u0628 2", time: "6:00 - 7:30 \u0645", player: "\u0633\u0639\u062F \u0627\u0644\u0645\u0637\u064A\u0631\u064A", amount: 150, type: "\u062D\u062C\u0632", date: "\u0627\u0644\u0633\u0628\u062A" },
          { id: "w1t3", court: "\u0645\u0644\u0639\u0628 1", time: "2:00 - 3:30 \u0645", player: "\u0641\u0647\u062F \u0627\u0644\u0642\u062D\u0637\u0627\u0646\u064A", amount: -180, type: "\u0625\u0644\u063A\u0627\u0621", date: "\u0627\u0644\u062C\u0645\u0639\u0629" },
          { id: "w1t4", court: "\u0645\u0644\u0639\u0628 3", time: "8:00 - 9:30 \u0645", player: "\u062E\u0627\u0644\u062F \u0627\u0644\u0639\u062A\u064A\u0628\u064A", amount: 200, type: "\u062D\u062C\u0632", date: "\u0627\u0644\u062E\u0645\u064A\u0633" }
        ]
      },
      w2: {
        total: "9,200",
        totalNum: 9200,
        sub: "+9.5% \u0639\u0646 \u0627\u0644\u0623\u0633\u0628\u0648\u0639 \u0627\u0644\u0633\u0627\u0628\u0642",
        up: true,
        courtRevenue: [
          { name: "\u0645\u0644\u0639\u0628 1 - \u062F\u0627\u062E\u0644\u064A", total: "4,000", pct: 43, bookings: 11 },
          { name: "\u0645\u0644\u0639\u0628 2 - \u062E\u0627\u0631\u062C\u064A", total: "3,200", pct: 35, bookings: 9 },
          { name: "\u0645\u0644\u0639\u0628 3 - \u062F\u0627\u062E\u0644\u064A", total: "2,000", pct: 22, bookings: 6 }
        ],
        bars: [
          { label: "\u0633\u0628\u062A", val: 2100 },
          { label: "\u0623\u062D\u062F", val: 1400 },
          { label: "\u0627\u062B\u0646", val: 1050 },
          { label: "\u062B\u0644\u0627", val: 1600 },
          { label: "\u0623\u0631\u0628", val: 900 },
          { label: "\u062E\u0645\u064A", val: 1700 },
          { label: "\u062C\u0645\u0639", val: 450 }
        ],
        txs: [
          { id: "w2t1", court: "\u0645\u0644\u0639\u0628 3", time: "5:00 - 6:30 \u0645", player: "\u0639\u0645\u0631 \u0627\u0644\u062D\u0627\u0631\u062B\u064A", amount: 200, type: "\u062D\u062C\u0632", date: "\u0627\u0644\u0633\u0628\u062A" },
          { id: "w2t2", court: "\u0645\u0644\u0639\u0628 1", time: "7:00 - 8:30 \u0645", player: "\u0631\u0627\u0634\u062F \u0627\u0644\u0623\u062D\u0645\u062F\u064A", amount: 180, type: "\u062D\u062C\u0632", date: "\u0627\u0644\u062C\u0645\u0639\u0629" },
          { id: "w2t3", court: "\u0645\u0644\u0639\u0628 2", time: "4:00 - 5:30 \u0645", player: "\u062C\u0627\u0633\u0645 \u0627\u0644\u0634\u0645\u0631\u064A", amount: -150, type: "\u0625\u0644\u063A\u0627\u0621", date: "\u0627\u0644\u0623\u0631\u0628\u0639\u0627\u0621" }
        ]
      },
      w3: {
        total: "7,600",
        totalNum: 7600,
        sub: "-17% \u0639\u0646 \u0627\u0644\u0623\u0633\u0628\u0648\u0639 \u0627\u0644\u0633\u0627\u0628\u0642",
        up: false,
        courtRevenue: [
          { name: "\u0645\u0644\u0639\u0628 1 - \u062F\u0627\u062E\u0644\u064A", total: "3,200", pct: 42, bookings: 9 },
          { name: "\u0645\u0644\u0639\u0628 2 - \u062E\u0627\u0631\u062C\u064A", total: "2,600", pct: 34, bookings: 7 },
          { name: "\u0645\u0644\u0639\u0628 3 - \u062F\u0627\u062E\u0644\u064A", total: "1,800", pct: 24, bookings: 5 }
        ],
        bars: [
          { label: "\u0633\u0628\u062A", val: 1600 },
          { label: "\u0623\u062D\u062F", val: 980 },
          { label: "\u0627\u062B\u0646", val: 820 },
          { label: "\u062B\u0644\u0627", val: 1300 },
          { label: "\u0623\u0631\u0628", val: 700 },
          { label: "\u062E\u0645\u064A", val: 1400 },
          { label: "\u062C\u0645\u0639", val: 800 }
        ],
        txs: [
          { id: "w3t1", court: "\u0645\u0644\u0639\u0628 2", time: "6:00 - 7:30 \u0645", player: "\u0646\u0627\u0635\u0631 \u0627\u0644\u0639\u0642\u064A\u0644", amount: 150, type: "\u062D\u062C\u0632", date: "\u0627\u0644\u0633\u0628\u062A" },
          { id: "w3t2", court: "\u0645\u0644\u0639\u0628 1", time: "3:00 - 4:30 \u0645", player: "\u0633\u0644\u0637\u0627\u0646 \u0627\u0644\u0642\u0631\u0646\u064A", amount: 180, type: "\u062D\u062C\u0632", date: "\u0627\u0644\u062E\u0645\u064A\u0633" }
        ]
      },
      w4: {
        total: "7,600",
        totalNum: 7600,
        sub: "= \u0645\u0633\u062A\u0648\u0649 \u0627\u0644\u0623\u0633\u0628\u0648\u0639 \u0627\u0644\u0633\u0627\u0628\u0642",
        up: true,
        courtRevenue: [
          { name: "\u0645\u0644\u0639\u0628 1 - \u062F\u0627\u062E\u0644\u064A", total: "3,300", pct: 43, bookings: 9 },
          { name: "\u0645\u0644\u0639\u0628 2 - \u062E\u0627\u0631\u062C\u064A", total: "2,700", pct: 36, bookings: 8 },
          { name: "\u0645\u0644\u0639\u0628 3 - \u062F\u0627\u062E\u0644\u064A", total: "1,600", pct: 21, bookings: 4 }
        ],
        bars: [
          { label: "\u0633\u0628\u062A", val: 1700 },
          { label: "\u0623\u062D\u062F", val: 1100 },
          { label: "\u0627\u062B\u0646", val: 900 },
          { label: "\u062B\u0644\u0627", val: 1350 },
          { label: "\u0623\u0631\u0628", val: 750 },
          { label: "\u062E\u0645\u064A", val: 1450 },
          { label: "\u062C\u0645\u0639", val: 350 }
        ],
        txs: [
          { id: "w4t1", court: "\u0645\u0644\u0639\u0628 1", time: "4:00 - 5:30 \u0645", player: "\u062D\u0633\u064A\u0646 \u0627\u0644\u063A\u0627\u0646\u0645", amount: 180, type: "\u062D\u062C\u0632", date: "\u0627\u0644\u0633\u0628\u062A" },
          { id: "w4t2", court: "\u0645\u0644\u0639\u0628 3", time: "7:00 - 8:30 \u0645", player: "\u0645\u0634\u0627\u0631\u064A \u0627\u0644\u062E\u0627\u0644\u062F", amount: 200, type: "\u062D\u062C\u0632", date: "\u0627\u0644\u062E\u0645\u064A\u0633" },
          { id: "w4t3", court: "\u0645\u0644\u0639\u0628 2", time: "5:00 - 6:30 \u0645", player: "\u0628\u0646\u062F\u0631 \u0627\u0644\u0633\u0639\u064A\u062F", amount: -150, type: "\u0625\u0644\u063A\u0627\u0621", date: "\u0627\u0644\u062B\u0644\u0627\u062B\u0627\u0621" }
        ]
      }
    };
    const activePeriodData = revPeriodType === "month" ? monthData[revSelectedMonth] : weekData[revSelectedWeek];
    const activePeriodLabel = revPeriodType === "month" ? MONTHS.find((m) => m.key === revSelectedMonth).label : WEEKS.find((w) => w.key === revSelectedWeek).label;
    const maxBar = Math.max(...activePeriodData.bars.map((b) => b.val));
    return <div className="flex-1 overflow-y-auto bg-background">
        {
      /* Header */
    }
        <div className="bg-gradient-to-br from-emerald-700 to-emerald-600 text-white px-6 pt-8 pb-6">
          <div className="flex justify-between items-start mb-5">
            <button onClick={() => setCurrentView("venue-dashboard")} className="p-2 bg-white/20 rounded-full backdrop-blur-sm hover:bg-white/30 transition-colors">
              <ChevronRight className="w-5 h-5" />
            </button>
            <div className="text-center">
              <h1 className="text-xl">تفاصيل الإيرادات</h1>
              <p className="text-xs text-white/70 mt-1">نادي البادل الملكي</p>
            </div>
            <button className="p-2 bg-white/20 rounded-full backdrop-blur-sm hover:bg-white/30 transition-colors">
              <Download className="w-5 h-5" />
            </button>
          </div>

          {
      /* Period Type Tabs */
    }
          <div className="flex bg-white/10 backdrop-blur-sm rounded-xl p-1 mb-4">
            {["month", "week"].map((t) => <button
      key={t}
      onClick={() => {
        setRevPeriodType(t);
        setRevShowPeriodPicker(false);
      }}
      className={`flex-1 py-2 rounded-lg text-sm transition-all ${revPeriodType === t ? "bg-white text-emerald-700" : "text-white/80 hover:text-white"}`}
    >
                {t === "month" ? "\u0634\u0647\u0631\u064A" : "\u0623\u0633\u0628\u0648\u0639\u064A"}
              </button>)}
          </div>

          {
      /* Period Selector Button */
    }
          <button
      onClick={() => setRevShowPeriodPicker(!revShowPeriodPicker)}
      className="w-full flex items-center justify-between bg-white/10 backdrop-blur-sm rounded-xl px-4 py-3 mb-4 hover:bg-white/20 transition-colors"
    >
            <ChevronDown className={`w-4 h-4 transition-transform ${revShowPeriodPicker ? "rotate-180" : ""}`} />
            <span className="text-sm">{activePeriodLabel}</span>
            <Calendar className="w-4 h-4 text-white/70" />
          </button>

          {
      /* Dropdown Picker */
    }
          {revShowPeriodPicker && <div className="bg-white rounded-xl overflow-hidden mb-4 shadow-lg">
              {(revPeriodType === "month" ? MONTHS : WEEKS).map((item) => {
      const isActive = revPeriodType === "month" ? revSelectedMonth === item.key : revSelectedWeek === item.key;
      return <button
        key={item.key}
        onClick={() => {
          if (revPeriodType === "month") setRevSelectedMonth(item.key);
          else setRevSelectedWeek(item.key);
          setRevShowPeriodPicker(false);
        }}
        className={`w-full text-right px-4 py-3 text-sm border-b border-gray-100 last:border-0 transition-colors ${isActive ? "bg-emerald-50 text-emerald-700" : "text-secondary hover:bg-gray-50"}`}
      >
                    {item.label}
                  </button>;
    })}
            </div>}

          {
      /* Total Revenue Hero */
    }
          <div className="bg-white/10 backdrop-blur-sm rounded-2xl p-5 text-center mb-4">
            <p className="text-white/70 text-sm mb-1">
              إجمالي إيرادات {revPeriodType === "month" ? "\u0627\u0644\u0634\u0647\u0631" : "\u0627\u0644\u0623\u0633\u0628\u0648\u0639"}
            </p>
            <p className="text-4xl mb-1">{activePeriodData.total}</p>
            <p className="text-white/80 text-sm">ريال سعودي</p>
            <div className="flex items-center justify-center gap-1 mt-2">
              {activePeriodData.up ? <ArrowUpRight className="w-4 h-4 text-emerald-300" /> : <ArrowDownRight className="w-4 h-4 text-red-300" />}
              <span className={`text-sm ${activePeriodData.up ? "text-emerald-300" : "text-red-300"}`}>{activePeriodData.sub}</span>
            </div>
          </div>
        </div>

        <div className="px-6 py-6 space-y-5">

          {
      /* Bar Chart */
    }
          <div className="bg-white border border-border rounded-2xl p-5 shadow-sm">
            <h2 className="text-base text-secondary flex items-center gap-2 mb-4">
              <BarChart2 className="w-5 h-5 text-emerald-600" />
              الإيرادات التفصيلية · {activePeriodLabel}
            </h2>
            <div className="flex items-end gap-2" style={{ height: "120px" }}>
              {activePeriodData.bars.map((b) => {
      const h = Math.round(b.val / maxBar * 100);
      return <div key={b.label} className="flex-1 flex flex-col items-center gap-1">
                    <span className="text-xs text-muted-foreground leading-none">
                      {b.val >= 1e3 ? (b.val / 1e3).toFixed(1) + "k" : b.val}
                    </span>
                    <div className="w-full relative bg-emerald-100 rounded-t-lg" style={{ height: "80px" }}>
                      <div
        className="absolute bottom-0 w-full rounded-t-lg bg-emerald-500 transition-all duration-500"
        style={{ height: `${h}%` }}
      />
                    </div>
                    <span className="text-xs text-muted-foreground leading-none">{b.label}</span>
                  </div>;
    })}
            </div>
          </div>

          {
      /* Revenue by Court */
    }
          <div className="bg-white border border-border rounded-2xl p-5 shadow-sm">
            <h2 className="text-base text-secondary flex items-center gap-2 mb-4">
              <TrendingUp className="w-5 h-5 text-emerald-600" />
              الإيرادات حسب الملعب
            </h2>
            <div className="space-y-4">
              {activePeriodData.courtRevenue.map((c, i) => <div key={c.name}>
                  <div className="flex items-center justify-between mb-1">
                    <div className="flex items-center gap-2">
                      <div className={`w-2 h-2 rounded-full ${i === 0 ? "bg-emerald-500" : i === 1 ? "bg-blue-500" : "bg-amber-500"}`} />
                      <span className="text-sm text-secondary">{c.name}</span>
                    </div>
                    <div className="text-left">
                      <span className="text-sm text-secondary">{c.total} ر.س</span>
                      <span className="text-xs text-muted-foreground mr-2">({c.bookings} حجز)</span>
                    </div>
                  </div>
                  <div className="w-full bg-gray-100 rounded-full h-2">
                    <div
      className={`h-2 rounded-full transition-all duration-500 ${i === 0 ? "bg-emerald-500" : i === 1 ? "bg-blue-500" : "bg-amber-500"}`}
      style={{ width: `${c.pct}%` }}
    />
                  </div>
                  <p className="text-xs text-muted-foreground mt-1">{c.pct}% من الإجمالي</p>
                </div>)}
            </div>
          </div>

          {
      /* Transactions */
    }
          <div className="bg-white border border-border rounded-2xl p-5 shadow-sm">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-base text-secondary flex items-center gap-2">
                <Filter className="w-5 h-5 text-emerald-600" />
                المعاملات · {activePeriodLabel}
              </h2>
              <span className="text-xs text-muted-foreground">{activePeriodData.txs.length} معاملة</span>
            </div>
            <div className="space-y-3">
              {activePeriodData.txs.map((tx) => <div key={tx.id} className={`flex items-center justify-between p-3 rounded-xl border ${tx.amount < 0 ? "bg-red-50 border-red-200" : "bg-gray-50 border-border"}`}>
                  <div className="flex items-center gap-3">
                    <div className={`w-10 h-10 rounded-full flex items-center justify-center flex-shrink-0 ${tx.amount < 0 ? "bg-red-100" : "bg-emerald-100"}`}>
                      {tx.amount < 0 ? <ArrowDownRight className="w-5 h-5 text-red-600" /> : <ArrowUpRight className="w-5 h-5 text-emerald-600" />}
                    </div>
                    <div>
                      <p className="text-sm text-secondary">{tx.court} · {tx.time}</p>
                      <p className="text-xs text-muted-foreground">{tx.player} · {tx.date}</p>
                    </div>
                  </div>
                  <div className="text-left">
                    <p className={`text-sm font-medium ${tx.amount < 0 ? "text-red-600" : "text-emerald-600"}`}>
                      {tx.amount < 0 ? "-" : "+"}{Math.abs(tx.amount)} ر.س
                    </p>
                    <span className={`text-xs px-2 py-0.5 rounded-full ${tx.amount < 0 ? "bg-red-100 text-red-600" : "bg-emerald-100 text-emerald-700"}`}>{tx.type}</span>
                  </div>
                </div>)}
            </div>
          </div>
        </div>
      </div>;
  }
  if (currentView === "top-up-wallet") {
    const currentBalance = userRoles.find((r) => r.type === "player" && r.completed) ? 250 : userRoles.find((r) => r.type === "coach" && r.completed) ? 3200 : 8400;
    return <TopUpWalletPage onBack={() => setCurrentView("roles")} currentBalance={currentBalance} onComplete={() => setCurrentView("roles")} />;
  }
  if (currentView === "roles") {
    const firstRole = userRoles[0];
    if (firstRole) {
      if (firstRole.type === "player") setCurrentView(firstRole.completed ? "player-dashboard" : "player-complete");
      else if (firstRole.type === "coach") setCurrentView(firstRole.completed ? "coach-dashboard" : "coach-complete");
      else if (firstRole.type === "venue") setCurrentView(firstRole.completed ? "venue-dashboard" : "venue-complete");
    }
    return null;
  }
  return <div className="flex-1 overflow-y-auto bg-background">
      <div className="px-6 py-6 space-y-4">
        <div className="bg-white border border-border rounded-2xl p-4 shadow-sm">
          <h2 className="text-lg text-secondary mb-4">الإعدادات العامة</h2>
          <div className="space-y-2">
            {
    /* تغيير اللغة */
  }
            <button onClick={() => setCurrentView("language")} className="w-full flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
                  <Languages className="w-5 h-5 text-primary" />
                </div>
                <div className="text-right">
                  <p className="text-sm text-secondary">تغيير اللغة</p>
                  <p className="text-xs text-muted-foreground">العربية</p>
                </div>
              </div>
              <ChevronLeft className="w-5 h-5 text-muted-foreground" />
            </button>

            {
    /* اتصل بنا */
  }
            <button onClick={() => setCurrentView("contact")} className="w-full flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
                  <MessageCircle className="w-5 h-5 text-primary" />
                </div>
                <div className="text-right">
                  <p className="text-sm text-secondary">اتصل بنا</p>
                  <p className="text-xs text-muted-foreground">واتساب، إيميل، دردشة</p>
                </div>
              </div>
              <ChevronLeft className="w-5 h-5 text-muted-foreground" />
            </button>

            {
    /* إعدادات الحساب */
  }
            <button onClick={() => setCurrentView("account-settings")} className="w-full flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
                  <Settings className="w-5 h-5 text-primary" />
                </div>
                <div className="text-right">
                  <p className="text-sm text-secondary">إعدادات الحساب</p>
                  <p className="text-xs text-muted-foreground">الجوال، الإيميل، كلمة المرور</p>
                </div>
              </div>
              <ChevronLeft className="w-5 h-5 text-muted-foreground" />
            </button>

            {
    /* الشروط والأحكام */
  }
            <button onClick={() => setCurrentView("terms")} className="w-full flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
                  <FileText className="w-5 h-5 text-primary" />
                </div>
                <div className="text-right">
                  <p className="text-sm text-secondary">الشروط والأحكام</p>
                  <p className="text-xs text-muted-foreground">الشروط القانونية للاستخدام</p>
                </div>
              </div>
              <ChevronLeft className="w-5 h-5 text-muted-foreground" />
            </button>

            {
    /* سياسة الخصوصية */
  }
            <button onClick={() => setCurrentView("privacy")} className="w-full flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
                  <Shield className="w-5 h-5 text-primary" />
                </div>
                <div className="text-right">
                  <p className="text-sm text-secondary">سياسة الخصوصية</p>
                  <p className="text-xs text-muted-foreground">حماية البيانات والخصوصية</p>
                </div>
              </div>
              <ChevronLeft className="w-5 h-5 text-muted-foreground" />
            </button>

            {
    /* سياسة الاسترجاع */
  }
            <button onClick={() => setCurrentView("refund")} className="w-full flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
                  <Wallet className="w-5 h-5 text-primary" />
                </div>
                <div className="text-right">
                  <p className="text-sm text-secondary">سياسة الاسترجاع</p>
                  <p className="text-xs text-muted-foreground">شروط استرجاع المبالغ</p>
                </div>
              </div>
              <ChevronLeft className="w-5 h-5 text-muted-foreground" />
            </button>

            {onLogout && <button
    onClick={onLogout}
    className="w-full flex items-center justify-between p-3 bg-red-50 rounded-lg hover:bg-red-100 transition-colors border border-red-200"
  >
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-red-100 rounded-full flex items-center justify-center">
                    <LogOut className="w-5 h-5 text-red-600" />
                  </div>
                  <div className="text-right">
                    <p className="text-sm text-red-600">تسجيل الخروج</p>
                    <p className="text-xs text-red-500">الخروج من الحساب</p>
                  </div>
                </div>
                <ChevronLeft className="w-5 h-5 text-red-400" />
              </button>}
          </div>
        </div>
      </div>

      {
    /* رسالة تحذير الحذف */
  }
      {showDeleteWarning && roleToDelete && <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          {
    /* خلفية معتمة */
  }
          <div
    className="absolute inset-0 bg-black/50 backdrop-blur-sm"
    onClick={cancelDelete}
  />

          {
    /* محتوى الرسالة */
  }
          <div className="relative bg-white rounded-2xl shadow-2xl max-w-md w-full mx-4 overflow-hidden animate-in fade-in zoom-in duration-200">
            {
    /* رأس الرسالة */
  }
            <div className="bg-gradient-to-br from-red-500 to-red-600 text-white px-6 py-5">
              <div className="flex items-center justify-between mb-2">
                <div className="flex items-center gap-3">
                  <div className="w-12 h-12 bg-white/20 rounded-full flex items-center justify-center backdrop-blur-sm">
                    <AlertTriangle className="w-6 h-6" />
                  </div>
                  <h2 className="text-xl font-bold">تحذير حذف الحساب</h2>
                </div>
                <button
    onClick={cancelDelete}
    className="p-1 hover:bg-white/20 rounded-lg transition-colors"
  >
                  <X className="w-5 h-5" />
                </button>
              </div>
            </div>

            {
    /* محتوى الرسالة */
  }
            <div className="px-6 py-6">
              <div className="mb-4">
                <p className="text-lg text-secondary font-medium mb-3">
                  هل أنت متأكد من حذف حساب <span className="text-red-600 font-bold">{getRoleName(roleToDelete)}</span>؟
                </p>

                <div className="bg-red-50 border-2 border-red-200 rounded-xl p-4 mb-4">
                  <div className="flex gap-3">
                    <AlertTriangle className="w-5 h-5 text-red-600 flex-shrink-0 mt-0.5" />
                    <div>
                      <p className="text-sm text-red-900 font-medium mb-2">
                        تنبيه مهم:
                      </p>
                      <p className="text-sm text-red-800 leading-relaxed">
                        عند حذفك للحساب سيتم <span className="font-bold">حذف جميع البيانات المتعلقة بالحساب</span> ولن يتم استرجاعها.
                      </p>
                    </div>
                  </div>
                </div>

                <div className="bg-gray-50 rounded-xl p-4 space-y-2">
                  <p className="text-sm text-secondary font-medium mb-2">سيتم حذف:</p>
                  <ul className="text-sm text-muted-foreground space-y-1.5">
                    <li className="flex items-center gap-2">
                      <div className="w-1.5 h-1.5 bg-red-500 rounded-full" />
                      <span>جميع المعلومات الشخصية</span>
                    </li>
                    <li className="flex items-center gap-2">
                      <div className="w-1.5 h-1.5 bg-red-500 rounded-full" />
                      <span>الإحصائيات والسجلات</span>
                    </li>
                    <li className="flex items-center gap-2">
                      <div className="w-1.5 h-1.5 bg-red-500 rounded-full" />
                      <span>الحجوزات والمباريات</span>
                    </li>
                    <li className="flex items-center gap-2">
                      <div className="w-1.5 h-1.5 bg-red-500 rounded-full" />
                      <span>جميع البيانات المرتبطة بالحساب</span>
                    </li>
                  </ul>
                </div>
              </div>

              {
    /* الأزرار */
  }
              <div className="flex gap-3 mt-6">
                <button
    onClick={cancelDelete}
    className="flex-1 py-3 px-4 bg-gray-100 text-secondary rounded-xl hover:bg-gray-200 transition-colors font-medium"
  >
                  إلغاء
                </button>
                <button
    onClick={confirmDelete}
    className="flex-1 py-3 px-4 bg-gradient-to-r from-red-500 to-red-600 text-white rounded-xl hover:from-red-600 hover:to-red-700 transition-all shadow-lg hover:shadow-xl font-medium"
  >
                  تأكيد الحذف
                </button>
              </div>
            </div>
          </div>
        </div>}

      {
    /* Language Settings */
  }
      {currentView === "language" && <LanguageSettings onBack={() => setCurrentView("roles")} />}

      {
    /* Contact Us */
  }
      {currentView === "contact" && <ContactUs
    onBack={() => setCurrentView("roles")}
    onNavigateToWhatsApp={() => setCurrentView("whatsapp")}
    onNavigateToChat={() => setCurrentView("live-chat")}
  />}

      {
    /* WhatsApp Contact */
  }
      {currentView === "whatsapp" && <WhatsAppContact onBack={() => setCurrentView("contact")} />}

      {
    /* Live Chat */
  }
      {currentView === "live-chat" && <LiveChat onBack={() => setCurrentView("contact")} />}

      {
    /* Account Settings */
  }
      {currentView === "account-settings" && <AccountSettings onBack={() => setCurrentView("roles")} />}

      {
    /* Terms and Conditions */
  }
      {currentView === "terms" && <TermsAndConditions onBack={() => setCurrentView("roles")} />}

      {
    /* Privacy Policy */
  }
      {currentView === "privacy" && <PrivacyPolicy onBack={() => setCurrentView("roles")} />}

      {
    /* Refund Policy */
  }
      {currentView === "refund" && <RefundPolicy onBack={() => setCurrentView("roles")} />}
    </div>;
}
export {
  ProfilePage as default
};
