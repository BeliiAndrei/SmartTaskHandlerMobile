import '../models/warehouse_task.dart';

String taskPriorityLabel(TaskPriority priority) {
  return switch (priority) {
    TaskPriority.low => 'Низкий',
    TaskPriority.medium => 'Средний',
    TaskPriority.high => 'Высокий',
  };
}

String taskStatusLabel(TaskStatus status) {
  return switch (status) {
    TaskStatus.newTask => 'Новая',
    TaskStatus.inProgress => 'В работе',
    TaskStatus.paused => 'Приостановлена',
    TaskStatus.completed => 'Выполнена',
  };
}

String formatTaskDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}

bool isTaskOverdue(WarehouseTask task, {DateTime? today}) {
  if (task.status == TaskStatus.completed) return false;

  final now = today ?? DateTime.now();
  final currentDate = DateTime(now.year, now.month, now.day);
  final dueDate = DateTime(
    task.dueDate.year,
    task.dueDate.month,
    task.dueDate.day,
  );
  return dueDate.isBefore(currentDate);
}
