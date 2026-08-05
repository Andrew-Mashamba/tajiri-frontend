import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';

// DESIGN.md tokens
const Color _kBg = Color(0xFFFAFAFA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kText = Color(0xFF1A1A1A);
const Color _kMuted = Color(0xFF666666);
const Color _kFaint = Color(0xFF999999);
const Color _kDivider = Color(0xFFE0E0E0);

// ignore: unused_element
const BoxShadow _kCardShadow = BoxShadow(
  color: Color(0x1A000000),
  blurRadius: 4,
  offset: Offset(0, 2),
);

enum _NotifType { order, review, message, system, promo }

class _SellerNotif {
  final _NotifType type;
  final String title;
  final String body;
  final DateTime time;
  final bool read;

  const _SellerNotif({
    required this.type,
    required this.title,
    required this.body,
    required this.time,
    this.read = false,
  });
}

/// Seller notification feed — orders, reviews, messages, system alerts.
class SellerNotificationsScreen extends StatefulWidget {
  const SellerNotificationsScreen({super.key});

  @override
  State<SellerNotificationsScreen> createState() =>
      _SellerNotificationsScreenState();
}

class _SellerNotificationsScreenState
    extends State<SellerNotificationsScreen> {
  bool _loading = true;
  final List<_SellerNotif> _items = [];
  String _filter = 'all';

  static const _filters = ['all', 'orders', 'reviews', 'messages', 'system'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _loading = false;
      _items.addAll([
        _SellerNotif(
          type: _NotifType.order,
          title: 'New Order #1042',
          body: 'Amina N. ordered 2× Blue Leso — confirm within 24 h.',
          time: DateTime.now().subtract(const Duration(minutes: 8)),
        ),
        _SellerNotif(
          type: _NotifType.order,
          title: 'Order #1039 shipped',
          body: 'Your shipment has been picked up by Sendy.',
          time: DateTime.now().subtract(const Duration(hours: 2)),
          read: true,
        ),
        _SellerNotif(
          type: _NotifType.review,
          title: '5-star review received',
          body: '"Fast delivery, exactly as described!" – James K.',
          time: DateTime.now().subtract(const Duration(hours: 5)),
        ),
        _SellerNotif(
          type: _NotifType.message,
          title: 'New message from buyer',
          body: 'Fatuma A. asked: "Do you deliver to Mombasa?"',
          time: DateTime.now().subtract(const Duration(hours: 7)),
        ),
        _SellerNotif(
          type: _NotifType.system,
          title: 'Account verification approved',
          body: 'Your seller identity has been verified. You now have a badge.',
          time: DateTime.now().subtract(const Duration(days: 1)),
          read: true,
        ),
        _SellerNotif(
          type: _NotifType.promo,
          title: 'Flash Sale window available',
          body: 'Join the weekend Flash Sale — slots filling fast.',
          time: DateTime.now().subtract(const Duration(days: 2)),
          read: true,
        ),
      ]);
    });
  }

  List<_SellerNotif> get _filtered {
    if (_filter == 'all') return _items;
    final map = {
      'orders': _NotifType.order,
      'reviews': _NotifType.review,
      'messages': _NotifType.message,
      'system': _NotifType.system,
    };
    final type = map[_filter];
    if (type == null) return _items;
    return _items.where((n) => n.type == type).toList();
  }

  HeroIcons _iconFor(_NotifType t) {
    switch (t) {
      case _NotifType.order:
        return HeroIcons.shoppingBag;
      case _NotifType.review:
        return HeroIcons.star;
      case _NotifType.message:
        return HeroIcons.chatBubbleLeft;
      case _NotifType.system:
        return HeroIcons.bell;
      case _NotifType.promo:
        return HeroIcons.megaphone;
    }
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final unread = _items.where((n) => !n.read).length;
    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: _kSurface,
            elevation: 0,
            pinned: true,
            centerTitle: false,
            title: Row(children: [
              const Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _kText,
                ),
              ),
              if (unread > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _kText,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$unread',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ]),
            iconTheme: const IconThemeData(color: _kText),
            actions: [
              TextButton(
                onPressed: () => setState(() {
                  for (var i = 0; i < _items.length; i++) {
                    _items[i] = _SellerNotif(
                      type: _items[i].type,
                      title: _items[i].title,
                      body: _items[i].body,
                      time: _items[i].time,
                      read: true,
                    );
                  }
                }),
                child: const Text(
                  'Mark all read',
                  style: TextStyle(color: _kMuted, fontSize: 13),
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(44),
              child: SizedBox(
                height: 44,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final f = _filters[i];
                    final active = _filter == f;
                    return ChoiceChip(
                      label: Text(f[0].toUpperCase() + f.substring(1)),
                      selected: active,
                      onSelected: (_) => setState(() => _filter = f),
                      backgroundColor: _kSurface,
                      selectedColor: _kText,
                      labelStyle: TextStyle(
                        color: active ? Colors.white : _kMuted,
                        fontSize: 13,
                      ),
                      side: BorderSide(
                          color: active ? _kText : _kDivider, width: 1),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    );
                  },
                ),
              ),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_filtered.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HeroIcon(HeroIcons.bell,
                        style: HeroIconStyle.outline,
                        color: _kFaint,
                        size: 48),
                    const SizedBox(height: 12),
                    const Text('No notifications',
                        style: TextStyle(color: _kMuted, fontSize: 15)),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _NotifTile(
                  notif: _filtered[i],
                  icon: _iconFor(_filtered[i].type),
                  relTime: _relativeTime(_filtered[i].time),
                ),
                childCount: _filtered.length,
              ),
            ),
        ],
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  const _NotifTile({
    required this.notif,
    required this.icon,
    required this.relTime,
  });

  final _SellerNotif notif;
  final HeroIcons icon;
  final String relTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: notif.read ? _kBg : _kSurface,
      child: Column(
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            minVerticalPadding: 0,
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: notif.read
                    ? const Color(0xFFF0F0F0)
                    : const Color(0xFFE8E8E8),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: HeroIcon(icon,
                    style: HeroIconStyle.outline, color: _kText, size: 20),
              ),
            ),
            title: Text(
              notif.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    notif.read ? FontWeight.w400 : FontWeight.w600,
                color: _kText,
              ),
            ),
            subtitle: Text(
              notif.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: _kMuted),
            ),
            trailing: Text(
              relTime,
              style: const TextStyle(fontSize: 11, color: _kFaint),
            ),
          ),
          const Divider(height: 1, color: _kDivider),
        ],
      ),
    );
  }
}
