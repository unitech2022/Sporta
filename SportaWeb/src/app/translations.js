const translations = {
  ar: {
    // Common
    back: "\u0631\u062C\u0648\u0639",
    save: "\u062D\u0641\u0638",
    cancel: "\u0625\u0644\u063A\u0627\u0621",
    confirm: "\u062A\u0623\u0643\u064A\u062F",
    delete: "\u062D\u0630\u0641",
    edit: "\u062A\u0639\u062F\u064A\u0644",
    search: "\u0628\u062D\u062B",
    viewAll: "\u0639\u0631\u0636 \u0627\u0644\u0643\u0644",
    loading: "\u062C\u0627\u0631\u064A \u0627\u0644\u062A\u062D\u0645\u064A\u0644...",
    // Auth
    login: "\u062A\u0633\u062C\u064A\u0644 \u0627\u0644\u062F\u062E\u0648\u0644",
    register: "\u0625\u0646\u0634\u0627\u0621 \u062D\u0633\u0627\u0628",
    logout: "\u062A\u0633\u062C\u064A\u0644 \u0627\u0644\u062E\u0631\u0648\u062C",
    email: "\u0627\u0644\u0628\u0631\u064A\u062F \u0627\u0644\u0625\u0644\u0643\u062A\u0631\u0648\u0646\u064A",
    password: "\u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631",
    phone: "\u0631\u0642\u0645 \u0627\u0644\u062C\u0648\u0627\u0644",
    // Navigation
    home: "\u0627\u0644\u0631\u0626\u064A\u0633\u064A\u0629",
    matches: "\u0627\u0644\u0645\u0628\u0627\u0631\u064A\u0627\u062A",
    courts: "\u0627\u0644\u0645\u0644\u0627\u0639\u0628",
    coaches: "\u0627\u0644\u0645\u062F\u0631\u0628\u064A\u0646",
    profile: "\u0635\u0641\u062D\u062A\u064A",
    // User Roles
    player: "\u0644\u0627\u0639\u0628",
    coach: "\u0645\u062F\u0631\u0628",
    venue: "\u0645\u0644\u0639\u0628",
    venueOwner: "\u0645\u0627\u0644\u0643 \u0645\u0644\u0639\u0628",
    // Home Page
    welcomeBack: "\u0645\u0631\u062D\u0628\u0627\u064B \u0628\u0639\u0648\u062F\u062A\u0643",
    upcomingMatches: "\u0627\u0644\u0645\u0628\u0627\u0631\u064A\u0627\u062A \u0627\u0644\u0642\u0627\u062F\u0645\u0629",
    nearbyMatches: "\u0645\u0628\u0627\u0631\u064A\u0627\u062A \u0642\u0631\u064A\u0628\u0629 \u0645\u0646\u0643",
    tournaments: "\u0627\u0644\u0628\u0637\u0648\u0644\u0627\u062A",
    padelTournaments: "\u0628\u0637\u0648\u0644\u0627\u062A \u0627\u0644\u0628\u0627\u062F\u0644",
    internationalTournaments: "\u0627\u0644\u0628\u0637\u0648\u0644\u0627\u062A \u0627\u0644\u062F\u0648\u0644\u064A\u0629",
    localTournaments: "\u0627\u0644\u0628\u0637\u0648\u0644\u0627\u062A \u0627\u0644\u0645\u062D\u0644\u064A\u0629",
    friendActivity: "\u0646\u0634\u0627\u0637 \u0627\u0644\u0623\u0635\u062F\u0642\u0627\u0621",
    friendSuggestions: "\u0627\u0642\u062A\u0631\u0627\u062D\u0627\u062A \u0627\u0644\u0623\u0635\u062F\u0642\u0627\u0621",
    latestActivities: "\u0622\u062E\u0631 \u0627\u0644\u0623\u0646\u0634\u0637\u0629",
    // Profile Page
    myProfile: "\u0635\u0641\u062D\u062A\u064A",
    statistics: "\u0627\u0644\u0625\u062D\u0635\u0627\u0626\u064A\u0627\u062A",
    matchesPlayed: "\u0627\u0644\u0628\u0637\u0648\u0644\u0627\u062A \u0627\u0644\u062A\u064A \u0644\u0639\u0628\u062A\u0647\u0627",
    winRate: "\u0646\u0633\u0628\u0629 \u0627\u0644\u0641\u0648\u0632",
    totalPoints: "\u0645\u062C\u0645\u0648\u0639 \u0627\u0644\u0646\u0642\u0627\u0637",
    ranking: "\u0627\u0644\u062A\u0631\u062A\u064A\u0628",
    level: "\u0627\u0644\u0645\u0633\u062A\u0648\u0649",
    notifications: "\u0627\u0644\u0625\u0634\u0639\u0627\u0631\u0627\u062A",
    wallet: "\u0627\u0644\u0645\u062D\u0641\u0638\u0629",
    availableBalance: "\u0627\u0644\u0631\u0635\u064A\u062F \u0627\u0644\u0645\u062A\u0627\u062D",
    topUpBalance: "\u0634\u062D\u0646 \u0627\u0644\u0631\u0635\u064A\u062F",
    withdrawBalance: "\u0633\u062D\u0628 \u0627\u0644\u0631\u0635\u064A\u062F",
    friendsList: "\u0642\u0627\u0626\u0645\u0629 \u0627\u0644\u0623\u0635\u062F\u0642\u0627\u0621",
    favoritesList: "\u0627\u0644\u0642\u0627\u0626\u0645\u0629 \u0627\u0644\u0645\u0641\u0636\u0644\u0629",
    generalSettings: "\u0627\u0644\u0625\u0639\u062F\u0627\u062F\u0627\u062A \u0627\u0644\u0639\u0627\u0645\u0629",
    // Settings
    changeLanguage: "\u062A\u063A\u064A\u064A\u0631 \u0627\u0644\u0644\u063A\u0629",
    contactUs: "\u0627\u062A\u0635\u0644 \u0628\u0646\u0627",
    accountSettings: "\u0625\u0639\u062F\u0627\u062F\u0627\u062A \u0627\u0644\u062D\u0633\u0627\u0628",
    termsAndConditions: "\u0627\u0644\u0634\u0631\u0648\u0637 \u0648\u0627\u0644\u0623\u062D\u0643\u0627\u0645",
    privacyPolicy: "\u0633\u064A\u0627\u0633\u0629 \u0627\u0644\u062E\u0635\u0648\u0635\u064A\u0629",
    refundPolicy: "\u0633\u064A\u0627\u0633\u0629 \u0627\u0644\u0627\u0633\u062A\u0631\u062C\u0627\u0639",
    // Contact
    whatsapp: "\u0648\u0627\u062A\u0633\u0627\u0628",
    liveChat: "\u0627\u0644\u062F\u0631\u062F\u0634\u0629 \u0627\u0644\u0645\u0628\u0627\u0634\u0631\u0629",
    sendMessage: "\u0625\u0631\u0633\u0627\u0644 \u0631\u0633\u0627\u0644\u0629",
    workingHours: "\u0623\u0648\u0642\u0627\u062A \u0627\u0644\u0639\u0645\u0644",
    // Time
    today: "\u0627\u0644\u064A\u0648\u0645",
    tomorrow: "\u063A\u062F\u0627\u064B",
    thisWeek: "\u0647\u0630\u0627 \u0627\u0644\u0623\u0633\u0628\u0648\u0639",
    thisMonth: "\u0647\u0630\u0627 \u0627\u0644\u0634\u0647\u0631",
    // Status
    confirmed: "\u0645\u0624\u0643\u062F\u0629",
    pending: "\u0642\u064A\u062F \u0627\u0644\u0627\u0646\u062A\u0638\u0627\u0631",
    cancelled: "\u0645\u0644\u063A\u0627\u0629",
    active: "\u0646\u0634\u0637",
    inactive: "\u063A\u064A\u0631 \u0646\u0634\u0637"
  },
  en: {
    // Common
    back: "Back",
    save: "Save",
    cancel: "Cancel",
    confirm: "Confirm",
    delete: "Delete",
    edit: "Edit",
    search: "Search",
    viewAll: "View All",
    loading: "Loading...",
    // Auth
    login: "Login",
    register: "Sign Up",
    logout: "Logout",
    email: "Email",
    password: "Password",
    phone: "Phone Number",
    // Navigation
    home: "Home",
    matches: "Matches",
    courts: "Courts",
    coaches: "Coaches",
    profile: "My Profile",
    // User Roles
    player: "Player",
    coach: "Coach",
    venue: "Venue",
    venueOwner: "Venue Owner",
    // Home Page
    welcomeBack: "Welcome Back",
    upcomingMatches: "Upcoming Matches",
    nearbyMatches: "Matches Near You",
    tournaments: "Tournaments",
    padelTournaments: "Padel Tournaments",
    internationalTournaments: "International Tournaments",
    localTournaments: "Local Tournaments",
    friendActivity: "Friend Activity",
    friendSuggestions: "Friend Suggestions",
    latestActivities: "Latest Activities",
    // Profile Page
    myProfile: "My Profile",
    statistics: "Statistics",
    matchesPlayed: "Tournaments Played",
    winRate: "Win Rate",
    totalPoints: "Total Points",
    ranking: "Ranking",
    level: "Level",
    notifications: "Notifications",
    wallet: "Wallet",
    availableBalance: "Available Balance",
    topUpBalance: "Top Up",
    withdrawBalance: "Withdraw",
    friendsList: "Friends List",
    favoritesList: "Favorites",
    generalSettings: "General Settings",
    // Settings
    changeLanguage: "Change Language",
    contactUs: "Contact Us",
    accountSettings: "Account Settings",
    termsAndConditions: "Terms & Conditions",
    privacyPolicy: "Privacy Policy",
    refundPolicy: "Refund Policy",
    // Contact
    whatsapp: "WhatsApp",
    liveChat: "Live Chat",
    sendMessage: "Send Message",
    workingHours: "Working Hours",
    // Time
    today: "Today",
    tomorrow: "Tomorrow",
    thisWeek: "This Week",
    thisMonth: "This Month",
    // Status
    confirmed: "Confirmed",
    pending: "Pending",
    cancelled: "Cancelled",
    active: "Active",
    inactive: "Inactive"
  }
};
const getTranslation = (key, lang = "ar") => {
  const keys = key.split(".");
  let value = translations[lang];
  for (const k of keys) {
    value = value?.[k];
  }
  return value || key;
};
const getCurrentLanguage = () => {
  return localStorage.getItem("appLanguage") || "ar";
};
const isRTL = (lang) => {
  return lang === "ar";
};
export {
  getCurrentLanguage,
  getTranslation,
  isRTL,
  translations
};
