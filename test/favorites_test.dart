import 'support/mock_warehouse_task_repository.dart';

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_task_handler_mobile/main.dart';
import 'package:smart_task_handler_mobile/models/task_model.dart';
import 'package:smart_task_handler_mobile/models/warehouse_task.dart';
import 'package:smart_task_handler_mobile/router.dart';
import 'package:smart_task_handler_mobile/services/favorite_repository.dart';
import 'package:smart_task_handler_mobile/services/favorite_store.dart';
import 'package:smart_task_handler_mobile/widgets/favorite_button.dart';
import 'package:smart_task_handler_mobile/widgets/task_card.dart';

import 'support/fake_auth_api.dart';

void main() {
  late Directory directory;
  late FavoriteRepository repository;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('smart_task_favorites_');
    repository = FavoriteRepository(directoryProvider: () async => directory);
  });

  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test('JSON stores ids and a new store restores them', () async {
    final favorites = FavoriteStore(repository);
    await favorites.load();
    expect(favorites.contains(1042), isFalse);

    expect(await favorites.toggle(1043), isTrue);
    expect(await favorites.toggle(1042), isTrue);
    final file = File(
      '${directory.path}${Platform.pathSeparator}${FavoriteRepository.fileName}',
    );
    expect(
      await file.readAsString(),
      contains('"taskIds": [\n    1042,\n    1043'),
    );

    final restored = FavoriteStore(repository);
    await restored.load();
    expect(restored.contains(1042), isTrue);
    expect(restored.contains(1043), isTrue);
    expect(await restored.toggle(1042), isFalse);

    final restoredAgain = FavoriteStore(repository);
    await restoredAgain.load();
    expect(restoredAgain.contains(1042), isFalse);
    expect(restoredAgain.contains(1043), isTrue);
  });

  test('bad JSON is not overwritten by a toggle', () async {
    final file = File(
      '${directory.path}${Platform.pathSeparator}${FavoriteRepository.fileName}',
    );
    await file.writeAsString('{bad json');
    final favorites = FavoriteStore(repository);
    await expectLater(favorites.load(), throwsFormatException);
    expect(favorites.hasLoadError, isTrue);
    await expectLater(favorites.toggle(1042), throwsStateError);
    expect(await file.readAsString(), '{bad json');
  });

  testWidgets('favorite appears in list, details and favorites tab', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final memoryRepository = _MemoryFavoriteRepository();
    final favorites = FavoriteStore(memoryRepository);
    await favorites.load();
    router.go('/login');
    await tester.pumpWidget(
      SmartTaskHandlerApp(
        taskRepository: MockWarehouseTaskRepository(),
        favoriteStore: favorites,
        authApi: FakeAuthApi(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'worker@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'secret1');
    await tester.ensureVisible(find.text('Войти'));
    await tester.tap(find.text('Войти'));
    await tester.pumpAndSettle();

    final firstCard = find.byType(TaskCard).first;
    final star = find.descendant(
      of: firstCard,
      matching: find.byType(FavoriteButton),
    );
    await tester.tap(star);
    await tester.pumpAndSettle();
    expect(favorites.contains(1042), isTrue);

    final restored = FavoriteStore(memoryRepository);
    await restored.load();
    expect(restored.contains(1042), isTrue);

    await tester.tap(find.text('Избранное'));
    await tester.pumpAndSettle();
    expect(find.text('Собрать заказ №1042'), findsOneWidget);
    final taskModel = Provider.of<TaskModel>(
      tester.element(find.byType(TaskCard).first),
      listen: false,
    );
    final statusUpdate = taskModel.updateStatus(1042, TaskStatus.completed);
    await tester.pump(const Duration(milliseconds: 800));
    await statusUpdate;
    await tester.pumpAndSettle();
    expect(find.text('Выполнена'), findsOneWidget);
    await tester.tap(find.text('Собрать заказ №1042'));
    await tester.pumpAndSettle();
    expect(find.text('Задача №1042'), findsOneWidget);
    await tester.tap(find.byTooltip('Убрать из избранного'));
    await tester.pumpAndSettle();
    expect(favorites.contains(1042), isFalse);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Пока нет избранных задач'), findsOneWidget);

    await tester.tap(find.text('Задачи'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(TaskCard).first,
        matching: find.byType(FavoriteButton),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Избранное'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(TaskCard).first,
        matching: find.byType(FavoriteButton),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Пока нет избранных задач'), findsOneWidget);
    expect(find.text('Удалено из избранного'), findsOneWidget);

    final restoredAgain = FavoriteStore(memoryRepository);
    await restoredAgain.load();
    expect(restoredAgain.contains(1042), isFalse);
  });
}

class _MemoryFavoriteRepository extends FavoriteRepository {
  Set<int> ids = <int>{};

  @override
  Future<Set<int>> readIds() async => Set<int>.of(ids);

  @override
  Future<void> writeIds(Set<int> next) async {
    ids = Set<int>.of(next);
  }
}
