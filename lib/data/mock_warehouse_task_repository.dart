import '../models/warehouse_task.dart';
import 'mock_tasks.dart';
import 'result.dart';
import 'warehouse_task_repository.dart';

class MockWarehouseTaskRepository implements WarehouseTaskRepository {
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
  Future<Result<List<WarehouseTask>>> fetchAll() async {
    await Future<void>.delayed(_latency);
    if (simulateError) return const Err(_networkError);
    return Ok(List.of(_tasks));
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
