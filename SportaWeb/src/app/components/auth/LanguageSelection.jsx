import { Check, ChevronRight } from "lucide-react";
import logo from "../../../imports/new_logo.png";
function LanguageSelection({ onSelectLanguage, onBack }) {
  return <div className="h-screen flex flex-col bg-background px-6">
      <div className="pt-8 pb-4">
        {onBack && <button
    onClick={onBack}
    className="p-2 bg-gray-100 rounded-full hover:bg-gray-200 transition-colors"
  >
            <ChevronRight className="w-5 h-5 text-secondary" />
          </button>}
      </div>

      <div className="flex-1 flex flex-col justify-center">
        <div className="text-center mb-12">
          <img
    src={logo}
    alt="SPORTA Logo"
    className="w-32 h-auto mx-auto mb-6"
  />
          <h1 className="text-3xl text-secondary mb-3">اختر اللغة</h1>
          <h2 className="text-2xl text-secondary/70 mb-2">Choose Language</h2>
          <p className="text-muted-foreground text-sm">يمكنك تغيير اللغة في أي وقت من الإعدادات</p>
        </div>

        <div className="space-y-4 max-w-md mx-auto w-full">
          <button
    onClick={() => onSelectLanguage("ar")}
    className="w-full bg-white border-2 border-primary text-secondary rounded-2xl p-6 flex items-center justify-between hover:bg-primary/5 transition-all shadow-sm"
  >
            <div className="flex items-center gap-4">
              <div className="text-4xl">🇸🇦</div>
              <div className="text-right">
                <h3 className="text-xl mb-1">العربية</h3>
                <p className="text-sm text-muted-foreground">Arabic</p>
              </div>
            </div>
            <div className="w-6 h-6 bg-primary rounded-full flex items-center justify-center">
              <Check className="w-4 h-4 text-white" />
            </div>
          </button>

          <button
    onClick={() => onSelectLanguage("en")}
    className="w-full bg-white border-2 border-border text-secondary rounded-2xl p-6 flex items-center justify-between hover:border-primary/50 hover:bg-gray-50 transition-all shadow-sm"
  >
            <div className="flex items-center gap-4">
              <div className="text-4xl">🇬🇧</div>
              <div className="text-right">
                <h3 className="text-xl mb-1">English</h3>
                <p className="text-sm text-muted-foreground">الإنجليزية</p>
              </div>
            </div>
            <div className="w-6 h-6 border-2 border-border rounded-full" />
          </button>
        </div>
      </div>

      <div className="pb-8">
        <div className="w-16 h-1 bg-primary rounded-full mx-auto" />
        <p className="text-center text-xs text-muted-foreground mt-2">خطوة 1 من 4</p>
      </div>
    </div>;
}
export {
  LanguageSelection as default
};
