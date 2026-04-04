import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/notification_models.dart';
import '../../services/notification_service.dart';
import '../../widgets/tajiri_app_bar.dart';

/// Full notification feed screen.
/// Paginated, grouped by date, swipe-to-delete, pull-to-refresh.
class NotificationsScreen extends StatefulWidget {
  final int currentUserId;

  const NotificationsScreen({super.key, required this.currentUserId});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<AppNotification> _notifications = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  bool _hasError = false;
  int _currentPage = 1;
  int _unreadCount = 0;

  // DESIGN.md palette
  static const Color _background = Color(0xFFFAFAFA);
  static const Color _primary = Color(0xFF1A1A1A);
  static const Color _secondary = Color(0xFF666666);
  static const Color _unreadDot = Color(0xFF1565C0);
  static const Color _deleteRed = Color(0xFFE53935);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _divider = Color(0xFFE0E0E0);

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final result = await NotificationService.getNotifications(
        widget.currentUserId,
        page: 1,
      );
      if (mounted) {
        setState(() {
          _notifications.clear();
          _notifications.addAll(result.notifications);
          _unreadCount = result.unreadCount;
          _hasMore = result.hasMore;
          _currentPage = 1;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final result = await NotificationService.getNotifications(
        widget.currentUserId,
        page: _currentPage + 1,
      );
      if (mounted) {
        setState(() {
          _notifications.addAll(result.notifications);
          _hasMore = result.hasMore;
          _currentPage++;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _markAllRead() async {
    final success = await NotificationService.markAllRead(widget.currentUserId);
    if (success && mounted) {
      setState(() {
        for (var i = 0; i < _notifications.length; i++) {
          if (!_notifications[i].isRead) {
            _notifications[i] = AppNotification(
              id: _notifications[i].id,
              type: _notifications[i].type,
              title: _notifications[i].title,
              body: _notifications[i].body,
              data: _notifications[i].data,
              readAt: DateTime.now(),
              createdAt: _notifications[i].createdAt,
            );
          }
        }
        _unreadCount = 0;
      });
    }
  }

  Future<void> _markRead(AppNotification notification) async {
    if (notification.isRead) return;
    final success = await NotificationService.markRead(
      notification.id,
      widget.currentUserId,
    );
    if (success && mounted) {
      final idx = _notifications.indexWhere((n) => n.id == notification.id);
      if (idx != -1) {
        setState(() {
          _notifications[idx] = AppNotification(
            id: notification.id,
            type: notification.type,
            title: notification.title,
            body: notification.body,
            data: notification.data,
            readAt: DateTime.now(),
            createdAt: notification.createdAt,
          );
          if (_unreadCount > 0) _unreadCount--;
        });
      }
    }
  }

  Future<void> _deleteNotification(AppNotification notification) async {
    final idx = _notifications.indexWhere((n) => n.id == notification.id);
    if (idx == -1) return;
    setState(() => _notifications.removeAt(idx));
    final success = await NotificationService.deleteNotification(
      notification.id,
      widget.currentUserId,
    );
    if (!success && mounted) {
      // Re-insert on failure
      setState(() => _notifications.insert(idx, notification));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete notification')),
        );
      }
    }
  }

  void _navigateByType(AppNotification notification) {
    _markRead(notification);
    final data = notification.data;
    switch (notification.type) {
      case 'new_message':
        final conversationId = data['conversation_id'];
        if (conversationId != null) {
          Navigator.pushNamed(context, '/chat/$conversationId');
        }
        break;
      case 'call_incoming':
      case 'call_missed':
        // Navigate to messages tab (calls sub-tab = index 2)
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
          arguments: {'initialIndex': 1, 'initialMessagesTab': 2},
        );
        break;
      case 'reaction':
      case 'comment':
      case 'like':
      case 'mention':
        final postId = data['post_id'];
        if (postId != null) {
          Navigator.pushNamed(context, '/post/$postId');
        }
        break;
      case 'follow':
        final userId = data['user_id'];
        if (userId != null) {
          Navigator.pushNamed(context, '/profile/$userId');
        }
        break;
      case 'share':
        final postId = data['post_id'];
        if (postId != null) {
          Navigator.pushNamed(context, '/post/$postId');
        }
        break;
      case 'group_invite':
      case 'group_update':
        final groupId = data['group_id'];
        if (groupId != null) {
          Navigator.pushNamed(context, '/group/$groupId');
        }
        break;
      default:
        // Just mark as read, no navigation
        break;
    }
  }

  /// Relative time label: "2m", "1h", "3d", etc.
  String _relativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w';
    return '${(diff.inDays / 30).floor()}mo';
  }

  /// Group notifications into date sections.
  List<_DateSection> _groupByDate(bool isSwahili) {
    if (_notifications.isEmpty) return [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final todayItems = <AppNotification>[];
    final yesterdayItems = <AppNotification>[];
    final earlierItems = <AppNotification>[];

    for (final n in _notifications) {
      final nDate = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      if (nDate == today || nDate.isAfter(today)) {
        todayItems.add(n);
      } else if (nDate == yesterday || (nDate.isAfter(yesterday) && nDate.isBefore(today))) {
        yesterdayItems.add(n);
      } else {
        earlierItems.add(n);
      }
    }

    final sections = <_DateSection>[];
    if (todayItems.isNotEmpty) {
      sections.add(_DateSection(
        label: isSwahili ? 'Leo' : 'Today',
        notifications: todayItems,
      ));
    }
    if (yesterdayItems.isNotEmpty) {
      sections.add(_DateSection(
        label: isSwahili ? 'Jana' : 'Yesterday',
        notifications: yesterdayItems,
      ));
    }
    if (earlierItems.isNotEmpty) {
      sections.add(_DateSection(
        label: isSwahili ? 'Mapema' : 'Earlier',
        notifications: earlierItems,
      ));
    }
    return sections;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final isSwahili = s?.languageCode == 'sw';

    return Scaffold(
      backgroundColor: _background,
      appBar: TajiriAppBar(
        title: isSwahili ? 'Arifa' : 'Notifications',
        actions: [
          if (_unreadCount > 0)
            TajiriAppBar.action(
              icon: HeroIcons.checkCircle,
              tooltip: isSwahili ? 'Soma zote' : 'Mark all read',
              onPressed: _markAllRead,
            ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(isSwahili),
      ),
    );
  }

  Widget _buildBody(bool isSwahili) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _primary));
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HeroIcon(
                HeroIcons.exclamationCircle,
                style: HeroIconStyle.outline,
                size: 56,
                color: _secondary,
              ),
              const SizedBox(height: 16),
              Text(
                isSwahili ? 'Hitilafu imetokea' : 'Something went wrong',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _primary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _loadNotifications,
                child: Text(
                  isSwahili ? 'Jaribu tena' : 'Try again',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HeroIcon(
                HeroIcons.bellSlash,
                style: HeroIconStyle.outline,
                size: 64,
                color: const Color(0xFF999999),
              ),
              const SizedBox(height: 16),
              Text(
                isSwahili ? 'Hakuna arifa' : 'No notifications',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _primary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                isSwahili
                    ? 'Utakapopata likes, maoni, na wafuatiliaji wataonekana hapa'
                    : 'When you get likes, comments, and follows they will show up here',
                style: const TextStyle(
                  fontSize: 12,
                  color: _secondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }

    final sections = _groupByDate(isSwahili);

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo.metrics.pixels >=
            scrollInfo.metrics.maxScrollExtent - 200) {
          _loadMore();
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: _loadNotifications,
        color: _primary,
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          itemCount: _itemCount(sections),
          itemBuilder: (context, index) =>
              _buildItem(context, index, sections, isSwahili),
        ),
      ),
    );
  }

  int _itemCount(List<_DateSection> sections) {
    int count = 0;
    for (final section in sections) {
      count += 1; // section header
      count += section.notifications.length;
    }
    if (_isLoadingMore) count += 1;
    return count;
  }

  Widget _buildItem(
    BuildContext context,
    int index,
    List<_DateSection> sections,
    bool isSwahili,
  ) {
    int cursor = 0;
    for (final section in sections) {
      // Section header
      if (index == cursor) {
        return _buildSectionHeader(section.label);
      }
      cursor++;

      // Notification tiles
      if (index < cursor + section.notifications.length) {
        final notification = section.notifications[index - cursor];
        return _buildNotificationTile(notification, isSwahili);
      }
      cursor += section.notifications.length;
    }

    // Loading more indicator
    if (_isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _primary,
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildSectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: _secondary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildNotificationTile(AppNotification notification, bool isSwahili) {
    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteNotification(notification),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: _deleteRed,
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
      child: Material(
        color: notification.isRead ? _background : _surface,
        child: InkWell(
          onTap: () => _navigateByType(notification),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: _divider, width: 0.5),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Leading icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: notification.iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    notification.icon,
                    size: 20,
                    color: notification.iconColor,
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (notification.title != null)
                        Text(
                          notification.title!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: notification.isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                            color: _primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (notification.body != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          notification.body!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: _secondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        _relativeTime(notification.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: _secondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Unread indicator
                if (!notification.isRead)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 8),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: _unreadDot,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Internal helper for grouping notifications by date section.
class _DateSection {
  final String label;
  final List<AppNotification> notifications;

  const _DateSection({required this.label, required this.notifications});
}
