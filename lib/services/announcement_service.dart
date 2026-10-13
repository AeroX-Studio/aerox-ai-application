/// Central Announcement client service for AeroX AI native applications.
///
/// Discovers active announcements published from the Admin Panel, evaluates
/// device display rules, manages read receipts, tracks click telemetry,
/// and handles offline event synchronization.
library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/announcement_item.dart';
import 'api_service.dart';
import 'platform_service.dart';

/// Singleton service managing cross-platform announcements on native clients.
class AnnouncementService {
  static final AnnouncementService _instance = AnnouncementService._internal();

  /// Returns the shared singleton instance of [AnnouncementService].
  factory AnnouncementService() => _instance;
  AnnouncementService._internal();

  final ApiService _api = ApiService();
  final PlatformService _platform = PlatformService();

  static const String _storagePrefix = 'aerox_ann_';
  static const String _queueKey = 'aerox_ann_offline_queue';
  static const String _revisionKey = 'aerox_ann_revision';
  static const String _cacheItemsKey = 'aerox_ann_cached_items';
  static const String _cacheTimeKey = 'aerox_ann_cache_time';

  final Set<String> _sessionDismissedIds = {};

  /// Reactive notifier holding the active announcement to be displayed, if any.
  final ValueNotifier<AnnouncementItem?> activeAnnouncement =
      ValueNotifier<AnnouncementItem?>(null);

  /// Reactive list of all valid announcements delivered to this client.
  final ValueNotifier<List<AnnouncementItem>> announcements =
      ValueNotifier<List<AnnouncementItem>>([]);

  /// Initializes the announcement client, checks offline queue, and fetches active announcements.
  Future<void> init() async {
    await flushOfflineEvents();
    await fetchAnnouncements();
  }

  /// Fetches active announcements from the centralized backend for the current platform.
  /// Falls back to local cached announcements if network is unreachable.
  Future<void> fetchAnnouncements({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final currentPlatform = _platform.currentPlatform;
      final storedRev = forceRefresh ? null : prefs.getString(_revisionKey);

      String url = '/api/announcements?platform=$currentPlatform';
      if (storedRev != null && storedRev.isNotEmpty) {
        url += '&revision=$storedRev';
      }

      final res = await _api.get(url);

      if (res is Map<String, dynamic>) {
        if (res['revision'] != null) {
          await prefs.setString(_revisionKey, res['revision'].toString());
        }

        final rawList = res['announcements'];
        if (rawList is List) {
          final items = rawList
              .map((a) => AnnouncementItem.fromJson(a as Map<String, dynamic>))
              .toList();

          announcements.value = items;

          // Save to persistent cache for offline availability
          await prefs.setString(
            _cacheItemsKey,
            jsonEncode(items.map((i) => i.toJson()).toList()),
          );
          await prefs.setString(
            _cacheTimeKey,
            DateTime.now().toIso8601String(),
          );

          // Find first eligible announcement by priority
          final eligible = <AnnouncementItem>[];
          for (final ann in items) {
            if (await _shouldShow(ann, prefs)) {
              eligible.add(ann);
            }
          }

          // Sort by priority (critical > high > normal > low)
          eligible.sort((a, b) {
            final pOrder = {'critical': 4, 'high': 3, 'normal': 2, 'low': 1};
            return (pOrder[b.priority] ?? 2).compareTo(pOrder[a.priority] ?? 2);
          });

          if (eligible.isNotEmpty) {
            activeAnnouncement.value = eligible.first;
            // Record initial read/impression
            await markAsRead(eligible.first.id);
          } else {
            activeAnnouncement.value = null;
          }
          return;
        }
      }
    } catch (_) {
      // Offline fallback: load cached announcements gracefully
      try {
        final cachedRaw = prefs.getString(_cacheItemsKey);
        if (cachedRaw != null && cachedRaw.isNotEmpty) {
          final List<dynamic> decoded = jsonDecode(cachedRaw);
          final cachedItems = decoded
              .map((a) => AnnouncementItem.fromJson(a as Map<String, dynamic>))
              .toList();

          announcements.value = cachedItems;

          final eligible = <AnnouncementItem>[];
          for (final ann in cachedItems) {
            if (await _shouldShow(ann, prefs)) {
              eligible.add(ann);
            }
          }

          eligible.sort((a, b) {
            final pOrder = {'critical': 4, 'high': 3, 'normal': 2, 'low': 1};
            return (pOrder[b.priority] ?? 2).compareTo(pOrder[a.priority] ?? 2);
          });

          if (eligible.isNotEmpty) {
            activeAnnouncement.value = eligible.first;
          }
        }
      } catch (_) {}
    }
  }

  /// Processes live real-time announcement events received via SSE stream.
  Future<void> handleRealtimeAnnouncementUpdate(Map<String, dynamic> data) async {
    try {
      final action = data['action']?.toString();
      final annId = data['announcementId']?.toString();

      if (action == 'unpublished' || action == 'archived' || action == 'deleted') {
        if (activeAnnouncement.value?.id == annId) {
          activeAnnouncement.value = null;
        }
        final updated = announcements.value.where((a) => a.id != annId).toList();
        announcements.value = updated;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          _cacheItemsKey,
          jsonEncode(updated.map((i) => i.toJson()).toList()),
        );
      } else if (action == 'published' || action == 'updated') {
        // Force refresh from server without stale revision cache
        await fetchAnnouncements(forceRefresh: true);
      }
    } catch (_) {}
  }

  /// Manually opens a specific announcement dialog (e.g., from the Announcement Center).
  void openAnnouncement(AnnouncementItem ann) {
    activeAnnouncement.value = ann;
  }

  /// Finds a loaded announcement by its unique identifier.
  AnnouncementItem? findById(String id) {
    try {
      return announcements.value.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Evaluates display frequency and visibility rules.
  Future<bool> _shouldShow(AnnouncementItem ann, SharedPreferences prefs) async {
    final id = ann.id;
    final rule = ann.displayRule;

    if (rule == 'show_once') {
      if (prefs.getBool('${_storagePrefix}shown_$id') == true) return false;
    } else if (rule == 'show_until_dismissed') {
      if (prefs.getBool('${_storagePrefix}dismissed_$id') == true) return false;
    } else if (rule == 'show_every_session') {
      if (_sessionDismissedIds.contains(id)) return false;
    } else if (rule == 'show_until_read') {
      if (ann.isRead || prefs.getBool('${_storagePrefix}read_$id') == true) {
        return false;
      }
    }

    return true;
  }

  /// Marks the announcement as read and acknowledges delivery.
  Future<void> markAsRead(String announcementId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_storagePrefix}read_$announcementId', true);
    await prefs.setBool('${_storagePrefix}shown_$announcementId', true);

    try {
      await _api.post(
        '/api/announcements/$announcementId/read',
        {'platform': _platform.currentPlatform},
      );
    } catch (_) {
      await _queueOfflineEvent({
        'announcementId': announcementId,
        'type': 'read',
      });
    }
  }

  /// Records a user click on a Call-To-Action (CTA) button.
  Future<void> recordClick(String announcementId, {int buttonIndex = 0}) async {
    try {
      await _api.post(
        '/api/announcements/$announcementId/click',
        {
          'platform': _platform.currentPlatform,
          'buttonIndex': buttonIndex,
        },
      );
    } catch (_) {
      await _queueOfflineEvent({
        'announcementId': announcementId,
        'type': 'click',
        'buttonIndex': buttonIndex,
      });
    }
  }

  /// Dismisses the active announcement dialog.
  Future<void> dismiss(String announcementId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_storagePrefix}dismissed_$announcementId', true);
    _sessionDismissedIds.add(announcementId);

    activeAnnouncement.value = null;

    try {
      await _api.post(
        '/api/announcements/$announcementId/dismiss',
        {'platform': _platform.currentPlatform},
      );
    } catch (_) {
      await _queueOfflineEvent({
        'announcementId': announcementId,
        'type': 'dismiss',
      });
    }
  }

  /// Queues an event locally if the client is currently offline.
  Future<void> _queueOfflineEvent(Map<String, dynamic> event) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_queueKey);
      final List<dynamic> q = raw != null ? jsonDecode(raw) : [];
      q.add({...event, 'timestamp': DateTime.now().toIso8601String()});
      await prefs.setString(_queueKey, jsonEncode(q));
    } catch (_) {}
  }

  /// Flushes all queued offline events to the central backend.
  Future<void> flushOfflineEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_queueKey);
      if (raw == null || raw.isEmpty) return;

      final List<dynamic> q = jsonDecode(raw);
      if (q.isEmpty) return;

      final res = await _api.post(
        '/api/announcements/sync',
        {'events': q},
      );

      if (res != null) {
        await prefs.remove(_queueKey);
      }
    } catch (_) {}
  }
}
