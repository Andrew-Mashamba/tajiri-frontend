// Mapato (Income Sources) — the panoramic landing for the lib/creator/ module.
// Spec: docs/superpowers/specs/2026-05-02-creator-income-sources-design.md §3
//
// This file exposes two widgets:
//   - IncomeSourcesView — body-only, embeddable inside the profile screen's
//     creator tab (no Scaffold/AppBar of its own).
//   - IncomeSourcesScreen — full Scaffold wrapper with AppBar + a "Stats"
//     action that pushes CreatorStatsScreen (tier/streak/multipliers).
//
// Sections, top to bottom:
//   1. Wallet hero (Tajiri Pay)
//   2. Period pills (Wiki / Mwezi / Robo / Yote)
//   3. KPI tiles row (this period · top source · unlocked count)
//   4. Filter chips (All / Active / Locked)
//   5. Live pinned card (only when streaming)
//   6. Unified source list (mixed active + locked, separated by state badges)
//   7. "How it works" footer link

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../screens/wallet/payout_request_screen.dart';
import '../../services/local_storage_service.dart';
import '../models/income_source.dart';
import '../services/income_sources_service.dart';
import '../widgets/kpi_tile.dart';
import '../widgets/live_pinned_card.dart';
import '../widgets/period_pill_selector.dart';
import '../widgets/source_row_card.dart';
import '../widgets/wallet_hero_card.dart';
import 'creator_stats_screen.dart';
import 'income_activity_screen.dart';
import 'income_source_detail_screen.dart';

enum _SourceFilter { all, active, locked }

/// Full-screen wrapper used by the `/creator` route. Embeds [IncomeSourcesView]
/// inside a Scaffold + AppBar with a "Stats" action that opens the tier /
/// streak / multipliers view.
class IncomeSourcesScreen extends StatelessWidget {
  final int creatorId;
  const IncomeSourcesScreen({super.key, required this.creatorId});

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final isSw = s?.isSwahili ?? false;
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(
          isSw ? 'Mapato' : 'Income',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            tooltip: isSw ? 'Takwimu' : 'Stats',
            icon: const Icon(Icons.insights_rounded, color: Color(0xFF1A1A1A)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreatorStatsScreen(creatorId: creatorId),
              ),
            ),
          ),
        ],
      ),
      body: IncomeSourcesView(creatorId: creatorId),
    );
  }
}

/// Embeddable body for the income sources surface — no Scaffold or AppBar.
/// Used inside the profile screen's "Creator" tab and as the body of
/// [IncomeSourcesScreen].
class IncomeSourcesView extends StatefulWidget {
  final int creatorId;

  const IncomeSourcesView({super.key, required this.creatorId});

  @override
  State<IncomeSourcesView> createState() => _IncomeSourcesViewState();
}

class _IncomeSourcesViewState extends State<IncomeSourcesView> {
  final IncomeSourcesService _service = IncomeSourcesService();

  IncomePeriod _period = IncomePeriod.month;
  _SourceFilter _filter = _SourceFilter.all;
  bool _loading = true;
  String? _error;
  IncomeSourcesResponse? _response;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (kDebugMode) debugPrint('[Mapato] load period=${_period.wire}');
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
      if (resp == null) {
        setState(() {
          _loading = false;
          _error = 'failed';
        });
        return;
      }
      setState(() {
        _response = resp;
        _loading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('[Mapato] load error: $e');
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

  void _setFilter(_SourceFilter f) {
    if (f == _filter) return;
    setState(() => _filter = f);
  }

  void _openWithdraw() {
    final balance = (_response?.summary.walletBalanceMinor ?? 0) / 100.0;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PayoutRequestScreen(
          currentUserId: widget.creatorId,
          availableBalance: balance,
        ),
      ),
    );
  }

  void _openActivity() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IncomeActivityScreen(creatorId: widget.creatorId),
      ),
    );
  }

  void _openSource(IncomeSource source) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IncomeSourceDetailScreen(
          creatorId: widget.creatorId,
          sourceId: source.id,
          initialSource: source,
        ),
      ),
    ).then((_) => _load());
  }

  List<IncomeSource> _filteredSources() {
    final all = _response?.sources ?? const [];
    switch (_filter) {
      case _SourceFilter.all:
        return all;
      case _SourceFilter.active:
        return all.where((s) => s.state.isActive).toList(growable: false);
      case _SourceFilter.locked:
        return all.where((s) => s.state.isLocked).toList(growable: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final isSw = s?.isSwahili ?? false;

    return SafeArea(
      child: RefreshIndicator(
        color: const Color(0xFF1A1A1A),
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
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF1A1A1A),
                      ),
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
    final sources = _filteredSources();
    final tally = _response?.liveTally;
    final hasError = _error != null && _response == null;

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        if (hasError)
          _ErrorBanner(
            message: isSw
                ? 'Imeshindwa kupakua data ya mapato. Vuta chini kujaribu tena.'
                : 'Could not load income data. Pull down to retry.',
            onRetry: _load,
          )
        else ...[
          WalletHeroCard(
            summary: summary,
            onWithdraw: _openWithdraw,
            onActivity: _openActivity,
          ),
          const SizedBox(height: 14),
          PeriodPillSelector(selected: _period, onChanged: _setPeriod),
          const SizedBox(height: 12),
          _KpiRow(summary: summary, isSw: isSw),
          const SizedBox(height: 16),
          if (tally != null) LivePinnedCard(tally: tally, onTap: () {}),
          _SectionHeader(
            title: isSw ? 'Vyanzo vya Mapato' : 'Income Sources',
            chips: _filterChips(isSw),
          ),
          const SizedBox(height: 6),
          if (sources.isEmpty)
            _EmptyState(filter: _filter, isSw: isSw)
          else
            for (final src in sources)
              SourceRowCard(source: src, onTap: () => _openSource(src)),
          const SizedBox(height: 12),
          _HowItWorksLink(isSw: isSw),
        ],
      ],
    );
  }

  Widget _filterChips(bool isSw) {
    final items = <_FilterChipModel>[
      _FilterChipModel(_SourceFilter.all, isSw ? 'Yote' : 'All'),
      _FilterChipModel(_SourceFilter.active, isSw ? 'Hai' : 'Active'),
      _FilterChipModel(_SourceFilter.locked, isSw ? 'Lala' : 'Locked'),
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final item in items) ...[
          _FilterChip(
            label: item.label,
            selected: _filter == item.filter,
            onTap: () => _setFilter(item.filter),
          ),
          if (item != items.last) const SizedBox(width: 4),
        ],
      ],
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  final IncomeSummary summary;
  final bool isSw;
  const _KpiRow({required this.summary, required this.isSw});

  @override
  Widget build(BuildContext context) {
    final delta = summary.thisPeriodDeltaPct;
    final deltaPrefix = delta >= 0 ? '+' : '';
    final deltaText = isSw
        ? '$deltaPrefix${delta.toStringAsFixed(0)}% vs mwezi uliopita'
        : '$deltaPrefix${delta.toStringAsFixed(0)}% vs prev';

    final unlockedFraction = '${summary.unlockedCount}'
        '/${summary.totalCount}';

    // IntrinsicHeight + CrossAxisAlignment.stretch makes all 3 tiles match
    // the tallest tile's height. Without IntrinsicHeight, `stretch` would
    // hand the tiles unbounded vertical constraints (the parent ListView
    // is itself unbounded), which crashes layout.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: KpiTile(
              label: (isSw ? 'KIPINDI HIKI' : 'THIS PERIOD'),
              value: formatTzsMinorBare(summary.thisPeriodNetMinor),
              subtitle: deltaText,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: KpiTile(
              label: (isSw ? 'CHANZO BORA' : 'TOP SOURCE'),
              value: summary.topSourceId ?? '—',
              subtitle: summary.topSourceSharePct > 0
                  ? '${summary.topSourceSharePct.toStringAsFixed(0)}%'
                  : '',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: KpiTile(
              label: (isSw ? 'VIMEFUNGULIWA' : 'UNLOCKED'),
              value: unlockedFraction,
              trailing: ProgressBar(
                pct: summary.totalCount == 0
                    ? 0
                    : (summary.unlockedCount * 100 / summary.totalCount),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget chips;
  const _SectionHeader({required this.title, required this.chips});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          chips,
        ],
      ),
    );
  }
}

class _FilterChipModel {
  final _SourceFilter filter;
  final String label;
  const _FilterChipModel(this.filter, this.label);
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? const Color(0xFF1A1A1A) : const Color(0xFFE5E5E5),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: selected ? const Color(0xFFFAFAFA) : const Color(0xFF666666),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final _SourceFilter filter;
  final bool isSw;
  const _EmptyState({required this.filter, required this.isSw});

  @override
  Widget build(BuildContext context) {
    final msg = filter == _SourceFilter.active
        ? (isSw ? 'Hakuna chanzo hai bado' : 'No active sources yet')
        : filter == _SourceFilter.locked
            ? (isSw ? 'Vyanzo vyote vimefunguliwa' : 'All sources unlocked')
            : (isSw ? 'Hakuna data' : 'No data');
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 56,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 8),
          Text(
            msg,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _HowItWorksLink extends StatelessWidget {
  final bool isSw;
  const _HowItWorksLink({required this.isSw});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E5E5), style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.menu_book_outlined, size: 16, color: Color(0xFF666666)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              isSw
                  ? 'Jifunze: vyanzo vyote vinafanyaje kazi'
                  : 'Learn how each source works',
              style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF9A9A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 18, color: Color(0xFFC62828)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: Color(0xFF8B0000)),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFC62828)),
            child: const Text('Retry', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
