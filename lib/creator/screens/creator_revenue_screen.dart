// lib/creator/screens/creator_revenue_screen.dart
//
// Top-level creator revenue index. Replaces IncomeSourcesView's
// mixed 12-source list with a 9-card grid of canonical revenue
// categories per docs/CREATOR_REVENUE_TAXONOMY.md.
//
// Each card opens a category-specific drill-down. Underlying
// backend data is aggregated client-side from the existing
// IncomeSources API (v1); backend natively returns the 9-category
// structure in v2.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/income_source.dart';
import '../services/income_sources_service.dart';
import '../widgets/wallet_hero_card.dart';
import 'category_revenue_screen.dart';
import 'creator_revenue_report_screen.dart';
import 'income_activity_screen.dart';
import 'posts_earnings_by_type_screen.dart';
import 'sponsored_posts_screen.dart';
import 'stream_type_earnings_screen.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kBorder = Color(0xFFE5E5E5);
const Color _kSurface = Colors.white;

/// Canonical creator revenue categories (taxonomy doc §2).
enum CreatorRevenueCategory {
  posts,
  streams,
  subscribers,
  brandDeals,
  adRevenue,
  photos,
  videos,
  music,
  files,
}

/// v1 client-side aggregation table (taxonomy doc §7.1). Each category
/// rolls up one or more backend `IncomeSource.id`s.
///
/// Photos / Videos / Music / Files are media-type slices of the same
/// engagement pool that funds Posts. The backend doesn't yet expose the
/// per-media-type breakdown — those four categories show "coming soon"
/// until v2 backend split (taxonomy doc §7.2).
const Map<CreatorRevenueCategory, List<String>> _kCategorySources = {
  CreatorRevenueCategory.posts: ['tips', 'creator_fund', 'ppv_unlocks', 'affiliate'],
  CreatorRevenueCategory.streams: ['live_gifts', 'super_chat', 'live_commerce'],
  CreatorRevenueCategory.subscribers: ['subscriptions'],
  CreatorRevenueCategory.brandDeals: ['brand_deals'],
  CreatorRevenueCategory.adRevenue: ['ad_share'],
  // v1: no backend per-media-type breakdown yet — all engagement on
  // photo/video/audio/document posts currently rolls up under
  // `creator_fund`, which is reported in the Posts category.
  CreatorRevenueCategory.photos: <String>[],
  CreatorRevenueCategory.videos: <String>[],
  CreatorRevenueCategory.music: <String>[],
  CreatorRevenueCategory.files: <String>[],
};

class CreatorRevenueScreen extends StatefulWidget {
  final int creatorId;

  const CreatorRevenueScreen({super.key, required this.creatorId});

  @override
  State<CreatorRevenueScreen> createState() => _CreatorRevenueScreenState();
}

class _CreatorRevenueScreenState extends State<CreatorRevenueScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final IncomeSourcesService _service = IncomeSourcesService();

  IncomePeriod _period = IncomePeriod.month;
  bool _loading = true;
  String? _error;
  IncomeSourcesResponse? _response;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      final resp = await _service.getSources(
        creatorId: widget.creatorId,
        period: _period,
        token: token,
      );
      if (!mounted) return;
      setState(() {
        _response = resp;
        _loading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('[CreatorRevenue] load error: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _setPeriod(IncomePeriod p) {
    if (p == _period) return;
    setState(() => _period = p);
    _load();
  }

  /// Aggregate the backend sources into the 9 frontend categories.
  /// Each category sums **all** matching sources — Posts shows the
  /// total of tips + creator_fund + ppv_unlocks + affiliate, not just
  /// the first match.
  Map<CreatorRevenueCategory, _CategoryAgg> _aggregate() {
    final out = <CreatorRevenueCategory, _CategoryAgg>{};
    for (final cat in CreatorRevenueCategory.values) {
      out[cat] = _CategoryAgg.zero();
    }
    final allSources = _response?.sources ?? const <IncomeSource>[];
    for (final src in allSources) {
      for (final entry in _kCategorySources.entries) {
        if (entry.value.contains(src.id)) {
          out[entry.key] = out[entry.key]!.add(src);
          break;
        }
      }
    }
    return out;
  }

  /// Return the IncomeSource list that maps to this category in the
  /// current backend response. Used when pushing the category detail
  /// screen so it can render Hero/History/HowItWorks across all
  /// contributing sources.
  List<IncomeSource> _sourcesForCategory(CreatorRevenueCategory cat) {
    final ids = _kCategorySources[cat] ?? const <String>[];
    final all = _response?.sources ?? const <IncomeSource>[];
    return all.where((s) => ids.contains(s.id)).toList(growable: false);
  }

  void _openCategory(CreatorRevenueCategory cat) {
    HapticFeedback.selectionClick();

    // Media-type categories route to their dedicated top-level modules
    // (lib/myphotos, lib/myvideos, lib/mymusic, lib/myfiles) — these
    // are first-class content modules with their own surfaces, NOT
    // engagement-pool slices.
    switch (cat) {
      case CreatorRevenueCategory.photos:
        Navigator.pushNamed(context, '/my-photos');
        return;
      case CreatorRevenueCategory.videos:
        Navigator.pushNamed(context, '/my-videos');
        return;
      case CreatorRevenueCategory.music:
        Navigator.pushNamed(context, '/my-music');
        return;
      case CreatorRevenueCategory.files:
        Navigator.pushNamed(context, '/my-files');
        return;
      case CreatorRevenueCategory.brandDeals:
        // Brand Deals routes to SponsoredPostsScreen for v1.
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SponsoredPostsScreen(currentUserId: widget.creatorId),
          ),
        );
        return;
      case CreatorRevenueCategory.posts:
        // Posts opens the by-type earnings page — one row per
        // canonical post type (text · photo · video · short_video ·
        // audio · audio_text · image_text · poll · shared) with
        // aggregate earnings. Tap a type to drill into that
        // type's posts, then tap a post for the full B+C breakdown.
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                PostsEarningsByTypeScreen(creatorId: widget.creatorId),
          ),
        );
        return;
      case CreatorRevenueCategory.streams:
        // Streams opens the dedicated Streams.earnings strategy
        // renderer — shows all 67 income sources across §I-§XII plus
        // the §X integrity framework (8 bonuses + 9 engagement
        // penalties + 17 system/safety/anti-gaming clamps + catchall).
        // Defaults to the most common live_video stream type;
        // backend `stream_type` filtering can switch this in future.
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StreamTypeEarningsScreen(
              creatorId: widget.creatorId,
              streamType: 'live_video',
            ),
          ),
        );
        return;
      case CreatorRevenueCategory.subscribers:
      case CreatorRevenueCategory.adRevenue:
        break; // fall through to backend-source drilldown
    }

    // For backend-source-backed categories (Posts / Streams /
    // Subscribers / Ad Revenue) push the aggregated CategoryRevenue
    // screen with the full list of matching backend sources. This
    // implements the docs/CREATOR_REVENUE_TAXONOMY.md §5 layout:
    // Hero (sums across sources) + History (merged) + How it works
    // (per-source formulas).
    final matching = _sourcesForCategory(cat);
    if (matching.isEmpty) {
      _showComingSoon(cat);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryRevenueScreen(
          creatorId: widget.creatorId,
          category: cat,
          sources: matching,
        ),
      ),
    );
  }

  void _showComingSoon(CreatorRevenueCategory cat) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    final isMediaTypeSlice = _kCategorySources[cat]?.isEmpty ?? true;
    final body = isMediaTypeSlice
        ? (isSw
            ? 'Mapato yako ya ${_categoryLabel(cat, isSw)} kwa sasa yamejumuishwa kwenye "Posts". Mtazamo wa kila aina ya maudhui (Picha · Video · Muziki · Faili) utawekwa wazi backend ikishasasishwa.'
            : 'Your earnings for ${_categoryLabel(cat, isSw)} are currently rolled up under "Posts". The per-media-type breakdown will become available once the backend v2 split ships.')
        : (isSw
            ? 'Aina hii ya mapato itafunguliwa hivi karibuni.'
            : 'This revenue category will unlock soon.');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_categoryLabel(cat, isSw)),
        content: Text(body, maxLines: 6),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isSw ? 'Sawa' : 'OK'),
          ),
        ],
      ),
    );
  }

  void _openWalletActivity() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IncomeActivityScreen(creatorId: widget.creatorId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;

    return SafeArea(
      child: RefreshIndicator(
        color: _kPrimary,
        onRefresh: _load,
        child: _loading && _response == null
            ? ListView(
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
              )
            : _buildBody(isSw),
      ),
    );
  }

  Widget _buildBody(bool isSw) {
    final summary = _response?.summary ?? IncomeSummary.empty;
    final agg = _aggregate();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        if (_error != null && _response == null)
          _ErrorBanner(
            message: isSw
                ? 'Imeshindwa kupakua data ya mapato. Vuta chini kujaribu tena.'
                : 'Could not load revenue data. Pull down to retry.',
            onRetry: _load,
          )
        else ...[
          WalletHeroCard(
            summary: summary,
            onWithdraw: () {/* unchanged behavior */},
            onActivity: _openWalletActivity,
          ),
          const SizedBox(height: 14),
          _PeriodRow(period: _period, onChanged: _setPeriod, isSw: isSw),
          const SizedBox(height: 20),
          _SectionLabel(isSw ? 'VYANZO VYANGU VYA MAPATO' : 'MY REVENUE SOURCES'),
          const SizedBox(height: 10),
          _CategoryGrid(
            agg: agg,
            isSw: isSw,
            onTap: _openCategory,
          ),
          const SizedBox(height: 16),
          _FullReportLink(creatorId: widget.creatorId, isSw: isSw),
          const SizedBox(height: 12),
          _OtherRevenueLink(isSw: isSw),
          const SizedBox(height: 12),
          _HowItWorksLink(isSw: isSw),
        ],
      ],
    );
  }
}

// ─── Aggregator ─────────────────────────────────────────────────────────

class _CategoryAgg {
  final int currentNetMinor;
  final int sourceCount;
  final SourceState? worstState;

  const _CategoryAgg({
    required this.currentNetMinor,
    required this.sourceCount,
    required this.worstState,
  });

  factory _CategoryAgg.zero() => const _CategoryAgg(
        currentNetMinor: 0,
        sourceCount: 0,
        worstState: null,
      );

  _CategoryAgg add(IncomeSource src) {
    return _CategoryAgg(
      currentNetMinor: currentNetMinor + (src.currentPeriod?.netMinor ?? 0),
      sourceCount: sourceCount + 1,
      worstState: _pickWorse(worstState, src.state),
    );
  }

  bool get isLocked => worstState != null && worstState!.isLocked;
  bool get hasAnyActive => sourceCount > 0 && !isLocked;

  static SourceState? _pickWorse(SourceState? a, SourceState b) {
    if (a == null) return b;
    // "Active" trumps "locked" — if any source is active the category is active.
    if (a.isActive) return a;
    if (b.isActive) return b;
    return a;
  }
}

// ─── Sub-widgets ───────────────────────────────────────────────────────

class _PeriodRow extends StatelessWidget {
  final IncomePeriod period;
  final ValueChanged<IncomePeriod> onChanged;
  final bool isSw;

  const _PeriodRow({required this.period, required this.onChanged, required this.isSw});

  @override
  Widget build(BuildContext context) {
    final items = [
      (IncomePeriod.week, isSw ? 'Wiki' : 'Week'),
      (IncomePeriod.month, isSw ? 'Mwezi' : 'Month'),
      (IncomePeriod.quarter, isSw ? 'Robo' : 'Quarter'),
      (IncomePeriod.all, isSw ? 'Yote' : 'All'),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final entry in items) ...[
          Expanded(
            child: _PeriodPill(
              label: entry.$2,
              selected: period == entry.$1,
              onTap: () => onChanged(entry.$1),
            ),
          ),
          if (entry.$1 != items.last.$1) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _PeriodPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodPill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? _kPrimary : _kBorder),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : _kPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _kTertiary,
              letterSpacing: 0.6,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      );
}

class _CategoryGrid extends StatelessWidget {
  final Map<CreatorRevenueCategory, _CategoryAgg> agg;
  final bool isSw;
  final ValueChanged<CreatorRevenueCategory> onTap;

  const _CategoryGrid({required this.agg, required this.isSw, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cats = CreatorRevenueCategory.values;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.92,
      ),
      itemBuilder: (ctx, i) {
        final cat = cats[i];
        return _CategoryCard(
          category: cat,
          agg: agg[cat]!,
          isSw: isSw,
          onTap: () => onTap(cat),
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CreatorRevenueCategory category;
  final _CategoryAgg agg;
  final bool isSw;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.agg,
    required this.isSw,
    required this.onTap,
  });

  /// Media-type categories (Photos / Videos / Music / Files) are full
  /// modules with their own surfaces. Their card shows "Open module"
  /// instead of a TZS amount until backend v2 ships per-media-type
  /// earnings breakdown.
  bool get _isMediaModule =>
      category == CreatorRevenueCategory.photos ||
      category == CreatorRevenueCategory.videos ||
      category == CreatorRevenueCategory.music ||
      category == CreatorRevenueCategory.files;

  @override
  Widget build(BuildContext context) {
    final label = _categoryLabel(category, isSw);
    final iconData = _categoryIcon(category);
    final amount = agg.currentNetMinor;
    final amountStr = _isMediaModule
        ? (isSw ? 'Fungua' : 'Open')
        : (amount > 0 ? 'TZS ${_fmt(amount / 100.0)}' : '—');
    final stateLabel = _isMediaModule
        ? (isSw ? 'Moduli' : 'Module')
        : (agg.isLocked
            ? (isSw ? 'Imefungwa' : 'Locked')
            : (agg.hasAnyActive
                ? (isSw ? 'Hai' : 'Active')
                : (isSw ? 'Tayari' : 'Ready')));

    return Material(
      color: _kSurface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: _kBorder),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(iconData, size: 20, color: _kPrimary),
              ),
              const Spacer(),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                amountStr,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _kSecondary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                stateLabel,
                style: const TextStyle(fontSize: 10, color: _kTertiary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FullReportLink extends StatelessWidget {
  final int creatorId;
  final bool isSw;
  const _FullReportLink({required this.creatorId, required this.isSw});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                CreatorRevenueReportScreen(creatorId: creatorId),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kPrimary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.receipt_long_rounded,
                  size: 20, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSw ? 'Ripoti kamili ya mapato' : 'Full revenue report',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isSw
                        ? 'Sehemu 15: muhtasari, top posts, royalty, funnel, mengineyo'
                        : '15 sections: summary, top posts, royalties, funnel & more',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.85)),
          ],
        ),
      ),
    );
  }
}

class _OtherRevenueLink extends StatelessWidget {
  final bool isSw;
  const _OtherRevenueLink({required this.isSw});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.pushNamed(context, '/revenue');
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kSurface,
          border: Border.all(color: _kBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.account_balance_wallet_rounded, size: 20, color: _kPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSw ? 'Mapato Mengine (siyo ya creator)' : 'Other revenue (non-creator)',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isSw
                        ? 'Duka, biashara, michango, ushirikiano wa Tajirika'
                        : 'Shop, businesses, contributions, Tajirika partnership',
                    style: const TextStyle(fontSize: 11, color: _kSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _kSecondary),
          ],
        ),
      ),
    );
  }
}

class _HowItWorksLink extends StatelessWidget {
  final bool isSw;
  const _HowItWorksLink({required this.isSw});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.pushNamed(context, '/creator-tier');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.help_outline_rounded, size: 16, color: _kTertiary),
            const SizedBox(width: 6),
            Text(
              isSw ? 'Jinsi mapato yanavyofanya kazi' : 'How earnings work',
              style: const TextStyle(fontSize: 12, color: _kSecondary, decoration: TextDecoration.underline),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE5E5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD32F2F)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 18, color: Color(0xFFD32F2F)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: Color(0xFFD32F2F)),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFD32F2F)),
            child: const Text('Retry', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ─── Category labels + icons ───────────────────────────────────────────

String _categoryLabel(CreatorRevenueCategory c, bool isSw) {
  switch (c) {
    case CreatorRevenueCategory.posts:
      return isSw ? 'Posts' : 'Posts';
    case CreatorRevenueCategory.streams:
      return isSw ? 'Live' : 'Streams';
    case CreatorRevenueCategory.subscribers:
      return isSw ? 'Wafuasi' : 'Subscribers';
    case CreatorRevenueCategory.brandDeals:
      return isSw ? 'Brand' : 'Brand Deals';
    case CreatorRevenueCategory.adRevenue:
      return isSw ? 'Matangazo' : 'Ad Revenue';
    case CreatorRevenueCategory.photos:
      return isSw ? 'Picha Zangu' : 'My Photos';
    case CreatorRevenueCategory.videos:
      return isSw ? 'Video Zangu' : 'My Videos';
    case CreatorRevenueCategory.music:
      return isSw ? 'Muziki Wangu' : 'My Music';
    case CreatorRevenueCategory.files:
      return isSw ? 'Faili Zangu' : 'My Files';
  }
}

IconData _categoryIcon(CreatorRevenueCategory c) {
  switch (c) {
    case CreatorRevenueCategory.posts:
      return Icons.article_rounded;
    case CreatorRevenueCategory.streams:
      return Icons.live_tv_rounded;
    case CreatorRevenueCategory.subscribers:
      return Icons.workspace_premium_rounded;
    case CreatorRevenueCategory.brandDeals:
      return Icons.handshake_rounded;
    case CreatorRevenueCategory.adRevenue:
      return Icons.campaign_rounded;
    case CreatorRevenueCategory.photos:
      return Icons.photo_library_rounded;
    case CreatorRevenueCategory.videos:
      return Icons.video_library_rounded;
    case CreatorRevenueCategory.music:
      return Icons.library_music_rounded;
    case CreatorRevenueCategory.files:
      return Icons.folder_copy_rounded;
  }
}

String _fmt(double v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
  return v.toStringAsFixed(0);
}
