part of 'subscription_cubit.dart';

enum SubscriptionStatus { initial, loading, success, failure }

class SubscriptionState extends Equatable {
  const SubscriptionState({
    this.status = SubscriptionStatus.initial,
    this.subscription,
    this.packages = const [],
    this.busy = false,
    this.busyPackageId,
    this.error,
  });

  final SubscriptionStatus status;
  final SubscriptionEntity? subscription;

  /// كل أنواع الاشتراك المتاحة (مرتّبة كما يرتّبها الأدمن).
  final List<PackageEntity> packages;

  final bool busy;

  /// الاشتراك الذي يجري تنفيذه الآن — لإظهار مؤشر التحميل على زرّه وحده.
  final int? busyPackageId;

  final String? error;

  /// معرّف الاشتراك الساري فعلياً (null حين لا اشتراك).
  int? get activePackageId =>
      subscription?.isPlus == true ? subscription?.packageId : null;

  SubscriptionState copyWith({
    SubscriptionStatus? status,
    SubscriptionEntity? subscription,
    List<PackageEntity>? packages,
    bool? busy,
    int? busyPackageId,
    String? error,
  }) {
    return SubscriptionState(
      status: status ?? this.status,
      subscription: subscription ?? this.subscription,
      packages: packages ?? this.packages,
      busy: busy ?? this.busy,
      busyPackageId: busyPackageId,
      error: error,
    );
  }

  @override
  List<Object?> get props =>
      [status, subscription, packages, busy, busyPackageId, error];
}
