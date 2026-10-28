import '../models/warehouse_task.dart';
import 'result.dart';

abstract class WarehouseTaskRepository {
  Future<Result<List<WarehouseTask>>> fetchAll({
    int page = 1,
    int limit = 20,
    String? search,
  });

  Future<Result<WarehouseTask>> fetchById(int id);

  Future<Result<WarehouseTask>> create(WarehouseTask task);

  Future<Result<WarehouseTask>> update(WarehouseTask task);

  Future<Result<void>> delete(int id);

  Future<Result<WarehouseTask>> changeStatus(
    WarehouseTask task,
    TaskStatus status, {
    String? comment,
  }) => update(task.copyWith(status: status));

  Future<Result<void>> confirmDestination(
    int taskId,
    String qrCodeValue,
  ) async => const Err('Подтверждение QR недоступно');

  Future<Result<List<TaskHistoryEntry>>> fetchHistory(int taskId) async =>
      const Ok([]);

  Future<Result<List<WarehouseLocation>>> fetchLocations() async =>
      const Ok([]);

  Future<Result<WarehouseLocation>> fetchLocation(int id) async {
    switch (await fetchLocations()) {
      case Err(msg: final msg):
        return Err(msg);
      case Ok(value: final items):
        for (final location in items) {
          if (location.id == id) return Ok(location);
        }
        return const Err('Точка не существует');
    }
  }
}

class WarehouseLocation {
  const WarehouseLocation({
    required this.id,
    required this.name,
    required this.zone,
    required this.qrCodeValue,
  });
  final int id;
  final String name;
  final String zone;
  final String qrCodeValue;

  factory WarehouseLocation.fromJson(Map<String, dynamic> json) =>
      WarehouseLocation(
        id: json['id'] as int,
        name: json['name'] as String,
        zone: json['zone'] as String,
        qrCodeValue: json['qrCodeValue'] as String,
      );
}

class TaskHistoryEntry {
  const TaskHistoryEntry({
    required this.previousStatus,
    required this.newStatus,
    required this.changedAt,
    this.comment,
  });

  final String? previousStatus;
  final String newStatus;
  final DateTime changedAt;
  final String? comment;

  factory TaskHistoryEntry.fromJson(Map<String, dynamic> json) =>
      TaskHistoryEntry(
        previousStatus: json['previousStatus'] as String?,
        newStatus: json['newStatus'] as String,
        changedAt: DateTime.parse(json['changedAt'] as String),
        comment: json['comment'] as String?,
      );
}
