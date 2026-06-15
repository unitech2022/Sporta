import 'package:flutter/widgets.dart';

import 'auth_notifier.dart';

class AuthScope extends InheritedNotifier<AuthNotifier> {
  const AuthScope({
    super.key,
    required AuthNotifier auth,
    required super.child,
  }) : super(notifier: auth);

  static AuthNotifier of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope not found in the widget tree');
    return scope!.notifier!;
  }
}

extension AuthScopeX on BuildContext {
  AuthNotifier get auth => AuthScope.of(this);
}
