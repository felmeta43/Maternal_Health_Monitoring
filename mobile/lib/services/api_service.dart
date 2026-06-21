import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/reading.dart';

/// Thin client for the FastAPI backend (see backend/app/routers/).
class ApiService {
  final String baseUrl;
  String? _accessToken;

  ApiService({required this.baseUrl});

  Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

  Future<void> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/login'),
      body: {'username': email, 'password': password},
    );
    if (response.statusCode != 200) {
      throw ApiException('Login failed: ${response.body}');
    }
    _accessToken = jsonDecode(response.body)['access_token'] as String;
  }

  /// Posts a reading and returns true if it was accepted by the server.
  /// Caller is responsible for marking the local cache row synced.
  Future<bool> submitReading(VitalReading reading) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/readings'),
      headers: _authHeaders,
      body: jsonEncode(reading.toApiJson()),
    );
    return response.statusCode == 201;
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}
