import { useState } from "react";
import WelcomePage from "./WelcomePage";
import LanguageSelection from "./LanguageSelection";
import UnifiedRegistration from "./UnifiedRegistration";
import LoginPage from "./LoginPage";
import SportsSelectionPage from "./SportsSelectionPage";
import { CheckCircle } from "lucide-react";
const calculateLevel = (formData) => {
  const answers = [
    formData.rallyAbility,
    formData.glassUsage,
    formData.skillDescription,
    formData.netPlay,
    formData.comparisonLevel
  ];
  let score = 0;
  const options = [
    ["\u0623\u0642\u0644 \u0645\u0646 5 \u0636\u0631\u0628\u0627\u062A \u0645\u062A\u062A\u0627\u0644\u064A\u0629", "5 \u0625\u0644\u0649 10 \u0636\u0631\u0628\u0627\u062A", "10 \u0625\u0644\u0649 20 \u0636\u0631\u0628\u0629", "\u0623\u0643\u062B\u0631 \u0645\u0646 20 \u0636\u0631\u0628\u0629 \u0628\u0633\u0647\u0648\u0644\u0629"],
    ["\u0644\u0627 \u0623\u0633\u062A\u062E\u062F\u0645 \u0627\u0644\u0632\u062C\u0627\u062C \u0623\u0648 \u0644\u0627 \u0623\u0639\u0631\u0641 \u0643\u064A\u0641\u064A\u0629 \u0627\u0644\u0644\u0639\u0628 \u0628\u0647", "\u0623\u062A\u0639\u0627\u0645\u0644 \u0645\u0639 \u0627\u0644\u0643\u0631\u0627\u062A \u0627\u0644\u0633\u0647\u0644\u0629 \u0628\u0639\u062F \u0627\u0644\u0627\u0631\u062A\u062F\u0627\u062F", "\u0623\u0633\u062A\u062E\u062F\u0645 \u0627\u0644\u0632\u062C\u0627\u062C \u0628\u0634\u0643\u0644 \u062C\u064A\u062F \u062F\u0641\u0627\u0639\u064A\u0627\u064B", "\u0623\u0633\u062A\u062E\u062F\u0645 \u0627\u0644\u0632\u062C\u0627\u062C \u0628\u0645\u0647\u0627\u0631\u0629 \u062F\u0641\u0627\u0639\u064A\u0627\u064B \u0648\u0647\u062C\u0648\u0645\u064A\u0627\u064B"],
    ["\u0645\u0627 \u0632\u0644\u062A \u0623\u062A\u0639\u0644\u0645 \u0623\u0633\u0627\u0633\u064A\u0627\u062A \u0627\u0644\u0644\u0639\u0628\u0629", "\u0623\u0644\u0639\u0628 \u0645\u0628\u0627\u0631\u064A\u0627\u062A \u062A\u0631\u0641\u064A\u0647\u064A\u0629 \u0628\u0634\u0643\u0644 \u0645\u0646\u062A\u0638\u0645", "\u0623\u0641\u0648\u0632 \u063A\u0627\u0644\u0628\u0627\u064B \u0639\u0644\u0649 \u0627\u0644\u0644\u0627\u0639\u0628\u064A\u0646 \u0627\u0644\u0645\u062A\u0648\u0633\u0637\u064A\u0646", "\u0623\u0634\u0627\u0631\u0643 \u0623\u0648 \u0623\u0633\u062A\u0637\u064A\u0639 \u0627\u0644\u0645\u0646\u0627\u0641\u0633\u0629 \u0641\u064A \u0627\u0644\u0628\u0637\u0648\u0644\u0627\u062A"],
    ["\u0623\u0641\u0636\u0644 \u0627\u0644\u0628\u0642\u0627\u0621 \u0641\u064A \u0627\u0644\u062E\u0644\u0641", "\u0623\u062A\u0642\u062F\u0645 \u0644\u0644\u0634\u0628\u0643\u0629 \u0623\u062D\u064A\u0627\u0646\u0627\u064B", "\u0623\u062A\u062D\u0643\u0645 \u0641\u064A \u0627\u0644\u0634\u0628\u0643\u0629 \u0645\u0639\u0638\u0645 \u0627\u0644\u0648\u0642\u062A", "\u0623\u062C\u064A\u062F \u0625\u0646\u0647\u0627\u0621 \u0627\u0644\u0646\u0642\u0627\u0637 \u0645\u0646 \u0627\u0644\u0634\u0628\u0643\u0629 \u0648\u0623\u062A\u062D\u0643\u0645 \u0628\u0627\u0644\u0645\u0628\u0627\u0631\u0627\u0629"],
    ["\u0623\u0642\u0644 \u0645\u0646 \u0627\u0644\u0645\u062A\u0648\u0633\u0637", "\u0645\u062A\u0648\u0633\u0637", "\u0641\u0648\u0642 \u0627\u0644\u0645\u062A\u0648\u0633\u0637", "\u0645\u0646 \u0623\u0641\u0636\u0644 \u0627\u0644\u0644\u0627\u0639\u0628\u064A\u0646 \u0627\u0644\u0630\u064A\u0646 \u0623\u0644\u0639\u0628 \u0645\u0639\u0647\u0645"]
  ];
  answers.forEach((answer, index) => {
    const answerIndex = options[index].indexOf(answer);
    if (answerIndex !== -1) {
      score += answerIndex + 1;
    }
  });
  const averageScore = score / 5;
  if (averageScore <= 1.5) return { level: "3.5", range: "3.0 - 4.0", name: "\u0645\u0628\u062A\u062F\u0626", elo: 1200 };
  if (averageScore <= 2.5) return { level: "4.5", range: "4.0 - 5.0", name: "\u0645\u062A\u0648\u0633\u0637", elo: 1400 };
  if (averageScore <= 3.5) return { level: "5.5", range: "5.0 - 6.0", name: "\u0645\u062A\u0642\u062F\u0645", elo: 1600 };
  return { level: "6.5", range: "6.0 - 7.0", name: "\u0645\u062D\u062A\u0631\u0641", elo: 1800 };
};
function AuthFlow({ onLoginSuccess } = {}) {
  const [stage, setStage] = useState("welcome");
  const [language, setLanguage] = useState(null);
  const [registrationData, setRegistrationData] = useState(null);
  const handleGoToRegister = () => {
    setStage("language");
  };
  const handleSelectLanguage = (lang) => {
    setLanguage(lang);
    setStage("registration");
  };
  const handleRegistrationComplete = (data) => {
    if (data) {
      setRegistrationData(data);
    }
    setStage("success");
  };
  const handleBackToWelcome = () => {
    setStage("welcome");
    setLanguage(null);
    setRegistrationData(null);
  };
  const handleBackFromLanguageToWelcome = () => {
    setStage("welcome");
    setLanguage(null);
  };
  const handleGoToLogin = () => {
    setStage("login");
  };
  const handleLoginSuccess = () => {
    setStage("sports-selection");
  };
  const handleSportsSelectionContinue = () => {
    if (onLoginSuccess) {
      onLoginSuccess();
    }
  };
  const handleBackFromLogin = () => {
    setStage("welcome");
  };
  if (stage === "welcome") {
    return <WelcomePage onRegister={handleGoToRegister} onLogin={handleGoToLogin} />;
  }
  if (stage === "login") {
    return <LoginPage onLoginSuccess={handleLoginSuccess} onBack={handleBackFromLogin} />;
  }
  if (stage === "sports-selection") {
    return <SportsSelectionPage onContinue={handleSportsSelectionContinue} />;
  }
  if (stage === "language") {
    return <LanguageSelection onSelectLanguage={handleSelectLanguage} onBack={handleBackFromLanguageToWelcome} />;
  }
  if (stage === "registration") {
    return <UnifiedRegistration
      onComplete={handleRegistrationComplete}
      onBack={handleBackFromLanguageToWelcome}
    />;
  }
  if (stage === "success") {
    return <div className="h-screen flex flex-col bg-background px-6">
        <div className="flex-1 flex flex-col justify-center items-center text-center">
          <div className="w-24 h-24 bg-green-100 rounded-full flex items-center justify-center mb-6 animate-bounce">
            <CheckCircle className="w-12 h-12 text-green-600" />
          </div>

          <h1 className="text-3xl text-secondary mb-3">مرحباً بك في SPORTA!</h1>

          <p className="text-muted-foreground mb-6 max-w-md">
            تم إنشاء حسابك بنجاح 🎉
          </p>

          {registrationData && registrationData.roles && <div className="bg-gradient-to-br from-primary/10 to-primary/5 border-2 border-primary/30 rounded-2xl p-6 mb-6 max-w-md">
              <h3 className="text-secondary mb-4 text-center">أدوارك في التطبيق</h3>
              <div className="flex justify-center gap-2 flex-wrap mb-4">
                {registrationData.roles.map((role) => <span key={role} className="px-4 py-2 bg-primary text-white rounded-full text-sm">
                    {role === "player" ? "\u{1F3BE} \u0644\u0627\u0639\u0628" : role === "coach" ? "\u{1F3C6} \u0645\u062F\u0631\u0628" : "\u{1F3DF}\uFE0F \u0645\u0627\u0644\u0643 \u0645\u0644\u0639\u0628"}
                  </span>)}
              </div>
              <div className="bg-white/50 rounded-lg p-3">
                <p className="text-xs text-muted-foreground text-center">
                  💡 يمكنك التبديل بين الأدوار في أي وقت من القائمة الرئيسية
                </p>
              </div>
            </div>}

          <div className="bg-white border border-border rounded-2xl p-5 mb-6 max-w-md">
            <h3 className="text-secondary mb-3 text-center">الخطوات التالية</h3>
            <ul className="space-y-2 text-sm text-muted-foreground text-right">
              {registrationData?.roles.includes("player") && <li className="flex items-start gap-2">
                  <span className="text-primary">✓</span>
                  <span>أكمل معلومات اللاعب وحدد مستواك</span>
                </li>}
              {registrationData?.roles.includes("coach") && <li className="flex items-start gap-2">
                  <span className="text-primary">✓</span>
                  <span>أضف شهاداتك وتخصصاتك التدريبية</span>
                </li>}
              {registrationData?.roles.includes("venue") && <li className="flex items-start gap-2">
                  <span className="text-primary">✓</span>
                  <span>أضف تفاصيل ملعبك والمرافق المتوفرة</span>
                </li>}
              <li className="flex items-start gap-2">
                <span className="text-primary">✓</span>
                <span>استكشف الملاعب والمباريات القريبة منك</span>
              </li>
            </ul>
          </div>

          <button
      onClick={() => onLoginSuccess && onLoginSuccess()}
      className="w-full max-w-md py-4 bg-gradient-to-r from-primary to-primary/90 text-white rounded-xl shadow-lg mb-3"
    >
            ابدأ الآن
          </button>
        </div>
      </div>;
  }
  return null;
}
export {
  AuthFlow as default
};
