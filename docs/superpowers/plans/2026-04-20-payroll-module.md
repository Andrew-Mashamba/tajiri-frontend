# Payroll Module Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extract the existing `PayrollPage` into a full-featured `lib/payroll/` module with per-employee payslips, statutory obligation tracking, and history — following the same conventions as `lib/team/` and `lib/myjob/`.

**Architecture:** New module at `lib/payroll/` with models, service, 5 pages, 2 widgets, and a barrel export. Models are migrated from `business_models.dart` (with re-exports left behind for backward compat). Service methods are extracted from `BusinessService` with delegation stubs. The `biz_payroll` profile tab is updated to use the new `PayrollHomePage`.

**Tech Stack:** Flutter/Dart (setState, no Provider/Bloc/Riverpod), `http` package, `intl` for currency, `share_plus` for share, `flutter/material.dart`

---

## File Map

| Action | File | Responsibility |
|--------|------|----------------|
| Create | `lib/payroll/models/payroll_models.dart` | PayrollStatus, PayrollEntry, PayrollRun, TanzaniaPAYE, StatutoryObligation |
| Modify | `lib/business/models/business_models.dart` | Add re-export block at bottom |
| Create | `lib/payroll/services/payroll_service.dart` | All payroll API calls (5 methods) |
| Modify | `lib/business/services/business_service.dart` | Add delegation stubs for 3 existing payroll methods |
| Create | `lib/payroll/widgets/payslip_card.dart` | Per-employee row widget |
| Create | `lib/payroll/widgets/tax_summary_widget.dart` | PAYE brackets reference card |
| Create | `lib/payroll/pages/payroll_run_page.dart` | Single run detail + approve/disburse |
| Create | `lib/payroll/pages/payslip_page.dart` | Per-employee payslip + share |
| Create | `lib/payroll/pages/payroll_history_page.dart` | Full paginated history with year filter |
| Create | `lib/payroll/pages/statutory_page.dart` | PAYE/NSSF/SDL/WCF obligations tracker |
| Create | `lib/payroll/pages/payroll_home_page.dart` | Hub page (no AppBar, tab-embedded) |
| Create | `lib/payroll/payroll.dart` | Barrel export |
| Modify | `lib/screens/profile/profile_screen.dart` | Update biz_payroll case + import |
| Delete | `lib/business/pages/payroll_page.dart` | Replaced by PayrollHomePage |

---

## Task 1: Payroll Models

**Files:**
- Create: `lib/payroll/models/payroll_models.dart`
- Modify: `lib/business/models/business_models.dart`

- [ ] **Step 1: Create `lib/payroll/models/payroll_models.dart`**

```dart
// lib/payroll/models/payroll_models.dart
import '../../team/models/team_models.dart' show Employee;

int? _parseInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString());
}

double _parseDouble(dynamic v, [double fallback = 0.0]) {
  if (v == null) return fallback;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString()) ?? fallback;
}

bool _parseBool(dynamic v, [bool fallback = false]) {
  if (v == null) return fallback;
  if (v is bool) return v;
  if (v is int) return v == 1;
  if (v is String) return v == '1' || v.toLowerCase() == 'true';
  return fallback;
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}

// ---------------------------------------------------------------------------
// PayrollStatus
// ---------------------------------------------------------------------------
enum PayrollStatus { draft, approved, paid }

PayrollStatus _parsePayrollStatus(dynamic v) {
  if (v == null) return PayrollStatus.draft;
  final s = v.toString().toLowerCase();
  for (final ps in PayrollStatus.values) {
    if (ps.name == s) return ps;
  }
  return PayrollStatus.draft;
}

String payrollStatusLabel(PayrollStatus s, {bool swahili = false}) {
  switch (s) {
    case PayrollStatus.draft:
      return swahili ? 'Rasimu' : 'Draft';
    case PayrollStatus.approved:
      return swahili ? 'Imeidhinishwa' : 'Approved';
    case PayrollStatus.paid:
      return swahili ? 'Imelipwa' : 'Paid';
  }
}

// ---------------------------------------------------------------------------
// PayrollEntry
// ---------------------------------------------------------------------------
class PayrollEntry {
  final int? employeeId;
  final String employeeName;
  final double grossSalary;
  final double paye;
  final double nssfEmployee;
  final double nssfEmployer;
  final double sdl;
  final double wcf;
  final double netSalary;

  PayrollEntry({
    this.employeeId,
    this.employeeName = '',
    this.grossSalary = 0,
    this.paye = 0,
    this.nssfEmployee = 0,
    this.nssfEmployer = 0,
    this.sdl = 0,
    this.wcf = 0,
    this.netSalary = 0,
  });

  factory PayrollEntry.fromJson(Map<String, dynamic> json) {
    return PayrollEntry(
      employeeId: _parseInt(json['employee_id']),
      employeeName: json['employee_name']?.toString() ?? '',
      grossSalary: _parseDouble(json['gross_salary']),
      paye: _parseDouble(json['paye']),
      nssfEmployee: _parseDouble(json['nssf_employee']),
      nssfEmployer: _parseDouble(json['nssf_employer']),
      sdl: _parseDouble(json['sdl']),
      wcf: _parseDouble(json['wcf']),
      netSalary: _parseDouble(json['net_salary']),
    );
  }

  Map<String, dynamic> toJson() => {
        'employee_id': employeeId,
        'employee_name': employeeName,
        'gross_salary': grossSalary,
        'paye': paye,
        'nssf_employee': nssfEmployee,
        'nssf_employer': nssfEmployer,
        'sdl': sdl,
        'wcf': wcf,
        'net_salary': netSalary,
      };

  double get totalEmployerCost => grossSalary + nssfEmployer + sdl + wcf;
}

// ---------------------------------------------------------------------------
// PayrollRun
// ---------------------------------------------------------------------------
class PayrollRun {
  final int? id;
  final int? businessId;
  final int month;
  final int year;
  final List<PayrollEntry> employees;
  final double totalGross;
  final double totalNet;
  final double totalPaye;
  final double totalNssf;
  final double totalSdl;
  final double totalWcf;
  final PayrollStatus status;
  final DateTime? createdAt;

  PayrollRun({
    this.id,
    this.businessId,
    this.month = 1,
    this.year = 2026,
    this.employees = const [],
    this.totalGross = 0,
    this.totalNet = 0,
    this.totalPaye = 0,
    this.totalNssf = 0,
    this.totalSdl = 0,
    this.totalWcf = 0,
    this.status = PayrollStatus.draft,
    this.createdAt,
  });

  factory PayrollRun.fromJson(Map<String, dynamic> json) {
    List<PayrollEntry> emps = [];
    if (json['employees'] is List) {
      emps = (json['employees'] as List)
          .map((e) => PayrollEntry.fromJson(e is Map<String, dynamic> ? e : {}))
          .toList();
    }
    return PayrollRun(
      id: _parseInt(json['id']),
      businessId: _parseInt(json['business_id']),
      month: _parseInt(json['month']) ?? 1,
      year: _parseInt(json['year']) ?? 2026,
      employees: emps,
      totalGross: _parseDouble(json['total_gross']),
      totalNet: _parseDouble(json['total_net']),
      totalPaye: _parseDouble(json['total_paye']),
      totalNssf: _parseDouble(json['total_nssf']),
      totalSdl: _parseDouble(json['total_sdl']),
      totalWcf: _parseDouble(json['total_wcf']),
      status: _parsePayrollStatus(json['status']),
      createdAt: _parseDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'business_id': businessId,
        'month': month,
        'year': year,
        'employees': employees.map((e) => e.toJson()).toList(),
        'total_gross': totalGross,
        'total_net': totalNet,
        'total_paye': totalPaye,
        'total_nssf': totalNssf,
        'total_sdl': totalSdl,
        'total_wcf': totalWcf,
        'status': status.name,
      };
}

// ---------------------------------------------------------------------------
// TanzaniaPAYE
// ---------------------------------------------------------------------------
class TanzaniaPAYE {
  static double calculateMonthlyPAYE(double grossMonthly) {
    if (grossMonthly <= 270000) return 0;

    double paye = 0;

    if (grossMonthly > 1000000) {
      paye += (grossMonthly - 1000000) * 0.30;
      paye += (1000000 - 760000) * 0.25;
      paye += (760000 - 520000) * 0.20;
      paye += (520000 - 270000) * 0.08;
    } else if (grossMonthly > 760000) {
      paye += (grossMonthly - 760000) * 0.25;
      paye += (760000 - 520000) * 0.20;
      paye += (520000 - 270000) * 0.08;
    } else if (grossMonthly > 520000) {
      paye += (grossMonthly - 520000) * 0.20;
      paye += (520000 - 270000) * 0.08;
    } else {
      paye += (grossMonthly - 270000) * 0.08;
    }

    return paye;
  }

  static double nssfEmployee(double gross) => gross * 0.10;
  static double nssfEmployer(double gross) => gross * 0.10;
  static double sdl(double gross) => gross * 0.035;
  static double wcf(double gross) => gross * 0.005;

  static double netSalary(double gross) {
    return gross - calculateMonthlyPAYE(gross) - nssfEmployee(gross);
  }

  static double totalEmployerCost(double gross) {
    return gross + nssfEmployer(gross) + sdl(gross) + wcf(gross);
  }

  static PayrollEntry buildPayrollEntry(Employee emp) {
    final gross = emp.grossSalary;
    return PayrollEntry(
      employeeId: emp.id,
      employeeName: emp.name,
      grossSalary: gross,
      paye: calculateMonthlyPAYE(gross),
      nssfEmployee: nssfEmployee(gross),
      nssfEmployer: nssfEmployer(gross),
      sdl: sdl(gross),
      wcf: wcf(gross),
      netSalary: netSalary(gross),
    );
  }
}

// ---------------------------------------------------------------------------
// StatutoryObligation
// ---------------------------------------------------------------------------
class StatutoryObligation {
  final int? id;
  final String type; // 'PAYE' | 'NSSF' | 'SDL' | 'WCF'
  final int month;
  final int year;
  final double amount;
  final bool remitted;
  final DateTime? dueDate;
  final DateTime? remittedAt;

  StatutoryObligation({
    this.id,
    required this.type,
    required this.month,
    required this.year,
    required this.amount,
    this.remitted = false,
    this.dueDate,
    this.remittedAt,
  });

  factory StatutoryObligation.fromJson(Map<String, dynamic> json) {
    return StatutoryObligation(
      id: _parseInt(json['id']),
      type: json['type']?.toString() ?? 'PAYE',
      month: _parseInt(json['month']) ?? 1,
      year: _parseInt(json['year']) ?? DateTime.now().year,
      amount: _parseDouble(json['amount']),
      remitted: _parseBool(json['remitted']),
      dueDate: _parseDate(json['due_date']),
      remittedAt: _parseDate(json['remitted_at']),
    );
  }
}
```

- [ ] **Step 2: Add re-exports at the bottom of `lib/business/models/business_models.dart`**

Open `lib/business/models/business_models.dart` and append these lines at the very end of the file (after the last closing brace on line 1846):

```dart

// Re-export payroll models from the dedicated payroll module.
// Kept here so existing callers (business_service.dart, payroll_page.dart, tax_page.dart) don't break.
export 'package:tajiri/payroll/models/payroll_models.dart'
    show PayrollRun, PayrollEntry, PayrollStatus, TanzaniaPAYE, payrollStatusLabel;
```

- [ ] **Step 3: Verify analyze passes**

```bash
cd /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND && flutter analyze lib/payroll/models/ lib/business/models/business_models.dart 2>&1 | head -30
```

Expected: no errors (warnings about duplicate definitions are expected — the re-export adds symbols that also exist locally in business_models.dart; that's fine because the local ones will still be used by local callers).

Note: If you see `'PayrollStatus' is already defined` errors, it means business_models.dart's local definitions conflict with the re-export. In that case, **remove only the re-export line** (the re-export is forward-compat; the local definitions stay). The key requirement is that `lib/payroll/models/payroll_models.dart` compiles cleanly on its own.

- [ ] **Step 4: Commit**

```bash
cd /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND && git add lib/payroll/models/payroll_models.dart lib/business/models/business_models.dart && git commit -m "feat(payroll): add payroll_models.dart with StatutoryObligation"
```

---

## Task 2: Payroll Service

**Files:**
- Create: `lib/payroll/services/payroll_service.dart`
- Modify: `lib/business/services/business_service.dart` (lines ~415-465)

- [ ] **Step 1: Create `lib/payroll/services/payroll_service.dart`**

```dart
// lib/payroll/services/payroll_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../models/payroll_models.dart';

void _log(String m) => debugPrint('[PayrollService] $m');

class PayrollResult<T> {
  final bool success;
  final T? data;
  final String? message;
  const PayrollResult({required this.success, this.data, this.message});
}

class PayrollListResult<T> {
  final bool success;
  final List<T> data;
  final String? message;
  const PayrollListResult({required this.success, this.data = const [], this.message});
}

class PayrollService {
  static Map<String, String> _h(String token) => ApiConfig.authHeaders(token);

  // GET /business/{id}/payroll
  static Future<PayrollListResult<PayrollRun>> getHistory(
      String token, int businessId) async {
    final url = '${ApiConfig.baseUrl}/business/$businessId/payroll';
    _log('GET $url');
    try {
      final res = await http.get(Uri.parse(url), headers: _h(token));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        final list = (body['data'] as List? ?? [])
            .map((e) => PayrollRun.fromJson(e as Map<String, dynamic>))
            .toList();
        return PayrollListResult(success: true, data: list);
      }
      return PayrollListResult(success: false, message: body['message']?.toString());
    } catch (e) {
      return PayrollListResult(success: false, message: e.toString());
    }
  }

  // POST /business/{id}/payroll/calculate
  static Future<PayrollResult<PayrollRun>> calculate(
      String token, int businessId, int month, int year) async {
    final url = '${ApiConfig.baseUrl}/business/$businessId/payroll/calculate';
    _log('POST $url');
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: {..._h(token), 'Content-Type': 'application/json'},
        body: jsonEncode({'month': month, 'year': year}),
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 || res.statusCode == 201) {
        final d = body['data'] ?? body;
        return PayrollResult(success: true, data: PayrollRun.fromJson(d as Map<String, dynamic>));
      }
      return PayrollResult(success: false, message: body['message']?.toString());
    } catch (e) {
      return PayrollResult(success: false, message: e.toString());
    }
  }

  // POST /business/payroll/{id}/approve
  static Future<PayrollResult<void>> approve(String token, int payrollId) async {
    final url = '${ApiConfig.baseUrl}/business/payroll/$payrollId/approve';
    _log('POST $url');
    try {
      final res = await http.post(Uri.parse(url), headers: _h(token));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 || res.statusCode == 201) {
        return const PayrollResult(success: true);
      }
      return PayrollResult(success: false, message: body['message']?.toString());
    } catch (e) {
      return PayrollResult(success: false, message: e.toString());
    }
  }

  // GET /business/{id}/payroll/statutory
  static Future<PayrollListResult<StatutoryObligation>> getStatutory(
      String token, int businessId) async {
    final url = '${ApiConfig.baseUrl}/business/$businessId/payroll/statutory';
    _log('GET $url');
    try {
      final res = await http.get(Uri.parse(url), headers: _h(token));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final list = (body['data'] as List? ?? [])
            .map((e) => StatutoryObligation.fromJson(e as Map<String, dynamic>))
            .toList();
        return PayrollListResult(success: true, data: list);
      }
      // 404 means endpoint not yet deployed — caller handles graceful degradation
      return PayrollListResult(success: false, message: 'endpoint_unavailable');
    } catch (e) {
      return PayrollListResult(success: false, message: e.toString());
    }
  }

  // POST /business/payroll/statutory/{id}/remit
  static Future<PayrollResult<void>> markRemitted(
      String token, int obligationId) async {
    final url =
        '${ApiConfig.baseUrl}/business/payroll/statutory/$obligationId/remit';
    _log('POST $url');
    try {
      final res = await http.post(Uri.parse(url), headers: _h(token));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 || res.statusCode == 201) {
        return const PayrollResult(success: true);
      }
      return PayrollResult(success: false, message: body['message']?.toString());
    } catch (e) {
      return PayrollResult(success: false, message: e.toString());
    }
  }
}
```

- [ ] **Step 2: Add delegation stubs in `business_service.dart`**

Find the three payroll methods in `lib/business/services/business_service.dart` (around line 415). Replace the bodies of `calculatePayroll`, `approvePayroll`, and `getPayrollHistory` to delegate to `PayrollService`. You also need to add the import at the top.

Add this import near the top of `business_service.dart` (after existing imports):
```dart
import 'package:tajiri/payroll/services/payroll_service.dart';
import 'package:tajiri/payroll/models/payroll_models.dart' show PayrollRun;
```

Replace the body of `calculatePayroll`:
```dart
  static Future<BusinessResult<PayrollRun>> calculatePayroll(
      String token, int businessId, int month, int year) async {
    final r = await PayrollService.calculate(token, businessId, month, year);
    return BusinessResult(success: r.success, data: r.data, message: r.message);
  }
```

Replace the body of `approvePayroll`:
```dart
  static Future<BusinessResult<void>> approvePayroll(
      String token, int payrollId) async {
    final r = await PayrollService.approve(token, payrollId);
    return BusinessResult(success: r.success, message: r.message);
  }
```

Replace the body of `getPayrollHistory`:
```dart
  static Future<BusinessListResult<PayrollRun>> getPayrollHistory(
      String token, int businessId) async {
    final r = await PayrollService.getHistory(token, businessId);
    return BusinessListResult(success: r.success, data: r.data, message: r.message);
  }
```

- [ ] **Step 3: Verify analyze passes**

```bash
cd /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND && flutter analyze lib/payroll/services/ lib/business/services/business_service.dart 2>&1 | head -30
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
cd /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND && git add lib/payroll/services/payroll_service.dart lib/business/services/business_service.dart && git commit -m "feat(payroll): add PayrollService, delegate BusinessService stubs"
```

---

## Task 3: Widgets (PayslipCard + TaxSummaryWidget)

**Files:**
- Create: `lib/payroll/widgets/payslip_card.dart`
- Create: `lib/payroll/widgets/tax_summary_widget.dart`

- [ ] **Step 1: Create `lib/payroll/widgets/payslip_card.dart`**

```dart
// lib/payroll/widgets/payslip_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/payroll_models.dart';
import '../pages/payslip_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCard = Color(0xFFFFFFFF);

class PayslipCard extends StatelessWidget {
  final PayrollEntry entry;
  final int month;
  final int year;
  final String token;
  final String businessName;

  const PayslipCard({
    super.key,
    required this.entry,
    required this.month,
    required this.year,
    required this.token,
    this.businessName = '',
  });

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat('#,###', 'en');
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PayslipPage(
            entry: entry,
            month: month,
            year: year,
            businessName: businessName,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: _kPrimary.withValues(alpha: 0.08),
              child: Text(
                entry.employeeName.isNotEmpty
                    ? entry.employeeName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    color: _kPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.employeeName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _kPrimary,
                        fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Gross: TZS ${nf.format(entry.grossSalary)}',
                    style: const TextStyle(fontSize: 11, color: _kSecondary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'TZS ${nf.format(entry.netSalary)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _kPrimary,
                      fontSize: 14),
                ),
                Text(
                  'PAYE: ${nf.format(entry.paye)}',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: _kSecondary),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Create `lib/payroll/widgets/tax_summary_widget.dart`**

```dart
// lib/payroll/widgets/tax_summary_widget.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class TaxSummaryWidget extends StatelessWidget {
  const TaxSummaryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final sw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sw ? 'Viwango vya PAYE (Tanzania)' : 'PAYE Tax Brackets (Tanzania)',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _kPrimary),
          ),
          const SizedBox(height: 8),
          _row('0 – 270,000', '0%'),
          _row('270,001 – 520,000', '8%'),
          _row('520,001 – 760,000', '20%'),
          _row('760,001 – 1,000,000', '25%'),
          _row(sw ? 'Zaidi ya 1,000,000' : 'Above 1,000,000', '30%'),
          const SizedBox(height: 8),
          Text(
            sw
                ? 'NSSF: Mwajiri 10% + Mfanyakazi 10% | SDL: 3.5% | WCF: 0.5%'
                : 'NSSF: Employer 10% + Employee 10% | SDL: 3.5% | WCF: 0.5%',
            style: TextStyle(
                fontSize: 10, color: _kSecondary.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }

  Widget _row(String range, String rate) {
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
```

- [ ] **Step 3: Verify analyze**

```bash
cd /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND && flutter analyze lib/payroll/widgets/ 2>&1 | head -20
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
cd /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND && git add lib/payroll/widgets/ && git commit -m "feat(payroll): add PayslipCard and TaxSummaryWidget"
```

---

## Task 4: PayslipPage

**Files:**
- Create: `lib/payroll/pages/payslip_page.dart`

- [ ] **Step 1: Create `lib/payroll/pages/payslip_page.dart`**

```dart
// lib/payroll/pages/payslip_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/payroll_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);
const Color _kCard = Color(0xFFFFFFFF);

class PayslipPage extends StatelessWidget {
  final PayrollEntry entry;
  final int month;
  final int year;
  final String businessName;

  const PayslipPage({
    super.key,
    required this.entry,
    required this.month,
    required this.year,
    this.businessName = '',
  });

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
    final monthName = sw ? _monthsSw[month - 1] : _monthsEn[month - 1];
    final text = '''
${businessName.isNotEmpty ? '$businessName\n' : ''}${sw ? 'STAKABADHI YA MSHAHARA' : 'PAYSLIP'} — $monthName $year
${sw ? 'Mfanyakazi' : 'Employee'}: ${entry.employeeName}

${sw ? 'Mshahara Ghafi' : 'Gross Salary'}:    TZS ${nf.format(entry.grossSalary)}
PAYE:                  TZS ${nf.format(entry.paye)}
NSSF (${sw ? 'Mfanyakazi' : 'Employee'} 10%): TZS ${nf.format(entry.nssfEmployee)}
─────────────────────────
${sw ? 'Mshahara Halisi' : 'Net Salary'}:     TZS ${nf.format(entry.netSalary)}

${sw ? 'Gharama za Mwajiri' : 'Employer Costs'}:
NSSF (${sw ? 'Mwajiri' : 'Employer'} 10%):  TZS ${nf.format(entry.nssfEmployer)}
SDL 3.5%:              TZS ${nf.format(entry.sdl)}
WCF 0.5%:              TZS ${nf.format(entry.wcf)}
${sw ? 'Jumla Gharama' : 'Total Employer Cost'}: TZS ${nf.format(entry.totalEmployerCost)}
''';
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    final sw = AppStringsScope.of(context)?.isSwahili ?? false;
    final nf = NumberFormat('#,###', 'en');
    final monthName = sw ? _monthsSw[month - 1] : _monthsEn[month - 1];

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: const BackButton(color: _kPrimary),
        title: Text(
          sw ? 'Stakabadhi ya Mshahara' : 'Payslip',
          style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w600),
        ),
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
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (businessName.isNotEmpty)
                    Text(businessName,
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
                  Text('$monthName $year',
                      style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        child: Text(
                          entry.employeeName.isNotEmpty
                              ? entry.employeeName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.employeeName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Earnings card
            _sectionCard(
              title: sw ? 'Mapato' : 'Earnings',
              children: [
                _row(sw ? 'Mshahara Msingi' : 'Basic Salary',
                    nf.format(entry.grossSalary)),
                const Divider(height: 12),
                _row(sw ? 'Jumla Mapato' : 'Total Earnings',
                    nf.format(entry.grossSalary),
                    isBold: true),
              ],
            ),

            const SizedBox(height: 10),

            // Deductions card
            _sectionCard(
              title: sw ? 'Makato' : 'Deductions',
              children: [
                _row('PAYE', nf.format(entry.paye),
                    valueColor: Colors.red.shade700),
                _row(sw ? 'NSSF (Mfanyakazi 10%)' : 'NSSF (Employee 10%)',
                    nf.format(entry.nssfEmployee),
                    valueColor: Colors.red.shade700),
                const Divider(height: 12),
                _row(sw ? 'Jumla Makato' : 'Total Deductions',
                    nf.format(entry.paye + entry.nssfEmployee),
                    isBold: true),
              ],
            ),

            const SizedBox(height: 16),

            // Net pay hero
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _kPrimary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    sw ? 'Mshahara Halisi' : 'Net Pay',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'TZS ${nf.format(entry.netSalary)}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
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
                  _row(sw ? 'NSSF (Mwajiri 10%)' : 'NSSF (Employer 10%)',
                      nf.format(entry.nssfEmployer)),
                  _row('SDL (3.5%)', nf.format(entry.sdl)),
                  _row('WCF (0.5%)', nf.format(entry.wcf)),
                  const Divider(height: 10),
                  _row(sw ? 'Jumla Gharama' : 'Total Employer Cost',
                      nf.format(entry.totalEmployerCost),
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
```

- [ ] **Step 2: Verify analyze**

```bash
cd /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND && flutter analyze lib/payroll/pages/payslip_page.dart 2>&1 | head -20
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
cd /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND && git add lib/payroll/pages/payslip_page.dart && git commit -m "feat(payroll): add PayslipPage with share support"
```

---

## Task 5: PayrollRunPage

**Files:**
- Create: `lib/payroll/pages/payroll_run_page.dart`

- [ ] **Step 1: Create `lib/payroll/pages/payroll_run_page.dart`**

```dart
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(sw ? 'Thibitisha Idhini' : 'Confirm Approval'),
        content: Text(sw
            ? 'Je, unataka kuidhinisha mishahara hii? Hatua hii haiwezi kurudishwa.'
            : 'Approve this payroll? This action cannot be undone.'),
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
                  _approve();
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
    Share.share(
      '${sw ? "Muhtasari wa Mishahara" : "Payroll Summary"} — $monthName ${widget.run.year}\n'
      '${sw ? "Wafanyakazi" : "Employees"}: ${widget.run.employees.length}\n'
      '${sw ? "Jumla Ghafi" : "Total Gross"}: TZS ${nf.format(widget.run.totalGross)}\n'
      '${sw ? "Jumla Halisi" : "Total Net"}: TZS ${nf.format(widget.run.totalNet)}\n'
      'PAYE: TZS ${nf.format(widget.run.totalPaye)}\n'
      'NSSF: TZS ${nf.format(widget.run.totalNssf)}\n'
      'SDL: TZS ${nf.format(widget.run.totalSdl)}\n'
      'WCF: TZS ${nf.format(widget.run.totalWcf)}',
    );
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

            // Per-employee breakdown
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
```

- [ ] **Step 2: Verify analyze**

```bash
cd /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND && flutter analyze lib/payroll/pages/payroll_run_page.dart 2>&1 | head -20
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
cd /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND && git add lib/payroll/pages/payroll_run_page.dart && git commit -m "feat(payroll): add PayrollRunPage with per-employee breakdown and approve flow"
```

---

## Task 6: PayrollHistoryPage

**Files:**
- Create: `lib/payroll/pages/payroll_history_page.dart`

- [ ] **Step 1: Create `lib/payroll/pages/payroll_history_page.dart`**

```dart
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
    setState(() => _loading = true);
    try {
      final res = await PayrollService.getHistory(widget.token, widget.businessId);
      if (mounted) {
        setState(() {
          _loading = false;
          if (res.success) _history = res.data;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
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
    final years = [now - 2, now - 1, now, now + 1];
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
            : Column(
                children: [
                  // Year filter chips
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
                              ],
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
```

- [ ] **Step 2: Verify analyze**

```bash
cd /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND && flutter analyze lib/payroll/pages/payroll_history_page.dart 2>&1 | head -20
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
cd /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND && git add lib/payroll/pages/payroll_history_page.dart && git commit -m "feat(payroll): add PayrollHistoryPage with year filter"
```

---

## Task 7: StatutoryPage

**Files:**
- Create: `lib/payroll/pages/statutory_page.dart`

- [ ] **Step 1: Create `lib/payroll/pages/statutory_page.dart`**

```dart
// lib/payroll/pages/statutory_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
        setState(() {
          _loading = false;
          if (res.success) {
            _all = res.data;
            _backendAvailable = true;
          } else {
            _backendAvailable = false;
            // Derive from payroll history locally
            _deriveFromHistory();
          }
        });
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_rounded,
                              size: 56, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            sw
                                ? 'Hakuna matoleo bado'
                                : 'No obligations recorded yet',
                            style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14),
                          ),
                        ],
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
    String link;
    String label;
    switch (type) {
      case 'PAYE':
      case 'SDL':
        link = 'https://efiling.tra.go.tz';
        label = sw ? 'TRA e-Filing' : 'TRA e-Filing';
        break;
      case 'NSSF':
        link = 'https://member.nssf.or.tz';
        label = sw ? 'Mwanachama wa NSSF' : 'NSSF Member Portal';
        break;
      default:
        link = 'https://efiling.tra.go.tz';
        label = sw ? 'TRA e-Filing' : 'TRA e-Filing';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: _kSecondary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              sw
                  ? 'Lipa $type kupitia $label'
                  : 'Remit $type via $label',
              style: const TextStyle(fontSize: 12, color: _kSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Verify analyze**

```bash
cd /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND && flutter analyze lib/payroll/pages/statutory_page.dart 2>&1 | head -20
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
cd /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND && git add lib/payroll/pages/statutory_page.dart && git commit -m "feat(payroll): add StatutoryPage with graceful backend degradation"
```

---

## Task 8: PayrollHomePage

**Files:**
- Create: `lib/payroll/pages/payroll_home_page.dart`

- [ ] **Step 1: Create `lib/payroll/pages/payroll_home_page.dart`**

```dart
// lib/payroll/pages/payroll_home_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../../team/models/team_models.dart' show Employee;
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

  const PayrollHomePage({super.key, required this.businessId});

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
      final results = await Future.wait([
        TeamService.getEmployees(_token!, widget.businessId),
        PayrollService.getHistory(_token!, widget.businessId),
      ]);

      final empRes = results[0] as dynamic;
      final histRes = results[1] as PayrollListResult<PayrollRun>;

      if (mounted) {
        setState(() {
          _loading = false;
          if (empRes.success == true) {
            _employees = (empRes.data as List<Employee>)
                .where((e) => e.isActive)
                .toList();
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
        setState(() => _calculating = false);
        if (res.success && res.data != null) {
          setState(() => _currentRun = res.data);
        } else {
          _calculateLocal();
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _calculating = false);
        _calculateLocal();
      }
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
                                          DateTime.now().year - 1 + i;
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
```

- [ ] **Step 2: Verify analyze**

```bash
cd /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND && flutter analyze lib/payroll/pages/payroll_home_page.dart 2>&1 | head -20
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
cd /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND && git add lib/payroll/pages/payroll_home_page.dart && git commit -m "feat(payroll): add PayrollHomePage hub (no AppBar, tab-embedded)"
```

---

## Task 9: Barrel Export + Navigation Wiring + Delete Old File

**Files:**
- Create: `lib/payroll/payroll.dart`
- Modify: `lib/screens/profile/profile_screen.dart`
- Delete: `lib/business/pages/payroll_page.dart`

- [ ] **Step 1: Create `lib/payroll/payroll.dart`**

```dart
// lib/payroll/payroll.dart
export 'models/payroll_models.dart';
export 'services/payroll_service.dart' show PayrollService, PayrollResult, PayrollListResult;
export 'pages/payroll_home_page.dart' show PayrollHomePage;
export 'pages/payroll_run_page.dart' show PayrollRunPage;
export 'pages/payslip_page.dart' show PayslipPage;
export 'pages/statutory_page.dart' show StatutoryPage;
export 'pages/payroll_history_page.dart' show PayrollHistoryPage;
export 'widgets/payslip_card.dart' show PayslipCard;
export 'widgets/tax_summary_widget.dart' show TaxSummaryWidget;
```

- [ ] **Step 2: Update `profile_screen.dart` biz_payroll case**

Find this block (around line 2214):
```dart
      case 'biz_payroll':
        return BizTabWrapper(userId: userId, builder: (uid, all, first, fId) =>
            fId != null ? PayrollPage(businessId: fId) : const SizedBox.shrink());
```

Replace with:
```dart
      case 'biz_payroll':
        return BizTabWrapper(userId: userId, builder: (uid, all, first, fId) =>
            fId != null ? PayrollHomePage(businessId: fId) : const SizedBox.shrink());
```

Also add the import at the top of `profile_screen.dart` where other module imports are (near the team/myjob imports):
```dart
import 'package:tajiri/payroll/payroll.dart' show PayrollHomePage;
```

And remove the old import for `PayrollPage` (search for `payroll_page` and delete that import line).

- [ ] **Step 3: Delete the old payroll_page.dart**

```bash
rm /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND/lib/business/pages/payroll_page.dart
```

- [ ] **Step 4: Verify full analyze**

```bash
cd /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND && flutter analyze lib/payroll/ lib/business/pages/ lib/screens/profile/profile_screen.dart 2>&1 | head -40
```

Expected: no errors.

- [ ] **Step 5: Commit**

```bash
cd /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND && git add lib/payroll/payroll.dart lib/screens/profile/profile_screen.dart && git rm lib/business/pages/payroll_page.dart && git commit -m "feat(payroll): wire PayrollHomePage to biz_payroll tab, remove old PayrollPage"
```

---

## Task 10: Final Full Analyze

- [ ] **Step 1: Run full project analyze**

```bash
cd /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND && flutter analyze 2>&1 | grep -v "^Analyzing" | head -50
```

Expected: no new errors (only pre-existing warnings if any).

- [ ] **Step 2: If there are import errors in `business_models.dart` re-export**

If `flutter analyze` shows `'PayrollStatus' is already defined` or similar duplicate symbol errors due to the re-export added in Task 1, the fix is to **remove the re-export block** from `business_models.dart`. The local definitions already satisfy all callers within `lib/business/`. Only external callers need the new `lib/payroll/payroll.dart` barrel.

- [ ] **Step 3: Commit final**

```bash
cd /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND && git add -A && git commit -m "feat(payroll): lib/payroll/ module complete"
```
