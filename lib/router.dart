import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/auth_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/task_details_screen.dart';
import 'screens/task_form_screen.dart';
import 'screens/task_history_screen.dart';
import 'screens/task_list_screen.dart';
import 'screens/task_status_screen.dart';
import 'widgets/app_shell.dart';

// One route table for the whole app. Only stable task ids travel in URLs.
final router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const AuthPage(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const AuthPage(isRegistration: true),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/tasks',
              builder: (context, state) => const TaskListPage(),
              routes: [
                // Fixed paths precede :id, so "new" is never parsed as an int.
                GoRoute(
                  path: 'new',
                  builder: (context, state) => const TaskFormPage(),
                ),
                _taskDetailsRoute(':id'),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/history',
              builder: (context, state) => const TaskHistoryPage(),
              routes: [_taskDetailsRoute(':id')],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfilePage(),
            ),
          ],
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Страница не найдена')),
    body: Center(child: Text('Не удалось открыть адрес: ${state.uri.path}')),
  ),
);

GoRoute _taskDetailsRoute(String path) => GoRoute(
  path: path,
  builder: (context, state) =>
      TaskDetailsPage(id: int.parse(state.pathParameters['id']!)),
  routes: [
    GoRoute(
      path: 'edit',
      builder: (context, state) =>
          TaskFormPage(taskId: int.parse(state.pathParameters['id']!)),
    ),
    GoRoute(
      path: 'status',
      builder: (context, state) =>
          TaskStatusPage(id: int.parse(state.pathParameters['id']!)),
    ),
  ],
);
