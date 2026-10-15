import { useState } from "react";
import { Search, MapPin, Star, DollarSign, Shield, X, SlidersHorizontal, ArrowUpDown, Heart, Map } from "lucide-react";
function CourtsPage({ onBack, onNavigateToCourt }) {
  const [searchQuery, setSearchQuery] = useState("");
  const [showFilters, setShowFilters] = useState(false);
  const [showMapView, setShowMapView] = useState(false);
  const [favoriteCourts, setFavoriteCourts] = useState([]);
  const [selectedCountry, setSelectedCountry] = useState("all");
  const [selectedCity, setSelectedCity] = useState("all");
  const [selectedNeighborhood, setSelectedNeighborhood] = useState("all");
  const [selectedType, setSelectedType] = useState("all");
  const [selectedGender, setSelectedGender] = useState("all");
  const [selectedPriceRange, setSelectedPriceRange] = useState("all");
  const [selectedRating, setSelectedRating] = useState("all");
  const [selectedDuration, setSelectedDuration] = useState("all");
  const [sortBy, setSortBy] = useState("rating");
  const allCourts = [
    {
      id: "1",
      name: "\u0646\u0627\u062F\u064A \u0627\u0644\u0628\u0627\u062F\u0644 \u0627\u0644\u0645\u0644\u0643\u064A",
      rating: 4.8,
      reviews: 124,
      distance: "1.8 \u0643\u0645",
      distanceValue: 1.8,
      city: "\u0627\u0644\u062F\u0645\u0627\u0645",
      neighborhood: "\u0627\u0644\u0639\u0632\u064A\u0632\u064A\u0629",
      country: "\u0627\u0644\u0633\u0639\u0648\u062F\u064A\u0629",
      type: "indoor",
      gender: "men",
      basePrice: 100,
      peakHourPrice: 150,
      availableTimes: ["07:00", "10:30", "11:30", "18:00"],
      availableDurations: [60, 90, 120],
      facilities: ["\u0645\u0648\u0627\u0642\u0641", "\u0643\u0627\u0641\u064A\u062A\u064A\u0631\u064A\u0627", "\u063A\u0631\u0641 \u062A\u0628\u062F\u064A\u0644"]
    },
    {
      id: "2",
      name: "\u0628\u0627\u062F\u0644 \u0643\u0644\u0648\u0628 \u0627\u0644\u0634\u0631\u0642\u064A\u0629",
      rating: 4.6,
      reviews: 89,
      distance: "3.2 \u0643\u0645",
      distanceValue: 3.2,
      city: "\u0627\u0644\u062E\u0628\u0631",
      neighborhood: "\u0627\u0644\u062B\u0642\u0628\u0629",
      country: "\u0627\u0644\u0633\u0639\u0648\u062F\u064A\u0629",
      type: "outdoor",
      gender: "women",
      basePrice: 80,
      peakHourPrice: 120,
      availableTimes: ["08:00", "19:30", "21:00"],
      availableDurations: [60, 90],
      facilities: ["\u0645\u0648\u0627\u0642\u0641", "\u062D\u062F\u064A\u0642\u0629"]
    },
    {
      id: "3",
      name: "\u0645\u0631\u0643\u0632 \u0628\u0627\u062F\u0644 \u0627\u0644\u0645\u062F\u064A\u0646\u0629",
      rating: 4.9,
      reviews: 201,
      distance: "5.4 \u0643\u0645",
      distanceValue: 5.4,
      city: "\u0627\u0644\u062F\u0645\u0627\u0645",
      neighborhood: "\u0627\u0644\u0641\u064A\u0635\u0644\u064A\u0629",
      country: "\u0627\u0644\u0633\u0639\u0648\u062F\u064A\u0629",
      type: "indoor",
      gender: "family",
      basePrice: 120,
      peakHourPrice: 180,
      availableTimes: ["06:00", "07:00", "09:00", "16:00", "20:00"],
      availableDurations: [90, 120],
      facilities: ["\u0645\u0648\u0627\u0642\u0641", "\u0643\u0627\u0641\u064A\u062A\u064A\u0631\u064A\u0627", "\u063A\u0631\u0641 \u062A\u0628\u062F\u064A\u0644", "\u0645\u0646\u0637\u0642\u0629 \u0623\u0637\u0641\u0627\u0644"]
    },
    {
      id: "4",
      name: "\u0645\u0644\u0627\u0639\u0628 \u0627\u0644\u0648\u0627\u062D\u0629",
      rating: 4.3,
      reviews: 56,
      distance: "4.1 \u0643\u0645",
      distanceValue: 4.1,
      city: "\u0627\u0644\u0642\u0637\u064A\u0641",
      neighborhood: "\u0627\u0644\u062C\u0634",
      country: "\u0627\u0644\u0633\u0639\u0648\u062F\u064A\u0629",
      type: "outdoor",
      gender: "all",
      basePrice: 70,
      peakHourPrice: 100,
      availableTimes: ["10:00", "15:00", "18:30"],
      availableDurations: [60, 120],
      facilities: ["\u0645\u0648\u0627\u0642\u0641"]
    },
    {
      id: "5",
      name: "\u0646\u0627\u062F\u064A \u0627\u0644\u0646\u062E\u0628\u0629",
      rating: 4.7,
      reviews: 145,
      distance: "2.3 \u0643\u0645",
      distanceValue: 2.3,
      city: "\u0627\u0644\u062E\u0628\u0631",
      neighborhood: "\u0627\u0644\u0639\u0642\u0631\u0628\u064A\u0629",
      country: "\u0627\u0644\u0633\u0639\u0648\u062F\u064A\u0629",
      type: "indoor",
      gender: "men",
      basePrice: 110,
      peakHourPrice: 160,
      availableTimes: ["07:30", "12:00", "19:00"],
      availableDurations: [60, 90, 120],
      facilities: ["\u0645\u0648\u0627\u0642\u0641", "\u0643\u0627\u0641\u064A\u062A\u064A\u0631\u064A\u0627", "\u063A\u0631\u0641 \u062A\u0628\u062F\u064A\u0644", "\u062C\u064A\u0645"]
    }
  ];
  const getFilteredCourts = () => {
    let filtered = allCourts.filter((court) => {
      if (searchQuery && !court.name.toLowerCase().includes(searchQuery.toLowerCase())) {
        return false;
      }
      if (selectedCountry !== "all" && court.country !== selectedCountry) {
        return false;
      }
      if (selectedCity !== "all" && court.city !== selectedCity) {
        return false;
      }
      if (selectedNeighborhood !== "all" && court.neighborhood !== selectedNeighborhood) {
        return false;
      }
      if (selectedType !== "all" && court.type !== selectedType) {
        return false;
      }
      if (selectedGender !== "all" && court.gender !== selectedGender && court.gender !== "all") {
        return false;
      }
      if (selectedPriceRange !== "all") {
        const avgPrice = (court.basePrice + court.peakHourPrice) / 2;
        if (selectedPriceRange === "low" && avgPrice > 100) return false;
        if (selectedPriceRange === "medium" && (avgPrice <= 100 || avgPrice > 150)) return false;
        if (selectedPriceRange === "high" && avgPrice <= 150) return false;
      }
      if (selectedRating === "4+" && court.rating < 4) return false;
      if (selectedRating === "4.5+" && court.rating < 4.5) return false;
      if (selectedDuration !== "all") {
        const duration = parseInt(selectedDuration);
        if (!court.availableDurations.includes(duration)) return false;
      }
      return true;
    });
    filtered.sort((a, b) => {
      switch (sortBy) {
        case "rating":
          return b.rating - a.rating;
        case "price":
          return a.basePrice - b.basePrice;
        case "distance":
          return a.distanceValue - b.distanceValue;
        default:
          return 0;
      }
    });
    return filtered;
  };
  const filteredCourts = getFilteredCourts();
  const getNeighborhoods = () => {
    if (selectedCity === "all") {
      return ["all", ...Array.from(new Set(allCourts.map((c) => c.neighborhood)))];
    }
    return ["all", ...Array.from(new Set(allCourts.filter((c) => c.city === selectedCity).map((c) => c.neighborhood)))];
  };
  const clearFilters = () => {
    setSelectedCountry("all");
    setSelectedCity("all");
    setSelectedNeighborhood("all");
    setSelectedType("all");
    setSelectedGender("all");
    setSelectedPriceRange("all");
    setSelectedRating("all");
    setSelectedDuration("all");
    setSearchQuery("");
    setSortBy("rating");
  };
  const hasActiveFilters = selectedCountry !== "all" || selectedCity !== "all" || selectedNeighborhood !== "all" || selectedType !== "all" || selectedGender !== "all" || selectedPriceRange !== "all" || selectedRating !== "all" || selectedDuration !== "all" || searchQuery !== "" || sortBy !== "rating";
  const toggleFavorite = (courtId) => {
    setFavoriteCourts(
      (prev) => prev.includes(courtId) ? prev.filter((id) => id !== courtId) : [...prev, courtId]
    );
  };
  const getGenderLabel = (gender) => {
    switch (gender) {
      case "women":
        return { text: "\u0646\u0633\u0627\u0621", color: "text-pink-500" };
      case "family":
        return { text: "\u0639\u0627\u0626\u0644\u0627\u062A", color: "text-blue-500" };
      case "men":
        return { text: "\u0631\u062C\u0627\u0644", color: "text-green-500" };
      default:
        return { text: "\u0627\u0644\u062C\u0645\u064A\u0639", color: "text-gray-500" };
    }
  };
  return <div className="flex-1 overflow-y-auto bg-background">
      {
    /* Header */
  }
      <div className="bg-gradient-to-br from-secondary to-secondary/90 text-white px-6 pt-8 pb-6">
        <div className="flex items-center gap-3 mb-4">
          <h1 className="text-2xl">احجز ملعب</h1>
        </div>

        {
    /* البحث وعرض الخريطة */
  }
        <div className="flex gap-2 mb-4">
          <div className="relative flex-1">
            <Search className="absolute right-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
            <input
    type="text"
    value={searchQuery}
    onChange={(e) => setSearchQuery(e.target.value)}
    placeholder="ابحث عن ملعب بالاسم..."
    className="w-full bg-white/95 backdrop-blur-sm text-gray-800 placeholder-gray-400 rounded-xl py-3 pr-11 pl-4 outline-none"
  />
          </div>
          <button
    onClick={() => setShowMapView(!showMapView)}
    className={`flex items-center gap-2 px-4 py-3 rounded-xl text-sm transition-colors whitespace-nowrap ${showMapView ? "bg-primary text-white" : "bg-white/95 text-secondary"}`}
  >
            <Map className="w-5 h-5" />
            <span className="hidden sm:inline">الخريطة</span>
          </button>
        </div>

        {
    /* زر الفلاتر */
  }
        {!showMapView && <div className="flex gap-2 items-center">
            <button
    onClick={() => setShowFilters(!showFilters)}
    className={`flex items-center gap-2 px-4 py-2 rounded-xl text-sm transition-colors ${showFilters || hasActiveFilters ? "bg-primary text-white" : "bg-white/20 backdrop-blur-sm text-white"}`}
  >
              <SlidersHorizontal className="w-4 h-4" />
              فلاتر التصفية
              {hasActiveFilters && !showFilters && <span className="bg-white text-primary w-5 h-5 rounded-full text-xs flex items-center justify-center">
                  •
                </span>}
            </button>

            {hasActiveFilters && <button
    onClick={clearFilters}
    className="flex items-center gap-1 px-3 py-2 bg-white/20 backdrop-blur-sm text-white rounded-xl text-sm"
  >
                <X className="w-4 h-4" />
                مسح
              </button>}

            <div className="flex-1 text-left text-sm text-white/80">
              {filteredCourts.length} ملعب
            </div>
          </div>}
      </div>

      {
    /* عرض الخريطة */
  }
      {showMapView && <div className="bg-white px-6 py-4">
          <div className="bg-gradient-to-br from-primary/10 to-primary/5 rounded-2xl overflow-hidden border-2 border-primary/20">
            <div className="h-96 flex items-center justify-center relative">
              <div className="absolute inset-0 bg-[url('data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTAwJSIgaGVpZ2h0PSIxMDAlIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPjxkZWZzPjxwYXR0ZXJuIGlkPSJncmlkIiB3aWR0aD0iNDAiIGhlaWdodD0iNDAiIHBhdHRlcm5Vbml0cz0idXNlclNwYWNlT25Vc2UiPjxwYXRoIGQ9Ik0gNDAgMCBMIDAgMCAwIDQwIiBmaWxsPSJub25lIiBzdHJva2U9IiMyQUI1Q0UiIHN0cm9rZS13aWR0aD0iMC41IiBvcGFjaXR5PSIwLjEiLz48L3BhdHRlcm4+PC9kZWZzPjxyZWN0IHdpZHRoPSIxMDAlIiBoZWlnaHQ9IjEwMCUiIGZpbGw9InVybCgjZ3JpZCkiLz48L3N2Zz4=')] opacity-50" />

              {
    /* علامات الملاعب على الخريطة */
  }
              {filteredCourts.map((court, index) => {
    const positions = [
      { top: "20%", left: "30%" },
      { top: "45%", left: "60%" },
      { top: "60%", left: "25%" },
      { top: "35%", left: "70%" },
      { top: "70%", left: "50%" }
    ];
    const position = positions[index % positions.length];
    return <div
      key={court.id}
      className="absolute transform -translate-x-1/2 -translate-y-1/2 cursor-pointer group"
      style={{ top: position.top, left: position.left }}
    >
                    <div className="relative">
                      <div className="w-10 h-10 bg-primary rounded-full shadow-lg flex items-center justify-center text-white animate-pulse">
                        <MapPin className="w-6 h-6" />
                      </div>
                      <div className="absolute bottom-full mb-2 left-1/2 transform -translate-x-1/2 hidden group-hover:block w-48 bg-white rounded-xl shadow-xl p-3 border border-border z-10">
                        <h4 className="text-sm font-medium text-secondary mb-1">{court.name}</h4>
                        <div className="flex items-center gap-1 mb-1">
                          <Star className="w-3 h-3 text-yellow-400 fill-yellow-400" />
                          <span className="text-xs text-secondary">{court.rating}</span>
                        </div>
                        <p className="text-xs text-muted-foreground mb-2">{court.distance}</p>
                        <button
      onClick={() => {
        setShowMapView(false);
        onNavigateToCourt && onNavigateToCourt(court.id);
      }}
      className="w-full py-1.5 bg-primary text-white rounded-lg text-xs"
    >
                          احجز الآن
                        </button>
                      </div>
                    </div>
                  </div>;
  })}

              <div className="text-center z-0">
                <Map className="w-16 h-16 text-primary/30 mx-auto mb-3" />
                <h3 className="text-secondary mb-2">عرض الخريطة</h3>
                <p className="text-sm text-muted-foreground max-w-xs mx-auto">
                  يظهر موقع {filteredCourts.length} ملعب على الخريطة. مرر المؤشر على العلامات لمزيد من التفاصيل.
                </p>
              </div>
            </div>
          </div>
        </div>}

      {
    /* لوحة الفلاتر */
  }
      {showFilters && !showMapView && <div className="bg-white border-b border-border px-6 py-5 space-y-4">
          {
    /* الترتيب */
  }
          <div>
            <label className="block text-sm text-secondary mb-2 flex items-center gap-2">
              <ArrowUpDown className="w-4 h-4 text-primary" />
              ترتيب النتائج
            </label>
            <div className="grid grid-cols-3 gap-2">
              <button
    onClick={() => setSortBy("rating")}
    className={`py-2 rounded-xl text-sm transition-colors ${sortBy === "rating" ? "bg-primary text-white" : "bg-gray-100 text-secondary"}`}
  >
                الأعلى تقييماً
              </button>
              <button
    onClick={() => setSortBy("price")}
    className={`py-2 rounded-xl text-sm transition-colors ${sortBy === "price" ? "bg-primary text-white" : "bg-gray-100 text-secondary"}`}
  >
                الأقل سعراً
              </button>
              <button
    onClick={() => setSortBy("distance")}
    className={`py-2 rounded-xl text-sm transition-colors ${sortBy === "distance" ? "bg-primary text-white" : "bg-gray-100 text-secondary"}`}
  >
                الأقرب
              </button>
            </div>
          </div>

          {
    /* الدولة */
  }
          <div>
            <label className="block text-sm text-secondary mb-2">الدولة</label>
            <div className="flex gap-2 overflow-x-auto pb-2">
              {["all", "\u0627\u0644\u0633\u0639\u0648\u062F\u064A\u0629"].map((country) => <button
    key={country}
    onClick={() => {
      setSelectedCountry(country);
      setSelectedCity("all");
      setSelectedNeighborhood("all");
    }}
    className={`px-4 py-2 rounded-full text-sm whitespace-nowrap flex-shrink-0 transition-colors ${selectedCountry === country ? "bg-primary text-white" : "bg-gray-100 text-secondary"}`}
  >
                  {country === "all" ? "\u0627\u0644\u0643\u0644" : country}
                </button>)}
            </div>
          </div>

          {
    /* المدينة */
  }
          <div>
            <label className="block text-sm text-secondary mb-2">المدينة</label>
            <div className="flex gap-2 overflow-x-auto pb-2">
              {["all", "\u0627\u0644\u062F\u0645\u0627\u0645", "\u0627\u0644\u062E\u0628\u0631", "\u0627\u0644\u0642\u0637\u064A\u0641"].map((city) => <button
    key={city}
    onClick={() => {
      setSelectedCity(city);
      setSelectedNeighborhood("all");
    }}
    className={`px-4 py-2 rounded-full text-sm whitespace-nowrap flex-shrink-0 transition-colors ${selectedCity === city ? "bg-primary text-white" : "bg-gray-100 text-secondary"}`}
  >
                  {city === "all" ? "\u0627\u0644\u0643\u0644" : city}
                </button>)}
            </div>
          </div>

          {
    /* الحي */
  }
          <div>
            <label className="block text-sm text-secondary mb-2">الحي</label>
            <div className="flex gap-2 overflow-x-auto pb-2">
              {getNeighborhoods().map((neighborhood) => <button
    key={neighborhood}
    onClick={() => setSelectedNeighborhood(neighborhood)}
    className={`px-4 py-2 rounded-full text-sm whitespace-nowrap flex-shrink-0 transition-colors ${selectedNeighborhood === neighborhood ? "bg-primary text-white" : "bg-gray-100 text-secondary"}`}
  >
                  {neighborhood === "all" ? "\u0643\u0644 \u0627\u0644\u0623\u062D\u064A\u0627\u0621" : neighborhood}
                </button>)}
            </div>
          </div>

          {
    /* نوع الملعب */
  }
          <div>
            <label className="block text-sm text-secondary mb-2">نوع الملعب</label>
            <div className="grid grid-cols-3 gap-2">
              <button
    onClick={() => setSelectedType("all")}
    className={`py-2 rounded-xl text-sm transition-colors ${selectedType === "all" ? "bg-primary text-white" : "bg-gray-100 text-secondary"}`}
  >
                الكل
              </button>
              <button
    onClick={() => setSelectedType("indoor")}
    className={`py-2 rounded-xl text-sm transition-colors ${selectedType === "indoor" ? "bg-primary text-white" : "bg-gray-100 text-secondary"}`}
  >
                داخلي
              </button>
              <button
    onClick={() => setSelectedType("outdoor")}
    className={`py-2 rounded-xl text-sm transition-colors ${selectedType === "outdoor" ? "bg-primary text-white" : "bg-gray-100 text-secondary"}`}
  >
                خارجي
              </button>
            </div>
          </div>

          {
    /* الجنس */
  }
          <div>
            <label className="block text-sm text-secondary mb-2">الفئة المستهدفة</label>
            <div className="grid grid-cols-4 gap-2">
              {[
    { value: "all", label: "\u0627\u0644\u0643\u0644" },
    { value: "men", label: "\u0631\u062C\u0627\u0644" },
    { value: "women", label: "\u0646\u0633\u0627\u0621" },
    { value: "family", label: "\u0639\u0627\u0626\u0644\u0627\u062A" }
  ].map((option) => <button
    key={option.value}
    onClick={() => setSelectedGender(option.value)}
    className={`py-2 rounded-xl text-sm transition-colors ${selectedGender === option.value ? "bg-primary text-white" : "bg-gray-100 text-secondary"}`}
  >
                  {option.label}
                </button>)}
            </div>
          </div>

          {
    /* نطاق السعر */
  }
          <div>
            <label className="block text-sm text-secondary mb-2">نطاق السعر</label>
            <div className="grid grid-cols-4 gap-2">
              {[
    { value: "all", label: "\u0627\u0644\u0643\u0644" },
    { value: "low", label: "\u0645\u0646\u062E\u0641\u0636" },
    { value: "medium", label: "\u0645\u062A\u0648\u0633\u0637" },
    { value: "high", label: "\u0645\u0631\u062A\u0641\u0639" }
  ].map((option) => <button
    key={option.value}
    onClick={() => setSelectedPriceRange(option.value)}
    className={`py-2 rounded-xl text-sm transition-colors ${selectedPriceRange === option.value ? "bg-primary text-white" : "bg-gray-100 text-secondary"}`}
  >
                  {option.label}
                </button>)}
            </div>
          </div>

          {
    /* التقييم */
  }
          <div>
            <label className="block text-sm text-secondary mb-2">التقييم</label>
            <div className="grid grid-cols-3 gap-2">
              {[
    { value: "all", label: "\u0627\u0644\u0643\u0644" },
    { value: "4+", label: "4+ \u0646\u062C\u0648\u0645" },
    { value: "4.5+", label: "4.5+ \u0646\u062C\u0648\u0645" }
  ].map((option) => <button
    key={option.value}
    onClick={() => setSelectedRating(option.value)}
    className={`py-2 rounded-xl text-sm transition-colors ${selectedRating === option.value ? "bg-primary text-white" : "bg-gray-100 text-secondary"}`}
  >
                  {option.label}
                </button>)}
            </div>
          </div>

          {
    /* المدة المتاحة */
  }
          <div>
            <label className="block text-sm text-secondary mb-2">المدة المتاحة</label>
            <div className="grid grid-cols-4 gap-2">
              {[
    { value: "all", label: "\u0627\u0644\u0643\u0644" },
    { value: "60", label: "60 \u062F\u0642\u064A\u0642\u0629" },
    { value: "90", label: "90 \u062F\u0642\u064A\u0642\u0629" },
    { value: "120", label: "120 \u062F\u0642\u064A\u0642\u0629" }
  ].map((option) => <button
    key={option.value}
    onClick={() => setSelectedDuration(option.value)}
    className={`py-2 rounded-xl text-sm transition-colors ${selectedDuration === option.value ? "bg-primary text-white" : "bg-gray-100 text-secondary"}`}
  >
                  {option.label}
                </button>)}
            </div>
          </div>
        </div>}

      {
    /* قائمة الملاعب */
  }
      {!showMapView && <div className="px-6 py-4 space-y-4">
          {filteredCourts.length === 0 ? <div className="text-center py-12">
            <div className="w-16 h-16 bg-gray-100 rounded-full mx-auto mb-4 flex items-center justify-center">
              <Search className="w-8 h-8 text-gray-400" />
            </div>
            <h3 className="text-secondary mb-2">لا توجد نتائج</h3>
            <p className="text-sm text-muted-foreground mb-4">جرب تغيير الفلاتر أو البحث</p>
            <button
    onClick={clearFilters}
    className="px-6 py-2 bg-primary text-white rounded-xl text-sm"
  >
              مسح الفلاتر
            </button>
          </div> : filteredCourts.map((court) => {
    const genderInfo = getGenderLabel(court.gender);
    return <div key={court.id} className="bg-white border border-border rounded-2xl overflow-hidden shadow-sm relative">
                {
      /* أيقونة التفضيل */
    }
                <button
      onClick={() => toggleFavorite(court.id)}
      className="absolute top-3 left-3 z-10 w-10 h-10 bg-white/90 backdrop-blur-sm rounded-full shadow-lg flex items-center justify-center hover:bg-white transition-colors"
    >
                  <Heart
      className={`w-5 h-5 transition-colors ${favoriteCourts.includes(court.id) ? "fill-red-500 text-red-500" : "text-gray-400"}`}
    />
                </button>

                <div className="h-32 bg-gradient-to-br from-primary/20 to-primary/5 flex items-center justify-center">
                  <div className="text-center">
                    <p className="text-gray-400 text-sm mb-1">صورة الملعب</p>
                    <div className="w-16 h-16 bg-primary/20 rounded-full mx-auto flex items-center justify-center">
                      <MapPin className="w-8 h-8 text-primary" />
                    </div>
                  </div>
                </div>

                <div className="p-4">
                  <div className="flex justify-between items-start mb-3">
                    <div className="flex-1">
                      <h3 className="text-secondary mb-1">{court.name}</h3>
                      <div className="flex items-center gap-1 mb-2">
                        <Star className="w-4 h-4 text-yellow-400 fill-yellow-400" />
                        <span className="text-sm text-secondary">{court.rating}</span>
                        <span className="text-xs text-muted-foreground">({court.reviews} تقييم)</span>
                      </div>
                      <div className="flex items-center gap-2 text-xs text-muted-foreground flex-wrap">
                        <MapPin className="w-3 h-3 text-primary" />
                        <span>{court.distance}</span>
                        <span>•</span>
                        <span>{court.city}</span>
                        <span>•</span>
                        <span>{court.type === "indoor" ? "\u0645\u0644\u0639\u0628 \u062F\u0627\u062E\u0644\u064A" : "\u0645\u0644\u0639\u0628 \u062E\u0627\u0631\u062C\u064A"}</span>
                        {court.gender !== "all" && <>
                            <span>•</span>
                            <Shield className={`w-3 h-3 ${genderInfo.color}`} />
                            <span className={genderInfo.color}>{genderInfo.text}</span>
                          </>}
                      </div>
                    </div>
                  </div>

                  <div className="flex justify-between items-center pt-3 border-t border-border">
                    <div className="flex items-center gap-1 text-secondary">
                      <DollarSign className="w-4 h-4 text-primary" />
                      <span className="text-lg">{court.basePrice}</span>
                      <span className="text-xs text-muted-foreground">ر.س / ساعة</span>
                    </div>
                    <button
      onClick={() => onNavigateToCourt && onNavigateToCourt(court.id)}
      className="px-5 py-2 bg-primary text-white rounded-lg hover:bg-primary/90 transition-colors"
    >
                      احجز الآن
                    </button>
                  </div>
                </div>
              </div>;
  })}
        </div>}
    </div>;
}
export {
  CourtsPage as default
};
