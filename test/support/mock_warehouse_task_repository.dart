import 'package:smart_task_handler_mobile/models/warehouse_task.dart';

import 'mock_tasks.dart';

import 'package:smart_task_handler_mobile/data/result.dart';
import 'package:smart_task_handler_mobile/data/warehouse_task_repository.dart';

class MockWarehouseTaskRepository extends WarehouseTaskRepository {
  MockWarehouseTaskRepository() : _tasks = List.of(mockTasks) {
    _nextId = _tasks.fold<int>(
      1000,
      (nextId, task) => task.id >= nextId ? task.id + 1 : nextId,
    );
  }

  final List<WarehouseTask> _tasks;
  late int _nextId;
  bool simulateError = false;

  static const _latency = Duration(milliseconds: 800);
  static const _networkError = 'Сервер не отвечает — повторите попытку';
  static const _notFoundError = 'Задача не существует';

  @override
  Future<Result<List<WarehouseLocation>>> fetchLocations() async => const Ok([
    WarehouseLocation(
      id: 1,
      name: 'Приёмка A',
      zone: 'A-01',
      qrCodeValue: 'STH-LOC-A1',
    ),
    WarehouseLocation(
      id: 2,
      name: 'Отгрузка B',
      zone: 'B-01',
      qrCodeValue: 'STH-LOC-B1',
    ),
  ]);

  @override
  Future<Result<List<WarehouseTask>>> fetchAll({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    await Future<void>.delayed(_latency);
    if (simulateError) return const Err(_networkError);
    final matches = _tasks
        .where(
          (task) =>
              search == null ||
              search.isEmpty ||
              task.title.toLowerCase().contains(search.toLowerCase()) ||
              task.zone.toLowerCase().contains(search.toLowerCase()),
        )
        .toList();
    final start = (page - 1) * limit;
    return Ok(
      start >= matches.length ? [] : matches.skip(start).take(limit).toList(),
    );
  }

  @override
  Future<Result<WarehouseTask>> fetchById(int id) async {
    await Future<void>.delayed(_latency);
    if (simulateError) return const Err(_networkError);
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index == -1) return const Err(_notFoundError);
    return Ok(_tasks[index]);
  }

  @override
  Future<Result<WarehouseTask>> create(WarehouseTask task) async {
    await Future<void>.delayed(_latency);
    if (simulateError) return const Err(_networkError);
    final created = task.copyWith(id: _nextId++);
    _tasks.add(created);
    return Ok(created);
  }

  @override
  Future<Result<WarehouseTask>> update(WarehouseTask task) async {
    await Future<void>.delayed(_latency);
    if (simulateError) return const Err(_networkError);
    final index = _tasks.indexWhere((current) => current.id == task.id);
    if (index == -1) return const Err(_notFoundError);
    _tasks[index] = task;
    return Ok(task);
  }

  @override
  Future<Result<void>> delete(int id) async {
    await Future<void>.delayed(_latency);
    if (simulateError) return const Err(_networkError);
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index == -1) return const Err(_notFoundError);
    _tasks.removeAt(index);
    return const Ok(null);
  }
}
