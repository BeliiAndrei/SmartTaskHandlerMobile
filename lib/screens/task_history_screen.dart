import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_tasks.dart';
import '../models/warehouse_task.dart';
import '../services/task_logic.dart';
import '../widgets/task_card.dart';

class TaskHistoryPage extends StatelessWidget {
  const TaskHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final completedTasks = TaskLogic.completedTasks(mockTasks);

    return Scaffold(
      appBar: AppBar(title: const Text('История задач')),
      body: _historyBody(context, completedTasks),
    );
  }

  Widget _historyBody(
    BuildContext context,
    List<WarehouseTask> completedTasks,
  ) {
    if (completedTasks.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.history_toggle_off_rounded,
                size: 62,
                color: Color(0xFF98A2B3),
              ),
              SizedBox(height: 14),
              Text(
                'История пока пуста',
                style: TextStyle(
                  color: Color(0xFF374151),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Выполненные задачи появятся здесь',
                style: TextStyle(color: Color(0xFF697386)),
              ),
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
            onTap: () => context.push('/history/${task.id}'),
            showPriority: false,
            showDueDate: false,
            showChevron: false,
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
