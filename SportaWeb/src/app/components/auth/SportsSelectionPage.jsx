function SportsSelectionPage({ onContinue }) {
  return <div className="h-screen flex flex-col bg-gradient-to-br from-[#0a0a1a] via-[#0f1a2e] to-[#0a1628] text-white overflow-hidden" dir="rtl">
      {
    /* Decorative background elements */
  }
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div className="absolute -top-20 -right-20 w-64 h-64 bg-primary/10 rounded-full blur-3xl" />
        <div className="absolute top-1/3 -left-20 w-48 h-48 bg-purple-500/10 rounded-full blur-3xl" />
        <div className="absolute bottom-20 right-1/4 w-56 h-56 bg-blue-500/10 rounded-full blur-3xl" />
        {
    /* Stars */
  }
        {[...Array(20)].map((_, i) => <div
    key={i}
    className="absolute rounded-full bg-white"
    style={{
      width: i % 3 === 0 ? "2px" : "1px",
      height: i % 3 === 0 ? "2px" : "1px",
      top: `${5 + i * 13.7 % 80}%`,
      left: `${3 + i * 17.3 % 94}%`,
      opacity: 0.3 + i % 4 * 0.15
    }}
  />)}
      </div>

      <div className="relative flex-1 flex flex-col justify-center px-6">
        {
    /* Header */
  }
        <div className="text-center mb-10">
          <div className="inline-flex items-center gap-2 bg-white/10 backdrop-blur-sm border border-white/20 rounded-full px-4 py-2 mb-6">
            <span className="w-2 h-2 bg-primary rounded-full animate-pulse" />
            <span className="text-xs text-white/80">اختر رياضتك المفضلة</span>
          </div>
          <h1 className="text-2xl text-white mb-2">مرحباً بك في SPORTA</h1>
          <p className="text-white/50 text-sm">لكل رياضة تجربة مخصصة في التطبيق</p>
        </div>

        {
    /* Sport Cards */
  }
        <div className="grid grid-cols-2 gap-4 mb-6">
          {
    /* Padel */
  }
          <button
    onClick={onContinue}
    className="group relative bg-gradient-to-br from-primary/20 to-primary/5 border border-primary/30 rounded-3xl p-6 flex flex-col items-center gap-3 hover:border-primary/60 hover:from-primary/30 transition-all duration-300 hover:scale-[1.03] active:scale-[0.98]"
  >
            <div className="absolute top-3 left-3">
              <span className="text-[10px] bg-primary/20 text-primary border border-primary/30 rounded-full px-2 py-0.5">متاح</span>
            </div>
            <div className="w-20 h-20 flex items-center justify-center">
              <svg viewBox="0 0 80 80" className="w-full h-full" fill="none">
                {
    /* Padel Racket */
  }
                <ellipse cx="38" cy="30" rx="20" ry="25" fill="none" stroke="#4ade80" strokeWidth="3" />
                <ellipse cx="38" cy="30" rx="20" ry="25" fill="#4ade80" fillOpacity="0.08" />
                {
    /* Grid lines */
  }
                <line x1="18" y1="30" x2="58" y2="30" stroke="#4ade80" strokeWidth="1.2" strokeOpacity="0.5" />
                <line x1="18" y1="20" x2="58" y2="20" stroke="#4ade80" strokeWidth="1.2" strokeOpacity="0.5" />
                <line x1="18" y1="40" x2="58" y2="40" stroke="#4ade80" strokeWidth="1.2" strokeOpacity="0.5" />
                <line x1="38" y1="5" x2="38" y2="55" stroke="#4ade80" strokeWidth="1.2" strokeOpacity="0.5" />
                <line x1="28" y1="6" x2="28" y2="54" stroke="#4ade80" strokeWidth="1.2" strokeOpacity="0.5" />
                <line x1="48" y1="6" x2="48" y2="54" stroke="#4ade80" strokeWidth="1.2" strokeOpacity="0.5" />
                {
    /* Handle */
  }
                <rect x="34" y="53" width="8" height="18" rx="4" fill="#4ade80" fillOpacity="0.7" />
                <rect x="32" y="65" width="12" height="4" rx="2" fill="#4ade80" fillOpacity="0.4" />
                {
    /* Ball */
  }
                <circle cx="60" cy="18" r="7" fill="#facc15" fillOpacity="0.9" />
                <path d="M55 15 Q60 18 65 15" stroke="#a16207" strokeWidth="1" fill="none" />
                <path d="M55 21 Q60 18 65 21" stroke="#a16207" strokeWidth="1" fill="none" />
              </svg>
            </div>
            <div className="text-center">
              <p className="text-white text-base">البادل</p>
              <p className="text-primary/70 text-xs mt-0.5">Padel</p>
            </div>
          </button>

          {
    /* Football - coming soon */
  }
          <div className="relative bg-white/5 border border-white/10 rounded-3xl p-6 flex flex-col items-center gap-3 opacity-60">
            <div className="absolute top-3 left-3">
              <span className="text-[10px] bg-white/10 text-white/60 border border-white/20 rounded-full px-2 py-0.5">قريباً</span>
            </div>
            <div className="w-20 h-20 flex items-center justify-center">
              <svg viewBox="0 0 80 80" className="w-full h-full" fill="none">
                {
    /* Football */
  }
                <circle cx="40" cy="40" r="28" fill="none" stroke="white" strokeWidth="2.5" strokeOpacity="0.4" />
                <circle cx="40" cy="40" r="28" fill="white" fillOpacity="0.05" />
                {
    /* Pentagon patches */
  }
                <polygon points="40,16 48,22 45,32 35,32 32,22" fill="white" fillOpacity="0.3" stroke="white" strokeWidth="1" strokeOpacity="0.4" />
                <polygon points="60,30 66,40 58,50 50,44 52,34" fill="white" fillOpacity="0.3" stroke="white" strokeWidth="1" strokeOpacity="0.4" />
                <polygon points="55,58 46,64 34,64 28,56 36,48 52,50" fill="white" fillOpacity="0.3" stroke="white" strokeWidth="1" strokeOpacity="0.4" />
                <polygon points="14,40 20,30 28,34 28,50 20,52" fill="white" fillOpacity="0.3" stroke="white" strokeWidth="1" strokeOpacity="0.4" />
                <polygon points="40,62 32,56 36,48 52,48 56,56" fill="white" fillOpacity="0.2" stroke="white" strokeWidth="1" strokeOpacity="0.3" />
              </svg>
            </div>
            <div className="text-center">
              <p className="text-white/60 text-base">كرة القدم</p>
              <p className="text-white/30 text-xs mt-0.5">Football</p>
            </div>
          </div>
        </div>

        {
    /* Coming Soon Row */
  }
        <div className="bg-white/5 border border-white/10 rounded-2xl p-4 flex items-center justify-between mb-8">
          <span className="text-xs bg-purple-500/20 text-purple-300 border border-purple-500/30 rounded-full px-3 py-1">قريباً</span>
          <div className="flex items-center gap-3">
            <div className="flex -space-x-1 rtl:space-x-reverse">
              {
    /* Tennis */
  }
              <div className="w-10 h-10 rounded-full bg-yellow-500/20 border border-yellow-500/30 flex items-center justify-center text-lg">🎾</div>
              {
    /* Basketball */
  }
              <div className="w-10 h-10 rounded-full bg-orange-500/20 border border-orange-500/30 flex items-center justify-center text-lg">🏀</div>
              {
    /* Swimming */
  }
              <div className="w-10 h-10 rounded-full bg-blue-500/20 border border-blue-500/30 flex items-center justify-center text-lg">🏊</div>
              {
    /* More */
  }
              <div className="w-10 h-10 rounded-full bg-white/10 border border-white/20 flex items-center justify-center text-xs text-white/60">+</div>
            </div>
            <p className="text-white/60 text-sm">رياضات أخرى</p>
          </div>
        </div>

        {
    /* Tagline */
  }
        <div className="text-center mb-8">
          <p className="text-white/40 text-xs leading-relaxed">
            ندعوك للاستمتاع بالتجربة 🎯
          </p>
        </div>

        {
    /* CTA */
  }
        <button
    onClick={onContinue}
    className="w-full py-4 bg-gradient-to-r from-primary to-primary/80 text-white rounded-2xl shadow-lg shadow-primary/20 hover:shadow-primary/30 hover:scale-[1.01] active:scale-[0.99] transition-all"
  >
          ابدأ تجربة البادل
        </button>
      </div>
    </div>;
}
export {
  SportsSelectionPage as default
};
