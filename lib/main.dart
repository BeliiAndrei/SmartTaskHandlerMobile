import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:provider/provider.dart';

import 'data/auth_api.dart';
import 'data/cached_warehouse_task_repository.dart';
import 'data/http_warehouse_task_repository.dart';
import 'data/task_cache_store.dart';
import 'data/token_store.dart';
import 'data/users_api.dart';
import 'data/warehouse_task_repository.dart';
import 'models/task_model.dart';
import 'models/session_model.dart';
import 'router.dart';
import 'services/favorite_repository.dart';
import 'services/favorite_store.dart';
import 'services/unsellable_repository.dart';
import 'services/unsellable_store.dart';
import 'state/admin_users_providers.dart';
import 'widgets/favorites_scope.dart';
import 'widgets/unsellable_scope.dart';

final defaultFavoriteStore = FavoriteStore(FavoriteRepository());
final defaultUnsellableStore = UnsellableStore(UnsellableRepository());

const configuredApiBaseUrl = String.fromEnvironment('API_BASE_URL');

String get apiBaseUrl {
  if (configuredApiBaseUrl.isNotEmpty) {
    return configuredApiBaseUrl.replaceFirst(RegExp(r'/$'), '');
  }
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    // Android's 10.0.2.2 alias routes from the emulator to the host machine.
    return 'http://10.0.2.2:8080';
  }
  return 'http://localhost:8080';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final tokens = TokenStore();
  final taskCache = TaskCacheStore();
  final loggedIn = await tokens.read() != null;
  if (!loggedIn) await taskCache.clear();
  final session = SessionModel(initialRole: loggedIn ? UserRole.user : null);
  final auth = AuthApi(apiBaseUrl, tokens);
  router = createRouter(initialLocation: loggedIn ? '/tasks' : '/login');
  late final TaskModel tasks;
  final repository = CachedWarehouseTaskRepository(
    HttpWarehouseTaskRepository(
      apiBaseUrl,
      tokens,
      onUnauthorized: () {
        tasks.clear();
        session.signOut();
        unawaited(taskCache.clear());
        router.go('/login');
      },
    ),
    taskCache,
  );
  tasks = TaskModel(repository);
  try {
    await defaultFavoriteStore.load();
  } catch (error) {
    debugPrint('Failed to load favorites: $error');
  }
  try {
    await defaultUnsellableStore.load();
  } catch (error) {
    debugPrint('Failed to load unsellable reports: $error');
  }
  runApp(
    SmartTaskHandlerApp(
      authApi: auth,
      sessionModel: session,
      taskRepository: repository,
      taskModel: tasks,
    ),
  );
  if (loggedIn) await tasks.load();

  if (loggedIn) {
    final valid = await auth.validateStoredToken();
    if (valid == false) {
      await taskCache.clear();
      session.signOut();
      router.go('/login');
    } else if (valid == true) {
      session.signIn(
        role: auth.profileRole == 'administrator'
            ? UserRole.administrator
            : UserRole.user,
      );
    }
  }
}

class SmartTaskHandlerApp extends StatelessWidget {
  const SmartTaskHandlerApp({
    super.key,
    this.taskRepository,
    this.favoriteStore,
    this.unsellableStore,
    this.authApi,
    this.sessionModel,
    this.taskModel,
    this.usersApi,
  });

  final WarehouseTaskRepository? taskRepository;
  final FavoriteStore? favoriteStore;
  final UnsellableStore? unsellableStore;
  final AuthApi? authApi;
  final SessionModel? sessionModel;
  final TaskModel? taskModel;
  final UsersApi? usersApi;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF3157D5);

    final repository =
        taskRepository ??
        CachedWarehouseTaskRepository(
          HttpWarehouseTaskRepository(
            apiBaseUrl,
            TokenStore(),
            onUnauthorized: () => router.go('/login'),
          ),
          TaskCacheStore(),
        );
    final auth = authApi ?? AuthApi(apiBaseUrl, TokenStore());

    return riverpod.ProviderScope(
      overrides: [
        usersApiProvider.overrideWithValue(
          usersApi ?? UsersApi(auth.baseUrl, auth.tokens),
        ),
      ],
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => sessionModel ?? SessionModel()),
          Provider<AuthApi>.value(value: auth),
          Provider<WarehouseTaskRepository>.value(value: repository),
          ChangeNotifierProvider(
            create: (context) =>
                taskModel ??
                (TaskModel(context.read<WarehouseTaskRepository>())..load()),
          ),
        ],
        child: UnsellableScope(
          store: unsellableStore ?? defaultUnsellableStore,
          child: FavoritesScope(
            store: favoriteStore ?? defaultFavoriteStore,
            child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              title: 'SmartTaskHandler',
              theme: ThemeData(
                useMaterial3: true,
                colorScheme: ColorScheme.fromSeed(seedColor: primary),
                scaffoldBackgroundColor: const Color(0xFFF3F6FB),
                inputDecorationTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: const Color(0xFFF7F8FC),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 17,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE0E5EF)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: primary, width: 1.5),
                  ),
                ),
              ),
              routerConfig: router,
            ),
          ),
        ),
      ),
    );
  }
}
