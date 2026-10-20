import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_task_handler_mobile/screens/unsellable_form_screen.dart';
import 'package:smart_task_handler_mobile/services/unsellable_repository.dart';
import 'package:smart_task_handler_mobile/services/unsellable_store.dart';
import 'package:smart_task_handler_mobile/widgets/unsellable_scope.dart';

void main() {
  late Directory directory;
  late UnsellableRepository repository;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('smart_task_unsellable_');
    repository = UnsellableRepository(directoryProvider: () async => directory);
  });

  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test('photo is copied into app storage and report survives reload', () async {
    final source = File('${directory.path}${Platform.pathSeparator}source.jpg');
    await source.writeAsBytes([1, 2, 3, 4]);

    final report = await repository.create(
      title: '  Повреждённая коробка  ',
      description: '  Порвана упаковка  ',
      sourcePhoto: source,
    );
    expect(report.title, 'Повреждённая коробка');
    expect(report.description, 'Порвана упаковка');
    expect(report.photoPath, isNot(source.path));
    expect(await File(report.photoPath).readAsBytes(), [1, 2, 3, 4]);
    expect(await source.exists(), isTrue);

    final index = File(
      '${directory.path}${Platform.pathSeparator}${UnsellableRepository.fileName}',
    );
    final json = jsonDecode(await index.readAsString()) as Map<String, dynamic>;
    expect((json['reports'] as List).length, 1);
    expect(
      (json['reports'] as List).first['photoFileName'],
      report.photoFileName,
    );

    final restored = await UnsellableRepository(
      directoryProvider: () async => directory,
    ).load();
    expect(restored, hasLength(1));
    expect(restored.single.id, report.id);
    expect(restored.single.photoPath, report.photoPath);
  });

  test('missing photo and corrupted JSON do not create a record', () async {
    final missing = File(
      '${directory.path}${Platform.pathSeparator}missing.jpg',
    );
    await expectLater(
      repository.create(
        title: 'Товар',
        description: 'Причина',
        sourcePhoto: missing,
      ),
      throwsA(isA<FileSystemException>()),
    );

    final source = File('${directory.path}${Platform.pathSeparator}source.jpg');
    await source.writeAsBytes([1, 2, 3]);
    final index = File(
      '${directory.path}${Platform.pathSeparator}${UnsellableRepository.fileName}',
    );
    await index.writeAsString('{bad json');
    await expectLater(
      repository.create(
        title: 'Товар',
        description: 'Причина',
        sourcePhoto: source,
      ),
      throwsFormatException,
    );
    expect(await index.readAsString(), '{bad json');
  });

  testWidgets('form requires a photo and opens the gallery picker', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = UnsellableStore(repository);
    ImageSource? selectedSource;

    await tester.pumpWidget(
      UnsellableScope(
        store: store,
        child: MaterialApp(
          home: UnsellableFormPage(
            pickImage: (sourceType) async {
              selectedSource = sourceType;
              return null;
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('Сохранить товар'));
    await tester.pump();
    expect(find.text('Введите название товара'), findsOneWidget);
    expect(find.text('Опишите причину'), findsOneWidget);
    expect(find.text('Прикрепите фотографию товара'), findsOneWidget);

    await tester.ensureVisible(find.text('Галерея'));
    await tester.tap(find.text('Галерея'));
    await tester.pumpAndSettle();
    expect(selectedSource, ImageSource.gallery);
    expect(find.text('Прикрепите фотографию товара'), findsOneWidget);

    await tester.tap(find.text('Камера'));
    await tester.pumpAndSettle();
    expect(selectedSource, ImageSource.camera);
    expect(find.text('Прикрепите фотографию товара'), findsOneWidget);
  });
}
