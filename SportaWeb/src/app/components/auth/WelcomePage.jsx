import { UserPlus, LogIn, ArrowLeft, Languages } from "lucide-react";
import { useState } from "react";
import logo from "../../../imports/new_logo.png";
function WelcomePage({ onRegister, onLogin }) {
  const [currentLang, setCurrentLang] = useState(() => {
    return localStorage.getItem("appLanguage") || "ar";
  });
  const toggleLanguage = () => {
    const newLang = currentLang === "ar" ? "en" : "ar";
    localStorage.setItem("appLanguage", newLang);
    setCurrentLang(newLang);
    window.location.reload();
  };
  const isArabic = currentLang === "ar";
  const texts = {
    ar: {
      appTitle: "\u062A\u0637\u0628\u064A\u0642 \u062D\u062C\u0632 \u0648\u0625\u062F\u0627\u0631\u0629 \u0627\u0644\u0645\u0628\u0627\u0631\u064A\u0627\u062A",
      appSubtitle: "",
      createAccount: "\u0625\u0646\u0634\u0627\u0621 \u062D\u0633\u0627\u0628 \u062C\u062F\u064A\u062F",
      infoText: "\u{1F4A1} \u064A\u0645\u0643\u0646\u0643 \u0628\u0639\u062F \u0627\u0644\u062A\u0633\u062C\u064A\u0644 \u0627\u0644\u0623\u0648\u0644\u064A \u0645\u0646 \u0635\u0641\u062D\u062A\u0643 \u0623\u0646 \u062A\u0646\u0636\u0645 \u0643\u0644\u0627\u0639\u0628 \u0623\u0648 \u0645\u062F\u0631\u0628 \u0623\u0648 \u0645\u0644\u0639\u0628",
      haveAccount: "\u0644\u062F\u064A\u0643 \u062D\u0633\u0627\u0628 \u0628\u0627\u0644\u0641\u0639\u0644\u061F",
      login: "\u062A\u0633\u062C\u064A\u0644 \u0627\u0644\u062F\u062E\u0648\u0644"
    },
    en: {
      appTitle: "Padel Court Booking App",
      appSubtitle: "and Match Management",
      createAccount: "Create New Account",
      infoText: "\u{1F4A1} After initial registration, you can join as a player, coach, or venue from your profile",
      haveAccount: "Already have an account?",
      login: "Login"
    }
  };
  const t = texts[currentLang];
  return <div className="h-screen flex flex-col bg-gradient-to-br from-secondary to-secondary/90 text-white px-6" dir={isArabic ? "rtl" : "ltr"}>
      {
    /* Language Toggle Button */
  }
      <div className="pt-6 flex justify-end">
        <button
    onClick={toggleLanguage}
    className="flex items-center gap-2 px-4 py-2 bg-white/10 backdrop-blur-sm border border-white/20 rounded-full hover:bg-white/20 transition-all"
  >
          <Languages className="w-4 h-4" />
          <span className="text-sm font-medium">{currentLang === "ar" ? "English" : "\u0627\u0644\u0639\u0631\u0628\u064A\u0629"}</span>
        </button>
      </div>

      <div className="flex-1 flex flex-col justify-center">
        <div className="text-center mb-12">
          <div className="mb-8">
            <img
    src={logo}
    alt="SPORTA Logo"
    className="w-44 h-auto mx-auto"
    style={{ filter: "brightness(0) invert(1)" }}
  />
          </div>
          <div className="space-y-3">
            <p className="text-white/90 text-base tracking-wide">{t.appTitle}</p>
            <p className="text-white/70 text-sm">{t.appSubtitle}</p>
            <div className="pt-1">
              <span
    className="text-xl"
    style={{ fontFamily: "'El Messiri', sans-serif", color: "#f0c040", letterSpacing: "0.02em", fontSize: "1.4rem" }}
  >
                {isArabic ? "\u062A\u062C\u0631\u0628\u0629 \u0631\u064A\u0627\u0636\u064A\u0629 \u0645\u062A\u0643\u0627\u0645\u0644\u0629" : "A Complete Sports Experience"}
              </span>
            </div>
          </div>
        </div>

        <div className="space-y-4 max-w-md mx-auto w-full">
          <button
    onClick={onRegister}
    className="w-full bg-white text-secondary rounded-2xl p-5 flex items-center justify-center gap-3 hover:bg-white/95 transition-all shadow-2xl hover:shadow-3xl hover:scale-[1.02]"
  >
            <div className="w-12 h-12 bg-primary/10 rounded-full flex items-center justify-center">
              <UserPlus className="w-6 h-6 text-primary" />
            </div>
            <h3 className="text-xl font-medium">{t.createAccount}</h3>
          </button>

          <div className="bg-white/10 backdrop-blur-sm border border-white/20 rounded-2xl p-4">
            <p className="text-center text-sm text-white/90 leading-relaxed">
              {t.infoText}
            </p>
          </div>
        </div>
      </div>

      <div className="pb-8">
        <div className="max-w-md mx-auto w-full">
          <p className="text-white/70 text-sm mb-3 text-center">{t.haveAccount}</p>
          <button
    onClick={onLogin}
    className="w-full bg-white/10 backdrop-blur-sm border-2 border-white/30 text-white rounded-2xl p-4 flex items-center justify-center gap-3 hover:bg-white/20 hover:border-white/50 transition-all"
  >
            <LogIn className="w-5 h-5" />
            <span className="text-lg">{t.login}</span>
            {isArabic ? <ArrowLeft className="w-5 h-5" /> : <ArrowLeft className="w-5 h-5 rotate-180" />}
          </button>
        </div>
      </div>
    </div>;
}
export {
  WelcomePage as default
};
