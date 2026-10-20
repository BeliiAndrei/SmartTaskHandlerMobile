import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/task_model.dart';
import '../widgets/favorite_actions.dart';
import '../widgets/favorites_scope.dart';
import '../widgets/task_card.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites = FavoritesScope.of(context);
    final tasks = context
        .watch<TaskModel>()
        .tasks
        .where((task) => favorites.contains(task.id))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Избранное')),
      body: favorites.hasLoadError
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Не удалось прочитать избранное'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () async {
                      try {
                        await favorites.load();
                      } catch (_) {
                        // Keep the error visible; do not overwrite the JSON file.
                      }
                    },
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            )
          : tasks.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star_border_rounded,
                    size: 60,
                    color: Color(0xFF98A2B3),
                  ),
                  SizedBox(height: 12),
                  Text('Пока нет избранных задач'),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
              itemCount: tasks.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, index) {
                final task = tasks[index];
                return TaskCard(
                  task: task,
                  isFavorite: favorites.contains(task.id),
                  onTap: () => context.push('/favorites/${task.id}'),
                  onFavoriteToggle: () =>
                      toggleFavoriteWithFeedback(context, task.id),
                );
              },
            ),
    );
  }
}
