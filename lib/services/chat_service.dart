/// Chat and real-time inference service for AeroX AI.
///
/// Handles AI model queries, conversation management, token streaming,
/// abort control, and image synthesis generation.
library;

import 'dart:async';

import 'package:http/http.dart' as http;

import '../models/ai_model.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import 'api_service.dart';
import 'auth_service.dart';

/// Service managing chat conversations, AI models, and real-time streaming inference.
class ChatService {
  static final ChatService _instance = ChatService._internal();

  /// Returns the shared singleton instance of [ChatService].
  factory ChatService() => _instance;
  ChatService._internal();

  final ApiService _api = ApiService();
  final AuthService _auth = AuthService();

  http.Client? _activeStreamClient;

  /// Whether an AI response is currently streaming token deltas.
  bool get isStreaming => _activeStreamClient != null;

  /// Fetches the catalog of available [AIModel] entities.
  Future<List<AIModel>> getModels() async {
    final res = await _api.get('/api/models');
    if (res is List) {
      return res
          .map((m) => AIModel.fromJson(m as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Fetches all conversation history items for the active user.
  Future<List<ConversationItem>> getConversations() async {
    final res = await _api.get('/api/chat/conversations');
    if (res is List) {
      return res
          .map((c) => ConversationItem.fromJson(c as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Fetches all historical [ChatMessage] items for the given [conversationId].
  Future<List<ChatMessage>> getMessages(String conversationId) async {
    final res = await _api.get(
      '/api/chat/conversations/$conversationId/messages',
    );
    if (res is List) {
      return res
          .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Updates the title of the conversation identified by [conversationId].
  Future<void> renameConversation(
    String conversationId,
    String newTitle,
  ) async {
    await _api.patch('/api/chat/conversations/$conversationId', {
      'title': newTitle,
    });
  }

  /// Permanently deletes the conversation identified by [conversationId].
  Future<void> deleteConversation(String conversationId) async {
    await _api.delete('/api/chat/conversations/$conversationId');
  }

  /// Aborts any in-flight SSE token generation stream immediately.
  void cancelCurrentStream() {
    if (_activeStreamClient != null) {
      _activeStreamClient?.close();
      _activeStreamClient = null;
    }
  }

  /// Sends a prompt and streams the assistant response in real time via SSE.
  ///
  /// Invokes [onStart] when the server begins generation, [onDelta] for each token chunk,
  /// [onDone] with updated credit balances when completed, and [onError] on failures.
  Future<void> streamMessage({
    required String modelId,
    String? conversationId,
    required String message,
    List<Map<String, dynamic>>? history,
    required Function(String conversationId, String modelName) onStart,
    required Function(String delta) onDelta,
    required Function(Map<String, dynamic> data) onDone,
    required Function(String error) onError,
  }) async {
    cancelCurrentStream();
    _activeStreamClient = http.Client();

    final body = {
      'modelId': modelId,
      'conversationId': ?conversationId,
      'message': message,
      if (history != null && history.isNotEmpty) 'messages': history,
    };

    try {
      await _api.streamSse(
        path: '/api/chat/stream',
        body: body,
        client: _activeStreamClient,
        onStart: (data) {
          final convId =
              data['conversationId']?.toString() ?? conversationId ?? '';
          final mName = data['modelName']?.toString() ?? 'AeroX Assistant';
          onStart(convId, mName);
        },
        onDelta: onDelta,
        onDone: (data) {
          // Update user balance if returned
          final credits = data['credits'];
          if (credits is Map<String, dynamic> && credits['available'] != null) {
            final avail = (credits['available'] as num).toDouble();
            final used = (credits['used'] as num?)?.toDouble();
            final total = (credits['total'] as num?)?.toDouble();
            _auth.updateCredits(available: avail, used: used, total: total);
          }
          _activeStreamClient = null;
          onDone(data);
        },
        onError: (err) {
          _activeStreamClient = null;
          onError(err);
        },
      );
    } catch (e) {
      _activeStreamClient = null;
      onError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Generates a synthetic image using the specified [prompt] and optional [size].
  Future<Map<String, dynamic>> generatePhoto({
    required String prompt,
    String? modelId,
    String? conversationId,
    String? size,
  }) async {
    final res = await _api.post('/api/chat/generate-image', {
      'prompt': prompt,
      'modelId': ?modelId,
      'conversationId': ?conversationId,
      'size': ?size,
    });
    return res is Map<String, dynamic> ? res : {};
  }
}
