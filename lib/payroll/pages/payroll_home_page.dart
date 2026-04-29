// lib/payroll/pages/payroll_home_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../business/models/business_models.dart' show Business;
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../../team/models/team_models.dart' show Employee;
import '../../team/pages/employees_page.dart' show EmployeesPage;
import '../../team/services/team_service.dart' show TeamService;
import '../models/payroll_models.dart';
import '../services/payroll_service.dart';
import 'payroll_run_page.dart';
import 'payroll_history_page.dart';
import 'statutory_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);
const Color _kCard = Color(0xFFFFFFFF);

class PayrollHomePage extends StatefulWidget {
  final int businessId;
  final List<Business> businesses;

  const PayrollHomePage({
    super.key,
    required this.businessId,
    this.businesses = const [],
  });

  @override
  State<PayrollHomePage> createState() => _PayrollHomePageState();
}

class _PayrollHomePageState extends State<PayrollHomePage> {
  String? _token;
  bool _loading = true;
  bool _calculating = false;
  List<Employee> _employees = [];
  List<PayrollRun> _history = [];
  PayrollRun? _currentRun;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  static const _monthsEn = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const _monthsSw = [
    'Januari', 'Februari', 'Machi', 'Aprili', 'Mei', 'Juni',
    'Julai', 'Agosti', 'Septemba', 'Oktoba', 'Novemba', 'Desemba',
  ];

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;
  List<String> get _months => _sw ? _monthsSw : _monthsEn;

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
      final empFuture = TeamService.getEmployees(_token!, widget.businessId);
      final histFuture = PayrollService.getHistory(_token!, widget.businessId);
      final empRes = await empFuture;
      final histRes = await histFuture;

      if (mounted) {
        setState(() {
          _loading = false;
          if (empRes.success) {
            _employees = empRes.data.where((e) => e.isActive).toList();
          }
          if (histRes.success) _history = histRes.data;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _calculateLocal() {
    if (_employees.isEmpty) return;
    setState(() => _calculating = true);
    final entries =
        _employees.map((e) => TanzaniaPAYE.buildPayrollEntry(e)).toList();
    final run = PayrollRun(
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
      _currentRun = run;
    });
  }

  Future<void> _calculate() async {
    if (_token == null) return;
    setState(() => _calculating = true);
    try {
      final res = await PayrollService.calculate(
          _token!, widget.businessId, _selectedMonth, _selectedYear);
      if (mounted) {
        if (res.success && res.data != null) {
          setState(() {
            _calculating = false;
            _currentRun = res.data;
          });
        } else {
          _calculateLocal();
        }
      }
    } catch (_) {
      if (mounted) _calculateLocal();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;
    final nf = NumberFormat('#,###', 'en');

    return Container(
      color: _kBg,
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: _kPrimary, strokeWidth: 2))
          : RefreshIndicator(
              onRefresh: _loadAll,
              color: _kPrimary,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Month/Year picker
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _kCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sw
                              ? 'Chagua Mwezi na Mwaka'
                              : 'Select Month & Year',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _kPrimary),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12),
                                decoration: BoxDecoration(
                                  color: _kBg,
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
                                          child: Text(_months[i],
                                              overflow:
                                                  TextOverflow.ellipsis)),
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12),
                                decoration: BoxDecoration(
                                  color: _kBg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: _selectedYear,
                                    items: List.generate(5, (i) {
                                      final y =
                                          DateTime.now().year - 4 + i;
                                      return DropdownMenuItem(
                                          value: y, child: Text('$y'));
                                    }),
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
                                : _calculate,
                            icon: _calculating
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2))
                                : const Icon(Icons.calculate_rounded,
                                    size: 20),
                            label: Text(
                              _calculating
                                  ? (sw ? 'Inahesabu...' : 'Calculating...')
                                  : (sw
                                      ? 'Hesabu Mishahara'
                                      : 'Calculate Payroll'),
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600),
                            ),
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

                  // Empty state
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
                                color: Colors.grey.shade500,
                                fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            sw
                                ? 'Nenda kwenye ukurasa wa Wafanyakazi'
                                : 'Go to the Employees page',
                            style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 13),
                          ),
                          if (widget.businesses.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EmployeesPage(
                                      businesses: widget.businesses),
                                ),
                              ).then((_) => _loadAll()),
                              icon: const Icon(Icons.people_rounded, size: 18),
                              label: Text(
                                sw ? 'Nenda Wafanyakazi' : 'Go to Employees',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _kPrimary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  // Stats strip
                  if (_currentRun != null) ...[
                    const SizedBox(height: 20),
                    _statsStrip(_currentRun!, nf, sw),
                    const SizedBox(height: 12),

                    // View Full Payroll card
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PayrollRunPage(
                            run: _currentRun!,
                            token: _token ?? '',
                          ),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _kCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.receipt_long_rounded,
                                color: _kPrimary, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                sw
                                    ? 'Tazama Mishahara Kamili'
                                    : 'View Full Payroll',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: _kPrimary),
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded,
                                color: _kSecondary, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Statutory Obligations shortcut
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StatutoryPage(
                          businessId: widget.businessId,
                          token: _token ?? '',
                        ),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _kCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance_rounded,
                              color: _kPrimary, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              sw
                                  ? 'Matoleo ya Kisheria (PAYE/NSSF/SDL/WCF)'
                                  : 'Statutory Obligations (PAYE/NSSF/SDL/WCF)',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _kPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              color: _kSecondary, size: 20),
                        ],
                      ),
                    ),
                  ),

                  // History section
                  if (_history.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          sw ? 'Historia ya Mishahara' : 'Payroll History',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: _kPrimary),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PayrollHistoryPage(
                                businessId: widget.businessId,
                                token: _token ?? '',
                              ),
                            ),
                          ),
                          child: Text(
                            sw ? 'Tazama Zote' : 'View All',
                            style: const TextStyle(
                                fontSize: 13,
                                color: _kPrimary,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ..._history.take(3).map((run) => GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PayrollRunPage(
                                run: run,
                                token: _token ?? '',
                              ),
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _kCard,
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: Colors.grey.shade100),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${_months[run.month - 1]} ${run.year}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: _kPrimary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
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
                                const Icon(Icons.chevron_right_rounded,
                                    size: 18, color: _kSecondary),
                              ],
                            ),
                          ),
                        )),
                  ],

                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _statsStrip(PayrollRun run, NumberFormat nf, bool sw) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kPrimary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_months[run.month - 1]} ${run.year}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _col(
                      sw ? 'Jumla Ghafi' : 'Gross',
                      nf.format(run.totalGross),
                      Colors.white)),
              Expanded(
                  child: _col(
                      sw ? 'Jumla Halisi' : 'Net',
                      nf.format(run.totalNet),
                      Colors.white)),
              Expanded(
                  child: _col(
                      'PAYE', nf.format(run.totalPaye), Colors.white70)),
              Expanded(
                  child: _col(
                      'NSSF', nf.format(run.totalNssf), Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _col(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 10, color: color.withValues(alpha: 0.7))),
        Text('TZS $value',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _statusChip(PayrollStatus s, bool sw) {
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
      child: Text(
        payrollStatusLabel(s, swahili: sw),
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}
