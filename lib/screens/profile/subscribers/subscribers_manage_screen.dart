// SubscribersManageScreen — creator-only management of their paid
// subscribers. Mirrors the Followers/Following/Friends pattern but
// has its own row shape (tier badge, expires hint) and an MRR figure
// surfaced in the AppBar subtitle.
//
// Cancel semantic = soft cancel (no refund). Subscriber keeps benefits
// until expires_at. A future feature will add pro-rated refund via the
// Tajiri Pay COA — out of scope for this screen.

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../l10n/app_strings_scope.dart';
import '../../../models/friend_models.dart';
import '../../../services/friend_service.dart';

enum SubscriberFilter { activeAll, newThisMonth, expiringSoon, churned }

class SubscribersManageScreen extends StatefulWidget {
  final int currentUserId;
  const SubscribersManageScreen({super.key, required this.currentUserId});

  @override
  State<SubscribersManageScreen> createState() =>
      _SubscribersManageScreenState();
}

class _SubscribersManageScreenState extends State<SubscribersManageScreen> {
  static const int _perPage = 30;
  static const int _bulkCap = 50;

  final FriendService _service = FriendService();
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  Timer? _searchDebounce;
  Timer? _bulkHintTimer;

  SubscriberInsights? _insights;
  SubscriberFilter _filter = SubscriberFilter.activeAll;
  String _sort = 'newest';
  String _query = '';

  final List<SubscriberEntry> _rows = [];
  int _page = 1;
  bool _loading = true;
  bool _appending = false;
  bool _hasMore = true;
  String? _error;

  bool _bulkMode = false;
  final Set<int> _selected = {}; // subscription_id (NOT subscriber_id)
  String? _bulkHint;

  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _refreshAll();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _searchCtrl.dispose();
    _searchDebounce?.cancel();
    _bulkHintTimer?.cancel();
    super.dispose();
  }

  String? _filterToParam(SubscriberFilter f) => switch (f) {
        SubscriberFilter.activeAll => null,
        SubscriberFilter.newThisMonth => 'new',
        SubscriberFilter.expiringSoon => 'expiring',
        SubscriberFilter.churned => 'churned',
      };

  Future<void> _refreshAll() async {
    setState(() {
      _loading = _rows.isEmpty;
      _error = null;
      _page = 1;
      _hasMore = true;
    });
    final results = await Future.wait([
      _service.getSubscriberInsights(creatorId: widget.currentUserId),
      _service.getOwnerSubscribers(
        creatorId: widget.currentUserId,
        page: 1,
        perPage: _perPage,
        q: _query.isEmpty ? null : _query,
        filter: _filterToParam(_filter),
        sort: _sort,
      ),
    ]);
    if (!mounted) return;
    final insights = results[0] as SubscriberInsights?;
    final list = results[1] as SubscriberListResult;
    setState(() {
      _insights = insights;
      _rows
        ..clear()
        ..addAll(list.entries);
      _hasMore = list.entries.length == _perPage;
      _loading = false;
      _error = list.success ? null : (list.message ?? 'Failed to load');
    });
  }

  void _onScroll() {
    if (_appending || !_hasMore) return;
    if (_scroll.position.pixels < _scroll.position.maxScrollExtent * 0.8) {
      return;
    }
    _appendNextPage();
  }

  Future<void> _appendNextPage() async {
    setState(() => _appending = true);
    final next = _page + 1;
    final list = await _service.getOwnerSubscribers(
      creatorId: widget.currentUserId,
      page: next,
      perPage: _perPage,
      q: _query.isEmpty ? null : _query,
      filter: _filterToParam(_filter),
      sort: _sort,
    );
    if (!mounted) return;
    setState(() {
      _appending = false;
      if (list.success) {
        _page = next;
        _rows.addAll(list.entries);
        _hasMore = list.entries.length == _perPage;
      }
    });
  }

  void _onSearchChanged(String text) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _query = text.trim();
      _refreshAll();
    });
  }

  void _onFilterTap(SubscriberFilter f) {
    setState(() =>
        _filter = (f == _filter) ? SubscriberFilter.activeAll : f);
    _refreshAll();
  }

  void _toggleSelect(int subscriptionId, {bool? force}) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    setState(() {
      final shouldAdd = force ?? !_selected.contains(subscriptionId);
      if (shouldAdd) {
        if (_selected.length >= _bulkCap) {
          _bulkHint = isSw
              ? 'Hadi $_bulkCap kwa wakati mmoja'
              : 'Up to $_bulkCap at a time';
          _bulkHintTimer?.cancel();
          _bulkHintTimer = Timer(const Duration(seconds: 2), () {
            if (mounted) setState(() => _bulkHint = null);
          });
          return;
        }
        _selected.add(subscriptionId);
      } else {
        _selected.remove(subscriptionId);
      }
    });
  }

  void _exitBulkMode() {
    setState(() {
      _bulkMode = false;
      _selected.clear();
      _bulkHint = null;
    });
  }

  // ── per-row actions ──

  Future<void> _onLongPressRow(SubscriberEntry e) async {
    HapticFeedback.heavyImpact();
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    final action = await showModalBottomSheet<_RowAction>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5E5),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.person_outline_rounded,
                  color: Color(0xFF1A1A1A)),
              title: Text(isSw ? 'Tazama wasifu' : 'View profile'),
              onTap: () => Navigator.of(sheetCtx).pop(_RowAction.view),
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline_rounded,
                  color: Color(0xFF1A1A1A)),
              title: Text(isSw ? 'Tuma ujumbe' : 'Message'),
              onTap: () => Navigator.of(sheetCtx).pop(_RowAction.message),
            ),
            if (e.status == 'active')
              ListTile(
                leading: const Icon(Icons.cancel_outlined,
                    color: Color(0xFFD32F2F)),
                title: Text(
                  isSw ? 'Sitisha usajili' : 'Cancel subscription',
                  style: const TextStyle(color: Color(0xFFD32F2F)),
                ),
                onTap: () => Navigator.of(sheetCtx).pop(_RowAction.cancel),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;
    switch (action) {
      case _RowAction.view:
        Navigator.of(context).pushNamed('/profile/${e.subscriberId}');
        break;
      case _RowAction.message:
        Navigator.of(context).pushNamed('/chat/${e.subscriberId}');
        break;
      case _RowAction.cancel:
        await _confirmAndCancel(e);
        break;
    }
  }

  Future<void> _confirmAndCancel(SubscriberEntry e) async {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    final handle =
        (e.username ?? '').isNotEmpty ? '@${e.username}' : e.fullName;
    final ok = await _confirmDanger(
      title: isSw ? 'Sitisha usajili' : 'Cancel subscription',
      body: isSw
          ? 'Sitisha usajili wa $handle? Hawatajulishwa, na watabaki na manufaa hadi $_expiresLine. Hakuna marejesho ya pesa.'
          : "Cancel $handle's subscription? They won't be notified, and benefits run until $_expiresLine. No refund will be issued.",
      confirmLabel: isSw ? 'Sitisha' : 'Cancel',
    );
    if (!ok) return;
    await _service.creatorCancelSubscription(
      creatorId: widget.currentUserId,
      subscriptionId: e.subscriptionId,
    );
    if (mounted) _refreshAll();
  }

  String get _expiresLine {
    // Just a generic phrase used in the dialog body.
    return AppStringsScope.of(context)?.isSwahili == true
        ? 'tarehe ya kumalizika kwa kipindi cha sasa'
        : 'the end of the current cycle';
  }

  Future<bool> _confirmDanger({
    required String title,
    required String body,
    required String confirmLabel,
  }) async {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(isSw ? 'Ghairi' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFD32F2F),
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _bulkConfirmCancel() async {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    final n = _selected.length;
    final ok = await _confirmDanger(
      title: isSw ? 'Sitisha wateja $n' : 'Cancel $n subscriptions',
      body: isSw
          ? 'Sitisha usajili wa wateja $n? Hawatajulishwa. Hakuna marejesho ya pesa. Watabaki na manufaa hadi tarehe ya kumalizika.'
          : "Cancel $n subscriptions? They won't be notified. No refunds will be issued. Subscribers keep benefits until each cycle ends.",
      confirmLabel: isSw ? 'Sitisha wote' : 'Cancel all',
    );
    if (!ok) return;
    HapticFeedback.mediumImpact();
    await _service.creatorBulkCancelSubscriptions(
      creatorId: widget.currentUserId,
      subscriptionIds: _selected.toList(),
    );
    if (!mounted) return;
    _exitBulkMode();
    await _refreshAll();
  }

  Future<void> _onExport() async {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    setState(() => _exporting = true);
    final path = await _service.exportSubscribersCsv(
        creatorId: widget.currentUserId);
    if (!mounted) return;
    setState(() => _exporting = false);
    if (path == null) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          content: Text(isSw ? 'Imeshindikana kuhamisha' : 'Export failed'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path)],
        text: isSw ? 'Wateja' : 'Subscribers',
      ),
    );
  }

  // ── build ──

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    final activeCount = _insights?.totalActive ?? 0;
    final mrr = _insights?.mrrTzs ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        leading: _bulkMode
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: _exitBulkMode,
              )
            : null,
        title: _bulkMode
            ? Text(
                isSw
                    ? '${_selected.length} wamechaguliwa'
                    : '${_selected.length} selected',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isSw ? 'Wateja' : 'Subscribers',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$activeCount ${isSw ? "wanaolipa" : "active"} · ${_formatTzs(mrr)} MRR',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
        actions: _bulkMode ? const [] : [_overflowMenu(isSw)],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF1A1A1A),
        onRefresh: _bulkMode ? () async {} : _refreshAll,
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildInsightsCard(isSw)),
            SliverToBoxAdapter(child: _buildSearchField(isSw)),
            if (_loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              )
            else if (_error != null)
              SliverToBoxAdapter(child: _buildErrorBlock(isSw))
            else if (_rows.isEmpty)
              SliverToBoxAdapter(child: _buildEmptyBlock(isSw))
            else ...[
              SliverFixedExtentList.builder(
                itemExtent: 72,
                itemCount: _rows.length,
                itemBuilder: (ctx, i) => _buildRow(_rows[i]),
              ),
              if (_appending)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: !_bulkMode
          ? null
          : _BulkBar(
              hint: _bulkHint,
              onCancel: _selected.isEmpty ? null : _bulkConfirmCancel,
            ),
    );
  }

  Widget _buildInsightsCard(bool isSw) {
    final loading = _insights == null;
    final i = _insights;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _pill(
            SubscriberFilter.activeAll,
            value: loading ? '–' : '${i!.totalActive}',
            label: isSw ? 'wanaolipa' : 'active',
            loading: loading,
          ),
          _pill(
            SubscriberFilter.newThisMonth,
            value: loading ? '+–' : '+${i!.newThisMonth}',
            label: isSw ? 'mwezi huu' : 'this month',
            loading: loading,
          ),
          _pill(
            SubscriberFilter.expiringSoon,
            value: loading ? '–' : '${i!.expiringSoon}',
            label: isSw ? 'wanaisha hivi karibuni' : 'expiring',
            loading: loading,
          ),
          _pill(
            SubscriberFilter.churned,
            value: loading ? '–' : '${i!.churned}',
            label: isSw ? 'wameondoka' : 'churned',
            loading: loading,
          ),
        ],
      ),
    );
  }

  Widget _pill(
    SubscriberFilter f, {
    required String value,
    required String label,
    required bool loading,
  }) {
    final isActive = _filter == f;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : () => _onFilterTap(f),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isActive
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.18),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(bool isSw) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchCtrl,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: isSw
              ? 'Tafuta kwa jina au @handle'
              : 'Search by name or @handle',
          prefixIcon:
              const Icon(Icons.search_rounded, color: Color(0xFF999999)),
          suffixIcon: _searchCtrl.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: Color(0xFF999999)),
                  onPressed: () {
                    _searchCtrl.clear();
                    _onSearchChanged('');
                  },
                ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _overflowMenu(bool isSw) {
    return PopupMenuButton<String>(
      icon: _exporting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF1A1A1A),
              ),
            )
          : const Icon(Icons.more_horiz_rounded),
      onSelected: (v) {
        switch (v) {
          case 'sort_newest':
            setState(() => _sort = 'newest');
            _refreshAll();
            break;
          case 'sort_oldest':
            setState(() => _sort = 'oldest');
            _refreshAll();
            break;
          case 'sort_name':
            setState(() => _sort = 'name');
            _refreshAll();
            break;
          case 'sort_expiring':
            setState(() => _sort = 'expiring');
            _refreshAll();
            break;
          case 'select':
            setState(() => _bulkMode = true);
            break;
          case 'export':
            _onExport();
            break;
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'sort_newest',
          child: _SortItem(
              active: _sort == 'newest', label: isSw ? 'Mpya' : 'Newest'),
        ),
        PopupMenuItem(
          value: 'sort_oldest',
          child: _SortItem(
              active: _sort == 'oldest', label: isSw ? 'Wa zamani' : 'Oldest'),
        ),
        PopupMenuItem(
          value: 'sort_name',
          child: _SortItem(active: _sort == 'name', label: 'A–Z'),
        ),
        PopupMenuItem(
          value: 'sort_expiring',
          child: _SortItem(
              active: _sort == 'expiring',
              label: isSw ? 'Wanaisha kwanza' : 'Expiring first'),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'select',
          child: Text(isSw ? 'Chagua' : 'Select'),
        ),
        PopupMenuItem(
          value: 'export',
          child: Text(isSw ? 'Hamisha CSV' : 'Export CSV'),
        ),
      ],
    );
  }

  Widget _buildRow(SubscriberEntry e) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    final isSelected = _selected.contains(e.subscriptionId);
    final avatarRadius = _bulkMode ? 16.0 : 20.0;

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () {
          if (_bulkMode) {
            _toggleSelect(e.subscriptionId);
          } else {
            Navigator.of(context).pushNamed('/profile/${e.subscriberId}');
          }
        },
        onLongPress: _bulkMode ? null : () => _onLongPressRow(e),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (_bulkMode) ...[
                Checkbox(
                  value: isSelected,
                  onChanged: (v) =>
                      _toggleSelect(e.subscriptionId, force: v),
                  activeColor: const Color(0xFF1A1A1A),
                ),
                const SizedBox(width: 4),
              ],
              _SubscriberAvatar(entry: e, radius: avatarRadius),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayName(e),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle(e, isSw),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ..._badge(e, isSw),
            ],
          ),
        ),
      ),
    );
  }

  String _displayName(SubscriberEntry e) {
    final n = e.fullName;
    return n.isEmpty ? (e.username ?? '') : n;
  }

  String _subtitle(SubscriberEntry e, bool isSw) {
    final handle = (e.username ?? '').isNotEmpty ? '@${e.username}' : '';
    final tier = e.tierName ?? '';
    final renew = e.autoRenew
        ? (isSw ? 'inajiongeza' : 'auto-renews')
        : (isSw ? 'haijirudii' : 'no auto-renew');
    final expiresAt = e.expiresAt;
    String tail = renew;
    if (expiresAt != null) {
      final diff = expiresAt.difference(DateTime.now()).inDays;
      if (e.status == 'active' && diff >= 0 && diff < 14) {
        tail = isSw
            ? 'inaisha siku $diff'
            : (diff == 0 ? 'expires today' : 'expires in ${diff}d');
      } else if (e.status != 'active') {
        tail = e.status;
      }
    }
    final parts = <String>[
      if (handle.isNotEmpty) handle,
      if (tier.isNotEmpty) tier,
      tail,
    ];
    return parts.join(' · ');
  }

  List<Widget> _badge(SubscriberEntry e, bool isSw) {
    if (e.status == 'cancelled' || e.status == 'expired') {
      return [_badgeBox(isSw ? 'Wametoka' : 'Churned', const Color(0xFFD32F2F))];
    }
    final expiresAt = e.expiresAt;
    if (e.status == 'active' &&
        !e.autoRenew &&
        expiresAt != null &&
        expiresAt.difference(DateTime.now()).inDays <= 7) {
      return [
        _badgeBox(isSw ? 'Inaisha' : 'Expiring', const Color(0xFFFFB300))
      ];
    }
    if (e.startedAt != null &&
        DateTime.now().difference(e.startedAt!).inDays < 30 &&
        e.status == 'active') {
      return [_badgeBox(isSw ? 'Mpya' : 'New', const Color(0xFF1A1A1A))];
    }
    return const [];
  }

  Widget _badgeBox(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
        ),
      );

  Widget _buildEmptyBlock(bool isSw) {
    final filtered =
        _query.isNotEmpty || _filter != SubscriberFilter.activeAll;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: Column(
        children: [
          Icon(Icons.workspace_premium_outlined,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            filtered
                ? (isSw ? 'Hakuna' : 'No results')
                : (isSw ? 'Hujapata wateja bado' : 'No subscribers yet'),
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            filtered
                ? ''
                : (isSw
                    ? 'Tengeneza viwango vya usajili kuwapata wateja wa kwanza'
                    : 'Set up subscription tiers to start earning'),
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            textAlign: TextAlign.center,
          ),
          if (filtered) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                _searchCtrl.clear();
                _query = '';
                setState(() => _filter = SubscriberFilter.activeAll);
                _refreshAll();
              },
              child: Text(isSw ? 'Futa kichungi' : 'Clear filter'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorBlock(bool isSw) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            _error ?? '',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _refreshAll,
            child: Text(isSw ? 'Jaribu tena' : 'Retry'),
          ),
        ],
      ),
    );
  }

  // Format TZS as "1.5M" / "450K" / "12,500" per playbook §161.
  String _formatTzs(double v) {
    if (v >= 1000000) {
      return '${(v / 1000000).toStringAsFixed(v >= 10000000 ? 0 : 1)}M TZS';
    }
    if (v >= 10000) {
      return '${(v / 1000).toStringAsFixed(0)}K TZS';
    }
    final s = v.toStringAsFixed(0);
    final reversed = s.split('').reversed.toList();
    final out = StringBuffer();
    for (var i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) out.write(',');
      out.write(reversed[i]);
    }
    return '${out.toString().split('').reversed.join('')} TZS';
  }
}

enum _RowAction { view, message, cancel }

class _SortItem extends StatelessWidget {
  final bool active;
  final String label;
  const _SortItem({required this.active, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      if (active)
        const Icon(Icons.check_rounded, size: 18, color: Color(0xFF1A1A1A))
      else
        const SizedBox(width: 18),
      const SizedBox(width: 8),
      Text(label),
    ]);
  }
}

class _SubscriberAvatar extends StatelessWidget {
  final SubscriberEntry entry;
  final double radius;
  const _SubscriberAvatar({required this.entry, required this.radius});

  @override
  Widget build(BuildContext context) {
    final url = entry.profilePhotoUrl;
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFFF0F0F0),
        backgroundImage: CachedNetworkImageProvider(url),
        onBackgroundImageError: (_, _) {},
      );
    }
    final n = entry.fullName.isNotEmpty
        ? entry.fullName[0]
        : (entry.username ?? '?');
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFE5E5E5),
      child: Text(
        n.isNotEmpty ? n[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: radius * 0.7,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1A1A1A),
        ),
      ),
    );
  }
}

class _BulkBar extends StatelessWidget {
  final String? hint;
  final VoidCallback? onCancel;
  const _BulkBar({required this.hint, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E5E5))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hint != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  hint!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFD32F2F),
                  ),
                ),
              ),
            SizedBox(
              height: 64,
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: onCancel,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFD32F2F),
                      ),
                      child: Text(
                        isSw ? 'Sitisha waliochaguliwa' : 'Cancel selected',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
