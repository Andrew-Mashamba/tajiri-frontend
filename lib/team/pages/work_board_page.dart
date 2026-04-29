// lib/team/pages/work_board_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/team_models.dart';
import '../models/task_models.dart';
import '../services/team_service.dart';
import '../services/work_service.dart';
import '../widgets/add_work_task_sheet.dart';
import 'task_detail_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);
const Color _kCard = Color(0xFFFFFFFF);

class WorkBoardPage extends StatefulWidget {
  final int businessId;
  final String token;

  const WorkBoardPage({
    super.key,
    required this.businessId,
    required this.token,
  });

  @override
  State<WorkBoardPage> createState() => _WorkBoardPageState();
}

class _WorkBoardPageState extends State<WorkBoardPage> {
  List<WorkTask> _tasks = [];
  List<Employee> _employees = [];
  bool _loading = true;

  String _statusFilter = 'all';
  String _typeFilter = 'all';
  int? _employeeFilter;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      WorkService.getAllBusinessTasks(widget.token, widget.businessId),
      TeamService.getEmployees(widget.token, widget.businessId),
    ]);
    if (!mounted) return;
    final taskRes = results[0] as WorkListResult<WorkTask>;
    final empRes = results[1] as TeamListResult<Employee>;
    setState(() {
      _loading = false;
      _tasks = taskRes.data;
      _employees = empRes.data;
    });
  }

  List<WorkTask> get _filtered {
    return _tasks.where((t) {
      if (_statusFilter != 'all' && t.status != _statusFilter) return false;
      if (_typeFilter != 'all' && t.taskType != _typeFilter) return false;
      if (_employeeFilter != null && t.employeeId != _employeeFilter) return false;
      if (_search.isNotEmpty &&
          !t.title.toLowerCase().contains(_search.toLowerCase()) &&
          !(t.assigneeName?.toLowerCase().contains(_search.toLowerCase()) ?? false)) {
        return false;
      }
      return true;
    }).toList();
  }

  int get _pendingCount => _tasks.where((t) => t.status == 'pending').length;
  int get _inProgressCount => _tasks.where((t) => t.status == 'in_progress').length;
  int get _doneCount => _tasks.where((t) => t.status == 'done').length;
  int get _overdueCount => _tasks.where((t) =>
      t.isAdhoc && t.dueDate != null && t.dueDate!.isBefore(DateTime.now()) && !t.isDone).length;

  void _openAdd(bool sw) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => AddWorkTaskSheet(
        token: widget.token,
        businessId: widget.businessId,
        employees: _employees,
        sw: sw,
        onSaved: _load,
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'in_progress': return Colors.amber;
      case 'done': return Colors.green;
      default: return Colors.grey;
    }
  }

  Employee? _empById(int id) {
    try { return _employees.firstWhere((e) => e.id == id); }
    catch (_) { return null; }
  }

  @override
  Widget build(BuildContext context) {
    final sw = AppStringsScope.of(context)?.isSwahili ?? false;
    final filtered = _filtered;
    final overdue = _overdueCount;

    return Scaffold(
      backgroundColor: _kBg,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAdd(sw),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
      body: RefreshIndicator(
        color: _kPrimary,
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2))
            : Column(children: [
                Container(
                  color: _kCard,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _summaryChip(sw ? 'Inasubiri' : 'Pending', _pendingCount, Colors.grey),
                      _summaryChip(sw ? 'Inaendelea' : 'In Progress', _inProgressCount, Colors.amber),
                      _summaryChip(sw ? 'Imekamilika' : 'Done', _doneCount, Colors.green),
                      _summaryChip(sw ? 'Imechelewa' : 'Overdue', overdue,
                          overdue > 0 ? Colors.red : Colors.grey),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    decoration: InputDecoration(
                      hintText: sw ? 'Tafuta kazi au mfanyakazi...' : 'Search tasks or employee...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(children: [
                    DropdownButton<int?>(
                      value: _employeeFilter,
                      hint: Text(sw ? 'Wafanyakazi Wote' : 'All Employees',
                          style: const TextStyle(fontSize: 12)),
                      underline: const SizedBox.shrink(),
                      items: [
                        DropdownMenuItem<int?>(
                            value: null,
                            child: Text(sw ? 'Wafanyakazi Wote' : 'All',
                                style: const TextStyle(fontSize: 12))),
                        ..._employees.map((e) => DropdownMenuItem<int?>(
                              value: e.id,
                              child: Text(e.name,
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis),
                            )),
                      ],
                      onChanged: (v) => setState(() => _employeeFilter = v),
                    ),
                    const SizedBox(width: 8),
                    for (final s in ['all', 'pending', 'in_progress', 'done'])
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(
                              s == 'all' ? (sw ? 'Zote' : 'All')
                              : s == 'pending' ? (sw ? 'Inasubiri' : 'Pending')
                              : s == 'in_progress' ? (sw ? 'Inaendelea' : 'In Progress')
                              : (sw ? 'Imekamilika' : 'Done'),
                              style: const TextStyle(fontSize: 11)),
                          selected: _statusFilter == s,
                          onSelected: (_) => setState(() => _statusFilter = s),
                          selectedColor: _kPrimary,
                          labelStyle: TextStyle(
                              color: _statusFilter == s ? Colors.white : _kPrimary),
                        ),
                      ),
                    const SizedBox(width: 4),
                    for (final t in ['all', 'standing', 'adhoc'])
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(
                              t == 'all' ? (sw ? 'Aina Zote' : 'All Types')
                              : t == 'standing' ? (sw ? 'Kawaida' : 'Standing')
                              : (sw ? 'Maalum' : 'Ad-hoc'),
                              style: const TextStyle(fontSize: 11)),
                          selected: _typeFilter == t,
                          onSelected: (_) => setState(() => _typeFilter = t),
                          selectedColor: _kPrimary,
                          labelStyle: TextStyle(
                              color: _typeFilter == t ? Colors.white : _kPrimary),
                        ),
                      ),
                  ]),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                              _tasks.isEmpty
                                  ? (sw ? 'Hakuna kazi bado. Gonga + kugawanya kazi ya kwanza.'
                                        : 'No tasks assigned yet. Tap + to assign the first task.')
                                  : (sw ? 'Hakuna kazi zinazofanana na vichujio vyako.'
                                        : 'No tasks match your filters.'),
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final t = filtered[i];
                            final emp = _empById(t.employeeId);
                            final due = t.dueDate != null
                                ? DateFormat('dd MMM').format(t.dueDate!)
                                : null;
                            return GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => TaskDetailPage(
                                        taskId: t.id!,
                                        task: t,
                                        token: widget.token,
                                        businessId: widget.businessId,
                                        allEmployees: _employees,
                                        sw: sw,
                                        onChanged: _load,
                                      ))),
                              child: Card(
                                color: _kCard, elevation: 0,
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Colors.grey.shade200,
                                      child: Text(
                                          emp?.name.isNotEmpty == true
                                              ? emp!.name[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                              fontSize: 12, color: _kPrimary,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(t.title,
                                          style: const TextStyle(
                                              fontSize: 13, fontWeight: FontWeight.w600,
                                              color: _kPrimary),
                                          maxLines: 1, overflow: TextOverflow.ellipsis),
                                      Text(emp?.name ?? t.assigneeName ?? '',
                                          style: const TextStyle(fontSize: 11, color: _kSecondary)),
                                      if (due != null)
                                        Text(due,
                                            style: const TextStyle(fontSize: 11, color: _kSecondary)),
                                    ])),
                                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                      Container(
                                          width: 8, height: 8,
                                          decoration: BoxDecoration(
                                              color: _statusColor(t.status),
                                              shape: BoxShape.circle)),
                                      const SizedBox(height: 4),
                                      Text('${t.progress}%',
                                          style: const TextStyle(fontSize: 11, color: _kSecondary)),
                                    ]),
                                  ]),
                                ),
                              ),
                            );
                          }),
                ),
              ]),
      ),
    );
  }

  Widget _summaryChip(String label, int count, Color color) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('$count',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: const TextStyle(fontSize: 10, color: _kSecondary)),
    ],
  );
}
