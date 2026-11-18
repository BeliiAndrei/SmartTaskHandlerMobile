import '../models/warehouse_task.dart';
import 'result.dart';
import 'task_cache_store.dart';
import 'warehouse_task_repository.dart';

/// Adds a persistent, read-only offline fallback to the live task repository.
class CachedWarehouseTaskRepository implements WarehouseTaskRepository {
  CachedWarehouseTaskRepository(this._remote, this._cache);

  final WarehouseTaskRepository _remote;
  final TaskCacheStore _cache;
  bool _showingCachedData = false;

  @override
  bool get isShowingCachedData => _showingCachedData;

  @override
  Future<void> clearCachedTasks() => _cache.clear();

  bool _isConnectivityFailure(String message) =>
      message.startsWith('Нет сети') ||
      message.startsWith('Сервер не отвечает');

  @override
  Future<Result<List<WarehouseTask>>> fetchAll({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    final result = await _remote.fetchAll(
      page: page,
      limit: limit,
      search: search,
    );
    switch (result) {
      case Ok(value: final tasks):
        if (page == 1) _showingCachedData = false;
        try {
          await _cache.writePage(
            page: page,
            limit: limit,
            tasks: tasks,
            search: search,
          );
        } on Object {
          // Cache failures must not turn a successful server response into an error.
        }
        return Ok(tasks);
      case Err(msg: final message):
        if (!_isConnectivityFailure(message)) return Err(message);
        try {
          final cached = await _cache.readPage(
            page: page,
            limit: limit,
            search: search,
          );
          if (cached != null) {
            _showingCachedData = true;
            return Ok(cached);
          }
        } on Object {
          // Keep the original network error if the local store is unavailable.
        }
        if (page > 1) {
          return const Err('Нет сети — эта страница ещё не сохранена');
        }
        return Err(message);
    }
  }

  @override
  Future<Result<WarehouseTask>> fetchById(int id) async {
    final result = await _remote.fetchById(id);
    switch (result) {
      case Ok():
        return result;
      case Err(msg: final message):
        if (!_isConnectivityFailure(message)) return Err(message);
        try {
          final cached = await _cache.readTask(id);
          if (cached != null) {
            _showingCachedData = true;
            return Ok(cached);
          }
        } on Object {
          // Preserve the original request error when local storage fails.
        }
        return Err(message);
    }
  }

  Future<Result<T>> _invalidateOnSuccess<T>(Future<Result<T>> request) async {
    final result = await request;
    if (result is Ok<T>) {
      try {
        await _cache.clear();
      } on Object {
        // A local cache must never block a successful server-side mutation.
      }
    }
    return result;
  }

  @override
  Future<Result<WarehouseTask>> create(WarehouseTask task) =>
      _invalidateOnSuccess(_remote.create(task));

  @override
  Future<Result<WarehouseTask>> update(WarehouseTask task) =>
      _invalidateOnSuccess(_remote.update(task));

  @override
  Future<Result<void>> delete(int id) =>
      _invalidateOnSuccess(_remote.delete(id));

  @override
  Future<Result<WarehouseTask>> changeStatus(
    WarehouseTask task,
    TaskStatus status, {
    String? comment,
  }) => _invalidateOnSuccess(
    _remote.changeStatus(task, status, comment: comment),
  );

  @override
  Future<Result<void>> confirmDestination(int taskId, String qrCodeValue) =>
      _invalidateOnSuccess(_remote.confirmDestination(taskId, qrCodeValue));

  @override
  Future<Result<List<TaskHistoryEntry>>> fetchHistory(int taskId) =>
      _remote.fetchHistory(taskId);

  @override
  Future<Result<List<WarehouseLocation>>> fetchLocations() =>
      _remote.fetchLocations();

  @override
  Future<Result<WarehouseLocation>> fetchLocation(int id) =>
      _remote.fetchLocation(id);
}
