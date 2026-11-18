import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/users_api.dart';
import '../state/admin_users_providers.dart';

class AdminUsersPage extends ConsumerWidget {
  const AdminUsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(adminUsersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Зарегистрированные пользователи')),
      body: users.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  error is UsersApiException
                      ? error.message
                      : 'Не удалось загрузить пользователей',
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(adminUsersProvider),
                  child: const Text('Повторить'),
                ),
              ],
            ),
          ),
        ),
        data: (items) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(adminUsersProvider);
            await ref.read(adminUsersProvider.future);
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: items.isEmpty ? 1 : items.length,
            itemBuilder: (context, index) {
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('Других пользователей пока нет')),
                );
              }
              final user = items[index];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person_outline),
                  ),
                  title: Text(user.name),
                  subtitle: Text(
                    '${user.email}\nID: ${user.id} · Зарегистрирован: ${_date(user.createdAt)}',
                  ),
                  isThreeLine: true,
                  trailing: Text(
                    user.role == 'administrator'
                        ? 'Администратор'
                        : 'Пользователь',
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _date(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}.'
        '${local.month.toString().padLeft(2, '0')}.${local.year}';
  }
}
