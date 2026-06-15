import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../features/courts/data/court_repository.dart';
import '../../features/courts/presentation/cubit/book_court/book_court_cubit.dart';
import '../../features/courts/presentation/cubit/courts_list/courts_cubit.dart';
import '../../features/level/data/level_repository.dart';
import '../../features/level/presentation/cubit/level_cubit.dart';
import '../network/api_client.dart';

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

  // ── Repositories ─────────────────────────────────────────────────────────────
  getIt.registerLazySingleton<CourtRepository>(
    () => CourtRepository(getIt<Dio>()),
  );
  getIt.registerLazySingleton<LevelRepository>(
    () => LevelRepository(getIt<Dio>()),
  );

  // ── Cubits ─────────────────────────────────────────────────────────────────
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
