/// Model selection bottom sheet modal dialog for AeroX AI.
///
/// Features high-tech model accent styling, search filtering, capability tags,
/// and smooth selection micro-interactions mirroring the web model dropdown.
library;

import 'package:flutter/material.dart';
import '../models/ai_model.dart';
import '../theme/aerox_animations.dart';
import '../theme/aerox_colors.dart';
import '../theme/aerox_theme.dart';
import 'aerox_badge.dart';

/// Modal bottom sheet allowing users to browse and switch active AI models.
class ModelSelectorModal extends StatefulWidget {
  /// The list of available [AIModel] options.
  final List<AIModel> models;

  /// The identifier of the currently selected model.
  final String selectedModelId;

  /// Callback executed when the user chooses an [AIModel].
  final Function(AIModel model) onSelect;

  const ModelSelectorModal({
    super.key,
    required this.models,
    required this.selectedModelId,
    required this.onSelect,
  });

  /// Displays the modal bottom sheet over the given [context].
  static Future<void> show(
    BuildContext context, {
    required List<AIModel> models,
    required String selectedModelId,
    required Function(AIModel model) onSelect,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AeroXColors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) => ModelSelectorModal(
        models: models,
        selectedModelId: selectedModelId,
        onSelect: (m) {
          Navigator.pop(ctx);
          onSelect(m);
        },
      ),
    );
  }

  /// Resolves the characteristic icon for the given model name and type.
  static IconData getModelIcon(String name, [String? modelType]) {
    if (modelType == 'image') return Icons.brush_outlined;
    final n = name.toLowerCase();
    if (n.contains('flash')) return Icons.bolt;
    if (n.contains('pulse')) return Icons.graphic_eq;
    if (n.contains('velocity')) return Icons.fast_forward;
    if (n.contains('altitude')) return Icons.landscape;
    if (n.contains('apex')) return Icons.diamond_outlined;
    if (n.contains('vector')) return Icons.code;
    if (n.contains('synapse')) return Icons.hub_outlined;
    if (n.contains('stratos')) return Icons.all_inclusive;
    if (n.contains('quantum')) return Icons.blur_on;
    if (n.contains('nexus')) return Icons.grain;
    if (n.contains('ultra')) return Icons.local_fire_department;
    if (n.contains('core')) return Icons.star_outline;
    if (n.contains('pro')) return Icons.view_in_ar;
    if (n.contains('reason')) return Icons.psychology;
    if (n.contains('vision') || n.contains('omni')) return Icons.visibility_outlined;
    return Icons.auto_awesome;
  }

  @override
  State<ModelSelectorModal> createState() => _ModelSelectorModalState();
}

class _ModelSelectorModalState extends State<ModelSelectorModal> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = '';
  String _activeTab = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _filter.trim().toLowerCase();
    final filtered = widget.models.where((m) {
      // Tab filter
      if (_activeTab == 'chat' && m.isImageModel) return false;
      if (_activeTab == 'vision' && !m.supportsVision) return false;
      if (_activeTab == 'free' && !m.isFreeEnabled) return false;

      // Search query
      if (query.isEmpty) return true;
      return m.publicName.toLowerCase().contains(query) ||
          (m.publicDescription ?? '').toLowerCase().contains(query) ||
          (m.badge ?? '').toLowerCase().contains(query) ||
          m.capabilities.any((c) => c.toLowerCase().contains(query));
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
        maxWidth: 620,
      ),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AeroXColors.borderPrimary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Intelligence Model',
                        style: AeroXTheme.heading(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Browse neural architectures, capability flags, and performance tiers',
                        style: AeroXTheme.body(
                          fontSize: 12,
                          color: AeroXColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AeroXColors.textSecondary, size: 20),
                  onPressed: () => Navigator.pop(context),
                  splashRadius: 20,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: AeroXColors.bgInput,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AeroXColors.borderPrimary),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 16, color: AeroXColors.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: AeroXTheme.body(fontSize: 13, color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Search models, capabilities...',
                        hintStyle: TextStyle(color: AeroXColors.textMuted, fontSize: 13),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      onChanged: (val) => setState(() => _filter = val),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() => _filter = '');
                      },
                      child: const Icon(Icons.clear, size: 16, color: AeroXColors.textMuted),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Capability Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildFilterChip('all', 'All Models', Icons.grid_view_rounded),
                const SizedBox(width: 6),
                _buildFilterChip('chat', 'Chat / LLM', Icons.chat_bubble_outline),
                const SizedBox(width: 6),
                _buildFilterChip('vision', 'Vision', Icons.visibility_outlined),
                const SizedBox(width: 6),
                _buildFilterChip('free', 'Free Tier', Icons.card_giftcard_outlined),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Divider(color: AeroXColors.borderPrimary),

          // Models List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No models found matching current criteria',
                      style: AeroXTheme.body(color: AeroXColors.textTertiary, fontSize: 13),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final model = filtered[index];
                      final isSelected = model.id == widget.selectedModelId;
                      final accentColor = AeroXColors.getModelColor(model.publicName, model.modelType);
                      final iconData = ModelSelectorModal.getModelIcon(model.publicName, model.modelType);

                      return _ModelTile(
                        model: model,
                        isSelected: isSelected,
                        accentColor: accentColor,
                        iconData: iconData,
                        onTap: () => widget.onSelect(model),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, IconData icon) {
    final isActive = _activeTab == key;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive
              ? AeroXColors.primary.withValues(alpha: 0.16)
              : AeroXColors.bgSecondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? AeroXColors.primary.withValues(alpha: 0.6)
                : AeroXColors.borderPrimary,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isActive ? AeroXColors.primary : AeroXColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: AeroXTheme.tech(
                fontSize: 11,
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

class _ModelTile extends StatefulWidget {
  final AIModel model;
  final bool isSelected;
  final Color accentColor;
  final IconData iconData;
  final VoidCallback onTap;

  const _ModelTile({
    required this.model,
    required this.isSelected,
    required this.accentColor,
    required this.iconData,
    required this.onTap,
  });

  @override
  State<_ModelTile> createState() => _ModelTileState();
}

class _ModelTileState extends State<_ModelTile> {
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AeroXColors.bgHover
                : (_isHovered ? AeroXColors.bgCard : AeroXColors.bgSecondary),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected
                  ? widget.accentColor.withValues(alpha: 0.6)
                  : (_isHovered ? AeroXColors.borderFocus : AeroXColors.borderPrimary),
              width: widget.isSelected ? 1.5 : 1,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: widget.accentColor.withValues(alpha: 0.15),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Model Icon box
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: widget.accentColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  widget.iconData,
                  size: 20,
                  color: widget.accentColor,
                ),
              ),
              const SizedBox(width: 12),

              // Title, badge, and description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Text(
                          widget.model.publicName,
                          style: AeroXTheme.body(
                            fontSize: 14,
                            fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        if (widget.model.isImageModel)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AeroXColors.modelImage.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AeroXColors.modelImage.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              'PHOTO',
                              style: AeroXTheme.tech(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AeroXColors.modelImage,
                              ),
                            ),
                          ),
                        if (widget.model.badge != null && widget.model.badge!.isNotEmpty)
                          AeroXBadge(
                            text: widget.model.badge!,
                            type: widget.isSelected ? AeroXBadgeType.info : AeroXBadgeType.neutral,
                          ),
                        if (widget.model.supportsVision && !widget.model.isImageModel)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              'VISION',
                              style: AeroXTheme.tech(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFC084FC),
                              ),
                            ),
                          ),
                        if (widget.model.isFreeEnabled)
                          const AeroXBadge(
                            text: 'FREE',
                            type: AeroXBadgeType.success,
                          ),
                      ],
                    ),
                    if (widget.model.publicDescription != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        widget.model.publicDescription!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AeroXTheme.tech(
                          fontSize: 11.5,
                          color: AeroXColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Credit cost and selection indicator
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${widget.model.creditCost.toStringAsFixed(1)} cr',
                    style: AeroXTheme.mono(
                      fontSize: 11,
                      color: AeroXColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (widget.isSelected)
                    Icon(Icons.check_circle, size: 16, color: widget.accentColor)
                  else
                    const SizedBox(width: 16, height: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
