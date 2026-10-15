const fullTranslations = {
  ar: {
    // App Name
    appName: "SPORTA",
    // Navigation
    nav: {
      home: "\u0627\u0644\u0631\u0626\u064A\u0633\u064A\u0629",
      matches: "\u0627\u0644\u0645\u0628\u0627\u0631\u064A\u0627\u062A",
      courts: "\u0627\u0644\u0645\u0644\u0627\u0639\u0628",
      coaches: "\u0627\u0644\u0645\u062F\u0631\u0628\u064A\u0646",
      profile: "\u0635\u0641\u062D\u062A\u064A",
      americano: "\u0623\u0645\u0631\u064A\u0643\u0627\u0646\u0648"
    },
    // Common
    common: {
      back: "\u0631\u062C\u0648\u0639",
      next: "\u0627\u0644\u062A\u0627\u0644\u064A",
      save: "\u062D\u0641\u0638",
      cancel: "\u0625\u0644\u063A\u0627\u0621",
      confirm: "\u062A\u0623\u0643\u064A\u062F",
      delete: "\u062D\u0630\u0641",
      edit: "\u062A\u0639\u062F\u064A\u0644",
      search: "\u0628\u062D\u062B",
      filter: "\u062A\u0635\u0641\u064A\u0629",
      viewAll: "\u0639\u0631\u0636 \u0627\u0644\u0643\u0644",
      loading: "\u062C\u0627\u0631\u064A \u0627\u0644\u062A\u062D\u0645\u064A\u0644...",
      sar: "\u0631.\u0633",
      online: "\u0645\u062A\u0635\u0644",
      offline: "\u063A\u064A\u0631 \u0645\u062A\u0635\u0644"
    },
    // Auth
    auth: {
      login: "\u062A\u0633\u062C\u064A\u0644 \u0627\u0644\u062F\u062E\u0648\u0644",
      register: "\u0625\u0646\u0634\u0627\u0621 \u062D\u0633\u0627\u0628",
      logout: "\u062A\u0633\u062C\u064A\u0644 \u0627\u0644\u062E\u0631\u0648\u062C",
      email: "\u0627\u0644\u0628\u0631\u064A\u062F \u0627\u0644\u0625\u0644\u0643\u062A\u0631\u0648\u0646\u064A",
      password: "\u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631",
      phone: "\u0631\u0642\u0645 \u0627\u0644\u062C\u0648\u0627\u0644",
      forgotPassword: "\u0646\u0633\u064A\u062A \u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631\u061F",
      dontHaveAccount: "\u0644\u064A\u0633 \u0644\u062F\u064A\u0643 \u062D\u0633\u0627\u0628\u061F",
      alreadyHaveAccount: "\u0644\u062F\u064A\u0643 \u062D\u0633\u0627\u0628 \u0628\u0627\u0644\u0641\u0639\u0644\u061F"
    },
    // User Roles
    roles: {
      player: "\u0644\u0627\u0639\u0628",
      coach: "\u0645\u062F\u0631\u0628",
      venue: "\u0645\u0644\u0639\u0628",
      venueOwner: "\u0645\u0627\u0644\u0643 \u0645\u0644\u0639\u0628"
    },
    // Home Page
    home: {
      welcomeBack: "\u0645\u0631\u062D\u0628\u0627\u064B \u0628\u0639\u0648\u062F\u062A\u0643",
      quickStats: "\u0625\u062D\u0635\u0627\u0626\u064A\u0627\u062A \u0633\u0631\u064A\u0639\u0629",
      upcomingMatches: "\u0627\u0644\u0645\u0628\u0627\u0631\u064A\u0627\u062A \u0627\u0644\u0642\u0627\u062F\u0645\u0629",
      nearbyMatches: "\u0645\u0628\u0627\u0631\u064A\u0627\u062A \u0642\u0631\u064A\u0628\u0629 \u0645\u0646\u0643",
      findMatch: "\u0627\u0628\u062D\u062B \u0639\u0646 \u0645\u0628\u0627\u0631\u0627\u0629",
      bookCourt: "\u0627\u062D\u062C\u0632 \u0645\u0644\u0639\u0628",
      findCoach: "\u0627\u0628\u062D\u062B \u0639\u0646 \u0645\u062F\u0631\u0628",
      tournaments: "\u0627\u0644\u0628\u0637\u0648\u0644\u0627\u062A",
      padelTournaments: "\u0628\u0637\u0648\u0644\u0627\u062A \u0627\u0644\u0628\u0627\u062F\u0644",
      internationalTournaments: "\u0627\u0644\u0628\u0637\u0648\u0644\u0627\u062A \u0627\u0644\u062F\u0648\u0644\u064A\u0629",
      localTournaments: "\u0627\u0644\u0628\u0637\u0648\u0644\u0627\u062A \u0627\u0644\u0645\u062D\u0644\u064A\u0629",
      friendActivity: "\u0646\u0634\u0627\u0637 \u0627\u0644\u0623\u0635\u062F\u0642\u0627\u0621",
      friendSuggestions: "\u0627\u0642\u062A\u0631\u0627\u062D\u0627\u062A \u0627\u0644\u0623\u0635\u062F\u0642\u0627\u0621",
      latestActivities: "\u0622\u062E\u0631 \u0627\u0644\u0623\u0646\u0634\u0637\u0629",
      basedOnLevel: "\u0628\u0646\u0627\u0621\u064B \u0639\u0644\u0649 \u0627\u0644\u0645\u0633\u062A\u0648\u0649",
      basedOnLocation: "\u0628\u0646\u0627\u0621\u064B \u0639\u0644\u0649 \u0627\u0644\u0645\u0648\u0642\u0639",
      mutualFriends: "\u0623\u0635\u062F\u0642\u0627\u0621 \u0645\u0634\u062A\u0631\u0643\u064A\u0646",
      playedWith: "\u0644\u0639\u0628 \u0645\u0639 \u0623\u0635\u062F\u0642\u0627\u0626\u0643",
      achievedPoints: "\u062D\u0642\u0642 \u0646\u0642\u0627\u0637",
      leveledUp: "\u0631\u0641\u0639 \u0645\u0633\u062A\u0648\u0627\u0647",
      joinedTournament: "\u0627\u0646\u0636\u0645 \u0644\u0628\u0637\u0648\u0644\u0629",
      bookedMatch: "\u062D\u062C\u0632 \u0645\u0628\u0627\u0631\u0627\u0629"
    },
    // Profile
    profile: {
      myProfile: "\u0635\u0641\u062D\u062A\u064A",
      statistics: "\u0627\u0644\u0625\u062D\u0635\u0627\u0626\u064A\u0627\u062A",
      matchesPlayed: "\u0627\u0644\u0628\u0637\u0648\u0644\u0627\u062A \u0627\u0644\u062A\u064A \u0644\u0639\u0628\u062A\u0647\u0627",
      winRate: "\u0646\u0633\u0628\u0629 \u0627\u0644\u0641\u0648\u0632",
      totalPoints: "\u0645\u062C\u0645\u0648\u0639 \u0627\u0644\u0646\u0642\u0627\u0637",
      ranking: "\u0627\u0644\u062A\u0631\u062A\u064A\u0628",
      level: "\u0627\u0644\u0645\u0633\u062A\u0648\u0649",
      currentLevel: "\u0627\u0644\u0645\u0633\u062A\u0648\u0649 \u0627\u0644\u062D\u0627\u0644\u064A",
      notifications: "\u0627\u0644\u0625\u0634\u0639\u0627\u0631\u0627\u062A",
      wallet: "\u0627\u0644\u0645\u062D\u0641\u0638\u0629",
      availableBalance: "\u0627\u0644\u0631\u0635\u064A\u062F \u0627\u0644\u0645\u062A\u0627\u062D",
      topUpBalance: "\u0634\u062D\u0646 \u0627\u0644\u0631\u0635\u064A\u062F",
      withdrawBalance: "\u0633\u062D\u0628 \u0627\u0644\u0631\u0635\u064A\u062F",
      friendsList: "\u0642\u0627\u0626\u0645\u0629 \u0627\u0644\u0623\u0635\u062F\u0642\u0627\u0621",
      favoritesList: "\u0627\u0644\u0642\u0627\u0626\u0645\u0629 \u0627\u0644\u0645\u0641\u0636\u0644\u0629",
      favoritePartner: "\u0634\u0631\u064A\u0643\u0643 \u0627\u0644\u0645\u0641\u0636\u0644",
      generalSettings: "\u0627\u0644\u0625\u0639\u062F\u0627\u062F\u0627\u062A \u0627\u0644\u0639\u0627\u0645\u0629",
      friends: "\u0635\u062F\u064A\u0642",
      favorites: "\u0645\u0641\u0636\u0644\u064A\u0646"
    },
    // Settings
    settings: {
      changeLanguage: "\u062A\u063A\u064A\u064A\u0631 \u0627\u0644\u0644\u063A\u0629",
      contactUs: "\u0627\u062A\u0635\u0644 \u0628\u0646\u0627",
      accountSettings: "\u0625\u0639\u062F\u0627\u062F\u0627\u062A \u0627\u0644\u062D\u0633\u0627\u0628",
      termsAndConditions: "\u0627\u0644\u0634\u0631\u0648\u0637 \u0648\u0627\u0644\u0623\u062D\u0643\u0627\u0645",
      privacyPolicy: "\u0633\u064A\u0627\u0633\u0629 \u0627\u0644\u062E\u0635\u0648\u0635\u064A\u0629",
      refundPolicy: "\u0633\u064A\u0627\u0633\u0629 \u0627\u0644\u0627\u0633\u062A\u0631\u062C\u0627\u0639",
      arabic: "\u0627\u0644\u0639\u0631\u0628\u064A\u0629",
      english: "\u0627\u0644\u0625\u0646\u062C\u0644\u064A\u0632\u064A\u0629",
      currentLanguage: "\u0627\u0644\u0644\u063A\u0629 \u0627\u0644\u062D\u0627\u0644\u064A\u0629"
    },
    // Contact
    contact: {
      whatsapp: "\u0648\u0627\u062A\u0633\u0627\u0628",
      email: "\u0627\u0644\u0628\u0631\u064A\u062F \u0627\u0644\u0625\u0644\u0643\u062A\u0631\u0648\u0646\u064A",
      liveChat: "\u0627\u0644\u062F\u0631\u062F\u0634\u0629 \u0627\u0644\u0645\u0628\u0627\u0634\u0631\u0629",
      sendMessage: "\u0625\u0631\u0633\u0627\u0644 \u0631\u0633\u0627\u0644\u0629",
      workingHours: "\u0623\u0648\u0642\u0627\u062A \u0627\u0644\u0639\u0645\u0644",
      contactViaWhatsApp: "\u062A\u0648\u0627\u0635\u0644 \u0645\u0639\u0646\u0627 \u0639\u0628\u0631 \u0627\u0644\u0648\u0627\u062A\u0633\u0627\u0628",
      sendEmail: "\u0623\u0631\u0633\u0644 \u0644\u0646\u0627 \u0631\u0633\u0627\u0644\u0629 \u0639\u0628\u0631 \u0627\u0644\u0628\u0631\u064A\u062F",
      chatWithSupport: "\u062A\u062D\u062F\u062B \u0645\u0639 \u0641\u0631\u064A\u0642 \u0627\u0644\u062F\u0639\u0645 \u0645\u0628\u0627\u0634\u0631\u0629",
      onlineNow: "\u0645\u062A\u0635\u0644 \u0627\u0644\u0622\u0646",
      subject: "\u0627\u0644\u0645\u0648\u0636\u0648\u0639",
      message: "\u0627\u0644\u0631\u0633\u0627\u0644\u0629",
      writeYourMessage: "\u0627\u0643\u062A\u0628 \u0631\u0633\u0627\u0644\u062A\u0643 \u0647\u0646\u0627..."
    },
    // Time
    time: {
      today: "\u0627\u0644\u064A\u0648\u0645",
      tomorrow: "\u063A\u062F\u0627\u064B",
      yesterday: "\u0623\u0645\u0633",
      thisWeek: "\u0647\u0630\u0627 \u0627\u0644\u0623\u0633\u0628\u0648\u0639",
      thisMonth: "\u0647\u0630\u0627 \u0627\u0644\u0634\u0647\u0631",
      am: "\u0635\u0628\u0627\u062D\u0627\u064B",
      pm: "\u0645\u0633\u0627\u0621\u064B"
    },
    // Status
    status: {
      confirmed: "\u0645\u0624\u0643\u062F\u0629",
      pending: "\u0642\u064A\u062F \u0627\u0644\u0627\u0646\u062A\u0638\u0627\u0631",
      cancelled: "\u0645\u0644\u063A\u0627\u0629",
      active: "\u0646\u0634\u0637",
      inactive: "\u063A\u064A\u0631 \u0646\u0634\u0637",
      available: "\u0645\u062A\u0627\u062D",
      booked: "\u0645\u062D\u062C\u0648\u0632",
      maintenance: "\u0635\u064A\u0627\u0646\u0629"
    }
  },
  en: {
    // App Name
    appName: "SPORTA",
    // Navigation
    nav: {
      home: "Home",
      matches: "Matches",
      courts: "Courts",
      coaches: "Coaches",
      profile: "My Profile",
      americano: "Americano"
    },
    // Common
    common: {
      back: "Back",
      next: "Next",
      save: "Save",
      cancel: "Cancel",
      confirm: "Confirm",
      delete: "Delete",
      edit: "Edit",
      search: "Search",
      filter: "Filter",
      viewAll: "View All",
      loading: "Loading...",
      sar: "SAR",
      online: "Online",
      offline: "Offline"
    },
    // Auth
    auth: {
      login: "Login",
      register: "Sign Up",
      logout: "Logout",
      email: "Email",
      password: "Password",
      phone: "Phone Number",
      forgotPassword: "Forgot Password?",
      dontHaveAccount: "Don't have an account?",
      alreadyHaveAccount: "Already have an account?"
    },
    // User Roles
    roles: {
      player: "Player",
      coach: "Coach",
      venue: "Venue",
      venueOwner: "Venue Owner"
    },
    // Home Page
    home: {
      welcomeBack: "Welcome Back",
      quickStats: "Quick Stats",
      upcomingMatches: "Upcoming Matches",
      nearbyMatches: "Matches Near You",
      findMatch: "Find a Match",
      bookCourt: "Book a Court",
      findCoach: "Find a Coach",
      tournaments: "Tournaments",
      padelTournaments: "Padel Tournaments",
      internationalTournaments: "International Tournaments",
      localTournaments: "Local Tournaments",
      friendActivity: "Friend Activity",
      friendSuggestions: "Friend Suggestions",
      latestActivities: "Latest Activities",
      basedOnLevel: "Based on Level",
      basedOnLocation: "Based on Location",
      mutualFriends: "Mutual Friends",
      playedWith: "Played with your friends",
      achievedPoints: "Achieved points",
      leveledUp: "Leveled up",
      joinedTournament: "Joined tournament",
      bookedMatch: "Booked a match"
    },
    // Profile
    profile: {
      myProfile: "My Profile",
      statistics: "Statistics",
      matchesPlayed: "Tournaments Played",
      winRate: "Win Rate",
      totalPoints: "Total Points",
      ranking: "Ranking",
      level: "Level",
      currentLevel: "Current Level",
      notifications: "Notifications",
      wallet: "Wallet",
      availableBalance: "Available Balance",
      topUpBalance: "Top Up",
      withdrawBalance: "Withdraw",
      friendsList: "Friends List",
      favoritesList: "Favorites",
      favoritePartner: "Your Favorite Partner",
      generalSettings: "General Settings",
      friends: "Friends",
      favorites: "Favorites"
    },
    // Settings
    settings: {
      changeLanguage: "Change Language",
      contactUs: "Contact Us",
      accountSettings: "Account Settings",
      termsAndConditions: "Terms & Conditions",
      privacyPolicy: "Privacy Policy",
      refundPolicy: "Refund Policy",
      arabic: "Arabic",
      english: "English",
      currentLanguage: "Current Language"
    },
    // Contact
    contact: {
      whatsapp: "WhatsApp",
      email: "Email",
      liveChat: "Live Chat",
      sendMessage: "Send Message",
      workingHours: "Working Hours",
      contactViaWhatsApp: "Contact us via WhatsApp",
      sendEmail: "Send us an email",
      chatWithSupport: "Chat with support team",
      onlineNow: "Online Now",
      subject: "Subject",
      message: "Message",
      writeYourMessage: "Write your message here..."
    },
    // Time
    time: {
      today: "Today",
      tomorrow: "Tomorrow",
      yesterday: "Yesterday",
      thisWeek: "This Week",
      thisMonth: "This Month",
      am: "AM",
      pm: "PM"
    },
    // Status
    status: {
      confirmed: "Confirmed",
      pending: "Pending",
      cancelled: "Cancelled",
      active: "Active",
      inactive: "Inactive",
      available: "Available",
      booked: "Booked",
      maintenance: "Maintenance"
    }
  }
};
const getFullTranslation = (key, lang = "ar") => {
  const keys = key.split(".");
  let value = fullTranslations[lang];
  for (const k of keys) {
    value = value?.[k];
  }
  return value || key;
};
export {
  fullTranslations,
  getFullTranslation
};
