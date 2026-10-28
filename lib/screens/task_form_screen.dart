import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/task_model.dart';
import '../models/warehouse_task.dart';
import '../data/result.dart';
import '../data/warehouse_task_repository.dart';
import '../utils/task_formatters.dart';
import '../widgets/task_data_view.dart';

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
  late TaskPriority _priority;
  List<WarehouseLocation>? _locations;
  String? _locationError;
  int? _sourceId;
  int? _destinationId;
  DateTime? _dueDate;
  bool _prefilled = false;
  bool _saving = false;

  bool get _isEditing => widget.taskId != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _priority = TaskPriority.medium;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLocations());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TaskDataView(
      builder: (context, model) => _buildForm(context, model),
    );
  }

  Widget _buildForm(BuildContext context, TaskModel model) {
    if (_locations == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Редактирование задачи' : 'Новая задача'),
        ),
        body: _locationError == null
            ? const Center(child: CircularProgressIndicator())
            : TaskErrorView(message: _locationError!, onRetry: _loadLocations),
      );
    }
    final task = _isEditing ? model.byId(widget.taskId!) : null;
    if (_isEditing && task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Задача не найдена')),
        body: Center(child: Text('Задача №${widget.taskId} отсутствует')),
      );
    }
    if (task != null && !_prefilled) {
      _titleController.text = task.title;
      _descriptionController.text = task.description;
      _priority = task.priority;
      _sourceId = task.sourceLocationId == 0 ? 1 : task.sourceLocationId;
      _destinationId = task.destinationLocationId == 0
          ? 2
          : task.destinationLocationId;
      _dueDate = task.dueDate;
      _prefilled = true;
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
            const _FieldTitle('Точка отправления'),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: _sourceId,
              items: _locations!
                  .map(
                    (location) => DropdownMenuItem(
                      value: location.id,
                      child: Text('${location.name} (${location.zone})'),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _sourceId = value),
              validator: (value) =>
                  value == null ? 'Выберите точку отправления' : null,
            ),
            const SizedBox(height: 18),
            const _FieldTitle('Точка назначения'),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: _destinationId,
              items: _locations!
                  .map(
                    (location) => DropdownMenuItem(
                      value: location.id,
                      child: Text('${location.name} (${location.zone})'),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _destinationId = value),
              validator: (value) => value == null
                  ? 'Выберите точку назначения'
                  : value == _sourceId
                  ? 'Точки должны отличаться'
                  : null,
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
                onPressed: _saving ? null : _save,
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

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final model = context.read<TaskModel>();
    final previous = _isEditing ? model.byId(widget.taskId!) : null;
    final draft = WarehouseTask(
      id: previous?.id ?? 0,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      priority: _priority,
      status: previous?.status ?? TaskStatus.newTask,
      dueDate: _dueDate!,
      zone: _locations!
          .firstWhere((location) => location.id == _destinationId)
          .zone,
      sourceLocationId: _sourceId!,
      destinationLocationId: _destinationId!,
      isFavorite: previous?.isFavorite ?? false,
    );

    setState(() => _saving = true);
    final error = _isEditing
        ? await model.update(draft)
        : await model.add(draft);
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    context.pop();
  }

  static String? _requiredValidator(String? value, String message) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  Future<void> _loadLocations() async {
    if (!mounted) return;
    setState(() {
      _locationError = null;
      _locations = null;
    });
    final result = await context
        .read<WarehouseTaskRepository>()
        .fetchLocations();
    if (!mounted) return;
    setState(() {
      switch (result) {
        case Ok(value: final value):
          _locations = value;
        case Err(msg: final msg):
          _locationError = msg;
      }
    });
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
