// lib/fee_status/pages/fee_status_home_page.dart
import 'package:flutter/material.dart';
import '../models/fee_status_models.dart';
import '../services/fee_status_service.dart';
import 'payment_page.dart';
import 'payment_history_page.dart';
import '../widgets/balance_card.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class FeeStatusHomePage extends StatefulWidget {
  final int userId;
  const FeeStatusHomePage({super.key, required this.userId});
  @override
  State<FeeStatusHomePage> createState() => _FeeStatusHomePageState();
}

class _FeeStatusHomePageState extends State<FeeStatusHomePage> {
  final FeeStatusService _service = FeeStatusService();
  FeeBalance? _balance;
  HeslbStatus? _heslb;
  List<ClearanceItem> _clearance = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([_service.getBalance(), _service.getHeslbStatus(), _service.getClearanceStatus()]);
    if (mounted) {
      setState(() {
        _isLoading = false;
        final bRes = results[0] as FeeResult<FeeBalance>;
        final hRes = results[1] as FeeResult<HeslbStatus>;
        final cRes = results[2] as FeeListResult<ClearanceItem>;
        if (bRes.success) _balance = bRes.data;
        if (hRes.success) _heslb = hRes.data;
        if (cRes.success) _clearance = cRes.items;
      });
    }
  }

  String _fmtAmount(double v) => 'TZS ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
            : RefreshIndicator(
                onRefresh: _loadData,
                color: _kPrimary,
                child: ListView(padding: const EdgeInsets.all(16), children: [
                  // Balance header
                  if (_balance != null) BalanceCard(balance: _balance!),
                  const SizedBox(height: 16),
                  // Actions
                  Row(children: [
                    _action(Icons.payment_rounded, 'Lipa', 'Pay Now', () => Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentPage(userId: widget.userId)))),
                    const SizedBox(width: 12),
                    _action(Icons.receipt_long_rounded, 'Historia', 'History', () => Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentHistoryPage(userId: widget.userId)))),
                  ]),
                  const SizedBox(height: 20),
                  // HESLB
                  if (_heslb != null) ...[
                    const Text('HESLB', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                      child: Column(children: [
                        _heslbRow('Iliyotengwa / Allocated', _fmtAmount(_heslb!.allocated)),
                        _heslbRow('Iliyotolewa / Disbursed', _fmtAmount(_heslb!.disbursed)),
                        _heslbRow('Iliyobaki / Remaining', _fmtAmount(_heslb!.remaining)),
                        const Divider(height: 16),
                        Row(children: [
                          Icon(_heslb!.status == 'active' ? Icons.check_circle_rounded : Icons.warning_rounded, size: 16, color: _heslb!.status == 'active' ? Colors.green : Colors.orange),
                          const SizedBox(width: 6),
                          Text(_heslb!.status == 'active' ? 'Inatumika' : 'Inasubiri', style: const TextStyle(fontSize: 13, color: _kPrimary)),
                        ]),
                      ]),
                    ),
                    const SizedBox(height: 20),
                  ],
                  // Clearance
                  if (_clearance.isNotEmpty) ...[
                    const Text('Clearance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
                    const SizedBox(height: 10),
                    ..._clearance.map((c) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        tileColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        leading: Icon(c.isCleared ? Icons.check_circle_rounded : Icons.cancel_rounded, color: c.isCleared ? Colors.green : Colors.red, size: 20),
                        title: Text(c.department, style: const TextStyle(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                        dense: true,
                      ),
                    )),
                  ],
                ]),
              ),
      ),
    );
  }

  Widget _action(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Expanded(child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 24, color: _kPrimary),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: _kSecondary)),
        ]),
      ),
    ));
  }

  Widget _heslbRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 13, color: _kSecondary)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
      ]),
    );
  }
}
