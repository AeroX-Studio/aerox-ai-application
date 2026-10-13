/// Central HTTP and SSE networking service for AeroX AI native applications.
///
/// Communicates with the official AeroX AI production backend endpoint,
/// managing session cookies, bearer tokens, JSON REST calls,
/// and high-speed Server-Sent Event (SSE) streaming.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

/// Singleton client managing network requests and real-time streaming connections.
class ApiService {
  static final ApiService _instance = ApiService._internal();

  /// Returns the shared singleton instance of [ApiService].
  factory ApiService() => _instance;
  ApiService._internal();

  /// The centralized, immutable base API URL.
  String get baseUrl => AppConfig.normalizedApiUrl;

  /// Returns the effective base URL used for all network calls.
  String get effectiveBaseUrl => AppConfig.normalizedApiUrl;

  String? _sessionCookie;
  String? _sessionToken;

  /// Optional callback invoked when the backend indicates an expired or invalid session.
  VoidCallback? onSessionExpired;

  /// The active session token, if authenticated.
  String? get sessionToken => _sessionToken;

  /// The active session cookie, if authenticated.
  String? get sessionCookie => _sessionCookie;

  /// Initializes authentication credentials from secure local storage
  /// and purges any legacy development overrides.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // Clean up any legacy developer URL override so production never runs on stale endpoints
    if (prefs.containsKey('aerox_custom_server_url')) {
      await prefs.remove('aerox_custom_server_url');
    }

    _sessionCookie = prefs.getString('aerox_session_cookie');
    _sessionToken = prefs.getString('aerox_session_token');
  }

  /// Tests network connectivity to the official AeroX AI production backend.
  Future<Map<String, dynamic>> testConnection([String? targetUrl]) async {
    final effective = (targetUrl != null && targetUrl.trim().isNotEmpty)
        ? (targetUrl.trim().endsWith('/')
              ? targetUrl.trim().substring(0, targetUrl.trim().length - 1)
              : targetUrl.trim())
        : effectiveBaseUrl;

    final stopwatch = Stopwatch()..start();
    try {
      final platformParam = kIsWeb
          ? 'web'
          : (Platform.isAndroid
                ? 'android'
                : (Platform.isWindows ? 'windows' : 'mobile'));
      final uri = Uri.parse(
        '$effective/api/app/config?platform=$platformParam',
      );
      final res = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'x-app-client': 'aerox-native',
            },
          )
          .timeout(const Duration(seconds: 8));
      stopwatch.stop();

      final isSuccess = res.statusCode >= 200 && res.statusCode < 400;
      return {
        'success': isSuccess,
        'statusCode': res.statusCode,
        'latencyMs': stopwatch.elapsedMilliseconds,
        'message': isSuccess
            ? 'Connected (${stopwatch.elapsedMilliseconds}ms)'
            : 'Server error (${res.statusCode})',
      };
    } catch (e) {
      stopwatch.stop();
      return {
        'success': false,
        'latencyMs': stopwatch.elapsedMilliseconds,
        'message': e is SocketException
            ? 'Cannot resolve host'
            : (e is TimeoutException ? 'Connection timed out' : 'Offline'),
      };
    }
  }

  /// Sets and persists active session authentication tokens and cookies.
  ///
  /// Providing a non-null [cookie] or [token] updates that value without
  /// inadvertently erasing the other credential.
  Future<void> setSession({String? cookie, String? token}) async {
    final prefs = await SharedPreferences.getInstance();

    if (cookie != null) {
      _sessionCookie = cookie;
      await prefs.setString('aerox_session_cookie', cookie);
    }

    if (token != null) {
      _sessionToken = token;
      await prefs.setString('aerox_session_token', token);
    }
  }

  /// Clears stored authentication credentials and terminates the session.
  Future<void> clearSession() async {
    _sessionCookie = null;
    _sessionToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('aerox_session_cookie');
    await prefs.remove('aerox_session_token');
  }

  Map<String, String> _buildHeaders({Map<String, String>? extra}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'x-app-client': 'aerox-native',
    };

    if (_sessionCookie != null && _sessionCookie!.isNotEmpty) {
      headers['Cookie'] = _sessionCookie!;
    }

    if (_sessionToken != null && _sessionToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_sessionToken';
      headers['x-session-token'] = _sessionToken!;
    }

    if (extra != null) {
      headers.addAll(extra);
    }
    return headers;
  }

  void _extractCookie(http.Response response) {
    final rawCookie = response.headers['set-cookie'];
    if (rawCookie != null) {
      final match = RegExp(r'aerox\.sid=[^;]+').firstMatch(rawCookie);
      if (match != null) {
        setSession(cookie: match.group(0));
      }
    }
  }

  Uri _uri(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Uri.parse(path);
    }
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$effectiveBaseUrl$normalizedPath');
  }

  /// Performs an HTTP GET request to the specified [path].
  Future<dynamic> get(String path) async {
    try {
      final res = await http
          .get(_uri(path), headers: _buildHeaders())
          .timeout(const Duration(seconds: 15));
      _extractCookie(res);
      return _handleResponse(res);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Performs an HTTP POST request to the specified [path] with optional [body].
  Future<dynamic> post(String path, [dynamic body]) async {
    try {
      final res = await http
          .post(
            _uri(path),
            headers: _buildHeaders(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 25));
      _extractCookie(res);
      return _handleResponse(res);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Performs an HTTP PATCH request to the specified [path] with payload [body].
  Future<dynamic> patch(String path, dynamic body) async {
    try {
      final res = await http
          .patch(_uri(path), headers: _buildHeaders(), body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));
      _extractCookie(res);
      return _handleResponse(res);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Performs an HTTP DELETE request to the specified [path].
  Future<dynamic> delete(String path) async {
    try {
      final res = await http
          .delete(_uri(path), headers: _buildHeaders())
          .timeout(const Duration(seconds: 15));
      _extractCookie(res);
      return _handleResponse(res);
    } catch (e) {
      throw _handleError(e);
    }
  }

  dynamic _handleResponse(http.Response res) {
    dynamic data;
    try {
      data = jsonDecode(res.body);
    } catch (_) {
      data = {'error': res.body};
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return data;
    }

    if (res.statusCode == 401) {
      onSessionExpired?.call();
    }

    final msg = data is Map
        ? (data['error'] ??
              data['message'] ??
              'Request failed (${res.statusCode})')
        : 'Server error';
    throw Exception(msg);
  }

  Exception _handleError(dynamic e) {
    if (e is SocketException) {
      return Exception(
        'Cannot connect to AeroX AI server. Please verify your internet connection.',
      );
    }
    if (e is TimeoutException) {
      return Exception('Connection timed out. Please try again.');
    }
    return Exception(e.toString().replaceAll('Exception: ', ''));
  }

  /// Streams token deltas from an SSE endpoint using chunked transfer decoding.
  Future<void> streamSse({
    required String path,
    required Map<String, dynamic> body,
    required Function(Map<String, dynamic> data) onStart,
    required Function(String delta) onDelta,
    required Function(Map<String, dynamic> data) onDone,
    required Function(String error) onError,
    http.Client? client,
  }) async {
    final httpClient = client ?? http.Client();
    final request = http.Request('POST', _uri(path));
    request.headers.addAll(
      _buildHeaders(
        extra: {'Accept': 'text/event-stream', 'Cache-Control': 'no-cache'},
      ),
    );
    request.body = jsonEncode(body);

    try {
      final response = await httpClient.send(request);

      if (response.statusCode != 200) {
        final errBody = await response.stream.bytesToString();
        String errMsg = 'Failed to connect to stream (${response.statusCode})';
        try {
          final parsed = jsonDecode(errBody);
          if (parsed['error'] != null) errMsg = parsed['error'];
        } catch (_) {}
        onError(errMsg);
        return;
      }

      String currentEvent = 'delta';
      final stream = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in stream) {
        if (line.isEmpty || line.startsWith(':')) {
          continue; // SSE heartbeat comment
        }

        if (line.startsWith('event:')) {
          currentEvent = line.substring(6).trim();
          continue;
        }

        if (line.startsWith('data:')) {
          final dataStr = line.substring(5).trim();
          if (dataStr.isEmpty) continue;

          try {
            final data = jsonDecode(dataStr);
            if (currentEvent == 'start') {
              onStart(data is Map<String, dynamic> ? data : {});
            } else if (currentEvent == 'delta') {
              final text = data['text']?.toString() ?? '';
              onDelta(text);
            } else if (currentEvent == 'done') {
              onDone(data is Map<String, dynamic> ? data : {});
            } else if (currentEvent == 'error') {
              onError(
                data['error']?.toString() ??
                    'An error occurred during response generation',
              );
            }
          } catch (_) {
            if (currentEvent == 'delta') {
              onDelta(dataStr);
            }
          }
        }
      }
    } catch (e) {
      if (e is! http.ClientException) {
        onError(_handleError(e).toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }
}
