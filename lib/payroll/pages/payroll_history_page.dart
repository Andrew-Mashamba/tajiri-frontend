// lib/payroll/pages/payroll_history_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/payroll_models.dart';
import '../services/payroll_service.dart';
import 'payroll_run_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);
const Color _kCard = Color(0xFFFFFFFF);

class PayrollHistoryPage extends StatefulWidget {
  final int businessId;
  final String token;
  final String businessName;

  const PayrollHistoryPage({
    super.key,
    required this.businessId,
    required this.token,
    this.businessName = '',
  });

  @override
  State<PayrollHistoryPage> createState() => _PayrollHistoryPageState();
}

class _PayrollHistoryPageState extends State<PayrollHistoryPage> {
  List<PayrollRun> _history = [];
  bool _loading = true;
  String? _error;
  int _selectedYear = DateTime.now().year;

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
      final res = await PayrollService.getHistory(widget.token, widget.businessId);
      if (mounted) {
        setState(() {
          _loading = false;
          if (res.success) {
            _history = res.data;
          } else {
            _error = res.message ?? 'Failed to load history';
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  List<PayrollRun> get _filtered =>
      _history.where((r) => r.year == _selectedYear).toList()
        ..sort((a, b) => b.month.compareTo(a.month));

  @override
  Widget build(BuildContext context) {
    final sw = AppStringsScope.of(context)?.isSwahili ?? false;
    final nf = NumberFormat('#,###', 'en');
    final months = sw ? _monthsSw : _monthsEn;
    final now = DateTime.now().year;
    final years = [now - 2, now - 1, now];
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: const BackButton(color: _kPrimary),
        title: Text(
          sw ? 'Historia ya Mishahara' : 'Payroll History',
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
                        ],
                      ),
                    ),
                  )
                : Column(
                children: [
                  SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      children: years.map((y) {
                        final sel = y == _selectedYear;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedYear = y),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: sel ? _kPrimary : _kCard,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: sel
                                      ? _kPrimary
                                      : Colors.grey.shade200),
                            ),
                            child: Text(
                              '$y',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: sel
                                      ? Colors.white
                                      : _kSecondary),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.history_rounded,
                                      size: 56,
                                      color: Colors.grey.shade300),
                                  const SizedBox(height: 12),
                                  Text(
                                    sw
                                        ? 'Hakuna mishahara bado.\nHesabu mshahara wako wa kwanza.'
                                        : 'No payroll runs yet.\nCalculate your first payroll.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 14),
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: _kPrimary),
                                    child: Text(
                                      sw ? 'Hesabu Mishahara' : 'Calculate Payroll',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (ctx, i) {
                              final run = filtered[i];
                              return GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PayrollRunPage(
                                      run: run,
                                      token: widget.token,
                                      businessName: widget.businessName,
                                    ),
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
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${months[run.month - 1]} ${run.year}',
                                              style: const TextStyle(
                                                  fontWeight:
                                                      FontWeight.w600,
                                                  color: _kPrimary),
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              sw
                                                  ? '${run.employees.length} wafanyakazi'
                                                  : '${run.employees.length} employees',
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: _kSecondary),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'TZS ${nf.format(run.totalNet)}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: _kPrimary),
                                          ),
                                          _statusChip(run.status, sw),
                                        ],
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                          Icons.chevron_right_rounded,
                                          size: 18,
                                          color: _kSecondary),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _statusChip(PayrollStatus s, bool sw) {
    final label = payrollStatusLabel(s, swahili: sw);
    Color bg;
    Color fg;
    switch (s) {
      case PayrollStatus.draft:
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade800;
        break;
      case PayrollStatus.approved:
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade800;
        break;
      case PayrollStatus.paid:
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        break;
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
