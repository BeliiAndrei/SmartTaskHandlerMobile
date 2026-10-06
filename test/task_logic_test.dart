import 'package:flutter_test/flutter_test.dart';
import 'package:smart_task_handler_mobile/models/warehouse_task.dart';
import 'package:smart_task_handler_mobile/services/task_logic.dart';
import 'package:smart_task_handler_mobile/utils/task_formatters.dart';

WarehouseTask _task({
  int id = 1,
  String title = 'Проверить остатки',
  TaskStatus status = TaskStatus.newTask,
  bool isFavorite = false,
}) {
  return WarehouseTask(
    id: id,
    title: title,
    description: 'Описание задачи',
    priority: TaskPriority.medium,
    status: status,
    dueDate: DateTime(2026, 10, 6),
    zone: 'A-01',
    isFavorite: isFavorite,
  );
}

void main() {
  group('TaskLogic', () {
    test('toggles favorite without changing the source task', () {
      final source = _task();
      final updated = TaskLogic.toggleFavorite(source);

      expect(source.isFavorite, isFalse);
      expect(updated.isFavorite, isTrue);
      expect(updated.id, source.id);
    });

    test('filters tasks by query and status', () {
      final tasks = [
        _task(id: 1, title: 'Принять поставку'),
        _task(id: 2, title: 'Собрать заказ', status: TaskStatus.completed),
      ];

      final result = TaskLogic.filterTasks(
        tasks,
        query: 'заказ',
        status: TaskStatus.completed,
      );

      expect(result.map((task) => task.id), [2]);
    });

    test('returns completed tasks and next id', () {
      final tasks = [_task(id: 3), _task(id: 8, status: TaskStatus.completed)];

      expect(TaskLogic.completedTasks(tasks).single.id, 8);
      expect(TaskLogic.nextTaskId(tasks), 9);
    });
  });

  test('shared formatter formats task dates', () {
    expect(formatTaskDate(DateTime(2026, 2, 4)), '04.02.2026');
  });
}
