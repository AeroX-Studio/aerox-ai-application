/// Push notification and real-time SSE stream listener service.
///
/// Subscribes to persistent notification streams, tracks unread counts,
/// coordinates read receipts, and triggers in-app alert banners.
library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/notification_item.dart';
import 'announcement_service.dart';
import 'api_service.dart';

/// Service managing client notifications, live SSE subscription, and unread states.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  /// Returns the shared singleton instance of [NotificationService].
  factory NotificationService() => _instance;
  NotificationService._internal();

  final ApiService _api = ApiService();

  /// Reactive counter of unread notifications for navigation badges.
  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  /// Reactive list of all fetched [NotificationItem] objects.
  final ValueNotifier<List<NotificationItem>> notifications = ValueNotifier<List<NotificationItem>>([]);

  /// Optional callback invoked when an incoming push notification arrives via SSE.
  Function(NotificationItem notification)? onNotificationReceived;

  http.Client? _streamClient;
  bool _isListening = false;
  Timer? _reconnectTimer;

  /// Initializes notifications by querying current inbox and opening the live SSE stream.
  Future<void> init() async {
    await fetchNotifications();
    startListening();
  }

  /// Fetches notification history from the backend server.
  Future<void> fetchNotifications({bool unreadOnly = false}) async {
    try {
      final res = await _api.get('/api/app/notifications?unreadOnly=$unreadOnly&limit=50');
      if (res is Map<String, dynamic>) {
        unreadCount.value = (res['unreadCount'] as num?)?.toInt() ?? 0;
        final rawList = res['notifications'];
        if (rawList is List) {
          notifications.value = rawList
              .map((n) => NotificationItem.fromJson(n as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {}
  }

  /// Marks a single notification identified by [notificationId] as read.
  Future<void> markAsRead(String notificationId) async {
    try {
      await _api.post('/api/app/notifications/$notificationId/read');
      final updated = notifications.value.map((n) {
        if (n.id == notificationId) {
          n.isRead = true;
        }
        return n;
      }).toList();
      notifications.value = updated;
      unreadCount.value = updated.where((n) => !n.isRead).length;
    } catch (_) {}
  }

  /// Marks all current user notifications as read.
  Future<void> markAllAsRead() async {
    try {
      await _api.post('/api/app/notifications/read-all');
      final updated = notifications.value.map((n) {
        n.isRead = true;
        return n;
      }).toList();
      notifications.value = updated;
      unreadCount.value = 0;
    } catch (_) {}
  }

  /// Establishes the real-time SSE stream listener for push broadcasts.
  void startListening() {
    if (_isListening) return;
    _isListening = true;
    _connectStream();
  }

  /// Closes the active notification stream and stops reconnect timers.
  void stopListening() {
    _isListening = false;
    _reconnectTimer?.cancel();
    _streamClient?.close();
    _streamClient = null;
  }

  Future<void> _connectStream() async {
    if (!_isListening) return;

    _streamClient?.close();
    _streamClient = http.Client();

    try {
      final uri = Uri.parse('${_api.effectiveBaseUrl}/api/app/notifications/stream');
      final request = http.Request('GET', uri);
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';
      request.headers['x-app-client'] = 'aerox-native';
      if (_api.sessionToken != null) {
        request.headers['Authorization'] = 'Bearer ${_api.sessionToken}';
      }

      final response = await _streamClient!.send(request);

      if (response.statusCode == 200) {
        final stream = response.stream.transform(utf8.decoder).transform(const LineSplitter());

        String currentEvent = '';
        await for (final line in stream) {
          if (!_isListening) break;
          if (line.isEmpty || line.startsWith(':')) continue;

          if (line.startsWith('event:')) {
            currentEvent = line.substring(6).trim();
            continue;
          }

          if (line.startsWith('data:')) {
            final dataStr = line.substring(5).trim();
            if (currentEvent == 'notification' && dataStr.isNotEmpty) {
              try {
                final data = jsonDecode(dataStr);
                final item = NotificationItem.fromJson(data as Map<String, dynamic>);

                // Prepend to notifications list
                final current = List<NotificationItem>.from(notifications.value);
                current.insert(0, item);
                notifications.value = current;
                unreadCount.value += 1;

                // Dispatch in-app alert banner
                onNotificationReceived?.call(item);
              } catch (_) {}
            } else if (currentEvent == 'announcement' && dataStr.isNotEmpty) {
              try {
                final data = jsonDecode(dataStr);
                if (data is Map<String, dynamic>) {
                  AnnouncementService().handleRealtimeAnnouncementUpdate(data);
                }
              } catch (_) {}
            }
          }
        }
      }
    } catch (_) {
      // Reconnect with backoff
    } finally {
      if (_isListening) {
        _reconnectTimer = Timer(const Duration(seconds: 5), () {
          if (_isListening) _connectStream();
        });
      }
    }
  }
}
