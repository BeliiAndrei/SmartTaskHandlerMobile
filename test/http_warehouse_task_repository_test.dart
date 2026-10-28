import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_task_handler_mobile/data/http_warehouse_task_repository.dart';
import 'package:smart_task_handler_mobile/data/result.dart';
import 'package:smart_task_handler_mobile/data/token_store.dart';
import 'package:smart_task_handler_mobile/models/warehouse_task.dart';

void main() {
  final taskJson = {
    'id': 7,
    'title': 'Коробка',
    'description': 'Перенести',
    'priority': 'high',
    'status': 'new',
    'sourceLocationId': 1,
    'destinationLocationId': 2,
    'assigneeId': 3,
    'dueAt': '2026-11-15T12:00:00Z',
    'createdAt': '2026-10-28T10:00:00Z',
    'updatedAt': '2026-10-28T10:00:00Z',
    'completedAt': null,
  };

  test(
    'list uses JWT and server page/search; create omits server-owned fields',
    () async {
      SharedPreferences.setMockInitialValues({});
      final tokens = TokenStore();
      await tokens.save('jwt-test');
      final seen = <http.Request>[];
      final client = MockClient((request) async {
        seen.add(request);
        if (request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'items': [taskJson],
              'page': 2,
              'limit': 1,
              'total': 21,
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response(
          jsonEncode(taskJson),
          201,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      final repo = HttpWarehouseTaskRepository(
        'http://example.test',
        tokens,
        client: client,
        onUnauthorized: () {},
      );
      final list = await repo.fetchAll(page: 2, limit: 1, search: 'коробка');
      expect((list as Ok<List<WarehouseTask>>).value.single.id, 7);
      expect(seen.first.url.queryParameters, {
        'page': '2',
        'limit': '1',
        'search': 'коробка',
      });
      expect(seen.first.headers['authorization'], 'Bearer jwt-test');

      final draft = WarehouseTask(
        id: 0,
        title: 'Коробка',
        description: 'Перенести',
        priority: TaskPriority.high,
        status: TaskStatus.newTask,
        dueDate: DateTime.utc(2026, 11, 15, 12),
        zone: 'B',
        sourceLocationId: 1,
        destinationLocationId: 2,
      );
      expect(await repo.create(draft), isA<Ok<WarehouseTask>>());
      final body = jsonDecode(seen.last.body) as Map<String, dynamic>;
      expect(
        body.keys,
        containsAll([
          'title',
          'description',
          'priority',
          'sourceLocationId',
          'destinationLocationId',
          'dueAt',
        ]),
      );
      expect(body.containsKey('id'), isFalse);
      expect(body.containsKey('status'), isFalse);
    },
  );

  test(
    '204 delete needs no JSON; 401 clears token and invokes callback',
    () async {
      SharedPreferences.setMockInitialValues({});
      final tokens = TokenStore();
      await tokens.save('expired');
      var calls = 0;
      final client = MockClient(
        (request) async => request.method == 'DELETE'
            ? http.Response('', 204)
            : http.Response(
                jsonEncode({
                  'error': {'code': 'UNAUTHORIZED', 'message': 'expired'},
                }),
                401,
              ),
      );
      final repo = HttpWarehouseTaskRepository(
        'http://example.test',
        tokens,
        client: client,
        onUnauthorized: () => calls++,
      );
      expect(await repo.delete(7), isA<Ok<void>>());
      expect(await repo.fetchAll(), isA<Err<List<WarehouseTask>>>());
      expect(await tokens.read(), isNull);
      expect(calls, 1);
    },
  );

  test('invalid success body stays an Err instead of crashing', () async {
    SharedPreferences.setMockInitialValues({});
    final tokens = TokenStore();
    final repo = HttpWarehouseTaskRepository(
      'http://example.test',
      tokens,
      client: MockClient((_) async => http.Response('<html>', 200)),
      onUnauthorized: () {},
    );
    expect((await repo.fetchAll() as Err).msg, 'Ответ не тот, что обещан');
  });
}
