import 'package:flutter_test/flutter_test.dart';
import 'package:smart_task_handler_mobile/data/mock_warehouse_task_repository.dart';
import 'package:smart_task_handler_mobile/models/task_model.dart';
import 'package:smart_task_handler_mobile/models/warehouse_task.dart';

void main() {
  test(
    'TaskModel exposes loading, error, retry and repository mutations',
    () async {
      final repository = MockWarehouseTaskRepository()..simulateError = true;
      final model = TaskModel(repository);
      addTearDown(model.dispose);
      var notifications = 0;
      model.addListener(() => notifications++);

      final failedLoad = model.load();
      expect(model.isLoading, isTrue);
      await failedLoad;
      expect(model.isLoading, isFalse);
      expect(model.error, 'Сервер не отвечает — повторите попытку');
      expect(model.tasks, isEmpty);

      repository.simulateError = false;
      await model.load();
      expect(model.error, isNull);
      expect(model.tasks, isNotEmpty);
      expect(() => model.tasks.clear(), throwsUnsupportedError);

      final draft = model.tasks.first.copyWith(id: 0, title: 'Новая задача');
      final oldCount = model.tasks.length;
      expect(await model.add(draft), isNull);
      final created = model.tasks.last;
      expect(model.tasks.length, oldCount + 1);
      expect(created.id, isNot(0));

      repository.simulateError = true;
      expect(
        await model.update(created.copyWith(title: 'Не сохранено')),
        'Сервер не отвечает — повторите попытку',
      );
      expect(model.byId(created.id)!.title, 'Новая задача');
      repository.simulateError = false;

      expect(
        await model.updateStatus(created.id, TaskStatus.completed),
        isNull,
      );
      expect(model.byId(created.id)!.status, TaskStatus.completed);
      expect(await model.remove(created.id), isNull);
      expect(model.byId(created.id), isNull);
      expect(notifications, greaterThanOrEqualTo(7));
    },
  );
}
