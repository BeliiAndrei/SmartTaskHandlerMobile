enum TaskPriority { low, medium, high }

enum TaskStatus { newTask, inProgress, paused, completed }

class WarehouseTask {
  const WarehouseTask({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.dueDate,
    required this.zone,
    this.isFavorite = false,
  });

  final int id;
  final String title;
  final String description;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime dueDate;
  final String zone;
  final bool isFavorite;

  WarehouseTask copyWith({
    int? id,
    String? title,
    String? description,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? dueDate,
    String? zone,
    bool? isFavorite,
  }) {
    return WarehouseTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      zone: zone ?? this.zone,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
