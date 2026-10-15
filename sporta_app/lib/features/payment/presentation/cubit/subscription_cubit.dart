import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/data/models/api_exception.dart';
import '../../data/subscription_repository.dart';
import '../../domain/entities/subscription_entity.dart';

part 'subscription_state.dart';

/// Drives the Sporta Plus screen: load + subscribe / cancel.
class SubscriptionCubit extends Cubit<SubscriptionState> {
  SubscriptionCubit(this._repository) : super(const SubscriptionState());

  final SubscriptionRepository _repository;

  /// يجلب اشتراك المستخدم الحالي وكل أنواع الاشتراك المتاحة معاً.
  Future<void> load({bool isArabic = true}) async {
    emit(state.copyWith(status: SubscriptionStatus.loading, error: null));
    try {
      final results = await Future.wait([
        _repository.fetch(),
        _repository.fetchPackages(),
      ]);
      emit(state.copyWith(
        status: SubscriptionStatus.success,
        subscription: results[0] as SubscriptionEntity,
        packages: results[1] as List<PackageEntity>,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: SubscriptionStatus.failure,
        error: e.display,
      ));
    }
  }

  Future<String?> _act(
    Future<SubscriptionEntity> Function() action, {
    bool isArabic = true,
    int? busyPackageId,
  }) async {
    emit(state.copyWith(busy: true, busyPackageId: busyPackageId));
    try {
      final sub = await action();
      emit(state.copyWith(subscription: sub, busy: false, busyPackageId: null));
      return null;
    } on ApiException catch (e) {
      emit(state.copyWith(busy: false, busyPackageId: null));
      return e.display;
    }
  }

  /// [packageId] فارغ = الاشتراك الافتراضي (زر الاشتراك القديم).
  Future<String?> subscribe({int? packageId}) => _act(
        () => _repository.subscribe(packageId: packageId),
        busyPackageId: packageId,
      );

  Future<String?> cancel() => _act(_repository.cancel);
}
