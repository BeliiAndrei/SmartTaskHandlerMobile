import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/task_model.dart';
import '../models/warehouse_task.dart';
import '../data/result.dart';
import '../data/warehouse_task_repository.dart';
import 'qr_scan_screen.dart';
import '../widgets/task_data_view.dart';

class TaskStatusPage extends StatefulWidget {
  const TaskStatusPage({super.key, required this.id});

  final int id;

  @override
  State<TaskStatusPage> createState() => _TaskStatusPageState();
}

class _TaskStatusPageState extends State<TaskStatusPage> {
  TaskStatus? _selectedStatus;
  bool _saving = false;
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    return TaskDataView(
      builder: (context, model) => _buildStatus(context, model),
    );
  }

  Widget _buildStatus(BuildContext context, TaskModel model) {
    final task = model.byId(widget.id);
    if (task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Задача не найдена')),
        body: Center(child: Text('Задача №${widget.id} отсутствует')),
      );
    }
    _selectedStatus ??= task.status;
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
            'Изменение статуса сразу появится в списке и истории.',
            style: TextStyle(color: Color(0xFF697386)),
          ),
          const SizedBox(height: 24),
          _StatusOption(
            title: 'Новая',
            subtitle: 'Задача ещё не начата',
            icon: Icons.fiber_new_rounded,
            color: const Color(0xFF3157D5),
            value: TaskStatus.newTask,
            groupValue: _selectedStatus!,
            onChanged: _selectStatus,
          ),
          if (_selectedStatus == TaskStatus.completed &&
              task.status != TaskStatus.completed) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _saving ? null : () => _scan(task),
              icon: const Icon(Icons.qr_code_scanner),
              label: Text(
                _confirmed
                    ? 'Точка подтверждена'
                    : 'Сканировать QR точки назначения',
              ),
            ),
          ],
          _StatusOption(
            title: 'В работе',
            subtitle: 'Сотрудник выполняет задачу',
            icon: Icons.play_circle_outline_rounded,
            color: const Color(0xFF7C3AED),
            value: TaskStatus.inProgress,
            groupValue: _selectedStatus!,
            onChanged: _selectStatus,
          ),
          _StatusOption(
            title: 'Приостановлена',
            subtitle: 'Выполнение временно остановлено',
            icon: Icons.pause_circle_outline_rounded,
            color: const Color(0xFF64748B),
            value: TaskStatus.paused,
            groupValue: _selectedStatus!,
            onChanged: _selectStatus,
          ),
          _StatusOption(
            title: 'Выполнена',
            subtitle: 'Задача завершена',
            icon: Icons.check_circle_outline_rounded,
            color: const Color(0xFF16A34A),
            value: TaskStatus.completed,
            groupValue: _selectedStatus!,
            onChanged: _selectStatus,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(20),
        child: SizedBox(
          height: 54,
          child: FilledButton(
            onPressed:
                _saving ||
                    (_selectedStatus == TaskStatus.completed &&
                        task.status != TaskStatus.completed &&
                        !_confirmed)
                ? null
                : _save,
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
    setState(() {
      _selectedStatus = status;
      if (status != TaskStatus.completed) _confirmed = false;
    });
  }

  Future<void> _scan(WarehouseTask task) async {
    final scanned = await Navigator.of(context)
        .push<String>(MaterialPageRoute(builder: (_) => const QrScanPage()));
    if (!mounted || scanned == null) return;
    final destination = await context
        .read<WarehouseTaskRepository>()
        .fetchLocation(task.destinationLocationId);
    if (!mounted) return;
    switch (destination) {
      case Err(msg: final msg):
        _message(msg);
        return;
      case Ok(value: final value):
        if (value.qrCodeValue != scanned) {
          _message('QR-код не соответствует точке назначения');
          return;
        }
    }
    setState(() => _saving = true);
    final error = await context.read<TaskModel>().confirmDestination(
      task.id,
      scanned,
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      _confirmed = error == null;
    });
    _message(error ?? 'Точка назначения подтверждена');
  }

  void _message(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  Future<void> _save() async {
    setState(() => _saving = true);
    final error = await context.read<TaskModel>().updateStatus(
      widget.id,
      _selectedStatus!,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Статус задачи обновлён')));
    context.pop();
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
