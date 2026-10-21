import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/mock_warehouse_task_repository.dart';
import 'data/warehouse_task_repository.dart';
import 'models/task_model.dart';
import 'router.dart';
import 'services/favorite_repository.dart';
import 'services/favorite_store.dart';
import 'services/unsellable_repository.dart';
import 'services/unsellable_store.dart';
import 'widgets/favorites_scope.dart';
import 'widgets/unsellable_scope.dart';

final defaultFavoriteStore = FavoriteStore(FavoriteRepository());
final defaultUnsellableStore = UnsellableStore(UnsellableRepository());

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  runApp(const SmartTaskHandlerApp());
}

class SmartTaskHandlerApp extends StatelessWidget {
  const SmartTaskHandlerApp({
    super.key,
    this.taskRepository,
    this.favoriteStore,
    this.unsellableStore,
  });

  final WarehouseTaskRepository? taskRepository;
  final FavoriteStore? favoriteStore;
  final UnsellableStore? unsellableStore;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF3157D5);

    final repository = taskRepository ?? MockWarehouseTaskRepository();

    return MultiProvider(
      providers: [
        Provider<WarehouseTaskRepository>.value(value: repository),
        ChangeNotifierProvider(
          create: (context) =>
              TaskModel(context.read<WarehouseTaskRepository>())..load(),
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
    );
  }
}
