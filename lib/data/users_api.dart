import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_message.dart';
import 'token_store.dart';

class RegisteredUser {
  const RegisteredUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.createdAt,
  });

  final int id;
  final String email;
  final String name;
  final String role;
  final DateTime createdAt;

  factory RegisteredUser.fromJson(Map<String, dynamic> json) => RegisteredUser(
    id: json['id'] as int,
    email: json['email'] as String,
    name: json['name'] as String,
    role: json['role'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

class UsersApiException implements Exception {
  const UsersApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class UsersApi {
  UsersApi(this.baseUrl, this.tokens, {http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final TokenStore tokens;
  final http.Client _client;

  Future<List<RegisteredUser>> fetchOthers() async {
    final token = await tokens.read();
    if (token == null) throw const UsersApiException('Войдите в аккаунт');
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl/admin/users'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        throw UsersApiException(apiMessage(response));
      }
      final rows = jsonDecode(response.body) as List<dynamic>;
      return List.unmodifiable(
        rows.map((row) => RegisteredUser.fromJson(row as Map<String, dynamic>)),
      );
    } on SocketException {
      throw const UsersApiException('Нет сети — повторите попытку');
    } on http.ClientException {
      throw const UsersApiException('Нет сети — повторите попытку');
    } on TimeoutException {
      throw const UsersApiException('Сервер не отвечает');
    } on FormatException {
      throw const UsersApiException('Ответ не тот, что обещан');
    } on TypeError {
      throw const UsersApiException('Ответ не тот, что обещан');
    }
  }
}
