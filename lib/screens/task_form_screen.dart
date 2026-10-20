import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/task_model.dart';
import '../models/warehouse_task.dart';
import '../utils/task_formatters.dart';

class TaskFormPage extends StatefulWidget {
  const TaskFormPage({super.key, this.taskId});

  final int? taskId;

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
  DateTime? _dueDate;

  bool get _isEditing => widget.taskId != null;

  @override
  void initState() {
    super.initState();
    final task = widget.taskId == null
        ? null
        : context.read<TaskModel>().byId(widget.taskId!);
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController = TextEditingController(
      text: task?.description ?? '',
    );
    _zoneController = TextEditingController(text: task?.zone ?? '');
    _priority = task?.priority ?? TaskPriority.medium;
    _status = task?.status ?? TaskStatus.newTask;
    _dueDate = task?.dueDate;
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
    if (_isEditing && context.watch<TaskModel>().byId(widget.taskId!) == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Задача не найдена')),
        body: Center(child: Text('Задача №${widget.taskId} отсутствует')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Редактирование задачи' : 'Новая задача'),
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
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
              validator: (value) =>
                  _requiredValidator(value, 'Введите название'),
            ),
            const SizedBox(height: 18),
            const _FieldTitle('Описание'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              minLines: 4,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Опишите, что необходимо выполнить',
                alignLabelWithHint: true,
              ),
              validator: (value) =>
                  _requiredValidator(value, 'Введите описание'),
            ),
            const SizedBox(height: 18),
            const _FieldTitle('Зона склада'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _zoneController,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(hintText: 'Например: A-03'),
              validator: (value) =>
                  _requiredValidator(value, 'Выберите зону склада'),
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
              validator: (value) => value == null ? 'Выберите приоритет' : null,
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
              validator: (value) => value == null ? 'Выберите статус' : null,
            ),
            const SizedBox(height: 18),
            const _FieldTitle('Срок выполнения'),
            const SizedBox(height: 8),
            FormField<DateTime>(
              initialValue: _dueDate,
              validator: (value) =>
                  value == null ? 'Выберите срок выполнения' : null,
              builder: (field) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Material(
                    color: const Color(0xFFF7F8FC),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: () => _pickDate(field),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: field.hasError
                                ? Theme.of(context).colorScheme.error
                                : const Color(0xFFE0E5EF),
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month_outlined),
                            const SizedBox(width: 12),
                            Text(
                              field.value == null
                                  ? 'Выберите дату'
                                  : formatTaskDate(field.value!),
                            ),
                            const Spacer(),
                            const Icon(Icons.chevron_right_rounded),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (field.hasError)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 6, 0, 0),
                      child: Text(
                        field.errorText!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
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

  Future<void> _pickDate(FormFieldState<DateTime> field) async {
    final date = await showDatePicker(
      context: context,
      initialDate: field.value ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (date != null && mounted) {
      field.didChange(date);
      setState(() => _dueDate = date);
    }
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEditing
              ? 'Изменения проверены: ${_titleController.text.trim()} (демо)'
              : 'Задача проверена: ${_titleController.text.trim()} (демо)',
        ),
      ),
    );
    context.pop();
  }

  static String? _requiredValidator(String? value, String message) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
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
