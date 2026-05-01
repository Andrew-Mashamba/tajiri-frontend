// lib/debts/pages/debts_overview_page.dart
//
// Credit bureau active loans: current user + each owned business.
// Manual bookkeeping remains on [DebtsPage] per business.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../business/business_notifier.dart';
import '../../business/biz_tab_wrapper.dart';
import '../../l10n/app_strings_scope.dart';
import '../../business/models/business_models.dart';
import '../../business/services/business_service.dart';
import '../../services/local_storage_service.dart';
import '../models/loans_overview_models.dart';
import 'debts_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

/// Profile tab entry: loads businesses (may be empty) then shows overview.
class DebtsOverviewEntry extends StatelessWidget {
  final int userId;

  /// `false` when opened via Vikumbusho "Open source" — shows top app bar + back.
  final bool embedInParent;

  const DebtsOverviewEntry({
    super.key,
    required this.userId,
    this.embedInParent = true,
  });

  @override
  Widget build(BuildContext context) {
    final notifier = BusinessNotifier.instance;
    if (!notifier.loaded) {
      notifier.load(userId);
    }
    return ValueListenableBuilder<List<Business>>(
      valueListenable: notifier,
      builder: (context, businesses, _) {
        if (!notifier.loaded) {
          const loading = Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _kPrimary,
            ),
          );
          // StandaloneRouteShell is not yet implemented — fall back to a
          // plain Scaffold for both embedded and standalone presentations.
          return const Scaffold(
            backgroundColor: _kBackground,
            body: loading,
          );
        }
        return DebtsOverviewPage(
          userId: userId,
          businesses: businesses,
          standalone: !embedInParent,
        );
      },
    );
  }
}

class DebtsOverviewPage extends StatefulWidget {
  final int userId;
  final List<Business> businesses;

  /// When `true`, shows an [AppBar] with back (Vikumbusho / standalone route).
  final bool standalone;

  const DebtsOverviewPage({
    super.key,
    required this.userId,
    required this.businesses,
    this.standalone = false,
  });

  @override
  State<DebtsOverviewPage> createState() => _DebtsOverviewPageState();
}

class _DebtsOverviewPageState extends State<DebtsOverviewPage> {
  final NumberFormat _nf = NumberFormat('#,###', 'en');

  String? _token;
  bool _loading = true;
  bool _syncing = false;
  String? _error;
  LoansOverview? _overview;

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(covariant DebtsOverviewPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldK = oldWidget.businesses.map((b) => b.id).join(',');
    final newK = widget.businesses.map((b) => b.id).join(',');
    if (oldK != newK) _load();
  }

  Future<void> _init() async {
    final storage = await LocalStorageService.getInstance();
    _token = storage.getAuthToken();
    await _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await BusinessService.getActiveLoansOverview(
        _token,
        widget.userId,
        widget.businesses,
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (res.success && res.data != null) {
          _overview = res.data;
        } else {
          _error = res.message ??
              (_sw ? 'Imeshindwa kupakia mikopo' : 'Failed to load loans');
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = _sw ? 'Hitilafu: $e' : 'Error: $e';
        });
      }
    }
  }

  Future<void> _syncAll() async {
    if (_token == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_sw ? 'Sasisha kutoka CRB?' : 'Refresh from credit bureau?'),
        content: Text(
          _sw
              ? 'Mikopo yako binafsi na ya biashara zako itasasishwa kutoka Creditinfo '
                  '(kama ruhusa na API ziko tayari). Gharama zinaweza kutokea.'
              : 'Your personal and business active loans will be refreshed from '
                  'Creditinfo where the backend is configured. Fees may apply.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_sw ? 'Ghairi' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_sw ? 'Sasisha' : 'Refresh'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _syncing = true);
    try {
      final res = await BusinessService.syncActiveLoansFromCrb(
        _token!,
        widget.businesses,
      );
      if (!mounted) return;
      setState(() => _syncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res.message ??
                (res.success
                    ? (_sw ? 'Imesasishwa' : 'Updated')
                    : (_sw ? 'Imeshindwa' : 'Failed')),
          ),
        ),
      );
      if (res.success) await _load();
    } catch (e) {
      if (mounted) {
        setState(() => _syncing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  void _openBusinessDebts(int businessId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => Scaffold(
          backgroundColor: _kBackground,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: _kBackground,
            foregroundColor: _kPrimary,
            title: Text(
              _sw ? 'Madeni — biashara' : 'Debts — business',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _kPrimary,
              ),
            ),
          ),
          body: DebtsPage(businessId: businessId),
        ),
      ),
    );
  }

  String _money(double v) => 'TZS ${_nf.format(v)}';

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: widget.standalone
          ? AppBar(
              backgroundColor: _kBackground,
              elevation: 0,
              scrolledUnderElevation: 1,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              title: Text(
                s?.profileTabLabel('biz_debts') ?? 'Debts',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                ),
              ),
            )
          : null,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _kPrimary,
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline_rounded,
                            size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: Text(_sw ? 'Jaribu tena' : 'Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: _kPrimary,
                  onRefresh: _load,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _sw ? 'Mikopo na madeni' : 'Loans & debts',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: _kPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _sw
                                    ? 'Mikopo hai kutoka taasisi ya mikopo (CRB), pamoja na madeni unayoweka mwenyewe kwa kila biashara.'
                                    : 'Active credit bureau facilities plus manual debts you track per business.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _pill(
                                    label: _syncing
                                        ? (_sw ? 'Inasasisha…' : 'Refreshing…')
                                        : (_sw
                                            ? 'Sasisha CRB'
                                            : 'Refresh CRB'),
                                    icon: Icons.cloud_download_rounded,
                                    filled: false,
                                    onTap: _syncing ? null : _syncAll,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_overview != null) ...[
                        _sectionTitle(
                          _sw ? 'Mikopo yako (mtumiaji)' : 'Your loans (personal)',
                        ),
                        if (_overview!.personal.isEmpty)
                          SliverToBoxAdapter(
                            child: _emptyHint(
                              _sw
                                  ? 'Hakuna mikopo ya CRB iliyopatikana bado. '
                                      'Sasisha CRB baada ya kuongeza taarifa za utambulisho.'
                                  : 'No personal bureau loans yet. Refresh after your '
                                      'profile has NIN/DOB for the credit bureau.',
                            ),
                          )
                        else
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (ctx, i) => _loanCard(_overview!.personal[i]),
                              childCount: _overview!.personal.length,
                            ),
                          ),
                        ..._buildBusinessSections(),
                      ],
                    ],
                  ),
                ),
    );
  }

  List<Widget> _buildBusinessSections() {
    final o = _overview!;
    final out = <Widget>[];

    if (widget.businesses.isEmpty) {
      out.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              _sw
                  ? 'Huna biashara iliyosajiliwa — ongeza biashara kwa ajili ya madeni ya biashara.'
                  : 'No registered business yet — add a business to track business debts.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
        ),
      );
      return out;
    }

    out.add(_sectionTitle(_sw ? 'Biashara zako' : 'Your businesses'));

    for (final b in widget.businesses) {
      if (b.id == null) continue;
      final id = b.id!;
      BusinessLoanSection? section;
      for (final s in o.businesses) {
        if (s.businessId == id) {
          section = s;
          break;
        }
      }
      final loans = section?.loans ?? const <CrbActiveLoan>[];

      out.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: BusinessSectionHeader(business: b),
          ),
        ),
      );
      out.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextButton.icon(
              onPressed: () => _openBusinessDebts(id),
              icon: const Icon(Icons.receipt_long_rounded, size: 18),
              label: Text(
                _sw
                    ? 'Fungua madeni yote (mkono + CRB)'
                    : 'Open all debts (manual + CRB)',
              ),
              style: TextButton.styleFrom(foregroundColor: _kPrimary),
            ),
          ),
        ),
      );

      if (loans.isEmpty) {
        out.add(
          SliverToBoxAdapter(
            child: _emptyHint(
              _sw
                  ? 'Hakuna mikopo ya CRB kwa biashara hii. Sasisha CRB au ongeza madeni kwa mkono.'
                  : 'No bureau loans for this business yet. Refresh CRB or add manual debts.',
            ),
          ),
        );
      } else {
        out.add(
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _loanCard(loans[i]),
              childCount: loans.length,
            ),
          ),
        );
      }
    }

    return out;
  }

  Widget _sectionTitle(String t) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Text(
          t,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _kPrimary,
          ),
        ),
      ),
    );
  }

  Widget _emptyHint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
        ),
      ),
    );
  }

  Widget _loanCard(CrbActiveLoan loan) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    loan.lenderLabel,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'CRB',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary,
                    ),
                  ),
                ),
              ],
            ),
            if (loan.sector != null && loan.sector!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                loan.sector!,
                style: const TextStyle(fontSize: 12, color: _kSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (loan.description != null && loan.description!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                loan.description!,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _miniMetric(
                    _sw ? 'Jumla' : 'Total',
                    _money(loan.totalAmount),
                  ),
                ),
                Expanded(
                  child: _miniMetric(
                    _sw ? 'Kuchelewa' : 'Past due',
                    _money(loan.pastDueAmount),
                  ),
                ),
                if (loan.pastDueDays > 0)
                  Expanded(
                    child: _miniMetric(
                      _sw ? 'Siku' : 'Days late',
                      '${loan.pastDueDays}',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniMetric(String k, String v) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          k,
          style: const TextStyle(fontSize: 11, color: _kSecondary),
        ),
        Text(
          v,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _kPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _pill({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
    bool filled = true,
  }) {
    final fg = filled ? Colors.white : _kPrimary;
    final bg = filled ? _kPrimary : _kCardBg;
    return SizedBox(
      height: 34,
      child: Material(
        color: filled ? bg : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: filled ? null : bg,
              borderRadius: BorderRadius.circular(999),
              border: filled ? null : Border.all(color: Colors.grey.shade300),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 14, color: fg),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: fg,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
