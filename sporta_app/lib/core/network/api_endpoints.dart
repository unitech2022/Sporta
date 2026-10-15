import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

abstract class ApiEndpoints {
  /// Local backend port (see SportaApis appsettings.Development.json → urls).
  /// 7050 وليس 7000 لأن مشروعاً آخر على نفس الجهاز يحجز 7000 فيلتقط طلبات
  /// `localhost` قبل الـ API.
  static const int _port = 7050;

  /// Production API origin.
  static const String _productionOrigin = 'https://apis.sportaapp.net';

  /// الافتراضي **خادم الإنتاج** (طُلب في 2026-08-20). للعمل على الباك إند
  /// المحلي مرّر `--dart-define=USE_PRODUCTION_API=false`. انتبه: الحسابات
  /// التجريبية المزروعة لا تعمل على الإنتاج.
  static const bool _useProductionApi = bool.fromEnvironment(
    'USE_PRODUCTION_API',
    defaultValue: true,
  );

  /// Base URL. Defaults to [_productionOrigin]. Pass
  /// `--dart-define=USE_PRODUCTION_API=false` for the local backend, resolved
  /// per platform:
  /// - Android emulator reaches the host machine via 10.0.2.2 (not localhost).
  /// - iOS simulator / macOS / web reach it directly via localhost.
  /// - Physical devices need the machine's LAN IP — set [_lanIpOverride].
  static String get baseUrl {
    if (_useProductionApi) return '$_productionOrigin/api';
    if (_lanIpOverride != null) return 'http://$_lanIpOverride:$_port/api';
    if (kIsWeb) return 'http://localhost:$_port/api';
    if (Platform.isAndroid) return 'http://10.0.2.2:$_port/api';
    return 'http://localhost:$_port/api';
  }

  /// جهاز حقيقي على الواي فاي لا يرى `localhost` الخاص بالكمبيوتر، فمرّر عنوان
  /// الشبكة المحلية: `--dart-define=API_HOST=192.168.1.21`. اتركه فارغاً
  /// للمحاكي/السيميوليتر.
  static const String _apiHost = String.fromEnvironment('API_HOST');
  static String? get _lanIpOverride => _apiHost.isEmpty ? null : _apiHost;

  static const String register = '/auth/register';

  // ── الجهاز الموثوق (بصمة) ──────────────────────────────────────────────────
  /// الدخول اليومي: الرقم + سرّ الجهاز بعد بصمة النظام — بلا رمز.
  static const String deviceLogin = '/auth/login/device';

  /// يسجّل هذا الهاتف جهازاً موثوقاً ويُسلّم سرّه مرة واحدة (يتطلب جلسة).
  static const String enrollDevice = '/auth/devices/enroll';
  static const String refreshToken = '/auth/refresh';

  // ── رموز التحقق عبر واتساب ─────────────────────────────────────────────────
  /// يطلب إرسال رمز على واتساب؛ الغرض يُرسَل معه (login | register | delete).
  static const String requestOtp = '/auth/otp/request';

  /// دخول برمز واتساب — للهاتف غير الموثوق قبل أن يسجّل بصمته.
  static const String otpLogin = '/auth/otp/login';

  /// يُبدّل الرمز بتذكرة تُقدَّم للخطوة التالية (تسجيل، حذف حساب).
  static const String otpVerify = '/auth/otp/verify';
  static const String updateLanguage = '/users/language';
  static const String updateProfile = '/users/me';
  static const String uploadAvatar = '/users/avatar';
  static const String addRole = '/users/roles';

  /// حذف ناعم لدور من الحساب — يعيد جلسة جديدة بلا صلاحية الدور المحذوف.
  static String deleteRole(String role) => '/users/roles/$role';
  static const String userLocation = '/users/location';

  /// فحص موقع ضد مناطق الخدمة (عام، بلا توكن).
  static const String serviceZoneCheck = '/service-zones/check';

  /// حذف الحساب نهائياً (DELETE) — متطلب App Store 5.1.1(v).
  static const String deleteAccount = '/users/me';

  /// Server origin (baseUrl without the trailing `/api`).
  static String get origin {
    final b = baseUrl;
    return b.endsWith('/api') ? b.substring(0, b.length - 4) : b;
  }

  /// Builds an absolute URL for a server file path (e.g. `/uploads/...`).
  static String fileUrl(String path) =>
      path.startsWith('http') ? path : '$origin$path';
  static const String uploadImage = '/uploads/image';
  static const String supportPhone = '/settings/support-phone';
  static const String publicSettings = '/settings/public';
  static const String assessmentQuestions = '/assessment/questions';
  static const String assessmentLevels = '/assessment/levels';
  static const String levelAssessment = '/players/level-assessment';
  static const String levelVideo = '/players/level-assessment/video';
  static const String levelCoach = '/players/level-assessment/coach';
  static const String myAssessments = '/players/level-assessments';
  static const String coachPendingAssessments = '/coaches/assessments/pending';
  static String assignAssessment(int id) => '/coaches/assessments/$id/assign';
  static const String playerProfile = '/players/me';
  static const String favoriteSport = '/players/favorite-sport';

  static const String cities = '/locations/cities';
  static String cityDistricts(int cityId) => '/locations/cities/$cityId/districts';

  static const String sports = '/sports';
  static const String coachSpecializations = '/coach-specializations';
  static const String venueOptions = '/venues/options';

  static const String courts = '/courts';
  static String court(int id) => '/courts/$id';
  static String courtAvailability(int id) => '/courts/$id/availability';
  static const String favoriteCourts = '/courts/favorites';
  static String courtFavorite(int id) => '/courts/$id/favorite';

  static const String bookings = '/bookings';
  static const String bookingQuote = '/bookings/quote';
  static const String myBookings = '/bookings/me';
  static String cancelBooking(int id) => '/bookings/$id/cancel';

  static const String coaches = '/coaches';
  static String coach(int id) => '/coaches/$id';
  static String coachSessions(int id) => '/coaches/$id/sessions';
  static const String myCoachSessions = '/coaches/sessions/me';
  static const String coachSessionRequests = '/coaches/sessions/requests';
  static const String coachBookings = '/coaches/bookings';
  static const String coachMe = '/coaches/me';
  static String respondCoachSession(int id) => '/coaches/sessions/$id/respond';
  static String rateCoachSession(int id) => '/coaches/sessions/$id/rate';
  static String rateCoachOfSession(int id) =>
      '/coaches/sessions/$id/rate-coach';
  static const String coachDashboard = '/coaches/dashboard';
  static const String coachStudents = '/coaches/students';
  static const String coachRevenue = '/coaches/revenue';
  static const String coachOffers = '/coaches/offers';
  static String setCoachOfferActive(int id) => '/coaches/offers/$id/active';
  static String coachOffer(int id) => '/coaches/offers/$id';
  static const String venueDashboard = '/venues/dashboard';
  static const String venueRevenue = '/venues/revenue';
  static const String myVenues = '/venues/mine';
  static const String venueBookings = '/venues/bookings';
  static String respondVenueBooking(int id) => '/venues/bookings/$id/respond';
  static const String venueMatchRequests = '/venues/match-requests';
  static String venueMatchRequest(int id) => '/venues/match-requests/$id';
  static String respondVenueMatchRequest(int id) =>
      '/venues/match-requests/$id/respond';
  static const String createVenue = '/venues';
  static String addCourt(int venueId) => '/venues/$venueId/courts';
  static String updateCourt(int courtId) => '/venues/courts/$courtId';
  static String deleteCourt(int courtId) => '/venues/courts/$courtId';
  static String venuePricing(int venueId) => '/venues/$venueId/pricing';
  // عضويات الأندية.
  static String venueMemberships(int venueId) =>
      '/venues/$venueId/memberships';
  static String venueMembershipPlans(int venueId) =>
      '/venues/$venueId/membership-plans';
  static String membershipPlan(int id) => '/venues/membership-plans/$id';
  static String venueBookingWindow(int venueId) =>
      '/venues/$venueId/booking-window';
  static String membershipForVenue(int venueId) =>
      '/memberships/venue/$venueId';
  static const String membershipSubscribe = '/memberships/subscribe';
  static String membershipAutoRenew(int id) => '/memberships/$id/auto-renew';
  static const String myMemberships = '/memberships/me';
  static const String membershipEventShare = '/memberships/event-share';
  static const String membershipCourtShare = '/memberships/court-share';
  static String courtSchedule(int courtId) =>
      '/venues/courts/$courtId/schedule';
  static String courtSlots(int courtId) => '/venues/courts/$courtId/slots';
  static String toggleCourtSlot(int courtId) =>
      '/venues/courts/$courtId/slots/toggle';
  static String bulkCourtSlots(int courtId) =>
      '/venues/courts/$courtId/slots/bulk';

  static const String matches = '/matches';
  static const String myMatches = '/matches/me';
  static const String upcomingMatches = '/matches/upcoming';
  static String match(int id) => '/matches/$id';
  static String joinMatch(int id) => '/matches/$id/join';

  /// لاعب من الفريق الآخر يؤكد النتيجة المقترحة أو يرفضها.
  static String matchResultRespond(int id) => '/matches/$id/result/respond';

  /// المنظّم يحسم خلافاً على النتيجة.
  static String matchResultResolve(int id) => '/matches/$id/result/resolve';

  /// إلغاء حدث يستضيفه صاحب الملعب (يردّ حصص المسجّلين).
  static String cancelMatch(int id) => '/matches/$id/cancel';
  static String makeMatchPublic(int id) => '/matches/$id/make-public';
  static String inviteMatch(int id) => '/matches/$id/invite';
  static String respondMatchInvite(int id) => '/matches/$id/invite/respond';
  static String matchRequests(int id) => '/matches/$id/requests';
  static String respondMatchRequest(int id) => '/matches/$id/requests/respond';
  static String withdrawMatch(int id) => '/matches/$id/withdraw';
  static String matchWaitlist(int id) => '/matches/$id/waitlist';
  static String respondMatchWithdrawal(int id) => '/matches/$id/withdraw/respond';

  static const String americano = '/americano';
  static const String myAmericano = '/americano/me';
  static String americanoById(int id) => '/americano/$id';
  static String americanoJoin(int id) => '/americano/$id/join';
  static String americanoInvite(int id) => '/americano/$id/invite';
  static String americanoInviteRespond(int id) => '/americano/$id/invite/respond';

  /// المنظّم يقبل/يرفض طلب انضمام (أمريكانو أو بطولة).
  static String americanoRequestRespond(int id) => '/americano/$id/requests/respond';
  static String americanoWithdraw(int id) => '/americano/$id/withdraw';
  static String americanoWaitlist(int id) => '/americano/$id/waitlist';
  static String americanoWithdrawRespond(int id) => '/americano/$id/withdraw/respond';
  static String americanoRoundScore(int roundId) =>
      '/americano/rounds/$roundId/score';
  static String americanoRoundScoreRespond(int roundId) =>
      '/americano/rounds/$roundId/score/respond';
  static String americanoRoundScoreResolve(int roundId) =>
      '/americano/rounds/$roundId/score/resolve';

  // ── البطولة الإقصائية (كأس) ──
  static const String cups = '/tournaments';
  static const String cupQuote = '/tournaments/quote';
  static String cupById(int id) => '/tournaments/$id';
  static String cupFixtureScore(int fixtureId) =>
      '/tournaments/fixtures/$fixtureId/score';
  static String cupFixtureScoreRespond(int fixtureId) =>
      '/tournaments/fixtures/$fixtureId/score/respond';
  static String cupFixtureScoreResolve(int fixtureId) =>
      '/tournaments/fixtures/$fixtureId/score/resolve';
  static String cupFixtureScoreOrganizer(int fixtureId) =>
      '/tournaments/fixtures/$fixtureId/score/organizer';
  static String cupStart(int id) => '/tournaments/$id/start';
  static String cupTeamName(int id, int team) => '/tournaments/$id/teams/$team/name';

  // ── دعوة الأصدقاء لحدث ──
  static const String invites = '/invites';
  static const String invitesMine = '/invites/mine';
  static String inviteDecline(int id) => '/invites/$id/decline';
  static String cupPostpone(int id) => '/tournaments/$id/postpone';
  static String cupCancel(int id) => '/tournaments/$id/cancel';

  static const String friends = '/friends';
  static const String friendsSearch = '/friends/search';
  static const String friendsSuggestions = '/friends/suggestions';
  static const String friendRequests = '/friends/requests';
  static String respondFriendRequest(int id) => '/friends/requests/$id/respond';
  static String friendFavorite(int userId) => '/friends/$userId/favorite';

  static const String wallet = '/wallet';
  static const String walletTransactions = '/wallet/transactions';
  /// Opens a hosted checkout session at the gateway (charges nothing).
  static const String walletTopUpSession = '/wallet/topup/session';

  /// Settles a session after the checkout page closes. The server re-reads the
  /// payment from the gateway, so this call cannot credit anything by itself.
  static const String walletTopUpConfirm = '/wallet/topup/confirm';

  /// One-shot Apple Pay top-up: the PassKit token goes to the server, which
  /// forwards it to the gateway and credits the wallet in the same call.
  static const String walletTopUpApplePay = '/wallet/topup/applepay';

  /// Fee + total for a given top-up amount (computed server-side only).
  static const String walletTopUpQuote = '/wallet/topup-quote';
  static const String walletPaymentConfig = '/wallet/payment-config';
  static const String walletWithdraw = '/wallet/withdraw';
  static const String walletWithdrawals = '/wallet/withdrawals';
  static String walletWithdrawalProcess(int id) => '/wallet/withdrawals/$id';

  static const String points = '/points';
  static const String pointsRedeem = '/points/redeem';
  static const String pointsLeaderboard = '/points/leaderboard';

  /// سُلَّم المستويات المعروض (يُدار من لوحة التحكم).
  static const String levels = '/levels';

  static const String subscription = '/subscription';
  static const String subscriptionPackages = '/subscription/packages';
  static const String subscribe = '/subscription/subscribe';
  static const String subscriptionCancel = '/subscription/cancel';

  static const String following = '/follow/following';
  static const String followers = '/follow/followers';
  static String follow(int userId) => '/follow/$userId';

  static const String feed = '/feed';

  /// Community-wide activity ("نبض المجتمع الرياضي"), unlike [feed] which is
  /// scoped to the players you follow.
  static const String pulse = '/pulse';

  static const String tournaments = '/tournaments';

  static const String ads = '/ads';

  // ── الدعم الفني (دردشة فورية مع الإدارة) ──────────────────────────────────

  /// محادثتي وأحدث صفحة من رسائلها.
  static const String supportChatMine = '/support-chat/mine';
  static const String supportChatSend = '/support-chat/mine/messages';
  static const String supportChatRead = '/support-chat/mine/read';
  static const String supportChatUnread = '/support-chat/mine/unread-count';

  /// مسار الـ SignalR hub (خارج مسار /api).
  static String get supportChatHub => '$origin/hubs/support-chat';

  // ── دردشة أعضاء الحدث (مباراة/أمريكانو/بطولة بمعرّف المباراة الأساسية) ──
  static String get eventChatHub => '$origin/hubs/event-chat';
  // التقييم المتبادل بعد التجربة (match | booking | session)
  static String reviewSession(String context, int id) => '/reviews/$context/$id';
  static const String pendingReviews = '/reviews/pending';
  static String courtRatings(int courtId) => '/courts/$courtId/ratings';
  static String playerReputation(int userId) => '/players/$userId/reputation';
  static String eventChat(int matchId) => '/event-chat/$matchId';
  static String eventChatMessages(int matchId) => '/event-chat/$matchId/messages';
  static String eventChatMessage(int matchId, int id) =>
      '/event-chat/$matchId/messages/$id';
  static String eventChatRead(int matchId) => '/event-chat/$matchId/read';
  static String eventChatAttachments(int matchId) => '/event-chat/$matchId/attachments';
  static String eventChatReaction(int matchId, int id) =>
      '/event-chat/$matchId/messages/$id/reaction';

  static const String notifications = '/notifications';
  static const String notificationsUnread = '/notifications/unread-count';
  static const String notificationsReadAll = '/notifications/read-all';
  static String notificationRead(int id) => '/notifications/$id/read';
}
