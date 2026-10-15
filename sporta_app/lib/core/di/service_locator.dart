import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../features/americano/data/americano_repository.dart';
import '../../features/americano/presentation/cubit/americano_detail_cubit.dart';
import '../../features/americano/presentation/cubit/americano_list_cubit.dart';
import '../../features/cup/data/cup_repository.dart';
import '../../features/invites/data/event_invite_repository.dart';
import '../../features/cup/presentation/cubit/cup_detail_cubit.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/coaches/data/coach_repository.dart';
import '../../features/coaches/presentation/cubit/coach_dashboard_cubit.dart';
import '../../features/coaches/presentation/cubit/coaches_cubit.dart';
import '../../features/coaches/presentation/cubit/my_sessions_cubit.dart';
import '../../features/courts/data/court_favorites_hub.dart';
import '../../features/courts/data/court_repository.dart';
import '../../features/courts/presentation/cubit/book_court/book_court_cubit.dart';
import '../../features/courts/presentation/cubit/courts_list/courts_cubit.dart';
import '../../features/courts/presentation/cubit/favorite_courts/favorite_courts_cubit.dart';
import '../../features/friends/data/friend_repository.dart';
import '../../features/friends/presentation/cubit/feed_cubit.dart';
import '../../features/friends/presentation/cubit/friends_cubit.dart';
import '../../features/level/data/level_repository.dart';
import '../../features/locations/data/location_repository.dart';
import '../../features/sports/data/sport_repository.dart';
import '../../features/level/presentation/cubit/level_cubit.dart';
import '../../features/payment/data/subscription_repository.dart';
import '../../features/points/data/points_repository.dart';
import '../../features/payment/data/wallet_repository.dart';
import '../../features/payment/presentation/cubit/subscription_cubit.dart';
import '../../features/points/presentation/cubit/points_cubit.dart';
import '../../features/payment/presentation/cubit/wallet_cubit.dart';
import '../../features/matches/data/match_repository.dart';
import '../../features/matches/presentation/cubit/matches_cubit.dart';
import '../../features/matches/presentation/cubit/my_events_cubit.dart';
import '../../features/reviews/data/review_repository.dart';
import '../../features/reviews/presentation/cubit/court_reviews_cubit.dart';
import '../../features/event_chat/data/event_chat_repository.dart';
import '../../features/event_chat/presentation/cubit/event_chat_cubit.dart';
import '../../features/notifications/data/notification_repository.dart';
import '../../features/settings/data/settings_repository.dart';
import '../../features/support/data/support_hub.dart';
import '../../features/support/data/support_repository.dart';
import '../../features/support/presentation/cubit/support_chat_cubit.dart';
import '../../features/tournaments/data/tournament_repository.dart';
import '../../features/home/data/pulse_repository.dart';
import '../../features/ads/data/ad_repository.dart';
import '../../features/notifications/presentation/cubit/notifications_cubit.dart';
import '../../features/venue/data/venue_repository.dart';
import '../../features/memberships/data/membership_repository.dart';
import '../../features/venue/presentation/cubit/manage_venues_cubit.dart';
import '../../features/venue/presentation/cubit/venue_dashboard_cubit.dart';
import '../network/api_client.dart';
import '../state/app_settings.dart';

/// Global service locator. Register dependencies once in [setupLocator] (from
/// `main`) and resolve them with `getIt<T>()`.
final GetIt getIt = GetIt.instance;

/// Wires up the dependency graph: shared infrastructure → repositories → cubits.
/// Repositories are singletons (stateless, reusable); cubits are factories so
/// each screen gets a fresh instance tied to its own lifecycle.
void setupLocator() {
  // ── Core / infrastructure ──────────────────────────────────────────────────
  // The shared Dio instance already carries the auth/refresh interceptor.
  getIt.registerLazySingleton<Dio>(() => ApiClient.instance.dio);
  // App-wide settings (language/role), shared by AppScope and AuthCubit.
  getIt.registerLazySingleton<AppSettings>(() => AppSettings());

  // ── Repositories ─────────────────────────────────────────────────────────────
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(getIt<Dio>()),
  );
  // ناقل مشترك يبقي قلوب المفضّلة متسقة بين قائمة الملاعب وصفحة المفضّلة.
  getIt.registerLazySingleton<CourtFavoritesHub>(() => CourtFavoritesHub());
  getIt.registerLazySingleton<CourtRepository>(
    () => CourtRepository(getIt<Dio>()),
  );
  getIt.registerLazySingleton<CoachRepository>(
    () => CoachRepository(getIt<Dio>()),
  );
  getIt.registerLazySingleton<LevelRepository>(
    () => LevelRepository(getIt<Dio>()),
  );
  getIt.registerLazySingleton<MatchRepository>(
    () => MatchRepository(getIt<Dio>()),
  );
  getIt.registerLazySingleton<AmericanoRepository>(
    () => AmericanoRepository(getIt<Dio>()),
  );
  getIt.registerLazySingleton<CupRepository>(() => CupRepository(getIt<Dio>()));
  getIt.registerLazySingleton<EventInviteRepository>(
    () => EventInviteRepository(getIt<Dio>()),
  );
  getIt.registerLazySingleton<FriendRepository>(
    () => FriendRepository(getIt<Dio>()),
  );
  getIt.registerLazySingleton<AdRepository>(() => AdRepository(getIt<Dio>()));
  getIt.registerLazySingleton<TournamentRepository>(
    () => TournamentRepository(getIt<Dio>()),
  );
  getIt.registerLazySingleton<PulseRepository>(
    () => PulseRepository(getIt<Dio>()),
  );
  getIt.registerLazySingleton<WalletRepository>(
    () => WalletRepository(getIt<Dio>()),
  );
  getIt.registerLazySingleton<NotificationRepository>(
    () => NotificationRepository(getIt<Dio>()),
  );
  getIt.registerLazySingleton<SubscriptionRepository>(
    () => SubscriptionRepository(getIt<Dio>()),
  );
  getIt.registerLazySingleton<PointsRepository>(
    () => PointsRepository(getIt<Dio>()),
  );
  getIt.registerLazySingleton<VenueRepository>(
    () => VenueRepository(getIt<Dio>()),
  );
  getIt.registerLazySingleton<MembershipRepository>(
    () => MembershipRepository(getIt<Dio>()),
  );
  getIt.registerLazySingleton<SettingsRepository>(
    () => SettingsRepository(getIt<Dio>()),
  );
  getIt.registerLazySingleton<LocationRepository>(
    () => LocationRepository(getIt<Dio>()),
  );
  getIt.registerLazySingleton<SportRepository>(
    () => SportRepository(getIt<Dio>()),
  );
  getIt.registerLazySingleton<SupportRepository>(
    () => SupportRepository(getIt<Dio>()),
  );
  // مقبس SignalR واحد للتطبيق كله — الشاشات تشترك فيه ولا تفتح غيره.
  getIt.registerLazySingleton<SupportHub>(() => SupportHub.instance);

  // ── Cubits ─────────────────────────────────────────────────────────────────
  // Auth is a single app-wide session; the rest are per-screen factories.
  getIt.registerLazySingleton<AuthCubit>(
    () => AuthCubit(
      getIt<AuthRepository>(),
      getIt<AppSettings>(),
      // Shared (singleton) cubits keep the previous account's data across a
      // logout — reset each one here. Currently only WalletCubit is shared.
      onSessionCleared: () => getIt<WalletCubit>().reset(),
    ),
  );
  getIt.registerFactory<CourtsCubit>(
    () => CourtsCubit(
      getIt<CourtRepository>(),
      getIt<LocationRepository>(),
      getIt<CourtFavoritesHub>(),
    ),
  );
  getIt.registerFactory<BookCourtCubit>(
    () => BookCourtCubit(getIt<CourtRepository>()),
  );
  getIt.registerFactory<FavoriteCourtsCubit>(
    () => FavoriteCourtsCubit(
      getIt<CourtRepository>(),
      getIt<CourtFavoritesHub>(),
    ),
  );
  getIt.registerFactory<CoachesCubit>(
    () => CoachesCubit(getIt<CoachRepository>()),
  );
  getIt.registerFactory<MySessionsCubit>(
    () => MySessionsCubit(getIt<CoachRepository>()),
  );
  getIt.registerFactory<LevelCubit>(() => LevelCubit(getIt<LevelRepository>()));
  getIt.registerFactory<MatchesCubit>(
    () => MatchesCubit(getIt<MatchRepository>()),
  );
  getIt.registerFactory<AmericanoListCubit>(
    () => AmericanoListCubit(getIt<AmericanoRepository>()),
  );
  // صفحة «عرض الكل» لما يخصّ المستخدم — النوع (مباراة/أمريكانو/بطولة) يُمرَّر
  // عند الطلب: getIt<MyEventsCubit>(param1: kind).
  // دردشة الحدث: مستودع واحد، وcubit لكل شاشة بمعرّف المباراة.
  getIt.registerLazySingleton<ReviewRepository>(
    () => ReviewRepository(getIt<Dio>()),
  );
  getIt.registerFactoryParam<CourtReviewsCubit, int, void>(
    (courtId, _) => CourtReviewsCubit(getIt<ReviewRepository>(), courtId),
  );
  getIt.registerLazySingleton<EventChatRepository>(
    () => EventChatRepository(getIt<Dio>()),
  );
  getIt.registerFactoryParam<EventChatCubit, int, void>(
    (matchId, _) => EventChatCubit(getIt<EventChatRepository>(), matchId),
  );
  // param2: true = صفحة «المنتهية»، وإلا «عرض الكل» للحالية.
  getIt.registerFactoryParam<MyEventsCubit, MyEventsKind, bool?>(
    (kind, finished) => MyEventsCubit(
      getIt<MatchRepository>(),
      getIt<AmericanoRepository>(),
      kind,
      finished: finished ?? false,
    ),
  );
  getIt.registerFactory<AmericanoDetailCubit>(
    () => AmericanoDetailCubit(getIt<AmericanoRepository>()),
  );
  getIt.registerFactory<CupDetailCubit>(
    () => CupDetailCubit(getIt<CupRepository>(), getIt<AmericanoRepository>()),
  );
  getIt.registerFactory<FriendsCubit>(
    () => FriendsCubit(getIt<FriendRepository>()),
  );
  getIt.registerFactory<FeedCubit>(() => FeedCubit(getIt<FriendRepository>()));
  // Shared, not a factory: the balance is shown on several screens at once
  // (profile, wallet). Separate instances meant a top-up refreshed only the
  // screen it happened on and left the others showing a stale balance.
  // Consumers must use BlocProvider.value so no single page closes it.
  getIt.registerLazySingleton<WalletCubit>(
    () => WalletCubit(getIt<WalletRepository>()),
  );
  getIt.registerFactory<SubscriptionCubit>(
    () => SubscriptionCubit(getIt<SubscriptionRepository>()),
  );
  getIt.registerFactory<PointsCubit>(
    () => PointsCubit(getIt<PointsRepository>()),
  );
  getIt.registerFactory<NotificationsCubit>(
    () => NotificationsCubit(getIt<NotificationRepository>()),
  );
  getIt.registerFactory<SupportChatCubit>(
    () => SupportChatCubit(getIt<SupportRepository>(), getIt<SupportHub>()),
  );
  getIt.registerFactory<CoachDashboardCubit>(
    () => CoachDashboardCubit(getIt<CoachRepository>()),
  );
  getIt.registerFactory<VenueDashboardCubit>(
    () => VenueDashboardCubit(getIt<VenueRepository>()),
  );
  getIt.registerFactory<ManageVenuesCubit>(
    () => ManageVenuesCubit(getIt<VenueRepository>()),
  );
}
