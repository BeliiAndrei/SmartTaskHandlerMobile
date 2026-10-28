import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_message.dart';
import 'result.dart';
import 'token_store.dart';

class AuthApi {
  AuthApi(this.baseUrl, this.tokens, {http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final TokenStore tokens;
  final http.Client _client;
  String? _profileRole;
  String? _profileName;
  String? _profileEmail;
  int? _profileId;

  String? get profileRole => _profileRole;
  String? get profileName => _profileName;
  String? get profileEmail => _profileEmail;
  int? get profileId => _profileId;

  static const _timeout = Duration(seconds: 8);

  Future<Result<void>> register(String email, String password, String name) =>
      _post('/auth/register', {
        'email': email,
        'password': password,
        'name': name,
      });

  Future<Result<void>> login(String email, String password) =>
      _post('/auth/login', {'email': email, 'password': password});

  Future<void> logout() async {
    _profileRole = null;
    _profileName = null;
    _profileEmail = null;
    _profileId = null;
    await tokens.clear();
  }

  Future<Result<void>> _post(String path, Map<String, Object?> body) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl$path'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      if (response.statusCode != 200 && response.statusCode != 201) {
        return Err(apiMessage(response, isLogin: path == '/auth/login'));
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final token = data['token'] as String;
      if (token.isEmpty) throw const FormatException('Empty token');
      _profileRole = null;
      _profileName = null;
      _profileEmail = null;
      _profileId = null;
      await tokens.save(token);
      return const Ok(null);
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

  /// Verifies a restored token. Only a 401 destroys it; a network outage does not.
  Future<bool?> validateStoredToken() async {
    final token = await tokens.read();
    if (token == null) {
      _profileRole = null;
      _profileName = null;
      _profileEmail = null;
      _profileId = null;
      return false;
    }
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl/profile'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(_timeout);
      if (response.statusCode == 401) {
        _profileRole = null;
        _profileName = null;
        _profileEmail = null;
        _profileId = null;
        await tokens.clear();
        return false;
      }
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final id = data['id'] as int;
      final role = data['role'] as String;
      if (role != 'user' && role != 'administrator') {
        throw const FormatException('Unknown role');
      }
      _profileRole = role;
      _profileName = data['name'] as String?;
      _profileEmail = data['email'] as String?;
      _profileId = id;
      return true;
    } on SocketException {
      return null;
    } on http.ClientException {
      return null;
    } on TimeoutException {
      return null;
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }
}
