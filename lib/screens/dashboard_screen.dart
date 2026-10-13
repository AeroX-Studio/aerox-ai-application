/// Primary conversational dashboard experience for AeroX AI.
///
/// Features 1:1 visual parity with the web platform (v2), including:
/// - Exact typography (Caacupe One, Lora, Share Tech, Quicksand, JetBrains Mono, Inter)
/// - Deep Black design tokens (#000000, #0a0a0a, #0d0d0d, #141414, #1a1a1a, #222222)
/// - Collapsible ChatGPT/Claude-style sidebar with "New chat" Ctrl+K button, search box,
///   animated conversation history, and quick voucher redemption
/// - Top bar with high-tech model indicator, 5-hour rolling usage meter, and notifications
/// - Pilot Welcome screen with pulsing celestial AI emblem and 4 suggestion cards
/// - Floating Pill Composer with [Build] [Plan] modes, attachment trays, queue button,
///   and sub-bar pill showing model, tier, and window timer
/// - Full Model Intelligence Directory view with search, filter chips, and spec sheets
/// - Usage & Token Analytics view with balance cards and quick redemption
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../models/ai_model.dart';
import '../models/attachment_item.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../services/announcement_service.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/file_service.dart';
import '../services/notification_service.dart';
import '../theme/aerox_animations.dart';
import '../theme/aerox_colors.dart';
import '../theme/aerox_theme.dart';
import '../widgets/aerox_badge.dart';
import '../widgets/aerox_toast.dart';
import '../widgets/announcement_dialog.dart';
import '../widgets/attachment_preview.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/model_selector_modal.dart';
import '../widgets/notification_banner.dart';
import '../widgets/notification_drawer.dart';
import '../widgets/redeem_voucher_dialog.dart';

import 'auth_screen.dart';
import 'settings_screen.dart';

/// Available primary sections matching the web dashboard layout.
enum DashboardSection { chat, models, usage }

class _SlashCommand {
  final String command;
  final String label;
  final String description;
  final IconData icon;

  const _SlashCommand({
    required this.command,
    required this.label,
    required this.description,
    required this.icon,
  });
}

const List<_SlashCommand> _availableSlashCommands = [
  _SlashCommand(
    command: '/help',
    label: '/help',
    description: 'Display all AeroX AI capabilities, commands, and tools',
    icon: Icons.help_outline,
  ),
  _SlashCommand(
    command: '/code',
    label: '/code',
    description: 'Specialized programming, debugging, and code generation',
    icon: Icons.code,
  ),
  _SlashCommand(
    command: '/photo',
    label: '/photo',
    description: 'High-fidelity AI image synthesis and creative art',
    icon: Icons.brush_outlined,
  ),
  _SlashCommand(
    command: '/search',
    label: '/search',
    description: 'Live real-time web search and grounded factual queries',
    icon: Icons.search,
  ),
  _SlashCommand(
    command: '/analyze',
    label: '/analyze',
    description: 'Deep analytical and structured breakdown of data/text',
    icon: Icons.analytics_outlined,
  ),
  _SlashCommand(
    command: '/summarize',
    label: '/summarize',
    description: 'Concise executive summaries and key bullet takeaways',
    icon: Icons.summarize_outlined,
  ),
  _SlashCommand(
    command: '/translate',
    label: '/translate',
    description: 'Multilingual translation in Bengali, Hindi, and English',
    icon: Icons.translate,
  ),
];

/// The central dashboard screen hosting conversations, AI streaming, models directory, and analytics.
class DashboardScreen extends StatefulWidget {
  final DashboardSection initialSection;

  const DashboardScreen({
    super.key,
    this.initialSection = DashboardSection.chat,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final FileService _fileService = FileService();
  final NotificationService _notificationService = NotificationService();

  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _historySearchController =
      TextEditingController();
  final TextEditingController _modelsSearchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();

  late DashboardSection _currentSection;
  String _activeComposerMode = 'Build'; // 'Build' or 'Plan'

  List<AIModel> _models = [];
  AIModel? _selectedModel;
  List<ConversationItem> _conversations = [];
  String? _currentConversationId;

  List<ChatMessage> _messages = [];
  final List<AttachmentItem> _pendingAttachments = [];

  bool _isLoadingHistory = false;
  bool _isSidebarCollapsed = false;
  String _historyFilter = '';
  String _modelsFilter = '';
  String _selectedCategory = 'all';

  // Stream buffering for silky-smooth 60fps rendering
  Timer? _streamBufferTimer;
  final StringBuffer _streamBuffer = StringBuffer();
  ChatMessage? _activeStreamingMsg;

  // Slash commands matching list
  List<_SlashCommand> _matchingSlashCommands = [];

  // ─── Animation Controllers ──────────────────────────────────────────
  late AnimationController _entranceController;
  late Animation<double> _sidebarFade;
  late Animation<Offset> _sidebarSlide;
  late Animation<double> _topBarFade;
  late Animation<double> _chatAreaFade;
  late Animation<Offset> _inputSlide;
  late Animation<double> _inputFade;

  // Sidebar collapse/expand animation
  late AnimationController _sidebarWidthController;
  late Animation<double> _sidebarWidthAnim;

  // Celestial Emblem continuous pulse animation
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _currentSection = widget.initialSection;
    _inputController.addListener(_onInputChanged);
    _historySearchController.addListener(() {
      setState(
        () =>
            _historyFilter = _historySearchController.text.trim().toLowerCase(),
      );
    });
    _modelsSearchController.addListener(() {
      setState(
        () => _modelsFilter = _modelsSearchController.text.trim().toLowerCase(),
      );
    });

    // Entrance animation: staggered reveal
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _sidebarFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.4, curve: Cubic(0.16, 1.0, 0.3, 1.0)),
      ),
    );
    _sidebarSlide =
        Tween<Offset>(begin: const Offset(-0.15, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.0, 0.5, curve: Cubic(0.16, 1.0, 0.3, 1.0)),
          ),
        );

    _topBarFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.15, 0.55, curve: Cubic(0.16, 1.0, 0.3, 1.0)),
      ),
    );

    _chatAreaFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.3, 0.7, curve: Cubic(0.16, 1.0, 0.3, 1.0)),
      ),
    );

    _inputSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.4, 0.85, curve: Cubic(0.16, 1.0, 0.3, 1.0)),
          ),
        );
    _inputFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.4, 0.8, curve: Cubic(0.16, 1.0, 0.3, 1.0)),
      ),
    );

    _sidebarWidthController = AnimationController(
      vsync: this,
      duration: AeroXAnimations.normal,
    );
    _sidebarWidthAnim = Tween<double>(begin: 270, end: 0).animate(
      CurvedAnimation(
        parent: _sidebarWidthController,
        curve: AeroXAnimations.easeOut,
      ),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _entranceController.forward();
    _loadInitialData();
    _setupNotificationListener();
    _setupAnnouncementListener();
  }

  @override
  void dispose() {
    _handleStopGeneration();
    AnnouncementService().activeAnnouncement.removeListener(
      _onActiveAnnouncementChanged,
    );
    _inputController.removeListener(_onInputChanged);
    _historySearchController.dispose();
    _modelsSearchController.dispose();
    _streamBufferTimer?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    _entranceController.dispose();
    _sidebarWidthController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    final text = _inputController.text;
    if (text.startsWith('/') && !text.contains(' ')) {
      final query = text.toLowerCase();
      final matches = _availableSlashCommands
          .where((c) => c.command.toLowerCase().startsWith(query))
          .toList();
      if (matches.length != _matchingSlashCommands.length) {
        setState(() => _matchingSlashCommands = matches);
      }
    } else {
      if (_matchingSlashCommands.isNotEmpty) {
        setState(() => _matchingSlashCommands = []);
      }
    }
  }

  void _applySlashCommand(_SlashCommand cmd) {
    setState(() {
      _inputController.text = '${cmd.command} ';
      _inputController.selection = TextSelection.fromPosition(
        TextPosition(offset: _inputController.text.length),
      );
      _matchingSlashCommands = [];
    });
    _inputFocusNode.requestFocus();
  }

  void _setupNotificationListener() {
    _notificationService.onNotificationReceived = (notification) {
      if (mounted) {
        NotificationBanner.show(
          context,
          notification,
          onTap: () => NotificationDrawer.show(context),
        );
      }
    };
  }

  bool _isAnnouncementDialogShowing = false;

  void _setupAnnouncementListener() {
    AnnouncementService().activeAnnouncement.addListener(
      _onActiveAnnouncementChanged,
    );
  }

  void _onActiveAnnouncementChanged() {
    final activeAnn = AnnouncementService().activeAnnouncement.value;
    if (activeAnn != null && mounted && !_isAnnouncementDialogShowing) {
      _isAnnouncementDialogShowing = true;
      AnnouncementDialog.show(
        context,
        activeAnn,
        onModelSelect: _selectModelById,
      ).then((_) {
        _isAnnouncementDialogShowing = false;
      });
    }
  }

  void _selectModelById(String modelId) {
    if (_models.isEmpty) return;
    final found = _models.firstWhere(
      (m) =>
          m.id == modelId ||
          m.apiModelId == modelId ||
          m.publicName.toLowerCase() == modelId.toLowerCase(),
      orElse: () => _models.first,
    );
    setState(() {
      _selectedModel = found;
      _currentSection = DashboardSection.chat;
    });
  }

  Future<void> _loadInitialData() async {
    try {
      final models = await _chatService.getModels();
      final convs = await _chatService.getConversations();

      if (mounted) {
        setState(() {
          _models = models;
          if (models.isNotEmpty && _selectedModel == null) {
            _selectedModel = models.firstWhere(
              (m) => m.isDefaultChat || m.isDefaultFree || m.isFreeEnabled,
              orElse: () => models.first,
            );
          }
          _conversations = convs;
        });

        if (convs.isNotEmpty && _currentConversationId == null) {
          _loadConversation(convs.first.id);
        }

        AnnouncementService().init().then((_) {
          _onActiveAnnouncementChanged();
        }).ignore();
      }
    } catch (e) {
      if (mounted) {
        AeroXToast.show(
          context,
          'Failed to load models or conversations',
          type: AeroXToastType.error,
        );
      }
    }
  }

  Future<void> _loadConversation(String conversationId) async {
    setState(() {
      _currentConversationId = conversationId;
      _isLoadingHistory = true;
      _currentSection = DashboardSection.chat;
    });

    try {
      final msgs = await _chatService.getMessages(conversationId);
      if (mounted) {
        setState(() {
          _messages = msgs;
          _isLoadingHistory = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
        AeroXToast.show(
          context,
          'Failed to load messages',
          type: AeroXToastType.error,
        );
      }
    }
  }

  void _startNewConversation() {
    _handleStopGeneration();
    setState(() {
      _currentConversationId = null;
      _messages = [];
      _pendingAttachments.clear();
      _matchingSlashCommands = [];
      _currentSection = DashboardSection.chat;
    });
    _inputFocusNode.requestFocus();
  }

  void _handleStopGeneration() {
    _chatService.cancelCurrentStream();
    if (_activeStreamingMsg != null) {
      _flushRemainingStreamBuffer(_activeStreamingMsg!);
      if (mounted) {
        setState(() {
          _activeStreamingMsg!.isStreaming = false;
          _activeStreamingMsg = null;
        });
      }
    }
  }

  void _onStreamDelta(ChatMessage assistantMsg, String delta) {
    _streamBuffer.write(delta);
    if (_streamBufferTimer == null || !_streamBufferTimer!.isActive) {
      _streamBufferTimer = Timer.periodic(const Duration(milliseconds: 35), (
        _,
      ) {
        if (_streamBuffer.isNotEmpty && mounted) {
          final chunk = _streamBuffer.toString();
          _streamBuffer.clear();
          setState(() {
            assistantMsg.content += chunk;
          });
          _scrollDuringStreaming();
        }
      });
    }
  }

  void _flushRemainingStreamBuffer(ChatMessage assistantMsg) {
    _streamBufferTimer?.cancel();
    _streamBufferTimer = null;
    if (_streamBuffer.isNotEmpty && mounted) {
      final chunk = _streamBuffer.toString();
      _streamBuffer.clear();
      setState(() {
        assistantMsg.content += chunk;
      });
    }
  }

  void _scrollDuringStreaming() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final distanceFromBottom = pos.maxScrollExtent - pos.pixels;
    if (distanceFromBottom < 160) {
      _scrollController.jumpTo(pos.maxScrollExtent);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: AeroXAnimations.normal,
          curve: AeroXAnimations.easeOut,
        );
      }
    });
  }

  Future<void> _handleCameraCapture() async {
    try {
      final item = await _fileService.captureFromCamera();
      if (item != null && mounted) {
        setState(() => _pendingAttachments.add(item));
      }
    } catch (e) {
      if (mounted) {
        AeroXToast.show(
          context,
          e.toString().replaceAll('Exception: ', ''),
          type: AeroXToastType.error,
        );
      }
    }
  }

  Future<void> _handleFileAttachment() async {
    try {
      final items = await _fileService.pickFiles();
      if (items.isNotEmpty && mounted) {
        setState(() => _pendingAttachments.addAll(items));
      }
    } catch (e) {
      if (mounted) {
        AeroXToast.show(
          context,
          e.toString().replaceAll('Exception: ', ''),
          type: AeroXToastType.error,
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty && _pendingAttachments.isEmpty) return;

    if (_selectedModel == null) {
      AeroXToast.show(
        context,
        'Please select an AI model first',
        type: AeroXToastType.error,
      );
      return;
    }

    List<AttachmentItem> uploaded = [];
    if (_pendingAttachments.isNotEmpty) {
      setState(() {
        for (var a in _pendingAttachments) {
          a.isUploading = true;
        }
      });

      for (var a in _pendingAttachments) {
        try {
          final item = await _fileService.uploadAttachment(a);
          uploaded.add(item);
        } catch (e) {
          if (mounted) {
            AeroXToast.show(
              context,
              'Upload failed: ${a.originalName}',
              type: AeroXToastType.error,
            );
          }
        }
      }
    }

    String fullMessageText = text;
    if (uploaded.isNotEmpty) {
      final links = uploaded
          .map(
            (u) => u.isImage
                ? '![${u.originalName}](${u.url})'
                : '[${u.originalName}](${u.url})',
          )
          .join('\n');
      fullMessageText = text.isEmpty ? links : '$text\n\n$links';
    }

    final userMsg = ChatMessage(
      id: const Uuid().v4(),
      conversationId: _currentConversationId,
      role: 'user',
      content: fullMessageText,
      createdAt: DateTime.now(),
      attachments: uploaded,
    );

    _inputController.clear();
    setState(() {
      _pendingAttachments.clear();
      _matchingSlashCommands = [];
      _currentSection = DashboardSection.chat;
    });

    final assistantMsg = ChatMessage(
      id: const Uuid().v4(),
      conversationId: _currentConversationId,
      role: 'assistant',
      content: '',
      createdAt: DateTime.now(),
      isStreaming: true,
    );

    setState(() {
      _messages.add(userMsg);
      _messages.add(assistantMsg);
    });
    _scrollToBottom();

    await _streamResponse(fullMessageText, assistantMsg: assistantMsg);
  }

  Future<void> _streamResponse(
    String fullMessageText, {
    required ChatMessage assistantMsg,
  }) async {
    _activeStreamingMsg = assistantMsg;
    _streamBuffer.clear();

    final historyPayload = _messages
        .where((m) => m.id != assistantMsg.id && m.content.isNotEmpty)
        .map((m) => {'role': m.role, 'content': m.content})
        .toList();

    await _chatService.streamMessage(
      modelId: _selectedModel!.id,
      conversationId: _currentConversationId,
      message: fullMessageText,
      history: historyPayload,
      onStart: (convId, mName) {
        if (mounted) {
          setState(() {
            _currentConversationId = convId;
          });
        }
      },
      onDelta: (delta) {
        _onStreamDelta(assistantMsg, delta);
      },
      onDone: (data) async {
        _flushRemainingStreamBuffer(assistantMsg);
        if (mounted) {
          setState(() {
            assistantMsg.isStreaming = false;
            _activeStreamingMsg = null;
          });
          _scrollToBottom();
          final convs = await _chatService.getConversations();
          if (mounted) setState(() => _conversations = convs);
        }
      },
      onError: (err) {
        _flushRemainingStreamBuffer(assistantMsg);
        if (mounted) {
          setState(() {
            assistantMsg.isStreaming = false;
            assistantMsg.isError = true;
            _activeStreamingMsg = null;
            if (assistantMsg.content.isEmpty) {
              assistantMsg.content = '⚠️ Request error: $err';
            }
          });
          _scrollToBottom();
          AeroXToast.show(context, err, type: AeroXToastType.error);
        }
      },
    );
  }

  void _retryMessage(ChatMessage failedAssistantMsg) {
    if (_chatService.isStreaming) return;
    final idx = _messages.indexOf(failedAssistantMsg);
    if (idx > 0) {
      final userMsg = _messages[idx - 1];
      if (userMsg.isUser) {
        setState(() {
          failedAssistantMsg.content = '';
          failedAssistantMsg.isError = false;
          failedAssistantMsg.isStreaming = true;
        });
        _streamResponse(userMsg.content, assistantMsg: failedAssistantMsg);
      }
    }
  }

  void _regenerateMessage(ChatMessage assistantMsg) {
    if (_chatService.isStreaming) return;
    final idx = _messages.indexOf(assistantMsg);
    if (idx > 0) {
      final userMsg = _messages[idx - 1];
      if (userMsg.isUser) {
        setState(() {
          assistantMsg.content = '';
          assistantMsg.isError = false;
          assistantMsg.isStreaming = true;
        });
        _streamResponse(userMsg.content, assistantMsg: assistantMsg);
      }
    }
  }

  void _handleLogout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context)
          .pushReplacement(AeroXAnimations.fadeScaleRoute(const AuthScreen()));
    }
  }

  void _toggleSidebar() {
    setState(() => _isSidebarCollapsed = !_isSidebarCollapsed);
    if (_isSidebarCollapsed) {
      _sidebarWidthController.forward();
    } else {
      _sidebarWidthController.reverse();
    }
  }

  void _openSettings() {
    Navigator.push(
      context,
      AeroXAnimations.slideUpRoute(
        SettingsScreen(
          currentUser: _authService.currentUser.value,
          onUserUpdated: () {
            _loadInitialData();
            setState(() {});
          },
        ),
      ),
    );
  }

  void _openRedeemDialog() {
    RedeemVoucherDialog.show(
      context,
      onSuccess: () {
        setState(() {});
      },
    );
  }

  Future<void> _renameConversation(ConversationItem conv) async {
    final controller = TextEditingController(text: conv.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AeroXColors.bgElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Rename Conversation',
          style: AeroXTheme.heading(fontSize: 18, color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AeroXTheme.body(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter new conversation title',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: AeroXTheme.body(color: AeroXColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(
              'Save',
              style: AeroXTheme.body(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );

    if (newTitle != null && newTitle.isNotEmpty && newTitle != conv.title) {
      try {
        await _chatService.renameConversation(conv.id, newTitle);
        final updated = await _chatService.getConversations();
        if (mounted) setState(() => _conversations = updated);
        if (mounted) {
          AeroXToast.show(
            context,
            'Conversation renamed',
            type: AeroXToastType.success,
          );
        }
      } catch (e) {
        if (mounted) {
          AeroXToast.show(
            context,
            'Failed to rename conversation',
            type: AeroXToastType.error,
          );
        }
      }
    }
  }

  // ─── Build Method ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 860;

    return Scaffold(
      backgroundColor: AeroXColors.bgPrimary,
      drawer: isDesktop ? null : _buildMobileDrawer(),
      body: AnimatedBuilder(
        animation: _entranceController,
        builder: (context, _) {
          return Row(
            children: [
              // Desktop Deep Black Sidebar
              if (isDesktop)
                AnimatedBuilder(
                  animation: _sidebarWidthController,
                  builder: (context, _) {
                    return ClipRect(
                      child: SizedBox(
                        width: _sidebarWidthAnim.value,
                        child: FadeTransition(
                          opacity: _sidebarFade,
                          child: SlideTransition(
                            position: _sidebarSlide,
                            child: _buildSidebarContent(),
                          ),
                        ),
                      ),
                    );
                  },
                ),

              // Main Active Section Area
              Expanded(
                child: Container(
                  color: AeroXColors.bgPrimary,
                  child: Column(
                    children: [
                      FadeTransition(
                        opacity: _topBarFade,
                        child: _buildTopBar(isDesktop),
                      ),
                      Expanded(
                        child: FadeTransition(
                          opacity: _chatAreaFade,
                          child: _buildActiveSectionView(),
                        ),
                      ),
                      if (_currentSection == DashboardSection.chat)
                        FadeTransition(
                          opacity: _inputFade,
                          child: SlideTransition(
                            position: _inputSlide,
                            child: _buildFloatingComposer(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Top Bar ────────────────────────────────────────────────────────

  Widget _buildTopBar(bool isDesktop) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallPhone = screenWidth <= 430;
    final isUltraNarrow = screenWidth <= 360;
    final horizontalPadding = isUltraNarrow
        ? 6.0
        : (isSmallPhone ? 10.0 : 16.0);
    final iconSpacing = isUltraNarrow ? 2.0 : (isSmallPhone ? 4.0 : 8.0);
    final user = _authService.currentUser.value;
    final packageName = user?.packageName ?? 'Free';

    return Container(
      decoration: const BoxDecoration(
        color: AeroXColors.bgPrimary,
        border: Border(
          bottom: BorderSide(color: AeroXColors.borderPrimary, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 60,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Row(
            children: [
              if (!isDesktop) ...[
                Builder(
                  builder: (ctx) => _AnimatedIconButton(
                    icon: Icons.menu,
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                    tooltip: 'Open Navigation',
                    size: isUltraNarrow ? 18 : 20,
                    padding: isSmallPhone ? const EdgeInsets.all(4) : null,
                    constraints: isSmallPhone
                        ? const BoxConstraints(minWidth: 32, minHeight: 32)
                        : null,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 28,
                  height: 28,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF222222)),
                  ),
                  child: Image.asset(
                    'assets/images/logo_icon.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ] else
                _AnimatedIconButton(
                  icon: _isSidebarCollapsed ? Icons.menu_open : Icons.menu,
                  onPressed: _toggleSidebar,
                  tooltip: _isSidebarCollapsed
                      ? 'Expand sidebar'
                      : 'Collapse sidebar',
                ),

              SizedBox(width: iconSpacing),

              // Model Selector Pill in Topbar
              Expanded(
                child: _ModelSelectorPill(
                  selectedModel: _selectedModel,
                  isCompact: isSmallPhone,
                  onTap: () {
                    if (_models.isNotEmpty) {
                      ModelSelectorModal.show(
                        context,
                        models: _models,
                        selectedModelId: _selectedModel?.id ?? '',
                        onSelect: (m) => setState(() => _selectedModel = m),
                      );
                    }
                  },
                ),
              ),

              if (isDesktop) ...[
                const SizedBox(width: 10),
                // 5-Hour Usage Meter Pill (matches web .topbar-usage)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AeroXColors.bgSecondary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AeroXColors.borderPrimary),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AeroXColors.bgElevated,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AeroXColors.borderFocus),
                        ),
                        child: Text(
                          packageName,
                          style: AeroXTheme.tech(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '0/25 req',
                        style: AeroXTheme.tech(
                          fontSize: 11,
                          color: AeroXColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '⏱ 5h 0m',
                        style: AeroXTheme.tech(
                          fontSize: 11,
                          color: AeroXColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ] else ...[
                SizedBox(width: iconSpacing),
              ],

              // Copy Chat Link Button (when conversation is active)
              if (_currentConversationId != null && !isUltraNarrow) ...[
                _AnimatedIconButton(
                  icon: Icons.link,
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: _currentConversationId!),
                    );
                    AeroXToast.show(
                      context,
                      'Conversation link copied to clipboard',
                      type: AeroXToastType.info,
                    );
                  },
                  tooltip: 'Copy link',
                  size: isUltraNarrow ? 16 : 18,
                  padding: isSmallPhone ? const EdgeInsets.all(4) : null,
                  constraints: isSmallPhone
                      ? const BoxConstraints(minWidth: 32, minHeight: 32)
                      : null,
                ),
                SizedBox(width: iconSpacing),
              ],

              // Notification Bell
              ValueListenableBuilder<int>(
                valueListenable: _notificationService.unreadCount,
                builder: (context, count, _) {
                  return Stack(
                    alignment: Alignment.topRight,
                    children: [
                      _AnimatedIconButton(
                        icon: Icons.notifications_none,
                        onPressed: () => NotificationDrawer.show(context),
                        tooltip: 'Notifications',
                        size: isUltraNarrow ? 18 : 20,
                        padding: isSmallPhone ? const EdgeInsets.all(4) : null,
                        constraints: isSmallPhone
                            ? const BoxConstraints(minWidth: 32, minHeight: 32)
                            : null,
                      ),
                      if (count > 0)
                        Positioned(
                          right: isSmallPhone ? 4 : 8,
                          top: isSmallPhone ? 4 : 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white,
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),

              SizedBox(width: iconSpacing),

              // New Chat quick topbar action
              _AnimatedIconButton(
                icon: Icons.add,
                onPressed: _startNewConversation,
                tooltip: 'New Chat',
                size: isUltraNarrow ? 18 : 20,
                padding: isSmallPhone ? const EdgeInsets.all(4) : null,
                constraints: isSmallPhone
                    ? const BoxConstraints(minWidth: 32, minHeight: 32)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Main Switcher between Sections ─────────────────────────────────

  Widget _buildActiveSectionView() {
    switch (_currentSection) {
      case DashboardSection.chat:
        return _buildChatArea();
      case DashboardSection.models:
        return _buildModelsDirectory();
      case DashboardSection.usage:
        return _buildUsageAnalytics();
    }
  }

  // ─── Chat Area (Welcome or Messages Stream) ─────────────────────────

  Widget _buildChatArea() {
    if (_isLoadingHistory) {
      return _buildChatSkeleton();
    }

    if (_messages.isEmpty) {
      return _buildPilotWelcome();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 14, bottom: 28),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        return ChatBubble(
          message: msg,
          modelName: _selectedModel?.publicName,
          onRetry: () => _retryMessage(msg),
          onRegenerate: () => _regenerateMessage(msg),
        );
      },
    );
  }

  /// Dark shimmer skeleton loader for conversation history
  Widget _buildChatSkeleton() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        _buildSkeletonMessage(isUser: true, width: 220),
        const SizedBox(height: 18),
        _buildSkeletonMessage(isUser: false, width: 360),
        const SizedBox(height: 18),
        _buildSkeletonMessage(isUser: true, width: 180),
        const SizedBox(height: 18),
        _buildSkeletonMessage(isUser: false, width: 300),
      ],
    );
  }

  Widget _buildSkeletonMessage({required bool isUser, required double width}) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: width),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF141414) : const Color(0xFF0D0D0D),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AeroXColors.borderPrimary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 10,
              width: width * 0.75,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 10,
              width: width * 0.5,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Pilot Welcome Screen (Matching 1:1 Website Chat Welcome) ────────

  Widget _buildPilotWelcome() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Celestial AI Emblem with pulsating ambient glow
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  final glow = 20.0 + (_pulseController.value * 25.0);
                  return Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AeroXColors.bgSecondary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AeroXColors.borderPrimary,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(
                            alpha: 0.04 + _pulseController.value * 0.05,
                          ),
                          blurRadius: glow,
                          spreadRadius: glow * 0.25,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(9),
                      child: Image.asset(
                        'assets/images/logo_icon.png',
                        fit: BoxFit.contain,
                        semanticLabel: 'AeroX AI logo',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 22),

              // Welcome Subtitle in Share Tech
              Text(
                'WELCOME TO AEROX AI',
                style: AeroXTheme.tech(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  color: AeroXColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),

              // Main Pilot Title in Lora Serif
              Text(
                'How Can I Assist You?',
                textAlign: TextAlign.center,
                style: AeroXTheme.heading(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 36),

              // 4 Interactive Suggestion Cards matching Reference Website
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 580;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildPilotCard(
                        title: 'Write a todo list for my day',
                        icon: Icons.checklist,
                        width: isWide
                            ? (constraints.maxWidth - 12) / 2
                            : double.infinity,
                      ),
                      _buildPilotCard(
                        title: 'Audit reverse proxy TLS certificate renewal pipeline',
                        icon: Icons.terminal,
                        width: isWide
                            ? (constraints.maxWidth - 12) / 2
                            : double.infinity,
                      ),
                      _buildPilotCard(
                        title: 'Scaffold async Redis token bucket rate limiter',
                        icon: Icons.timer_outlined,
                        width: isWide
                            ? (constraints.maxWidth - 12) / 2
                            : double.infinity,
                      ),
                      _buildPilotCard(
                        title: 'Generate photorealistic cyberpunk cityscape',
                        icon: Icons.brush_outlined,
                        width: isWide
                            ? (constraints.maxWidth - 12) / 2
                            : double.infinity,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPilotCard({
    required String title,
    required IconData icon,
    required double width,
  }) {
    return HoverScale(
      hoverScale: 1.02,
      hoverLift: -2.0,
      onTap: () {
        _inputController.text = title;
        _sendMessage();
      },
      child: Container(
        width: width,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AeroXColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AeroXColors.borderPrimary, width: 1),
          boxShadow: const [AeroXColors.shadowSm],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: AeroXTheme.body(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AeroXColors.bgSecondary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AeroXColors.borderSubtle),
              ),
              child: Icon(icon, size: 16, color: AeroXColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Floating Pill Composer (Matching Website Island) ───────────────

  Widget _buildFloatingComposer() {
    final isStreaming = _chatService.isStreaming;

    return Container(
      decoration: const BoxDecoration(
        color: AeroXColors.bgPrimary,
        border: Border(
          top: BorderSide(color: AeroXColors.borderPrimary, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Slash Command auto-complete tray
              if (_matchingSlashCommands.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  constraints: const BoxConstraints(maxHeight: 180),
                  decoration: BoxDecoration(
                    color: AeroXColors.bgElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AeroXColors.borderFocus),
                    boxShadow: const [AeroXColors.shadowMd],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _matchingSlashCommands.length,
                    separatorBuilder: (_, _) => const Divider(
                      color: AeroXColors.borderPrimary,
                      height: 1,
                    ),
                    itemBuilder: (context, idx) {
                      final cmd = _matchingSlashCommands[idx];
                      return _AnimatedSlashCommandTile(
                        command: cmd,
                        index: idx,
                        onTap: () => _applySlashCommand(cmd),
                      );
                    },
                  ),
                ),

              // Pending attachments tray
              AttachmentPreviewTray(
                attachments: _pendingAttachments,
                onRemove: (idx) =>
                    setState(() => _pendingAttachments.removeAt(idx)),
              ),

              // Floating Streaming Status Pill (matches v2 generation indicator)
              if (isStreaming)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF222222)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.04),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AeroXColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Generating response...',
                        style: AeroXTheme.tech(
                          fontSize: 11,
                          color: AeroXColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: _handleStopGeneration,
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: Text(
                            'Stop',
                            style: AeroXTheme.tech(
                              fontSize: 11,
                              color: AeroXColors.textTertiary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Floating Composer Island
              Container(
                decoration: BoxDecoration(
                  color: AeroXColors.bgInput,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AeroXColors.borderPrimary,
                    width: 1,
                  ),
                  boxShadow: const [AeroXColors.shadowMd],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    // Textarea Input
                    TextField(
                      controller: _inputController,
                      focusNode: _inputFocusNode,
                      maxLines: 5,
                      minLines: 1,
                      style: AeroXTheme.body(
                        fontSize: 14,
                        color: Colors.white,
                        height: 1.4,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Type a message — / for skills, @ for threads, or Queue',
                        hintStyle: AeroXTheme.body(
                          color: AeroXColors.textMuted,
                          fontSize: 13.5,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        filled: false,
                      ),
                      onSubmitted: (_) {
                        if (!isStreaming) _sendMessage();
                      },
                    ),

                    const SizedBox(height: 6),

                    // Controls Row: [Build / Plan modes], Attachments, Queue, and Send
                    Row(
                      children: [
                        // Modes Toggle [Build] [Plan]
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AeroXColors.bgSecondary,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AeroXColors.borderSubtle),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildComposerModePill('Build'),
                              _buildComposerModePill('Plan'),
                            ],
                          ),
                        ),

                        const Spacer(),

                        // Document Attachment
                        _AnimatedIconButton(
                          icon: Icons.attach_file,
                          onPressed: isStreaming ? null : _handleFileAttachment,
                          tooltip: 'Attach document',
                          size: 18,
                        ),

                        // Image / Camera Attachment
                        _AnimatedIconButton(
                          icon: Icons.camera_alt_outlined,
                          onPressed: isStreaming ? null : _handleCameraCapture,
                          tooltip: 'Take photo or upload image',
                          size: 18,
                        ),

                        // Queue Button with icon
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: InkWell(
                            onTap: () {
                              AeroXToast.show(
                                context,
                                'Task queued for execution',
                                type: AeroXToastType.info,
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AeroXColors.bgSecondary,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AeroXColors.borderPrimary,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.alarm,
                                    size: 13,
                                    color: AeroXColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Queue',
                                    style: AeroXTheme.tech(
                                      fontSize: 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),


                        // Send or Stop Button
                        AnimatedSwitcher(
                          duration: AeroXAnimations.fast,
                          child: isStreaming
                              ? _SendStopButton(
                                  key: const ValueKey('stop'),
                                  icon: Icons.stop,
                                  onPressed: _handleStopGeneration,
                                  tooltip: 'Stop generation',
                                )
                              : _SendStopButton(
                                  key: const ValueKey('send'),
                                  icon: Icons.arrow_upward,
                                  onPressed: _sendMessage,
                                  tooltip: 'Send message',
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Sub-bar Pill matching Reference Screenshot
              _buildComposerSubBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComposerModePill(String mode) {
    final isActive = _activeComposerMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _activeComposerMode = mode),
      child: AnimatedContainer(
        duration: AeroXAnimations.fast,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? AeroXColors.bgElevated : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          mode,
          style: AeroXTheme.body(
            fontSize: 11.5,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? Colors.white : AeroXColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildComposerSubBar() {
    final user = _authService.currentUser.value;
    final tier = user?.packageName ?? 'Free';

    return Row(
      children: [
        // Green live dot + Model trigger
        InkWell(
          onTap: () {
            if (_models.isNotEmpty) {
              ModelSelectorModal.show(
                context,
                models: _models,
                selectedModelId: _selectedModel?.id ?? '',
                onSelect: (m) => setState(() => _selectedModel = m),
              );
            }
          },
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4ADE80),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Color(0xFF4ADE80), blurRadius: 6),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _selectedModel?.publicName ?? 'AeroX Pro',
                  style: AeroXTheme.tech(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 8),
        Text(
          '•',
          style: TextStyle(color: AeroXColors.textTertiary, fontSize: 12),
        ),
        const SizedBox(width: 8),

        // Tier badge
        Text(
          tier,
          style: AeroXTheme.tech(
            fontSize: 11.5,
            color: AeroXColors.textSecondary,
          ),
        ),

        const SizedBox(width: 8),
        Text(
          '•',
          style: TextStyle(color: AeroXColors.textTertiary, fontSize: 12),
        ),
        const SizedBox(width: 8),

        // Window Timer
        Text(
          '⏱ 23:03',
          style: AeroXTheme.tech(
            fontSize: 11.5,
            color: AeroXColors.textTertiary,
          ),
        ),

        const SizedBox(width: 8),
        Text(
          '•',
          style: TextStyle(color: AeroXColors.textTertiary, fontSize: 12),
        ),
        const SizedBox(width: 8),

        // Upgrade Plan link
        GestureDetector(
          onTap: () {
            AeroXToast.show(
              context,
              'Upgrade to AeroX Pro for unlimited quotas',
              type: AeroXToastType.info,
            );
          },
          child: Text(
            'Upgrade Plan ›',
            style: AeroXTheme.tech(
              fontSize: 11.5,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const Spacer(),

        // Tune settings button
        _AnimatedIconButton(
          icon: Icons.tune,
          onPressed: () {
            if (_models.isNotEmpty) {
              ModelSelectorModal.show(
                context,
                models: _models,
                selectedModelId: _selectedModel?.id ?? '',
                onSelect: (m) => setState(() => _selectedModel = m),
              );
            }
          },
          tooltip: 'Model configuration',
          size: 16,
        ),
      ],
    );
  }

  // ─── Model Intelligence Directory View ──────────────────────────────

  Widget _buildModelsDirectory() {
    final query = _modelsFilter;
    final cat = _selectedCategory;

    final filtered = _models.where((m) {
      if (query.isNotEmpty) {
        final matches =
            m.publicName.toLowerCase().contains(query) ||
            (m.publicDescription ?? '').toLowerCase().contains(query) ||
            (m.badge ?? '').toLowerCase().contains(query);
        if (!matches) return false;
      }
      if (cat == 'coding') {
        return (m.badge ?? '').toLowerCase().contains('code') ||
            m.publicName.toLowerCase().contains('vector');
      }
      if (cat == 'reasoning') {
        return (m.badge ?? '').toLowerCase().contains('reason') ||
            m.publicName.toLowerCase().contains('reason');
      }
      if (cat == 'vision') {
        return m.supportsVision || m.isImageModel;
      }
      if (cat == 'fast') {
        return (m.badge ?? '').toLowerCase().contains('fast') ||
            (m.badge ?? '').toLowerCase().contains('speed') ||
            m.publicName.toLowerCase().contains('pulse');
      }
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Heading
          Text(
            'Model Intelligence Directory',
            style: AeroXTheme.heading(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Browse specialized neural intelligence architectures with detailed context limits, capability tags, and direct chat launch.',
            style: AeroXTheme.body(
              fontSize: 13.5,
              color: AeroXColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // Search and Filter row
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: AeroXColors.bgInput,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AeroXColors.borderPrimary),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search,
                        size: 16,
                        color: AeroXColors.textMuted,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _modelsSearchController,
                          style: AeroXTheme.body(
                            fontSize: 13,
                            color: Colors.white,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Search models by name or tag...',
                            hintStyle: TextStyle(
                              color: AeroXColors.textMuted,
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All Models', 'all'),
                _buildFilterChip('Coding', 'coding'),
                _buildFilterChip('Reasoning', 'reasoning'),
                _buildFilterChip('Vision', 'vision'),
                _buildFilterChip('Ultra-Fast', 'fast'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Grid / List of Models
          if (filtered.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text(
                  'No models found matching criteria',
                  style: AeroXTheme.body(color: AeroXColors.textTertiary),
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 740;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: filtered.map((m) {
                    final cardWidth = isWide
                        ? (constraints.maxWidth - 16) / 2
                        : double.infinity;
                    return _buildModelDirectoryCard(m, cardWidth);
                  }).toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String key) {
    final isSelected = _selectedCategory == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedCategory = key),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: AeroXAnimations.fast,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : AeroXColors.bgSecondary,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.white : AeroXColors.borderPrimary,
            ),
          ),
          child: Text(
            label,
            style: AeroXTheme.tech(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.black : AeroXColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModelDirectoryCard(AIModel model, double width) {
    final accent = AeroXColors.getModelColor(model.publicName, model.modelType);
    final icon = ModelSelectorModal.getModelIcon(
      model.publicName,
      model.modelType,
    );

    return HoverScale(
      hoverScale: 1.015,
      hoverLift: -2.0,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AeroXColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AeroXColors.borderPrimary, width: 1),
          boxShadow: const [AeroXColors.shadowSm],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top: Icon, Name, Badge
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accent.withValues(alpha: 0.3)),
                  ),
                  child: Icon(icon, size: 22, color: accent),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              model.publicName,
                              style: AeroXTheme.heading(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (model.badge != null &&
                              model.badge!.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            AeroXBadge(
                              text: model.badge!,
                              type: AeroXBadgeType.info,
                            ),
                          ],
                          if (model.isFreeEnabled) ...[
                            const SizedBox(width: 6),
                            const AeroXBadge(
                              text: 'FREE',
                              type: AeroXBadgeType.success,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        model.publicDescription ??
                            'High-performance AI model architecture.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AeroXTheme.body(
                          fontSize: 12,
                          color: AeroXColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Specs 4-item grid
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AeroXColors.bgSecondary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AeroXColors.borderSubtle),
              ),
              child: Row(
                children: [
                  Expanded(child: _buildSpecItem('Context', '128k tokens')),
                  Expanded(
                    child: _buildSpecItem(
                      'Cost',
                      '${model.creditCost.toStringAsFixed(1)} cr',
                    ),
                  ),
                  Expanded(
                    child: _buildSpecItem(
                      'Vision',
                      model.supportsVision ? '✓ Yes' : '— Text',
                    ),
                  ),
                  Expanded(
                    child: _buildSpecItem(
                      'Speed',
                      model.badge == 'FAST' ? 'Ultra-Low' : 'Fast',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Launch button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                onPressed: () {
                  setState(() {
                    _selectedModel = model;
                    _currentSection = DashboardSection.chat;
                  });
                  _inputFocusNode.requestFocus();
                  AeroXToast.show(
                    context,
                    'Switched active model to ${model.publicName}',
                    type: AeroXToastType.info,
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Start Chat with Model',
                      style: AeroXTheme.body(
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: Colors.black,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AeroXTheme.tech(
            fontSize: 10.5,
            color: AeroXColors.textTertiary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AeroXTheme.tech(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  // ─── Usage & Token Analytics View ───────────────────────────────────

  Widget _buildUsageAnalytics() {
    final user = _authService.currentUser.value;
    final totalCredits = user?.totalCredits ?? 0;
    final usedCredits = user?.usedCredits ?? 0;
    final availCredits = user?.availableCredits ?? 0;
    final packageName = user?.packageName ?? 'Free Tier';

    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 640;
    final isUltraNarrow = screenWidth <= 360;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isUltraNarrow ? 12 : (isCompact ? 16 : 28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;
              final refreshBtn = OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: AeroXColors.borderPrimary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
                onPressed: () async {
                  await _authService.refreshProfile();
                  if (!mounted) return;
                  setState(() {});
                  AeroXToast.show(
                    this.context,
                    'Data refreshed',
                    type: AeroXToastType.info,
                  );
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: Text(
                  'Refresh Data',
                  style: AeroXTheme.tech(fontSize: 12),
                ),
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Usage & Token Analytics',
                      style: AeroXTheme.heading(
                        fontSize: isUltraNarrow ? 20 : 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Monitor your credit balances, 5-hour rolling consumption window, and real-time request logs.',
                      style: AeroXTheme.body(
                        fontSize: 12.5,
                        color: AeroXColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    refreshBtn,
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Usage & Token Analytics',
                          style: AeroXTheme.heading(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Monitor your credit balances, 5-hour rolling consumption window, and real-time request logs.',
                          style: AeroXTheme.body(
                            fontSize: 13.5,
                            color: AeroXColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  refreshBtn,
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // 3 Metric Cards Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 740;
              final cardWidth = isWide
                  ? (constraints.maxWidth - 32) / 3
                  : constraints.maxWidth;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildMetricCard(
                    title: 'Available Balance',
                    value: availCredits.toStringAsFixed(1),
                    sub:
                        'Total: ${totalCredits.toStringAsFixed(1)} • Used: ${usedCredits.toStringAsFixed(1)}',
                    buttonLabel: 'Redeem Voucher',
                    onButtonTap: _openRedeemDialog,
                    width: cardWidth,
                    isCompact: isCompact,
                  ),
                  _buildMetricCard(
                    title: '5-Hour Window',
                    value: '0 / 25 req',
                    sub: '⏱ Resets in 5h 0m',
                    buttonLabel: 'View Quotas',
                    onButtonTap: () {},
                    width: cardWidth,
                    isCompact: isCompact,
                  ),
                  _buildMetricCard(
                    title: 'Subscription Tier',
                    value: packageName,
                    sub: 'Active & Verified',
                    buttonLabel: 'Upgrade Plan',
                    onButtonTap: () {
                      AeroXToast.show(
                        context,
                        'Choose a plan to upgrade',
                        type: AeroXToastType.info,
                      );
                    },
                    width: cardWidth,
                    isCompact: isCompact,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),

          // Quick Redeem Card
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompactCard = constraints.maxWidth < 640;
              if (isCompactCard) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AeroXColors.bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AeroXColors.borderPrimary),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AeroXColors.bgElevated,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AeroXColors.borderFocus,
                              ),
                            ),
                            child: const Icon(
                              Icons.card_giftcard,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Have a promo code or voucher?',
                              style: AeroXTheme.heading(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Redeem your voucher key to immediately grant bonus credits or unlock pro tiers.',
                        style: AeroXTheme.body(
                          fontSize: 12,
                          color: AeroXColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _openRedeemDialog,
                          child: Text(
                            'Redeem Code',
                            style: AeroXTheme.body(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AeroXColors.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AeroXColors.borderPrimary),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AeroXColors.bgElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AeroXColors.borderFocus),
                      ),
                      child: const Icon(
                        Icons.card_giftcard,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Have a promo code or voucher?',
                            style: AeroXTheme.heading(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Redeem your voucher key to immediately grant bonus credits or unlock pro tiers.',
                            style: AeroXTheme.body(
                              fontSize: 12.5,
                              color: AeroXColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                      onPressed: _openRedeemDialog,
                      child: Text(
                        'Redeem Code',
                        style: AeroXTheme.body(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String sub,
    required String buttonLabel,
    required VoidCallback onButtonTap,
    required double width,
    bool isCompact = false,
  }) {
    return Container(
      width: width,
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      decoration: BoxDecoration(
        color: AeroXColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AeroXColors.borderPrimary),
        boxShadow: const [AeroXColors.shadowSm],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AeroXTheme.tech(
              fontSize: 11.5,
              color: AeroXColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AeroXTheme.heading(
              fontSize: isCompact ? 24 : 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            sub,
            style: AeroXTheme.body(
              fontSize: 12,
              color: AeroXColors.textTertiary,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: AeroXColors.borderPrimary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: onButtonTap,
              child: Text(buttonLabel, style: AeroXTheme.tech(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Sidebar Drawer for Mobile ──────────────────────────────────────

  Widget _buildMobileDrawer() {
    return Drawer(
      backgroundColor: AeroXColors.bgPrimary,
      child: SafeArea(child: _buildSidebarContent()),
    );
  }

  // ─── Deep Black Sidebar Content (1:1 Web Parity) ─────────────────────

  Widget _buildSidebarContent() {
    final isDesktop = MediaQuery.of(context).size.width >= 860;
    final filteredConversations = _conversations.where((c) {
      if (_historyFilter.isEmpty) return true;
      return c.title.toLowerCase().contains(_historyFilter);
    }).toList();

    return Container(
      color: const Color(0xFF000000), // Deep black #000000
      child: Column(
        children: [
          // Sidebar Header: AeroX Logo (Caacupe One) + AI badge
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.1),
                            blurRadius: 8,
                            spreadRadius: 0.5,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 28,
                          height: 28,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AeroX',
                      style: AeroXTheme.display(
                        fontSize: 21,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111111),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: const Color(0xFF222222)),
                      ),
                      child: const Text(
                        'AI',
                        style: TextStyle(
                          color: Color(0xFFF4F4F5),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
                if (!isDesktop)
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AeroXColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
              ],
            ),
          ),

          // Deep Black "New chat" button matching web .new-chat-btn
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: HoverScale(
              hoverScale: 1.015,
              hoverLift: -1.0,
              onTap: () {
                if (!isDesktop) Navigator.pop(context);
                _startNewConversation();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D0D0D),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: const Color(0xFF1F1F1F)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add, size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'New chat',
                      style: AeroXTheme.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFF4F4F5),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF2A2A2A)),
                      ),
                      child: Text(
                        'Ctrl K',
                        style: AeroXTheme.tech(
                          fontSize: 10,
                          color: AeroXColors.textTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Navigation Links: Chats, Models, Usage, Settings
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                _buildSidebarNavLink(
                  icon: Icons.chat_bubble_outline,
                  label: 'Chats',
                  isActive: _currentSection == DashboardSection.chat,
                  onTap: () {
                    if (!isDesktop) Navigator.pop(context);
                    setState(() => _currentSection = DashboardSection.chat);
                  },
                ),
                _buildSidebarNavLink(
                  icon: Icons.auto_awesome_mosaic_outlined,
                  label: 'Models',
                  isActive: _currentSection == DashboardSection.models,
                  onTap: () {
                    if (!isDesktop) Navigator.pop(context);
                    setState(() => _currentSection = DashboardSection.models);
                  },
                ),
                _buildSidebarNavLink(
                  icon: Icons.bar_chart_outlined,
                  label: 'Usage',
                  isActive: _currentSection == DashboardSection.usage,
                  onTap: () {
                    if (!isDesktop) Navigator.pop(context);
                    setState(() => _currentSection = DashboardSection.usage);
                  },
                ),
                _buildSidebarNavLink(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  isActive: false,
                  onTap: () {
                    if (!isDesktop) Navigator.pop(context);
                    _openSettings();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Divider(color: Color(0xFF181818), height: 1),

          // Recent Chats Header & Search Input
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              children: [
                Text(
                  'RECENT',
                  style: AeroXTheme.tech(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: AeroXColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Search Box in History
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D0D),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: const Color(0xFF1C1C1C)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.search,
                    size: 14,
                    color: AeroXColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _historySearchController,
                      style: AeroXTheme.inter(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Search chats...',
                        hintStyle: TextStyle(
                          color: AeroXColors.textMuted,
                          fontSize: 12,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Chat History List
          Expanded(
            child: filteredConversations.isEmpty
                ? Center(
                    child: Text(
                      'No chats found',
                      style: AeroXTheme.inter(
                        color: AeroXColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    itemCount: filteredConversations.length,
                    itemBuilder: (context, index) {
                      final conv = filteredConversations[index];
                      final isSelected = conv.id == _currentConversationId;

                      return _ConversationRow(
                        title: conv.title,
                        modelName: conv.modelName,
                        isSelected: isSelected,
                        onTap: () {
                          if (!isDesktop) Navigator.pop(context);
                          _loadConversation(conv.id);
                        },
                        onRename: () => _renameConversation(conv),
                        onDelete: () async {
                          await _chatService.deleteConversation(conv.id);
                          final updated = await _chatService.getConversations();
                          if (mounted) {
                            setState(() {
                              _conversations = updated;
                              if (_currentConversationId == conv.id) {
                                _startNewConversation();
                              }
                            });
                          }
                        },
                      );
                    },
                  ),
          ),

          const Divider(color: Color(0xFF181818), height: 1),

          // Sidebar Footer: Redeem Voucher + User Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Redeem Voucher Button
                InkWell(
                  onTap: _openRedeemDialog,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F0F0F),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF222222)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.confirmation_number_outlined,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Redeem Voucher',
                          style: AeroXTheme.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          '✦',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // User Row
                ValueListenableBuilder<User?>(
                  valueListenable: _authService.currentUser,
                  builder: (context, user, _) {
                    if (user == null) return const SizedBox.shrink();

                    return Row(
                      children: [
                        // Avatar Circle
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1C1C),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF2E2E2E)),
                          ),
                          child: Center(
                            child: Text(
                              user.username.isNotEmpty
                                  ? user.username[0].toUpperCase()
                                  : 'U',
                              style: AeroXTheme.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Name & Credits
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AeroXTheme.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.5,
                                ),
                              ),
                              Row(
                                children: [
                                  const Text(
                                    '✦ ',
                                    style: TextStyle(
                                      color: Color(0xFF4ADE80),
                                      fontSize: 10,
                                    ),
                                  ),
                                  Flexible(
                                    child: Text(
                                      '${user.availableCredits.toStringAsFixed(1)} credits',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: AeroXTheme.tech(
                                        color: AeroXColors.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Logout button
                        _AnimatedIconButton(
                          icon: Icons.logout,
                          onPressed: _handleLogout,
                          tooltip: 'Sign out',
                          size: 16,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarNavLink({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return HoverScale(
      hoverScale: 1.01,
      hoverLift: 0,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF141414) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive ? Border.all(color: const Color(0xFF222222)) : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.white : AeroXColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: AeroXTheme.inter(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? Colors.white : AeroXColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Conversation Row Tile with Rename & Delete Actions ───────────────

class _ConversationRow extends StatefulWidget {
  final String title;
  final String? modelName;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _ConversationRow({
    required this.title,
    this.modelName,
    required this.isSelected,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  @override
  State<_ConversationRow> createState() => _ConversationRowState();
}

class _ConversationRowState extends State<_ConversationRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AeroXAnimations.fast,
          margin: const EdgeInsets.only(bottom: 3),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? const Color(0xFF141414)
                : (_isHovered ? const Color(0xFF0F0F0F) : Colors.transparent),
            borderRadius: BorderRadius.circular(7),
            border: widget.isSelected
                ? Border.all(color: const Color(0xFF282828))
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AeroXTheme.inter(
                    fontSize: 12.5,
                    fontWeight: widget.isSelected
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: widget.isSelected || _isHovered
                        ? Colors.white
                        : AeroXColors.textSecondary,
                  ),
                ),
              ),
              if (_isHovered || widget.isSelected) ...[
                GestureDetector(
                  onTap: widget.onRename,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 13,
                      color: AeroXColors.textSecondary,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: widget.onDelete,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      Icons.delete_outline,
                      size: 13,
                      color: AeroXColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Sub-Widgets & Helpers ────────────────────────────────────────────

class _AnimatedIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final double size;
  final EdgeInsetsGeometry? padding;
  final BoxConstraints? constraints;

  const _AnimatedIconButton({
    required this.icon,
    this.onPressed,
    this.tooltip = '',
    this.size = 20,
    this.padding,
    this.constraints,
  });

  @override
  State<_AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<_AnimatedIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.08 : 1.0,
        duration: AeroXAnimations.fast,
        child: IconButton(
          icon: Icon(
            widget.icon,
            color: _isHovered ? Colors.white : AeroXColors.textSecondary,
            size: widget.size,
          ),
          onPressed: widget.onPressed,
          tooltip: widget.tooltip,
          padding: widget.padding ?? const EdgeInsets.all(8),
          constraints: widget.constraints,
          splashRadius: 20,
        ),
      ),
    );
  }
}

class _ModelSelectorPill extends StatefulWidget {
  final AIModel? selectedModel;
  final VoidCallback onTap;
  final bool isCompact;

  const _ModelSelectorPill({
    required this.selectedModel,
    required this.onTap,
    this.isCompact = false,
  });

  @override
  State<_ModelSelectorPill> createState() => _ModelSelectorPillState();
}

class _ModelSelectorPillState extends State<_ModelSelectorPill> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = AeroXColors.getModelColor(
      widget.selectedModel?.publicName ?? '',
      widget.selectedModel?.modelType,
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AeroXAnimations.fast,
          padding: EdgeInsets.symmetric(
            horizontal: widget.isCompact ? 6 : 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: _isHovered ? AeroXColors.bgHover : AeroXColors.bgElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isHovered
                  ? AeroXColors.borderFocus
                  : AeroXColors.borderPrimary,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.selectedModel?.isImageModel == true
                      ? Icons.brush
                      : Icons.auto_awesome,
                  size: 11,
                  color: accent,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.selectedModel?.publicName ?? 'Select Model',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: AeroXTheme.body(
                    fontSize: widget.isCompact ? 12 : 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              if (widget.selectedModel?.badge != null && !widget.isCompact) ...[
                const SizedBox(width: 4),
                AeroXBadge(
                  text: widget.selectedModel!.badge!,
                  type: AeroXBadgeType.info,
                ),
              ],
              const SizedBox(width: 2),
              const Icon(
                Icons.keyboard_arrow_down,
                size: 14,
                color: AeroXColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedSlashCommandTile extends StatelessWidget {
  final _SlashCommand command;
  final int index;
  final VoidCallback onTap;

  const _AnimatedSlashCommandTile({
    required this.command,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: AeroXColors.bgPrimary,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(command.icon, size: 15, color: Colors.white),
      ),
      title: Row(
        children: [
          Text(
            command.command,
            style: AeroXTheme.mono(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              command.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AeroXTheme.body(
                fontSize: 11.5,
                color: AeroXColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _SendStopButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  const _SendStopButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  State<_SendStopButton> createState() => _SendStopButtonState();
}

class _SendStopButtonState extends State<_SendStopButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Tooltip(
          message: widget.tooltip,
          child: AnimatedContainer(
            duration: AeroXAnimations.fast,
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: _isHovered
                  ? [
                      const BoxShadow(
                        color: Color(0x30FFFFFF),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Icon(widget.icon, color: Colors.black, size: 16),
          ),
        ),
      ),
    );
  }
}
