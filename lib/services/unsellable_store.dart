import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/unsellable_report.dart';
import 'unsellable_repository.dart';

class UnsellableStore extends ChangeNotifier {
  UnsellableStore(this.repository);

  final UnsellableRepository repository;
  List<UnsellableReport> _reports = <UnsellableReport>[];
  Object? _loadError;
  Future<void> _pendingWrite = Future<void>.value();

  List<UnsellableReport> get reports => List.unmodifiable(_reports);
  bool get hasLoadError => _loadError != null;

  UnsellableReport? find(String id) {
    for (final report in _reports) {
      if (report.id == id) return report;
    }
    return null;
  }

  Future<void> load() async {
    try {
      _reports = await repository.load();
      _loadError = null;
      notifyListeners();
    } catch (error) {
      _loadError = error;
      notifyListeners();
      rethrow;
    }
  }

  Future<UnsellableReport> create({
    required String title,
    required String description,
    required File sourcePhoto,
  }) {
    final operation = _pendingWrite.then((_) async {
      if (_loadError != null) {
        throw StateError('Unsellable reports could not be loaded');
      }
      final report = await repository.create(
        title: title,
        description: description,
        sourcePhoto: sourcePhoto,
      );
      _reports = [report, ..._reports];
      notifyListeners();
      return report;
    });
    _pendingWrite = operation.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return operation;
  }
}
