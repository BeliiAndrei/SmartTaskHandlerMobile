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
    this.sourceLocationId = 0,
    this.destinationLocationId = 0,
    this.isFavorite = false,
  });

  final int id;
  final String title;
  final String description;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime dueDate;
  final String zone;
  final int sourceLocationId;
  final int destinationLocationId;
  final bool isFavorite;

  factory WarehouseTask.fromJson(Map<String, dynamic> json) {
    final destination = json['destinationLocationId'] as int;
    return WarehouseTask(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      priority: switch (json['priority'] as String) {
        'low' => TaskPriority.low,
        'medium' => TaskPriority.medium,
        'high' => TaskPriority.high,
        _ => throw const FormatException('Unknown task priority'),
      },
      status: switch (json['status'] as String) {
        'new' => TaskStatus.newTask,
        'in_progress' => TaskStatus.inProgress,
        'paused' => TaskStatus.paused,
        'completed' => TaskStatus.completed,
        _ => throw const FormatException('Unknown task status'),
      },
      dueDate: DateTime.parse(json['dueAt'] as String),
      zone: 'Точка №$destination',
      sourceLocationId: json['sourceLocationId'] as int,
      destinationLocationId: destination,
    );
  }

  Map<String, Object?> toJson() => {
    'title': title,
    'description': description,
    'priority': priority.name,
    'sourceLocationId': sourceLocationId,
    'destinationLocationId': destinationLocationId,
    'dueAt': dueDate.toUtc().toIso8601String(),
  };

  WarehouseTask copyWith({
    int? id,
    String? title,
    String? description,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? dueDate,
    String? zone,
    int? sourceLocationId,
    int? destinationLocationId,
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
      sourceLocationId: sourceLocationId ?? this.sourceLocationId,
      destinationLocationId:
          destinationLocationId ?? this.destinationLocationId,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
