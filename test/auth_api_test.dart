import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_task_handler_mobile/data/api_message.dart';
import 'package:smart_task_handler_mobile/data/auth_api.dart';
import 'package:smart_task_handler_mobile/data/result.dart';
import 'package:smart_task_handler_mobile/data/token_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'registration sends the required name and persists only the JWT',
    () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/auth/register');
        expect(jsonDecode(request.body), {
          'email': 'worker@example.com',
          'password': 'secret1',
          'name': 'Работник',
        });
        return http.Response('{"token":"jwt-123","user":{"id":1}}', 201);
      });
      final tokens = TokenStore();
      final api = AuthApi('http://localhost:8080', tokens, client: client);

      expect(
        await api.register('worker@example.com', 'secret1', 'Работник'),
        isA<Ok<void>>(),
      );
      expect(await TokenStore().read(), 'jwt-123');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), {'auth_token'});
      await api.logout();
      expect(await tokens.read(), isNull);
    },
  );

  test('HTTP errors use Russian messages from the standard envelope', () async {
    final client = MockClient((request) async {
      if (request.url.path == '/auth/login') {
        return http.Response(
          '{"error":{"code":"UNAUTHORIZED","message":"Invalid email or password"}}',
          401,
        );
      }
      return http.Response(
        '{"error":{"code":"EMAIL_TAKEN","message":"Taken"}}',
        409,
      );
    });
    final api = AuthApi('http://localhost:8080', TokenStore(), client: client);

    final badLogin = await api.login('worker@example.com', 'wrong');
    expect(badLogin, isA<Err<void>>());
    expect((badLogin as Err<void>).msg, 'Неверный email или пароль');
    final duplicate = await api.register(
      'worker@example.com',
      'secret1',
      'Name',
    );
    expect((duplicate as Err<void>).msg, 'Аккаунт с этим email уже существует');
    expect(await TokenStore().read(), isNull);
  });

  test(
    'broken JSON and transport failures stay in Result, not exceptions',
    () async {
      final broken = AuthApi(
        'http://localhost:8080',
        TokenStore(),
        client: MockClient(
          (_) async => http.Response('<html>oops</html>', 200),
        ),
      );
      expect(
        (await broken.login('a@b.co', 'secret1') as Err<void>).msg,
        'Ответ не тот, что обещан',
      );

      final disconnected = AuthApi(
        'http://localhost:8080',
        TokenStore(),
        client: MockClient((_) async => throw const SocketException('offline')),
      );
      expect(
        (await disconnected.login('a@b.co', 'secret1') as Err<void>).msg,
        'Нет сети — повторите попытку',
      );

      final timedOut = AuthApi(
        'http://localhost:8080',
        TokenStore(),
        client: MockClient((_) async => throw TimeoutException('timeout')),
      );
      expect(
        (await timedOut.login('a@b.co', 'secret1') as Err<void>).msg,
        'Сервер не отвечает',
      );
    },
  );

  test(
    'restored token is removed on 401 and kept during network outage',
    () async {
      final tokens = TokenStore();
      await tokens.save('expired');
      final rejected = AuthApi(
        'http://localhost:8080',
        tokens,
        client: MockClient((request) async {
          expect(request.url.path, '/profile');
          expect(request.headers['Authorization'], 'Bearer expired');
          return http.Response('{"error":{"code":"UNAUTHORIZED"}}', 401);
        }),
      );
      expect(await rejected.validateStoredToken(), isFalse);
      expect(await tokens.read(), isNull);

      await tokens.save('still-valid');
      final offline = AuthApi(
        'http://localhost:8080',
        tokens,
        client: MockClient((_) async => throw const SocketException('offline')),
      );
      expect(await offline.validateStoredToken(), isNull);
      expect(await tokens.read(), 'still-valid');
    },
  );

  test('profile supplies the server role and logout forgets it', () async {
    final tokens = TokenStore();
    await tokens.save('admin-token');
    final api = AuthApi(
      'http://localhost:8080',
      tokens,
      client: MockClient(
        (_) async => http.Response('{"id":1,"role":"administrator"}', 200),
      ),
    );
    expect(await api.validateStoredToken(), isTrue);
    expect(api.profileRole, 'administrator');
    await api.logout();
    expect(api.profileRole, isNull);
    expect(await tokens.read(), isNull);
  });

  test('unexpected error bodies show status, never raw server text', () {
    expect(
      apiMessage(http.Response('<html>server error</html>', 500)),
      'Ошибка сервера (500)',
    );
    expect(
      apiMessage(http.Response('{"error":{"code":"OTHER"}}', 418)),
      'Ошибка сервера (OTHER)',
    );
  });
}
