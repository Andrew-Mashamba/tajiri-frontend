// lib/creator/screens/category_revenue_screen.dart
//
// Detail screen for one creator-revenue category that aggregates
// across all the category's backend sources. Implements the canonical
// "Hero + History + How it works" layout from
// docs/CREATOR_REVENUE_TAXONOMY.md §5.
//
// Categories that map to multiple backend sources (e.g. Posts =
// tips + creator_fund + ppv_unlocks + affiliate) sum here so the
// creator sees one number per category, not 4 sub-rows.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_strings_scope.dart';
import '../../widgets/tajiri_app_bar.dart';
import '../models/income_source.dart';
import 'income_source_detail_screen.dart';
import 'creator_revenue_screen.dart' show CreatorRevenueCategory;

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kBorder = Color(0xFFE5E5E5);
const Color _kSurface = Colors.white;
const Color _kBackground = Color(0xFFFAFAFA);

class CategoryRevenueScreen extends StatelessWidget {
  final int creatorId;
  final CreatorRevenueCategory category;
  final List<IncomeSource> sources;

  const CategoryRevenueScreen({
    super.key,
    required this.creatorId,
    required this.category,
    required this.sources,
  });

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: TajiriAppBar(title: _categoryLabel(category, isSw)),
      body: SafeArea(
        child: RefreshIndicator(
          color: _kPrimary,
          // Pop back to CreatorRevenueScreen on pull — that screen owns
          // the data load + has its own RefreshIndicator. Returning a
          // truthy result tells the parent to refetch.
          onRefresh: () async {
            if (Navigator.canPop(context)) {
              Navigator.pop(context, true);
            }
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
            _HeroCard(category: category, sources: sources, isSw: isSw),
            const SizedBox(height: 20),
            _SectionLabel(isSw ? 'HISTORIA YA HIVI KARIBUNI' : 'RECENT HISTORY'),
            const SizedBox(height: 8),
            _HistoryCard(sources: sources, isSw: isSw),
            const SizedBox(height: 20),
            _SectionLabel(isSw ? 'JINSI INAVYOFANYA KAZI' : 'HOW IT WORKS'),
            const SizedBox(height: 8),
            _HowItWorksCard(sources: sources, isSw: isSw),
            const SizedBox(height: 20),
            if (sources.length > 1) ...[
              _SectionLabel(isSw ? 'VYANZO VINAVYOCHANGIA' : 'CONTRIBUTING SOURCES'),
              const SizedBox(height: 8),
              _SourcesBreakdownCard(
                sources: sources,
                creatorId: creatorId,
                isSw: isSw,
              ),
            ],
          ],
          ),
        ),
      ),
    );
  }
}

// ─── Hero card — total this-period earnings + cleared/pending ──────────

class _HeroCard extends StatelessWidget {
  final CreatorRevenueCategory category;
  final List<IncomeSource> sources;
  final bool isSw;

  const _HeroCard({required this.category, required this.sources, required this.isSw});

  @override
  Widget build(BuildContext context) {
    final totals = _aggregate(sources);
    final period = sources.firstWhere(
      (s) => s.currentPeriod != null,
      orElse: () => sources.first,
    ).currentPeriod;
    final periodLabel = _periodLabel(period?.period, isSw);
    final hasAnyEarning = totals.netMinor > 0;

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
                child: Icon(_categoryIcon(category), color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                isSw ? 'Mapato $periodLabel · halisi' : '$periodLabel · net',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.70),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _fmtAmount(totals.netMinor / 100.0),
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
                  totals.currency,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.80),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _HeroPill(
                  label: isSw ? 'Imeisha' : 'Cleared',
                  value: _fmtAmount(totals.clearedMinor / 100.0),
                  hint: isSw
                      ? 'Inalipwa baada ya siku 30'
                      : 'Paid out after 30 days',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HeroPill(
                  label: isSw ? 'Inangoja' : 'Pending',
                  value: _fmtAmount(totals.pendingMinor / 100.0),
                  hint: isSw ? 'Itaisha hivi karibuni' : 'Clearing soon',
                ),
              ),
            ],
          ),
          if (!hasAnyEarning) ...[
            const SizedBox(height: 10),
            Text(
              isSw
                  ? 'Endelea kuchapisha — mapato yanaonekana hapa.'
                  : 'Keep posting — earnings show up here.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.70),
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final String label;
  final String value;
  final String hint;

  const _HeroPill({required this.label, required this.value, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.70), fontSize: 11),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            'TZS $value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            hint,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 10),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── History card — last N transactions across category sources ────────

class _HistoryCard extends StatelessWidget {
  final List<IncomeSource> sources;
  final bool isSw;

  const _HistoryCard({required this.sources, required this.isSw});

  @override
  Widget build(BuildContext context) {
    final allHistory = <_HistoryRow>[];
    for (final src in sources) {
      for (final h in src.recentHistory) {
        allHistory.add(_HistoryRow(item: h, source: src));
      }
    }
    allHistory.sort((a, b) => b.item.occurredAt.compareTo(a.item.occurredAt));
    final shown = allHistory.take(10).toList();

    if (shown.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorder),
        ),
        child: Center(
          child: Text(
            isSw ? 'Hakuna shughuli ya hivi karibuni.' : 'No recent activity yet.',
            style: const TextStyle(fontSize: 13, color: _kSecondary),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          for (var i = 0; i < shown.length; i++) ...[
            _HistoryRowTile(row: shown[i]),
            if (i < shown.length - 1)
              const Divider(height: 1, color: _kBorder, indent: 16, endIndent: 16),
          ],
        ],
      ),
    );
  }
}

class _HistoryRow {
  final HistoryItem item;
  final IncomeSource source;
  const _HistoryRow({required this.item, required this.source});
}

class _HistoryRowTile extends StatelessWidget {
  final _HistoryRow row;
  const _HistoryRowTile({required this.row});

  @override
  Widget build(BuildContext context) {
    final postId = row.item.postId;
    final streamId = row.item.streamId;
    final isTappable = postId != null || streamId != null;

    final body = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                row.source.icon ?? '·',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.item.actorUsername ?? row.source.displayName.en,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _shortDate(row.item.occurredAt),
                  style: const TextStyle(fontSize: 11, color: _kTertiary),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            'TZS ${_fmtAmount(row.item.netMinor / 100.0)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _kPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          if (isTappable) ...[
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: _kTertiary, size: 18),
          ],
        ],
      ),
    );

    if (!isTappable) return body;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        if (postId != null) {
          Navigator.pushNamed(context, '/post/$postId');
        } else if (streamId != null) {
          Navigator.pushNamed(context, '/stream/$streamId');
        }
      },
      child: body,
    );
  }
}

// ─── How it works ──────────────────────────────────────────────────────

class _HowItWorksCard extends StatelessWidget {
  final List<IncomeSource> sources;
  final bool isSw;

  const _HowItWorksCard({required this.sources, required this.isSw});

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
          for (var i = 0; i < sources.length; i++) ...[
            _formulaRow(sources[i], isSw),
            if (i < sources.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: _kBorder),
              ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: _kBorder),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.schedule_rounded, size: 16, color: _kSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isSw
                      ? 'Mapato yana dirisha la siku 30 — yanapojengeka na kuwa "Imeisha" yanalipwa kwenye mkoba wako.'
                      : 'Earnings have a 30-day window — once they clear they become available in your wallet.',
                  style: const TextStyle(fontSize: 12, color: _kSecondary, height: 1.45),
                  maxLines: 4, overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _formulaRow(IncomeSource src, bool isSw) {
    final math = src.math;
    final ownStatement = math?.ownStatement;
    final formula = math?.formula ?? '';
    final summary = ownStatement != null
        ? (isSw ? ownStatement.sw : ownStatement.en)
        : (isSw ? src.displayName.sw : src.displayName.en);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(src.icon ?? '·', style: const TextStyle(fontSize: 14)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isSw ? src.displayName.sw : src.displayName.en,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                summary,
                style: const TextStyle(fontSize: 12, color: _kSecondary, height: 1.4),
                maxLines: 3, overflow: TextOverflow.ellipsis,
              ),
              if (formula.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  formula,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _kTertiary,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Per-source breakdown (when category aggregates multiple sources) ──

class _SourcesBreakdownCard extends StatelessWidget {
  final List<IncomeSource> sources;
  final int creatorId;
  final bool isSw;

  const _SourcesBreakdownCard({
    required this.sources,
    required this.creatorId,
    required this.isSw,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          for (var i = 0; i < sources.length; i++) ...[
            _SourceRow(
              source: sources[i],
              creatorId: creatorId,
              isSw: isSw,
            ),
            if (i < sources.length - 1)
              const Divider(height: 1, color: _kBorder, indent: 16, endIndent: 16),
          ],
        ],
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  final IncomeSource source;
  final int creatorId;
  final bool isSw;

  const _SourceRow({
    required this.source,
    required this.creatorId,
    required this.isSw,
  });

  @override
  Widget build(BuildContext context) {
    final amount = (source.currentPeriod?.netMinor ?? 0) / 100.0;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => IncomeSourceDetailScreen(
              creatorId: creatorId,
              sourceId: source.id,
              initialSource: source,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(source.icon ?? '·', style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSw ? source.displayName.sw : source.displayName.en,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isSw ? source.stateLabel.sw : source.stateLabel.en,
                    style: const TextStyle(fontSize: 11, color: _kTertiary),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              'TZS ${_fmtAmount(amount)}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _kPrimary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: _kTertiary, size: 18),
          ],
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
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _kTertiary,
            letterSpacing: 0.6,
          ),
          maxLines: 1, overflow: TextOverflow.ellipsis,
        ),
      );
}

// ─── Helpers ───────────────────────────────────────────────────────────

class _CategoryTotals {
  final int grossMinor;
  final int netMinor;
  final int clearedMinor;
  final int pendingMinor;
  final String currency;

  const _CategoryTotals({
    required this.grossMinor,
    required this.netMinor,
    required this.clearedMinor,
    required this.pendingMinor,
    required this.currency,
  });
}

_CategoryTotals _aggregate(List<IncomeSource> sources) {
  var gross = 0;
  var net = 0;
  var currency = 'TZS';
  for (final s in sources) {
    final p = s.currentPeriod;
    if (p == null) continue;
    gross += p.grossMinor;
    net += p.netMinor;
    currency = p.currency;
  }
  // We don't have separate cleared/pending fields on IncomeSource — until
  // backend exposes them, treat the entire current-period net as the
  // "pending → will be cleared" bucket and lifetime-cleared as 0.
  return _CategoryTotals(
    grossMinor: gross,
    netMinor: net,
    clearedMinor: 0,
    pendingMinor: net,
    currency: currency,
  );
}

String _categoryLabel(CreatorRevenueCategory c, bool isSw) {
  switch (c) {
    case CreatorRevenueCategory.posts:
      return 'Posts';
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

String _periodLabel(IncomePeriod? p, bool isSw) {
  switch (p) {
    case IncomePeriod.week:
      return isSw ? 'wiki hii' : 'this week';
    case IncomePeriod.quarter:
      return isSw ? 'robo hii' : 'this quarter';
    case IncomePeriod.all:
      return isSw ? 'jumla' : 'all-time';
    case IncomePeriod.month:
    case null:
      return isSw ? 'mwezi huu' : 'this month';
  }
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

String _shortDate(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return '${dt.day}/${dt.month}/${dt.year.toString().substring(2)}';
}
