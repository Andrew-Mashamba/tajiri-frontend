// lib/team/pages/employee_tasks_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/team_models.dart';
import '../models/task_models.dart';
import '../services/work_service.dart';
import '../services/team_service.dart';
import '../widgets/add_work_task_sheet.dart';
import 'task_detail_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);
const Color _kCard = Color(0xFFFFFFFF);

class EmployeeTasksPage extends StatefulWidget {
  final int employeeId;
  final int businessId;
  final String employeeName;
  final String token;

  const EmployeeTasksPage({
    super.key,
    required this.employeeId,
    required this.businessId,
    required this.employeeName,
    required this.token,
  });

  @override
  State<EmployeeTasksPage> createState() => _EmployeeTasksPageState();
}

class _EmployeeTasksPageState extends State<EmployeeTasksPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<WorkTask> _tasks = [];
  List<Employee> _allEmployees = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      WorkService.getEmployeeTasks(widget.token, widget.employeeId),
      TeamService.getEmployees(widget.token, widget.businessId),
    ]);
    if (!mounted) return;
    final taskRes = results[0] as WorkListResult<WorkTask>;
    final empRes = results[1] as TeamListResult<Employee>;
    setState(() {
      _loading = false;
      _tasks = taskRes.data;
      _allEmployees = empRes.data;
    });
  }

  List<WorkTask> _filtered(String status) =>
      _tasks.where((t) => t.status == status).toList();

  void _openAddSheet(bool sw) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => AddWorkTaskSheet(
        token: widget.token,
        businessId: widget.businessId,
        preselectedEmployeeId: widget.employeeId,
        preselectedEmployeeName: widget.employeeName,
        employees: _allEmployees,
        sw: sw,
        onSaved: _load,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: const BackButton(color: _kPrimary),
        title: Text(widget.employeeName,
            style: const TextStyle(
                color: _kPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task_rounded, color: _kPrimary),
            tooltip: sw ? 'Gawanya Kazi' : 'Assign Task',
            onPressed: () => _openAddSheet(sw),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: _kPrimary,
          unselectedLabelColor: _kSecondary,
          indicatorColor: _kPrimary,
          tabs: [
            Tab(text: sw ? 'Inasubiri' : 'Pending'),
            Tab(text: sw ? 'Inaendelea' : 'In Progress'),
            Tab(text: sw ? 'Imekamilika' : 'Done'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2))
          : Column(children: [
              Builder(builder: (ctx) {
                final adhoc = _tasks.where((t) => t.isAdhoc).toList();
                final adhocDone = adhoc.where((t) => t.isDone).length;
                final pct = adhoc.isEmpty ? 0 : (adhocDone * 100 ~/ adhoc.length);
                return Container(
                  color: _kCard,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(children: [
                    Expanded(child: Text(
                        sw ? 'Ukamilishaji wiki hii: $adhocDone kati ya ${adhoc.length} ($pct%)'
                           : 'Completion this week: $adhocDone of ${adhoc.length} ad-hoc tasks done ($pct%)',
                        style: const TextStyle(fontSize: 12, color: _kSecondary))),
                  ]),
                );
              }),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _TaskList(tasks: _filtered('pending'), allTasks: _tasks, token: widget.token,
                        businessId: widget.businessId, allEmployees: _allEmployees, sw: sw, onChanged: _load),
                    _TaskList(tasks: _filtered('in_progress'), allTasks: _tasks, token: widget.token,
                        businessId: widget.businessId, allEmployees: _allEmployees, sw: sw, onChanged: _load),
                    _TaskList(tasks: _filtered('done'), allTasks: _tasks, token: widget.token,
                        businessId: widget.businessId, allEmployees: _allEmployees, sw: sw, onChanged: _load),
                  ],
                ),
              ),
            ]),
    );
  }
}

class _TaskList extends StatelessWidget {
  final List<WorkTask> tasks;
  final List<WorkTask> allTasks;
  final String token;
  final int businessId;
  final List<Employee> allEmployees;
  final bool sw;
  final VoidCallback onChanged;

  const _TaskList({
    required this.tasks,
    required this.allTasks,
    required this.token,
    required this.businessId,
    required this.allEmployees,
    required this.sw,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return Center(
        child: Text(sw ? 'Hakuna kazi' : 'No tasks',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
      );
    }
    return RefreshIndicator(
      color: const Color(0xFF1A1A1A),
      onRefresh: () async => onChanged(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tasks.length,
        itemBuilder: (_, i) => _WorkTaskCard(
          task: tasks[i],
          allTasks: allTasks,
          token: token,
          businessId: businessId,
          allEmployees: allEmployees,
          sw: sw,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _WorkTaskCard extends StatelessWidget {
  final WorkTask task;
  final List<WorkTask> allTasks;
  final String token;
  final int businessId;
  final List<Employee> allEmployees;
  final bool sw;
  final VoidCallback onChanged;

  const _WorkTaskCard({
    required this.task,
    required this.allTasks,
    required this.token,
    required this.businessId,
    required this.allEmployees,
    required this.sw,
    required this.onChanged,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'in_progress': return Colors.amber;
      case 'done': return Colors.green;
      default: return Colors.grey;
    }
  }

  void _openDetail(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(
        builder: (_) => TaskDetailPage(
              taskId: task.id!,
              task: task,
              token: token,
              businessId: businessId,
              allEmployees: allEmployees,
              sw: sw,
              onChanged: onChanged,
            )));
  }

  Future<void> _showReassign(BuildContext context) async {
    final others = allEmployees
        .where((e) => e.isActive && e.id != task.employeeId)
        .toList();
    if (others.isEmpty) return;
    int? newEmpId;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx2, setSt) {
        final pendingForNew = newEmpId == null ? 0
            : allTasks.where((t) => t.employeeId == newEmpId && t.status == 'pending').length;
        final showWarning = pendingForNew >= 5;
        return AlertDialog(
          title: Text(sw ? 'Gawanya Upya Kazi' : 'Reassign Task',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<int>(
              decoration: InputDecoration(
                  labelText: sw ? 'Mfanyakazi Mpya' : 'New Employee',
                  border: const OutlineInputBorder()),
              items: others.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name))).toList(),
              onChanged: (v) => setSt(() => newEmpId = v),
            ),
            if (showWarning) ...[
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange),
                const SizedBox(width: 6),
                Expanded(child: Text(
                    sw ? 'Mfanyakazi huyu ana kazi $pendingForNew zinazongoja.'
                       : 'This employee has $pendingForNew pending tasks.',
                    style: const TextStyle(fontSize: 12, color: Colors.orange))),
              ]),
            ],
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(sw ? 'Ghairi' : 'Cancel')),
            ElevatedButton(
              onPressed: newEmpId == null ? null : () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(ctx);
                final res = await WorkService.reassignTask(token, task.id!, newEmpId!);
                if (res.success) {
                  onChanged();
                } else {
                  messenger.showSnackBar(SnackBar(
                      content: Text(res.message ??
                          (sw ? 'Imeshindwa kugawanya upya. Jaribu tena.'
                              : 'Failed to reassign. Try again.')),
                      backgroundColor: Colors.red));
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A1A), foregroundColor: Colors.white),
              child: Text(sw ? 'Gawanya Upya' : 'Reassign'),
            ),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dueStr = task.dueDate != null
        ? DateFormat('dd MMM').format(task.dueDate!)
        : null;
    final recurrenceStr = task.recurrence != null
        ? (sw
            ? (task.recurrence == 'daily' ? 'Kila Siku'
                : task.recurrence == 'weekly' ? 'Kila Wiki'
                : task.recurrence == 'weekdays' ? 'Siku za Kazi' : 'Maalum')
            : (task.recurrence == 'daily' ? 'Daily'
                : task.recurrence == 'weekly' ? 'Weekly'
                : task.recurrence == 'weekdays' ? 'Weekdays' : 'Custom'))
        : null;

    return GestureDetector(
      onTap: () => _openDetail(context),
      onLongPress: () async {
        final action = await showModalBottomSheet<String>(
          context: context,
          builder: (_) => SafeArea(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              ListTile(
                leading: const Icon(Icons.swap_horiz_rounded),
                title: Text(sw ? 'Gawanya Upya Kazi' : 'Reassign Task'),
                onTap: () => Navigator.pop(context, 'reassign'),
              ),
              ListTile(
                leading: const Icon(Icons.open_in_new_rounded),
                title: Text(sw ? 'Tazama Maelezo' : 'View Details'),
                onTap: () => Navigator.pop(context, 'detail'),
              ),
            ]),
          ),
        );
        if (!context.mounted) return;
        if (action == 'reassign') _showReassign(context);
        if (action == 'detail') _openDetail(context);
      },
      child: Card(
        color: Colors.white,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: task.isStanding ? Colors.blue.shade50 : Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(6)),
                child: Text(
                    task.isStanding
                        ? (sw ? 'Kawaida' : 'Standing')
                        : (sw ? 'Maalum' : 'Ad-hoc'),
                    style: TextStyle(
                        fontSize: 10,
                        color: task.isStanding ? Colors.blue : Colors.purple)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(task.title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                    color: _statusColor(task.status), shape: BoxShape.circle),
              ),
            ]),
            if (dueStr != null || recurrenceStr != null) ...[
              const SizedBox(height: 4),
              Text(dueStr ?? recurrenceStr!,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
            ],
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: task.progress / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(_statusColor(task.status)),
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
            ),
            const SizedBox(height: 4),
            Text('${task.progress}%',
                style: const TextStyle(fontSize: 11, color: Color(0xFF666666))),
          ]),
        ),
      ),
    );
  }
}
