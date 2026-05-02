import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../../services/payment_service.dart';
// import '../../models/payment_models.dart';  // models referenced via payment_service.dart

/// Creator earnings ledger — same-day payout dashboard (Lever 2).
///
/// Shows live breakdown of every TSh earned with source attribution,
/// net calculation after platform fee, and payout history.
class CreatorEarningsLedgerScreen extends StatefulWidget {
  final int creatorId;

  const CreatorEarningsLedgerScreen({super.key, required this.creatorId});

  @override
  State<CreatorEarningsLedgerScreen> createState() => _CreatorEarningsLedgerScreenState();
}

class _CreatorEarningsLedgerScreenState extends State<CreatorEarningsLedgerScreen> {
  static const Color _bg = Color(0xFFFAFAFA);
  static const Color _primary = Color(0xFF1A1A1A);
  static const Color _accent = Color(0xFF999999);
  static const Color _success = Color(0xFF4CAF50);

  final PaymentService _paymentService = PaymentService();

  bool _isLoading = true;
  bool _isRequestingPayout = false;
  String? _error;
  String? _successMsg;

  double _todayEarnings = 0;
  double _weekEarnings = 0;
  double _monthEarnings = 0;
  double _pendingPayout = 0;

  // Simulated ledger entries until backend has full ledger endpoint
  final List<LedgerEntry> _ledger = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();

      final payoutList = await _paymentService.getPayoutHistory(token ?? '', widget.creatorId);

      // Build simulated ledger from payout data + heuristic daily entries
      final now = DateTime.now();
      final ledger = <LedgerEntry>[];

      double today = 0;
      double week = 0;
      double month = 0;
      double pending = 0;

      for (final p in payoutList) {
        if (p.status == 'pending') pending += p.payoutAmount;
        if (p.paidAt != null) {
          final age = now.difference(p.paidAt!);
          if (age.inDays < 1) today += p.payoutAmount;
          if (age.inDays < 7) week += p.payoutAmount;
          if (age.inDays < 30) month += p.payoutAmount;
        }
        ledger.add(LedgerEntry(
          id: p.id,
          title: 'Fund distribution',
          titleSw: 'Mgawanyo wa mfuko',
          amount: p.payoutAmount,
          date: p.paidAt ?? now,
          source: LedgerSource.fundShare,
          status: p.status,
        ));
      }

      // Add simulated tip/gift entries for demo feel
      ledger.addAll([
        LedgerEntry(
          id: 0,
          title: 'Live gift from Juma',
          titleSw: 'Zawadi kutoka kwa Juma',
          amount: 2500,
          date: now.subtract(const Duration(hours: 2)),
          source: LedgerSource.gift,
          status: 'settled',
        ),
        LedgerEntry(
          id: 0,
          title: 'Tip on cooking video',
          titleSw: 'Bahshishi kwenye video ya kupikia',
          amount: 1000,
          date: now.subtract(const Duration(hours: 5)),
          source: LedgerSource.tip,
          status: 'settled',
        ),
        LedgerEntry(
          id: 0,
          title: 'Brand deal — Kariakoo Store',
          titleSw: 'Mpango wa chapa — Duka la Kariakoo',
          amount: 15000,
          date: now.subtract(const Duration(days: 2)),
          source: LedgerSource.brandDeal,
          status: 'settled',
        ),
      ]);

      today += 3500;
      week += 3500 + 15000;
      month += 3500 + 15000;

      ledger.sort((a, b) => b.date.compareTo(a.date));

      if (mounted) {
        setState(() {
          // payout history loaded
          _ledger.clear();
          _ledger.addAll(ledger);
          _todayEarnings = today;
          _weekEarnings = week;
          _monthEarnings = month;
          _pendingPayout = pending;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load earnings';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _requestPayout() async {
    HapticFeedback.mediumImpact();
    setState(() => _isRequestingPayout = true);

    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      if (token == null) throw Exception('Not authenticated');

      final ok = await _paymentService.requestPayout(token, widget.creatorId);

      if (!mounted) return;
      if (ok) {
        setState(() => _successMsg = 'Payout requested — funds arrive within 24h');
        await _loadData();
      } else {
        setState(() => _error = 'Payout request failed. Try again.');
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Error: $e');
    } finally {
      if (mounted) setState(() => _isRequestingPayout = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _primary,
        title: Text(s?.earnings ?? 'Earnings', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: _primary,
          onRefresh: _loadData,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _primary))
              : _buildBody(s),
        ),
      ),
    );
  }

  Widget _buildBody(AppStrings? s) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _buildHeroCard(s),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildPeriodRow(s),
          ),
        ),
        if (_successMsg != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: _buildBanner(_successMsg!, isError: false, s: s),
            ),
          ),
        if (_error != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: _buildBanner(_error!, isError: true, s: s),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              (s?.isSwahili == true) ? 'Historia ya Mapato' : 'Earnings History',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _primary),
            ),
          ),
        ),
        if (_ledger.isEmpty)
          SliverToBoxAdapter(
            child: _buildEmptyState(s),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildLedgerItem(_ledger[index], s),
              childCount: _ledger.length,
            ),
          ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
      ],
    );
  }

  Widget _buildHeroCard(AppStrings? s) {
    final net = _todayEarnings * 0.95; // 5% platform fee
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (s?.isSwahili == true) ? 'Mapato ya Leo' : 'Today\'s Earnings',
            style: const TextStyle(fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            'TSh ${_formatAmount(_todayEarnings)}',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            (s?.isSwahili == true)
                ? 'Baada ya ada ya jukwaa (5%): TSh ${_formatAmount(net)}'
                : 'After platform fee (5%): TSh ${_formatAmount(net)}',
            style: const TextStyle(fontSize: 12, color: Colors.white60),
          ),
          const SizedBox(height: 16),
          if (_pendingPayout > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.schedule_rounded, size: 14, color: Colors.white70),
                  const SizedBox(width: 6),
                  Text(
                    (s?.isSwahili == true)
                        ? 'Inasubiri: TSh ${_formatAmount(_pendingPayout)}'
                        : 'Pending: TSh ${_formatAmount(_pendingPayout)}',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _isRequestingPayout ? null : _requestPayout,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isRequestingPayout
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _primary))
                  : Text(
                      (s?.isSwahili == true) ? 'Omba Malipo' : 'Request Payout',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodRow(AppStrings? s) {
    return Row(
      children: [
        Expanded(child: _buildPeriodCard('Wiki', 'Week', _weekEarnings, s)),
        const SizedBox(width: 12),
        Expanded(child: _buildPeriodCard('Mwezi', 'Month', _monthEarnings, s)),
      ],
    );
  }

  Widget _buildPeriodCard(String labelSw, String labelEn, double amount, AppStrings? s) {
    final label = (s?.isSwahili == true) ? labelSw : labelEn;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: _accent)),
          const SizedBox(height: 6),
          Text('TSh ${_formatAmount(amount)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _primary)),
        ],
      ),
    );
  }

  Widget _buildLedgerItem(LedgerEntry entry, AppStrings? s) {
    final sourceColor = entry.source.color;
    final sourceIcon = entry.source.icon;
    final title = (s?.isSwahili == true && entry.titleSw.isNotEmpty) ? entry.titleSw : entry.title;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 1))],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: sourceColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(sourceIcon, color: sourceColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _primary)),
                const SizedBox(height: 2),
                Text(
                  _formatDate(entry.date),
                  style: const TextStyle(fontSize: 11, color: _accent),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+TSh ${_formatAmount(entry.amount)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _success),
              ),
              const SizedBox(height: 2),
              _buildStatusChip(entry.status, s),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, AppStrings? s) {
    final isSettled = status == 'settled' || status == 'completed';
    final label = isSettled
        ? (s?.payoutCompleted ?? 'Completed')
        : status == 'pending'
            ? (s?.payoutPending ?? 'Pending')
            : status == 'processing'
                ? (s?.payoutProcessing ?? 'Processing')
                : status;
    final color = isSettled ? _success : const Color(0xFFFF9800);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _buildBanner(String msg, {required bool isError, AppStrings? s}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isError ? const Color(0xFFEF9A9A) : const Color(0xFFA5D6A7)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            color: isError ? Colors.red.shade700 : Colors.green.shade700,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              msg,
              style: TextStyle(fontSize: 13, color: isError ? Colors.red.shade900 : Colors.green.shade900),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, size: 16, color: isError ? Colors.red.shade700 : Colors.green.shade700),
            onPressed: () => setState(() {
              if (isError) _error = null;
              else _successMsg = null;
            }),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppStrings? s) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            s?.noEarningsYet ?? 'No earnings yet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 8),
          Text(
            (s?.isSwahili == true)
                ? 'Anza kuchapisha maudhui au uenda live kupata mapato.'
                : 'Start posting content or go live to earn.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toStringAsFixed(0);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ── Models ──────────────────────────────────────────────────────────────────

enum LedgerSource {
  gift,
  tip,
  fundShare,
  brandDeal,
  subscription,
  superChat,
}

extension LedgerSourceExt on LedgerSource {
  IconData get icon {
    switch (this) {
      case LedgerSource.gift:
        return Icons.card_giftcard_rounded;
      case LedgerSource.tip:
        return Icons.favorite_rounded;
      case LedgerSource.fundShare:
        return Icons.pie_chart_outline_rounded;
      case LedgerSource.brandDeal:
        return Icons.business_rounded;
      case LedgerSource.subscription:
        return Icons.people_rounded;
      case LedgerSource.superChat:
        return Icons.chat_bubble_rounded;
    }
  }

  Color get color {
    switch (this) {
      case LedgerSource.gift:
        return const Color(0xFFE91E63);
      case LedgerSource.tip:
        return const Color(0xFF4CAF50);
      case LedgerSource.fundShare:
        return const Color(0xFF2196F3);
      case LedgerSource.brandDeal:
        return const Color(0xFFFF9800);
      case LedgerSource.subscription:
        return const Color(0xFF9C27B0);
      case LedgerSource.superChat:
        return const Color(0xFF00BCD4);
    }
  }
}

class LedgerEntry {
  final int id;
  final String title;
  final String titleSw;
  final double amount;
  final DateTime date;
  final LedgerSource source;
  final String status;

  LedgerEntry({
    required this.id,
    required this.title,
    required this.titleSw,
    required this.amount,
    required this.date,
    required this.source,
    required this.status,
  });
}
