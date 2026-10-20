import 'package:flutter/foundation.dart';

import 'warehouse_task.dart';

/// Shared task state. Screen-specific search and form fields stay in widgets.
class TaskModel extends ChangeNotifier {
  TaskModel(Iterable<WarehouseTask> initialTasks)
    : _tasks = List.of(initialTasks);

  final List<WarehouseTask> _tasks;

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

  bool updateStatus(int id, TaskStatus status) {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index == -1) return false;
    if (_tasks[index].status == status) return true;
    _tasks[index] = _tasks[index].copyWith(status: status);
    notifyListeners();
    return true;
  }
}
