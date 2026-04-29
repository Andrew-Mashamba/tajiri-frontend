// lib/team/pages/task_detail_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/team_models.dart';
import '../models/task_models.dart';
import '../services/work_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);
const Color _kCard = Color(0xFFFFFFFF);

class TaskDetailPage extends StatefulWidget {
  final int taskId;
  final WorkTask task;
  final String token;
  final int businessId;
  final List<Employee> allEmployees;
  final bool sw;
  final VoidCallback? onChanged;

  const TaskDetailPage({
    super.key,
    required this.taskId,
    required this.task,
    required this.token,
    required this.businessId,
    required this.allEmployees,
    required this.sw,
    this.onChanged,
  });

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  List<TaskUpdate> _updates = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await WorkService.getTaskUpdates(widget.token, widget.taskId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _updates = res.data;
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'in_progress': return Colors.amber;
      case 'done': return Colors.green;
      default: return Colors.grey;
    }
  }

  Future<void> _deleteTask() async {
    final sw = widget.sw;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(sw ? 'Futa Kazi' : 'Delete Task',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(sw ? 'Futa kazi hii?' : 'Delete this task?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text(sw ? 'Ghairi' : 'Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(sw ? 'Futa' : 'Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final nav = Navigator.of(context);
    final res = await WorkService.deleteTask(widget.token, widget.taskId);
    if (!mounted) return;
    if (res.success) {
      widget.onChanged?.call();
      nav.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res.message ?? 'Failed'), backgroundColor: Colors.red));
    }
  }

  Future<void> _reassign() async {
    final sw = widget.sw;
    final others = widget.allEmployees
        .where((e) => e.isActive && e.id != widget.task.employeeId)
        .toList();
    if (others.isEmpty) return;
    int? newEmpId;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx2, setSt) => AlertDialog(
        title: Text(sw ? 'Gawanya Upya Kazi' : 'Reassign Task',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: DropdownButtonFormField<int>(
          decoration: InputDecoration(
              labelText: sw ? 'Mfanyakazi Mpya' : 'New Employee',
              border: const OutlineInputBorder()),
          items: others.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name))).toList(),
          onChanged: (v) => setSt(() => newEmpId = v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(sw ? 'Ghairi' : 'Cancel')),
          ElevatedButton(
            onPressed: newEmpId == null ? null : () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              final res = await WorkService.reassignTask(widget.token, widget.taskId, newEmpId!);
              if (!mounted) return;
              final name = others.firstWhere((e) => e.id == newEmpId).name;
              messenger.showSnackBar(SnackBar(
                  content: Text(res.success
                      ? (sw ? 'Kazi imegawiwa kwa $name' : 'Task reassigned to $name')
                      : (res.message ?? 'Failed'))));
              if (res.success) { widget.onChanged?.call(); _load(); }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary, foregroundColor: Colors.white),
            child: Text(sw ? 'Gawanya Upya' : 'Reassign'),
          ),
        ],
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sw = widget.sw;
    final progress = _updates.isNotEmpty ? _updates.first.progress : widget.task.progress;
    final status = _updates.isNotEmpty ? _updates.first.status : widget.task.status;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: const BackButton(color: _kPrimary),
        title: Text(sw ? 'Maelezo ya Kazi' : 'Task Detail',
            style: const TextStyle(color: _kPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            onPressed: _deleteTask,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2))
          : ListView(padding: const EdgeInsets.all(16), children: [
              Card(
                color: _kCard, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.task.title,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold, color: _kPrimary),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 6, children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: widget.task.isStanding ? Colors.blue.shade50 : Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(6)),
                        child: Text(
                            widget.task.isStanding
                                ? (sw ? 'Kawaida' : 'Standing')
                                : (sw ? 'Maalum' : 'Ad-hoc'),
                            style: TextStyle(
                                fontSize: 11,
                                color: widget.task.isStanding ? Colors.blue : Colors.purple)),
                      ),
                      if (widget.task.assigneeName != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.person_outline_rounded, size: 12, color: _kSecondary),
                            const SizedBox(width: 4),
                            Text(widget.task.assigneeName!,
                                style: const TextStyle(fontSize: 11, color: _kPrimary)),
                          ]),
                        ),
                      if (widget.task.dueDate != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.calendar_today_rounded, size: 12, color: _kSecondary),
                            const SizedBox(width: 4),
                            Text(DateFormat('dd MMM yyyy').format(widget.task.dueDate!),
                                style: const TextStyle(fontSize: 11, color: _kPrimary)),
                          ]),
                        )
                      else if (widget.task.recurrence != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.repeat_rounded, size: 12, color: _kSecondary),
                            const SizedBox(width: 4),
                            Text(
                                sw
                                    ? (widget.task.recurrence == 'daily' ? 'Kila Siku'
                                        : widget.task.recurrence == 'weekly' ? 'Kila Wiki'
                                        : widget.task.recurrence == 'weekdays' ? 'Siku za Kazi' : 'Maalum')
                                    : (widget.task.recurrence == 'daily' ? 'Every day'
                                        : widget.task.recurrence == 'weekly' ? 'Every week'
                                        : widget.task.recurrence == 'weekdays' ? 'Every weekday' : 'Custom'),
                                style: const TextStyle(fontSize: 11, color: _kPrimary)),
                          ]),
                        ),
                    ]),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                color: _kCard, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [
                    SizedBox(
                      width: 100, height: 100,
                      child: Stack(alignment: Alignment.center, children: [
                        CircularProgressIndicator(
                          value: progress / 100,
                          strokeWidth: 8,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation(
                              status == 'done' ? Colors.green
                              : status == 'in_progress' ? Colors.amber
                              : Colors.grey),
                        ),
                        Text('$progress%',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold, color: _kPrimary)),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                          color: (status == 'done' ? Colors.green
                              : status == 'in_progress' ? Colors.amber
                              : Colors.grey).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(
                          sw
                              ? (status == 'done' ? 'Imekamilika'
                                  : status == 'in_progress' ? 'Inaendelea' : 'Inasubiri')
                              : (status == 'done' ? 'Done'
                                  : status == 'in_progress' ? 'In Progress' : 'Pending'),
                          style: TextStyle(
                              fontSize: 12,
                              color: status == 'done' ? Colors.green
                                  : status == 'in_progress' ? Colors.amber.shade800
                                  : Colors.grey)),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _reassign,
                      style: OutlinedButton.styleFrom(foregroundColor: _kPrimary),
                      child: Text(sw ? 'Gawanya Upya' : 'Reassign'),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                color: _kCard, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(sw ? 'Historia ya Masasisho' : 'Update History',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600, color: _kSecondary)),
                    const SizedBox(height: 12),
                    if (_updates.isEmpty)
                      Text(
                          sw ? 'Hakuna masasisho bado. Mfanyakazi hajasasisha maendeleo.'
                             : "No updates yet. Employee hasn't logged progress.",
                          style: const TextStyle(
                              fontSize: 14, color: _kSecondary, fontStyle: FontStyle.italic))
                    else
                      ..._updates.map((u) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                                color: _statusColor(u.status).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6)),
                            child: Text(
                                sw
                                    ? (u.status == 'done' ? 'Imekamilika'
                                        : u.status == 'in_progress' ? 'Inaendelea' : 'Inasubiri')
                                    : (u.status == 'done' ? 'Done'
                                        : u.status == 'in_progress' ? 'In Progress' : 'Pending'),
                                style: TextStyle(fontSize: 10, color: _statusColor(u.status))),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('${u.progress}%',
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
                            if (u.comment != null && u.comment!.isNotEmpty)
                              Text(u.comment!,
                                  style: const TextStyle(fontSize: 12, color: _kPrimary),
                                  maxLines: 3, overflow: TextOverflow.ellipsis),
                            Text(DateFormat('dd MMM yyyy · HH:mm').format(u.createdAt),
                                style: const TextStyle(fontSize: 11, color: _kSecondary)),
                          ])),
                        ]),
                      )),
                  ]),
                ),
              ),
              const SizedBox(height: 32),
            ]),
    );
  }
}
