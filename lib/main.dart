import 'package:flutter/material.dart';

import 'router.dart';
import 'services/favorite_repository.dart';
import 'services/favorite_store.dart';
import 'widgets/favorites_scope.dart';

final defaultFavoriteStore = FavoriteStore(FavoriteRepository());

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await defaultFavoriteStore.load();
  } catch (error) {
    debugPrint('Failed to load favorites: $error');
  }
  runApp(const SmartTaskHandlerApp());
}

class SmartTaskHandlerApp extends StatelessWidget {
  const SmartTaskHandlerApp({super.key, this.favoriteStore});

  final FavoriteStore? favoriteStore;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF3157D5);

    return FavoritesScope(
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
    );
  }
}
