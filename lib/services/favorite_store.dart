import 'package:flutter/foundation.dart';

import 'favorite_repository.dart';

/// One observable source of truth shared by the list, details and favorites tab.
class FavoriteStore extends ChangeNotifier {
  FavoriteStore(this.repository);

  final FavoriteRepository repository;
  Set<int> _ids = <int>{};
  Object? _loadError;
  Future<void> _pendingWrite = Future<void>.value();

  bool contains(int id) => _ids.contains(id);
  bool get hasLoadError => _loadError != null;

  Future<void> load() async {
    try {
      _ids = await repository.readIds();
      _loadError = null;
      notifyListeners();
    } catch (error) {
      _loadError = error;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> toggle(int id) {
    if (id <= 0) throw ArgumentError.value(id, 'id');

    // Queue changes so fast repeated taps cannot overwrite a newer file.
    final operation = _pendingWrite.then((_) async {
      if (_loadError != null) {
        throw StateError('Favorites could not be loaded');
      }
      final next = Set<int>.of(_ids);
      final isFavorite = next.add(id);
      if (!isFavorite) next.remove(id);
      await repository.writeIds(next);
      _ids = next;
      notifyListeners();
      return isFavorite;
    });
    _pendingWrite = operation.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return operation;
  }
}
