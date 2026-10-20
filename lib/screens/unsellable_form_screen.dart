import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../widgets/unsellable_scope.dart';

class UnsellableFormPage extends StatefulWidget {
  const UnsellableFormPage({super.key, this.pickImage});

  /// Allows a picker substitute in widget tests.
  final Future<XFile?> Function(ImageSource source)? pickImage;

  @override
  State<UnsellableFormPage> createState() => _UnsellableFormPageState();
}

class _UnsellableFormPageState extends State<UnsellableFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _photoFieldKey = GlobalKey<FormFieldState<XFile>>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();
  bool _picking = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid && widget.pickImage == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _recoverLostPhoto());
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _recoverLostPhoto() async {
    try {
      final response = await _picker.retrieveLostData();
      if (!mounted || response.isEmpty) return;
      final files = response.files;
      if (files != null && files.isNotEmpty) {
        _photoFieldKey.currentState?.didChange(files.first);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Фотография восстановлена')),
        );
      }
    } catch (_) {
      // The form remains usable through camera and gallery buttons.
    }
  }

  Future<void> _selectPhoto(
    ImageSource source,
    FormFieldState<XFile> field,
  ) async {
    if (_picking || _saving) return;
    setState(() => _picking = true);
    try {
      final pickImage = widget.pickImage;
      final photo = await (pickImage != null
          ? pickImage(source)
          : _picker.pickImage(
              source: source,
              maxWidth: 1600,
              maxHeight: 1600,
              imageQuality: 85,
            ));
      if (mounted && field.mounted && photo != null) field.didChange(photo);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось получить фотографию')),
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    final photo = _photoFieldKey.currentState?.value;
    if (photo == null) return;

    setState(() => _saving = true);
    try {
      await UnsellableScope.of(context).create(
        title: _titleController.text,
        description: _descriptionController.text,
        sourcePhoto: File(photo.path),
      );
      if (mounted) context.pop(true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось сохранить товар и фото')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Неликвидный товар')),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Название товара'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'Например: повреждённая коробка',
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Введите название товара'
                  : null,
            ),
            const SizedBox(height: 18),
            const Text('Причина / описание'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Опишите повреждение или причину списания',
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Опишите причину'
                  : null,
            ),
            const SizedBox(height: 18),
            const Text('Фотография товара *'),
            const SizedBox(height: 8),
            FormField<XFile>(
              key: _photoFieldKey,
              validator: (photo) =>
                  photo == null ? 'Прикрепите фотографию товара' : null,
              builder: (field) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 190,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F8FC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: field.hasError
                            ? Theme.of(context).colorScheme.error
                            : const Color(0xFFE0E5EF),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: field.value == null
                        ? const Center(
                            child: Icon(
                              Icons.add_a_photo_outlined,
                              size: 52,
                              color: Color(0xFF98A2B3),
                            ),
                          )
                        : Image.file(
                            File(field.value!.path),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(
                                  child: Text('Предпросмотр недоступен'),
                                ),
                          ),
                  ),
                  if (field.errorText != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      field.errorText!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _picking || _saving
                              ? null
                              : () => _selectPhoto(ImageSource.camera, field),
                          icon: const Icon(Icons.photo_camera_outlined),
                          label: const Text('Камера'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _picking || _saving
                              ? null
                              : () => _selectPhoto(ImageSource.gallery, field),
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Галерея'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Сохранение...' : 'Сохранить товар'),
            ),
          ],
        ),
      ),
    );
  }
}
