import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/task_model.dart';
import '../utils/task_formatters.dart';
import '../widgets/favorite_actions.dart';
import '../widgets/favorites_scope.dart';
import '../widgets/favorite_button.dart';
import '../widgets/labeled_value_row.dart';
import '../widgets/task_data_view.dart';
import '../data/result.dart';
import '../data/warehouse_task_repository.dart';
import 'task_status_history_sheet.dart';

class TaskDetailsPage extends StatefulWidget {
  const TaskDetailsPage({super.key, required this.id});

  final int id;

  @override
  State<TaskDetailsPage> createState() => _TaskDetailsPageState();
}

class _TaskDetailsPageState extends State<TaskDetailsPage> {
  bool _loading = true;
  String? _detailError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _detailError = null;
    });
    final error = await context.read<TaskModel>().refreshById(widget.id);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _detailError = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_detailError case final message?) {
      return Scaffold(
        appBar: AppBar(title: const Text('Задача')),
        body: TaskErrorView(message: message, onRetry: _refresh),
      );
    }
    return TaskDataView(
      builder: (context, model) => _buildDetails(context, model),
    );
  }

  Widget _buildDetails(BuildContext context, TaskModel model) {
    final task = model.byId(widget.id);
    if (task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Задача не найдена')),
        body: Center(child: Text('Задача №${widget.id} отсутствует')),
      );
    }
    final favorites = FavoritesScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Задача №${task.id}'),
        actions: [
          FavoriteButton(
            isFavorite: favorites.contains(task.id),
            onPressed: () => toggleFavoriteWithFeedback(context, task.id),
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
                task.sourceLocationId == 0
                    ? LabeledValueRow(
                        icon: Icons.warehouse_outlined,
                        label: 'Зона склада',
                        value: task.zone,
                      )
                    : _LocationRows(
                        sourceId: task.sourceLocationId,
                        destinationId: task.destinationLocationId,
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
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => TaskStatusHistorySheet(taskId: task.id),
              ),
              icon: const Icon(Icons.history),
              label: const Text('История статусов'),
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
          const SizedBox(height: 12),
          SizedBox(
            height: 54,
            child: OutlinedButton.icon(
              onPressed: () => _deleteTask(context, task.id),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Удалить задачу'),
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

  Future<void> _deleteTask(BuildContext context, int taskId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удалить задачу?'),
        content: const Text('Задача исчезнет из списка и истории.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final error = await context.read<TaskModel>().remove(taskId);
    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    context.pop();
  }
}

class _LocationRows extends StatefulWidget {
  const _LocationRows({required this.sourceId, required this.destinationId});
  final int sourceId;
  final int destinationId;

  @override
  State<_LocationRows> createState() => _LocationRowsState();
}

class _LocationRowsState extends State<_LocationRows> {
  late final Future<Result<List<WarehouseLocation>>> _locations;

  @override
  void initState() {
    super.initState();
    _locations = context.read<WarehouseTaskRepository>().fetchLocations();
  }

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<Result<List<WarehouseLocation>>>(
        future: _locations,
        builder: (context, snapshot) {
          final locations = switch (snapshot.data) {
            Ok<List<WarehouseLocation>>(value: final items) => items,
            _ => <WarehouseLocation>[],
          };
          String name(int id) {
            for (final location in locations) {
              if (location.id == id) {
                return '${location.name} (${location.zone})';
              }
            }
            return 'Точка №$id';
          }

          return Column(
            children: [
              LabeledValueRow(
                icon: Icons.move_up_outlined,
                label: 'Откуда',
                value: name(widget.sourceId),
              ),
              const Divider(height: 28),
              LabeledValueRow(
                icon: Icons.place_outlined,
                label: 'Куда',
                value: name(widget.destinationId),
              ),
            ],
          );
        },
      );
}
