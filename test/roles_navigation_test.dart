import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_task_handler_mobile/main.dart';
import 'package:smart_task_handler_mobile/router.dart';

void main() {
  testWidgets('history is available only to a local administrator', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    router.go('/login');
    await tester.pumpWidget(const SmartTaskHandlerApp());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'worker@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'secret1');
    await tester.tap(find.text('Войти'));
    await tester.pumpAndSettle();
    expect(find.text('История'), findsNothing);
    expect(find.byType(NavigationDestination), findsNWidgets(4));

    router.go('/history/1041');
    await tester.pumpAndSettle();
    expect(find.text('Складские задачи'), findsOneWidget);
    expect(find.text('Задача №1041'), findsNothing);

    await tester.tap(find.text('Профиль'));
    await tester.pumpAndSettle();
    expect(find.text('Пользователь'), findsOneWidget);
    await tester.tap(find.text('Выйти из аккаунта'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Выйти'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'admin@smarttask.local',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'admin123');
    await tester.tap(find.text('Войти'));
    await tester.pumpAndSettle();
    expect(find.text('История'), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(5));

    router.go('/history/1041');
    await tester.pumpAndSettle();
    expect(find.text('Задача №1041'), findsOneWidget);
  });
}
