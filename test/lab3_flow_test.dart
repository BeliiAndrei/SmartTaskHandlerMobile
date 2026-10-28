import 'support/mock_warehouse_task_repository.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_task_handler_mobile/main.dart';
import 'package:smart_task_handler_mobile/models/task_model.dart';
import 'package:smart_task_handler_mobile/models/session_model.dart';
import 'package:smart_task_handler_mobile/router.dart';
import 'package:smart_task_handler_mobile/screens/task_form_screen.dart';
import 'package:smart_task_handler_mobile/screens/task_list_screen.dart';

import 'support/fake_auth_api.dart';

void main() {
  testWidgets('L3 login and validation with L4 repository submit', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    router.go('/login');
    await tester.pumpWidget(
      SmartTaskHandlerApp(
        taskRepository: MockWarehouseTaskRepository(),
        authApi: FakeAuthApi(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsNothing);
    await tester.ensureVisible(find.text('Войти'));
    await tester.tap(find.text('Войти'));
    await tester.pumpAndSettle();
    expect(find.text('Введите e-mail'), findsOneWidget);
    expect(find.text('Пароль: минимум 6 символов'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'admin@smarttask.local',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'admin123');
    await tester.ensureVisible(find.text('Войти'));
    await tester.tap(find.text('Войти'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Складские задачи'), findsOneWidget);
    expect(find.text('Вход в систему'), findsNothing);
    expect(router.canPop(), isFalse);

    Provider.of<SessionModel>(
      tester.element(find.byType(TaskListPage)),
      listen: false,
    ).signIn(role: UserRole.administrator);
    await tester.pumpAndSettle();

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
    await tester.tap(find.text('Приостановлена'));
    await tester.tap(find.text('Сохранить статус'));
    await tester.pumpAndSettle();
    expect(find.text('Задача №1042'), findsOneWidget);
    expect(find.text('Статус задачи обновлён'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Складские задачи'), findsOneWidget);

    final taskModel = Provider.of<TaskModel>(
      tester.element(find.byType(TaskListPage)),
      listen: false,
    );
    final countBefore = taskModel.tasks.length;
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
    expect(find.text('Выберите точку отправления'), findsOneWidget);
    expect(find.text('Выберите точку назначения'), findsOneWidget);
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
    await tester.tap(find.byType(DropdownButtonFormField<int>).at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Приёмка A (A-01)').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<int>).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Отгрузка B (B-01)').last);
    await tester.pumpAndSettle();
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
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(find.text('Складские задачи'), findsOneWidget);
    expect(taskModel.tasks.length, countBefore + 1);
    expect(taskModel.tasks.first.title, 'Переместить груз');

    final search = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.hintText == 'Поиск по задачам или зоне',
    );
    await tester.enterText(search, 'поставку');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 800));
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

    await tester.tap(find.text('Регистрация'));
    await tester.pumpAndSettle();
    expect(find.text('Регистрация сотрудника'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'worker@invalid');
    await tester.enterText(find.byType(TextFormField).at(2), 'secret1');
    await tester.enterText(find.byType(TextFormField).at(3), 'different');
    await tester.ensureVisible(find.text('Зарегистрироваться'));
    await tester.tap(find.text('Зарегистрироваться'));
    await tester.pumpAndSettle();
    expect(find.text('Введите корректный e-mail'), findsOneWidget);
    expect(find.text('Введите имя'), findsOneWidget);
    expect(find.text('Пароли не совпадают'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'worker@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'Работник');
    await tester.enterText(find.byType(TextFormField).at(3), 'secret1');
    await tester.ensureVisible(find.text('Зарегистрироваться'));
    await tester.tap(find.text('Зарегистрироваться'));
    await tester.pumpAndSettle();
    expect(find.text('Складские задачи'), findsOneWidget);
    expect(router.canPop(), isFalse);

    router.go('/tasks/not-a-number');
    await tester.pumpAndSettle();
    expect(find.text('Неверный номер задачи: not-a-number'), findsOneWidget);
    router.go('/tasks/999999');
    await tester.pumpAndSettle();
    expect(find.text('Задача не существует'), findsOneWidget);
    router.go('/history/1041');
    await tester.pumpAndSettle();
    expect(find.text('Складские задачи'), findsOneWidget);
    expect(find.text('История'), findsNothing);
  });
}
