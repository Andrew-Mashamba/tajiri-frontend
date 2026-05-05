// Owner-only follower management page. Visitors continue to use the
// existing ProfileStatsBottomSheet — see profile_screen.dart line ~1118.
//
// Layout (top → bottom):
//   AppBar (title + count, overflow → Sort/Select/Export)
//   FollowersInsightsCard (4 tappable filter pills)
//   Search field (300ms debounced, server-side)
//   ListView of FollowerRow (long-press → action sheet, tap → /profile/{id})
//   Bottom action bar (visible only in bulk mode with ≥1 selected)

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../l10n/app_strings_scope.dart';
import '../../../models/friend_models.dart';
import '../../../services/friend_service.dart';
import 'follower_actions_sheet.dart';
import 'follower_row.dart';
import 'followers_insights_card.dart';

class FollowersManageScreen extends StatefulWidget {
  final int currentUserId;
  const FollowersManageScreen({super.key, required this.currentUserId});

  @override
  State<FollowersManageScreen> createState() => _FollowersManageScreenState();
}

class _FollowersManageScreenState extends State<FollowersManageScreen> {
  static const int _perPage = 30;
  static const int _bulkCap = 50;

  final FriendService _service = FriendService();
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  Timer? _searchDebounce;
  Timer? _bulkHintTimer;

  FollowerInsights? _insights;
  FollowerFilter _filter = FollowerFilter.total;
  String _sort = 'newest';
  String _query = '';

  final List<FollowUser> _rows = [];
  int _page = 1;
  bool _loading = true;
  bool _appending = false;
  bool _hasMore = true;
  String? _error;

  bool _bulkMode = false;
  final Set<int> _selected = {};
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

  // ── data ──────────────────────────────────────────────────────────────

  Future<void> _refreshAll() async {
    setState(() {
      _loading = _rows.isEmpty;
      _error = null;
      _page = 1;
      _hasMore = true;
    });
    final results = await Future.wait([
      _service.getFollowerInsights(userId: widget.currentUserId),
      _service.getOwnerFollowers(
        userId: widget.currentUserId,
        page: 1,
        perPage: _perPage,
        q: _query.isEmpty ? null : _query,
        filter: _filterToParam(_filter),
        sort: _sort,
      ),
    ]);
    if (!mounted) return;
    final insights = results[0] as FollowerInsights?;
    final list = results[1] as FollowListResult;
    setState(() {
      _insights = insights;
      _rows
        ..clear()
        ..addAll(list.users);
      _hasMore = list.users.length == _perPage;
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
    final list = await _service.getOwnerFollowers(
      userId: widget.currentUserId,
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
        _rows.addAll(list.users);
        _hasMore = list.users.length == _perPage;
      }
    });
  }

  String? _filterToParam(FollowerFilter f) => switch (f) {
        FollowerFilter.total => null,
        FollowerFilter.newThisWeek => 'new',
        FollowerFilter.inactive => 'inactive',
        FollowerFilter.mutualGap => 'mutual_gap',
      };

  // ── search / filter / sort ────────────────────────────────────────────

  void _onSearchChanged(String text) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _query = text.trim();
      _refreshAll();
    });
  }

  void _onFilterTap(FollowerFilter f) {
    setState(() => _filter = (f == _filter) ? FollowerFilter.total : f);
    _refreshAll();
  }

  // ── bulk mode ─────────────────────────────────────────────────────────

  void _toggleSelect(int id, {bool? force}) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    setState(() {
      final shouldAdd = force ?? !_selected.contains(id);
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
        _selected.add(id);
      } else {
        _selected.remove(id);
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

  // ── single-row actions ────────────────────────────────────────────────

  Future<void> _onLongPressRow(FollowUser f) async {
    HapticFeedback.heavyImpact();
    final action =
        await FollowerActionsSheet.show(context, isMuted: f.isMuted);
    if (action == null || !mounted) return;
    switch (action) {
      case FollowerAction.view:
        Navigator.of(context).pushNamed('/profile/${f.id}');
        break;
      case FollowerAction.mute:
        final ok = await _service.muteUser(
          userId: widget.currentUserId,
          mutedUserId: f.id,
        );
        if (ok && mounted) _refreshAll();
        break;
      case FollowerAction.unmute:
        final ok = await _service.unmuteUser(
          userId: widget.currentUserId,
          mutedUserId: f.id,
        );
        if (ok && mounted) _refreshAll();
        break;
      case FollowerAction.remove:
        await _confirmAndRemove(f);
        break;
      case FollowerAction.block:
        await _confirmAndBlock(f);
        break;
    }
  }

  Future<void> _confirmAndRemove(FollowUser f) async {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    final handle = (f.username ?? '').isNotEmpty ? '@${f.username}' : f.fullName;
    final ok = await _confirmDanger(
      title: isSw ? 'Ondoa mfuasi' : 'Remove follower',
      body: isSw
          ? 'Ondoa $handle? Hawatajulishwa, lakini wanaweza kukufuata tena.'
          : "Remove $handle? They won't be notified, but they can follow you again.",
      confirmLabel: isSw ? 'Ondoa' : 'Remove',
    );
    if (!ok) return;
    await _service.removeFollower(
      userId: widget.currentUserId,
      followerId: f.id,
    );
    if (mounted) _refreshAll();
  }

  Future<void> _confirmAndBlock(FollowUser f) async {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    final handle = (f.username ?? '').isNotEmpty ? '@${f.username}' : f.fullName;
    final ok = await _confirmDanger(
      title: isSw ? 'Zuia' : 'Block',
      body: isSw
          ? 'Zuia $handle? Hawataweza kupata wasifu au maudhui yako. Wewe pia hutaona yao.'
          : "Block $handle? They won't be able to find your profile or content. You won't see theirs.",
      confirmLabel: isSw ? 'Zuia' : 'Block',
    );
    if (!ok) return;
    // Reuse the bulk-block endpoint with a single-id list (frontend
    // doesn't have a single-block service today, and this matches how
    // we'd batch it anyway).
    await _service.bulkBlockUsers(
      userId: widget.currentUserId,
      ids: [f.id],
    );
    if (mounted) _refreshAll();
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

  // ── bulk actions ──────────────────────────────────────────────────────

  Future<void> _bulkConfirmRemove() async {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    final n = _selected.length;
    final ok = await _confirmDanger(
      title: isSw ? 'Ondoa wafuasi' : 'Remove followers',
      body: isSw
          ? 'Ondoa wafuasi $n? Hawatajulishwa.'
          : "Remove $n followers? They won't be notified.",
      confirmLabel: isSw ? 'Ondoa' : 'Remove',
    );
    if (!ok) return;
    HapticFeedback.mediumImpact();
    await _service.bulkRemoveFollowers(
      userId: widget.currentUserId,
      ids: _selected.toList(),
    );
    if (!mounted) return;
    _exitBulkMode();
    await _refreshAll();
  }

  Future<void> _bulkConfirmMute() async {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    final n = _selected.length;
    final ok = await _confirmDanger(
      title: isSw ? 'Nyamazisha' : 'Mute',
      body: isSw ? 'Nyamazisha wafuasi $n?' : 'Mute $n followers?',
      confirmLabel: isSw ? 'Nyamazisha' : 'Mute',
    );
    if (!ok) return;
    HapticFeedback.mediumImpact();
    await _service.bulkMuteUsers(
      userId: widget.currentUserId,
      ids: _selected.toList(),
    );
    if (!mounted) return;
    _exitBulkMode();
    await _refreshAll();
  }

  Future<void> _bulkConfirmBlock() async {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    final n = _selected.length;
    final ok = await _confirmDanger(
      title: isSw ? 'Zuia' : 'Block',
      body: isSw
          ? 'Zuia wafuasi $n? Hawataweza kupata wasifu wako.'
          : "Block $n followers? They won't be able to find your profile.",
      confirmLabel: isSw ? 'Zuia' : 'Block',
    );
    if (!ok) return;
    HapticFeedback.mediumImpact();
    await _service.bulkBlockUsers(
      userId: widget.currentUserId,
      ids: _selected.toList(),
    );
    if (!mounted) return;
    _exitBulkMode();
    await _refreshAll();
  }

  // ── export CSV ────────────────────────────────────────────────────────

  Future<void> _onExport() async {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    setState(() => _exporting = true);
    final path = await _service.exportFollowersCsv(userId: widget.currentUserId);
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
        text: isSw ? 'Wafuasi' : 'Followers',
      ),
    );
  }

  // ── build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    final total = _insights?.total ?? 0;

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
                    isSw ? 'Wafuasi' : 'Followers',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    isSw ? 'jumla $total' : '$total total',
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
            SliverToBoxAdapter(
              child: FollowersInsightsCard(
                insights: _insights,
                active: _filter,
                onTap: _onFilterTap,
              ),
            ),
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
                itemExtent: 64,
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
          : _BulkActionBar(
              count: _selected.length,
              hint: _bulkHint,
              onRemove: _selected.isEmpty ? null : _bulkConfirmRemove,
              onMute: _selected.isEmpty ? null : _bulkConfirmMute,
              onBlock: _selected.isEmpty ? null : _bulkConfirmBlock,
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
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF999999)),
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
          child: Row(children: [
            if (_sort == 'newest')
              const Icon(Icons.check_rounded, size: 18, color: Color(0xFF1A1A1A))
            else
              const SizedBox(width: 18),
            const SizedBox(width: 8),
            Text(isSw ? 'Mpya' : 'Newest'),
          ]),
        ),
        PopupMenuItem(
          value: 'sort_oldest',
          child: Row(children: [
            if (_sort == 'oldest')
              const Icon(Icons.check_rounded, size: 18, color: Color(0xFF1A1A1A))
            else
              const SizedBox(width: 18),
            const SizedBox(width: 8),
            Text(isSw ? 'Wa zamani' : 'Oldest'),
          ]),
        ),
        PopupMenuItem(
          value: 'sort_name',
          child: Row(children: [
            if (_sort == 'name')
              const Icon(Icons.check_rounded, size: 18, color: Color(0xFF1A1A1A))
            else
              const SizedBox(width: 18),
            const SizedBox(width: 8),
            const Text('A–Z'),
          ]),
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

  Widget _buildRow(FollowUser f) {
    return FollowerRow(
      follower: f,
      inBulkMode: _bulkMode,
      isSelected: _selected.contains(f.id),
      onTap: () {
        if (_bulkMode) {
          _toggleSelect(f.id);
        } else {
          Navigator.of(context).pushNamed('/profile/${f.id}');
        }
      },
      onLongPress: _bulkMode ? null : () => _onLongPressRow(f),
      onCheckboxChanged: (v) => _toggleSelect(f.id, force: v),
    );
  }

  Widget _buildEmptyBlock(bool isSw) {
    final filtered = _query.isNotEmpty || _filter != FollowerFilter.total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: Column(
        children: [
          Icon(Icons.group_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            filtered
                ? (isSw ? 'Hakuna wafuasi' : 'No followers')
                : (isSw ? 'Hujapata wafuasi bado' : 'No followers yet'),
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            filtered
                ? ''
                : (isSw
                    ? 'Shiriki wasifu wako kuanza'
                    : 'Share your profile to get started'),
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            textAlign: TextAlign.center,
          ),
          if (filtered) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                _searchCtrl.clear();
                _query = '';
                setState(() => _filter = FollowerFilter.total);
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
}

class _BulkActionBar extends StatelessWidget {
  final int count;
  final String? hint;
  final VoidCallback? onRemove;
  final VoidCallback? onMute;
  final VoidCallback? onBlock;

  const _BulkActionBar({
    required this.count,
    required this.hint,
    required this.onRemove,
    required this.onMute,
    required this.onBlock,
  });

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
                      onPressed: onRemove,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFD32F2F),
                      ),
                      child: Text(isSw ? 'Ondoa' : 'Remove'),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: onMute,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF1A1A1A),
                      ),
                      child: Text(isSw ? 'Nyamazisha' : 'Mute'),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: onBlock,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFD32F2F),
                      ),
                      child: Text(isSw ? 'Zuia' : 'Block'),
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
