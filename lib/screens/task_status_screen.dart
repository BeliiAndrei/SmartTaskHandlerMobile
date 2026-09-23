import 'package:flutter/material.dart';

import '../models/warehouse_task.dart';

class TaskStatusPage extends StatefulWidget {
  const TaskStatusPage({super.key, required this.currentStatus});

  final TaskStatus currentStatus;

  @override
  State<TaskStatusPage> createState() => _TaskStatusPageState();
}

class _TaskStatusPageState extends State<TaskStatusPage> {
  late TaskStatus _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentStatus;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Изменение статуса')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Выберите новый статус задачи',
            style: TextStyle(
              color: Color(0xFF172033),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Статус будет отображаться в общем списке и истории.',
            style: TextStyle(color: Color(0xFF697386)),
          ),
          const SizedBox(height: 24),
          _StatusOption(
            title: 'Новая',
            subtitle: 'Задача ещё не начата',
            icon: Icons.fiber_new_rounded,
            color: const Color(0xFF3157D5),
            value: TaskStatus.newTask,
            groupValue: _selectedStatus,
            onChanged: _selectStatus,
          ),
          _StatusOption(
            title: 'В работе',
            subtitle: 'Сотрудник выполняет задачу',
            icon: Icons.play_circle_outline_rounded,
            color: const Color(0xFF7C3AED),
            value: TaskStatus.inProgress,
            groupValue: _selectedStatus,
            onChanged: _selectStatus,
          ),
          _StatusOption(
            title: 'Приостановлена',
            subtitle: 'Выполнение временно остановлено',
            icon: Icons.pause_circle_outline_rounded,
            color: const Color(0xFF64748B),
            value: TaskStatus.paused,
            groupValue: _selectedStatus,
            onChanged: _selectStatus,
          ),
          _StatusOption(
            title: 'Выполнена',
            subtitle: 'Задача завершена',
            icon: Icons.check_circle_outline_rounded,
            color: const Color(0xFF16A34A),
            value: TaskStatus.completed,
            groupValue: _selectedStatus,
            onChanged: _selectStatus,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(20),
        child: SizedBox(
          height: 54,
          child: FilledButton(
            onPressed: () => Navigator.pop(context, _selectedStatus),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF3157D5),
            ),
            child: const Text(
              'Сохранить статус',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }

  void _selectStatus(TaskStatus status) {
    setState(() => _selectedStatus = status);
  }
}

class _StatusOption extends StatelessWidget {
  const _StatusOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final TaskStatus value;
  final TaskStatus groupValue;
  final ValueChanged<TaskStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => onChanged(value),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? color : const Color(0xFFE0E5EF),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF697386),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: selected ? color : const Color(0xFF98A2B3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
