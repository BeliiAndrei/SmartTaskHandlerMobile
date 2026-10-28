import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/result.dart';
import '../data/warehouse_task_repository.dart';

class TaskStatusHistorySheet extends StatefulWidget {
  const TaskStatusHistorySheet({super.key, required this.taskId});
  final int taskId;

  @override
  State<TaskStatusHistorySheet> createState() => _TaskStatusHistorySheetState();
}

class _TaskStatusHistorySheetState extends State<TaskStatusHistorySheet> {
  late Future<Result<List<TaskHistoryEntry>>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = context.read<WarehouseTaskRepository>().fetchHistory(
      widget.taskId,
    );
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'История статусов',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Flexible(
            child: FutureBuilder<Result<List<TaskHistoryEntry>>>(
              future: _future,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                switch (snapshot.data!) {
                  case Err(msg: final msg):
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(msg),
                        TextButton(
                          onPressed: () => setState(_reload),
                          child: const Text('Повторить'),
                        ),
                      ],
                    );
                  case Ok(value: final entries):
                    if (entries.isEmpty) {
                      return const Text('Изменений пока нет');
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return ListTile(
                          leading: const Icon(Icons.history),
                          title: Text(_label(entry.newStatus)),
                          subtitle: Text(
                            '${entry.changedAt.toLocal()}${entry.comment == null ? '' : '\n${entry.comment}'}',
                          ),
                        );
                      },
                    );
                }
              },
            ),
          ),
        ],
      ),
    ),
  );

  String _label(String status) => switch (status) {
    'new' => 'Новая',
    'in_progress' => 'В работе',
    'paused' => 'Приостановлена',
    'completed' => 'Выполнена',
    _ => status,
  };
}
