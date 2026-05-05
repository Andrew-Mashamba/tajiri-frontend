// IncomeSourceDetailScreen — drill-in for a single income source.
// Spec §5 (anatomy) and §6 (state machine).
//
// Branches on `source.state`:
//   active variants (earning | live | pending | paused) →
//     hero net + math + insights + recent history + CTA
//   locked variants (locked | ready) →
//     hero progress + what-is-it + math preview + estimate + eligibility
//     checklist + accelerators + CTA

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../screens/wallet/payout_request_screen.dart';
import '../../services/local_storage_service.dart';
import '../models/income_source.dart';
import '../services/income_sources_service.dart';
import '../widgets/accelerator_row.dart';
import '../widgets/eligibility_checklist.dart';
import '../widgets/estimate_card.dart';
import '../widgets/history_row.dart';
import '../widgets/kpi_tile.dart';
import '../widgets/math_card.dart';
import '../widgets/state_badge.dart';

class IncomeSourceDetailScreen extends StatefulWidget {
  final int creatorId;
  final String sourceId;
  final IncomeSource? initialSource;

  const IncomeSourceDetailScreen({
    super.key,
    required this.creatorId,
    required this.sourceId,
    this.initialSource,
  });

  @override
  State<IncomeSourceDetailScreen> createState() =>
      _IncomeSourceDetailScreenState();
}

class _IncomeSourceDetailScreenState extends State<IncomeSourceDetailScreen> {
  final IncomeSourcesService _service = IncomeSourcesService();
  IncomeSource? _source;
  bool _loading = false;
  String? _inlineMessage;
  bool _inlineIsError = false;
  bool _activating = false;

  @override
  void initState() {
    super.initState();
    _source = widget.initialSource;
    _load();
  }

  Future<void> _load() async {
    if (kDebugMode) {
      debugPrint('[Mapato] detail load id=${widget.sourceId}');
    }
    setState(() => _loading = _source == null);
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      final detail = await _service.getSourceDetail(
        creatorId: widget.creatorId,
        sourceId: widget.sourceId,
        token: token,
      );
      if (!mounted) return;
      if (detail != null) {
        setState(() {
          _source = detail;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Mapato] detail error: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _runPrimaryCta() async {
    final source = _source;
    if (source == null || source.primaryCta == null) return;
    final action = source.primaryCta!.action;
    final s = AppStringsScope.of(context);
    final isSw = s?.isSwahili ?? false;
    final navigator = Navigator.of(context);

    switch (action) {
      case 'withdraw':
        final balance = (source.currentPeriod?.netMinor ?? 0) / 100.0;
        navigator.push(
          MaterialPageRoute(
            builder: (_) => PayoutRequestScreen(
              currentUserId: widget.creatorId,
              availableBalance: balance,
            ),
          ),
        );
        break;
      case 'subscribe_to_unlock':
        await _subscribeToUnlock();
        break;
      case 'activate':
        await _activate();
        break;
      default:
        if (kDebugMode) debugPrint('[Mapato] unknown CTA action: $action');
        if (mounted) {
          setState(() {
            _inlineMessage = isSw
                ? 'Hatua haijatekelezeka bado'
                : 'Action not implemented yet';
            _inlineIsError = false;
          });
        }
    }
  }

  Future<void> _subscribeToUnlock() async {
    final s = AppStringsScope.of(context);
    final isSw = s?.isSwahili ?? false;
    final storage = await LocalStorageService.getInstance();
    final token = storage.getAuthToken();
    final ok = await _service.notifyOnUnlock(
      creatorId: widget.creatorId,
      sourceId: widget.sourceId,
      token: token,
    );
    if (!mounted) return;
    setState(() {
      _inlineMessage = ok
          ? (isSw ? 'Tutakuarifu mara tu chanzo kitakapokuwa tayari.' : "We'll notify you when this source unlocks.")
          : (isSw ? 'Imeshindwa kujiandikisha. Jaribu tena.' : 'Could not subscribe. Try again.');
      _inlineIsError = !ok;
    });
  }

  Future<void> _activate() async {
    final s = AppStringsScope.of(context);
    final isSw = s?.isSwahili ?? false;
    setState(() => _activating = true);
    final storage = await LocalStorageService.getInstance();
    final token = storage.getAuthToken();
    final updated = await _service.activateSource(
      creatorId: widget.creatorId,
      sourceId: widget.sourceId,
      token: token,
    );
    if (!mounted) return;
    setState(() {
      _activating = false;
      if (updated != null) {
        _source = updated;
        _inlineMessage = isSw ? 'Chanzo kimezinduliwa.' : 'Source activated.';
        _inlineIsError = false;
      } else {
        _inlineMessage = isSw ? 'Imeshindwa kuzindua.' : 'Activation failed.';
        _inlineIsError = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final source = _source;
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(
          source?.displayName.forContext(context) ?? '',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: _loading || source == null
            ? const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              )
            : RefreshIndicator(
                color: const Color(0xFF1A1A1A),
                onRefresh: _load,
                child: source.state.isLocked
                    ? _LockedBody(
                        source: source,
                        inlineMessage: _inlineMessage,
                        inlineIsError: _inlineIsError,
                        onClearMessage: () => setState(() => _inlineMessage = null),
                        onPrimaryCta: _activating ? null : _runPrimaryCta,
                        ctaLoading: _activating,
                      )
                    : _ActiveBody(
                        source: source,
                        inlineMessage: _inlineMessage,
                        inlineIsError: _inlineIsError,
                        onClearMessage: () => setState(() => _inlineMessage = null),
                        onPrimaryCta: _runPrimaryCta,
                      ),
              ),
      ),
    );
  }
}

// ── Active variant body ────────────────────────────────────────────────────

class _ActiveBody extends StatelessWidget {
  final IncomeSource source;
  final String? inlineMessage;
  final bool inlineIsError;
  final VoidCallback onClearMessage;
  final VoidCallback onPrimaryCta;

  const _ActiveBody({
    required this.source,
    required this.inlineMessage,
    required this.inlineIsError,
    required this.onClearMessage,
    required this.onPrimaryCta,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final isSw = s?.isSwahili ?? false;
    final cp = source.currentPeriod;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        if (inlineMessage != null) ...[
          _InlineMessage(
            message: inlineMessage!,
            isError: inlineIsError,
            onClose: onClearMessage,
          ),
          const SizedBox(height: 12),
        ],
        _ActiveHero(source: source),
        const SizedBox(height: 12),
        if (source.math != null)
          MathCard(
            math: source.math!,
            title: isSw ? 'Hesabu' : 'Math',
          ),
        const SizedBox(height: 12),
        if (source.insights.isNotEmpty) ...[
          _InsightsCard(insights: source.insights, isSw: isSw),
          const SizedBox(height: 12),
        ],
        if (source.recentHistory.isNotEmpty) ...[
          _Card(
            title: isSw ? 'Hivi karibuni' : 'Recent',
            child: Column(
              children: [
                for (var i = 0; i < source.recentHistory.length; i++)
                  HistoryRowTile(
                    item: source.recentHistory[i],
                    last: i == source.recentHistory.length - 1,
                  ),
                if (cp != null && cp.count > source.recentHistory.length) ...[
                  const SizedBox(height: 6),
                  Text(
                    isSw
                        ? 'Ona zote (${cp.count}) →'
                        : 'See all (${cp.count}) →',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (source.primaryCta != null)
          _CtaPrimary(
            label: source.primaryCta!.label.forContext(context),
            onPressed: onPrimaryCta,
          ),
        if (source.secondaryCta != null) ...[
          const SizedBox(height: 8),
          _CtaSecondary(
            label: source.secondaryCta!.label.forContext(context),
            onPressed: () {},
          ),
        ],
      ],
    );
  }
}

class _ActiveHero extends StatelessWidget {
  final IncomeSource source;
  const _ActiveHero({required this.source});

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final isSw = s?.isSwahili ?? false;
    final cp = source.currentPeriod;
    final amountText = cp != null
        ? formatTzsMinor(cp.netMinor)
        : 'TSh 0';

    final subParts = <String>[];
    if (cp != null) {
      if (cp.count > 0) {
        final lbl = cp.countLabel.forContext(context);
        subParts.add('${cp.count}${lbl.isNotEmpty ? " $lbl" : ""}');
      }
      if (cp.averageMinor > 0) {
        subParts.add(
          '${isSw ? "wastani" : "avg"} ${formatTzsMinor(cp.averageMinor)}',
        );
      }
      if (cp.deltaPctVsPrev != 0) {
        final p = cp.deltaPctVsPrev >= 0 ? '+' : '';
        subParts.add('$p${cp.deltaPctVsPrev.toStringAsFixed(0)}%');
      }
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (isSw ? 'KIPINDI HIKI · NET' : 'THIS PERIOD · NET'),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xAACCCCCC),
              letterSpacing: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          if (source.icon != null)
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: Text(
                source.icon!,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            amountText,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFAFAFA),
              height: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subParts.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subParts.join(' · '),
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xCCCCCCCC),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),
          StateBadge(
            state: source.state,
            pulse: source.state == SourceState.live,
          ),
        ],
      ),
    );
  }
}

class _InsightsCard extends StatelessWidget {
  final List<IncomeInsight> insights;
  final bool isSw;
  const _InsightsCard({required this.insights, required this.isSw});

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: isSw ? 'Maarifa' : 'Insights',
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.6,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        children: [
          for (final ins in insights.take(4))
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ins.label.forContext(context).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF666666),
                      letterSpacing: 0.8,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ins.value.forContext(context),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Locked variant body ────────────────────────────────────────────────────

class _LockedBody extends StatelessWidget {
  final IncomeSource source;
  final String? inlineMessage;
  final bool inlineIsError;
  final VoidCallback onClearMessage;
  final VoidCallback? onPrimaryCta;
  final bool ctaLoading;

  const _LockedBody({
    required this.source,
    required this.inlineMessage,
    required this.inlineIsError,
    required this.onClearMessage,
    required this.onPrimaryCta,
    required this.ctaLoading,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final isSw = s?.isSwahili ?? false;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        if (inlineMessage != null) ...[
          _InlineMessage(
            message: inlineMessage!,
            isError: inlineIsError,
            onClose: onClearMessage,
          ),
          const SizedBox(height: 12),
        ],
        _LockedHero(source: source, isSw: isSw),
        const SizedBox(height: 12),
        if (source.math != null) ...[
          MathCard(
            math: source.math!,
            title: isSw ? 'Hesabu (jinsi unavyolipwa)' : 'Math (how you get paid)',
          ),
          const SizedBox(height: 12),
        ],
        if (source.estimate != null) ...[
          EstimateCard(estimate: source.estimate!),
          const SizedBox(height: 12),
        ],
        if (source.eligibility != null &&
            source.eligibility!.rules.isNotEmpty) ...[
          _Card(
            title: isSw ? 'Vigezo vya kufungua' : 'Unlock criteria',
            child: EligibilityChecklist(rules: source.eligibility!.rules),
          ),
          const SizedBox(height: 12),
        ],
        if (source.accelerators.isNotEmpty) ...[
          _Card(
            title: isSw ? 'Jinsi ya kufungua haraka' : 'How to unlock faster',
            child: Column(
              children: [
                for (final a in source.accelerators)
                  AcceleratorRow(accelerator: a),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (source.primaryCta != null)
          _CtaPrimary(
            label: source.primaryCta!.label.forContext(context),
            onPressed: onPrimaryCta,
            loading: ctaLoading,
          ),
        if (source.secondaryCta != null) ...[
          const SizedBox(height: 8),
          _CtaSecondary(
            label: source.secondaryCta!.label.forContext(context),
            onPressed: () {},
          ),
        ],
      ],
    );
  }
}

class _LockedHero extends StatelessWidget {
  final IncomeSource source;
  final bool isSw;
  const _LockedHero({required this.source, required this.isSw});

  @override
  Widget build(BuildContext context) {
    final eligibility = source.eligibility;
    final blocking = eligibility?.blockingRule;

    String headline;
    String? subline;
    double? progressPct;

    if (blocking != null &&
        blocking.currentValue != null &&
        blocking.targetValue != null) {
      headline = '${blocking.currentValue} / ${blocking.targetValue}';
      final remaining = blocking.targetValue! - blocking.currentValue!;
      subline = isSw
          ? '${blocking.label.forContext(context).toLowerCase()} · $remaining ${remaining == 1 ? "zaidi" : "zaidi"} unahitaji'
          : '${blocking.label.forContext(context).toLowerCase()} · $remaining to go';
      progressPct = eligibility?.completionPct;
    } else if (eligibility != null) {
      headline = isSw ? 'Imefungwa' : 'Locked';
      subline = isSw
          ? 'Vigezo havijakamilika'
          : 'Eligibility incomplete';
      progressPct = eligibility.completionPct;
    } else {
      headline = isSw ? 'Imefungwa' : 'Locked';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'STATUS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF666666),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          if (source.icon != null)
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: Text(
                source.icon!,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            headline,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
              height: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subline != null) ...[
            const SizedBox(height: 4),
            Text(
              subline,
              style: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (progressPct != null) ...[
            const SizedBox(height: 10),
            ProgressBar(pct: progressPct, height: 6),
          ],
          const SizedBox(height: 10),
          StateBadge(state: source.state),
        ],
      ),
    );
  }
}

// ── Shared ────────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF666666),
              letterSpacing: 1.0,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _CtaPrimary extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  const _CtaPrimary({
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF1A1A1A),
          foregroundColor: const Color(0xFFFAFAFA),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFFAFAFA),
                ),
              )
            : Text(
                label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
      ),
    );
  }
}

class _CtaSecondary extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _CtaSecondary({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF1A1A1A),
          side: const BorderSide(color: Color(0xFFE5E5E5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  final String message;
  final bool isError;
  final VoidCallback onClose;
  const _InlineMessage({
    required this.message,
    required this.isError,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isError ? const Color(0xFFFFE5E5) : const Color(0xFFF5F5F5);
    final fg = isError ? const Color(0xFFD32F2F) : const Color(0xFF1A1A1A);
    final border = isError ? const Color(0xFFD32F2F) : const Color(0xFFE5E5E5);
    final icon = isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12, color: fg),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          InkWell(
            onTap: onClose,
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.close_rounded, color: fg, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}
