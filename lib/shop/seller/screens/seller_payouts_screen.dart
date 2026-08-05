import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';

// DESIGN.md tokens
const Color _kBg = Color(0xFFFAFAFA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kText = Color(0xFF1A1A1A);
const Color _kMuted = Color(0xFF666666);
const Color _kFaint = Color(0xFF999999);
const Color _kDivider = Color(0xFFE0E0E0);

const BoxShadow _kCardShadow = BoxShadow(
  color: Color(0x1A000000),
  blurRadius: 4,
  offset: Offset(0, 2),
);

class _PayoutRow {
  final String id;
  final String date;
  final double amount;
  final String method;
  final String status;

  const _PayoutRow({
    required this.id,
    required this.date,
    required this.amount,
    required this.method,
    required this.status,
  });
}

/// Seller payouts history and balance overview.
class SellerPayoutsScreen extends StatefulWidget {
  const SellerPayoutsScreen({super.key});

  @override
  State<SellerPayoutsScreen> createState() => _SellerPayoutsScreenState();
}

class _SellerPayoutsScreenState extends State<SellerPayoutsScreen> {
  bool _loading = true;
  double _available = 0;
  double _pending = 0;
  String _nextPayoutDate = '';
  final List<_PayoutRow> _rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _loading = false;
      _available = 24500;
      _pending = 8200;
      _nextPayoutDate = 'May 10, 2026';
      _rows.addAll([
        const _PayoutRow(
          id: 'PO-0041',
          date: 'May 1, 2026',
          amount: 18300,
          method: 'Tajiri Pay',
          status: 'completed',
        ),
        const _PayoutRow(
          id: 'PO-0040',
          date: 'Apr 24, 2026',
          amount: 9750,
          method: 'Tajiri Pay',
          status: 'completed',
        ),
        const _PayoutRow(
          id: 'PO-0039',
          date: 'Apr 17, 2026',
          amount: 5400,
          method: 'Bank Transfer',
          status: 'completed',
        ),
        const _PayoutRow(
          id: 'PO-0038',
          date: 'Apr 10, 2026',
          amount: 12100,
          method: 'Tajiri Pay',
          status: 'completed',
        ),
      ]);
    });
  }

  void _showWithdrawSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _WithdrawSheet(available: _available),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: _kSurface,
            elevation: 0,
            pinned: true,
            centerTitle: false,
            title: const Text(
              'Payouts',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _kText),
            ),
            iconTheme: const IconThemeData(color: _kText),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: TextButton(
                  onPressed: _showWithdrawSheet,
                  style: TextButton.styleFrom(
                    backgroundColor: _kText,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    minimumSize: const Size(0, 36),
                  ),
                  child: const Text('Withdraw',
                      style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
          if (_loading)
            const SliverFillRemaining(
              child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            SliverList(
              delegate: SliverChildListDelegate([
                // Balance cards
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Expanded(
                      child: _BalanceCard(
                        label: 'Available',
                        amount: _available,
                        subtitle: 'Ready to withdraw',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _BalanceCard(
                        label: 'Pending',
                        amount: _pending,
                        subtitle: 'Next: $_nextPayoutDate',
                      ),
                    ),
                  ]),
                ),

                // History header
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Text(
                    'Payout History',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _kText),
                  ),
                ),

                if (_rows.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text('No payouts yet',
                          style: TextStyle(color: _kMuted)),
                    ),
                  )
                else
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: _kSurface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [_kCardShadow],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _rows.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1, color: _kDivider),
                      itemBuilder: (context, i) =>
                          _PayoutTile(row: _rows[i]),
                    ),
                  ),
                const SizedBox(height: 24),
              ]),
            ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.label,
    required this.amount,
    required this.subtitle,
  });
  final String label;
  final double amount;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [_kCardShadow],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: _kMuted)),
        const SizedBox(height: 4),
        Text(
          'TZS ${amount.toStringAsFixed(0)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: _kText),
        ),
        const SizedBox(height: 4),
        Text(subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: _kFaint)),
      ]),
    );
  }
}

class _PayoutTile extends StatelessWidget {
  const _PayoutTile({required this.row});
  final _PayoutRow row;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Color(0xFFF0F0F0),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: HeroIcon(HeroIcons.banknotes,
              style: HeroIconStyle.outline, color: _kText, size: 20),
        ),
      ),
      title: Text(
        row.id,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w500, color: _kText),
      ),
      subtitle: Text(
        '${row.date} · ${row.method}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12, color: _kMuted),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'TZS ${row.amount.toStringAsFixed(0)}',
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _kText),
          ),
          const SizedBox(height: 2),
          Text(
            row.status,
            style: const TextStyle(fontSize: 11, color: _kFaint),
          ),
        ],
      ),
    );
  }
}

class _WithdrawSheet extends StatefulWidget {
  const _WithdrawSheet({required this.available});
  final double available;

  @override
  State<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<_WithdrawSheet> {
  final _ctrl = TextEditingController();
  String _method = 'Tajiri Pay';
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDDDDD),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Withdraw Funds',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _kText)),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Available: TZS ${widget.available.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 13, color: _kMuted),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Amount (TZS)',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _method,
            decoration: InputDecoration(
              labelText: 'Method',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 14),
            ),
            items: ['Tajiri Pay', 'Bank Transfer']
                .map((m) =>
                    DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: (v) => setState(() => _method = v ?? _method),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _loading
                  ? null
                  : () async {
                      setState(() => _loading = true);
                      final nav = Navigator.of(context);
                      final sm = ScaffoldMessenger.of(context);
                      await Future.delayed(
                          const Duration(milliseconds: 800));
                      if (!mounted) return;
                      nav.pop();
                      sm.showSnackBar(
                        const SnackBar(
                            content:
                                Text('Withdrawal request submitted')),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kText,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Request Withdrawal',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }
}
