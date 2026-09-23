import 'package:flutter/material.dart';

import '../data/mock_tasks.dart';
import '../models/warehouse_task.dart';
import '../widgets/task_card.dart';
import 'profile_screen.dart';
import 'task_details_screen.dart';
import 'task_form_screen.dart';
import 'task_history_screen.dart';

class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key, required this.logoutDestination});

  final Widget logoutDestination;

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  final _searchController = TextEditingController();
  TaskStatus? _selectedStatus;
  int _currentSection = 0;

  final List<WarehouseTask> _tasks = createMockTasks();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<WarehouseTask> get _visibleTasks {
    final query = _searchController.text.trim().toLowerCase();

    return _tasks.where((task) {
      final matchesStatus =
          _selectedStatus == null || task.status == _selectedStatus;
      final matchesSearch =
          query.isEmpty ||
          task.title.toLowerCase().contains(query) ||
          task.description.toLowerCase().contains(query) ||
          task.zone.toLowerCase().contains(query);
      return matchesStatus && matchesSearch;
    }).toList();
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
            Text(
              _sectionTitle,
              style: const TextStyle(
                color: Color(0xFF172033),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              _sectionSubtitle,
              style: const TextStyle(
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
      body: switch (_currentSection) {
        0 => _buildTaskList(),
        1 => TaskHistoryPage(tasks: _tasks, onTaskSelected: _openTask),
        _ => ProfilePage(tasks: _tasks, onLogout: _logout),
      },
      floatingActionButton: _currentSection == 0
          ? FloatingActionButton.extended(
              onPressed: _createTask,
              backgroundColor: const Color(0xFF3157D5),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Новая задача',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentSection,
        onDestinationSelected: (index) {
          setState(() => _currentSection = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment_rounded),
            label: 'Задачи',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            label: 'История',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }

  String get _sectionTitle {
    return switch (_currentSection) {
      0 => 'Складские задачи',
      1 => 'История задач',
      _ => 'Профиль',
    };
  }

  String get _sectionSubtitle {
    return switch (_currentSection) {
      0 => 'Сегодня, 16 сентября',
      1 => 'Выполненные задания',
      _ => 'Данные сотрудника',
    };
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
                    return TaskCard(task: task, onTap: () => _openTask(task));
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _openTask(WarehouseTask task) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => TaskDetailsPage(
          task: task,
          onTaskChanged: (updatedTask) {
            final index = _tasks.indexWhere(
              (item) => item.id == updatedTask.id,
            );
            if (index != -1) setState(() => _tasks[index] = updatedTask);
          },
        ),
      ),
    );
  }

  Future<void> _createTask() async {
    final nextId =
        _tasks.map((task) => task.id).reduce((a, b) => a > b ? a : b) + 1;
    final result = await Navigator.push<WarehouseTask>(
      context,
      MaterialPageRoute(builder: (_) => TaskFormPage(taskId: nextId)),
    );
    if (result != null && mounted) {
      setState(() => _tasks.insert(0, result));
      _showSuccess('Задача создана');
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Text(message),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF15803D),
        ),
      );
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => widget.logoutDestination),
      (_) => false,
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
