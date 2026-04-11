// lib/dawasco/pages/dawasco_home_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/dawasco_models.dart';
import '../services/dawasco_service.dart';
import '../widgets/account_card.dart';
import 'account_management_page.dart';
import 'pay_bill_page.dart';
import 'bill_history_page.dart';
import 'report_issue_page.dart';
import 'consumption_dashboard_page.dart';
import 'supply_schedule_page.dart';
import 'my_reports_page.dart';
import 'new_connection_page.dart';
import 'tariff_info_page.dart';
import 'water_tips_page.dart';
import 'water_quality_page.dart';
import 'help_page.dart';
import 'meter_reading_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class DawascoHomePage extends StatefulWidget {
  final int userId;
  const DawascoHomePage({super.key, required this.userId});
  @override
  State<DawascoHomePage> createState() => _DawascoHomePageState();
}

class _DawascoHomePageState extends State<DawascoHomePage> {
  WaterAccount? _account;
  List<WaterBill> _bills = [];
  SupplyStatus? _supplyStatus;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        DawascoService.getAccount(),
        DawascoService.getBills(),
      ]);
      if (!mounted) return;

      final accR = results[0] as SingleResult<WaterAccount>;
      if (accR.success) _account = accR.data;

      final billR = results[1] as PaginatedResult<WaterBill>;
      if (billR.success) _bills = billR.items;

      // Fetch supply status if we have ward info
      if (_account?.wardId != null) {
        final statusR = await DawascoService.getSupplyStatus(wardId: _account!.wardId);
        if (!mounted) return;
        if (statusR.success) _supplyStatus = statusR.data;
      }
    } catch (e) {
      if (!mounted) return;
      final sw = _sw;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(sw ? 'Imeshindwa kupakia data: $e' : 'Failed to load data: $e'),
      ));
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  Future<void> _checkBalance() async {
    if (_account == null) return;
    final sw = _sw;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await DawascoService.getBalance(_account!.accountNumber);
      if (!mounted) return;
      if (result.success) {
        final balance = result.data?['balance'] ?? result.data?['amount'] ?? 0;
        messenger.showSnackBar(SnackBar(
          content: Text(sw ? 'Salio: TZS $balance' : 'Balance: TZS $balance'),
        ));
      } else {
        messenger.showSnackBar(SnackBar(
          content: Text(result.message ?? (sw ? 'Imeshindwa kupata salio' : 'Failed to get balance')),
        ));
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text(sw ? 'Hitilafu: $e' : 'Error: $e'),
      ));
    }
  }

  void _showReconnectionDialog() {
    final sw = _sw;
    final accountCtrl = TextEditingController(text: _account?.accountNumber ?? '');
    final phoneCtrl = TextEditingController();
    String paymentMethod = 'M-Pesa';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(sw ? 'Kuunganisha Tena' : 'Reconnection',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: accountCtrl,
                decoration: InputDecoration(
                  labelText: sw ? 'Namba ya Akaunti' : 'Account Number',
                  labelStyle: const TextStyle(fontSize: 13, color: _kSecondary),
                  filled: true, fillColor: const Color(0xFFFAFAFA),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                ),
                style: const TextStyle(fontSize: 14, color: _kPrimary),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: paymentMethod,
                decoration: InputDecoration(
                  labelText: sw ? 'Njia ya Malipo' : 'Payment Method',
                  labelStyle: const TextStyle(fontSize: 13, color: _kSecondary),
                  filled: true, fillColor: const Color(0xFFFAFAFA),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                ),
                items: const [
                  DropdownMenuItem(value: 'M-Pesa', child: Text('M-Pesa')),
                  DropdownMenuItem(value: 'Tigo', child: Text('Tigo Pesa')),
                  DropdownMenuItem(value: 'Airtel', child: Text('Airtel Money')),
                ],
                onChanged: (v) { if (v != null) setDialogState(() => paymentMethod = v); },
                style: const TextStyle(fontSize: 14, color: _kPrimary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: sw ? 'Namba ya Simu' : 'Phone Number',
                  labelStyle: const TextStyle(fontSize: 13, color: _kSecondary),
                  filled: true, fillColor: const Color(0xFFFAFAFA),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                ),
                style: const TextStyle(fontSize: 14, color: _kPrimary),
              ),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(sw ? 'Ghairi' : 'Cancel', style: const TextStyle(color: _kSecondary)),
            ),
            FilledButton(
              onPressed: () async {
                final acct = accountCtrl.text.trim();
                if (acct.isEmpty || phoneCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                final messenger = ScaffoldMessenger.of(context);
                try {
                  final result = await DawascoService.requestReconnection(acct, paymentMethod);
                  if (!mounted) return;
                  messenger.showSnackBar(SnackBar(content: Text(
                    result.success
                        ? (sw ? 'Ombi la kuunganishwa tena limetumwa' : 'Reconnection request submitted')
                        : (result.message ?? (sw ? 'Imeshindwa' : 'Failed')),
                  )));
                } catch (e) {
                  if (!mounted) return;
                  messenger.showSnackBar(SnackBar(
                    content: Text(sw ? 'Hitilafu: $e' : 'Error: $e'),
                  ));
                }
              },
              style: FilledButton.styleFrom(backgroundColor: _kPrimary),
              child: Text(sw ? 'Wasilisha' : 'Submit'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;
    final unpaid = _bills.where((b) => !b.isPaid).toList();

    // NO AppBar — rendered inside profile tab
    return RefreshIndicator(
      onRefresh: _load,
      color: _kPrimary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── Account card (reusable widget) ──────────────────────
          if (_account != null)
            DawascoAccountCard(
              account: _account!,
              supplyStatus: _supplyStatus,
              isSwahili: sw,
              onPay: unpaid.isNotEmpty
                  ? () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => PayBillPage(bill: unpaid.first)))
                  : null,
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.water_drop_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Text(sw ? 'Hakuna akaunti' : 'No account linked',
                    style: const TextStyle(color: Colors.white54, fontSize: 14)),
              ]),
            ),

          // ─── Check Balance button ────────────────────────────────
          if (_account != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: _checkBalance,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.refresh_rounded, size: 16, color: _kPrimary),
                    const SizedBox(width: 4),
                    Text(sw ? 'Angalia Salio' : 'Check Balance',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kPrimary)),
                  ]),
                ),
              ),
            ),
          ],

          // ─── Supply status banner ─────────────────────────────
          if (_supplyStatus != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _supplyStatus!.isAvailable
                    ? const Color(0xFF4CAF50).withValues(alpha: 0.08)
                    : Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                Icon(
                  _supplyStatus!.isAvailable ? Icons.check_circle_rounded : Icons.warning_rounded,
                  size: 18,
                  color: _supplyStatus!.isAvailable ? const Color(0xFF4CAF50) : Colors.red,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _supplyStatus!.isAvailable
                        ? (sw ? 'Maji yanapatikana eneo lako' : 'Water available in your area')
                        : (sw ? 'Maji hayapatikani eneo lako' : 'Water unavailable in your area'),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                        color: _supplyStatus!.isAvailable ? const Color(0xFF4CAF50) : Colors.red),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text('${_supplyStatus!.reportsCount} ${sw ? 'ripoti' : 'reports'}',
                    style: const TextStyle(fontSize: 10, color: _kSecondary)),
              ]),
            ),
          ],

          // ─── Quick actions grid ───────────────────────────────
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.75,
            crossAxisSpacing: 6,
            mainAxisSpacing: 10,
            children: [
              _QA(icon: Icons.payment_rounded, label: sw ? 'Lipa Bili' : 'Pay Bill', onTap: () {
                if (unpaid.isNotEmpty) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => PayBillPage(bill: unpaid.first)));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(sw ? 'Hakuna bili ya kulipa' : 'No bills to pay')));
                }
              }),
              _QA(icon: Icons.history_rounded, label: sw ? 'Historia' : 'History', onTap: () =>
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const BillHistoryPage()))),
              _QA(icon: Icons.speed_rounded, label: sw ? 'Soma Mita' : 'Reading', onTap: () =>
                  Navigator.push(context, MaterialPageRoute(builder: (_) => MeterReadingPage(account: _account)))),
              _QA(icon: Icons.bar_chart_rounded, label: sw ? 'Matumizi' : 'Usage', onTap: () =>
                  Navigator.push(context, MaterialPageRoute(builder: (_) =>
                      ConsumptionDashboardPage(accountNumber: _account?.accountNumber)))),
              _QA(icon: Icons.schedule_rounded, label: sw ? 'Ratiba' : 'Schedule', onTap: () =>
                  Navigator.push(context, MaterialPageRoute(builder: (_) =>
                      SupplySchedulePage(wardId: _account?.wardId)))),
              _QA(icon: Icons.report_problem_rounded, label: sw ? 'Ripoti' : 'Report', onTap: () =>
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportIssuePage()))),
              _QA(icon: Icons.add_circle_outline_rounded, label: sw ? 'Unganisha' : 'Connect', onTap: () =>
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const NewConnectionPage()))),
              _QA(icon: Icons.power_rounded, label: sw ? 'Unganisha\nTena' : 'Reconnect', onTap: _showReconnectionDialog),
              _QA(icon: Icons.manage_accounts_rounded, label: sw ? 'Akaunti' : 'Account', onTap: () =>
                  Navigator.push(context, MaterialPageRoute(builder: (_) =>
                      AccountManagementPage(account: _account)))),
              _QA(icon: Icons.science_rounded, label: sw ? 'Ubora' : 'Quality', onTap: () =>
                  Navigator.push(context, MaterialPageRoute(builder: (_) =>
                      WaterQualityPage(wardId: _account?.wardId)))),
              _QA(icon: Icons.tips_and_updates_rounded, label: sw ? 'Vidokezo' : 'Tips', onTap: () =>
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const WaterTipsPage()))),
              _QA(icon: Icons.table_chart_rounded, label: sw ? 'Bei' : 'Tariffs', onTap: () =>
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TariffInfoPage()))),
              _QA(icon: Icons.help_outline_rounded, label: sw ? 'Msaada' : 'Help', onTap: () =>
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpPage()))),
            ],
          ),

          // ─── Recent unpaid bills ──────────────────────────────
          const SizedBox(height: 20),
          if (unpaid.isNotEmpty) ...[
            Text(sw ? 'Bili Ambazo Hazijalipwa' : 'Unpaid Bills',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary)),
            const SizedBox(height: 10),
            ...unpaid.take(3).map((b) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PayBillPage(bill: b))),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    Container(width: 4, height: 40,
                      decoration: BoxDecoration(
                        color: b.isOverdue ? Colors.red : Colors.orange,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(b.billingPeriod,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('${b.consumption.toStringAsFixed(1)} m\u00B3',
                          style: const TextStyle(fontSize: 11, color: _kSecondary),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('TZS ${b.totalAmount.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('${b.dueDate.day}/${b.dueDate.month}',
                          style: TextStyle(fontSize: 11, color: b.isOverdue ? Colors.red : _kSecondary)),
                    ]),
                  ]),
                ),
              ),
            )),
          ],

          // ─── My Reports shortcut ──────────────────────────────
          const SizedBox(height: 8),
          _InfoTile(
            icon: Icons.assignment_rounded,
            title: sw ? 'Ripoti Zangu' : 'My Reports',
            subtitle: sw ? 'Fuatilia matatizo yaliyoripotiwa' : 'Track reported issues',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyReportsPage())),
          ),

          if (_loading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary)),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _QA extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QA({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: _kPrimary),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: _kPrimary),
              textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _InfoTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 22, color: _kPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: _kSecondary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
            const Icon(Icons.chevron_right_rounded, size: 20, color: _kSecondary),
          ]),
        ),
      ),
    );
  }
}
