// lib/creator/screens/my_posts_earnings_list_screen.dart
//
// Creator → Posts page: a list of every post that earned in the
// selected period, with per-post net + a compact engagement preview.
// Tapping a row opens [PostEarningsScreen] for the full per-post
// breakdown (hero + 6-row B+C table + transparency explainer).
//
// Replaces the metric-grouped breakdown screen — creators want
// per-post detail, not aggregated metric sections.
//
// Playbook compliance: monochrome palette, dark hero card, period
// pills, paginated list with empty/loading/error triumvirate,
// pull-to-refresh, bilingual.
//
// Backend: GET /api/users/me/posts/earnings (CreatorEarningsController
// ::myPostsEarnings) — paginated, period-scoped, joins posts +
// earning_events totals + per-metric breakdown + thumbnails.
//
// Strategy doc: docs/post_earnings_tajiri_strategy.md §2 (B+C
// attribution table).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../../widgets/tajiri_app_bar.dart';
import '../models/creator_earnings_models.dart';
import '../services/creator_earnings_service.dart';
import 'post_earnings_screen.dart';
import 'posts_earnings_by_type_screen.dart' show typeLabel;

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kBorder = Color(0xFFE5E5E5);
const Color _kSurface = Colors.white;
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kIconBg = Color(0xFFF5F5F5);

enum _Period { week, month, quarter, year }

extension _PeriodWire on _Period {
  String get wire => name;
  String label(bool isSw) => switch (this) {
        _Period.week => isSw ? 'Wiki' : 'Week',
        _Period.month => isSw ? 'Mwezi' : 'Month',
        _Period.quarter => isSw ? 'Robo' : 'Quarter',
        _Period.year => isSw ? 'Mwaka' : 'Year',
      };
}

class MyPostsEarningsListScreen extends StatefulWidget {
  final int creatorId;

  /// Optional canonical post-type to filter by — one of the values
  /// in `PostType` (lib/models/post_models.dart). When set, only
  /// rows whose `postType` matches are rendered, and the AppBar
  /// shows the type label. The drill-down target from
  /// `PostsEarningsByTypeScreen` uses this.
  final String? postTypeFilter;

  const MyPostsEarningsListScreen({
    super.key,
    required this.creatorId,
    this.postTypeFilter,
  });

  @override
  State<MyPostsEarningsListScreen> createState() =>
      _MyPostsEarningsListScreenState();
}

class _MyPostsEarningsListScreenState
    extends State<MyPostsEarningsListScreen> {
  final _service = CreatorEarningsService();
  final _scrollController = ScrollController();

  _Period _period = _Period.month;
  final List<PostEarningsListRow> _rows = [];
  PostEarningsListResponse? _meta;

  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  String? _token;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _hydrate();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _hydrate() async {
    final token = (await LocalStorageService.getInstance()).getAuthToken();
    if (!mounted) return;
    setState(() => _token = token);
    await _loadFirstPage();
  }

  Future<void> _loadFirstPage() async {
    if (_token == null) return;
    setState(() {
      _loading = true;
      _error = null;
      _rows.clear();
      _page = 1;
    });
    try {
      final fresh = await _service.getMyPostsEarnings(
        userId: widget.creatorId,
        token: _token!,
        period: _period.wire,
        page: 1,
        perPage: 20,
      );
      if (!mounted) return;
      setState(() {
        _meta = fresh;
        _rows
          ..clear()
          ..addAll(_applyTypeFilter(fresh.items));
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _sanitize(e.toString());
      });
    }
  }

  /// Filter the list against [widget.postTypeFilter] when set.
  Iterable<PostEarningsListRow> _applyTypeFilter(
      Iterable<PostEarningsListRow> rows) {
    final filter = widget.postTypeFilter;
    if (filter == null) return rows;
    return rows.where((r) => r.postType == filter);
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _meta == null) return;
    if (_page >= (_meta!.lastPage)) return;
    if (_token == null) return;
    setState(() => _loadingMore = true);
    try {
      final next = _page + 1;
      final more = await _service.getMyPostsEarnings(
        userId: widget.creatorId,
        token: _token!,
        period: _period.wire,
        page: next,
        perPage: 20,
      );
      if (!mounted) return;
      setState(() {
        _rows.addAll(_applyTypeFilter(more.items));
        _meta = more;
        _page = next;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels > pos.maxScrollExtent - 320) {
      _loadMore();
    }
  }

  String _sanitize(String raw) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    if (raw.contains('SocketException') || raw.contains('Failed host lookup')) {
      return isSw
          ? 'Hakuna intaneti. Hakikisha umeunganishwa.'
          : "Can't reach the server. Check your connection.";
    }
    return isSw ? 'Imeshindwa kupakia.' : 'Failed to load.';
  }

  void _setPeriod(_Period p) {
    if (p == _period) return;
    HapticFeedback.selectionClick();
    setState(() => _period = p);
    _loadFirstPage();
  }

  void _openDetail(PostEarningsListRow row) {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostEarningsScreen(
          postId: row.postId,
          currentUserId: widget.creatorId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: TajiriAppBar(
        title: widget.postTypeFilter != null
            ? (isSw
                ? '${typeLabel(widget.postTypeFilter!, true)} · Mapato'
                : '${typeLabel(widget.postTypeFilter!, false)} · Earnings')
            : (isSw ? 'Posts · Mapato' : 'Posts · Earnings'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: _kPrimary,
          onRefresh: _loadFirstPage,
          child: _loading && _rows.isEmpty
              ? const _LoadingList()
              : _meta == null && _error != null
                  ? _ErrorView(
                      message: _error!, onRetry: _loadFirstPage, isSw: isSw)
                  : _buildBody(isSw),
        ),
      ),
    );
  }

  Widget _buildBody(bool isSw) {
    final meta = _meta!;
    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: _rows.isEmpty ? 4 : _rows.length + 4,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _HeroCard(meta: meta, postCount: _rows.length, isSw: isSw);
        }
        if (index == 1) {
          return Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 14),
            child: _PeriodPills(
              selected: _period,
              onChanged: _setPeriod,
              isSw: isSw,
            ),
          );
        }
        if (_rows.isEmpty) {
          if (index == 2) return _EmptyCard(isSw: isSw);
          if (index == 3) return _HowItWorksCard(isSw: isSw);
          return const SizedBox.shrink();
        }
        // index >= 2: rows + footer
        final rowIndex = index - 2;
        if (rowIndex < _rows.length) {
          final row = _rows[rowIndex];
          final isLast = rowIndex == _rows.length - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 4 : 10),
            child: _PostEarningsRow(
              row: row,
              isSw: isSw,
              onTap: () => _openDetail(row),
            ),
          );
        }
        if (rowIndex == _rows.length) {
          return _loadingMore
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _kPrimary),
                    ),
                  ),
                )
              : const SizedBox(height: 8);
        }
        if (rowIndex == _rows.length + 1) {
          return Padding(
            padding: const EdgeInsets.only(top: 6),
            child: _HowItWorksCard(isSw: isSw),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

// ─── Hero ──────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final PostEarningsListResponse meta;
  final int postCount;
  final bool isSw;
  const _HeroCard({
    required this.meta,
    required this.postCount,
    required this.isSw,
  });

  @override
  Widget build(BuildContext context) {
    final monthLabel = _formatPeriod(meta.periodStart, meta.period, isSw);
    final total = meta.items.fold<double>(0, (a, b) => a + b.totalNetTsh);
    final events = meta.items.fold<int>(0, (a, b) => a + b.eventCount);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kPrimary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.article_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isSw
                      ? 'Mapato kwenye posts · $monthLabel'
                      : 'Posts earnings · $monthLabel',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.70),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _fmtAmount(total),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.0,
                  letterSpacing: -0.6,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  meta.currency,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.80),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isSw
                ? '$postCount posts · $events matukio'
                : '$postCount posts · $events events',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.70),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Period selector ──────────────────────────────────────────────────

class _PeriodPills extends StatelessWidget {
  final _Period selected;
  final ValueChanged<_Period> onChanged;
  final bool isSw;

  const _PeriodPills({
    required this.selected,
    required this.onChanged,
    required this.isSw,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < _Period.values.length; i++) ...[
          Expanded(
            child: _PeriodPill(
              label: _Period.values[i].label(isSw),
              isSelected: _Period.values[i] == selected,
              onTap: () => onChanged(_Period.values[i]),
            ),
          ),
          if (i < _Period.values.length - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _PeriodPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _PeriodPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _kPrimary : _kSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? _kPrimary : _kBorder),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : _kPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

// ─── Post row ─────────────────────────────────────────────────────────

class _PostEarningsRow extends StatelessWidget {
  final PostEarningsListRow row;
  final bool isSw;
  final VoidCallback onTap;

  const _PostEarningsRow({
    required this.row,
    required this.isSw,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final excerpt = (row.content ?? '').trim();
    final placeholderTitle = typeLabel(row.postType, isSw);
    final dateLabel = _formatRelative(row.createdAt, isSw);
    final pillsText = _buildPillsText(row.metrics, isSw);

    return Material(
      color: _kSurface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: _kBorder),
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumbnail(row: row),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      excerpt.isNotEmpty ? excerpt : placeholderTitle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        typeLabel(row.postType, isSw),
                        if (dateLabel != null) dateLabel,
                      ].join(' · '),
                      style: const TextStyle(
                        fontSize: 11,
                        color: _kTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (pillsText != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        pillsText,
                        style: const TextStyle(
                          fontSize: 11,
                          color: _kSecondary,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'TZS ${_fmtAmount(row.totalNetTsh)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _kPrimary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isSw ? '${row.eventCount} matukio' : '${row.eventCount} events',
                    style: const TextStyle(
                      fontSize: 10,
                      color: _kTertiary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Icon(Icons.chevron_right_rounded,
                      size: 18, color: _kTertiary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final PostEarningsListRow row;
  const _Thumbnail({required this.row});

  @override
  Widget build(BuildContext context) {
    final url = row.thumbnailUrl;
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          url,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _IconThumb(type: row.postType),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return _IconThumb(type: row.postType);
          },
        ),
      );
    }
    return _IconThumb(type: row.postType);
  }
}

class _IconThumb extends StatelessWidget {
  final String type;
  const _IconThumb({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: _kIconBg,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Icon(_typeIcon(type), size: 22, color: _kPrimary),
    );
  }
}

// ─── Empty ────────────────────────────────────────────────────────────

class _EmptyCard extends StatelessWidget {
  final bool isSw;
  const _EmptyCard({required this.isSw});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.article_outlined, size: 36, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            isSw
                ? 'Hakuna mapato kwenye posts kipindi hiki.'
                : 'No post earnings for this period yet.',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _kPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            isSw
                ? 'Endelea kuchapisha — kila mwoneko, reaction, comment, share na save hujenga mapato.'
                : 'Keep posting — every view, reaction, comment, share and save earns.',
            style: const TextStyle(
              fontSize: 12,
              color: _kSecondary,
              height: 1.45,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── How it works ────────────────────────────────────────────────────

class _HowItWorksCard extends StatelessWidget {
  final bool isSw;
  const _HowItWorksCard({required this.isSw});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 16, color: _kSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isSw ? 'Jinsi inavyofanya kazi' : 'How it works',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isSw
                ? 'Bofya post yoyote kuona uchanganuzi kamili wa mapato yake — kwa kila tendo (mwoneko, reaction, comment, share, save). Mapato yana dirisha la siku 30 — yanapokwisha yanalipwa kwa mkoba wako.'
                : 'Tap any post to see its full earnings breakdown — per action (view, reaction, comment, share, save). Earnings have a 30-day clearing window — once cleared they land in your wallet.',
            style: const TextStyle(
              fontSize: 12,
              color: _kSecondary,
              height: 1.5,
            ),
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Loading + error sentinels ───────────────────────────────────────

class _LoadingList extends StatelessWidget {
  const _LoadingList();
  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 120),
        Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final bool isSw;
  const _ErrorView({
    required this.message,
    required this.onRetry,
    required this.isSw,
  });
  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 60),
        Icon(Icons.error_outline_rounded,
            size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(
          message,
          style: const TextStyle(color: _kSecondary, fontSize: 14),
          textAlign: TextAlign.center,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: _kPrimary,
              side: const BorderSide(color: _kPrimary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(isSw ? 'Jaribu tena' : 'Retry'),
          ),
        ),
      ],
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────

String? _buildPillsText(List<PostMetricSlice> metrics, bool isSw) {
  if (metrics.isEmpty) return null;
  // Top 3 by net descending — shown as a compact "1.2K views · 78 reactions"
  final sorted = [...metrics]..sort((a, b) => b.netTsh.compareTo(a.netTsh));
  final top = sorted.take(3);
  final parts = <String>[];
  for (final m in top) {
    parts.add('${_fmtCount(m.rawCountTotal)} ${_metricUnit(m.metric, m.rawCountTotal, isSw)}');
  }
  return parts.join(' · ');
}

String _metricUnit(String metric, int n, bool isSw) {
  return switch (metric) {
    'view' => isSw ? (n == 1 ? 'mwoneko' : 'mioneko') : (n == 1 ? 'view' : 'views'),
    'watch_second' => isSw ? 'sekunde' : (n == 1 ? 'sec' : 'secs'),
    'reaction' => isSw ? 'reactions' : 'reactions',
    'comment' => isSw ? 'maoni' : (n == 1 ? 'comment' : 'comments'),
    'reply' => isSw ? 'majibu' : (n == 1 ? 'reply' : 'replies'),
    'share' => isSw ? 'kushiriki' : (n == 1 ? 'share' : 'shares'),
    'save' => isSw ? 'kuhifadhi' : (n == 1 ? 'save' : 'saves'),
    'comment_reaction' =>
      isSw ? 'reactions kwenye maoni' : 'comment reactions',
    'follow_from_post' => isSw ? 'follows' : 'follows',
    'subscribe_from_post' => isSw ? 'subs' : 'subs',
    'derivative_royalty' => isSw ? 'derivatives' : 'derivatives',
    _ => metric,
  };
}

IconData _typeIcon(String type) {
  return switch (type) {
    'photo' || 'image' => Icons.image_outlined,
    'video' || 'short_video' => Icons.videocam_outlined,
    'audio' || 'music' => Icons.music_note_outlined,
    'live' => Icons.podcasts_rounded,
    'gallery' => Icons.collections_outlined,
    _ => Icons.article_outlined,
  };
}

String? _formatRelative(String? iso, bool isSw) {
  if (iso == null || iso.isEmpty) return null;
  final dt = DateTime.tryParse(iso);
  if (dt == null) return null;
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return isSw ? 'sasa hivi' : 'just now';
  if (diff.inMinutes < 60) {
    final n = diff.inMinutes;
    return isSw ? '${n}d zilizopita' : '${n}m ago';
  }
  if (diff.inHours < 24) {
    final n = diff.inHours;
    return isSw ? '${n}s zilizopita' : '${n}h ago';
  }
  if (diff.inDays < 7) {
    final n = diff.inDays;
    return isSw ? '${n}sk zilizopita' : '${n}d ago';
  }
  if (diff.inDays < 30) {
    final n = diff.inDays ~/ 7;
    return isSw ? '${n}wk zilizopita' : '${n}w ago';
  }
  if (diff.inDays < 365) {
    final n = diff.inDays ~/ 30;
    return isSw ? '${n}mw zilizopita' : '${n}mo ago';
  }
  final n = diff.inDays ~/ 365;
  return isSw ? '${n}mk zilizopita' : '${n}y ago';
}

String _formatPeriod(String iso, String period, bool isSw) {
  if (iso.isEmpty) {
    return switch (period) {
      'week' => isSw ? 'wiki hii' : 'this week',
      'month' => isSw ? 'mwezi huu' : 'this month',
      'quarter' => isSw ? 'robo hii' : 'this quarter',
      'year' => isSw ? 'mwaka huu' : 'this year',
      _ => '',
    };
  }
  final dt = DateTime.tryParse(iso);
  if (dt == null) return iso;
  const enMonths = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  const swMonths = [
    'Januari', 'Februari', 'Machi', 'Aprili', 'Mei', 'Juni',
    'Julai', 'Agosti', 'Septemba', 'Oktoba', 'Novemba', 'Desemba',
  ];
  final months = isSw ? swMonths : enMonths;
  return switch (period) {
    'month' => '${months[dt.month - 1]} ${dt.year}',
    'year' => '${dt.year}',
    _ => '${months[dt.month - 1]} ${dt.year}',
  };
}

String _fmtCount(int v) {
  if (v >= 1000000) {
    return '${(v / 1000000).toStringAsFixed(v >= 10000000 ? 0 : 1)}M';
  }
  if (v >= 1000) {
    return '${(v / 1000).toStringAsFixed(v >= 10000 ? 0 : 1)}K';
  }
  return '$v';
}

String _fmtAmount(double v) {
  if (v >= 1000000) {
    return '${(v / 1000000).toStringAsFixed(v >= 10000000 ? 0 : 1)}M';
  }
  if (v >= 10000) return '${(v / 1000).toStringAsFixed(0)}K';
  final whole = v.truncateToDouble() == v;
  final s = whole ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
  final parts = s.split('.');
  final intPart = parts[0];
  final reversed = intPart.split('').reversed.toList();
  final out = StringBuffer();
  for (var i = 0; i < reversed.length; i++) {
    if (i > 0 && i % 3 == 0) out.write(',');
    out.write(reversed[i]);
  }
  final formatted = out.toString().split('').reversed.join('');
  return parts.length > 1 ? '$formatted.${parts[1]}' : formatted;
}
