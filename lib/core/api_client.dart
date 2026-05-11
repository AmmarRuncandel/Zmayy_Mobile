import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

import 'config.dart';
import 'secure_storage.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  final http.Client _inner = http.Client();
  static const Duration _requestTimeout = Duration(seconds: 15);

  Uri _buildUri(String path) {
    final base = Uri.parse(AppConfig.backendBaseUrl);
    final resolvedPath = path.startsWith('/') ? path.substring(1) : path;
    return base.resolve(resolvedPath);
  }

  Future<dynamic> get(String path) async {
    final url = _buildUri(path);
    final token = await SecureStorage.readToken();
    final request = http.Request('GET', url)
      ..followRedirects = false
      ..headers.addAll(_headers(token));

    final response = await _send(request);
    return _processResponse(response);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final url = _buildUri(path);
    final token = await SecureStorage.readToken();
    final request = http.Request('POST', url)
      ..followRedirects = false
      ..headers.addAll(_headers(token))
      ..body = jsonEncode(body);

    final response = await _send(request);
    return _processResponse(response);
  }

  Map<String, String> _headers(String? token) {
    return <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> _send(http.Request request) async {
    developer.log('API Request: ${request.method} ${request.url}', level: 800);
    
    try {
      final streamed = await _inner.send(request).timeout(
        _requestTimeout,
        onTimeout: () {
          developer.log('Request timeout after ${_requestTimeout.inSeconds}s: ${request.url}', level: 1000);
          throw TimeoutException('Request timeout after ${_requestTimeout.inSeconds}s', _requestTimeout);
        },
      );
      final response = await http.Response.fromStream(streamed);
      
      developer.log('API Response: ${response.statusCode} from ${request.url}', level: 800);

      final status = response.statusCode;
      // Do not auto-follow redirects for API calls. A redirect often indicates the backend
      // is applying web middleware (e.g. redirecting unauthenticated traffic to /login),
      // which breaks mobile auth flows and can surface as a confusing 405 later.
      if ((status == 301 || status == 302 || status == 303 || status == 307 || status == 308) &&
          response.headers['location'] != null) {
        final locationRaw = response.headers['location']!;
        final location = Uri.tryParse(locationRaw);
        final resolved = location == null
            ? locationRaw
            : (location.isAbsolute ? location.toString() : request.url.resolveUri(location).toString());
        final snippet = response.body.trim().isEmpty ? '<empty body>' : response.body.trim();
        throw ApiException(
          status,
          'Unexpected redirect while calling ${request.url} → $resolved. '
          'This usually means the backend is redirecting API requests to a web login page. '
          'Body: $snippet',
        );
      }

      return response;
    } catch (e) {
      developer.log('API Error: $e from ${request.url}', level: 1000);
      rethrow;
    }
  }

  Future<dynamic> _processResponse(http.Response resp) async {
    final status = resp.statusCode;
    final body = resp.body;
    final contentType = resp.headers['content-type'] ?? '';

    if (status != 200 && status != 201) {
      final location = resp.headers['location'];
      final extra = location == null ? '' : ' Location: $location';
      throw ApiException(status, '${_messageFromResponse(status, body, contentType)}$extra');
    }

    if (!contentType.toLowerCase().contains('application/json')) {
      throw ApiException(status, 'Expected JSON response from ${resp.request?.url}. Raw body: $body');
    }

    try {
      return body.isEmpty ? null : jsonDecode(body);
    } on FormatException catch (error) {
      throw ApiException(status, 'Invalid JSON response from ${resp.request?.url}. Raw body: $body (${error.message})');
    }
  }

  String _messageFromResponse(int status, String body, String contentType) {
    final trimmedBody = body.trim();
    if (trimmedBody.isEmpty) {
      return 'HTTP $status returned an empty response.';
    }

    if (!contentType.toLowerCase().contains('application/json')) {
      return 'HTTP $status returned non-JSON content. Raw body: $trimmedBody';
    }

    try {
      final decoded = jsonDecode(trimmedBody);
      if (decoded is Map && decoded['error'] != null) {
        return decoded['error'].toString();
      }
    } on FormatException {
      // fall through to raw body
    }

    return 'HTTP $status: $trimmedBody';
  }
}
