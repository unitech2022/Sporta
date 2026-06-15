/// Supported application languages.
enum AppLanguage {
  ar,
  en;

  bool get isRtl => this == AppLanguage.ar;
}

/// Central translation table (ported from translations.ts).
/// Feature-specific keys are appended as features are converted.
abstract class AppTranslations {
  static String of(AppLanguage language, String key) {
    final table = language == AppLanguage.ar ? _ar : _en;
    return table[key] ?? key;
  }

  static const Map<String, String> _ar = {
    // Common
    'back': 'رجوع',
    'save': 'حفظ',
    'cancel': 'إلغاء',
    'confirm': 'تأكيد',
    'delete': 'حذف',
    'edit': 'تعديل',
    'search': 'بحث',
    'viewAll': 'عرض الكل',
    'loading': 'جاري التحميل...',
    'comingSoon': 'قريباً',

    // Auth
    'login': 'تسجيل الدخول',
    'register': 'إنشاء حساب',
    'firstName': 'الاسم الأول',
    'lastName': 'الاسم الأخير',
    'firstNameHint': 'أدخل اسمك الأول',
    'lastNameHint': 'أدخل اسمك الأخير',
    'gender': 'الجنس',
    'male': 'ذكر',
    'female': 'أنثى',
    'city': 'المدينة',
    'cityHint': 'مثال: الرياض',
    'district': 'الحي',
    'districtHint': 'مثال: العليا',
    'logout': 'تسجيل الخروج',
    'email': 'البريد الإلكتروني',
    'password': 'كلمة المرور',
    'phone': 'رقم الجوال',
    'appTagline': 'تطبيق حجز وإدارة المباريات',
    'brandTagline': 'تجربة رياضية متكاملة',
    'createNewAccount': 'إنشاء حساب جديد',
    'registerRolesHint':
        '💡 يمكنك بعد التسجيل الأولي من صفحتك أن تنضم كلاعب أو مدرب أو ملعب',
    'haveAccount': 'لديك حساب بالفعل؟',
    'welcomeBackExcl': 'أهلاً بعودتك!',
    'rememberMe': 'تذكرني',
    'forgotPassword': 'نسيت كلمة السر؟',
    'biometricTitle': 'تفعيل تسجيل الدخول ببصمة الوجه',
    'biometricDesc': 'سيتم حفظ بياناتك بشكل آمن لتسجيل الدخول السريع',

    // Validation
    'fieldRequired': 'هذا الحقل مطلوب',
    'nameTooShort': 'الاسم يجب أن يكون حرفين على الأقل',
    'invalidEmail': 'البريد الإلكتروني غير صحيح',
    'invalidPhone': 'رقم الجوال غير صحيح (يجب أن يبدأ بـ 05 ويتكون من 10 أرقام)',
    'passwordTooShort': 'كلمة السر يجب أن تكون 8 أحرف على الأقل',
    'passwordWeak': 'يجب أن تحتوي كلمة السر على أحرف وأرقام',
    'passwordsNotMatch': 'كلمة السر غير متطابقة',
    'genderRequired': 'يرجى اختيار الجنس',
    'cityRequired': 'يرجى إدخال المدينة',
    'roleRequired': 'يرجى اختيار دور واحد على الأقل',

    // Forgot password flow
    'forgotPasswordTitle': 'نسيت كلمة السر',
    'forgotPasswordDesc': 'أدخل رقم جوالك وسنرسل لك رمز التحقق',
    'sendOtp': 'إرسال رمز التحقق',
    'otpTitle': 'رمز التحقق',
    'otpDesc': 'تم إرسال رمز مكون من 6 أرقام إلى',
    'otpHint': 'أدخل الرمز',
    'verifyOtp': 'تحقق',
    'resendOtp': 'إعادة إرسال الرمز',
    'resendIn': 'إعادة الإرسال بعد',
    'newPasswordTitle': 'كلمة السر الجديدة',
    'newPassword': 'كلمة السر الجديدة',
    'confirmPassword': 'تأكيد كلمة السر',
    'resetPassword': 'تغيير كلمة السر',
    'passwordResetSuccess': 'تم تغيير كلمة السر بنجاح',

    // Generic errors / states
    'tryAgain': 'حاول مجدداً',
    'seconds': 'ثانية',
    'step': 'خطوة',
    'of': 'من',
    'next': 'التالي',
    'createAccount': 'إنشاء الحساب',

    // Role details (coach / venue)
    'roleDetailsTitle': 'تفاصيل الدور',
    'roleDetailsSubtitle':
        'أكمل البيانات الخاصة بالأدوار التي اخترتها',
    'coachInfo': 'بيانات المدرب',
    'coachSpecialization': 'التخصص',
    'coachSpecializationHint': 'مثال: تدريب بادل، تنس',
    'coachHourlyRate': 'السعر بالساعة (ريال)',
    'coachHourlyRateHint': 'مثال: 150',
    'coachBio': 'نبذة تعريفية',
    'coachBioHint': 'اكتب نبذة مختصرة عن خبرتك',
    'venueInfo': 'بيانات الملعب',
    'venueName': 'اسم الملعب / النادي',
    'venueNameHint': 'مثال: نادي الرياض الرياضي',
    'venueAddress': 'العنوان',
    'venueAddressHint': 'الشارع والحي',
    'venueCity': 'المدينة',
    'venueDescription': 'وصف الملعب',
    'venueDescriptionHint': 'المرافق والخدمات المتوفرة',
    'venueGenderPolicy': 'سياسة الدخول',
    'venuePolicyMixed': 'مختلط',
    'venuePolicyWomenOnly': 'نساء فقط',
    'venuePolicyFamilyOnly': 'عائلات فقط',
    'invalidRate': 'يرجى إدخال سعر صحيح',

    // Level assessment
    'levelAssessmentTitle': 'تحديد مستواك',
    'levelAssessmentSubtitle': 'أجب عن الأسئلة لنحدد مستواك في البادل',
    'levelQuestionLabel': 'سؤال',
    'calculateMyLevel': 'احسب مستواي',
    'yourLevelIs': 'مستواك هو',
    'levelResultHint': 'يمكنك رفع مستواك بمزيد من المباريات والتقييمات',
    'startNow': 'ابدأ الآن',
    'unexpectedError': 'حدث خطأ غير متوقع',
    'yourLevel': 'مستواك',
    'assessLevelCta': 'حدد مستواك الآن',
    'levelNotAssessed': 'لم تحدد مستواك بعد',
    'completeLevelBanner': 'أكمل تقييم مستواك للحصول على تجربة أفضل',

    // Navigation
    'home': 'الرئيسية',
    'matches': 'المباريات',
    'courts': 'الملاعب',
    'coaches': 'المدربين',
    'profile': 'صفحتي',

    // User roles
    'player': 'لاعب',
    'coach': 'مدرب',
    'venue': 'ملعب',
    'venueOwner': 'مالك ملعب',

    // Home
    'welcomeBack': 'مرحباً بعودتك',
    'upcomingMatches': 'المباريات القادمة',
    'nearbyMatches': 'مباريات قريبة منك',
    'tournaments': 'البطولات',
    'friendActivity': 'نشاط الأصدقاء',
    'friendSuggestions': 'اقتراحات الأصدقاء',
    'latestActivities': 'آخر الأنشطة',

    // Profile
    'myProfile': 'صفحتي',
    'statistics': 'الإحصائيات',
    'matchesPlayed': 'البطولات التي لعبتها',
    'winRate': 'نسبة الفوز',
    'totalPoints': 'مجموع النقاط',
    'ranking': 'الترتيب',
    'level': 'المستوى',
    'notifications': 'الإشعارات',
    'wallet': 'المحفظة',
    'availableBalance': 'الرصيد المتاح',
    'topUpBalance': 'شحن الرصيد',
    'withdrawBalance': 'سحب الرصيد',
    'friendsList': 'قائمة الأصدقاء',
    'favoritesList': 'القائمة المفضلة',
    'generalSettings': 'الإعدادات العامة',

    // Settings
    'changeLanguage': 'تغيير اللغة',
    'contactUs': 'اتصل بنا',
    'accountSettings': 'إعدادات الحساب',
    'termsAndConditions': 'الشروط والأحكام',
    'privacyPolicy': 'سياسة الخصوصية',
    'refundPolicy': 'سياسة الاسترجاع',

    // Contact
    'whatsapp': 'واتساب',
    'liveChat': 'الدردشة المباشرة',
    'sendMessage': 'إرسال رسالة',
    'workingHours': 'أوقات العمل',

    // Time
    'today': 'اليوم',
    'tomorrow': 'غداً',
    'thisWeek': 'هذا الأسبوع',
    'thisMonth': 'هذا الشهر',

    // Status
    'confirmed': 'مؤكدة',
    'pending': 'قيد الانتظار',
    'cancelled': 'ملغاة',
    'active': 'نشط',
    'inactive': 'غير نشط',
  };

  static const Map<String, String> _en = {
    // Common
    'back': 'Back',
    'save': 'Save',
    'cancel': 'Cancel',
    'confirm': 'Confirm',
    'delete': 'Delete',
    'edit': 'Edit',
    'search': 'Search',
    'viewAll': 'View All',
    'loading': 'Loading...',
    'comingSoon': 'Coming Soon',

    // Auth
    'login': 'Login',
    'register': 'Sign Up',
    'firstName': 'First Name',
    'lastName': 'Last Name',
    'firstNameHint': 'Enter your first name',
    'lastNameHint': 'Enter your last name',
    'gender': 'Gender',
    'male': 'Male',
    'female': 'Female',
    'city': 'City',
    'cityHint': 'e.g. Riyadh',
    'district': 'District',
    'districtHint': 'e.g. Al-Olaya',
    'logout': 'Logout',
    'email': 'Email',
    'password': 'Password',
    'phone': 'Phone Number',
    'appTagline': 'Padel Court Booking App and Match Management',
    'brandTagline': 'A Complete Sports Experience',
    'createNewAccount': 'Create New Account',
    'registerRolesHint':
        '💡 After initial registration, you can join as a player, coach, or venue from your profile',
    'haveAccount': 'Already have an account?',
    'welcomeBackExcl': 'Welcome Back!',
    'rememberMe': 'Remember Me',
    'forgotPassword': 'Forgot Password?',
    'biometricTitle': 'Enable Face ID Login',
    'biometricDesc': 'Your data will be securely saved for quick login',

    // Validation
    'fieldRequired': 'This field is required',
    'nameTooShort': 'Name must be at least 2 characters',
    'invalidEmail': 'Invalid email address',
    'invalidPhone': 'Invalid phone number (must start with 05, 10 digits)',
    'passwordTooShort': 'Password must be at least 8 characters',
    'passwordWeak': 'Password must contain letters and numbers',
    'passwordsNotMatch': 'Passwords do not match',
    'genderRequired': 'Please select your gender',
    'cityRequired': 'Please enter your city',
    'roleRequired': 'Please select at least one role',

    // Forgot password flow
    'forgotPasswordTitle': 'Forgot Password',
    'forgotPasswordDesc': 'Enter your phone number and we\'ll send you a verification code',
    'sendOtp': 'Send Verification Code',
    'otpTitle': 'Verification Code',
    'otpDesc': 'A 6-digit code was sent to',
    'otpHint': 'Enter the code',
    'verifyOtp': 'Verify',
    'resendOtp': 'Resend Code',
    'resendIn': 'Resend in',
    'newPasswordTitle': 'New Password',
    'newPassword': 'New Password',
    'confirmPassword': 'Confirm Password',
    'resetPassword': 'Reset Password',
    'passwordResetSuccess': 'Password reset successfully',

    // Generic errors / states
    'tryAgain': 'Try Again',
    'seconds': 'sec',
    'step': 'Step',
    'of': 'of',
    'next': 'Next',
    'createAccount': 'Create Account',

    // Role details (coach / venue)
    'roleDetailsTitle': 'Role Details',
    'roleDetailsSubtitle': 'Complete the details for the roles you selected',
    'coachInfo': 'Coach Details',
    'coachSpecialization': 'Specialization',
    'coachSpecializationHint': 'e.g. Padel, Tennis coaching',
    'coachHourlyRate': 'Hourly Rate (SAR)',
    'coachHourlyRateHint': 'e.g. 150',
    'coachBio': 'Bio',
    'coachBioHint': 'Write a short bio about your experience',
    'venueInfo': 'Venue Details',
    'venueName': 'Venue / Club Name',
    'venueNameHint': 'e.g. Riyadh Sports Club',
    'venueAddress': 'Address',
    'venueAddressHint': 'Street and district',
    'venueCity': 'City',
    'venueDescription': 'Venue Description',
    'venueDescriptionHint': 'Available facilities and services',
    'venueGenderPolicy': 'Entry Policy',
    'venuePolicyMixed': 'Mixed',
    'venuePolicyWomenOnly': 'Women Only',
    'venuePolicyFamilyOnly': 'Families Only',
    'invalidRate': 'Please enter a valid rate',

    // Level assessment
    'levelAssessmentTitle': 'Find Your Level',
    'levelAssessmentSubtitle': 'Answer a few questions to set your padel level',
    'levelQuestionLabel': 'Question',
    'calculateMyLevel': 'Calculate My Level',
    'yourLevelIs': 'Your level is',
    'levelResultHint': 'You can raise your level with more matches and ratings',
    'startNow': 'Start Now',
    'unexpectedError': 'An unexpected error occurred',
    'yourLevel': 'Your Level',
    'assessLevelCta': 'Assess your level now',
    'levelNotAssessed': "You haven't set your level yet",
    'completeLevelBanner': 'Complete your level assessment for a better experience',

    // Navigation
    'home': 'Home',
    'matches': 'Matches',
    'courts': 'Courts',
    'coaches': 'Coaches',
    'profile': 'My Profile',

    // User roles
    'player': 'Player',
    'coach': 'Coach',
    'venue': 'Venue',
    'venueOwner': 'Venue Owner',

    // Home
    'welcomeBack': 'Welcome Back',
    'upcomingMatches': 'Upcoming Matches',
    'nearbyMatches': 'Matches Near You',
    'tournaments': 'Tournaments',
    'friendActivity': 'Friend Activity',
    'friendSuggestions': 'Friend Suggestions',
    'latestActivities': 'Latest Activities',

    // Profile
    'myProfile': 'My Profile',
    'statistics': 'Statistics',
    'matchesPlayed': 'Tournaments Played',
    'winRate': 'Win Rate',
    'totalPoints': 'Total Points',
    'ranking': 'Ranking',
    'level': 'Level',
    'notifications': 'Notifications',
    'wallet': 'Wallet',
    'availableBalance': 'Available Balance',
    'topUpBalance': 'Top Up',
    'withdrawBalance': 'Withdraw',
    'friendsList': 'Friends List',
    'favoritesList': 'Favorites',
    'generalSettings': 'General Settings',

    // Settings
    'changeLanguage': 'Change Language',
    'contactUs': 'Contact Us',
    'accountSettings': 'Account Settings',
    'termsAndConditions': 'Terms & Conditions',
    'privacyPolicy': 'Privacy Policy',
    'refundPolicy': 'Refund Policy',

    // Contact
    'whatsapp': 'WhatsApp',
    'liveChat': 'Live Chat',
    'sendMessage': 'Send Message',
    'workingHours': 'Working Hours',

    // Time
    'today': 'Today',
    'tomorrow': 'Tomorrow',
    'thisWeek': 'This Week',
    'thisMonth': 'This Month',

    // Status
    'confirmed': 'Confirmed',
    'pending': 'Pending',
    'cancelled': 'Cancelled',
    'active': 'Active',
    'inactive': 'Inactive',
  };
}
