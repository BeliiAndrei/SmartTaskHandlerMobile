import 'package:flutter/material.dart';

import '../models/warehouse_task.dart';
import '../widgets/labeled_value_row.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.tasks, required this.onLogout});

  final List<WarehouseTask> tasks;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final completed = tasks
        .where((task) => task.status == TaskStatus.completed)
        .length;
    final active = tasks.length - completed;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE0E5EF)),
          ),
          child: const Column(
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: Color(0xFF3157D5),
                child: Text(
                  'BA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Belii Andrei',
                style: TextStyle(
                  color: Color(0xFF172033),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Сотрудник склада',
                style: TextStyle(color: Color(0xFF697386)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ProfileStat(
                value: active.toString(),
                label: 'Активные',
                icon: Icons.pending_actions_rounded,
                color: const Color(0xFF3157D5),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ProfileStat(
                value: completed.toString(),
                label: 'Выполнено',
                icon: Icons.task_alt_rounded,
                color: const Color(0xFF16A34A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE0E5EF)),
          ),
          child: const Column(
            children: [
              LabeledValueRow(
                icon: Icons.badge_outlined,
                label: 'Логин',
                value: 'belii.andrei',
              ),
              Divider(height: 28),
              LabeledValueRow(
                icon: Icons.warehouse_outlined,
                label: 'Подразделение',
                value: 'Основной склад',
              ),
              Divider(height: 28),
              LabeledValueRow(
                icon: Icons.groups_outlined,
                label: 'Группа',
                value: 'TI-235',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () => _confirmLogout(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
              side: const BorderSide(color: Color(0xFFF1B8B8)),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: const Text(
              'Выйти из аккаунта',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
          title: const Text('Выйти из аккаунта?'),
          content: const Text(
            'Вы вернётесь на страницу авторизации.',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
              ),
              child: const Text('Выйти'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) onLogout();
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E5EF)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF697386), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
