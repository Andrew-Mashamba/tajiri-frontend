// lib/team/pages/employees_page.dart
// Employee management — add, edit, remove. Shows employees from ALL businesses.
import 'package:flutter/material.dart';
import '../../business/biz_tab_wrapper.dart' show BusinessSectionHeader;
import '../../business/models/business_models.dart' show Business;
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/team_models.dart';
import '../services/team_service.dart';
import '../widgets/compensation_sheet.dart';
import '../widgets/employee_card.dart';
import '../widgets/user_search_sheet.dart';
import 'employee_detail_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class EmployeesPage extends StatefulWidget {
  final List<Business> businesses;
  const EmployeesPage({super.key, required this.businesses});

  @override
  State<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<EmployeesPage> {
  String? _token;
  final Map<int, List<Employee>> _employeesByBusiness = {};
  final Map<int, bool> _loadingByBusiness = {};
  final Map<int, String?> _errorByBusiness = {};
  final _searchCtrl = TextEditingController();
  bool _showInactive = false;

  bool get _isSwahili {
    final s = AppStringsScope.of(context);
    return s?.isSwahili ?? false;
  }

  bool get _isAnyLoading => _loadingByBusiness.values.any((v) => v);

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
    if (!mounted) return;
    setState(() {
      for (final biz in widget.businesses) {
        if (biz.id != null) {
          _loadingByBusiness[biz.id!] = true;
          _errorByBusiness[biz.id!] = null;
        }
      }
    });
    await Future.wait(widget.businesses.map((biz) async {
      if (biz.id == null) return;
      try {
        final res = await TeamService.getEmployees(_token!, biz.id!);
        if (mounted) {
          setState(() {
            _loadingByBusiness[biz.id!] = false;
            if (res.success) {
              _employeesByBusiness[biz.id!] = res.data;
            } else {
              _errorByBusiness[biz.id!] = res.message;
            }
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _loadingByBusiness[biz.id!] = false;
            _errorByBusiness[biz.id!] = e.toString();
          });
        }
      }
    }));
  }

  List<Employee> _filteredForBusiness(int businessId) {
    final all = _employeesByBusiness[businessId] ?? [];
    final visible = _showInactive ? all : all.where((e) => e.isActive).toList();
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return visible;
    return visible
        .where((e) =>
            e.name.toLowerCase().contains(q) ||
            (e.position ?? '').toLowerCase().contains(q))
        .toList();
  }

  void _pickBusiness(void Function(Business) onPicked) {
    final sw = _isSwahili;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
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
            Text(
              sw ? 'Chagua Biashara' : 'Select Business',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _kPrimary),
            ),
            const SizedBox(height: 12),
            ...widget.businesses.map((biz) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: _kPrimary.withValues(alpha: 0.1),
                    child: Text(
                      biz.name.isNotEmpty ? biz.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                          color: _kPrimary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(biz.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () {
                    Navigator.pop(context);
                    onPicked(biz);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showUserSearch(int businessId) {
    if (_token == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFFFFF),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => UserSearchSheet(
        token: _token!,
        onSelected: (user) => _showAddSheet(user, businessId),
      ),
    );
  }

  void _showAddSheet(PlatformUser user, int businessId) {
    if (_token == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFFFFF),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => CompensationSheet(
        token: _token!,
        businessId: businessId,
        user: user,
        onSaved: _load,
      ),
    );
  }

  void _showEditSheet(Employee employee, int businessId) {
    if (_token == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFFFFF),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => CompensationSheet(
        token: _token!,
        businessId: businessId,
        employee: employee,
        onSaved: _load,
      ),
    );
  }

  void _openDetail(Employee emp, int businessId) {
    if (_token == null || emp.id == null) return;
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => EmployeeDetailPage(
        employeeId: emp.id!,
        token: _token!,
        businessId: businessId,
        onChanged: _load,
      ),
    ));
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
      final res = await TeamService.removeEmployee(_token!, emp.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(res.success
                ? (sw ? 'Ameondolewa' : 'Employee removed')
                : (res.message ?? (sw ? 'Imeshindikana' : 'Failed')))));
        if (res.success) _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text(sw ? 'Imeshindikana' : 'Failed to remove employee')));
      }
    }
  }

  List<Widget> _buildSections(bool sw) {
    final items = <Widget>[];
    for (int i = 0; i < widget.businesses.length; i++) {
      final biz = widget.businesses[i];
      if (biz.id == null) continue;
      items.add(BusinessSectionHeader(business: biz, showDivider: i > 0));
      final error = _errorByBusiness[biz.id!];
      if (error != null) {
        items.add(Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            sw ? 'Imeshindikana kupakia' : 'Failed to load',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ));
      } else {
        final filtered = _filteredForBusiness(biz.id!);
        if (filtered.isEmpty) {
          items.add(Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 4),
            child: Text(
              sw ? 'Hakuna wafanyakazi' : 'No employees yet',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
          ));
        } else {
          for (final emp in filtered) {
            items.add(EmployeeCard(
              employee: emp,
              onTap: () => _openDetail(emp, biz.id!),
              onEditTap: () => _showEditSheet(emp, biz.id!),
              onRemoveTap: () => _removeEmployee(emp),
            ));
          }
        }
      }
    }
    items.add(const SizedBox(height: 80)); // FAB clearance
    return items;
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
        onPressed: () {
          if (widget.businesses.length == 1) {
            _showUserSearch(widget.businesses.first.id!);
          } else {
            _pickBusiness((biz) => _showUserSearch(biz.id!));
          }
        },
        backgroundColor: _kPrimary,
        child: const Icon(Icons.person_add_rounded, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText:
                        sw ? 'Tafuta mfanyakazi...' : 'Search employee...',
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
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.visibility_outlined, size: 16, color: _kSecondary),
                    const SizedBox(width: 6),
                    Text(
                      sw ? 'Onyesha wasio hai' : 'Show inactive',
                      style: const TextStyle(fontSize: 13, color: _kSecondary),
                    ),
                    const Spacer(),
                    Switch.adaptive(
                      value: _showInactive,
                      onChanged: (v) => setState(() => _showInactive = v),
                      activeThumbColor: _kPrimary,
                      activeTrackColor: _kPrimary.withValues(alpha: 0.3),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isAnyLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: _kPrimary, strokeWidth: 2))
                : RefreshIndicator(
                    color: _kPrimary,
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: _buildSections(sw),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
