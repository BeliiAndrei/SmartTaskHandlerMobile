import 'package:flutter/material.dart';

import '../services/favorite_store.dart';

class FavoritesScope extends InheritedNotifier<FavoriteStore> {
  const FavoritesScope({
    super.key,
    required FavoriteStore store,
    required super.child,
  }) : super(notifier: store);

  static FavoriteStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<FavoritesScope>();
    assert(scope != null, 'FavoritesScope is missing above this widget');
    return scope!.notifier!;
  }
}
