import 'package:flutter/material.dart';

import '../models/warehouse_task.dart';

class TaskFormPage extends StatefulWidget {
  const TaskFormPage({super.key, required this.taskId, this.task});

  final int taskId;
  final WarehouseTask? task;

  @override
  State<TaskFormPage> createState() => _TaskFormPageState();
}

class _TaskFormPageState extends State<TaskFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _zoneController;
  late TaskPriority _priority;
  late TaskStatus _status;
  late DateTime _dueDate;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController = TextEditingController(
      text: task?.description ?? '',
    );
    _zoneController = TextEditingController(text: task?.zone ?? '');
    _priority = task?.priority ?? TaskPriority.medium;
    _status = task?.status ?? TaskStatus.newTask;
    _dueDate = task?.dueDate ?? DateTime(2026, 9, 17);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _zoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Редактирование задачи' : 'Новая задача'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const _FieldTitle('Название'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'Например: принять поставку',
              ),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 18),
            const _FieldTitle('Описание'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              minLines: 4,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Опишите, что необходимо выполнить',
                alignLabelWithHint: true,
              ),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 18),
            const _FieldTitle('Зона склада'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _zoneController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(hintText: 'Например: A-03'),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 18),
            const _FieldTitle('Приоритет'),
            const SizedBox(height: 8),
            DropdownButtonFormField<TaskPriority>(
              initialValue: _priority,
              items: const [
                DropdownMenuItem(
                  value: TaskPriority.low,
                  child: Text('Низкий'),
                ),
                DropdownMenuItem(
                  value: TaskPriority.medium,
                  child: Text('Средний'),
                ),
                DropdownMenuItem(
                  value: TaskPriority.high,
                  child: Text('Высокий'),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _priority = value);
              },
            ),
            const SizedBox(height: 18),
            const _FieldTitle('Статус'),
            const SizedBox(height: 8),
            DropdownButtonFormField<TaskStatus>(
              initialValue: _status,
              items: const [
                DropdownMenuItem(
                  value: TaskStatus.newTask,
                  child: Text('Новая'),
                ),
                DropdownMenuItem(
                  value: TaskStatus.inProgress,
                  child: Text('В работе'),
                ),
                DropdownMenuItem(
                  value: TaskStatus.paused,
                  child: Text('Приостановлена'),
                ),
                DropdownMenuItem(
                  value: TaskStatus.completed,
                  child: Text('Выполнена'),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _status = value);
              },
            ),
            const SizedBox(height: 18),
            const _FieldTitle('Срок выполнения'),
            const SizedBox(height: 8),
            Material(
              color: const Color(0xFFF7F8FC),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE0E5EF)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_outlined,
                        color: Color(0xFF697386),
                      ),
                      const SizedBox(width: 12),
                      Text(_formatDate(_dueDate)),
                      const Spacer(),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF3157D5),
                ),
                child: Text(
                  _isEditing ? 'Сохранить изменения' : 'Создать задачу',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (date != null) setState(() => _dueDate = date);
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.pop(
      context,
      WarehouseTask(
        id: widget.taskId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _priority,
        status: _status,
        dueDate: _dueDate,
        zone: _zoneController.text.trim(),
      ),
    );
  }

  static String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Заполните поле';
    return null;
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }
}

class _FieldTitle extends StatelessWidget {
  const _FieldTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF374151),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
