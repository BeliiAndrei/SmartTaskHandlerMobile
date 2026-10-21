import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_task_handler_mobile/main.dart';
import 'package:smart_task_handler_mobile/router.dart';

void main() {
  testWidgets('changing status updates the task list and history', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SmartTaskHandlerApp());
    router.go('/tasks');
    await tester.pumpAndSettle();
    expect(find.text('5'), findsOneWidget); // Active task count in AppBar.

    await tester.tap(find.text('Собрать заказ №1042'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Изменить статус'));
    await tester.tap(find.text('Изменить статус'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Выполнена'));
    await tester.tap(find.text('Сохранить статус'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('4'), findsOneWidget);
    await tester.tap(find.text('История'));
    await tester.pumpAndSettle();
    expect(find.text('Собрать заказ №1042'), findsOneWidget);
    expect(find.text('2 выполнено'), findsOneWidget);

    await tester.tap(find.text('Собрать заказ №1042'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Удалить задачу'));
    await tester.tap(find.text('Удалить задачу'));
    await tester.pumpAndSettle();
    expect(find.text('Удалить задачу?'), findsOneWidget);
    await tester.tap(find.text('Удалить'));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(find.text('Собрать заказ №1042'), findsNothing);
    expect(find.text('1 выполнено'), findsOneWidget);
    await tester.tap(find.text('Задачи'));
    await tester.pumpAndSettle();
    expect(find.text('Собрать заказ №1042'), findsNothing);
  });
}
