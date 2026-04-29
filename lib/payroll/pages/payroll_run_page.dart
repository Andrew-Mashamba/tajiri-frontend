// lib/payroll/pages/payroll_run_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/payroll_models.dart';
import '../services/payroll_service.dart';
import '../widgets/payslip_card.dart';
import '../widgets/tax_summary_widget.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);
const Color _kCard = Color(0xFFFFFFFF);

class PayrollRunPage extends StatefulWidget {
  final PayrollRun run;
  final String token;
  final String businessName;

  const PayrollRunPage({
    super.key,
    required this.run,
    required this.token,
    this.businessName = '',
  });

  @override
  State<PayrollRunPage> createState() => _PayrollRunPageState();
}

class _PayrollRunPageState extends State<PayrollRunPage> {
  bool _approving = false;

  static const _monthsEn = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const _monthsSw = [
    'Januari', 'Februari', 'Machi', 'Aprili', 'Mei', 'Juni',
    'Julai', 'Agosti', 'Septemba', 'Oktoba', 'Novemba', 'Desemba',
  ];

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  Future<void> _approve() async {
    if (widget.run.id == null) {
      final sw = _sw;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(sw
              ? 'Mishahara imehesabiwa lakini haijahifadhiwa kwenye seva'
              : 'Payroll calculated locally — not saved to server yet')));
      return;
    }

    final sw = _sw;
    final months = sw ? _monthsSw : _monthsEn;
    final monthName = months[widget.run.month - 1];
    final nf = NumberFormat('#,###', 'en');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(sw ? 'Idhinisha Mishahara?' : 'Approve Payroll?'),
        content: Text(sw
            ? 'Hii itaidhinisha mishahara ya $monthName ${widget.run.year} ya TZS ${nf.format(widget.run.totalNet)} kwa wafanyakazi ${widget.run.employees.length}. Haiwezi kubatilishwa.'
            : 'This will approve the $monthName ${widget.run.year} payroll of TZS ${nf.format(widget.run.totalNet)} for ${widget.run.employees.length} employees. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(sw ? 'Ghairi' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: _kPrimary),
            child: Text(sw ? 'Idhinisha' : 'Approve',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _approving = true);
    final res = await PayrollService.approve(widget.token, widget.run.id!);
    if (!mounted) return;
    setState(() => _approving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.success
            ? (sw ? 'Mishahara imeidhinishwa!' : 'Payroll approved!')
            : (res.message ?? (sw ? 'Imeshindikana' : 'Approval failed')))));
    if (res.success) Navigator.pop(context, true);
  }

  void _showDisburseSalaries() {
    final sw = _sw;
    final nf = NumberFormat('#,###', 'en');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(sw ? 'Lipa Mishahara' : 'Disburse Salaries',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _kPrimary)),
            Text(
                sw
                    ? 'M-Pesa disbursement inakuja hivi karibuni'
                    : 'M-Pesa disbursement coming soon',
                style: const TextStyle(fontSize: 12, color: _kSecondary)),
            const SizedBox(height: 16),
            ...widget.run.employees.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text(e.employeeName,
                              style: const TextStyle(
                                  fontSize: 13, color: _kPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis)),
                      Text('TZS ${nf.format(e.netSalary)}',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _kPrimary)),
                    ],
                  ),
                )),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(sw ? 'Jumla' : 'Total',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _kPrimary)),
                Text('TZS ${nf.format(widget.run.totalNet)}',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _kPrimary)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(sw
                        ? 'M-Pesa inakuja hivi karibuni'
                        : 'M-Pesa disbursement coming soon'),
                  ));
                },
                icon: const Icon(Icons.payments_rounded, size: 20),
                label: Text(sw ? 'Idhinisha Malipo' : 'Approve Payments',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareSummary() {
    final sw = _sw;
    final nf = NumberFormat('#,###', 'en');
    final months = sw ? _monthsSw : _monthsEn;
    final monthName = months[widget.run.month - 1];
    const sep = '─────────────────────';
    final statusLabel = payrollStatusLabel(widget.run.status, swahili: sw);
    final buf = StringBuffer();
    buf.writeln('${sw ? "MUHTASARI WA MISHAHARA" : "PAYROLL SUMMARY"} — $monthName ${widget.run.year}');
    if (widget.businessName.isNotEmpty) buf.writeln(widget.businessName);
    buf.writeln(sep);
    buf.writeln('${sw ? "Jumla Ghafi  " : "Total Gross  "}:   TZS ${nf.format(widget.run.totalGross)}');
    buf.writeln('${sw ? "Jumla Halisi " : "Total Net    "}:   TZS ${nf.format(widget.run.totalNet)}');
    buf.writeln('PAYE         :   TZS ${nf.format(widget.run.totalPaye)}');
    buf.writeln('NSSF         :   TZS ${nf.format(widget.run.totalNssf)}');
    buf.writeln('SDL          :   TZS ${nf.format(widget.run.totalSdl)}');
    buf.writeln('WCF          :   TZS ${nf.format(widget.run.totalWcf)}');
    buf.writeln('${sw ? "Wafanyakazi" : "Employees"}: ${widget.run.employees.length}');
    buf.writeln('${sw ? "Hali" : "Status"}: $statusLabel');
    buf.writeln(sep);
    buf.write(sw ? 'Imetolewa na TAJIRI' : 'Generated by TAJIRI');
    Share.share(buf.toString());
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;
    final nf = NumberFormat('#,###', 'en');
    final months = sw ? _monthsSw : _monthsEn;
    final monthName = months[widget.run.month - 1];
    final run = widget.run;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: const BackButton(color: _kPrimary),
        title: Text(
          '$monthName ${run.year}',
          style: const TextStyle(
              color: _kPrimary, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: _shareSummary,
            icon: const Icon(Icons.share_rounded, color: _kPrimary),
            tooltip: sw ? 'Shiriki' : 'Share',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Summary card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kPrimary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$monthName ${run.year}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                      _statusBadge(run.status, sw),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                          child: _summaryCol(
                              sw ? 'Jumla Ghafi' : 'Total Gross',
                              nf.format(run.totalGross),
                              Colors.white)),
                      Expanded(
                          child: _summaryCol(
                              sw ? 'Jumla Halisi' : 'Total Net',
                              nf.format(run.totalNet),
                              Colors.white)),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 18),
                  Row(
                    children: [
                      Expanded(
                          child: _summaryCol(
                              'PAYE', nf.format(run.totalPaye), Colors.white70)),
                      Expanded(
                          child: _summaryCol(
                              'NSSF', nf.format(run.totalNssf), Colors.white70)),
                      Expanded(
                          child: _summaryCol(
                              'SDL', nf.format(run.totalSdl), Colors.white70)),
                      Expanded(
                          child: _summaryCol(
                              'WCF', nf.format(run.totalWcf), Colors.white70)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    sw
                        ? '${run.employees.length} wafanyakazi'
                        : '${run.employees.length} employees',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Text(
              sw ? 'Maelezo kwa Mfanyakazi' : 'Per-Employee Breakdown',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary),
            ),
            const SizedBox(height: 10),
            ...run.employees.map((e) => PayslipCard(
                  entry: e,
                  month: run.month,
                  year: run.year,
                  token: widget.token,
                  businessName: widget.businessName,
                )),

            const SizedBox(height: 16),

            const TaxSummaryWidget(),

            if (run.status == PayrollStatus.draft) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _approving ? null : _approve,
                  icon: _approving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.check_circle_rounded, size: 20),
                  label: Text(
                    _approving
                        ? (sw ? 'Inaidhinisha...' : 'Approving...')
                        : (sw
                            ? 'Idhinisha na Lipa Mishahara'
                            : 'Approve & Disburse Payroll'),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: _showDisburseSalaries,
                  icon: const Icon(Icons.payments_rounded, size: 20),
                  label: Text(
                    sw ? 'Tazama Maelezo ya Malipo' : 'View Payment Details',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kPrimary,
                    side: const BorderSide(color: _kPrimary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _summaryCol(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11, color: color.withValues(alpha: 0.7))),
        Text('TZS $value',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _statusBadge(PayrollStatus s, bool sw) {
    Color bg;
    Color fg;
    switch (s) {
      case PayrollStatus.draft:
        bg = Colors.orange.shade800;
        fg = Colors.white;
        break;
      case PayrollStatus.approved:
        bg = Colors.blue.shade800;
        fg = Colors.white;
        break;
      case PayrollStatus.paid:
        bg = Colors.green.shade800;
        fg = Colors.white;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        payrollStatusLabel(s, swahili: sw),
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}
