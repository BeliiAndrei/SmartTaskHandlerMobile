import 'package:smart_task_handler_mobile/data/auth_api.dart';
import 'package:smart_task_handler_mobile/data/result.dart';
import 'package:smart_task_handler_mobile/data/token_store.dart';

/// Keeps older task-screen widget tests independent of a running backend.
class FakeAuthApi extends AuthApi {
  FakeAuthApi() : super('http://unused.local', TokenStore());

  @override
  Future<Result<void>> login(String email, String password) async =>
      const Ok(null);

  @override
  Future<Result<void>> register(
    String email,
    String password,
    String name,
  ) async => const Ok(null);

  @override
  Future<void> logout() async {}

  @override
  Future<bool?> validateStoredToken() async => null;
}
