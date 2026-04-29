// lib/myjob/pages/my_payslips_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams;
import '../../l10n/app_strings_scope.dart';
import '../models/myjob_models.dart';
import '../services/my_job_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);
const Color _kCard = Color(0xFFFFFFFF);

class MyPayslipsPage extends StatefulWidget {
  final String token;
  const MyPayslipsPage({super.key, required this.token});

  @override
  State<MyPayslipsPage> createState() => _MyPayslipsPageState();
}

class _MyPayslipsPageState extends State<MyPayslipsPage> {
  List<MyPayslip> _payslips = [];
  bool _loading = true;
  String? _error;

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
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await MyJobService.getMyPayslips(widget.token);
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (res.success) {
          _payslips = res.data
            ..sort((a, b) {
              final yc = b.year.compareTo(a.year);
              return yc != 0 ? yc : b.month.compareTo(a.month);
            });
        } else {
          _error = res.message ?? 'Failed to load payslips';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
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
          sw ? 'Stakabadhi za Mishahara' : 'My Payslips',
          style: const TextStyle(
              color: _kPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                    color: _kPrimary, strokeWidth: 2))
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.error_outline_rounded,
                            size: 56, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _load,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: _kPrimary),
                          child: Text(
                            sw ? 'Jaribu Tena' : 'Retry',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ]),
                    ),
                  )
                : _payslips.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.receipt_long_rounded,
                                    size: 64,
                                    color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  sw
                                      ? 'Hakuna stakabadhi bado.\nMeneja wako hajatoa mishahara bado.'
                                      : "No payslips yet.\nYour employer hasn't run payroll yet.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 14),
                                ),
                              ]),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: _kPrimary,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _payslips.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 8),
                          itemBuilder: (ctx, i) {
                            final p = _payslips[i];
                            return GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      _MyPayslipDetailPage(payslip: p),
                                ),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: _kCard,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.grey.shade100),
                                ),
                                child: Row(children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${months[p.month - 1]} ${p.year}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: _kPrimary),
                                        ),
                                        if (p.businessName.isNotEmpty)
                                          Text(
                                            p.businessName,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: _kSecondary),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'TZS ${nf.format(p.netSalary)}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _kPrimary),
                                      ),
                                      _statusChip(p.status, sw),
                                    ],
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.chevron_right_rounded,
                                      size: 18, color: _kSecondary),
                                ]),
                              ),
                            );
                          },
                        ),
                      ),
      ),
    );
  }

  Widget _statusChip(String status, bool sw) {
    Color bg;
    Color fg;
    String label;
    switch (status) {
      case 'approved':
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade800;
        label = sw ? 'Imeidhinishwa' : 'Approved';
        break;
      case 'paid':
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        label = sw ? 'Imelipwa' : 'Paid';
        break;
      default:
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade800;
        label = sw ? 'Rasimu' : 'Draft';
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
}

class _MyPayslipDetailPage extends StatelessWidget {
  final MyPayslip payslip;
  const _MyPayslipDetailPage({required this.payslip});

  static const _monthsEn = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const _monthsSw = [
    'Januari', 'Februari', 'Machi', 'Aprili', 'Mei', 'Juni',
    'Julai', 'Agosti', 'Septemba', 'Oktoba', 'Novemba', 'Desemba',
  ];

  void _share(bool sw) {
    final nf = NumberFormat('#,###', 'en');
    final monthName =
        sw ? _monthsSw[payslip.month - 1] : _monthsEn[payslip.month - 1];
    final displayBusiness = payslip.businessName.isNotEmpty
        ? payslip.businessName
        : (sw ? 'Biashara Yako' : 'Your Employer');
    const sep = '─────────────────────────────';
    final buf = StringBuffer();
    buf.writeln(sep);
    buf.writeln(
        '${sw ? "STAKABADHI YA MSHAHARA" : "PAYSLIP"} — $monthName ${payslip.year}');
    buf.writeln(displayBusiness);
    buf.writeln(sep);
    buf.writeln(sw ? 'MAPATO' : 'EARNINGS');
    buf.writeln(
        '${sw ? "Mshahara Msingi" : "Basic Salary"}:       TZS ${nf.format(payslip.grossSalary)}');
    buf.writeln(sep);
    buf.writeln(sw ? 'MAKATO' : 'DEDUCTIONS');
    buf.writeln('PAYE:              -TZS ${nf.format(payslip.paye)}');
    buf.writeln(
        '${sw ? "NSSF (Mfanyakazi)" : "NSSF (Employee)"}:   -TZS ${nf.format(payslip.nssfEmployee)}');
    buf.writeln(sep);
    buf.writeln(
        '${sw ? "MSHAHARA HALISI" : "NET PAY"}:            TZS ${nf.format(payslip.netSalary)}');
    buf.writeln(sep);
    buf.writeln(
        sw ? 'Mwajiri pia analipa:' : 'Employer also pays:');
    buf.writeln(
        '${sw ? "NSSF (Mwajiri)" : "NSSF (Employer)"}:    TZS ${nf.format(payslip.nssfEmployer)}');
    buf.writeln('SDL:                TZS ${nf.format(payslip.sdl)}');
    buf.writeln('WCF:                TZS ${nf.format(payslip.wcf)}');
    buf.writeln(
        '${sw ? "Jumla Gharama" : "Total cost to employer"}: TZS ${nf.format(payslip.totalEmployerCost)}');
    buf.writeln(sep);
    buf.write(sw
        ? 'Imetolewa na TAJIRI Payroll'
        : 'Generated by TAJIRI Payroll');
    SharePlus.instance.share(ShareParams(text: buf.toString()));
  }

  @override
  Widget build(BuildContext context) {
    final sw = AppStringsScope.of(context)?.isSwahili ?? false;
    final nf = NumberFormat('#,###', 'en');
    final monthName =
        sw ? _monthsSw[payslip.month - 1] : _monthsEn[payslip.month - 1];
    final displayBusiness = payslip.businessName.isNotEmpty
        ? payslip.businessName
        : (sw ? 'Biashara Yako' : 'Your Employer');

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: const BackButton(color: _kPrimary),
        title: Text(
          sw ? 'Stakabadhi ya Mshahara' : 'Payslip',
          style: const TextStyle(
              color: _kPrimary, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: () => _share(sw),
            icon: const Icon(Icons.share_rounded, color: _kPrimary),
            tooltip: sw ? 'Shiriki' : 'Share',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: _kPrimary,
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayBusiness,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(
                    sw ? 'STAKABADHI YA MSHAHARA' : 'PAYSLIP',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2),
                  ),
                  Text('$monthName ${payslip.year}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Earnings card
            _sectionCard(
              title: sw ? 'Mapato' : 'Earnings',
              children: [
                _row(sw ? 'Mshahara Msingi' : 'Basic Salary',
                    nf.format(payslip.grossSalary)),
                const Divider(height: 12),
                _row(sw ? 'Jumla Mapato' : 'Total Earnings',
                    nf.format(payslip.grossSalary),
                    isBold: true),
              ],
            ),

            const SizedBox(height: 10),

            // Deductions card
            _sectionCard(
              title: sw ? 'Makato' : 'Deductions',
              children: [
                _row('PAYE', nf.format(payslip.paye),
                    valueColor: Colors.red.shade700),
                _row(
                    sw
                        ? 'NSSF (Mfanyakazi 10%)'
                        : 'NSSF (Employee 10%)',
                    nf.format(payslip.nssfEmployee),
                    valueColor: Colors.red.shade700),
                const Divider(height: 12),
                _row(sw ? 'Jumla Makato' : 'Total Deductions',
                    nf.format(payslip.totalDeductions),
                    isBold: true),
              ],
            ),

            const SizedBox(height: 16),

            // Net pay hero
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: _kPrimary,
                  borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                Text(sw ? 'Mshahara Halisi' : 'Net Pay',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  'TZS ${nf.format(payslip.netSalary)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold),
                ),
              ]),
            ),

            const SizedBox(height: 10),

            // Employer costs footnote
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sw ? 'Gharama za Mwajiri' : 'Employer Costs',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary),
                  ),
                  const SizedBox(height: 6),
                  _row(
                      sw ? 'NSSF (Mwajiri 10%)' : 'NSSF (Employer 10%)',
                      nf.format(payslip.nssfEmployer)),
                  _row('SDL (3.5%)', nf.format(payslip.sdl)),
                  _row('WCF (0.5%)', nf.format(payslip.wcf)),
                  const Divider(height: 10),
                  _row(
                      sw ? 'Jumla Gharama' : 'Total Employer Cost',
                      nf.format(payslip.totalEmployerCost),
                      isBold: true),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Share button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                onPressed: () => _share(sw),
                icon: const Icon(Icons.share_rounded, size: 18),
                label: Text(
                  sw ? 'Shiriki Stakabadhi' : 'Share Payslip',
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

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(
      {required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary)),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String label, String value,
      {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 12,
                  color: _kSecondary,
                  fontWeight:
                      isBold ? FontWeight.w600 : FontWeight.normal),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'TZS $value',
            style: TextStyle(
                fontSize: 12,
                color: valueColor ?? _kPrimary,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
