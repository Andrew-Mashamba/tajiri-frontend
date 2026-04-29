// lib/payroll/pages/statutory_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/payroll_models.dart';
import '../services/payroll_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);
const Color _kCard = Color(0xFFFFFFFF);

class StatutoryPage extends StatefulWidget {
  final int businessId;
  final String token;

  const StatutoryPage({
    super.key,
    required this.businessId,
    required this.token,
  });

  @override
  State<StatutoryPage> createState() => _StatutoryPageState();
}

class _StatutoryPageState extends State<StatutoryPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  List<StatutoryObligation> _all = [];
  bool _loading = true;
  bool _backendAvailable = true;

  static const _types = ['PAYE', 'NSSF', 'SDL', 'WCF'];

  static const _monthsEn = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const _monthsSw = [
    'Januari', 'Februari', 'Machi', 'Aprili', 'Mei', 'Juni',
    'Julai', 'Agosti', 'Septemba', 'Oktoba', 'Novemba', 'Desemba',
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await PayrollService.getStatutory(widget.token, widget.businessId);
      if (mounted) {
        if (res.success) {
          setState(() {
            _loading = false;
            _all = res.data;
            _backendAvailable = true;
          });
        } else {
          setState(() {
            _loading = false;
            _backendAvailable = false;
          });
          _deriveFromHistory();
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _backendAvailable = false;
        });
      }
    }
  }

  Future<void> _deriveFromHistory() async {
    final histRes =
        await PayrollService.getHistory(widget.token, widget.businessId);
    if (!mounted) return;
    if (!histRes.success) return;
    final derived = <StatutoryObligation>[];
    for (final run in histRes.data) {
      if (run.status == PayrollStatus.approved ||
          run.status == PayrollStatus.paid) {
        derived.addAll([
          StatutoryObligation(
            type: 'PAYE',
            month: run.month,
            year: run.year,
            amount: run.totalPaye,
            dueDate: DateTime(run.year, run.month + 1, 7),
          ),
          StatutoryObligation(
            type: 'NSSF',
            month: run.month,
            year: run.year,
            amount: run.totalNssf,
            dueDate: DateTime(run.year, run.month + 1, 15),
          ),
          StatutoryObligation(
            type: 'SDL',
            month: run.month,
            year: run.year,
            amount: run.totalSdl,
            dueDate: DateTime(run.year, run.month + 1, 7),
          ),
          StatutoryObligation(
            type: 'WCF',
            month: run.month,
            year: run.year,
            amount: run.totalWcf,
          ),
        ]);
      }
    }
    if (mounted) setState(() => _all = derived);
  }

  Future<void> _markRemitted(StatutoryObligation ob) async {
    if (!_backendAvailable || ob.id == null) return;
    final res =
        await PayrollService.markRemitted(widget.token, ob.id!);
    if (!mounted) return;
    final sw = AppStringsScope.of(context)?.isSwahili ?? false;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.success
            ? (sw ? 'Imethibitishwa kama imelipwa' : 'Marked as remitted')
            : (res.message ??
                (sw ? 'Imeshindikana' : 'Failed')))));
    if (res.success) _load();
  }

  @override
  Widget build(BuildContext context) {
    final sw = AppStringsScope.of(context)?.isSwahili ?? false;
    final nf = NumberFormat('#,###', 'en');
    final months = sw ? _monthsSw : _monthsEn;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: const BackButton(color: _kPrimary),
        title: Text(
          sw ? 'Matoleo ya Kisheria' : 'Statutory Obligations',
          style: const TextStyle(
              color: _kPrimary, fontWeight: FontWeight.w600),
        ),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'PAYE'),
            Tab(text: 'NSSF'),
            Tab(text: 'SDL'),
            Tab(text: 'WCF'),
          ],
          labelColor: _kPrimary,
          unselectedLabelColor: _kSecondary,
          indicatorColor: _kPrimary,
          indicatorSize: TabBarIndicatorSize.label,
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                    color: _kPrimary, strokeWidth: 2))
            : TabBarView(
                controller: _tabs,
                children: _types.map((type) {
                  final items = _all
                      .where((o) => o.type == type)
                      .toList()
                    ..sort((a, b) {
                      final yc = b.year.compareTo(a.year);
                      return yc != 0 ? yc : b.month.compareTo(a.month);
                    });

                  if (items.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.receipt_long_rounded,
                                size: 56, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              sw
                                  ? 'Hakuna majukumu bado. Hesabu na idhinisha mishahara kwanza.'
                                  : 'No obligations yet. Run and approve payroll to track obligations.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      if (i == items.length) {
                        return _infoCard(type, sw);
                      }
                      final ob = items[i];
                      final isOverdue = ob.dueDate != null &&
                          !ob.remitted &&
                          ob.dueDate!.isBefore(DateTime.now());

                      return GestureDetector(
                        onLongPress: () => _confirmRemit(ob, sw),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _kCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isOverdue
                                  ? Colors.red.shade200
                                  : Colors.grey.shade100,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${months[ob.month - 1]} ${ob.year}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: _kPrimary),
                                    ),
                                    if (ob.dueDate != null)
                                      Text(
                                        '${sw ? "Tarehe ya mwisho" : "Due"}: ${ob.dueDate!.day}/${ob.dueDate!.month}/${ob.dueDate!.year}',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: isOverdue
                                                ? Colors.red.shade600
                                                : _kSecondary),
                                      ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'TZS ${nf.format(ob.amount)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _kPrimary),
                                  ),
                                  _obligationBadge(ob, isOverdue, sw),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
      ),
    );
  }

  Future<void> _confirmRemit(StatutoryObligation ob, bool sw) async {
    if (ob.remitted) return;
    if (!_backendAvailable || ob.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(sw
              ? 'Unahitaji sync na seva kwanza'
              : 'Sync required to mark as remitted')));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(sw ? 'Thibitisha Malipo' : 'Confirm Remittance'),
        content: Text(sw
            ? 'Je, umethibitisha kulipa ${ob.type} kwa mwezi huu?'
            : 'Confirm ${ob.type} has been remitted for this month?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(sw ? 'Hapana' : 'No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: _kPrimary),
            child: Text(sw ? 'Ndiyo' : 'Yes',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) _markRemitted(ob);
  }

  Widget _obligationBadge(
      StatutoryObligation ob, bool isOverdue, bool sw) {
    String label;
    Color bg;
    Color fg;
    if (ob.remitted) {
      label = sw ? 'Imelipwa' : 'Remitted';
      bg = Colors.green.shade50;
      fg = Colors.green.shade800;
    } else if (isOverdue) {
      label = sw ? 'Imechelewa' : 'Overdue';
      bg = Colors.red.shade50;
      fg = Colors.red.shade800;
    } else {
      label = sw ? 'Inasubiri' : 'Due';
      bg = Colors.orange.shade50;
      fg = Colors.orange.shade800;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  Widget _infoCard(String type, bool sw) {
    String url;
    String description;
    switch (type) {
      case 'PAYE':
        url = 'https://efiling.tra.go.tz';
        description = sw
            ? 'Lipa PAYE kupitia TRA e-Filing (efiling.tra.go.tz)'
            : 'File PAYE via TRA e-Filing (efiling.tra.go.tz)';
        break;
      case 'NSSF':
        url = 'https://member.nssf.or.tz';
        description = sw
            ? 'Lipa NSSF kupitia Mwanachama wa NSSF (nssf.or.tz)'
            : 'Remit NSSF via NSSF Member Portal (nssf.or.tz)';
        break;
      case 'SDL':
        url = 'https://efiling.tra.go.tz';
        description = sw
            ? 'SDL inalipwa pamoja na PAYE kupitia TRA e-Filing (efiling.tra.go.tz)'
            : 'SDL is filed together with PAYE via TRA e-Filing (efiling.tra.go.tz)';
        break;
      default: // WCF
        url = 'https://www.wcf.go.tz';
        description = sw
            ? 'WCF ni mchango wa kila mwaka unaolipwa kabla ya 31 Machi kupitia WCF (wcf.go.tz)'
            : 'WCF is an annual contribution filed by 31 March via WCF (wcf.go.tz)';
    }

    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded,
                color: _kSecondary, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                description,
                style: const TextStyle(fontSize: 12, color: _kSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.open_in_new_rounded,
                size: 14, color: _kSecondary),
          ],
        ),
      ),
    );
  }
}
