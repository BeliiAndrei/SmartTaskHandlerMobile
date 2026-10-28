import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'models/session_model.dart';

import 'screens/auth_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/task_details_screen.dart';
import 'screens/task_form_screen.dart';
import 'screens/task_history_screen.dart';
import 'screens/task_list_screen.dart';
import 'screens/task_status_screen.dart';
import 'screens/unsellable_details_screen.dart';
import 'screens/unsellable_form_screen.dart';
import 'screens/unsellable_screen.dart';
import 'widgets/app_shell.dart';

// Main chooses the initial route after reading the saved JWT. Tests may create
// a fresh router with an explicit initial route.
GoRouter router = createRouter();

GoRouter createRouter({String initialLocation = '/login'}) => GoRouter(
  initialLocation: initialLocation,
  redirect: (context, state) {
    final path = state.uri.path;
    final session = context.read<SessionModel>();
    if (!session.isAuthenticated && path != '/login' && path != '/register') {
      return '/login';
    }
    if ((path == '/history' || path.startsWith('/history/')) &&
        !session.isAdministrator) {
      return '/tasks';
    }
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const AuthPage()),
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
              path: '/favorites',
              builder: (context, state) => const FavoritesPage(),
              routes: [_taskDetailsRoute(':id')],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/unsellable',
              builder: (context, state) => const UnsellablePage(),
              routes: [
                GoRoute(
                  path: 'new',
                  builder: (context, state) => const UnsellableFormPage(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (context, state) =>
                      UnsellableDetailsPage(id: state.pathParameters['id']!),
                ),
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
      _taskPage(state, (id) => TaskDetailsPage(id: id)),
  routes: [
    GoRoute(
      path: 'edit',
      builder: (context, state) =>
          _taskPage(state, (id) => TaskFormPage(taskId: id)),
    ),
    GoRoute(
      path: 'status',
      builder: (context, state) =>
          _taskPage(state, (id) => TaskStatusPage(id: id)),
    ),
  ],
);

Widget _taskPage(GoRouterState state, Widget Function(int id) buildPage) {
  final rawId = state.pathParameters['id'];
  final id = int.tryParse(rawId ?? '');
  if (id == null) {
    return Scaffold(
      appBar: AppBar(title: const Text('Задача не найдена')),
      body: Center(child: Text('Неверный номер задачи: $rawId')),
    );
  }
  return buildPage(id);
}
