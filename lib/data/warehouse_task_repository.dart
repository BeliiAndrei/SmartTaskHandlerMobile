import '../models/warehouse_task.dart';
import 'result.dart';

abstract class WarehouseTaskRepository {
  Future<Result<List<WarehouseTask>>> fetchAll();

  Future<Result<WarehouseTask>> fetchById(int id);

  Future<Result<WarehouseTask>> create(WarehouseTask task);

  Future<Result<WarehouseTask>> update(WarehouseTask task);

  Future<Result<void>> delete(int id);
}
