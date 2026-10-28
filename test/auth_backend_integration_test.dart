import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_task_handler_mobile/data/auth_api.dart';
import 'package:smart_task_handler_mobile/data/result.dart';
import 'package:smart_task_handler_mobile/data/token_store.dart';

const runLiveBackend = bool.fromEnvironment('RUN_LIVE_BACKEND');

void main() {
  test('AuthApi talks to the real .NET backend', () async {
    SharedPreferences.setMockInitialValues({});
    final email =
        'flutter-${DateTime.now().microsecondsSinceEpoch}@example.test';
    final tokens = TokenStore();
    final auth = AuthApi('http://127.0.0.1:8080', tokens);

    expect(
      await auth.register(email, 'secret123', 'Flutter Tester'),
      isA<Ok<void>>(),
    );
    expect(await tokens.read(), isNotNull);
    expect(await auth.validateStoredToken(), isTrue);
    await auth.logout();
    expect(await tokens.read(), isNull);

    final wrongPassword = await auth.login(email, 'wrong-password');
    expect((wrongPassword as Err<void>).msg, 'Неверный email или пароль');
    expect(await auth.login(email, 'secret123'), isA<Ok<void>>());
    expect(await tokens.read(), isNotNull);
  }, skip: !runLiveBackend);
}
