import '../models/warehouse_task.dart';

/// Shared task-domain operations that do not depend on Flutter widgets.
class TaskLogic {
  const TaskLogic._();

  static WarehouseTask toggleFavorite(WarehouseTask task) {
    return task.copyWith(isFavorite: !task.isFavorite);
  }

  static List<WarehouseTask> filterTasks(
    Iterable<WarehouseTask> tasks, {
    String query = '',
    TaskStatus? status,
  }) {
    final normalizedQuery = query.trim().toLowerCase();

    return tasks.where((task) {
      final matchesStatus = status == null || task.status == status;
      final matchesSearch =
          normalizedQuery.isEmpty ||
          task.title.toLowerCase().contains(normalizedQuery) ||
          task.description.toLowerCase().contains(normalizedQuery) ||
          task.zone.toLowerCase().contains(normalizedQuery);
      return matchesStatus && matchesSearch;
    }).toList();
  }

  static List<WarehouseTask> completedTasks(Iterable<WarehouseTask> tasks) {
    return tasks.where((task) => task.status == TaskStatus.completed).toList();
  }

  static int nextTaskId(Iterable<WarehouseTask> tasks) {
    if (tasks.isEmpty) return 1;
    return tasks.map((task) => task.id).reduce((a, b) => a > b ? a : b) + 1;
  }
}
