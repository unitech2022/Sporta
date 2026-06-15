import '../../../../core/state/app_settings.dart';

/// One of the user's role accounts shown in the "حساباتي في التطبيق" box.
class RoleAccount {
  RoleAccount({required this.type, this.completed = false});

  final UserRole type;
  bool completed;
}
