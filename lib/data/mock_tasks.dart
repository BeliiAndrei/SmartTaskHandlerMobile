import '../models/warehouse_task.dart';

List<WarehouseTask> createMockTasks() {
  return [
    WarehouseTask(
      id: 1042,
      title: 'Собрать заказ №1042',
      description: 'Подготовить товары и передать заказ в зону отгрузки.',
      priority: TaskPriority.high,
      status: TaskStatus.inProgress,
      dueDate: DateTime(2026, 9, 16),
      zone: 'A-03',
    ),
    WarehouseTask(
      id: 1043,
      title: 'Принять утреннюю поставку',
      description: 'Проверить количество коробок и состояние упаковки.',
      priority: TaskPriority.high,
      status: TaskStatus.newTask,
      dueDate: DateTime(2026, 9, 16),
      zone: 'Приёмка',
    ),
    WarehouseTask(
      id: 1044,
      title: 'Проверить остатки секции B',
      description: 'Сверить фактические остатки с учётной системой.',
      priority: TaskPriority.medium,
      status: TaskStatus.paused,
      dueDate: DateTime.now().subtract(const Duration(days: 2)),
      zone: 'B-12',
    ),
    WarehouseTask(
      id: 1045,
      title: 'Переместить палеты в зону хранения',
      description: 'Освободить проход и разместить груз по маркировке.',
      priority: TaskPriority.medium,
      status: TaskStatus.inProgress,
      dueDate: DateTime(2026, 9, 18),
      zone: 'C-05',
    ),
    WarehouseTask(
      id: 1046,
      title: 'Обновить маркировку стеллажей',
      description: 'Заменить повреждённые этикетки на местах хранения.',
      priority: TaskPriority.low,
      status: TaskStatus.newTask,
      dueDate: DateTime(2026, 9, 20),
      zone: 'D-01',
    ),
    WarehouseTask(
      id: 1041,
      title: 'Инвентаризация возвратов',
      description: 'Подсчитать возвращённые товары и составить ведомость.',
      priority: TaskPriority.low,
      status: TaskStatus.completed,
      dueDate: DateTime(2026, 9, 15),
      zone: 'Возвраты',
    ),
  ];
}
