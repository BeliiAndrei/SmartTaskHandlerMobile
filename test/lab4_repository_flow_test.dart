import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_task_handler_mobile/data/mock_warehouse_task_repository.dart';
import 'package:smart_task_handler_mobile/main.dart';
import 'package:smart_task_handler_mobile/models/session_model.dart';
import 'package:smart_task_handler_mobile/router.dart';
import 'package:smart_task_handler_mobile/screens/task_form_screen.dart';

import 'support/fake_auth_api.dart';

void main() {
  setUp(() => router.go('/tasks'));

  testWidgets('loading, failure and retry are visible across task screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = MockWarehouseTaskRepository();
    await tester.pumpWidget(
      SmartTaskHandlerApp(
        taskRepository: repository,
        authApi: FakeAuthApi(),
        sessionModel: SessionModel(initialRole: UserRole.user),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(find.text('Собрать заказ №1042'), findsOneWidget);

    await tester.tap(find.text('Профиль'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Симулировать сбой сети'));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Задачи'));
    await tester.pumpAndSettle();
    expect(find.text('Сервер не отвечает — повторите попытку'), findsOneWidget);
    await tester.tap(find.text('Повторить'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(find.text('Сервер не отвечает — повторите попытку'), findsOneWidget);

    await tester.tap(find.text('Профиль'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Симулировать сбой сети'));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Задачи'));
    await tester.pumpAndSettle();
    expect(find.text('Собрать заказ №1042'), findsOneWidget);
  });

  testWidgets('failed form submission keeps the entered data', (tester) async {
    tester.view.physicalSize = const Size(430, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = MockWarehouseTaskRepository();
    await tester.pumpWidget(
      SmartTaskHandlerApp(
        taskRepository: repository,
        authApi: FakeAuthApi(),
        sessionModel: SessionModel(initialRole: UserRole.user),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Новая задача'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Проверить поставку',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Сверить накладную',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'A-01');
    final formScroll = find
        .descendant(
          of: find.byType(TaskFormPage),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('Выберите дату'),
      250,
      scrollable: formScroll,
    );
    await tester.tap(find.text('Выберите дату'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Создать задачу'),
      250,
      scrollable: formScroll,
    );

    repository.simulateError = true;
    await tester.tap(find.text('Создать задачу'));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(find.byType(TaskFormPage), findsOneWidget);
    expect(find.text('Сервер не отвечает — повторите попытку'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller!
          .text,
      'Проверить поставку',
    );
  });

  testWidgets('editing a task updates details and the shared list', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      SmartTaskHandlerApp(
        authApi: FakeAuthApi(),
        sessionModel: SessionModel(initialRole: UserRole.user),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Собрать заказ №1042'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Редактировать задачу'));
    await tester.tap(find.text('Редактировать задачу'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).first,
      'Собрать заказ срочно',
    );
    final formScroll = find
        .descendant(
          of: find.byType(TaskFormPage),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('Сохранить изменения'),
      250,
      scrollable: formScroll,
    );
    await tester.tap(find.text('Сохранить изменения'));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(find.text('Собрать заказ срочно'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Собрать заказ срочно'), findsOneWidget);
  });
}
