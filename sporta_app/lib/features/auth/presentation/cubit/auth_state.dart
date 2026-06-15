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
  });

  final UserModel? user;
  final bool isLoading;
  final String? errorMessage;
  final String? errorCode;

  /// True while a saved session is being restored at startup.
  final bool isCheckingSession;

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? errorMessage,
    String? errorCode,
    bool? isCheckingSession,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
      isCheckingSession: isCheckingSession ?? this.isCheckingSession,
    );
  }

  @override
  List<Object?> get props =>
      [user, isLoading, errorMessage, errorCode, isCheckingSession];
}
