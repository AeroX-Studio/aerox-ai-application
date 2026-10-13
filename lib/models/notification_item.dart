/// Model representing in-app push notification items.
///
/// Encapsulates notification payloads delivered from the Admin Panel,
/// including severity types, optional deep-link actions, and read receipts.
library;

/// Represents an alert, update, or broadcast notification received by the client.
class NotificationItem {
  /// The unique identifier of the notification.
  final String id;

  /// The unique identifier of this user's specific delivery receipt.
  final String? deliveryId;

  /// The notification headline or title.
  final String title;

  /// The detailed text body or message.
  final String message;

  /// The classification category, such as `'info'`, `'update'`, `'promo'`, or `'alert'`.
  final String type;

  /// An optional URL or route to open when tapped by the user.
  final String? actionUrl;

  /// The creation timestamp when the broadcast was generated.
  final DateTime createdAt;

  /// Whether the user has marked this notification as read.
  bool isRead;

  /// Creates a new [NotificationItem].
  NotificationItem({
    required this.id,
    this.deliveryId,
    required this.title,
    required this.message,
    this.type = 'info',
    this.actionUrl,
    required this.createdAt,
    this.isRead = false,
  });

  /// Deserializes a [NotificationItem] from a JSON map.
  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    DateTime created;
    try {
      created = json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now();
    } catch (_) {
      created = DateTime.now();
    }

    return NotificationItem(
      id: json['id']?.toString() ?? '',
      deliveryId: json['deliveryId']?.toString(),
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'info',
      actionUrl: json['actionUrl']?.toString(),
      createdAt: created,
      isRead: json['isRead'] == true,
    );
  }
}
