import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/unsellable_report.dart';
import '../utils/task_formatters.dart';
import '../widgets/unsellable_scope.dart';

class UnsellablePage extends StatelessWidget {
  const UnsellablePage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = UnsellableScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Неликвидный товар')),
      body: store.hasLoadError
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Не удалось загрузить записи'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () async {
                      try {
                        await store.load();
                      } catch (_) {
                        // Keep the error visible without replacing stored data.
                      }
                    },
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            )
          : store.reports.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.report_problem_outlined,
                      size: 60,
                      color: Color(0xFF98A2B3),
                    ),
                    SizedBox(height: 12),
                    Text('Неликвидных товаров пока нет'),
                    SizedBox(height: 6),
                    Text(
                      'Добавьте товар и приложите его фотографию',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
              itemCount: store.reports.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final report = store.reports[index];
                return _ReportCard(report: report);
              },
            ),
      floatingActionButton: store.hasLoadError
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                final saved = await context.push<bool>('/unsellable/new');
                if (!context.mounted || saved != true) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Неликвидный товар сохранён')),
                );
              },
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Добавить товар'),
            ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});

  final UnsellableReport report;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => context.push('/unsellable/${report.id}'),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(report.photoPath),
                  width: 86,
                  height: 86,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(
                    width: 86,
                    height: 86,
                    child: Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      report.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      formatTaskDate(report.createdAt.toLocal()),
                      style: const TextStyle(color: Color(0xFF697386)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
