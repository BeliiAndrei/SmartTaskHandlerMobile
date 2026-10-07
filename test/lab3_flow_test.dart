import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_task_handler_mobile/data/mock_tasks.dart';
import 'package:smart_task_handler_mobile/main.dart';
import 'package:smart_task_handler_mobile/router.dart';
import 'package:smart_task_handler_mobile/screens/task_form_screen.dart';

void main() {
  testWidgets('L3 login, task route, validation and mock-only submit', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const SmartTaskHandlerApp());
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsNothing);
    await tester.ensureVisible(find.text('Войти'));
    await tester.tap(find.text('Войти'));
    await tester.pumpAndSettle();
    expect(find.text('Введите e-mail'), findsOneWidget);
    expect(find.text('Пароль: минимум 6 символов'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'worker@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'secret1');
    await tester.ensureVisible(find.text('Войти'));
    await tester.tap(find.text('Войти'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Складские задачи'), findsOneWidget);
    expect(find.text('Вход в систему'), findsNothing);
    expect(router.canPop(), isFalse);

    await tester.tap(find.text('Собрать заказ №1042'));
    await tester.pumpAndSettle();
    expect(find.text('Задача №1042'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.ensureVisible(find.text('Редактировать задачу'));
    await tester.tap(find.text('Редактировать задачу'));
    await tester.pumpAndSettle();
    expect(find.text('Редактирование задачи'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller!
          .text,
      'Собрать заказ №1042',
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Изменить статус'));
    await tester.pumpAndSettle();
    expect(find.text('Изменение статуса'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Складские задачи'), findsOneWidget);

    final countBefore = mockTasks.length;
    await tester.tap(find.text('Новая задача'));
    await tester.pumpAndSettle();
    expect(find.byType(TaskFormPage), findsOneWidget);
    final formScroll = find
        .descendant(
          of: find.byType(TaskFormPage),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('Создать задачу'),
      250,
      scrollable: formScroll,
    );
    await tester.tap(find.text('Создать задачу'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Введите название'),
      -250,
      scrollable: formScroll,
    );
    expect(find.text('Введите название'), findsOneWidget);
    expect(find.text('Введите описание'), findsOneWidget);
    expect(find.text('Выберите зону склада'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Выберите срок выполнения'),
      250,
      scrollable: formScroll,
    );
    expect(find.text('Выберите срок выполнения'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byType(TextFormField).first,
      -250,
      scrollable: formScroll,
    );

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Переместить груз',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Взять груз из A и доставить в B',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'A-03');
    await tester.scrollUntilVisible(
      find.text('Выберите дату'),
      -250,
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
    await tester.tap(find.text('Создать задачу'));
    await tester.pumpAndSettle();
    expect(find.text('Складские задачи'), findsOneWidget);
    expect(mockTasks.length, countBefore);
    expect(find.text('Переместить груз'), findsNothing);

    final search = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.hintText == 'Поиск по задачам или зоне',
    );
    await tester.enterText(search, 'поставку');
    await tester.pumpAndSettle();
    expect(find.text('Найдено: 1'), findsOneWidget);
    await tester.tap(find.text('История'));
    await tester.pumpAndSettle();
    expect(find.text('История задач'), findsOneWidget);
    await tester.tap(find.text('Задачи'));
    await tester.pumpAndSettle();
    expect(find.text('Найдено: 1'), findsOneWidget);

    await tester.tap(find.text('Профиль'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Выйти из аккаунта'));
    await tester.pumpAndSettle();
    expect(find.text('Выйти из аккаунта?'), findsOneWidget);
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.tap(find.text('Выйти из аккаунта'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Выйти'));
    await tester.pumpAndSettle();
    expect(find.text('Вход в систему'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
