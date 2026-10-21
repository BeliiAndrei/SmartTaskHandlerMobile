import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task_model.dart';

/// Renders the repository-backed loading, error, and data states consistently.
class TaskDataView extends StatelessWidget {
  const TaskDataView({super.key, required this.builder});

  final Widget Function(BuildContext context, TaskModel model) builder;

  @override
  Widget build(BuildContext context) {
    final model = context.watch<TaskModel>();
    if (model.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (model.error case final message?) {
      return TaskErrorView(
        message: message,
        onRetry: () => context.read<TaskModel>().load(),
      );
    }
    return builder(context, model);
  }
}

class TaskErrorView extends StatelessWidget {
  const TaskErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Повторить')),
          ],
        ),
      ),
    );
  }
}
