import { useState } from "react";
import { Search, Filter, MapPin, Clock, Users, Plus, Trophy, Target, CheckCircle } from "lucide-react";
import Tooltip from "./Tooltip";
function MatchesPage({ onBack, onNavigate }) {
  const [activeTab, setActiveTab] = useState("matches");
  return <div className="flex-1 overflow-y-auto bg-background">
      <div className="bg-gradient-to-br from-secondary to-secondary/90 text-white px-6 pt-8 pb-6">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-3">
            <h1 className="text-2xl">المباريات</h1>
          </div>
          <button
    onClick={() => onNavigate && onNavigate(activeTab === "matches" ? "create-match" : "create-americano")}
    className="flex items-center gap-2 px-4 py-2 bg-primary text-white rounded-xl shadow-lg hover:bg-primary/90 transition-colors"
  >
            <Plus className="w-5 h-5" />
            <span className="text-sm">{activeTab === "matches" ? "\u0625\u0646\u0634\u0627\u0621 \u0645\u0628\u0627\u0631\u0627\u0629" : "\u0625\u0646\u0634\u0627\u0621 \u0623\u0645\u0631\u064A\u0643\u0627\u0646\u0648"}</span>
          </button>
        </div>

        {
    /* Tabs */
  }
        <div className="flex gap-2 mb-4">
          <button
    onClick={() => setActiveTab("matches")}
    className={`flex-1 py-3 rounded-xl transition-all flex items-center justify-center gap-2 ${activeTab === "matches" ? "bg-white text-primary shadow-lg" : "bg-white/20 text-white hover:bg-white/30"}`}
  >
            <Target className="w-5 h-5" />
            <span className="font-medium">مباريات مفتوحة</span>
          </button>
          <button
    onClick={() => setActiveTab("americano")}
    className={`flex-1 py-3 rounded-xl transition-all flex items-center justify-center gap-2 ${activeTab === "americano" ? "bg-white text-primary shadow-lg" : "bg-white/20 text-white hover:bg-white/30"}`}
  >
            <Trophy className="w-5 h-5" />
            <span className="font-medium">أمريكانو</span>
          </button>
        </div>

        <div className="relative">
          <Search className="absolute right-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
          <input
    type="text"
    placeholder={activeTab === "matches" ? "\u0627\u0628\u062D\u062B \u0639\u0646 \u0645\u0628\u0627\u0631\u0627\u0629..." : "\u0627\u0628\u062D\u062B \u0639\u0646 \u0623\u0645\u0631\u064A\u0643\u0627\u0646\u0648..."}
    className="w-full bg-white/95 backdrop-blur-sm text-gray-800 placeholder-gray-400 rounded-xl py-3 pr-11 pl-4 outline-none"
  />
        </div>
      </div>

      <div className="px-6 py-4">
        <div className="flex gap-2 mb-5 overflow-x-auto pb-2">
          <button className="px-4 py-2 bg-primary text-white rounded-full text-sm whitespace-nowrap flex-shrink-0">
            الكل
          </button>
          <Tooltip content="فلترة حسب المستوى" position="bottom">
            <button className="px-4 py-2 bg-white border border-border text-secondary rounded-full text-sm whitespace-nowrap flex-shrink-0">
              <Filter className="w-4 h-4 inline ml-1 text-primary" />
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
    /* محتوى المباريات المفتوحة */
  }
        {activeTab === "matches" && <div className="space-y-4">
          <div className="bg-gradient-to-br from-primary/5 to-primary/10 border-2 border-primary/30 rounded-2xl p-4">
            <div className="flex justify-between items-start mb-4">
              <div className="flex items-center gap-2 flex-wrap">
                <span className="px-3 py-1 bg-primary text-white text-xs rounded-full">متاحة الآن</span>
                <Tooltip content="مباراة تحدي للفرق (2 ضد 2)" position="bottom">
                  <span className="px-3 py-1 bg-purple-100 text-purple-600 text-xs rounded-full cursor-help">تحدي فرق</span>
                </Tooltip>
              </div>
              <Tooltip content="مستوى اللاعبين المطلوب" position="left">
                <span className="text-sm text-secondary whitespace-nowrap cursor-help">مستوى: 5.0 - 6.0</span>
              </Tooltip>
            </div>

            <div className="mb-4">
              <div className="flex items-center gap-2 mb-2">
                <MapPin className="w-4 h-4 text-primary" />
                <p className="text-sm text-secondary">نادي البادل الملكي</p>
              </div>
              <p className="text-xs text-muted-foreground mr-6">1.8 كم • ملعب خارجي</p>
            </div>

            <div className="flex items-center gap-3 mb-4">
              <div className="flex -space-x-2">
                <div className="w-10 h-10 bg-gradient-to-br from-primary to-primary/80 rounded-full border-2 border-white flex items-center justify-center">
                  <span className="text-white text-sm">4.5</span>
                </div>
                <div className="w-10 h-10 bg-gradient-to-br from-secondary to-secondary/80 rounded-full border-2 border-white flex items-center justify-center">
                  <span className="text-white text-sm">4.2</span>
                </div>
                <div className="w-10 h-10 bg-dashed border-2 border-dashed border-primary rounded-full flex items-center justify-center">
                  <Users className="w-5 h-5 text-primary" />
                </div>
              </div>
              <div className="text-xs text-muted-foreground">يحتاج لاعبين (2)</div>
            </div>

            <div className="flex items-center justify-between pt-3 border-t border-primary/20">
              <div className="flex items-center gap-2">
                <Clock className="w-4 h-4 text-primary" />
                <span className="text-sm text-secondary">اليوم، 6:00 مساءً</span>
              </div>
              <button
    onClick={() => onNavigate && onNavigate("join-match", "\u062A\u062D\u062F\u064A \u0641\u0631\u0642")}
    className="px-5 py-2 bg-primary text-white rounded-lg shadow-md"
  >
                انضم الآن
              </button>
            </div>
          </div>

          <div className="bg-white border border-border rounded-2xl p-4 shadow-sm">
            <div className="flex justify-between items-start mb-4">
              <div className="flex items-center gap-2 flex-wrap">
                <span className="px-3 py-1 bg-orange-100 text-orange-600 text-xs rounded-full">يحتاج لاعب واحد</span>
                <Tooltip content="مباراة ودية فردية (كل لاعب لوحده)" position="bottom">
                  <span className="px-3 py-1 bg-blue-100 text-blue-600 text-xs rounded-full cursor-help">ودية فردي</span>
                </Tooltip>
              </div>
              <Tooltip content="مستوى اللاعبين المطلوب" position="left">
                <span className="text-sm text-secondary whitespace-nowrap cursor-help">مستوى: 4.5 - 5.5</span>
              </Tooltip>
            </div>

            <div className="mb-4">
              <div className="flex items-center gap-2 mb-2">
                <MapPin className="w-4 h-4 text-primary" />
                <p className="text-sm text-secondary">ملعب الأندية الشرقية</p>
              </div>
              <p className="text-xs text-muted-foreground mr-6">3.2 كم • ملعب داخلي</p>
            </div>

            <div className="flex items-center gap-3 mb-4">
              <div className="flex items-center gap-2">
                <div className="w-10 h-10 bg-gradient-to-br from-primary to-primary/80 rounded-full flex items-center justify-center">
                  <span className="text-white text-sm">3.8</span>
                </div>
                <span className="text-xs text-muted-foreground">vs</span>
                <div className="w-10 h-10 bg-gradient-to-br from-secondary to-secondary/80 rounded-full flex items-center justify-center">
                  <span className="text-white text-sm">4.1</span>
                </div>
                <span className="text-xs text-muted-foreground">vs</span>
                <div className="w-10 h-10 bg-gradient-to-br from-orange-500 to-orange-600 rounded-full flex items-center justify-center">
                  <span className="text-white text-sm">4.3</span>
                </div>
                <span className="text-xs text-muted-foreground">vs</span>
                <div className="w-10 h-10 bg-gray-300 rounded-full flex items-center justify-center">
                  <span className="text-white text-sm">?</span>
                </div>
              </div>
            </div>
            <p className="text-xs text-muted-foreground mb-4">مباراة فردية (4 لاعبين) • يحتاج لاعب واحد</p>

            <div className="flex items-center justify-between pt-3 border-t border-border">
              <div className="flex items-center gap-2">
                <Clock className="w-4 h-4 text-primary" />
                <span className="text-sm text-secondary">غداً، 7:30 مساءً</span>
              </div>
              <button
    onClick={() => onNavigate && onNavigate("join-match", "\u0648\u062F\u064A\u0629 \u0641\u0631\u062F\u064A")}
    className="px-5 py-2 bg-primary text-white rounded-lg"
  >
                انضم الآن
              </button>
            </div>
          </div>

          <div className="bg-white border border-border rounded-2xl p-4 shadow-sm">
            <div className="flex justify-between items-start mb-4">
              <div className="flex items-center gap-2 flex-wrap">
                <span className="px-3 py-1 bg-green-100 text-green-600 text-xs rounded-full">متاحة</span>
                <Tooltip content="مباراة ودية للفرق (2 ضد 2)" position="bottom">
                  <span className="px-3 py-1 bg-teal-100 text-teal-600 text-xs rounded-full cursor-help">ودية فرق</span>
                </Tooltip>
              </div>
              <Tooltip content="مستوى اللاعبين المطلوب" position="left">
                <span className="text-sm text-secondary whitespace-nowrap cursor-help">مستوى: 3.5 - 4.5</span>
              </Tooltip>
            </div>

            <div className="mb-4">
              <div className="flex items-center gap-2 mb-2">
                <MapPin className="w-4 h-4 text-primary" />
                <p className="text-sm text-secondary">نادي الرياضة للبادل</p>
              </div>
              <p className="text-xs text-muted-foreground mr-6">4.5 كم • ملعب خارجي</p>
            </div>

            <div className="flex items-center gap-3 mb-4">
              <div className="flex -space-x-2">
                <div className="w-10 h-10 bg-gradient-to-br from-primary to-primary/80 rounded-full border-2 border-white flex items-center justify-center">
                  <span className="text-white text-sm">3.5</span>
                </div>
                <div className="w-10 h-10 bg-gradient-to-br from-secondary to-secondary/80 rounded-full border-2 border-white flex items-center justify-center">
                  <span className="text-white text-sm">3.9</span>
                </div>
              </div>
              <div className="text-xs text-muted-foreground">يحتاج فريق (2)</div>
            </div>

            <div className="flex items-center justify-between pt-3 border-t border-border">
              <div className="flex items-center gap-2">
                <Clock className="w-4 h-4 text-primary" />
                <span className="text-sm text-secondary">بعد غد، 5:30 مساءً</span>
              </div>
              <button
    onClick={() => onNavigate && onNavigate("join-match", "\u0648\u062F\u064A\u0629 \u0641\u0631\u0642")}
    className="px-5 py-2 bg-primary text-white rounded-lg"
  >
                انضم الآن
              </button>
            </div>
          </div>

          {
    /* ودية فردي - مكتملة */
  }
          <div
    className="bg-gradient-to-br from-blue-50 to-blue-100/30 border-2 border-blue-300 rounded-2xl p-4 shadow-sm cursor-pointer hover:shadow-md transition-shadow"
    onClick={() => onNavigate && onNavigate("match-result", "\u0648\u062F\u064A\u0629 \u0641\u0631\u062F\u064A")}
  >
            <div className="flex justify-between items-start mb-4">
              <div className="flex items-center gap-2 flex-wrap">
                <span className="px-3 py-1 bg-blue-500 text-white text-xs rounded-full flex items-center gap-1">
                  <CheckCircle className="w-3 h-3" />مكتملة 4/4
                </span>
                <span className="px-3 py-1 bg-blue-100 text-blue-600 text-xs rounded-full">ودية فردي</span>
              </div>
              <span className="text-sm text-secondary whitespace-nowrap">مستوى: 4.5 - 5.5</span>
            </div>

            <div className="mb-3">
              <div className="flex items-center gap-2 mb-1">
                <MapPin className="w-4 h-4 text-blue-500" />
                <p className="text-sm text-secondary">ملعب الأندية الشرقية</p>
              </div>
              <p className="text-xs text-muted-foreground mr-6">3.2 كم • ملعب داخلي</p>
            </div>

            {
    /* اللاعبون الأربعة */
  }
            <div className="flex items-center gap-2 mb-3">
              {[
    { av: "\u0645.\u0623", level: "5.0", color: "from-primary to-primary/80" },
    { av: "\u0639.\u0633", level: "4.8", color: "from-blue-500 to-blue-600" },
    { av: "\u0641.\u0639", level: "5.2", color: "from-purple-500 to-purple-600" },
    { av: "\u0628.\u062D", level: "4.6", color: "from-orange-500 to-orange-600" }
  ].map((p, i) => <div key={i} className="flex flex-col items-center gap-0.5">
                  <div className={`w-10 h-10 bg-gradient-to-br ${p.color} rounded-full flex items-center justify-center`}>
                    <span className="text-white text-xs">{p.av}</span>
                  </div>
                  <span className="text-xs text-muted-foreground">{p.level}</span>
                </div>)}
              <div className="mr-1">
                <p className="text-xs text-blue-600">جاهزة لإدخال النتيجة</p>
                <p className="text-xs text-muted-foreground">مباراة فردية (4 لاعبين)</p>
              </div>
            </div>

            <div className="flex items-center justify-between pt-3 border-t border-blue-200">
              <div className="flex items-center gap-2">
                <Clock className="w-4 h-4 text-blue-500" />
                <span className="text-sm text-secondary">اليوم، 7:30 مساءً</span>
              </div>
              <button
    onClick={(e) => {
      e.stopPropagation();
      onNavigate && onNavigate("match-result", "\u0648\u062F\u064A\u0629 \u0641\u0631\u062F\u064A");
    }}
    className="px-5 py-2 bg-blue-500 text-white rounded-lg flex items-center gap-1.5 shadow-sm hover:bg-blue-600 transition-colors"
  >
                <CheckCircle className="w-4 h-4" />
                مكتملة
              </button>
            </div>
          </div>

          <div
    className="bg-gradient-to-br from-green-50 to-green-100/30 border-2 border-green-300 rounded-2xl p-4 shadow-sm cursor-pointer hover:shadow-md transition-shadow"
    onClick={() => onNavigate && onNavigate("match-result", "\u062A\u062D\u062F\u064A \u0641\u0631\u0642")}
  >
            <div className="flex justify-between items-start mb-4">
              <div className="flex items-center gap-2 flex-wrap">
                <span className="px-3 py-1 bg-green-500 text-white text-xs rounded-full flex items-center gap-1">
                  <CheckCircle className="w-3 h-3" />مكتملة 4/4
                </span>
                <Tooltip content="مباراة تحدي للفرق (2 ضد 2)" position="bottom">
                  <span className="px-3 py-1 bg-purple-100 text-purple-600 text-xs rounded-full cursor-help">تحدي فرق</span>
                </Tooltip>
              </div>
              <span className="text-sm text-secondary whitespace-nowrap">مستوى: 5.0 - 6.0</span>
            </div>

            <div className="mb-4">
              <div className="flex items-center gap-2 mb-2">
                <MapPin className="w-4 h-4 text-green-600" />
                <p className="text-sm text-secondary">نادي النخبة للبادل</p>
              </div>
              <p className="text-xs text-muted-foreground mr-6">2.1 كم • ملعب داخلي</p>
            </div>

            <div className="flex items-center gap-3 mb-4">
              <div className="flex -space-x-2">
                {["\u0623.\u0632", "\u0633.\u0645", "\u062E.\u0639", "\u0641.\u0633"].map((av, i) => <div key={i} className={`w-10 h-10 rounded-full border-2 border-white flex items-center justify-center text-white text-xs ${i < 2 ? "bg-gradient-to-br from-primary to-primary/80" : "bg-gradient-to-br from-secondary to-secondary/80"}`}>{av}</div>)}
              </div>
              <div className="text-xs text-green-600">جاهزة لإدخال النتيجة</div>
            </div>

            <div className="flex items-center justify-between pt-3 border-t border-green-200">
              <div className="flex items-center gap-2">
                <Clock className="w-4 h-4 text-green-600" />
                <span className="text-sm text-secondary">اليوم، 5:00 مساءً</span>
              </div>
              <button
    onClick={(e) => {
      e.stopPropagation();
      onNavigate && onNavigate("match-result", "\u062A\u062D\u062F\u064A \u0641\u0631\u0642");
    }}
    className="px-5 py-2 bg-green-500 text-white rounded-lg flex items-center gap-1.5 shadow-sm hover:bg-green-600 transition-colors"
  >
                <CheckCircle className="w-4 h-4" />
                مكتملة
              </button>
            </div>
          </div>
          </div>}

        {
    /* محتوى أمريكانو */
  }
        {activeTab === "americano" && <div className="space-y-4">
            <div className="bg-gradient-to-br from-yellow-50 to-yellow-100/50 border-2 border-yellow-400/50 rounded-2xl p-4">
              <div className="flex justify-between items-start mb-4">
                <div className="flex items-center gap-2 flex-wrap">
                  <span className="px-3 py-1 bg-yellow-500 text-white text-xs rounded-full">جاري التسجيل</span>
                  <span className="px-3 py-1 bg-purple-100 text-purple-600 text-xs rounded-full">أمريكانو فرق</span>
                </div>
                <Tooltip content="مستوى اللاعبين المطلوب" position="left">
                  <span className="text-sm text-secondary whitespace-nowrap cursor-help">مستوى: 5.0 - 6.5</span>
                </Tooltip>
              </div>

              <div className="mb-4">
                <div className="flex items-center gap-2 mb-2">
                  <MapPin className="w-4 h-4 text-yellow-600" />
                  <p className="text-sm text-secondary font-medium">أمريكانو البادل الملكي</p>
                </div>
                <p className="text-xs text-muted-foreground mr-6">نادي البادل الملكي • 1.8 كم</p>
              </div>

              <div className="bg-white/60 rounded-xl p-3 mb-4">
                <div className="grid grid-cols-2 gap-3 text-center">
                  <div>
                    <p className="text-xs text-muted-foreground mb-1">المسجلين</p>
                    <p className="text-lg font-bold text-yellow-600">8 / 12</p>
                  </div>
                  <div>
                    <p className="text-xs text-muted-foreground mb-1">الملاعب</p>
                    <p className="text-lg font-bold text-yellow-600">3 ملاعب</p>
                  </div>
                </div>
              </div>

              <div className="flex items-center justify-between pt-3 border-t border-yellow-300">
                <div className="flex items-center gap-2">
                  <Clock className="w-4 h-4 text-yellow-600" />
                  <span className="text-sm text-secondary">اليوم، 6:00 مساءً</span>
                </div>
                <button
    onClick={() => onNavigate && onNavigate("join-americano")}
    className="px-5 py-2 bg-yellow-500 text-white rounded-lg shadow-md hover:bg-yellow-600 transition-colors"
  >
                  انضم الآن
                </button>
              </div>
            </div>

            <div className="bg-white border border-border rounded-2xl p-4 shadow-sm">
              <div className="flex justify-between items-start mb-4">
                <div className="flex items-center gap-2 flex-wrap">
                  <span className="px-3 py-1 bg-green-100 text-green-600 text-xs rounded-full">متاح</span>
                  <span className="px-3 py-1 bg-blue-100 text-blue-600 text-xs rounded-full">أمريكانو فردي</span>
                </div>
                <Tooltip content="مستوى اللاعبين المطلوب" position="left">
                  <span className="text-sm text-secondary whitespace-nowrap cursor-help">مستوى: 4.0 - 5.0</span>
                </Tooltip>
              </div>

              <div className="mb-4">
                <div className="flex items-center gap-2 mb-2">
                  <MapPin className="w-4 h-4 text-primary" />
                  <p className="text-sm text-secondary font-medium">أمريكانو الأندية الشرقية</p>
                </div>
                <p className="text-xs text-muted-foreground mr-6">ملعب الأندية الشرقية • 3.2 كم</p>
              </div>

              <div className="bg-gray-50 rounded-xl p-3 mb-4">
                <div className="grid grid-cols-2 gap-3 text-center">
                  <div>
                    <p className="text-xs text-muted-foreground mb-1">المسجلين</p>
                    <p className="text-lg font-bold text-primary">4 / 16</p>
                  </div>
                  <div>
                    <p className="text-xs text-muted-foreground mb-1">الملاعب</p>
                    <p className="text-lg font-bold text-primary">4 ملاعب</p>
                  </div>
                </div>
              </div>

              <div className="flex items-center justify-between pt-3 border-t border-border">
                <div className="flex items-center gap-2">
                  <Clock className="w-4 h-4 text-primary" />
                  <span className="text-sm text-secondary">غداً، 5:00 مساءً</span>
                </div>
                <button
    onClick={() => onNavigate && onNavigate("join-americano")}
    className="px-5 py-2 bg-primary text-white rounded-lg"
  >
                  انضم
                </button>
              </div>
            </div>

            <div className="bg-white border border-border rounded-2xl p-4 shadow-sm">
              <div className="flex justify-between items-start mb-4">
                <div className="flex items-center gap-2 flex-wrap">
                  <span className="px-3 py-1 bg-orange-100 text-orange-600 text-xs rounded-full">أماكن محدودة</span>
                  <span className="px-3 py-1 bg-purple-100 text-purple-600 text-xs rounded-full">أمريكانو فرق</span>
                </div>
                <Tooltip content="مستوى اللاعبين المطلوب" position="left">
                  <span className="text-sm text-secondary whitespace-nowrap cursor-help">مستوى: 3.5 - 4.5</span>
                </Tooltip>
              </div>

              <div className="mb-4">
                <div className="flex items-center gap-2 mb-2">
                  <MapPin className="w-4 h-4 text-primary" />
                  <p className="text-sm text-secondary font-medium">أمريكانو الرياضة</p>
                </div>
                <p className="text-xs text-muted-foreground mr-6">نادي الرياضة للبادل • 4.5 كم</p>
              </div>

              <div className="bg-gray-50 rounded-xl p-3 mb-4">
                <div className="grid grid-cols-2 gap-3 text-center">
                  <div>
                    <p className="text-xs text-muted-foreground mb-1">المسجلين</p>
                    <p className="text-lg font-bold text-orange-600">10 / 12</p>
                  </div>
                  <div>
                    <p className="text-xs text-muted-foreground mb-1">الملاعب</p>
                    <p className="text-lg font-bold text-primary">3 ملاعب</p>
                  </div>
                </div>
              </div>

              <div className="flex items-center justify-between pt-3 border-t border-border">
                <div className="flex items-center gap-2">
                  <Clock className="w-4 h-4 text-primary" />
                  <span className="text-sm text-secondary">بعد غد، 7:00 مساءً</span>
                </div>
                <button
    onClick={() => onNavigate && onNavigate("join-americano")}
    className="px-5 py-2 bg-primary text-white rounded-lg"
  >
                  انضم
                </button>
              </div>
            </div>

            {
    /* أمريكانو فرق - مكتمل */
  }
            <div
    className="bg-gradient-to-br from-purple-50 to-purple-100/30 border-2 border-purple-300 rounded-2xl p-4 shadow-sm cursor-pointer hover:shadow-md transition-shadow"
    onClick={() => onNavigate && onNavigate("match-result", "\u0623\u0645\u0631\u064A\u0643\u0627\u0646\u0648 \u0641\u0631\u0642")}
  >
              <div className="flex justify-between items-start mb-4">
                <div className="flex items-center gap-2 flex-wrap">
                  <span className="px-3 py-1 bg-purple-600 text-white text-xs rounded-full flex items-center gap-1">
                    <CheckCircle className="w-3 h-3" />مكتمل 8/8
                  </span>
                  <span className="px-3 py-1 bg-purple-100 text-purple-600 text-xs rounded-full">أمريكانو فرق</span>
                </div>
                <span className="text-sm text-secondary whitespace-nowrap">مستوى: 4.5 - 5.5</span>
              </div>

              <div className="mb-3">
                <div className="flex items-center gap-2 mb-1">
                  <MapPin className="w-4 h-4 text-purple-600" />
                  <p className="text-sm text-secondary">نادي البادل الملكي</p>
                </div>
                <p className="text-xs text-muted-foreground mr-6">1.8 كم • ملعبان داخليان</p>
              </div>

              {
    /* الفرق الأربعة */
  }
              <div className="grid grid-cols-2 gap-2 mb-3">
                {[
    { name: "\u0627\u0644\u0635\u0642\u0648\u0631", avs: ["\u0623.\u0632", "\u0633.\u0645"], colors: ["from-primary to-primary/80", "from-blue-500 to-blue-600"] },
    { name: "\u0627\u0644\u0646\u0633\u0648\u0631", avs: ["\u062E.\u0639", "\u0639.\u0634"], colors: ["from-purple-500 to-purple-600", "from-indigo-500 to-indigo-600"] },
    { name: "\u0627\u0644\u0623\u0633\u0648\u062F", avs: ["\u0641.\u0639", "\u0645.\u0633"], colors: ["from-orange-500 to-orange-600", "from-red-500 to-red-600"] },
    { name: "\u0627\u0644\u0646\u0645\u0648\u0631", avs: ["\u0628.\u062D", "\u0641.\u062F"], colors: ["from-teal-500 to-teal-600", "from-green-500 to-green-600"] }
  ].map((team, ti) => <div key={ti} className="flex items-center gap-1.5 bg-white/70 rounded-xl px-2 py-1.5 border border-purple-200">
                    <div className="flex -space-x-1.5">
                      {team.avs.map((av, i) => <div key={i} className={`w-7 h-7 bg-gradient-to-br ${team.colors[i]} rounded-full border border-white flex items-center justify-center`}>
                          <span className="text-white text-[9px]">{av}</span>
                        </div>)}
                    </div>
                    <span className="text-xs text-secondary truncate">{team.name}</span>
                  </div>)}
              </div>

              <div className="flex items-center justify-between pt-3 border-t border-purple-200">
                <div className="flex items-center gap-2">
                  <Clock className="w-4 h-4 text-purple-600" />
                  <span className="text-sm text-secondary">اليوم، 6:00 مساءً</span>
                </div>
                <button
    onClick={(e) => {
      e.stopPropagation();
      onNavigate && onNavigate("match-result", "\u0623\u0645\u0631\u064A\u0643\u0627\u0646\u0648 \u0641\u0631\u0642");
    }}
    className="px-5 py-2 bg-purple-600 text-white rounded-lg flex items-center gap-1.5 shadow-sm hover:bg-purple-700 transition-colors"
  >
                  <CheckCircle className="w-4 h-4" />
                  مكتمل
                </button>
              </div>
            </div>

            {
    /* أمريكانو فردي - مكتمل */
  }
            <div
    className="bg-gradient-to-br from-teal-50 to-cyan-100/30 border-2 border-teal-300 rounded-2xl p-4 shadow-sm cursor-pointer hover:shadow-md transition-shadow"
    onClick={() => onNavigate && onNavigate("match-result", "\u0623\u0645\u0631\u064A\u0643\u0627\u0646\u0648 \u0641\u0631\u062F\u064A")}
  >
              <div className="flex justify-between items-start mb-4">
                <div className="flex items-center gap-2 flex-wrap">
                  <span className="px-3 py-1 bg-teal-600 text-white text-xs rounded-full flex items-center gap-1">
                    <CheckCircle className="w-3 h-3" />مكتمل 8/8
                  </span>
                  <span className="px-3 py-1 bg-teal-100 text-teal-700 text-xs rounded-full">أمريكانو فردي</span>
                </div>
                <span className="text-sm text-secondary whitespace-nowrap">مستوى: 3.5 - 5.2</span>
              </div>

              <div className="mb-3">
                <div className="flex items-center gap-2 mb-1">
                  <MapPin className="w-4 h-4 text-teal-600" />
                  <p className="text-sm text-secondary">نادي النخبة للبادل</p>
                </div>
                <p className="text-xs text-muted-foreground mr-6">2.1 كم • ملعبان داخليان</p>
              </div>

              {
    /* اللاعبون الثمانية */
  }
              <div className="flex flex-wrap gap-1.5 mb-3">
                {[
    { av: "\u0623.\u0632", color: "from-primary to-primary/80" },
    { av: "\u0633.\u0645", color: "from-blue-500 to-blue-600" },
    { av: "\u0639.\u0634", color: "from-purple-500 to-purple-600" },
    { av: "\u0641.\u0633", color: "from-green-500 to-green-600" },
    { av: "\u062E.\u0639", color: "from-orange-500 to-orange-600" },
    { av: "\u0645.\u0633", color: "from-teal-500 to-teal-600" },
    { av: "\u0641.\u0639", color: "from-red-400 to-red-500" },
    { av: "\u0628.\u062D", color: "from-indigo-500 to-indigo-600" }
  ].map((p, i) => <div key={i} className={`w-8 h-8 bg-gradient-to-br ${p.color} rounded-full border border-white flex items-center justify-center`}>
                    <span className="text-white text-[9px]">{p.av}</span>
                  </div>)}
              </div>

              <div className="flex items-center justify-between pt-3 border-t border-teal-200">
                <div className="flex items-center gap-2">
                  <Clock className="w-4 h-4 text-teal-600" />
                  <span className="text-sm text-secondary">اليوم، 4:00 مساءً</span>
                </div>
                <button
    onClick={(e) => {
      e.stopPropagation();
      onNavigate && onNavigate("match-result", "\u0623\u0645\u0631\u064A\u0643\u0627\u0646\u0648 \u0641\u0631\u062F\u064A");
    }}
    className="px-5 py-2 bg-teal-600 text-white rounded-lg flex items-center gap-1.5 shadow-sm hover:bg-teal-700 transition-colors"
  >
                  <CheckCircle className="w-4 h-4" />مكتمل
                </button>
              </div>
            </div>
          </div>}
      </div>

      <div className="px-6 pb-6">
        <button
    onClick={() => onNavigate && onNavigate(activeTab === "matches" ? "create-match" : "create-americano")}
    className="w-full py-4 bg-gradient-to-r from-primary to-primary/90 text-white rounded-xl shadow-lg flex items-center justify-center gap-2"
  >
          {activeTab === "matches" ? <>
              <Users className="w-5 h-5" />
              أنشئ مباراة جديدة
            </> : <>
              <Trophy className="w-5 h-5" />
              أنشئ أمريكانو جديد
            </>}
        </button>
      </div>
    </div>;
}
export {
  MatchesPage as default
};
