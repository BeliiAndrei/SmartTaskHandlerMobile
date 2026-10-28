import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/auth_api.dart';
import '../models/task_model.dart';
import '../models/session_model.dart';
import '../widgets/labeled_value_row.dart';
import '../widgets/task_data_view.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final role = context.watch<SessionModel>().role;
    final auth = context.read<AuthApi>();

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
          child: Column(
            children: [
              const CircleAvatar(
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
              const SizedBox(height: 16),
              Text(
                auth.profileName ?? 'Пользователь',
                style: TextStyle(
                  color: Color(0xFF172033),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Сотрудник склада',
                style: TextStyle(color: Color(0xFF697386)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TaskDataView(
          builder: (context, model) => Row(
            children: [
              Expanded(
                child: _ProfileStat(
                  value: model.activeCount.toString(),
                  label: 'Активные',
                  icon: Icons.pending_actions_rounded,
                  color: const Color(0xFF3157D5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ProfileStat(
                  value: model.completedCount.toString(),
                  label: 'Выполнено',
                  icon: Icons.task_alt_rounded,
                  color: const Color(0xFF16A34A),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE0E5EF)),
          ),
          child: Column(
            children: [
              LabeledValueRow(
                icon: Icons.badge_outlined,
                label: 'Email',
                value: auth.profileEmail ?? '—',
              ),
              const Divider(height: 28),
              const LabeledValueRow(
                icon: Icons.warehouse_outlined,
                label: 'Подразделение',
                value: 'Основной склад',
              ),
              const Divider(height: 28),
              const LabeledValueRow(
                icon: Icons.groups_outlined,
                label: 'Группа',
                value: 'TI-235',
              ),
              const Divider(height: 28),
              LabeledValueRow(
                icon: Icons.admin_panel_settings_outlined,
                label: 'Роль',
                value: role == UserRole.administrator
                    ? 'Администратор'
                    : 'Пользователь',
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

    if (confirmed == true && context.mounted) {
      await context.read<AuthApi>().logout();
      if (!context.mounted) return;
      context.read<SessionModel>().signOut();
      context.read<TaskModel>().clear();
      context.go('/login');
    }
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
