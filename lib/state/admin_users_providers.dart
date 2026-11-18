import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/users_api.dart';

/// The app supplies the API instance; tests can override it independently.
final usersApiProvider = Provider<UsersApi>(
  (ref) => throw StateError('UsersApi must be provided at the app root'),
);

/// Riverpod owns the request, loading/error states and refresh lifecycle.
final adminUsersProvider = FutureProvider.autoDispose<List<RegisteredUser>>(
  (ref) => ref.watch(usersApiProvider).fetchOthers(),
);
