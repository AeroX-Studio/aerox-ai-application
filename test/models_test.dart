import 'package:flutter_test/flutter_test.dart';
import 'package:aeroxai/models/user.dart';
import 'package:aeroxai/models/ai_model.dart';
import 'package:aeroxai/models/conversation.dart';
import 'package:aeroxai/models/message.dart';
import 'package:aeroxai/models/platform_config.dart';

void main() {
  group('User Model Tests', () {
    test('parses User from complete JSON map', () {
      final json = {
        'id': 'usr_123',
        'email': 'developer@aerox.ai',
        'username': 'aeroxdev',
        'displayName': 'AeroX Developer',
        'role': 'admin',
        'totalCredits': 500.0,
        'usedCredits': 150.0,
        'availableCredits': 350.0,
        'avatarUrl': 'https://aerox.ai/avatar.png',
        'package': {
          'name': 'Enterprise Tier',
          'slug': 'enterprise',
        }
      };

      final user = User.fromJson(json);

      expect(user.id, equals('usr_123'));
      expect(user.email, equals('developer@aerox.ai'));
      expect(user.username, equals('aeroxdev'));
      expect(user.displayName, equals('AeroX Developer'));
      expect(user.role, equals('admin'));
      expect(user.totalCredits, equals(500.0));
      expect(user.usedCredits, equals(150.0));
      expect(user.availableCredits, equals(350.0));
      expect(user.avatarUrl, equals('https://aerox.ai/avatar.png'));
      expect(user.packageName, equals('Enterprise Tier'));
      expect(user.packageSlug, equals('enterprise'));
    });

    test('falls back to default values for missing or empty JSON keys', () {
      final user = User.fromJson({});

      expect(user.id, equals(''));
      expect(user.email, equals(''));
      expect(user.username, equals(''));
      expect(user.displayName, equals(''));
      expect(user.role, equals('user'));
      expect(user.totalCredits, equals(0.0));
      expect(user.usedCredits, equals(0.0));
      expect(user.availableCredits, equals(0.0));
      expect(user.packageName, isNull);
      expect(user.packageSlug, isNull);
    });
  });

  group('AIModel Model Tests', () {
    test('parses AIModel from JSON map correctly', () {
      final json = {
        'id': 'mod_gpt4',
        'internalModelId': 'gpt-4o',
        'apiModelId': 'openai/gpt-4o',
        'publicName': 'GPT-4 Omni',
        'publicDescription': 'Fast multimodal flagship intelligence',
        'publicIcon': 'https://aerox.ai/icons/gpt4o.svg',
        'badge': 'PRO',
        'modelType': 'text',
        'isFreeEnabled': false,
        'creditCost': 2.5,
        'supportsVision': true,
        'supportsStreaming': true,
      };

      final model = AIModel.fromJson(json);

      expect(model.id, equals('mod_gpt4'));
      expect(model.internalModelId, equals('gpt-4o'));
      expect(model.publicName, equals('GPT-4 Omni'));
      expect(model.badge, equals('PRO'));
      expect(model.creditCost, equals(2.5));
      expect(model.supportsVision, isTrue);
      expect(model.supportsStreaming, isTrue);
    });
  });

  group('ConversationItem Model Tests', () {
    test('parses ConversationItem and handles model nested structure', () {
      final now = DateTime.now();
      final json = {
        'id': 'conv_999',
        'title': 'Flutter Windows Desktop Architecture',
        'updatedAt': now.toIso8601String(),
        'model': {
          'publicName': 'Claude 3.5 Sonnet',
          'publicIcon': '/icons/claude.png',
        }
      };

      final conv = ConversationItem.fromJson(json);

      expect(conv.id, equals('conv_999'));
      expect(conv.title, equals('Flutter Windows Desktop Architecture'));
      expect(conv.modelName, equals('Claude 3.5 Sonnet'));
      expect(conv.modelIcon, equals('/icons/claude.png'));
    });
  });

  group('ChatMessage Model Tests', () {
    test('parses user and assistant messages with role flags', () {
      final userMsg = ChatMessage(
        id: 'msg_1',
        role: 'user',
        content: 'Hello AeroX',
        createdAt: DateTime.now(),
      );

      final assistantMsg = ChatMessage(
        id: 'msg_2',
        role: 'assistant',
        content: 'Hello! How can I assist you today?',
        createdAt: DateTime.now(),
      );

      expect(userMsg.isUser, isTrue);
      expect(userMsg.isAssistant, isFalse);
      expect(assistantMsg.isUser, isFalse);
      expect(assistantMsg.isAssistant, isTrue);
    });
  });

  group('PlatformConfig Model Tests', () {
    test('parses platform maintenance and update status', () {
      final json = {
        'platform': 'windows',
        'name': 'Windows Desktop',
        'isMaintenance': false,
        'maintenanceMessage': null,
        'minSupportedVersion': '1.0.0',
        'latestVersion': '1.1.0',
        'downloadUrl': 'https://aerox.ai/download',
        'releaseNotes': 'Performance enhancements',
      };

      final config = PlatformConfig.fromJson(json);

      expect(config.platform, equals('windows'));
      expect(config.name, equals('Windows Desktop'));
      expect(config.isMaintenance, isFalse);
      expect(config.minSupportedVersion, equals('1.0.0'));
      expect(config.latestVersion, equals('1.1.0'));
      expect(config.downloadUrl, equals('https://aerox.ai/download'));
      expect(config.releaseNotes, equals('Performance enhancements'));
    });
  });
}
