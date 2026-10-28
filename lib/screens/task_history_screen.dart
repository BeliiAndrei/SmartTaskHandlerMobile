import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/warehouse_task.dart';
import '../models/task_model.dart';
import '../services/task_logic.dart';
import '../widgets/favorite_actions.dart';
import '../widgets/favorites_scope.dart';
import '../widgets/task_card.dart';
import '../widgets/task_data_view.dart';

class TaskHistoryPage extends StatelessWidget {
  const TaskHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('История задач')),
      body: TaskDataView(
        builder: (context, model) =>
            _historyBody(context, model, TaskLogic.completedTasks(model.tasks)),
      ),
    );
  }

  Widget _historyBody(
    BuildContext context,
    TaskModel model,
    List<WarehouseTask> completedTasks,
  ) {
    final favorites = FavoritesScope.of(context);
    if (completedTasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.history_toggle_off_rounded,
                size: 62,
                color: Color(0xFF98A2B3),
              ),
              const SizedBox(height: 14),
              const Text(
                'История пока пуста',
                style: TextStyle(
                  color: Color(0xFF374151),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Выполненные задачи появятся здесь',
                style: TextStyle(color: Color(0xFF697386)),
              ),
              if (model.hasMore) _moreButton(model),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF8EF),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF16A34A),
                size: 34,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${completedTasks.length} выполнено',
                      style: const TextStyle(
                        color: Color(0xFF166534),
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Text(
                      'История завершённых складских задач',
                      maxLines: 2,
                      style: TextStyle(color: Color(0xFF3F7652), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        for (final task in completedTasks) ...[
          TaskCard(
            task: task,
            isFavorite: favorites.contains(task.id),
            onTap: () => context.push('/history/${task.id}'),
            onFavoriteToggle: () =>
                toggleFavoriteWithFeedback(context, task.id),
            showPriority: false,
            showDueDate: false,
            showChevron: false,
          ),
          const SizedBox(height: 12),
        ],
        if (model.hasMore) _moreButton(model),
      ],
    );
  }

  Widget _moreButton(TaskModel model) => TextButton(
    onPressed: model.isLoadingMore ? null : model.loadMore,
    child: Text(
      model.moreError == null
          ? 'Загрузить ещё задачи'
          : '${model.moreError} — повторить',
    ),
  );
}
