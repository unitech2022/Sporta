part of 'auth_cubit.dart';

/// Authentication state. Field names mirror the getters the UI relies on
/// (`user`, `isLoading`, `errorMessage`, …) so screens read them directly.
class AuthState extends Equatable {
  const AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
    this.errorCode,
    this.isCheckingSession = true,
    this.accountDisabled = false,
    this.isGuest = false,
    this.justRegistered = false,
    this.sessionExpired = false,
  });

  final UserModel? user;
  final bool isLoading;
  final String? errorMessage;
  final String? errorCode;

  /// True while a saved session is being restored at startup.
  final bool isCheckingSession;

  /// True when the account was suspended by an admin (shows the blocked screen).
  final bool accountDisabled;

  /// True حين اختار المستخدم التصفّح بلا حساب (وضع الزائر).
  final bool isGuest;

  /// True من لحظة إنشاء الحساب حتى يرى صاحبه شاشة «تم إنشاء حسابك». تُقرأ في
  /// `_AppEntry` لا في `AuthFlowPage`: الجلسة تقوم فور التسجيل فتُستبدل شاشات
  /// الدخول كلها، وبلا هذه الراية تُقفز شاشة النجاح.
  final bool justRegistered;

  /// True لحظة أن رفض الخادم الجلسة (انتهت ولم يُجدَّد التوكن). يقرؤها
  /// `_AppEntry` فيغلق الصفحات المفتوحة ويعود لشاشة الدخول برسالة، ثم يصفّرها.
  final bool sessionExpired;

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? errorMessage,
    String? errorCode,
    bool? isCheckingSession,
    bool? accountDisabled,
    bool? isGuest,
    bool? justRegistered,
    bool? sessionExpired,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
      isCheckingSession: isCheckingSession ?? this.isCheckingSession,
      accountDisabled: accountDisabled ?? this.accountDisabled,
      isGuest: isGuest ?? this.isGuest,
      justRegistered: justRegistered ?? this.justRegistered,
      sessionExpired: sessionExpired ?? this.sessionExpired,
    );
  }

  @override
  List<Object?> get props =>
      [user, isLoading, errorMessage, errorCode, isCheckingSession,
       accountDisabled, isGuest, justRegistered, sessionExpired];
}
