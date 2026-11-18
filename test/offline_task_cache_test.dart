import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_task_handler_mobile/data/cached_warehouse_task_repository.dart';
import 'package:smart_task_handler_mobile/data/result.dart';
import 'package:smart_task_handler_mobile/data/task_cache_store.dart';
import 'package:smart_task_handler_mobile/models/warehouse_task.dart';

import 'support/mock_warehouse_task_repository.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('restores cached list and task details after a network failure', () async {
    final remote = MockWarehouseTaskRepository();
    final cache = TaskCacheStore();
    final online = CachedWarehouseTaskRepository(remote, cache);

    final onlinePage = await online.fetchAll(limit: 20);
    expect(onlinePage, isA<Ok<List<WarehouseTask>>>());

    remote.simulateError = true;
    final restartedRepository = CachedWarehouseTaskRepository(remote, cache);
    final offlinePage = await restartedRepository.fetchAll(limit: 20);
    expect(offlinePage, isA<Ok<List<WarehouseTask>>>());
    expect(restartedRepository.isShowingCachedData, isTrue);
    final cachedTasks = (offlinePage as Ok<List<WarehouseTask>>).value;
    expect(cachedTasks, isNotEmpty);

    final firstTask = cachedTasks.first;
    final detail = await restartedRepository.fetchById(firstTask.id);
    expect(detail, isA<Ok<WarehouseTask>>());
    expect((detail as Ok<WarehouseTask>).value.title, firstTask.title);
  });

  test('does not invent an uncached page after a network failure', () async {
    final remote = MockWarehouseTaskRepository()..simulateError = true;
    final repository = CachedWarehouseTaskRepository(
      remote,
      TaskCacheStore(),
    );

    final result = await repository.fetchAll();
    expect(result, isA<Err<List<WarehouseTask>>>());
    expect(repository.isShowingCachedData, isFalse);
  });

  test('successful server mutation invalidates previously cached tasks', () async {
    final remote = MockWarehouseTaskRepository();
    final repository = CachedWarehouseTaskRepository(
      remote,
      TaskCacheStore(),
    );
    final loaded = await repository.fetchAll(limit: 20);
    final task = (loaded as Ok<List<WarehouseTask>>).value.first;

    final updated = await repository.update(
      task.copyWith(title: 'Изменённая задача'),
    );
    expect(updated, isA<Ok<WarehouseTask>>());

    remote.simulateError = true;
    final afterInvalidation = await repository.fetchAll(limit: 20);
    expect(afterInvalidation, isA<Err<List<WarehouseTask>>>());
  });
}
