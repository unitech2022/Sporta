import { ChevronRight, Check, Globe } from "lucide-react";
function LanguageSettings({ onBack }) {
  const currentLang = localStorage.getItem("appLanguage") || "ar";
  const isArabic = currentLang === "ar";
  const languages = [
    { code: "ar", name: isArabic ? "\u0627\u0644\u0639\u0631\u0628\u064A\u0629" : "Arabic", nativeName: "\u0627\u0644\u0639\u0631\u0628\u064A\u0629", flag: "\u{1F1F8}\u{1F1E6}", selected: currentLang === "ar" },
    { code: "en", name: isArabic ? "\u0627\u0644\u0625\u0646\u062C\u0644\u064A\u0632\u064A\u0629" : "English", nativeName: "English", flag: "\u{1F1EC}\u{1F1E7}", selected: currentLang === "en" }
  ];
  const handleLanguageChange = (code) => {
    localStorage.setItem("appLanguage", code);
    window.location.reload();
  };
  const texts = {
    ar: {
      title: "\u062A\u063A\u064A\u064A\u0631 \u0627\u0644\u0644\u063A\u0629",
      chooseLanguage: "\u0627\u062E\u062A\u0631 \u0627\u0644\u0644\u063A\u0629 \u0627\u0644\u0645\u0641\u0636\u0644\u0629",
      description: "\u0633\u064A\u062A\u0645 \u062A\u0637\u0628\u064A\u0642 \u0627\u0644\u0644\u063A\u0629 \u0627\u0644\u062C\u062F\u064A\u062F\u0629 \u0639\u0644\u0649 \u062C\u0645\u064A\u0639 \u0623\u062C\u0632\u0627\u0621 \u0627\u0644\u062A\u0637\u0628\u064A\u0642",
      note: "\u0645\u0644\u0627\u062D\u0638\u0629:",
      noteText: "\u0628\u0639\u062F \u062A\u063A\u064A\u064A\u0631 \u0627\u0644\u0644\u063A\u0629\u060C \u0633\u064A\u062A\u0645 \u0625\u0639\u0627\u062F\u0629 \u062A\u0634\u063A\u064A\u0644 \u0627\u0644\u062A\u0637\u0628\u064A\u0642 \u0644\u062A\u0637\u0628\u064A\u0642 \u0627\u0644\u062A\u063A\u064A\u064A\u0631\u0627\u062A."
    },
    en: {
      title: "Change Language",
      chooseLanguage: "Choose Your Preferred Language",
      description: "The new language will be applied to all parts of the app",
      note: "Note:",
      noteText: "After changing the language, the app will restart to apply the changes."
    }
  };
  const t = texts[currentLang];
  return <div className="flex-1 overflow-y-auto bg-background" dir={isArabic ? "rtl" : "ltr"}>
      {
    /* Header */
  }
      <div className="bg-gradient-to-br from-primary to-primary/90 text-white px-6 pt-8 pb-6">
        <div className="flex justify-between items-start mb-4">
          <button onClick={onBack} className="p-2 bg-white/20 rounded-full backdrop-blur-sm hover:bg-white/30 transition-colors">
            {isArabic ? <ChevronRight className="w-5 h-5" /> : <ChevronRight className="w-5 h-5 rotate-180" />}
          </button>
          <div className="text-center flex-1">
            <h1 className="text-xl">{t.title}</h1>
          </div>
          <div className="w-9" />
        </div>
      </div>

      <div className="px-6 py-6 space-y-4">
        <div className="bg-blue-50 border border-blue-200 rounded-2xl p-4 mb-4">
          <div className="flex items-start gap-3">
            <Globe className="w-5 h-5 text-blue-600 mt-0.5" />
            <div>
              <p className="text-sm text-secondary mb-1 font-medium">{t.chooseLanguage}</p>
              <p className="text-xs text-muted-foreground">{t.description}</p>
            </div>
          </div>
        </div>

        <div className="bg-white border border-border rounded-2xl overflow-hidden shadow-sm">
          {languages.map((language, index) => <button
    key={language.code}
    onClick={() => handleLanguageChange(language.code)}
    className={`w-full px-5 py-4 flex items-center justify-between transition-colors ${index !== languages.length - 1 ? "border-b border-border" : ""} ${language.selected ? "bg-primary/5" : "hover:bg-gray-50"}`}
  >
              <div className="flex items-center gap-4">
                <div className="text-4xl">
                  {language.flag}
                </div>
                <div className={isArabic ? "text-right" : "text-left"}>
                  <p className="text-sm text-secondary font-medium">{language.name}</p>
                  <p className="text-xs text-muted-foreground">{language.nativeName}</p>
                </div>
              </div>
              {language.selected && <div className="w-6 h-6 bg-primary rounded-full flex items-center justify-center">
                  <Check className="w-4 h-4 text-white" />
                </div>}
            </button>)}
        </div>

        <div className="bg-yellow-50 border border-yellow-200 rounded-2xl p-4">
          <p className="text-xs text-secondary">
            <span className="font-medium">{t.note}</span> {t.noteText}
          </p>
        </div>
      </div>
    </div>;
}
export {
  LanguageSettings as default
};
