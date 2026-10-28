import 'package:flutter/foundation.dart';

import '../data/result.dart';
import '../data/warehouse_task_repository.dart';
import 'warehouse_task.dart';

/// Shared warehouse task state. The repository supplies all task data.
class TaskModel extends ChangeNotifier {
  TaskModel(this._repository);

  final WarehouseTaskRepository _repository;
  List<WarehouseTask> _tasks = [];
  bool _loading = false;
  String? _error;
  String? _search;
  int _page = 1;
  static const _limit = 20;
  bool _hasMore = false;
  bool _loadingMore = false;
  String? _moreError;
  int _requestGeneration = 0;

  bool get isLoading => _loading;
  String? get error => _error;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _loadingMore;
  String? get moreError => _moreError;
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

  Future<String?> refreshById(int id) async {
    switch (await _repository.fetchById(id)) {
      case Ok(value: final value):
        final index = _tasks.indexWhere((item) => item.id == id);
        if (index == -1) {
          _tasks = [..._tasks, value];
        } else {
          _tasks = List.of(_tasks)..[index] = value;
        }
        notifyListeners();
        return null;
      case Err(msg: final msg):
        return msg;
    }
  }

  Future<void> load({String? search}) async {
    if (search != null) _search = search.trim();
    final generation = ++_requestGeneration;
    _page = 1;
    _hasMore = false;
    _loadingMore = false;
    _moreError = null;
    _loading = true;
    _error = null;
    notifyListeners();

    final result = await _repository.fetchAll(limit: _limit, search: _search);
    if (generation != _requestGeneration) return;
    switch (result) {
      case Ok(value: final value):
        _tasks = List.of(value);
        _hasMore = value.length == _limit;
      case Err(msg: final msg):
        _tasks = [];
        _error = msg;
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_loading || _loadingMore || !_hasMore) return;
    _loadingMore = true; // Called from itemBuilder: do not notify during build.
    final generation = _requestGeneration;
    final result = await _repository.fetchAll(
      page: _page + 1,
      limit: _limit,
      search: _search,
    );
    if (generation != _requestGeneration) return;
    _loadingMore = false;
    switch (result) {
      case Ok(value: final value):
        _page++;
        _tasks = [..._tasks, ...value];
        _hasMore = value.length == _limit;
        _moreError = null;
      case Err(msg: final msg):
        _moreError = msg;
    }
    notifyListeners();
  }

  void clear() {
    ++_requestGeneration;
    _tasks = [];
    _error = null;
    _hasMore = false;
    _loading = false;
    _loadingMore = false;
    _moreError = null;
    _search = null;
    notifyListeners();
  }

  Future<String?> add(WarehouseTask draft) async {
    switch (await _repository.create(draft)) {
      case Ok(value: final value):
        if (_search != null && _search!.isNotEmpty) {
          await load();
        } else {
          _tasks = [value, ..._tasks];
          notifyListeners();
        }
        return null;
      case Err(msg: final msg):
        return msg;
    }
  }

  Future<String?> update(WarehouseTask task) async {
    if (byId(task.id) == null) return 'Задача не существует';
    switch (await _repository.update(task)) {
      case Ok(value: final value):
        final index = _tasks.indexWhere((current) => current.id == value.id);
        if (index == -1) return 'Задача не существует';
        _tasks = List.of(_tasks)..[index] = value;
        if (_search != null && _search!.isNotEmpty) {
          await load();
        } else {
          notifyListeners();
        }
        return null;
      case Err(msg: final msg):
        return msg;
    }
  }

  Future<String?> remove(int id) async {
    if (byId(id) == null) return 'Задача не существует';
    switch (await _repository.delete(id)) {
      case Ok():
        _tasks = _tasks.where((task) => task.id != id).toList();
        notifyListeners();
        return null;
      case Err(msg: final msg):
        return msg;
    }
  }

  Future<String?> updateStatus(int id, TaskStatus status) async {
    final task = byId(id);
    if (task == null) return 'Задача не существует';
    switch (await _repository.changeStatus(task, status)) {
      case Ok(value: final value):
        _tasks = _tasks.map((item) => item.id == id ? value : item).toList();
        notifyListeners();
        return null;
      case Err(msg: final msg):
        return msg;
    }
  }

  Future<String?> confirmDestination(int id, String qr) async {
    switch (await _repository.confirmDestination(id, qr)) {
      case Ok():
        return null;
      case Err(msg: final msg):
        return msg;
    }
  }
}
