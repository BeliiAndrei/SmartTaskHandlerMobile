import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_task_handler_mobile/data/auth_api.dart';
import 'package:smart_task_handler_mobile/data/token_store.dart';
import 'package:smart_task_handler_mobile/main.dart';
import 'package:smart_task_handler_mobile/router.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    router = createRouter();
  });

  testWidgets(
    'registration uses backend, saves token, then logout removes it',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final client = MockClient((request) async {
        if (request.url.path == '/profile') {
          expect(request.headers['Authorization'], 'Bearer registered-jwt');
          return http.Response('{"id":1,"role":"user"}', 200);
        }
        expect(request.url.path, '/auth/register');
        expect(request.body, contains('"name":"Работник"'));
        return http.Response('{"token":"registered-jwt","user":{"id":1}}', 201);
      });
      await tester.pumpWidget(
        SmartTaskHandlerApp(
          authApi: AuthApi(
            'http://localhost:8080',
            TokenStore(),
            client: client,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Регистрация'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'worker@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'Работник');
      await tester.enterText(find.byType(TextFormField).at(2), 'secret1');
      await tester.enterText(find.byType(TextFormField).at(3), 'secret1');
      await tester.tap(find.text('Зарегистрироваться'));
      await tester.pumpAndSettle();

      expect(find.text('Складские задачи'), findsOneWidget);
      expect(await TokenStore().read(), 'registered-jwt');
      await tester.tap(find.text('Профиль'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Выйти из аккаунта'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Выйти'));
      await tester.pumpAndSettle();
      expect(find.text('Вход в систему'), findsOneWidget);
      expect(await TokenStore().read(), isNull);
    },
  );

  testWidgets('login disables duplicate submit and shows translated 401', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final response = Completer<http.Response>();
    var calls = 0;
    final client = MockClient((request) {
      calls++;
      expect(request.url.path, '/auth/login');
      return response.future;
    });
    await tester.pumpWidget(
      SmartTaskHandlerApp(
        authApi: AuthApi('http://localhost:8080', TokenStore(), client: client),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'worker@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'wrong1');
    await tester.tap(find.text('Войти'));
    await tester.pump();

    expect(calls, 1);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    response.complete(
      http.Response(
        '{"error":{"code":"UNAUTHORIZED","message":"Invalid email or password"}}',
        401,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Неверный email или пароль'), findsOneWidget);
    expect(find.text('Вход в систему'), findsOneWidget);
    expect(await TokenStore().read(), isNull);
  });

  testWidgets('server profile role controls administrator navigation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final client = MockClient((request) async {
      if (request.url.path == '/auth/login') {
        return http.Response('{"token":"admin-jwt","user":{"id":1}}', 200);
      }
      expect(request.url.path, '/profile');
      expect(request.headers['Authorization'], 'Bearer admin-jwt');
      return http.Response('{"id":1,"role":"administrator"}', 200);
    });
    await tester.pumpWidget(
      SmartTaskHandlerApp(
        authApi: AuthApi('http://localhost:8080', TokenStore(), client: client),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'admin@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'secret1');
    await tester.tap(find.text('Войти'));
    await tester.pumpAndSettle();

    expect(find.text('Складские задачи'), findsOneWidget);
    expect(find.text('История'), findsOneWidget);
  });
}
