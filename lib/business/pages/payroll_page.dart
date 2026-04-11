// lib/business/pages/payroll_page.dart
// Payroll calculation with accurate Tanzania PAYE, NSSF, SDL, WCF.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/business_models.dart';
import '../services/business_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class PayrollPage extends StatefulWidget {
  final int businessId;
  const PayrollPage({super.key, required this.businessId});

  @override
  State<PayrollPage> createState() => _PayrollPageState();
}

class _PayrollPageState extends State<PayrollPage> {
  String? _token;
  bool _loading = true;
  bool _calculating = false;
  bool _approving = false;
  List<Employee> _employees = [];
  List<PayrollRun> _history = [];
  PayrollRun? _currentPayroll;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  final _monthsEn = const [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  final _monthsSw = const [
    'Januari', 'Februari', 'Machi', 'Aprili', 'Mei', 'Juni',
    'Julai', 'Agosti', 'Septemba', 'Oktoba', 'Novemba', 'Desemba',
  ];

  bool get _isSwahili {
    final s = AppStringsScope.of(context);
    return s?.isSwahili ?? false;
  }

  List<String> get _months => _isSwahili ? _monthsSw : _monthsEn;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final storage = await LocalStorageService.getInstance();
    _token = storage.getAuthToken();
    await _loadAll();
  }

  Future<void> _loadAll() async {
    if (_token == null) return;
    setState(() => _loading = true);

    try {
      final results = await Future.wait([
        BusinessService.getEmployees(_token!, widget.businessId),
        BusinessService.getPayrollHistory(_token!, widget.businessId),
      ]);

      final empRes = results[0] as BusinessListResult<Employee>;
      final histRes = results[1] as BusinessListResult<PayrollRun>;

      if (mounted) {
        setState(() {
          _loading = false;
          if (empRes.success) {
            _employees = empRes.data.where((e) => e.isActive).toList();
          }
          if (histRes.success) _history = histRes.data;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  /// Calculate payroll locally using accurate Tanzania tax tables.
  void _calculateLocal() {
    if (_employees.isEmpty) return;
    setState(() => _calculating = true);

    final entries =
        _employees.map((e) => TanzaniaPAYE.buildPayrollEntry(e)).toList();

    final payroll = PayrollRun(
      businessId: widget.businessId,
      month: _selectedMonth,
      year: _selectedYear,
      employees: entries,
      totalGross: entries.fold(0.0, (s, e) => s + e.grossSalary),
      totalNet: entries.fold(0.0, (s, e) => s + e.netSalary),
      totalPaye: entries.fold(0.0, (s, e) => s + e.paye),
      totalNssf: entries.fold(
          0.0, (s, e) => s + e.nssfEmployee + e.nssfEmployer),
      totalSdl: entries.fold(0.0, (s, e) => s + e.sdl),
      totalWcf: entries.fold(0.0, (s, e) => s + e.wcf),
      status: PayrollStatus.draft,
    );

    setState(() {
      _calculating = false;
      _currentPayroll = payroll;
    });
  }

  /// Also try calculating via API.
  Future<void> _calculateViaApi() async {
    if (_token == null) return;
    setState(() => _calculating = true);
    try {
      final res = await BusinessService.calculatePayroll(
          _token!, widget.businessId, _selectedMonth, _selectedYear);
      if (mounted) {
        setState(() {
          _calculating = false;
          if (res.success && res.data != null) _currentPayroll = res.data;
        });
        if (!res.success) {
          // Fall back to local calculation
          _calculateLocal();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _calculating = false);
        _calculateLocal();
      }
    }
  }

  Future<void> _approvePayroll() async {
    if (_token == null || _currentPayroll == null) return;
    final sw = _isSwahili;

    setState(() => _approving = true);

    try {
      if (_currentPayroll!.id != null) {
        // Payroll has an id (from API), approve it
        final res = await BusinessService.approvePayroll(
            _token!, _currentPayroll!.id!);
        if (mounted) {
          setState(() => _approving = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(res.success
                  ? (sw ? 'Mishahara imeidhinishwa!' : 'Payroll approved!')
                  : (res.message ??
                      (sw ? 'Imeshindikana' : 'Approval failed')))));
          if (res.success) _loadAll();
        }
      } else {
        // Local-only calculation, no server-side payroll to approve
        if (mounted) {
          setState(() => _approving = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(sw
                  ? 'Mishahara imehesabiwa lakini haijahifadhiwa kwenye seva'
                  : 'Payroll calculated locally but not saved to server')));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _approving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(sw ? 'Imeshindikana' : 'An error occurred')));
      }
    }
  }

  void _showDisburseSalaries() {
    if (_currentPayroll == null) return;
    final nf = NumberFormat('#,###', 'en');
    final entries = _currentPayroll!.employees;
    final sw = _isSwahili;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(sw ? 'Lipa Mishahara' : 'Disburse Salaries',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _kPrimary)),
            const SizedBox(height: 4),
            Text(
                sw
                    ? 'M-Pesa disbursement inakuja hivi karibuni'
                    : 'M-Pesa disbursement coming soon',
                style: const TextStyle(fontSize: 12, color: _kSecondary)),
            const SizedBox(height: 16),
            // Employee breakdown
            ...entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(e.employeeName,
                            style: const TextStyle(
                                fontSize: 13, color: _kPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
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
                Text('TZS ${nf.format(_currentPayroll!.totalNet)}',
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
                  _approvePayroll();
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

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat('#,###', 'en');
    final sw = _isSwahili;

    return Container(
      color: _kBackground,
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: _kPrimary, strokeWidth: 2))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Month/Year selector
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _kCardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sw ? 'Chagua Mwezi na Mwaka' : 'Select Month & Year',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _kPrimary)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: _kBackground,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: _selectedMonth,
                                  isExpanded: true,
                                  items: List.generate(
                                    12,
                                    (i) => DropdownMenuItem(
                                        value: i + 1,
                                        child: Text(_months[i])),
                                  ),
                                  onChanged: (v) {
                                    if (v != null) {
                                      setState(() => _selectedMonth = v);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 100,
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: _kBackground,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: _selectedYear,
                                  items: List.generate(
                                    5,
                                    (i) {
                                      final y = DateTime.now().year - 1 + i;
                                      return DropdownMenuItem(
                                          value: y, child: Text('$y'));
                                    },
                                  ),
                                  onChanged: (v) {
                                    if (v != null) {
                                      setState(() => _selectedYear = v);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: _calculating || _employees.isEmpty
                              ? null
                              : () {
                                  // Try API first, fall back to local
                                  _calculateViaApi();
                                },
                          icon: _calculating
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.calculate_rounded, size: 20),
                          label: Text(
                              _calculating
                                  ? (sw ? 'Inahesabu...' : 'Calculating...')
                                  : (sw
                                      ? 'Hesabu Mishahara'
                                      : 'Calculate Payroll'),
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kPrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (_employees.isEmpty) ...[
                  const SizedBox(height: 40),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.people_outline_rounded,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                            sw
                                ? 'Ongeza wafanyakazi kwanza'
                                : 'Add employees first',
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(
                            sw
                                ? 'Nenda kwenye ukurasa wa Wafanyakazi'
                                : 'Go to the Employees page',
                            style: TextStyle(
                                color: Colors.grey.shade400, fontSize: 13)),
                      ],
                    ),
                  ),
                ],

                // Payroll results
                if (_currentPayroll != null) ...[
                  const SizedBox(height: 20),

                  // Summary totals
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _kPrimary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_months[_currentPayroll!.month - 1]} ${_currentPayroll!.year}',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _summaryCol(
                                  sw ? 'Jumla Mshahara' : 'Total Gross',
                                  nf.format(_currentPayroll!.totalGross),
                                  Colors.white),
                            ),
                            Expanded(
                              child: _summaryCol(
                                  sw ? 'Jumla Halisi' : 'Total Net',
                                  nf.format(_currentPayroll!.totalNet),
                                  Colors.white),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white24, height: 20),
                        Row(
                          children: [
                            Expanded(
                                child: _summaryCol('PAYE',
                                    nf.format(_currentPayroll!.totalPaye),
                                    Colors.white70)),
                            Expanded(
                                child: _summaryCol('NSSF',
                                    nf.format(_currentPayroll!.totalNssf),
                                    Colors.white70)),
                            Expanded(
                                child: _summaryCol('SDL',
                                    nf.format(_currentPayroll!.totalSdl),
                                    Colors.white70)),
                            Expanded(
                                child: _summaryCol('WCF',
                                    nf.format(_currentPayroll!.totalWcf),
                                    Colors.white70)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Per-employee breakdown
                  Text(
                      sw
                          ? 'Maelezo kwa Mfanyakazi'
                          : 'Per-Employee Breakdown',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary)),
                  const SizedBox(height: 10),
                  ..._currentPayroll!.employees
                      .map((entry) => _employeePayrollCard(entry, nf, sw)),

                  const SizedBox(height: 16),

                  // PAYE bracket reference
                  _payeBracketReference(sw),

                  const SizedBox(height: 16),

                  // Approve button
                  if (_currentPayroll!.status == PayrollStatus.draft)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _approving ? null : _approvePayroll,
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
                                fontSize: 15, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),

                  if (_currentPayroll!.status == PayrollStatus.draft) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton.icon(
                        onPressed: _showDisburseSalaries,
                        icon: const Icon(Icons.payments_rounded, size: 20),
                        label: Text(
                            sw
                                ? 'Tazama Maelezo ya Malipo'
                                : 'View Payment Details',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kPrimary,
                          side: const BorderSide(color: _kPrimary),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ],

                // Payroll history
                if (_history.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(sw ? 'Historia ya Mishahara' : 'Payroll History',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _kPrimary)),
                  const SizedBox(height: 10),
                  ..._history.map((pr) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _kCardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_months[pr.month - 1]} ${pr.year}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: _kPrimary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    sw
                                        ? '${pr.employees.length} wafanyakazi'
                                        : '${pr.employees.length} employees',
                                    style: const TextStyle(
                                        fontSize: 12, color: _kSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('TZS ${nf.format(pr.totalNet)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _kPrimary)),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: pr.status == PayrollStatus.paid
                                        ? Colors.green.shade50
                                        : Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _payrollStatusLabel(pr.status, sw),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: pr.status == PayrollStatus.paid
                                          ? Colors.green.shade700
                                          : Colors.orange.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )),
                ],

                const SizedBox(height: 80),
              ],
            ),
    );
  }

  String _payrollStatusLabel(PayrollStatus s, bool sw) {
    switch (s) {
      case PayrollStatus.draft:
        return sw ? 'Rasimu' : 'Draft';
      case PayrollStatus.approved:
        return sw ? 'Imeidhinishwa' : 'Approved';
      case PayrollStatus.paid:
        return sw ? 'Imelipwa' : 'Paid';
    }
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
                fontSize: 14, fontWeight: FontWeight.bold, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _employeePayrollCard(PayrollEntry entry, NumberFormat nf, bool sw) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: _kPrimary.withValues(alpha: 0.08),
                child: Text(
                  entry.employeeName.isNotEmpty
                      ? entry.employeeName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: _kPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(entry.employeeName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: _kPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(sw ? 'Halisi' : 'Net',
                      style:
                          const TextStyle(fontSize: 10, color: _kSecondary)),
                  Text('TZS ${nf.format(entry.netSalary)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _kPrimary,
                          fontSize: 15)),
                ],
              ),
            ],
          ),
          const Divider(height: 16),
          _payrollRow(sw ? 'Mshahara Ghafi' : 'Gross Salary',
              nf.format(entry.grossSalary)),
          _payrollRow('PAYE', '- ${nf.format(entry.paye)}',
              color: Colors.red.shade700),
          _payrollRow(
              sw ? 'NSSF (Mfanyakazi 10%)' : 'NSSF (Employee 10%)',
              '- ${nf.format(entry.nssfEmployee)}',
              color: Colors.red.shade700),
          const Divider(height: 12),
          _payrollRow(sw ? 'Mshahara Halisi' : 'Net Salary',
              nf.format(entry.netSalary),
              isBold: true),
          const SizedBox(height: 6),
          Text(
              sw
                  ? 'Mwajiri analipa: NSSF ${nf.format(entry.nssfEmployer)} + SDL ${nf.format(entry.sdl)} + WCF ${nf.format(entry.wcf)}'
                  : 'Employer pays: NSSF ${nf.format(entry.nssfEmployer)} + SDL ${nf.format(entry.sdl)} + WCF ${nf.format(entry.wcf)}',
              style: TextStyle(
                  fontSize: 10,
                  color: _kSecondary.withValues(alpha: 0.7))),
          Text(
              sw
                  ? 'Jumla gharama ya mwajiri: TZS ${nf.format(entry.totalEmployerCost)}'
                  : 'Total employer cost: TZS ${nf.format(entry.totalEmployerCost)}',
              style: const TextStyle(fontSize: 11, color: _kSecondary)),
        ],
      ),
    );
  }

  Widget _payrollRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: _kSecondary,
                    fontWeight: isBold ? FontWeight.w600 : FontWeight.normal),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Text('TZS $value',
              style: TextStyle(
                  fontSize: 12,
                  color: color ?? _kPrimary,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _payeBracketReference(bool sw) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(sw ? 'Viwango vya PAYE (Tanzania)' : 'PAYE Tax Brackets (Tanzania)',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary)),
          const SizedBox(height: 8),
          _bracketRow('0 - 270,000', '0%'),
          _bracketRow('270,001 - 520,000', '8%'),
          _bracketRow('520,001 - 760,000', '20%'),
          _bracketRow('760,001 - 1,000,000', '25%'),
          _bracketRow(sw ? 'Zaidi ya 1,000,000' : 'Above 1,000,000', '30%'),
          const SizedBox(height: 8),
          Text(
            sw
                ? 'NSSF: Mwajiri 10% + Mfanyakazi 10% | SDL: 3.5% | WCF: 0.5%'
                : 'NSSF: Employer 10% + Employee 10% | SDL: 3.5% | WCF: 0.5%',
            style: TextStyle(
                fontSize: 10,
                color: _kSecondary.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }

  Widget _bracketRow(String range, String rate) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('TZS $range',
              style: const TextStyle(fontSize: 11, color: _kSecondary)),
          Text(rate,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary)),
        ],
      ),
    );
  }
}
