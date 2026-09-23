import 'package:flutter/material.dart';

import '../models/warehouse_task.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task, required this.onTap});

  final WarehouseTask task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final priorityColor = _priorityColor(task.priority);
    final statusColor = _statusColor(task.status);
    final isOverdue = _isOverdue(task);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE7EAF0)),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: Color(0xFF3157D5),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF172033),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Зона: ${task.zone}',
                          style: const TextStyle(
                            color: Color(0xFF697386),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF98A2B3),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _TaskBadge(
                    text: _statusText(task.status),
                    color: statusColor,
                  ),
                  const SizedBox(width: 8),
                  _TaskBadge(
                    text: _priorityText(task.priority),
                    color: priorityColor,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    isOverdue
                        ? Icons.warning_amber_rounded
                        : Icons.calendar_today_outlined,
                    size: 16,
                    color: isOverdue
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF697386),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Срок: ${_formatDate(task.dueDate)}',
                    style: TextStyle(
                      color: isOverdue
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF697386),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isOverdue) ...[
                    const Spacer(),
                    const _TaskBadge(
                      text: 'Просрочено',
                      color: Color(0xFFDC2626),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _priorityColor(TaskPriority priority) {
    return switch (priority) {
      TaskPriority.low => const Color(0xFF16A34A),
      TaskPriority.medium => const Color(0xFFF59E0B),
      TaskPriority.high => const Color(0xFFDC2626),
    };
  }

  static Color _statusColor(TaskStatus status) {
    return switch (status) {
      TaskStatus.newTask => const Color(0xFF3157D5),
      TaskStatus.inProgress => const Color(0xFF7C3AED),
      TaskStatus.paused => const Color(0xFF64748B),
      TaskStatus.completed => const Color(0xFF16A34A),
    };
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

  static bool _isOverdue(WarehouseTask task) {
    if (task.status == TaskStatus.completed) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(
      task.dueDate.year,
      task.dueDate.month,
      task.dueDate.day,
    );
    return dueDate.isBefore(today);
  }
}

class _TaskBadge extends StatelessWidget {
  const _TaskBadge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
