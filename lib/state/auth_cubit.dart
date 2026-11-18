import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/auth_api.dart';
import '../data/result.dart';
import '../models/session_model.dart';

enum AuthPhase { idle, submitting, success, failure }

class AuthState {
  const AuthState(this.phase, {this.role, this.message});

  final AuthPhase phase;
  final UserRole? role;
  final String? message;
}

/// One submission at a time; the form only renders and reacts to transitions.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._api) : super(const AuthState(AuthPhase.idle));

  final AuthApi _api;

  Future<void> submit({
    required bool isRegistration,
    required String email,
    required String password,
    String name = '',
  }) async {
    if (state.phase == AuthPhase.submitting) return;
    emit(const AuthState(AuthPhase.submitting));
    final result = isRegistration
        ? await _api.register(email, password, name)
        : await _api.login(email, password);
    switch (result) {
      case Ok():
        final valid = await _api.validateStoredToken();
        if (valid == false) {
          emit(
            const AuthState(
              AuthPhase.failure,
              message: 'Сессия истекла — войдите снова',
            ),
          );
          return;
        }
        emit(
          AuthState(
            AuthPhase.success,
            role: _api.profileRole == 'administrator'
                ? UserRole.administrator
                : UserRole.user,
          ),
        );
      case Err(msg: final msg):
        emit(AuthState(AuthPhase.failure, message: msg));
    }
  }
}
