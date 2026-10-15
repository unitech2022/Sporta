import 'package:flutter/material.dart';

import '../../americano/presentation/pages/americano_detail_page.dart';
import '../../coaches/presentation/pages/coach_bookings_page.dart';
import '../../event_chat/presentation/pages/event_chat_page.dart';
import '../../friends/presentation/pages/friends_page.dart';
import '../../matches/presentation/pages/match_detail_page.dart';
import '../../memberships/presentation/pages/my_memberships_page.dart';
import '../../memberships/presentation/pages/venue_memberships_page.dart';
import '../../profile/presentation/pages/my_bookings_page.dart';
import '../../reviews/domain/review_models.dart';
import '../../reviews/presentation/pages/court_reviews_page.dart';
import '../../reviews/presentation/widgets/rate_experience_sheet.dart';
import '../../support/presentation/pages/support_chat_page.dart';
import '../../venue/presentation/pages/manage_bookings_page.dart';
import '../../venue/presentation/pages/manage_venues_page.dart';

/// Opens the screen a notification refers to, based on its `type` and
/// `referenceId`. Shared by the in-app notifications list and push taps
/// (OneSignal click handler), so both land on the same page.
///
/// [context] must sit under the app's [Navigator] (a page context, or the
/// navigator key's `currentContext`).
void openNotificationTarget(
  BuildContext context, {
  required String type,
  int? referenceId,
}) {
  final nav = Navigator.of(context);
  void push(Widget Function(VoidCallback onBack) page) {
    nav.push(MaterialPageRoute<void>(builder: (_) => page(nav.pop)));
  }

  // Friend/follow notifications open the friends hub (no reference id needed).
  if (type.startsWith('friend_') || type == 'follow') {
    push((back) => FriendsPage(onBack: back));
    return;
  }

  // تقييم التجربة: اللاعب يفتح نافذة التقييم (court_rating قديم = مباراة)،
  // والمالك يفتح تقييمات ملعبه (المرجع معرّف الملعب). قبل قاعدة court_.
  final reviewCtx = switch (type) {
    'review_match' || 'court_rating' => ReviewContext.match,
    'review_booking' => ReviewContext.booking,
    'review_session' => ReviewContext.session,
    _ => null,
  };
  if (reviewCtx != null) {
    if (referenceId != null) openReviewSheet(context, reviewCtx, referenceId);
    return;
  }
  if (type == 'court_rated') {
    if (referenceId != null) {
      push((_) => CourtReviewsPage(courtId: referenceId));
    }
    return;
  }

  // عضويات الأندية: المالك يفتح عضويات ناديه (المرجع معرّف النادي)،
  // واللاعب يفتح «عضوياتي».
  if (type == 'membership_new' && referenceId != null) {
    push((_) => VenueMembershipsPage(venueId: referenceId));
    return;
  }
  if (type.startsWith('membership_')) {
    push((_) => const MyMembershipsPage());
    return;
  }

  // Admin moderation of a venue/court — open the owner's venues management.
  if (type.startsWith('venue_') || type.startsWith('court_')) {
    push((back) => ManageVenuesPage(onBack: back));
    return;
  }

  // طلب حجز جديد يصل لمالك الملعب: يفتح إدارة حجوزات ملاعبه.
  if (type == 'booking_created') {
    push((back) => ManageBookingsPage(onBack: back));
    return;
  }
  // Court booking status changes open the player's courts bookings tab.
  if (type.startsWith('booking_')) {
    push((back) => MyBookingsPage(onBack: back, initialTab: 2));
    return;
  }

  // جلسات التدريب: طلب جديد/تقييم من لاعب يصل للمدرب فيفتح حجوزاته،
  // والباقي (تأكيد/رفض/إلغاء/تقييم المدرب) يصل للاعب فيفتح تبويب التقييمات.
  if (type == 'coach_session_request' ||
      type == 'coach_rated_by_player' ||
      type == 'coach_session_player_cancelled') {
    push((_) => const CoachBookingsPage());
    return;
  }
  if (type.startsWith('coach_session_')) {
    push((back) => MyBookingsPage(onBack: back, initialTab: 1));
    return;
  }

  if (type == 'support_chat') {
    push((_) => const SupportChatPage());
    return;
  }

  if (referenceId == null) return;
  // دردشة الحدث: المرجع معرّف المباراة الأساسية، فتُفتح الدردشة مباشرة.
  if (type == 'event_chat') {
    push((_) => EventChatPage(matchId: referenceId));
    return;
  }
  // Americano notifications carry the americano id; match ones the match id.
  // إشعارات البطولة الإقصائية تحمل معرّف الأمريكانو نفسه، وصفحته تحوّل
  // تلقائياً إلى صفحة البطولة. يشمل ذلك الإلغاء (americano_cancelled،
  // tournament_cancelled) وحسم/تسجيل المنظّم للنتيجة
  // (tournament_result_resolved): الصفحة تعرض الحالة الملغاة أو النتيجة.
  // match_cancelled/match_expired تحمل معرّف المباراة فتفتح تفاصيلها.
  if (type.startsWith('americano_') || type.startsWith('tournament_')) {
    push(
      (back) => AmericanoDetailPage(americanoId: referenceId, onBack: back),
    );
  } else if (type.startsWith('match_')) {
    push((_) => MatchDetailPage(matchId: referenceId));
  }
}
