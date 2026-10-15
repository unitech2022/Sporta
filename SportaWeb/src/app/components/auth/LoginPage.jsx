import { useState } from "react";
import { ChevronRight, Phone, Lock, Eye, EyeOff, Languages } from "lucide-react";
import logo from "../../../imports/new_logo.png";
function LoginPage({ onLoginSuccess, onBack }) {
  const [formData, setFormData] = useState({
    phone: "",
    password: ""
  });
  const [showPassword, setShowPassword] = useState(false);
  const [useBiometric, setUseBiometric] = useState(false);
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
      login: "\u062A\u0633\u062C\u064A\u0644 \u0627\u0644\u062F\u062E\u0648\u0644",
      welcomeBack: "\u0623\u0647\u0644\u0627\u064B \u0628\u0639\u0648\u062F\u062A\u0643!",
      phone: "\u0631\u0642\u0645 \u0627\u0644\u062C\u0648\u0627\u0644",
      password: "\u0643\u0644\u0645\u0629 \u0627\u0644\u0633\u0631",
      rememberMe: "\u062A\u0630\u0643\u0631\u0646\u064A",
      forgotPassword: "\u0646\u0633\u064A\u062A \u0643\u0644\u0645\u0629 \u0627\u0644\u0633\u0631\u061F",
      biometricTitle: "\u062A\u0641\u0639\u064A\u0644 \u062A\u0633\u062C\u064A\u0644 \u0627\u0644\u062F\u062E\u0648\u0644 \u0628\u0628\u0635\u0645\u0629 \u0627\u0644\u0648\u062C\u0647",
      biometricDesc: "\u0633\u064A\u062A\u0645 \u062D\u0641\u0638 \u0628\u064A\u0627\u0646\u0627\u062A\u0643 \u0628\u0634\u0643\u0644 \u0622\u0645\u0646 \u0644\u062A\u0633\u062C\u064A\u0644 \u0627\u0644\u062F\u062E\u0648\u0644 \u0627\u0644\u0633\u0631\u064A\u0639",
      loginButton: "\u062A\u0633\u062C\u064A\u0644 \u0627\u0644\u062F\u062E\u0648\u0644"
    },
    en: {
      login: "Login",
      welcomeBack: "Welcome Back!",
      phone: "Phone Number",
      password: "Password",
      rememberMe: "Remember Me",
      forgotPassword: "Forgot Password?",
      biometricTitle: "Enable Face ID Login",
      biometricDesc: "Your data will be securely saved for quick login",
      loginButton: "Login"
    }
  };
  const t = texts[currentLang];
  const handleLogin = () => {
    onLoginSuccess();
  };
  return <div className="h-screen flex flex-col bg-gradient-to-br from-secondary to-secondary/90" dir={isArabic ? "rtl" : "ltr"}>
      <div className="flex-1 overflow-y-auto px-6 py-8">
        {
    /* Header */
  }
        <div className="flex items-center justify-between mb-8">
          <div className="flex items-center gap-3">
            <button onClick={onBack} className="p-2 bg-white/20 rounded-full backdrop-blur-sm hover:bg-white/30 transition-colors">
              {isArabic ? <ChevronRight className="w-5 h-5 text-white" /> : <ChevronRight className="w-5 h-5 text-white rotate-180" />}
            </button>
            <h1 className="text-2xl text-white">{t.login}</h1>
          </div>
          <button
    onClick={toggleLanguage}
    className="flex items-center gap-2 px-3 py-2 bg-white/10 backdrop-blur-sm border border-white/20 rounded-full hover:bg-white/20 transition-all"
  >
            <Languages className="w-4 h-4 text-white" />
            <span className="text-sm text-white font-medium">{currentLang === "ar" ? "EN" : "\u0639"}</span>
          </button>
        </div>

        {
    /* Logo */
  }
        <div className="text-center mb-8">
          <img
    src={logo}
    alt="SPORTA Logo"
    className="w-24 h-auto mb-3 mx-auto"
    style={{ filter: "brightness(0) invert(1)" }}
  />
          <p className="text-white/80 text-sm">{t.welcomeBack}</p>
        </div>

        {
    /* Form Container */
  }
        <div className="space-y-4 max-w-md mx-auto">
          {
    /* Phone Input */
  }
          <div className="bg-white/95 backdrop-blur-sm border-2 border-white/30 rounded-2xl overflow-hidden focus-within:border-white transition-colors shadow-lg">
            <div className="flex items-center gap-3 px-4 py-4">
              <div className="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center flex-shrink-0">
                <Phone className="w-5 h-5 text-primary" />
              </div>
              <div className="flex-1">
                <label className="block text-xs text-muted-foreground mb-1">{t.phone}</label>
                <input
    type="tel"
    value={formData.phone}
    onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
    placeholder="05xxxxxxxx"
    className="w-full bg-transparent outline-none text-secondary placeholder-gray-400"
    dir="ltr"
  />
              </div>
            </div>
          </div>

          {
    /* Password Input */
  }
          <div className="bg-white/95 backdrop-blur-sm border-2 border-white/30 rounded-2xl overflow-hidden focus-within:border-white transition-colors shadow-lg">
            <div className="flex items-center gap-3 px-4 py-4">
              <div className="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center flex-shrink-0">
                <Lock className="w-5 h-5 text-primary" />
              </div>
              <div className="flex-1">
                <label className="block text-xs text-muted-foreground mb-1">{t.password}</label>
                <input
    type={showPassword ? "text" : "password"}
    value={formData.password}
    onChange={(e) => setFormData({ ...formData, password: e.target.value })}
    placeholder="••••••••"
    className="w-full bg-transparent outline-none text-secondary placeholder-gray-400"
  />
              </div>
              <button
    type="button"
    onClick={() => setShowPassword(!showPassword)}
    className="text-muted-foreground hover:text-secondary transition-colors flex-shrink-0"
  >
                {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
              </button>
            </div>
          </div>

          {
    /* Remember Me & Forgot Password */
  }
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <input
    type="checkbox"
    id="remember"
    className="w-4 h-4 accent-primary"
  />
              <label htmlFor="remember" className="text-sm text-white cursor-pointer">
                {t.rememberMe}
              </label>
            </div>
            <button className="text-sm text-white hover:underline">
              {t.forgotPassword}
            </button>
          </div>

          {
    /* Biometric Option */
  }
          <div className="bg-white/10 backdrop-blur-sm border border-white/20 rounded-xl p-4">
            <div className="flex items-start gap-3">
              <input
    type="checkbox"
    id="biometric"
    checked={useBiometric}
    onChange={(e) => setUseBiometric(e.target.checked)}
    className="mt-1 w-4 h-4 accent-primary"
  />
              <label htmlFor="biometric" className="text-sm text-white cursor-pointer flex-1">
                <span className="block mb-1">{t.biometricTitle}</span>
                <span className="text-xs text-white/70">
                  {t.biometricDesc}
                </span>
              </label>
            </div>
          </div>

          {
    /* Login Button */
  }
          <button
    onClick={handleLogin}
    disabled={!formData.phone || !formData.password}
    className={`w-full py-4 rounded-xl shadow-xl flex items-center justify-center gap-2 transition-all mt-6 ${formData.phone && formData.password ? "bg-primary text-white hover:bg-primary/90 hover:shadow-2xl" : "bg-white/10 border-2 border-white/20 cursor-not-allowed opacity-50 text-white"}`}
  >
            <span className="text-lg font-medium">{t.loginButton}</span>
          </button>
        </div>
      </div>
    </div>;
}
export {
  LoginPage as default
};
