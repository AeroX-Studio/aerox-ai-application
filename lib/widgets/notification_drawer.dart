/// Slide-over notification and announcement center modal bottom sheet.
///
/// Displays the full notification inbox, unread counts, mark-all-read actions,
/// and the unified Cross-Platform Announcement Center across native platforms.
library;

import 'package:flutter/material.dart';
import '../models/announcement_item.dart';
import '../models/notification_item.dart';
import '../services/announcement_service.dart';
import '../services/notification_service.dart';
import '../theme/aerox_colors.dart';
import 'aerox_badge.dart';
import 'announcement_dialog.dart';

/// Modal drawer displaying user notifications and the Announcement Center.
class NotificationDrawer extends StatefulWidget {
  /// Creates a [NotificationDrawer] widget.
  const NotificationDrawer({super.key});

  /// Displays the notification center modal bottom sheet over [context].
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AeroXColors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) => const NotificationDrawer(),
    );
  }

  @override
  State<NotificationDrawer> createState() => _NotificationDrawerState();
}

class _NotificationDrawerState extends State<NotificationDrawer> {
  int _activeTabIndex = 0; // 0 = Notifications, 1 = Announcement Center

  @override
  Widget build(BuildContext context) {
    final notifService = NotificationService();
    final annService = AnnouncementService();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
        maxWidth: 640,
      ),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          // Header with Tab Switcher & Close
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Segmented Tab Switcher
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AeroXColors.bgCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AeroXColors.borderPrimary),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tab 0: Notifications
                      _buildTabButton(
                        index: 0,
                        title: 'Notifications',
                        icon: Icons.notifications_outlined,
                        badgeCountNotifier: notifService.unreadCount,
                      ),
                      const SizedBox(width: 4),
                      // Tab 1: Announcement Center
                      _buildTabButton(
                        index: 1,
                        title: 'Announcements',
                        icon: Icons.campaign_outlined,
                        countWidget: ValueListenableBuilder<List<AnnouncementItem>>(
                          valueListenable: annService.announcements,
                          builder: (context, list, _) {
                            final unread = list.where((a) => !a.isRead).length;
                            if (unread == 0) return const SizedBox.shrink();
                            return Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$unread',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                Row(
                  children: [
                    if (_activeTabIndex == 0)
                      TextButton(
                        onPressed: () => notifService.markAllAsRead(),
                        child: const Text(
                          'Mark all read',
                          style: TextStyle(color: AeroXColors.textSecondary, fontSize: 12),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: AeroXColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),
          const Divider(color: AeroXColors.borderPrimary),

          // Content Area
          Expanded(
            child: _activeTabIndex == 0
                ? _buildNotificationsList(notifService, annService)
                : _buildAnnouncementCenterList(annService),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required String title,
    required IconData icon,
    ValueNotifier<int>? badgeCountNotifier,
    Widget? countWidget,
  }) {
    final isSelected = _activeTabIndex == index;

    return InkWell(
      onTap: () => setState(() => _activeTabIndex = index),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF232530) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AeroXColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : AeroXColors.textSecondary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (badgeCountNotifier != null)
              ValueListenableBuilder<int>(
                valueListenable: badgeCountNotifier,
                builder: (context, count, _) {
                  if (count == 0) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ?countWidget,
          ],
        ),
      ),
    );
  }

  // --- TAB 0: User Notifications Inbox ---
  Widget _buildNotificationsList(NotificationService notifService, AnnouncementService annService) {
    return ValueListenableBuilder<List<NotificationItem>>(
      valueListenable: notifService.notifications,
      builder: (context, list, _) {
        if (list.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none, size: 40, color: AeroXColors.textMuted),
                SizedBox(height: 12),
                Text(
                  'No notifications yet',
                  style: TextStyle(color: AeroXColors.textSecondary, fontSize: 14),
                ),
                SizedBox(height: 4),
                Text(
                  'Direct system alerts and updates will appear here.',
                  style: TextStyle(color: AeroXColors.textTertiary, fontSize: 12),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = list[index];

            AeroXBadgeType bType = AeroXBadgeType.info;
            if (item.type == 'update') bType = AeroXBadgeType.success;
            if (item.type == 'promo') bType = AeroXBadgeType.warning;
            if (item.type == 'alert') bType = AeroXBadgeType.error;

            return InkWell(
              onTap: () {
                notifService.markAsRead(item.id);
                _showDetailDialog(context, item, annService);
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: item.isRead ? AeroXColors.bgCard : AeroXColors.bgHover,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: item.isRead ? AeroXColors.borderPrimary : AeroXColors.borderFocus,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 5, right: 10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: item.isRead ? Colors.transparent : Colors.white,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: item.isRead ? FontWeight.w500 : FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              AeroXBadge(text: item.type.toUpperCase(), type: bType),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AeroXColors.textSecondary,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formatDate(item.createdAt),
                            style: const TextStyle(
                              color: AeroXColors.textTertiary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- TAB 1: Unified Announcement Center ---
  Widget _buildAnnouncementCenterList(AnnouncementService annService) {
    return ValueListenableBuilder<List<AnnouncementItem>>(
      valueListenable: annService.announcements,
      builder: (context, list, _) {
        if (list.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.campaign_outlined, size: 40, color: AeroXColors.textMuted),
                SizedBox(height: 12),
                Text(
                  'No announcements available',
                  style: TextStyle(color: AeroXColors.textSecondary, fontSize: 14),
                ),
                SizedBox(height: 4),
                Text(
                  'Model launches, new features, and updates will appear here.',
                  style: TextStyle(color: AeroXColors.textTertiary, fontSize: 12),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final ann = list[index];

            return InkWell(
              onTap: () {
                annService.markAsRead(ann.id);
                ann.isRead = true;
                setState(() {});
                AnnouncementDialog.show(context, ann);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ann.isRead ? AeroXColors.bgCard : const Color(0xFF191B24),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ann.isRead ? AeroXColors.borderPrimary : const Color(0xFF6366F1).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon or Cover Thumbnail
                    if (ann.coverImage != null && ann.coverImage!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: Image.network(
                            ann.coverImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(ann),
                          ),
                        ),
                      )
                    else
                      _buildFallbackIcon(ann),

                    const SizedBox(width: 12),

                    // Title & Description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  ann.title,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: ann.isRead ? FontWeight.w600 : FontWeight.w800,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: ann.isRead
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : const Color(0xFF6366F1).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  ann.type.replaceAll('_', ' ').toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: ann.isRead ? Colors.white70 : const Color(0xFF6366F1),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (ann.subtitle != null && ann.subtitle!.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              ann.subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AeroXColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          const SizedBox(height: 5),
                          Text(
                            ann.shortDescription ??
                                (ann.content?.replaceAll(RegExp(r'<[^>]*>'), '') ?? ''),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AeroXColors.textTertiary,
                              fontSize: 11.5,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFallbackIcon(AnnouncementItem ann) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AeroXColors.bgElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AeroXColors.borderPrimary),
      ),
      child: Center(
        child: Text(
          ann.icon.isNotEmpty ? ann.icon : '📢',
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }

  void _showDetailDialog(BuildContext context, NotificationItem item, AnnouncementService annService) {
    // Check if notification points to an announcement
    AnnouncementItem? linkedAnn;
    if (item.actionUrl != null && item.actionUrl!.startsWith('/announcements/')) {
      final annId = item.actionUrl!.replaceFirst('/announcements/', '').split('?').first;
      linkedAnn = annService.findById(annId);
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AeroXColors.bgElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(item.title, style: const TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.message,
              style: const TextStyle(color: AeroXColors.textSecondary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Received: ${_formatDate(item.createdAt)}',
              style: const TextStyle(color: AeroXColors.textTertiary, fontSize: 11),
            ),
          ],
        ),
        actions: [
          if (linkedAnn != null)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                AnnouncementDialog.show(context, linkedAnn!);
              },
              child: const Text('View Announcement'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}
