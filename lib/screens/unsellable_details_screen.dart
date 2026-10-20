import 'dart:io';

import 'package:flutter/material.dart';

import '../utils/task_formatters.dart';
import '../widgets/unsellable_scope.dart';

class UnsellableDetailsPage extends StatelessWidget {
  const UnsellableDetailsPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final report = UnsellableScope.of(context).find(id);
    if (report == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Запись не найдена')),
        body: const Center(child: Text('Неликвидный товар не найден')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Неликвидный товар')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.file(
              File(report.photoPath),
              height: 300,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const SizedBox(
                height: 300,
                child: Center(child: Text('Фотография недоступна')),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            report.title,
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text(report.description, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 18),
          Text(
            'Добавлено: ${formatTaskDate(report.createdAt.toLocal())}',
            style: const TextStyle(color: Color(0xFF697386)),
          ),
        ],
      ),
    );
  }
}
