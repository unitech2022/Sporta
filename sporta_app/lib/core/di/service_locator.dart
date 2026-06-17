import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/courts/data/court_repository.dart';
import '../../features/courts/presentation/cubit/book_court/book_court_cubit.dart';
import '../../features/courts/presentation/cubit/courts_list/courts_cubit.dart';
import '../../features/level/data/level_repository.dart';
import '../../features/level/presentation/cubit/level_cubit.dart';
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
  getIt.registerLazySingleton<CourtRepository>(
    () => CourtRepository(getIt<Dio>()),
  );
  getIt.registerLazySingleton<LevelRepository>(
    () => LevelRepository(getIt<Dio>()),
  );

  // ── Cubits ─────────────────────────────────────────────────────────────────
  // Auth is a single app-wide session; the rest are per-screen factories.
  getIt.registerLazySingleton<AuthCubit>(
    () => AuthCubit(getIt<AuthRepository>(), getIt<AppSettings>()),
  );
  getIt.registerFactory<CourtsCubit>(
    () => CourtsCubit(getIt<CourtRepository>()),
  );
  getIt.registerFactory<BookCourtCubit>(
    () => BookCourtCubit(getIt<CourtRepository>()),
  );
  getIt.registerFactory<LevelCubit>(
    () => LevelCubit(getIt<LevelRepository>()),
  );
}
