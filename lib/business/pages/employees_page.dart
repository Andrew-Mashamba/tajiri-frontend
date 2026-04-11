// lib/business/pages/employees_page.dart
// Employee management — add, edit, remove.
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/business_models.dart';
import '../services/business_service.dart';
import '../widgets/employee_card.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class EmployeesPage extends StatefulWidget {
  final int businessId;
  const EmployeesPage({super.key, required this.businessId});

  @override
  State<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<EmployeesPage> {
  String? _token;
  bool _loading = true;
  String? _error;
  List<Employee> _employees = [];
  List<Employee> _filtered = [];
  final _searchCtrl = TextEditingController();

  bool get _isSwahili {
    final s = AppStringsScope.of(context);
    return s?.isSwahili ?? false;
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final storage = await LocalStorageService.getInstance();
    _token = storage.getAuthToken();
    await _load();
  }

  Future<void> _load() async {
    if (_token == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res =
          await BusinessService.getEmployees(_token!, widget.businessId);
      if (mounted) {
        setState(() {
          _loading = false;
          if (res.success) {
            _employees = res.data;
            _applyFilter();
          } else {
            _error = res.message;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) {
      _filtered = List.from(_employees);
    } else {
      _filtered = _employees
          .where((e) =>
              e.name.toLowerCase().contains(q) ||
              (e.position ?? '').toLowerCase().contains(q))
          .toList();
    }
  }

  void _showAddEditSheet({Employee? employee}) {
    final sw = _isSwahili;
    final nameCtrl = TextEditingController(text: employee?.name ?? '');
    final phoneCtrl = TextEditingController(text: employee?.phone ?? '');
    final nidaCtrl = TextEditingController(text: employee?.nidaNumber ?? '');
    final posCtrl = TextEditingController(text: employee?.position ?? '');
    final salaryCtrl = TextEditingController(
        text: employee?.grossSalary.toStringAsFixed(0) ?? '');
    final bankAccCtrl =
        TextEditingController(text: employee?.bankAccount ?? '');
    final bankNameCtrl =
        TextEditingController(text: employee?.bankName ?? '');
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
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
                Text(
                  employee == null
                      ? (sw ? 'Ongeza Mfanyakazi' : 'Add Employee')
                      : (sw ? 'Hariri Mfanyakazi' : 'Edit Employee'),
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _kPrimary),
                ),
                const SizedBox(height: 16),
                _inputField(nameCtrl,
                    sw ? 'Jina Kamili' : 'Full Name', Icons.person_rounded),
                const SizedBox(height: 10),
                _inputField(phoneCtrl,
                    sw ? 'Namba ya Simu' : 'Phone Number', Icons.phone_rounded,
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 10),
                _inputField(nidaCtrl,
                    sw ? 'Namba ya NIDA' : 'NIDA Number', Icons.badge_rounded),
                const SizedBox(height: 10),
                _inputField(posCtrl,
                    sw ? 'Nafasi / Cheo' : 'Position / Role', Icons.work_rounded),
                const SizedBox(height: 10),
                _inputField(salaryCtrl,
                    sw ? 'Mshahara (TZS/mwezi)' : 'Salary (TZS/month)',
                    Icons.payments_rounded,
                    keyboardType: TextInputType.number),
                const SizedBox(height: 10),
                _inputField(bankNameCtrl,
                    sw ? 'Jina la Benki' : 'Bank Name',
                    Icons.account_balance_rounded),
                const SizedBox(height: 10),
                _inputField(bankAccCtrl,
                    sw ? 'Akaunti ya Benki' : 'Bank Account',
                    Icons.credit_card_rounded),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            if (nameCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(sw
                                          ? 'Tafadhali weka jina'
                                          : 'Please enter a name')));
                              return;
                            }
                            setSheetState(() => saving = true);
                            final body = {
                              'business_id': widget.businessId,
                              'name': nameCtrl.text.trim(),
                              'phone': phoneCtrl.text.trim(),
                              'nida_number': nidaCtrl.text.trim(),
                              'position': posCtrl.text.trim(),
                              'gross_salary': double.tryParse(
                                      salaryCtrl.text
                                          .replaceAll(',', '')) ??
                                  0,
                              'bank_name': bankNameCtrl.text.trim(),
                              'bank_account': bankAccCtrl.text.trim(),
                              'is_active': true,
                            };
                            try {
                              if (employee == null) {
                                final res = await BusinessService.addEmployee(
                                    _token!, body);
                                if (mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(res.success
                                              ? (sw
                                                  ? 'Ameongezwa'
                                                  : 'Employee added')
                                              : (res.message ??
                                                  (sw
                                                      ? 'Imeshindikana'
                                                      : 'Failed')))));
                                }
                              } else {
                                final res =
                                    await BusinessService.updateEmployee(
                                        _token!, employee.id!, body);
                                if (mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(res.success
                                              ? (sw
                                                  ? 'Imehifadhiwa'
                                                  : 'Saved')
                                              : (res.message ??
                                                  (sw
                                                      ? 'Imeshindikana'
                                                      : 'Failed')))));
                                }
                              }
                              _load();
                            } catch (e) {
                              setSheetState(() => saving = false);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(sw
                                            ? 'Imeshindikana'
                                            : 'An error occurred')));
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(
                            employee == null
                                ? (sw ? 'Ongeza' : 'Add')
                                : (sw ? 'Hifadhi' : 'Save'),
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField(TextEditingController ctrl, String label, IconData icon,
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Future<void> _removeEmployee(Employee emp) async {
    if (_token == null || emp.id == null) return;
    final sw = _isSwahili;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(sw ? 'Ondoa Mfanyakazi' : 'Remove Employee',
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
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(sw ? 'Ondoa' : 'Remove'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final res = await BusinessService.removeEmployee(_token!, emp.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(res.success
                ? (sw ? 'Ameondolewa' : 'Employee removed')
                : (res.message ?? (sw ? 'Imeshindikana' : 'Failed')))));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text(sw ? 'Imeshindikana' : 'Failed to remove employee')));
      }
    }
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sw = _isSwahili;

    return Scaffold(
      backgroundColor: _kBackground,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditSheet(),
        backgroundColor: _kPrimary,
        child: const Icon(Icons.person_add_rounded, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(_applyFilter),
              decoration: InputDecoration(
                hintText: sw ? 'Tafuta mfanyakazi...' : 'Search employee...',
                prefixIcon:
                    const Icon(Icons.search_rounded, color: _kSecondary),
                filled: true,
                fillColor: _kCardBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: _kPrimary, strokeWidth: 2))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline_rounded,
                                size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              sw ? 'Imeshindikana kupakia' : 'Failed to load',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey.shade500),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _load,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _kPrimary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text(sw ? 'Jaribu Tena' : 'Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.badge_rounded,
                                    size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                Text(
                                    sw
                                        ? 'Hakuna wafanyakazi'
                                        : 'No employees yet',
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 16)),
                                const SizedBox(height: 4),
                                Text(
                                    sw
                                        ? 'Bonyeza + kuongeza'
                                        : 'Tap + to add one',
                                    style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 13)),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            color: _kPrimary,
                            onRefresh: _load,
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _filtered.length,
                              itemBuilder: (_, i) {
                                final emp = _filtered[i];
                                return EmployeeCard(
                                  employee: emp,
                                  onEditTap: () =>
                                      _showAddEditSheet(employee: emp),
                                  onRemoveTap: () => _removeEmployee(emp),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
