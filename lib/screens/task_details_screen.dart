import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_tasks.dart';
import '../utils/task_formatters.dart';
import '../widgets/favorite_button.dart';
import '../widgets/labeled_value_row.dart';

class TaskDetailsPage extends StatelessWidget {
  const TaskDetailsPage({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context) {
    final task = findMockTask(id);
    if (task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Задача не найдена')),
        body: Center(child: Text('Задача №$id отсутствует в mock-данных')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Задача №${task.id}'),
        actions: [
          FavoriteButton(
            isFavorite: task.isFavorite,
            onPressed: () => _showSuccess(
              context,
              'Избранное: действие подтверждено (демо)',
            ),
          ),
          IconButton(
            onPressed: () => _editTask(context),
            tooltip: 'Редактировать',
            icon: const Icon(Icons.edit_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE0E5EF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: const TextStyle(
                          color: Color(0xFF172033),
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        color: Color(0xFF3157D5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Описание',
                  style: TextStyle(
                    color: Color(0xFF697386),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  task.description,
                  style: const TextStyle(
                    color: Color(0xFF374151),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE0E5EF)),
            ),
            child: Column(
              children: [
                LabeledValueRow(
                  icon: Icons.flag_outlined,
                  label: 'Приоритет',
                  value: taskPriorityLabel(task.priority),
                ),
                const Divider(height: 28),
                LabeledValueRow(
                  icon: Icons.calendar_month_outlined,
                  label: 'Срок',
                  value: formatTaskDate(task.dueDate),
                ),
                const Divider(height: 28),
                LabeledValueRow(
                  icon: Icons.warehouse_outlined,
                  label: 'Зона склада',
                  value: task.zone,
                ),
                const Divider(height: 28),
                LabeledValueRow(
                  icon: Icons.sync_rounded,
                  label: 'Статус',
                  value: taskStatusLabel(task.status),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: () => _changeStatus(context),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF3157D5),
              ),
              icon: const Icon(Icons.sync_rounded),
              label: const Text(
                'Изменить статус',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 54,
            child: OutlinedButton.icon(
              onPressed: () => _editTask(context),
              icon: const Icon(Icons.edit_outlined),
              label: const Text(
                'Редактировать задачу',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editTask(BuildContext context) {
    context.push('${GoRouterState.of(context).uri.path}/edit');
  }

  void _changeStatus(BuildContext context) {
    context.push('${GoRouterState.of(context).uri.path}/status');
  }

  void _showSuccess(BuildContext context, String message) {
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
}
