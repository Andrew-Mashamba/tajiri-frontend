// lib/creator/screens/posts_earnings_by_type_screen.dart
//
// Posts → earnings landing. Lists every post type Tajiri supports
// (per the PostType enum at lib/models/post_models.dart):
//
//   text · photo · video · short_video · audio · audio_text ·
//   image_text · poll · shared
//
// Each row shows aggregate earnings + post count for that type in
// the selected period. All 9 types render even when empty so
// creators can see at a glance which formats are working.
//
// Tap any row → MyPostsEarningsListScreen filtered to that type.
//
// Aggregation is client-side from the existing
// `/api/users/me/posts/earnings` endpoint (paginated until
// exhausted, capped at 5 pages = 500 posts). When the backend gains
// a dedicated `/by-type` endpoint (see STRATEGY_ALIGNMENT.md §10a),
// swap the loader for that.
//
// Playbook compliance: monochrome (#1A1A1A / #666666 / #999999 /
// #FAFAFA / #FFFFFF), bilingual, ellipsised, tabular figures,
// pull-to-refresh, empty/loading/error triumvirate.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../../widgets/tajiri_app_bar.dart';
import '../services/creator_earnings_service.dart';
import 'my_posts_earnings_list_screen.dart';
import 'photo_earnings_screen.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kBorder = Color(0xFFE5E5E5);
const Color _kSurface = Colors.white;
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kIconBg = Color(0xFFF5F5F5);

/// Canonical Tajiri post types — must match `PostType` in
/// lib/models/post_models.dart. Ordered most-to-least common so
/// active types surface first on this list.
const List<String> _kPostTypes = [
  'photo',
  'short_video',
  'video',
  'text',
  'audio',
  'audio_text',
  'image_text',
  'poll',
  'shared',
];

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

class PostsEarningsByTypeScreen extends StatefulWidget {
  final int creatorId;
  const PostsEarningsByTypeScreen({super.key, required this.creatorId});

  @override
  State<PostsEarningsByTypeScreen> createState() =>
      _PostsEarningsByTypeScreenState();
}

class _PostsEarningsByTypeScreenState
    extends State<PostsEarningsByTypeScreen> {
  final _service = CreatorEarningsService();

  _Period _period = _Period.month;

  /// Aggregates per type. Always contains all 9 keys after a load —
  /// missing types map to (count: 0, net: 0) so all rows render.
  Map<String, _TypeAgg> _agg = {
    for (final t in _kPostTypes) t: const _TypeAgg(count: 0, netTsh: 0),
  };
  String? _periodLabel;
  String _currency = 'TZS';

  bool _loading = true;
  String? _error;
  String? _token;

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  Future<void> _hydrate() async {
    final token = (await LocalStorageService.getInstance()).getAuthToken();
    if (!mounted) return;
    setState(() => _token = token);
    await _load();
  }

  Future<void> _load() async {
    if (_token == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Walk pages until exhausted or 5-page safety cap.
      final agg = {
        for (final t in _kPostTypes) t: const _TypeAgg(count: 0, netTsh: 0),
      };
      String? periodLabel;
      String currency = 'TZS';
      const maxPages = 5;
      var page = 1;
      var lastPage = 1;
      do {
        final resp = await _service.getMyPostsEarnings(
          userId: widget.creatorId,
          token: _token!,
          period: _period.wire,
          page: page,
          perPage: 100,
        );
        periodLabel = resp.periodStart;
        currency = resp.currency;
        for (final row in resp.items) {
          final key = _kPostTypes.contains(row.postType) ? row.postType : 'text';
          final cur = agg[key] ?? const _TypeAgg(count: 0, netTsh: 0);
          agg[key] = _TypeAgg(
            count: cur.count + 1,
            netTsh: cur.netTsh + row.totalNetTsh,
          );
        }
        lastPage = resp.lastPage;
        page++;
      } while (page <= lastPage && page <= maxPages);

      if (!mounted) return;
      setState(() {
        _agg = agg;
        _periodLabel = periodLabel;
        _currency = currency;
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
    _load();
  }

  void _openType(String type) {
    HapticFeedback.selectionClick();
    // Photo has its own dedicated rate-card screen showing the
    // per-event payout schedule. Other types currently route to
    // the per-post list filtered by type. As each type gets its
    // own rate card defined, route it to its dedicated screen here.
    Widget destination;
    switch (type) {
      case 'photo':
        destination = PhotoEarningsScreen(creatorId: widget.creatorId);
        break;
      default:
        destination = MyPostsEarningsListScreen(
          creatorId: widget.creatorId,
          postTypeFilter: type,
        );
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: TajiriAppBar(
        title: isSw ? 'Posts · Mapato' : 'Posts · Earnings',
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: _kPrimary,
          onRefresh: _load,
          child: _loading
              ? const _LoadingList()
              : _error != null
                  ? _ErrorView(
                      message: _error!, onRetry: _load, isSw: isSw)
                  : _buildBody(isSw),
        ),
      ),
    );
  }

  Widget _buildBody(bool isSw) {
    final totalNet = _agg.values.fold<double>(0, (a, b) => a + b.netTsh);
    final totalCount = _agg.values.fold<int>(0, (a, b) => a + b.count);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _Hero(
          totalNet: totalNet,
          totalCount: totalCount,
          currency: _currency,
          periodIso: _periodLabel,
          isSw: isSw,
        ),
        const SizedBox(height: 14),
        _PeriodPills(
          selected: _period, onChanged: _setPeriod, isSw: isSw),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            isSw ? 'AINA ZA POSTS' : 'POST TYPES',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _kTertiary,
              letterSpacing: 0.6,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kBorder),
          ),
          child: Column(
            children: [
              for (var i = 0; i < _kPostTypes.length; i++) ...[
                _TypeRow(
                  type: _kPostTypes[i],
                  agg: _agg[_kPostTypes[i]] ??
                      const _TypeAgg(count: 0, netTsh: 0),
                  isSw: isSw,
                  onTap: () => _openType(_kPostTypes[i]),
                ),
                if (i < _kPostTypes.length - 1)
                  const Divider(
                      height: 1,
                      color: _kBorder,
                      indent: 14,
                      endIndent: 14),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        _HowItWorks(isSw: isSw),
      ],
    );
  }
}

class _TypeAgg {
  final int count;
  final double netTsh;
  const _TypeAgg({required this.count, required this.netTsh});
}

// ─── Hero ──────────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  final double totalNet;
  final int totalCount;
  final String currency;
  final String? periodIso;
  final bool isSw;
  const _Hero({
    required this.totalNet,
    required this.totalCount,
    required this.currency,
    required this.periodIso,
    required this.isSw,
  });

  @override
  Widget build(BuildContext context) {
    final monthLabel = _formatMonth(periodIso, isSw);
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
                alignment: Alignment.center,
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
                _fmtAmount(totalNet),
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
                  currency,
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
                ? '$totalCount posts · aina ${_kPostTypes.length}'
                : '$totalCount posts · ${_kPostTypes.length} types',
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

// ─── Type row ─────────────────────────────────────────────────────────

class _TypeRow extends StatelessWidget {
  final String type;
  final _TypeAgg agg;
  final bool isSw;
  final VoidCallback onTap;

  const _TypeRow({
    required this.type,
    required this.agg,
    required this.isSw,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasEarnings = agg.count > 0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _kIconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(_iconFor(type), size: 20, color: _kPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      typeLabel(type, isSw),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasEarnings
                          ? (isSw
                              ? '${agg.count} posts'
                              : '${agg.count} posts')
                          : (isSw
                              ? 'Hakuna posts za aina hii'
                              : 'No posts of this type'),
                      style: TextStyle(
                        fontSize: 11,
                        color: hasEarnings ? _kSecondary : _kTertiary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    hasEarnings ? 'TZS ${_fmtAmount(agg.netTsh)}' : '—',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: hasEarnings ? _kPrimary : _kTertiary,
                      fontFeatures: const [FontFeature.tabularFigures()],
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

// ─── How it works ────────────────────────────────────────────────────

class _HowItWorks extends StatelessWidget {
  final bool isSw;
  const _HowItWorks({required this.isSw});

  @override
  Widget build(BuildContext context) {
    return Container(
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
                ? 'Bofya aina yoyote kuona orodha ya posts za aina hiyo na mapato halisi kwa kila moja. Aina zote tisa zinaonekana hata kama bado huna posts za aina hiyo.'
                : 'Tap any type to see the posts of that format and their per-post earnings. All nine types are listed even when you have no posts of that kind yet.',
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

// ─── Sentinels ────────────────────────────────────────────────────────

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
            child:
                CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
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

// ─── Type metadata (shared with MyPostsEarningsListScreen) ───────────

/// Bilingual label for each canonical post type.
String typeLabel(String type, bool isSw) {
  return switch (type) {
    'text' => isSw ? 'Maandishi' : 'Text post',
    'photo' => isSw ? 'Picha' : 'Photo',
    'image' => isSw ? 'Picha' : 'Photo',
    'video' => isSw ? 'Video ndefu' : 'Video',
    'short_video' => isSw ? 'Video fupi' : 'Short video',
    'audio' => isSw ? 'Sauti' : 'Audio',
    'audio_text' => isSw ? 'Sauti + Maandishi' : 'Audio + text',
    'image_text' => isSw ? 'Picha + Maandishi' : 'Photo + text',
    'poll' => isSw ? 'Kura' : 'Poll',
    'shared' => isSw ? 'Imeshirikiwa' : 'Shared',
    _ => isSw ? 'Post' : 'Post',
  };
}

IconData _iconFor(String type) {
  return switch (type) {
    'text' => Icons.text_fields_rounded,
    'photo' || 'image' => Icons.image_outlined,
    'video' => Icons.movie_outlined,
    'short_video' => Icons.videocam_outlined,
    'audio' => Icons.music_note_outlined,
    'audio_text' => Icons.queue_music_outlined,
    'image_text' => Icons.photo_size_select_actual_outlined,
    'poll' => Icons.poll_outlined,
    'shared' => Icons.repeat_rounded,
    _ => Icons.article_outlined,
  };
}

// ─── Helpers ─────────────────────────────────────────────────────────

String _formatMonth(String? iso, bool isSw) {
  if (iso == null || iso.isEmpty) {
    return isSw ? 'mwezi huu' : 'this month';
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
  return '${months[dt.month - 1]} ${dt.year}';
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
