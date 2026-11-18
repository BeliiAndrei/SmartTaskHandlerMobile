import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_task_handler_mobile/data/token_store.dart';
import 'package:smart_task_handler_mobile/data/users_api.dart';
import 'package:smart_task_handler_mobile/main.dart';
import 'package:smart_task_handler_mobile/models/session_model.dart';
import 'package:smart_task_handler_mobile/router.dart';

import 'support/fake_auth_api.dart';
import 'support/mock_warehouse_task_repository.dart';

void main() {
  setUp(
    () => SharedPreferences.setMockInitialValues({'auth_token': 'admin-jwt'}),
  );

  test('admin request sends JWT and parses registered users', () async {
    final api = UsersApi(
      'http://localhost:8080',
      TokenStore(),
      client: MockClient((request) async {
        expect(request.url.path, '/admin/users');
        expect(request.headers['Authorization'], 'Bearer admin-jwt');
        return http.Response(
          '[{"id":2,"name":"Worker","email":"worker@example.com",'
          '"role":"user","createdAt":"2026-11-11T08:00:00Z"}]',
          200,
        );
      }),
    );
    final users = await api.fetchOthers();
    expect(users.single.name, 'Worker');
    expect(users.single.id, 2);
  });

  test('forbidden response is shown without leaking server text', () async {
    final api = UsersApi(
      'http://localhost:8080',
      TokenStore(),
      client: MockClient(
        (_) async => http.Response(
          '{"error":{"code":"FORBIDDEN","message":"internal text"}}',
          403,
        ),
      ),
    );
    await expectLater(
      api.fetchOthers(),
      throwsA(
        isA<UsersApiException>().having(
          (e) => e.message,
          'message',
          'Недостаточно прав для просмотра пользователей',
        ),
      ),
    );
  });

  testWidgets('admin sees other registered users on the new page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    router = createRouter(initialLocation: '/admin/users');
    final usersApi = UsersApi(
      'http://localhost:8080',
      TokenStore(),
      client: MockClient(
        (_) async => http.Response(
          '[{"id":2,"name":"Worker","email":"worker@example.com",'
          '"role":"user","createdAt":"2026-11-11T08:00:00Z"}]',
          200,
        ),
      ),
    );
    await tester.pumpWidget(
      SmartTaskHandlerApp(
        authApi: FakeAuthApi(),
        taskRepository: MockWarehouseTaskRepository(),
        sessionModel: SessionModel(initialRole: UserRole.administrator),
        usersApi: usersApi,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Зарегистрированные пользователи'), findsOneWidget);
    expect(find.text('Worker'), findsOneWidget);
    expect(find.textContaining('worker@example.com'), findsOneWidget);
  });

  testWidgets('worker cannot open the admin route', (tester) async {
    router = createRouter(initialLocation: '/admin/users');
    await tester.pumpWidget(
      SmartTaskHandlerApp(
        authApi: FakeAuthApi(),
        taskRepository: MockWarehouseTaskRepository(),
        sessionModel: SessionModel(initialRole: UserRole.user),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Зарегистрированные пользователи'), findsNothing);
    expect(find.text('Складские задачи'), findsOneWidget);
  });
}
