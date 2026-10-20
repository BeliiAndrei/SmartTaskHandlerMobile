import 'package:flutter/material.dart';

import '../services/unsellable_store.dart';

class UnsellableScope extends InheritedNotifier<UnsellableStore> {
  const UnsellableScope({
    super.key,
    required UnsellableStore store,
    required super.child,
  }) : super(notifier: store);

  static UnsellableStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<UnsellableScope>();
    assert(scope != null, 'UnsellableScope is missing above this widget');
    return scope!.notifier!;
  }
}
