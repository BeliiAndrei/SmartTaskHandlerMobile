import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_task_handler_mobile/data/auth_api.dart';
import 'package:smart_task_handler_mobile/data/http_warehouse_task_repository.dart';
import 'package:smart_task_handler_mobile/data/result.dart';
import 'package:smart_task_handler_mobile/data/token_store.dart';
import 'package:smart_task_handler_mobile/models/warehouse_task.dart';

const runLiveBackend = bool.fromEnvironment('RUN_LIVE_BACKEND');

void main() {
  test('Flutter task flow uses the live .NET contract', () async {
    SharedPreferences.setMockInitialValues({});
    final tokens = TokenStore();
    final auth = AuthApi('http://127.0.0.1:8080', tokens);
    final email = 'tasks-${DateTime.now().microsecondsSinceEpoch}@example.test';
    expect(
      await auth.register(email, 'secret123', 'Task Tester'),
      isA<Ok<void>>(),
    );

    var unauthorized = false;
    final repository = HttpWarehouseTaskRepository(
      'http://127.0.0.1:8080',
      tokens,
      onUnauthorized: () => unauthorized = true,
    );
    final locations = (await repository.fetchLocations() as Ok).value;
    expect(locations.length, greaterThanOrEqualTo(2));
    final source = locations[0];
    final destination = locations[1];
    expect(
      (await repository.fetchLocation(destination.id) as Ok).value.qrCodeValue,
      destination.qrCodeValue,
    );
    final draft = WarehouseTask(
      id: 0,
      title: 'Проверить коробку',
      description: 'Перенести в точку назначения',
      priority: TaskPriority.high,
      status: TaskStatus.newTask,
      dueDate: DateTime.now().add(const Duration(days: 2)),
      zone: destination.zone,
      sourceLocationId: source.id,
      destinationLocationId: destination.id,
    );

    final created = (await repository.create(draft) as Ok<WarehouseTask>).value;
    expect(created.id, greaterThan(0));
    expect(created.status, TaskStatus.newTask);
    expect(
      (await repository.fetchById(created.id) as Ok<WarehouseTask>).value.title,
      draft.title,
    );
    final list = (await repository.fetchAll(
      page: 1,
      limit: 1,
      search: 'Проверить',
    ) as Ok<List<WarehouseTask>>).value;
    expect(list.single.id, created.id);

    final edited = (await repository.update(
      created.copyWith(title: 'Коробка B'),
    ) as Ok<WarehouseTask>).value;
    expect(edited.title, 'Коробка B');
    final started = (await repository.changeStatus(
      edited,
      TaskStatus.inProgress,
    ) as Ok<WarehouseTask>).value;
    expect(started.status, TaskStatus.inProgress);
    expect(
      await repository.confirmDestination(created.id, 'WRONG'),
      isA<Err<void>>(),
    );
    expect(
      await repository.changeStatus(started, TaskStatus.completed),
      isA<Err<WarehouseTask>>(),
    );
    expect(
      await repository.confirmDestination(created.id, destination.qrCodeValue),
      isA<Ok<void>>(),
    );
    final completed = (await repository.changeStatus(
      started,
      TaskStatus.completed,
    ) as Ok<WarehouseTask>).value;
    expect(completed.status, TaskStatus.completed);
    expect(
      (await repository.fetchHistory(created.id) as Ok).value.length,
      greaterThanOrEqualTo(3),
    );
    expect(await repository.delete(created.id), isA<Ok<void>>());
    expect(await repository.fetchById(created.id), isA<Err<WarehouseTask>>());

    await tokens.save('invalid-token');
    expect(await repository.fetchAll(), isA<Err<List<WarehouseTask>>>());
    expect(unauthorized, isTrue);
    expect(await tokens.read(), isNull);
  }, skip: !runLiveBackend);
}
