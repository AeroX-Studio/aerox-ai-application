/// Model representing cross-platform announcement items.
///
/// Encapsulates announcement payloads delivered from the centralized
/// Admin Announcement Management System across Web, Windows, Android,
/// iOS, macOS, and Linux applications.
library;

import 'dart:convert';

/// Represents a Call-To-Action (CTA) button attached to an announcement.
class AnnouncementButton {
  final String text;
  final String url;
  final bool newTab;
  final bool platformAction;

  AnnouncementButton({
    required this.text,
    required this.url,
    this.newTab = true,
    this.platformAction = false,
  });

  factory AnnouncementButton.fromJson(Map<String, dynamic> json) {
    return AnnouncementButton(
      text: json['text']?.toString() ?? 'Action',
      url: json['url']?.toString() ?? '#',
      newTab: json['newTab'] == true,
      platformAction: json['platformAction'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'url': url,
        'newTab': newTab,
        'platformAction': platformAction,
      };
}

/// Comprehensive announcement item model.
class AnnouncementItem {
  final String id;
  final String title;
  final String? subtitle;
  final String? shortDescription;
  final String? content;
  final String type;
  final String status;
  final String priority;
  final String layout;
  final String? coverImage;
  final String? videoUrl;
  final String? mediaType;
  final String icon;
  final String accentColor;
  final String? textColor;
  final String? buttonColor;
  final String targetAudience;
  final dynamic targetPlatforms;
  final List<AnnouncementButton> buttons;
  final String displayRule;
  final DateTime? startAt;
  final DateTime? endAt;
  bool isRead;

  AnnouncementItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.shortDescription,
    this.content,
    this.type = 'general',
    this.status = 'published',
    this.priority = 'normal',
    this.layout = 'modal',
    this.coverImage,
    this.videoUrl,
    this.mediaType,
    this.icon = '📢',
    this.accentColor = '#6366f1',
    this.textColor,
    this.buttonColor,
    this.targetAudience = 'everyone',
    this.targetPlatforms = 'all',
    this.buttons = const [],
    this.displayRule = 'show_until_read',
    this.startAt,
    this.endAt,
    this.isRead = false,
  });

  factory AnnouncementItem.fromJson(Map<String, dynamic> json) {
    List<AnnouncementButton> parsedButtons = [];
    if (json['buttons'] != null) {
      try {
        dynamic rawBtns = json['buttons'];
        if (rawBtns is String && rawBtns.isNotEmpty) {
          rawBtns = jsonDecode(rawBtns);
        }
        if (rawBtns is List) {
          parsedButtons = rawBtns
              .map((b) => AnnouncementButton.fromJson(b as Map<String, dynamic>))
              .toList();
        }
      } catch (_) {}
    }

    DateTime? start;
    if (json['startAt'] != null) {
      try {
        start = DateTime.parse(json['startAt'].toString());
      } catch (_) {}
    }

    DateTime? end;
    if (json['endAt'] != null) {
      try {
        end = DateTime.parse(json['endAt'].toString());
      } catch (_) {}
    }

    return AnnouncementItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString(),
      shortDescription: json['shortDescription']?.toString(),
      content: json['content']?.toString(),
      type: json['type']?.toString() ?? 'general',
      status: json['status']?.toString() ?? 'published',
      priority: json['priority']?.toString() ?? 'normal',
      layout: json['layout']?.toString() ?? 'modal',
      coverImage: json['coverImage']?.toString(),
      videoUrl: json['videoUrl']?.toString() ?? json['background']?.toString(),
      mediaType: json['mediaType']?.toString(),
      icon: json['icon']?.toString() ?? '📢',
      accentColor: json['accentColor']?.toString() ?? '#6366f1',
      textColor: json['textColor']?.toString(),
      buttonColor: json['buttonColor']?.toString(),
      targetAudience: json['targetAudience']?.toString() ?? 'everyone',
      targetPlatforms: json['targetPlatforms'] ?? 'all',
      buttons: parsedButtons,
      displayRule: json['displayRule']?.toString() ?? 'show_until_read',
      startAt: start,
      endAt: end,
      isRead: json['isRead'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'shortDescription': shortDescription,
        'content': content,
        'type': type,
        'status': status,
        'priority': priority,
        'layout': layout,
        'coverImage': coverImage,
        'videoUrl': videoUrl,
        'mediaType': mediaType,
        'icon': icon,
        'accentColor': accentColor,
        'textColor': textColor,
        'buttonColor': buttonColor,
        'targetAudience': targetAudience,
        'targetPlatforms': targetPlatforms,
        'buttons': buttons.map((b) => b.toJson()).toList(),
        'displayRule': displayRule,
        'startAt': startAt?.toIso8601String(),
        'endAt': endAt?.toIso8601String(),
        'isRead': isRead,
      };
}
