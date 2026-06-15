import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/auth_cubit.dart';

/// Convenience accessor for the app-wide [AuthCubit] (provided above
/// `MaterialApp`). Kept as `context.auth` so existing screens are unchanged.
extension AuthScopeX on BuildContext {
  AuthCubit get auth => read<AuthCubit>();
}
