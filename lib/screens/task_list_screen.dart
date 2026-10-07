import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_tasks.dart';
import '../models/warehouse_task.dart';
import '../services/task_logic.dart';
import '../widgets/task_card.dart';

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

  List<WarehouseTask> get _visibleTasks {
    return TaskLogic.filterTasks(
      mockTasks,
      query: _searchController.text,
      status: _selectedStatus,
    );
  }

  @override
  Widget build(BuildContext context) {
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
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: CircleAvatar(
              backgroundColor: const Color(0xFF3157D5),
              child: Text(
                'BA',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _buildTaskList(),
      floatingActionButton: FloatingActionButton.extended(
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

  Widget _buildTaskList() {
    final visibleTasks = _visibleTasks;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Поиск по задачам или зоне',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
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
          child: visibleTasks.isEmpty
              ? const _EmptyTaskList()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  itemCount: visibleTasks.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final task = visibleTasks[index];
                    return TaskCard(
                      task: task,
                      onTap: () => context.push('/tasks/${task.id}'),
                      onFavoriteToggle: () => _showSuccess(
                        'Избранное: действие подтверждено (демо)',
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(message, style: const TextStyle(fontSize: 12)),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          width: 300,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          backgroundColor: const Color(0xFF15803D),
        ),
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
