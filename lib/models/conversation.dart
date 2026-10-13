/// Model representing a user conversation session.
///
/// Encapsulates conversation metadata, associated AI model information,
/// and timestamp tracking for sidebar navigation.
library;

/// Represents a chat thread item in the sidebar and dashboard history.
class ConversationItem {
  /// The unique identifier of the conversation.
  final String id;

  /// The title or topic summary of the conversation.
  final String title;

  /// The timestamp of the last message activity in this conversation.
  final DateTime updatedAt;

  /// The public display name of the AI model associated with this thread.
  final String? modelName;

  /// The icon or avatar URL of the associated AI model.
  final String? modelIcon;

  /// Creates a new [ConversationItem].
  ConversationItem({
    required this.id,
    required this.title,
    required this.updatedAt,
    this.modelName,
    this.modelIcon,
  });

  /// Deserializes a [ConversationItem] from backend JSON data.
  factory ConversationItem.fromJson(Map<String, dynamic> json) {
    final model = json['model'] is Map<String, dynamic> ? json['model'] : null;

    DateTime updated;
    try {
      updated = json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : DateTime.now();
    } catch (_) {
      updated = DateTime.now();
    }

    return ConversationItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'New Conversation',
      updatedAt: updated,
      modelName: model?['publicName']?.toString(),
      modelIcon: model?['publicIcon']?.toString(),
    );
  }
}
