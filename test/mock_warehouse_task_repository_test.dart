import 'package:flutter_test/flutter_test.dart';

import 'support/mock_warehouse_task_repository.dart';

import 'package:smart_task_handler_mobile/data/result.dart';
import 'package:smart_task_handler_mobile/models/warehouse_task.dart';

void main() {
  test('mock repository supports CRUD without exposing its list', () async {
    final repository = MockWarehouseTaskRepository();
    final stopwatch = Stopwatch()..start();
    final initial = await repository.fetchAll();
    stopwatch.stop();

    expect(
      stopwatch.elapsed,
      greaterThanOrEqualTo(const Duration(milliseconds: 750)),
    );
    expect(initial, isA<Ok<List<WarehouseTask>>>());
    final returnedList = (initial as Ok<List<WarehouseTask>>).value;
    final originalCount = returnedList.length;
    final highestId = returnedList
        .map((task) => task.id)
        .reduce((a, b) => a > b ? a : b);
    final draft = returnedList.first.copyWith(id: 0, title: 'Новая задача');
    returnedList.clear();

    final untouched = await repository.fetchAll();
    expect((untouched as Ok<List<WarehouseTask>>).value.length, originalCount);

    final createdResult = await repository.create(draft);
    expect(createdResult, isA<Ok<WarehouseTask>>());
    final created = (createdResult as Ok<WarehouseTask>).value;
    expect(draft.id, 0);
    expect(created.id, highestId + 1);
    expect(
      (await repository.fetchById(created.id) as Ok<WarehouseTask>).value.title,
      'Новая задача',
    );

    final changed = created.copyWith(status: TaskStatus.completed);
    expect(await repository.update(changed), isA<Ok<WarehouseTask>>());
    expect(
      (await repository.fetchById(
        created.id,
      ) as Ok<WarehouseTask>).value.status,
      TaskStatus.completed,
    );

    expect(await repository.delete(created.id), isA<Ok<void>>());
    final missing = await repository.fetchById(created.id);
    expect(missing, isA<Err<WarehouseTask>>());
    expect((missing as Err<WarehouseTask>).msg, 'Задача не существует');
    expect(await repository.update(changed), isA<Err<WarehouseTask>>());
    expect(await repository.delete(created.id), isA<Err<void>>());
  });

  test(
    'simulated failure affects every method without changing data',
    () async {
      final repository = MockWarehouseTaskRepository();
      final before =
          (await repository.fetchAll() as Ok<List<WarehouseTask>>).value;
      final existing = before.first;
      repository.simulateError = true;

      final failedLoad = await repository.fetchAll();
      expect(failedLoad, isA<Err<List<WarehouseTask>>>());
      expect(
        (failedLoad as Err<List<WarehouseTask>>).msg,
        'Сервер не отвечает — повторите попытку',
      );
      expect(
        await repository.fetchById(existing.id),
        isA<Err<WarehouseTask>>(),
      );
      expect(await repository.create(existing), isA<Err<WarehouseTask>>());
      expect(await repository.update(existing), isA<Err<WarehouseTask>>());
      expect(await repository.delete(existing.id), isA<Err<void>>());

      repository.simulateError = false;
      final after =
          (await repository.fetchAll() as Ok<List<WarehouseTask>>).value;
      expect(after.map((task) => task.id), before.map((task) => task.id));
    },
  );
}
