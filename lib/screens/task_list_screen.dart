import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/task_model.dart';
import '../models/warehouse_task.dart';
import '../services/task_logic.dart';
import '../widgets/favorite_actions.dart';
import '../widgets/favorites_scope.dart';
import '../widgets/task_card.dart';
import '../widgets/task_data_view.dart';

class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  final _searchController = TextEditingController();
  TaskStatus? _selectedStatus;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<WarehouseTask> _visibleTasks(List<WarehouseTask> tasks) {
    return TaskLogic.filterTasks(
      tasks,
      query: '', // Search is performed by the backend for all pages.
      status: _selectedStatus,
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<TaskModel>();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F6FB),
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Складские задачи',
              style: TextStyle(
                color: Color(0xFF172033),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Text(
              'Назначенные задания',
              style: TextStyle(
                color: Color(0xFF697386),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: Tooltip(
              message: 'Активные задачи',
              child: Consumer<TaskModel>(
                builder: (context, model, child) =>
                    Badge(label: Text('${model.activeCount}'), child: child!),
                child: const Icon(Icons.assignment_outlined),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: CircleAvatar(
              backgroundColor: const Color(0xFF3157D5),
              child: Icon(
                Icons.person_rounded,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
      body: TaskDataView(builder: (context, model) => _buildTaskList(model)),
      floatingActionButton: model.isLoading || model.error != null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/tasks/new'),
              backgroundColor: const Color(0xFF3157D5),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Новая задача',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
    );
  }

  Widget _buildTaskList(TaskModel model) {
    final visibleTasks = _visibleTasks(model.tasks);
    final favorites = FavoritesScope.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onChanged: (_) => setState(() {}),
            onSubmitted: (value) {
              context.read<TaskModel>().load(search: value);
            },
            decoration: InputDecoration(
              hintText: 'Поиск по задачам или зоне',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                        context.read<TaskModel>().load(search: '');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
        ),
        SizedBox(
          height: 66,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            scrollDirection: Axis.horizontal,
            children: [
              _StatusFilterChip(
                text: 'Все',
                selected: _selectedStatus == null,
                onSelected: () => setState(() => _selectedStatus = null),
              ),
              _StatusFilterChip(
                text: 'Новые',
                selected: _selectedStatus == TaskStatus.newTask,
                onSelected: () {
                  setState(() => _selectedStatus = TaskStatus.newTask);
                },
              ),
              _StatusFilterChip(
                text: 'В работе',
                selected: _selectedStatus == TaskStatus.inProgress,
                onSelected: () {
                  setState(() => _selectedStatus = TaskStatus.inProgress);
                },
              ),
              _StatusFilterChip(
                text: 'Приостановлены',
                selected: _selectedStatus == TaskStatus.paused,
                onSelected: () {
                  setState(() => _selectedStatus = TaskStatus.paused);
                },
              ),
              _StatusFilterChip(
                text: 'Выполненные',
                selected: _selectedStatus == TaskStatus.completed,
                onSelected: () {
                  setState(() => _selectedStatus = TaskStatus.completed);
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Найдено: ${visibleTasks.length}',
              style: const TextStyle(
                color: Color(0xFF697386),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        Expanded(
          child: visibleTasks.isEmpty && !model.hasMore
              ? const _EmptyTaskList()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  itemCount: visibleTasks.length + (model.hasMore ? 1 : 0),
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == visibleTasks.length) {
                      if (!model.isLoadingMore && model.moreError == null) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) context.read<TaskModel>().loadMore();
                        });
                      }
                      if (model.moreError case final message?) {
                        return TextButton(
                          onPressed: () => context.read<TaskModel>().loadMore(),
                          child: Text('$message — повторить'),
                        );
                      }
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    final task = visibleTasks[index];
                    return TaskCard(
                      task: task,
                      isFavorite: favorites.contains(task.id),
                      onTap: () => context.push('/tasks/${task.id}'),
                      onFavoriteToggle: () =>
                          toggleFavoriteWithFeedback(context, task.id),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  const _StatusFilterChip({
    required this.text,
    required this.selected,
    required this.onSelected,
  });

  final String text;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(text),
        selected: selected,
        onSelected: (_) => onSelected(),
        showCheckmark: false,
        selectedColor: const Color(0xFF3157D5),
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFE0E5EF)),
        labelStyle: TextStyle(
          color: selected ? Colors.white : const Color(0xFF4B5563),
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

class _EmptyTaskList extends StatelessWidget {
  const _EmptyTaskList();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 58, color: Color(0xFF98A2B3)),
            SizedBox(height: 12),
            Text(
              'Задачи не найдены',
              style: TextStyle(
                color: Color(0xFF4B5563),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Измените поисковый запрос или выберите другой статус',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF697386)),
            ),
          ],
        ),
      ),
    );
  }
}
