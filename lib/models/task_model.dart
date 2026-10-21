import 'package:flutter/foundation.dart';

import '../data/result.dart';
import '../data/warehouse_task_repository.dart';
import 'warehouse_task.dart';

/// Shared warehouse task state. The repository supplies all task data.
class TaskModel extends ChangeNotifier {
  TaskModel(this._repository);

  final WarehouseTaskRepository _repository;
  List<WarehouseTask> _tasks = [];
  bool _loading = false;
  String? _error;

  bool get isLoading => _loading;
  String? get error => _error;
  List<WarehouseTask> get tasks => List.unmodifiable(_tasks);

  int get completedCount =>
      _tasks.where((task) => task.status == TaskStatus.completed).length;

  int get activeCount => _tasks.length - completedCount;

  WarehouseTask? byId(int id) {
    for (final task in _tasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    switch (await _repository.fetchAll()) {
      case Ok(value: final value):
        _tasks = List.of(value);
      case Err(msg: final msg):
        _error = msg;
    }

    _loading = false;
    notifyListeners();
  }

  Future<String?> add(WarehouseTask draft) async {
    switch (await _repository.create(draft)) {
      case Ok(value: final value):
        _tasks = [..._tasks, value];
        notifyListeners();
        return null;
      case Err(msg: final msg):
        return msg;
    }
  }

  Future<String?> update(WarehouseTask task) async {
    if (byId(task.id) == null) return 'Задача не существует';
    switch (await _repository.update(task)) {
      case Ok(value: final value):
        final index = _tasks.indexWhere((current) => current.id == value.id);
        if (index == -1) return 'Задача не существует';
        _tasks = List.of(_tasks)..[index] = value;
        notifyListeners();
        return null;
      case Err(msg: final msg):
        return msg;
    }
  }

  Future<String?> remove(int id) async {
    if (byId(id) == null) return 'Задача не существует';
    switch (await _repository.delete(id)) {
      case Ok():
        _tasks = _tasks.where((task) => task.id != id).toList();
        notifyListeners();
        return null;
      case Err(msg: final msg):
        return msg;
    }
  }

  Future<String?> updateStatus(int id, TaskStatus status) async {
    final task = byId(id);
    if (task == null) return 'Задача не существует';
    return update(task.copyWith(status: status));
  }
}
