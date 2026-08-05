import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// DESIGN.md tokens
const Color _kBg = Color(0xFFFAFAFA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kText = Color(0xFF1A1A1A);
const Color _kMuted = Color(0xFF666666);
const Color _kFaint = Color(0xFF999999);
const Color _kDivider = Color(0xFFE0E0E0);

const BoxShadow _kCardShadow = BoxShadow(
  color: Color(0x0F000000),
  blurRadius: 8,
  offset: Offset(0, 2),
);

String _fmtTzs(double amount) =>
    'TZS ${NumberFormat('#,##0', 'en_US').format(amount)}';

enum _TxFilter { all, income, payouts, refunds }

enum _TxType { income, payout, refund }

enum _TxStatus { completed, pending, failed }

class _Transaction {
  final String id;
  final String description;
  final double amount;
  final _TxType type;
  final _TxStatus status;
  final String date;
  final String time;

  const _Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.status,
    required this.date,
    required this.time,
  });

  bool get isCredit => type == _TxType.income;
}

/// Full financial transaction history for seller/buyer.
class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  bool _loading = true;
  bool _loadingMore = false;
  _TxFilter _filter = _TxFilter.all;
  final List<_Transaction> _transactions = [];
  int _page = 1;

  static const _mockPage1 = [
    _Transaction(
      id: 'TX-0101',
      description: 'Order #2041 payment received',
      amount: 85000,
      type: _TxType.income,
      status: _TxStatus.completed,
      date: 'May 6, 2026',
      time: '10:45 AM',
    ),
    _Transaction(
      id: 'TX-0100',
      description: 'Payout PO-0041',
      amount: 120000,
      type: _TxType.payout,
      status: _TxStatus.completed,
      date: 'May 5, 2026',
      time: '2:30 PM',
    ),
    _Transaction(
      id: 'TX-0099',
      description: 'Order #2038 payment received',
      amount: 45500,
      type: _TxType.income,
      status: _TxStatus.completed,
      date: 'May 4, 2026',
      time: '9:15 AM',
    ),
    _Transaction(
      id: 'TX-0098',
      description: 'Refund — Order #2035',
      amount: 32000,
      type: _TxType.refund,
      status: _TxStatus.completed,
      date: 'May 3, 2026',
      time: '4:00 PM',
    ),
    _Transaction(
      id: 'TX-0097',
      description: 'Order #2031 payment received',
      amount: 18750,
      type: _TxType.income,
      status: _TxStatus.completed,
      date: 'May 2, 2026',
      time: '11:55 AM',
    ),
    _Transaction(
      id: 'TX-0096',
      description: 'Payout PO-0040',
      amount: 97800,
      type: _TxType.payout,
      status: _TxStatus.pending,
      date: 'May 1, 2026',
      time: '8:00 AM',
    ),
  ];

  static const _mockPage2 = [
    _Transaction(
      id: 'TX-0095',
      description: 'Order #2028 payment received',
      amount: 63000,
      type: _TxType.income,
      status: _TxStatus.completed,
      date: 'Apr 30, 2026',
      time: '3:22 PM',
    ),
    _Transaction(
      id: 'TX-0094',
      description: 'Refund — Order #2024',
      amount: 15000,
      type: _TxType.refund,
      status: _TxStatus.completed,
      date: 'Apr 28, 2026',
      time: '1:10 PM',
    ),
    _Transaction(
      id: 'TX-0093',
      description: 'Order #2020 payment received',
      amount: 102500,
      type: _TxType.income,
      status: _TxStatus.completed,
      date: 'Apr 27, 2026',
      time: '10:00 AM',
    ),
    _Transaction(
      id: 'TX-0092',
      description: 'Payout PO-0039',
      amount: 88000,
      type: _TxType.payout,
      status: _TxStatus.failed,
      date: 'Apr 25, 2026',
      time: '6:45 PM',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() {
      _loading = false;
      _page = 1;
      _transactions
        ..clear()
        ..addAll(_mockPage1);
    });
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    await _load();
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _page >= 2) return;
    setState(() => _loadingMore = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _loadingMore = false;
      _page = 2;
      _transactions.addAll(_mockPage2);
    });
  }

  List<_Transaction> get _filtered {
    switch (_filter) {
      case _TxFilter.income:
        return _transactions.where((t) => t.type == _TxType.income).toList();
      case _TxFilter.payouts:
        return _transactions.where((t) => t.type == _TxType.payout).toList();
      case _TxFilter.refunds:
        return _transactions.where((t) => t.type == _TxType.refund).toList();
      case _TxFilter.all:
        return _transactions;
    }
  }

  double get _totalIn => _transactions
      .where((t) => t.type == _TxType.income)
      .fold(0, (s, t) => s + t.amount);

  double get _totalOut => _transactions
      .where((t) => t.type != _TxType.income)
      .fold(0, (s, t) => s + t.amount);

  double get _net => _totalIn - _totalOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        foregroundColor: _kText,
        title: const Text(
          'Transaction History',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: _kText),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range_rounded, size: 22, color: _kText),
            tooltip: 'Filter by date',
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final now = DateTime.now();
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(now.year - 2),
                lastDate: now,
                initialDateRange: DateTimeRange(
                  start: now.subtract(const Duration(days: 30)),
                  end: now,
                ),
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Color(0xFF1A1A1A),
                      onPrimary: Colors.white,
                    ),
                  ),
                  child: child!,
                ),
              );
              if (range != null) {
                final msg = 'Filtered: ${range.start.day}/${range.start.month}/${range.start.year} – ${range.end.day}/${range.end.month}/${range.end.year}';
                messenger.showSnackBar(SnackBar(content: Text(msg)));
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child:
                    CircularProgressIndicator(strokeWidth: 2, color: _kText))
            : RefreshIndicator(
                color: _kText,
                onRefresh: _refresh,
                child: NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n is ScrollEndNotification &&
                        n.metrics.extentAfter < 80) {
                      _loadMore();
                    }
                    return false;
                  },
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(child: _buildSummaryCards()),
                      SliverToBoxAdapter(child: _buildFilterChips()),
                      if (_filtered.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildEmptyState(),
                        )
                      else ...[
                        SliverPadding(
                          padding:
                              const EdgeInsets.fromLTRB(16, 0, 16, 0),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, i) => _TxTile(tx: _filtered[i]),
                              childCount: _filtered.length,
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: _page < 2
                              ? Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: OutlinedButton(
                                    onPressed: _loadMore,
                                    style: OutlinedButton.styleFrom(
                                      minimumSize:
                                          const Size(double.infinity, 48),
                                      foregroundColor: _kText,
                                      side: const BorderSide(
                                          color: _kDivider),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                    child: _loadingMore
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child:
                                                CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: _kText),
                                          )
                                        : const Text('Load More'),
                                  ),
                                )
                              : const SizedBox(height: 24),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Expanded(
          child: _SummaryCard(
            label: 'Total In',
            value: _fmtTzs(_totalIn),
            isPositive: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            label: 'Total Out',
            value: _fmtTzs(_totalOut),
            isPositive: false,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            label: 'Net',
            value: _fmtTzs(_net.abs()),
            isNet: true,
            netPositive: _net >= 0,
          ),
        ),
      ]),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          _Chip(
            label: 'All',
            selected: _filter == _TxFilter.all,
            onTap: () => setState(() => _filter = _TxFilter.all),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Income',
            selected: _filter == _TxFilter.income,
            onTap: () => setState(() => _filter = _TxFilter.income),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Payouts',
            selected: _filter == _TxFilter.payouts,
            onTap: () => setState(() => _filter = _TxFilter.payouts),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Refunds',
            selected: _filter == _TxFilter.refunds,
            onTap: () => setState(() => _filter = _TxFilter.refunds),
          ),
        ]),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.receipt_long_rounded,
            size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(
          'No transactions',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500),
        ),
        const SizedBox(height: 8),
        Text(
          'No transactions match the selected filter.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
        ),
      ]),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    this.isPositive = false,
    this.isNet = false,
    this.netPositive = true,
  });
  final String label;
  final String value;
  final bool isPositive;
  final bool isNet;
  final bool netPositive;

  Color get _valueColor {
    if (isNet) return netPositive ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F);
    if (isPositive) return const Color(0xFF2E7D32);
    return const Color(0xFFD32F2F);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [_kCardShadow],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: _kMuted)),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: _valueColor),
        ),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _kText : _kSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? _kText : _kDivider),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : _kMuted,
          ),
        ),
      ),
    );
  }
}

class _TxTile extends StatelessWidget {
  const _TxTile({required this.tx});
  final _Transaction tx;

  IconData get _typeIcon {
    switch (tx.type) {
      case _TxType.income:
        return Icons.arrow_downward_rounded;
      case _TxType.payout:
        return Icons.arrow_upward_rounded;
      case _TxType.refund:
        return Icons.replay_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final amountColor = tx.isCredit
        ? const Color(0xFF2E7D32)
        : const Color(0xFFD32F2F);
    final amountPrefix = tx.isCredit ? '+' : '−';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [_kCardShadow],
      ),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_typeIcon, size: 20, color: _kText),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              tx.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500, color: _kText),
            ),
            const SizedBox(height: 3),
            Text(
              '${tx.date} · ${tx.time}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: _kFaint),
            ),
          ]),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(
            '$amountPrefix ${_fmtTzs(tx.amount)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: amountColor),
          ),
          const SizedBox(height: 3),
          _StatusBadge(status: tx.status),
        ]),
      ]),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final _TxStatus status;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case _TxStatus.completed:
        color = const Color(0xFF2E7D32);
        label = 'Completed';
        break;
      case _TxStatus.pending:
        color = const Color(0xFFF57C00);
        label = 'Pending';
        break;
      case _TxStatus.failed:
        color = const Color(0xFFD32F2F);
        label = 'Failed';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
