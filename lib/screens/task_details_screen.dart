import 'package:flutter/material.dart';

import '../models/warehouse_task.dart';
import '../widgets/labeled_value_row.dart';
import 'task_form_screen.dart';
import 'task_status_screen.dart';

class TaskDetailsPage extends StatefulWidget {
  const TaskDetailsPage({
    super.key,
    required this.task,
    required this.onTaskChanged,
  });

  final WarehouseTask task;
  final ValueChanged<WarehouseTask> onTaskChanged;

  @override
  State<TaskDetailsPage> createState() => _TaskDetailsPageState();
}

class _TaskDetailsPageState extends State<TaskDetailsPage> {
  late WarehouseTask _task;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text('Задача №${_task.id}'),
        actions: [
          IconButton(
            onPressed: _editTask,
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
                        _task.title,
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
                  _task.description,
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
                  value: _priorityText(_task.priority),
                ),
                const Divider(height: 28),
                LabeledValueRow(
                  icon: Icons.calendar_month_outlined,
                  label: 'Срок',
                  value: _formatDate(_task.dueDate),
                ),
                const Divider(height: 28),
                LabeledValueRow(
                  icon: Icons.warehouse_outlined,
                  label: 'Зона склада',
                  value: _task.zone,
                ),
                const Divider(height: 28),
                LabeledValueRow(
                  icon: Icons.sync_rounded,
                  label: 'Статус',
                  value: _statusText(_task.status),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: _changeStatus,
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
              onPressed: _editTask,
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

  Future<void> _editTask() async {
    final result = await Navigator.push<WarehouseTask>(
      context,
      MaterialPageRoute(
        builder: (_) => TaskFormPage(taskId: _task.id, task: _task),
      ),
    );
    if (result != null) {
      setState(() => _task = result);
      widget.onTaskChanged(_task);
      _showSuccess('Изменения сохранены');
    }
  }

  Future<void> _changeStatus() async {
    final result = await Navigator.push<TaskStatus>(
      context,
      MaterialPageRoute(
        builder: (_) => TaskStatusPage(currentStatus: _task.status),
      ),
    );
    if (result != null) {
      setState(() => _task = _task.copyWith(status: result));
      widget.onTaskChanged(_task);
      _showSuccess('Статус задачи изменён');
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

  static String _priorityText(TaskPriority priority) {
    return switch (priority) {
      TaskPriority.low => 'Низкий',
      TaskPriority.medium => 'Средний',
      TaskPriority.high => 'Высокий',
    };
  }

  static String _statusText(TaskStatus status) {
    return switch (status) {
      TaskStatus.newTask => 'Новая',
      TaskStatus.inProgress => 'В работе',
      TaskStatus.paused => 'Приостановлена',
      TaskStatus.completed => 'Выполнена',
    };
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }
}
