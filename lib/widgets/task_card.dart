import 'package:flutter/material.dart';

import '../models/warehouse_task.dart';
import '../utils/task_formatters.dart';
import 'favorite_button.dart';
import 'task_badge.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onFavoriteToggle,
    this.showZone = true,
    this.showStatus = true,
    this.showPriority = true,
    this.showDueDate = true,
    this.showChevron = true,
  });

  final WarehouseTask task;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final bool showZone;
  final bool showStatus;
  final bool showPriority;
  final bool showDueDate;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final priorityColor = _priorityColor(task.priority);
    final statusColor = _statusColor(task.status);
    final isOverdue = isTaskOverdue(task);

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
                        if (showZone) ...[
                          const SizedBox(height: 5),
                          Text(
                            'Зона: ${task.zone}',
                            style: const TextStyle(
                              color: Color(0xFF697386),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (onFavoriteToggle != null)
                    FavoriteButton(
                      isFavorite: task.isFavorite,
                      onPressed: onFavoriteToggle!,
                      compact: true,
                    ),
                  if (showChevron)
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF98A2B3),
                    ),
                ],
              ),
              if (showStatus || showPriority) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (showStatus)
                      TaskBadge(
                        text: taskStatusLabel(task.status),
                        color: statusColor,
                      ),
                    if (showStatus && showPriority) const SizedBox(width: 8),
                    if (showPriority)
                      TaskBadge(
                        text: taskPriorityLabel(task.priority),
                        color: priorityColor,
                      ),
                  ],
                ),
              ],
              if (showDueDate) ...[
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
                    Expanded(
                      child: Text(
                        'Срок: ${formatTaskDate(task.dueDate)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isOverdue
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF697386),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isOverdue) ...[
                      const SizedBox(width: 6),
                      const TaskBadge(
                        text: 'Просрочено',
                        color: Color(0xFFDC2626),
                        icon: Icons.warning_amber_rounded,
                      ),
                    ],
                  ],
                ),
              ],
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
}
