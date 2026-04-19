# Enhanced Team Module Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enhance the existing `lib/team/` module so owners register team members from platform users, configure PAYE/NSSF/NHIF toggles and named allowances, and view per-employee net-pay breakdowns.

**Architecture:** All changes stay in `lib/team/`. A new pure `CompensationService` handles deduction math. A two-step add flow (user picker → compensation sheet) replaces the old free-text sheet. `EmployeeDetailPage` shows the compensation breakdown.

**Tech Stack:** Flutter/Dart, `http` package, existing `TanzaniaPAYE` in `lib/business/models/business_models.dart`, `flutter_test` for unit tests.

---

### Task 1: Request backend endpoints via ask_backend.sh

**Files:**
- Run: `./scripts/ask_backend.sh`

- [ ] **Step 1: Run the backend request**

```bash
./scripts/ask_backend.sh "Please add/update the following Laravel API endpoints for the Team module:

1. GET /api/users/search?q={query}&limit=20
   Returns: { data: [ { id, name, username, profile_photo_url } ] }
   Searches platform users by name or username (case-insensitive LIKE).

2. GET /api/business/employees/{id}
   Returns: { data: { id, business_id, user_id, name, phone, nida_number, position, department, contract_type, gross_salary, apply_paye, apply_nssf, apply_nhif, allowances (JSON array [{name,amount}]), start_date, bank_account, bank_name, is_active } }

3. POST /api/business/employees — update to also accept:
   user_id (int, required), department (string), contract_type (string: permanent|contract|part_time),
   apply_paye (bool), apply_nssf (bool), apply_nhif (bool),
   allowances (JSON array of {name: string, amount: number})
   SIDE EFFECT: set the linked user's profile fields: employer (business name), job_title (position), employment_start_date (start_date), contract_type.

4. PUT /api/business/employees/{id} — same extra fields as POST.
   SIDE EFFECT: sync position → job_title and contract_type to the linked user profile.

5. DELETE /api/business/employees/{id}
   SIDE EFFECT: clear the linked user's employer, job_title, employment_start_date (set to null).

All endpoints require Bearer token auth."
```

- [ ] **Step 2: Verify routes exist on UAT**

```bash
ssh root@172.240.241.180 "cd /var/www/tajiri && php artisan route:list | grep -E 'users/search|business/employees'"
```

Expected: rows for `GET api/users/search`, `GET api/business/employees/{id}`, `POST api/business/employees`, `PUT api/business/employees/{id}`, `DELETE api/business/employees/{id}`.

---

### Task 2: Enhanced Team models

**Files:**
- Modify: `lib/team/models/team_models.dart`
- Create: `test/team/team_models_test.dart`

- [ ] **Step 1: Write failing tests**

```dart
// test/team/team_models_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tajiri/team/models/team_models.dart';

void main() {
  group('Allowance', () {
    test('fromJson parses name and amount', () {
      final a = Allowance.fromJson({'name': 'Transport', 'amount': 50000});
      expect(a.name, 'Transport');
      expect(a.amount, 50000.0);
    });
    test('toJson round-trips', () {
      const a = Allowance(name: 'Housing', amount: 100000);
      expect(Allowance.fromJson(a.toJson()).amount, 100000.0);
    });
  });

  group('PlatformUser', () {
    test('fromJson parses id, name, username, avatarUrl', () {
      final u = PlatformUser.fromJson(
          {'id': 7, 'name': 'Alice', 'username': 'alice99', 'profile_photo_url': 'https://x.com/a.jpg'});
      expect(u.id, 7);
      expect(u.username, 'alice99');
      expect(u.avatarUrl, 'https://x.com/a.jpg');
    });
    test('avatarUrl is nullable', () {
      final u = PlatformUser.fromJson({'id': 1, 'name': 'Bob', 'username': 'bob'});
      expect(u.avatarUrl, isNull);
    });
  });

  group('Employee (enhanced)', () {
    final json = {
      'id': 5, 'business_id': 2, 'user_id': 10,
      'name': 'Jane', 'phone': '0712345678', 'position': 'Engineer',
      'department': 'Tech', 'contract_type': 'permanent',
      'gross_salary': 800000, 'apply_paye': true, 'apply_nssf': true, 'apply_nhif': false,
      'allowances': [{'name': 'Transport', 'amount': 30000}],
      'start_date': '2024-01-01', 'bank_account': '123', 'bank_name': 'NBC', 'is_active': true,
    };
    test('fromJson parses all new fields', () {
      final e = Employee.fromJson(json);
      expect(e.userId, 10);
      expect(e.department, 'Tech');
      expect(e.contractType, 'permanent');
      expect(e.applyPAYE, true);
      expect(e.applyNHIF, false);
      expect(e.allowances.length, 1);
      expect(e.allowances.first.name, 'Transport');
    });
    test('toJson includes all new fields', () {
      final j = Employee.fromJson(json).toJson();
      expect(j['user_id'], 10);
      expect(j['department'], 'Tech');
      expect((j['allowances'] as List).length, 1);
    });
  });
}
```

- [ ] **Step 2: Run tests — expect failure**

```bash
flutter test test/team/team_models_test.dart
```

Expected: compilation errors (Allowance, PlatformUser not defined yet).

- [ ] **Step 3: Replace `lib/team/models/team_models.dart` with enhanced version**

```dart
// lib/team/models/team_models.dart
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

class Allowance {
  final String name;
  final double amount;

  const Allowance({required this.name, required this.amount});

  factory Allowance.fromJson(Map<String, dynamic> json) => Allowance(
        name: json['name']?.toString() ?? '',
        amount: _parseDouble(json['amount']),
      );

  Map<String, dynamic> toJson() => {'name': name, 'amount': amount};
}

class PlatformUser {
  final int id;
  final String name;
  final String username;
  final String? avatarUrl;

  const PlatformUser({
    required this.id,
    required this.name,
    required this.username,
    this.avatarUrl,
  });

  factory PlatformUser.fromJson(Map<String, dynamic> json) => PlatformUser(
        id: _parseInt(json['id']) ?? 0,
        name: json['name']?.toString() ?? '',
        username: json['username']?.toString() ?? '',
        avatarUrl: json['profile_photo_url']?.toString(),
      );
}

class Employee {
  final int? id;
  final int? businessId;
  final int? userId;
  final String name;
  final String? phone;
  final String? nidaNumber;
  final String? position;
  final String? department;
  final String? contractType; // permanent | contract | part_time
  final double grossSalary;
  final bool applyPAYE;
  final bool applyNSSF;
  final bool applyNHIF;
  final List<Allowance> allowances;
  final DateTime? startDate;
  final String? bankAccount;
  final String? bankName;
  final bool isActive;

  const Employee({
    this.id,
    this.businessId,
    this.userId,
    required this.name,
    this.phone,
    this.nidaNumber,
    this.position,
    this.department,
    this.contractType,
    this.grossSalary = 0,
    this.applyPAYE = true,
    this.applyNSSF = true,
    this.applyNHIF = true,
    this.allowances = const [],
    this.startDate,
    this.bankAccount,
    this.bankName,
    this.isActive = true,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    final rawAllowances = json['allowances'];
    final allowances = rawAllowances is List
        ? rawAllowances
            .whereType<Map<String, dynamic>>()
            .map(Allowance.fromJson)
            .toList()
        : <Allowance>[];
    return Employee(
      id: _parseInt(json['id']),
      businessId: _parseInt(json['business_id']),
      userId: _parseInt(json['user_id']),
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString(),
      nidaNumber: json['nida_number']?.toString(),
      position: json['position']?.toString(),
      department: json['department']?.toString(),
      contractType: json['contract_type']?.toString(),
      grossSalary: _parseDouble(json['gross_salary']),
      applyPAYE: _parseBool(json['apply_paye'], true),
      applyNSSF: _parseBool(json['apply_nssf'], true),
      applyNHIF: _parseBool(json['apply_nhif'], true),
      allowances: allowances,
      startDate: _parseDate(json['start_date']),
      bankAccount: json['bank_account']?.toString(),
      bankName: json['bank_name']?.toString(),
      isActive: _parseBool(json['is_active'], true),
    );
  }

  Map<String, dynamic> toJson() => {
        'business_id': businessId,
        'user_id': userId,
        'name': name,
        'phone': phone,
        'nida_number': nidaNumber,
        'position': position,
        'department': department,
        'contract_type': contractType,
        'gross_salary': grossSalary,
        'apply_paye': applyPAYE,
        'apply_nssf': applyNSSF,
        'apply_nhif': applyNHIF,
        'allowances': allowances.map((a) => a.toJson()).toList(),
        'start_date': startDate?.toIso8601String(),
        'bank_account': bankAccount,
        'bank_name': bankName,
        'is_active': isActive,
      };
}
```

- [ ] **Step 4: Run tests — expect pass**

```bash
flutter test test/team/team_models_test.dart
```

Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/team/models/team_models.dart test/team/team_models_test.dart
git commit -m "feat(team): enhance Employee model — userId, department, contractType, deduction toggles, allowances"
```

---

### Task 3: CompensationService with unit tests

**Files:**
- Create: `lib/team/services/compensation_service.dart`
- Create: `test/team/compensation_service_test.dart`

- [ ] **Step 1: Write failing tests**

```dart
// test/team/compensation_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tajiri/team/models/team_models.dart';
import 'package:tajiri/team/services/compensation_service.dart';

void main() {
  group('CompensationService.computeNSSF', () {
    test('10% of gross up to 20000 cap', () {
      expect(CompensationService.computeNSSF(100000), 10000.0);
      expect(CompensationService.computeNSSF(300000), 20000.0); // capped
      expect(CompensationService.computeNSSF(50000), 5000.0);
    });
  });

  group('CompensationService.computeNHIF', () {
    test('tiered by gross salary', () {
      expect(CompensationService.computeNHIF(50000), 0.0);
      expect(CompensationService.computeNHIF(150000), 5000.0);
      expect(CompensationService.computeNHIF(250000), 7500.0);
      expect(CompensationService.computeNHIF(350000), 10000.0);
      expect(CompensationService.computeNHIF(450000), 12500.0);
      expect(CompensationService.computeNHIF(750000), 15000.0);
      expect(CompensationService.computeNHIF(1500000), 20000.0);
    });
  });

  group('CompensationService.computePAYE', () {
    test('zero below threshold', () {
      expect(CompensationService.computePAYE(270000), 0.0);
    });
    test('positive above threshold', () {
      expect(CompensationService.computePAYE(400000), greaterThan(0));
    });
  });

  group('CompensationService.computeNetPay', () {
    test('all deductions off: net = gross + allowances', () {
      final net = CompensationService.computeNetPay(
        grossSalary: 300000,
        allowances: [const Allowance(name: 'Transport', amount: 50000)],
        applyPAYE: false,
        applyNSSF: false,
        applyNHIF: false,
      );
      expect(net, 350000.0);
    });

    test('all deductions on: net = gross - PAYE - NSSF - NHIF', () {
      const gross = 500000.0;
      final expected = gross
          - CompensationService.computePAYE(gross)
          - CompensationService.computeNSSF(gross)
          - CompensationService.computeNHIF(gross);
      final net = CompensationService.computeNetPay(
        grossSalary: gross,
        allowances: const [],
        applyPAYE: true,
        applyNSSF: true,
        applyNHIF: true,
      );
      expect(net, closeTo(expected, 0.01));
    });
  });
}
```

- [ ] **Step 2: Run tests — expect failure**

```bash
flutter test test/team/compensation_service_test.dart
```

Expected: compilation error — `CompensationService` not defined.

- [ ] **Step 3: Create `lib/team/services/compensation_service.dart`**

```dart
// lib/team/services/compensation_service.dart
import '../../business/models/business_models.dart' show TanzaniaPAYE;
import '../models/team_models.dart' show Allowance;

class CompensationService {
  CompensationService._();

  static double computeNSSF(double gross) =>
      (gross * 0.10).clamp(0.0, 20000.0);

  static double computeNHIF(double gross) {
    if (gross <= 100000) return 0;
    if (gross <= 200000) return 5000;
    if (gross <= 300000) return 7500;
    if (gross <= 400000) return 10000;
    if (gross <= 500000) return 12500;
    if (gross <= 1000000) return 15000;
    return 20000;
  }

  static double computePAYE(double gross) =>
      TanzaniaPAYE.calculateMonthlyPAYE(gross);

  static double computeNetPay({
    required double grossSalary,
    required List<Allowance> allowances,
    required bool applyPAYE,
    required bool applyNSSF,
    required bool applyNHIF,
  }) {
    final totalAllowances = allowances.fold(0.0, (s, a) => s + a.amount);
    final paye = applyPAYE ? computePAYE(grossSalary) : 0.0;
    final nssf = applyNSSF ? computeNSSF(grossSalary) : 0.0;
    final nhif = applyNHIF ? computeNHIF(grossSalary) : 0.0;
    return grossSalary + totalAllowances - paye - nssf - nhif;
  }
}
```

- [ ] **Step 4: Run tests — expect pass**

```bash
flutter test test/team/compensation_service_test.dart
```

Expected: All 7 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/team/services/compensation_service.dart test/team/compensation_service_test.dart
git commit -m "feat(team): add CompensationService — PAYE/NSSF/NHIF computation with unit tests"
```

---

### Task 4: TeamService additions

**Files:**
- Modify: `lib/team/services/team_service.dart`

- [ ] **Step 1: Add `searchPlatformUsers` and `getEmployee` methods**

Add these two methods to `TeamService` in `lib/team/services/team_service.dart` before `getExpiringEmployeeContracts`:

```dart
  static Future<TeamListResult<PlatformUser>> searchPlatformUsers(
      String token, String query) async {
    try {
      final encoded = Uri.encodeQueryComponent(query);
      final url = '$_baseUrl/users/search?q=$encoded&limit=20';
      _log('GET $url');
      final res =
          await http.get(Uri.parse(url), headers: ApiConfig.authHeaders(token));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['data'] as List? ?? [])
            .map((e) => PlatformUser.fromJson(e as Map<String, dynamic>))
            .toList();
        return TeamListResult(success: true, data: list);
      }
      return TeamListResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      return TeamListResult(success: false, message: e.toString());
    }
  }

  static Future<TeamResult<Employee>> getEmployee(
      String token, int employeeId) async {
    try {
      final url = '$_baseUrl/business/employees/$employeeId';
      _log('GET $url');
      final res =
          await http.get(Uri.parse(url), headers: ApiConfig.authHeaders(token));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return TeamResult(
            success: true,
            data: Employee.fromJson(data['data'] ?? data));
      }
      return TeamResult(success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      return TeamResult(success: false, message: e.toString());
    }
  }
```

- [ ] **Step 2: Verify the file compiles**

```bash
flutter analyze lib/team/services/team_service.dart
```

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/team/services/team_service.dart
git commit -m "feat(team): add searchPlatformUsers and getEmployee to TeamService"
```

---

### Task 5: UserSearchSheet widget

**Files:**
- Create: `lib/team/widgets/user_search_sheet.dart`

- [ ] **Step 1: Create the widget**

```dart
// lib/team/widgets/user_search_sheet.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/team_models.dart';
import '../services/team_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class UserSearchSheet extends StatefulWidget {
  final String token;
  final void Function(PlatformUser user) onSelected;

  const UserSearchSheet({
    super.key,
    required this.token,
    required this.onSelected,
  });

  @override
  State<UserSearchSheet> createState() => _UserSearchSheetState();
}

class _UserSearchSheetState extends State<UserSearchSheet> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  List<PlatformUser> _results = [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() { _results = []; _loading = false; _error = null; });
      return;
    }
    setState(() { _loading = true; _error = null; });
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(q.trim()));
  }

  Future<void> _search(String q) async {
    final res = await TeamService.searchPlatformUsers(widget.token, q);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.success) {
        _results = res.data;
        _error = null;
      } else {
        _error = res.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            sw ? 'Chagua Mfanyakazi' : 'Select Team Member',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kPrimary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            autofocus: true,
            onChanged: _onChanged,
            decoration: InputDecoration(
              hintText: sw ? 'Tafuta jina au username...' : 'Search by name or username...',
              prefixIcon: const Icon(Icons.search_rounded, color: _kSecondary),
              filled: true,
              fillColor: _kBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 8),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2)),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _results.length,
                itemBuilder: (_, i) {
                  final u = _results[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: u.avatarUrl != null
                          ? NetworkImage(u.avatarUrl!)
                          : null,
                      child: u.avatarUrl == null
                          ? Text(u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                              style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.bold))
                          : null,
                    ),
                    title: Text(u.name,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: _kPrimary)),
                    subtitle: Text('@${u.username}',
                        style: const TextStyle(fontSize: 12, color: _kSecondary)),
                    onTap: () {
                      Navigator.of(context).pop();
                      widget.onSelected(u);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/team/widgets/user_search_sheet.dart
```

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/team/widgets/user_search_sheet.dart
git commit -m "feat(team): add UserSearchSheet — debounced platform user picker"
```

---

### Task 6: CompensationSheet widget

**Files:**
- Create: `lib/team/widgets/compensation_sheet.dart`

- [ ] **Step 1: Create the widget**

```dart
// lib/team/widgets/compensation_sheet.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/team_models.dart';
import '../services/compensation_service.dart';
import '../services/team_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

/// Add (employee==null, user required) or edit (employee!=null) sheet.
class CompensationSheet extends StatefulWidget {
  final String token;
  final int businessId;
  final PlatformUser? user;   // null when editing existing employee
  final Employee? employee;   // null when adding new
  final VoidCallback onSaved;

  const CompensationSheet({
    super.key,
    required this.token,
    required this.businessId,
    this.user,
    this.employee,
    required this.onSaved,
  });

  @override
  State<CompensationSheet> createState() => _CompensationSheetState();
}

class _CompensationSheetState extends State<CompensationSheet> {
  late final TextEditingController _posCtrl;
  late final TextEditingController _deptCtrl;
  late final TextEditingController _salaryCtrl;
  late final TextEditingController _bankNameCtrl;
  late final TextEditingController _bankAccCtrl;
  late final TextEditingController _nidaCtrl;

  late String _contractType;
  late bool _applyPAYE;
  late bool _applyNSSF;
  late bool _applyNHIF;
  late bool _isActive;
  late List<Allowance> _allowances;
  DateTime? _startDate;
  bool _saving = false;

  static const _contractTypes = ['permanent', 'contract', 'part_time'];

  @override
  void initState() {
    super.initState();
    final e = widget.employee;
    _posCtrl = TextEditingController(text: e?.position ?? '');
    _deptCtrl = TextEditingController(text: e?.department ?? '');
    _salaryCtrl = TextEditingController(
        text: e != null ? e.grossSalary.toStringAsFixed(0) : '');
    _bankNameCtrl = TextEditingController(text: e?.bankName ?? '');
    _bankAccCtrl = TextEditingController(text: e?.bankAccount ?? '');
    _nidaCtrl = TextEditingController(text: e?.nidaNumber ?? '');
    _contractType = e?.contractType ?? 'permanent';
    _applyPAYE = e?.applyPAYE ?? true;
    _applyNSSF = e?.applyNSSF ?? true;
    _applyNHIF = e?.applyNHIF ?? true;
    _isActive = e?.isActive ?? true;
    _allowances = List.from(e?.allowances ?? []);
    _startDate = e?.startDate;
  }

  @override
  void dispose() {
    for (final c in [_posCtrl, _deptCtrl, _salaryCtrl, _bankNameCtrl, _bankAccCtrl, _nidaCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  String _contractLabel(String type, bool sw) {
    switch (type) {
      case 'permanent': return sw ? 'Kudumu' : 'Permanent';
      case 'contract': return sw ? 'Mkataba' : 'Contract';
      case 'part_time': return sw ? 'Sehemu ya Wakati' : 'Part-time';
      default: return type;
    }
  }

  Future<void> _pickDate(bool sw) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) setState(() => _startDate = picked);
  }

  Future<void> _addAllowanceDialog(bool sw) async {
    final nameCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(sw ? 'Ongeza Posho' : 'Add Allowance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(hintText: sw ? 'Jina (k.m. Usafiri)' : 'Name (e.g. Transport)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: amtCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(hintText: sw ? 'Kiasi (TZS)' : 'Amount (TZS)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(sw ? 'Ghairi' : 'Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white),
            child: Text(sw ? 'Ongeza' : 'Add'),
          ),
        ],
      ),
    );
    if (added == true && nameCtrl.text.trim().isNotEmpty) {
      setState(() {
        _allowances.add(Allowance(
          name: nameCtrl.text.trim(),
          amount: double.tryParse(amtCtrl.text.replaceAll(',', '')) ?? 0,
        ));
      });
    }
    nameCtrl.dispose();
    amtCtrl.dispose();
  }

  Future<void> _save(bool sw) async {
    final gross = double.tryParse(_salaryCtrl.text.replaceAll(',', '')) ?? 0;
    if (_posCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(sw ? 'Tafadhali weka nafasi' : 'Please enter a position')));
      return;
    }
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final body = <String, dynamic>{
      'business_id': widget.businessId,
      if (widget.user != null) 'user_id': widget.user!.id,
      if (widget.user != null) 'name': widget.user!.name,
      'position': _posCtrl.text.trim(),
      'department': _deptCtrl.text.trim(),
      'contract_type': _contractType,
      'gross_salary': gross,
      'apply_paye': _applyPAYE,
      'apply_nssf': _applyNSSF,
      'apply_nhif': _applyNHIF,
      'allowances': _allowances.map((a) => a.toJson()).toList(),
      'start_date': _startDate?.toIso8601String(),
      'bank_name': _bankNameCtrl.text.trim(),
      'bank_account': _bankAccCtrl.text.trim(),
      'nida_number': _nidaCtrl.text.trim(),
      'is_active': _isActive,
    };
    try {
      final bool success;
      String? msg;
      if (widget.employee == null) {
        final res = await TeamService.addEmployee(widget.token, body);
        success = res.success;
        msg = res.message;
      } else {
        final res = await TeamService.updateEmployee(widget.token, widget.employee!.id!, body);
        success = res.success;
        msg = res.message;
      }
      if (!mounted) return;
      nav.pop();
      messenger.showSnackBar(SnackBar(
          content: Text(success
              ? (sw ? 'Imehifadhiwa' : 'Saved')
              : (msg ?? (sw ? 'Imeshindikana' : 'Failed')))));
      if (success) widget.onSaved();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        messenger.showSnackBar(SnackBar(
            content: Text(sw ? 'Imeshindikana' : 'An error occurred')));
      }
    }
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: _kSecondary),
        filled: true,
        fillColor: _kBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: _kPrimary)),
        Switch(value: value, activeThumbColor: _kPrimary, onChanged: onChanged),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final sw = AppStringsScope.of(context)?.isSwahili ?? false;
    final displayName = widget.user?.name ?? widget.employee?.name ?? '';
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(
              widget.employee == null
                  ? (sw ? 'Ongeza Mwanatimu' : 'Add Team Member')
                  : (sw ? 'Hariri Mwanatimu' : 'Edit Team Member'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kPrimary),
            ),
            if (displayName.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(displayName,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _kSecondary)),
            ],
            const SizedBox(height: 16),
            _field(_posCtrl, sw ? 'Nafasi / Cheo' : 'Position / Role', Icons.work_rounded),
            const SizedBox(height: 10),
            _field(_deptCtrl, sw ? 'Idara' : 'Department', Icons.business_rounded),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _contractType,
              decoration: InputDecoration(
                labelText: sw ? 'Aina ya Mkataba' : 'Contract Type',
                prefixIcon: const Icon(Icons.description_rounded, size: 20, color: _kSecondary),
                filled: true,
                fillColor: _kBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              items: _contractTypes.map((t) => DropdownMenuItem(
                value: t,
                child: Text(_contractLabel(t, sw)),
              )).toList(),
              onChanged: (v) => setState(() => _contractType = v ?? 'permanent'),
            ),
            const SizedBox(height: 10),
            _field(_salaryCtrl, sw ? 'Mshahara Jumla (TZS/mwezi)' : 'Gross Salary (TZS/month)',
                Icons.payments_rounded, keyboardType: TextInputType.number),
            const SizedBox(height: 14),
            Text(sw ? 'Makato' : 'Deductions',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kSecondary)),
            _toggle('PAYE', _applyPAYE, (v) => setState(() => _applyPAYE = v)),
            _toggle('NSSF', _applyNSSF, (v) => setState(() => _applyNSSF = v)),
            _toggle('NHIF', _applyNHIF, (v) => setState(() => _applyNHIF = v)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(sw ? 'Posho' : 'Allowances',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kSecondary)),
                TextButton.icon(
                  onPressed: () => _addAllowanceDialog(sw),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text(sw ? 'Ongeza' : 'Add'),
                  style: TextButton.styleFrom(foregroundColor: _kPrimary),
                ),
              ],
            ),
            if (_allowances.isNotEmpty)
              Wrap(
                spacing: 8, runSpacing: 4,
                children: _allowances.asMap().entries.map((entry) {
                  final i = entry.key;
                  final a = entry.value;
                  return Chip(
                    label: Text('${a.name}: ${a.amount.toStringAsFixed(0)}'),
                    deleteIcon: const Icon(Icons.close_rounded, size: 14),
                    onDeleted: () => setState(() => _allowances.removeAt(i)),
                    backgroundColor: _kBackground,
                    side: BorderSide(color: Colors.grey.shade300),
                  );
                }).toList(),
              ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _pickDate(sw),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: sw ? 'Tarehe ya Kuanza' : 'Start Date',
                  prefixIcon: const Icon(Icons.calendar_today_rounded, size: 20, color: _kSecondary),
                  filled: true,
                  fillColor: _kBackground,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                child: Text(
                  _startDate != null
                      ? '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}'
                      : (sw ? 'Chagua tarehe' : 'Select date'),
                  style: TextStyle(
                      color: _startDate != null ? _kPrimary : Colors.grey.shade500, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _field(_nidaCtrl, sw ? 'Namba ya NIDA' : 'NIDA Number', Icons.badge_rounded),
            const SizedBox(height: 10),
            _field(_bankNameCtrl, sw ? 'Jina la Benki' : 'Bank Name', Icons.account_balance_rounded),
            const SizedBox(height: 10),
            _field(_bankAccCtrl, sw ? 'Namba ya Akaunti' : 'Account Number', Icons.credit_card_rounded),
            const SizedBox(height: 12),
            _toggle(sw ? 'Mfanyakazi Hai' : 'Active Employee', _isActive,
                (v) => setState(() => _isActive = v)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : () => _save(sw),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(sw ? 'Hifadhi' : 'Save',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/team/widgets/compensation_sheet.dart
```

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/team/widgets/compensation_sheet.dart
git commit -m "feat(team): add CompensationSheet — add/edit employee with deduction toggles and allowances"
```

---

### Task 7: EmployeeDetailPage

**Files:**
- Create: `lib/team/pages/employee_detail_page.dart`

- [ ] **Step 1: Create the page**

```dart
// lib/team/pages/employee_detail_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/team_models.dart';
import '../services/compensation_service.dart';
import '../services/team_service.dart';
import '../widgets/compensation_sheet.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class EmployeeDetailPage extends StatefulWidget {
  final int employeeId;
  final String token;
  final int businessId;
  final VoidCallback? onChanged;

  const EmployeeDetailPage({
    super.key,
    required this.employeeId,
    required this.token,
    required this.businessId,
    this.onChanged,
  });

  @override
  State<EmployeeDetailPage> createState() => _EmployeeDetailPageState();
}

class _EmployeeDetailPageState extends State<EmployeeDetailPage> {
  Employee? _employee;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    final res = await TeamService.getEmployee(widget.token, widget.employeeId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.success) {
        _employee = res.data;
      } else {
        _error = res.message;
      }
    });
  }

  void _openEdit(bool sw) {
    if (_employee == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => CompensationSheet(
        token: widget.token,
        businessId: widget.businessId,
        employee: _employee,
        onSaved: () {
          _load();
          widget.onChanged?.call();
        },
      ),
    );
  }

  Future<void> _confirmRemove(bool sw) async {
    final emp = _employee;
    if (emp == null || emp.id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(sw ? 'Ondoa Mwanatimu' : 'Remove Team Member',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(sw
            ? 'Ondoa ${emp.name} kutoka kwenye biashara?'
            : 'Remove ${emp.name} from the business?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(sw ? 'Ghairi' : 'Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(sw ? 'Ondoa' : 'Remove'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final res = await TeamService.removeEmployee(widget.token, emp.id!);
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(
        content: Text(res.success
            ? (sw ? 'Ameondolewa' : 'Removed')
            : (res.message ?? (sw ? 'Imeshindikana' : 'Failed')))));
    if (res.success) {
      widget.onChanged?.call();
      nav.pop();
    }
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _kSecondary),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(fontSize: 13, color: _kSecondary)),
          const Spacer(),
          Text(value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
        ],
      ),
    );
  }

  Widget _deductionRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: _kSecondary)),
          Text('- ${amount.toStringAsFixed(0)} TZS',
              style: const TextStyle(fontSize: 13, color: _kPrimary)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sw = AppStringsScope.of(context)?.isSwahili ?? false;
    final emp = _employee;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        leading: const BackButton(color: _kPrimary),
        title: Text(emp?.name ?? (sw ? 'Mwanatimu' : 'Team Member'),
            style: const TextStyle(color: _kPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          if (emp != null) ...[
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: _kPrimary),
              onPressed: () => _openEdit(sw),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              onPressed: () => _confirmRemove(sw),
            ),
          ],
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline_rounded, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(_error!, style: TextStyle(color: Colors.grey.shade500)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                          onPressed: _load,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: _kPrimary, foregroundColor: Colors.white),
                          child: Text(sw ? 'Jaribu Tena' : 'Retry')),
                    ],
                  ),
                )
              : emp == null
                  ? const SizedBox.shrink()
                  : RefreshIndicator(
                      color: _kPrimary,
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Avatar + name card
                          Card(
                            color: _kCardBg,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 32,
                                    backgroundColor: Colors.grey.shade200,
                                    child: Text(
                                      emp.name.isNotEmpty ? emp.name[0].toUpperCase() : '?',
                                      style: const TextStyle(
                                          fontSize: 26, fontWeight: FontWeight.bold, color: _kPrimary),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(emp.name,
                                      style: const TextStyle(
                                          fontSize: 18, fontWeight: FontWeight.bold, color: _kPrimary)),
                                  if (emp.position != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(emp.position!,
                                          style: const TextStyle(fontSize: 14, color: _kSecondary)),
                                    ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8, runSpacing: 4,
                                    alignment: WrapAlignment.center,
                                    children: [
                                      if (emp.department != null)
                                        _chip(emp.department!),
                                      if (emp.contractType != null)
                                        _chip(_contractLabel(emp.contractType!, sw)),
                                      _chip(
                                        emp.isActive
                                            ? (sw ? 'Hai' : 'Active')
                                            : (sw ? 'Hayupo' : 'Inactive'),
                                        color: emp.isActive
                                            ? Colors.green.shade50
                                            : Colors.grey.shade100,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Info card
                          Card(
                            color: _kCardBg,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(sw ? 'Maelezo' : 'Details',
                                      style: const TextStyle(
                                          fontSize: 13, fontWeight: FontWeight.w600, color: _kSecondary)),
                                  const SizedBox(height: 8),
                                  if (emp.phone != null)
                                    _infoRow(Icons.phone_rounded, sw ? 'Simu' : 'Phone', emp.phone!),
                                  if (emp.bankName != null)
                                    _infoRow(Icons.account_balance_rounded, sw ? 'Benki' : 'Bank', emp.bankName!),
                                  if (emp.bankAccount != null)
                                    _infoRow(Icons.credit_card_rounded, sw ? 'Akaunti' : 'Account', emp.bankAccount!),
                                  if (emp.startDate != null)
                                    _infoRow(Icons.calendar_today_rounded, sw ? 'Ilianza' : 'Start',
                                        '${emp.startDate!.year}-${emp.startDate!.month.toString().padLeft(2, '0')}-${emp.startDate!.day.toString().padLeft(2, '0')}'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Compensation card
                          Card(
                            color: _kCardBg,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(sw ? 'Malipo' : 'Compensation',
                                      style: const TextStyle(
                                          fontSize: 13, fontWeight: FontWeight.w600, color: _kSecondary)),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(sw ? 'Mshahara Jumla' : 'Gross Salary',
                                          style: const TextStyle(fontSize: 13, color: _kPrimary)),
                                      Text('${emp.grossSalary.toStringAsFixed(0)} TZS',
                                          style: const TextStyle(
                                              fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
                                    ],
                                  ),
                                  if (emp.applyPAYE) ...[
                                    const SizedBox(height: 4),
                                    _deductionRow('PAYE', CompensationService.computePAYE(emp.grossSalary)),
                                  ],
                                  if (emp.applyNSSF) ...[
                                    const SizedBox(height: 4),
                                    _deductionRow('NSSF', CompensationService.computeNSSF(emp.grossSalary)),
                                  ],
                                  if (emp.applyNHIF) ...[
                                    const SizedBox(height: 4),
                                    _deductionRow('NHIF', CompensationService.computeNHIF(emp.grossSalary)),
                                  ],
                                  for (final a in emp.allowances) ...[
                                    const SizedBox(height: 4),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('+ ${a.name}',
                                              style: const TextStyle(fontSize: 13, color: _kSecondary)),
                                          Text('${a.amount.toStringAsFixed(0)} TZS',
                                              style: const TextStyle(fontSize: 13, color: _kPrimary)),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const Divider(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(sw ? 'Mshahara Halisi' : 'Net Pay',
                                          style: const TextStyle(
                                              fontSize: 15, fontWeight: FontWeight.bold, color: _kPrimary)),
                                      Text(
                                        '${CompensationService.computeNetPay(
                                          grossSalary: emp.grossSalary,
                                          allowances: emp.allowances,
                                          applyPAYE: emp.applyPAYE,
                                          applyNSSF: emp.applyNSSF,
                                          applyNHIF: emp.applyNHIF,
                                        ).toStringAsFixed(0)} TZS',
                                        style: const TextStyle(
                                            fontSize: 15, fontWeight: FontWeight.bold, color: _kPrimary),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  String _contractLabel(String type, bool sw) {
    switch (type) {
      case 'permanent': return sw ? 'Kudumu' : 'Permanent';
      case 'contract': return sw ? 'Mkataba' : 'Contract';
      case 'part_time': return sw ? 'Sehemu ya Wakati' : 'Part-time';
      default: return type;
    }
  }

  Widget _chip(String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color ?? Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, color: _kPrimary)),
    );
  }
}
```

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/team/pages/employee_detail_page.dart
```

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/team/pages/employee_detail_page.dart
git commit -m "feat(team): add EmployeeDetailPage — compensation breakdown with net pay"
```

---

### Task 8: Update EmployeesPage — wire new add flow and detail navigation

**Files:**
- Modify: `lib/team/pages/employees_page.dart`

Replace `_showAddEditSheet` and the `EmployeeCard` `onTap`/`onEditTap` handlers. The new flow:
- FAB → `UserSearchSheet` → on user selected → `CompensationSheet` (add mode)
- `onEditTap` on existing card → `CompensationSheet` (edit mode)
- `onTap` on card → push `EmployeeDetailPage`

- [ ] **Step 1: Update imports at top of `lib/team/pages/employees_page.dart`**

Add these imports after the existing ones:

```dart
import '../widgets/compensation_sheet.dart';
import '../widgets/user_search_sheet.dart';
import 'employee_detail_page.dart';
```

- [ ] **Step 2: Replace `_showAddEditSheet` with three new methods**

Remove the entire `_showAddEditSheet` method and replace with:

```dart
  void _showUserSearch() {
    if (_token == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFFFFF),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => UserSearchSheet(
        token: _token!,
        onSelected: (user) => _showAddSheet(user),
      ),
    );
  }

  void _showAddSheet(PlatformUser user) {
    if (_token == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFFFFF),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => CompensationSheet(
        token: _token!,
        businessId: widget.businessId,
        user: user,
        onSaved: _load,
      ),
    );
  }

  void _showEditSheet(Employee employee) {
    if (_token == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFFFFF),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => CompensationSheet(
        token: _token!,
        businessId: widget.businessId,
        employee: employee,
        onSaved: _load,
      ),
    );
  }

  void _openDetail(Employee emp) {
    if (_token == null || emp.id == null) return;
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => EmployeeDetailPage(
        employeeId: emp.id!,
        token: _token!,
        businessId: widget.businessId,
        onChanged: _load,
      ),
    ));
  }
```

- [ ] **Step 3: Update the FAB `onPressed` and the `EmployeeCard` callbacks**

In `build`, change:
- `onPressed: () => _showAddEditSheet()` → `onPressed: _showUserSearch`
- `onTap: () => _showAddEditSheet(employee: emp)` → `onTap: () => _openDetail(emp)`
- `onEditTap: () => _showAddEditSheet(employee: emp)` → `onEditTap: () => _showEditSheet(emp)`

- [ ] **Step 4: Analyze**

```bash
flutter analyze lib/team/pages/employees_page.dart
```

Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add lib/team/pages/employees_page.dart
git commit -m "feat(team): wire user-pick → compensation add flow and detail navigation in EmployeesPage"
```

---

### Task 9: Update team.dart barrel

**Files:**
- Modify: `lib/team/team.dart`

- [ ] **Step 1: Update barrel**

```dart
// lib/team/team.dart
export 'models/team_models.dart';
export 'pages/employee_detail_page.dart' show EmployeeDetailPage;
export 'pages/employees_page.dart' show EmployeesPage;
export 'services/compensation_service.dart' show CompensationService;
export 'services/team_service.dart' show TeamService;
```

- [ ] **Step 2: Run full analysis**

```bash
flutter analyze lib/team/
```

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/team/team.dart
git commit -m "feat(team): update barrel exports — EmployeeDetailPage, CompensationService"
```

---
