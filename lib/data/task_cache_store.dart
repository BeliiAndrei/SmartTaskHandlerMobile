import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/warehouse_task.dart';

/// Persistent, paginated cache for task lists previously received from server.
class TaskCacheStore {
  static const _prefix = 'warehouse_task_cache_v1_';

  String _key(String? search, int limit) {
    final query = (search ?? '').trim();
    final encodedQuery = base64Url.encode(utf8.encode(query));
    return '$_prefix${limit}_$encodedQuery';
  }

  Future<List<WarehouseTask>?> readPage({
    required int page,
    required int limit,
    String? search,
  }) async {
    if (page < 1 || limit < 1) return null;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(search, limit));
    if (raw == null) return null;

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final items = (decoded['items'] as List<dynamic>)
          .map(
            (item) => WarehouseTask.fromCacheJson(item as Map<String, dynamic>),
          )
          .toList();
      final complete = decoded['complete'] as bool? ?? false;
      final start = (page - 1) * limit;
      if (start >= items.length) {
        return complete ? <WarehouseTask>[] : null;
      }
      return items.skip(start).take(limit).toList();
    } on Object {
      // Ignore a corrupt/old cache. The next successful server read replaces it.
      await prefs.remove(_key(search, limit));
      return null;
    }
  }

  Future<WarehouseTask?> readTask(int id) async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys().where((key) => key.startsWith(_prefix))) {
      final raw = prefs.getString(key);
      if (raw == null) continue;
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        for (final value in decoded['items'] as List<dynamic>) {
          final task = WarehouseTask.fromCacheJson(
            value as Map<String, dynamic>,
          );
          if (task.id == id) return task;
        }
      } on Object {
        await prefs.remove(key);
      }
    }
    return null;
  }

  Future<void> writePage({
    required int page,
    required int limit,
    required List<WarehouseTask> tasks,
    String? search,
  }) async {
    if (page < 1 || limit < 1) return;
    final prefs = await SharedPreferences.getInstance();
    final key = _key(search, limit);
    var items = <WarehouseTask>[];
    if (page > 1) {
      final raw = prefs.getString(key);
      if (raw != null) {
        try {
          final decoded = jsonDecode(raw) as Map<String, dynamic>;
          items = (decoded['items'] as List<dynamic>)
              .map(
                (item) =>
                    WarehouseTask.fromCacheJson(item as Map<String, dynamic>),
              )
              .toList();
        } on Object {
          items = <WarehouseTask>[];
        }
      }
    }

    final start = (page - 1) * limit;
    if (page == 1) items = <WarehouseTask>[];
    if (start > items.length) return;
    if (items.length > start) items.removeRange(start, items.length);
    items.addAll(tasks);
    await prefs.setString(
      key,
      jsonEncode({
        'items': items.map((task) => task.toCacheJson()).toList(),
        'complete': tasks.length < limit,
      }),
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(_prefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
