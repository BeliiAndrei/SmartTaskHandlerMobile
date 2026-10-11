import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

typedef SupportDirectoryProvider = Future<Directory> Function();

/// Stores only task ids; task details continue to come from the task source.
class FavoriteRepository {
  FavoriteRepository({SupportDirectoryProvider? directoryProvider})
    : _directoryProvider = directoryProvider ?? getApplicationSupportDirectory;

  static const fileName = 'favorite_task_ids.json';
  final SupportDirectoryProvider _directoryProvider;

  Future<File> _file() async {
    final directory = await _directoryProvider();
    return File('${directory.path}${Platform.pathSeparator}$fileName');
  }

  Future<Set<int>> readIds() async {
    final file = await _file();
    if (!await file.exists()) return <int>{};

    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, dynamic> || decoded['taskIds'] is! List) {
      throw const FormatException('Invalid favorites JSON structure');
    }

    final ids = <int>{};
    for (final value in decoded['taskIds'] as List) {
      if (value is! int || value <= 0) {
        throw const FormatException('Invalid favorite task id');
      }
      ids.add(value);
    }
    return ids;
  }

  Future<void> writeIds(Set<int> ids) async {
    if (ids.any((id) => id <= 0)) {
      throw ArgumentError.value(ids, 'ids', 'Task ids must be positive');
    }

    final file = await _file();
    await file.parent.create(recursive: true);
    final sortedIds = ids.toList()..sort();
    final contents = const JsonEncoder.withIndent('  ')
        .convert({'taskIds': sortedIds});
    await file.writeAsString('$contents\n', flush: true);
  }
}
