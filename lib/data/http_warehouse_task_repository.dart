import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/warehouse_task.dart';
import 'api_message.dart';
import 'result.dart';
import 'token_store.dart';
import 'warehouse_task_repository.dart';

class HttpWarehouseTaskRepository implements WarehouseTaskRepository {
  HttpWarehouseTaskRepository(
    this.baseUrl,
    this.tokens, {
    required this.onUnauthorized,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final TokenStore tokens;
  final void Function() onUnauthorized;
  final http.Client _client;
  static const _timeout = Duration(seconds: 8);

  Future<Result<T>> _send<T>(
    String method,
    String path,
    T Function(http.Response) parse, {
    Object? body,
  }) async {
    try {
      final token = await tokens.read();
      final request = http.Request(method, Uri.parse('$baseUrl$path'));
      request.headers['Authorization'] = 'Bearer ${token ?? ''}';
      if (body != null) {
        request.headers['Content-Type'] = 'application/json';
        request.body = jsonEncode(body);
      }
      final streamed = await _client.send(request).timeout(_timeout);
      final response = await http.Response.fromStream(streamed)
          .timeout(_timeout);
      if (response.statusCode == 401) {
        if (token != null && await tokens.read() == token) {
          await tokens.clear();
          onUnauthorized();
        }
        return Err(apiMessage(response));
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return Err(apiMessage(response));
      }
      return Ok(parse(response));
    } on SocketException {
      return const Err('Нет сети — повторите попытку');
    } on http.ClientException {
      return const Err('Нет сети — повторите попытку');
    } on TimeoutException {
      return const Err('Сервер не отвечает');
    } on FormatException {
      return const Err('Ответ не тот, что обещан');
    } on TypeError {
      return const Err('Ответ не тот, что обещан');
    }
  }

  static Map<String, dynamic> _object(http.Response response) =>
      jsonDecode(response.body) as Map<String, dynamic>;

  static void _noContent(http.Response response) {}

  @override
  Future<Result<List<WarehouseTask>>> fetchAll({
    int page = 1,
    int limit = 20,
    String? search,
  }) {
    final uri = Uri.parse('$baseUrl/tasks').replace(
      queryParameters: {
        'page': '$page',
        'limit': '$limit',
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return _send('GET', uri.toString().substring(baseUrl.length), (response) {
      final items = _object(response)['items'] as List<dynamic>;
      return items
          .map((item) => WarehouseTask.fromJson(item as Map<String, dynamic>))
          .toList();
    });
  }

  @override
  Future<Result<WarehouseTask>> fetchById(int id) => _send(
    'GET',
    '/tasks/$id',
    (response) => WarehouseTask.fromJson(_object(response)),
  );

  @override
  Future<Result<WarehouseTask>> create(WarehouseTask task) => _send(
    'POST',
    '/tasks',
    (response) => WarehouseTask.fromJson(_object(response)),
    body: task.toJson(),
  );

  @override
  Future<Result<WarehouseTask>> update(WarehouseTask task) => _send(
    'PUT',
    '/tasks/${task.id}',
    (response) => WarehouseTask.fromJson(_object(response)),
    body: task.toJson(),
  );

  @override
  Future<Result<void>> delete(int id) =>
      _send('DELETE', '/tasks/$id', _noContent);

  @override
  Future<Result<WarehouseTask>> changeStatus(
    WarehouseTask task,
    TaskStatus status, {
    String? comment,
  }) => _send(
    'PATCH',
    '/tasks/${task.id}/status',
    (response) => WarehouseTask.fromJson(_object(response)),
    body: {
      'status': switch (status) {
        TaskStatus.newTask => 'new',
        TaskStatus.inProgress => 'in_progress',
        TaskStatus.paused => 'paused',
        TaskStatus.completed => 'completed',
      },
      if (comment != null && comment.trim().isNotEmpty)
        'comment': comment.trim(),
    },
  );

  @override
  Future<Result<void>> confirmDestination(int taskId, String qrCodeValue) =>
      _send(
        'POST',
        '/tasks/$taskId/qr-confirmation',
        _noContent,
        body: {'qrCodeValue': qrCodeValue},
      );

  @override
  Future<Result<List<TaskHistoryEntry>>> fetchHistory(int taskId) =>
      _send('GET', '/tasks/$taskId/history', (response) {
        final items = _object(response)['items'] as List<dynamic>;
        return items
            .map(
              (item) => TaskHistoryEntry.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      });

  @override
  Future<Result<List<WarehouseLocation>>> fetchLocations() =>
      _send('GET', '/locations?limit=100', (response) {
        final items = _object(response)['items'] as List<dynamic>;
        return items
            .map(
              (item) =>
                  WarehouseLocation.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      });

  @override
  Future<Result<WarehouseLocation>> fetchLocation(int id) => _send(
    'GET',
    '/locations/$id',
    (response) => WarehouseLocation.fromJson(_object(response)),
  );
}
