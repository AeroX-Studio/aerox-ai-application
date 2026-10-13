/// Defines the AI intelligence model configuration entity.
///
/// Encapsulates model capabilities such as streaming, vision support,
/// credit consumption rates, and presentation badges.
library;

/// Represents an available AI model for chat completion or image synthesis.
class AIModel {
  /// The unique identifier of the model entity.
  final String id;

  /// The internal model key used in backend routing.
  final String internalModelId;

  /// The external API identifier passed to LLM providers.
  final String? apiModelId;

  /// The human-readable display name shown in the UI.
  final String publicName;

  /// A brief summary describing the model's strengths and domain expertise.
  final String? publicDescription;

  /// The URL or asset path of the model's icon.
  final String? publicIcon;

  /// An optional visual tag such as `PRO`, `FAST`, or `NEW`.
  final String? badge;

  /// The modality type of the model, typically `'text'` or `'image'`.
  final String modelType;

  /// Whether the model is available to users on the free tier.
  final bool isFreeEnabled;

  /// The number of credits consumed per generation request or token batch.
  final double creditCost;

  /// Whether the model can accept multi-modal image inputs.
  final bool supportsVision;

  /// Whether the model supports token-by-token streaming responses.
  final bool supportsStreaming;

  /// The capability tags associated with this model (e.g. text, vision, streaming).
  final List<String> capabilities;

  /// Whether this model is configured as the default chat model.
  final bool isDefaultChat;

  /// Whether this model is configured as the default free-tier model.
  final bool isDefaultFree;

  final String? providerType;
  final List<String> capabilityBadges;

  /// Creates a new [AIModel] instance.
  AIModel({
    required this.id,
    required this.internalModelId,
    this.apiModelId,
    required this.publicName,
    this.publicDescription,
    this.publicIcon,
    this.badge,
    this.modelType = 'text',
    this.isFreeEnabled = false,
    this.creditCost = 1.0,
    this.supportsVision = false,
    this.supportsStreaming = true,
    this.capabilities = const ['text'],
    this.isDefaultChat = false,
    this.isDefaultFree = false,
    this.providerType,
    this.capabilityBadges = const [],
  });

  /// Whether this model specializes in generative image creation.
  bool get isImageModel => modelType == 'image';

  /// Deserializes an [AIModel] instance from a JSON map.
  factory AIModel.fromJson(Map<String, dynamic> json) {
    final rawCaps = json['capabilities'];
    List<String> parsedCaps = [];
    if (rawCaps is List) {
      parsedCaps = rawCaps.map((e) => e.toString().toLowerCase().trim()).toList();
    } else if (rawCaps is String && rawCaps.isNotEmpty) {
      parsedCaps = rawCaps
          .split(',')
          .map((s) => s.toLowerCase().trim())
          .where((s) => s.isNotEmpty)
          .toList();
    } else {
      parsedCaps = (json['modelType'] == 'image') ? ['image'] : ['text'];
    }

    final providerType = json['providerType']?.toString().toLowerCase();

    final rawBadges = json['capabilityBadges'];
    List<String> capabilityBadges = [];
    if (rawBadges is List) {
      capabilityBadges = rawBadges
          .map((e) {
            if (e is Map) {
              return e['label']?.toString() ?? e['id']?.toString() ?? '';
            }
            return e.toString();
          })
          .where((s) => s.isNotEmpty)
          .toList();
    }
    if (capabilityBadges.isEmpty) {
      if (json['supportsVision'] == true ||
          parsedCaps.contains('vision') ||
          parsedCaps.contains('image-input')) {
        capabilityBadges.add('Vision');
      }
      if (json['supportsStreaming'] != false && parsedCaps.contains('streaming')) {
        capabilityBadges.add('Streaming');
      }
      if (json['modelType'] == 'image' || parsedCaps.contains('image') || parsedCaps.contains('photo')) {
        capabilityBadges.add('Photo Gen');
      }
      if (capabilityBadges.isEmpty && json['modelType'] != 'image') {
        capabilityBadges.add('Text Only');
      }
    }

    return AIModel(
      id: json['id']?.toString() ?? '',
      internalModelId: json['internalModelId']?.toString() ?? '',
      apiModelId: json['apiModelId']?.toString(),
      publicName: json['publicName']?.toString() ?? 'AeroX Assistant',
      publicDescription: json['publicDescription']?.toString(),
      publicIcon: json['publicIcon']?.toString(),
      badge: json['badge']?.toString(),
      modelType: json['modelType']?.toString() ?? 'text',
      isFreeEnabled: json['isFreeEnabled'] == true,
      creditCost: (json['creditCost'] as num?)?.toDouble() ?? 1.0,
      supportsVision: json['supportsVision'] == true ||
          parsedCaps.contains('vision') ||
          parsedCaps.contains('image-input'),
      supportsStreaming: json['supportsStreaming'] != false,
      capabilities: parsedCaps,
      isDefaultChat: json['isDefaultChat'] == true,
      isDefaultFree: json['isDefaultFree'] == true,
      providerType: providerType,
      capabilityBadges: capabilityBadges,
    );
  }
}
