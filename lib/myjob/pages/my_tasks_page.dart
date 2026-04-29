// lib/myjob/pages/my_tasks_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/myjob_models.dart';
import '../services/my_job_service.dart';
import '../widgets/update_task_sheet.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);
const Color _kCard = Color(0xFFFFFFFF);

class MyTasksPage extends StatefulWidget {
  final String token;

  const MyTasksPage({super.key, required this.token});

  @override
  State<MyTasksPage> createState() => _MyTasksPageState();
}

class _MyTasksPageState extends State<MyTasksPage> {
  DateTime _selectedDate = DateTime.now();
  List<WorkTask> _standing = [];
  List<WorkTask> _adhoc = [];
  bool _loading = false;
  String? _error;

  late final List<DateTime> _days;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _days = List.generate(
        30, (i) => today.subtract(const Duration(days: 7)).add(Duration(days: i)));
    _load(_selectedDate);
  }

  Future<void> _load(DateTime date) async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await MyJobService.getMyTasks(widget.token, date: date);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _standing = res.standingTasks;
        _adhoc = res.adhocTasks;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  bool _isSelected(DateTime d) =>
      d.year == _selectedDate.year &&
      d.month == _selectedDate.month &&
      d.day == _selectedDate.day;

  bool _isPast(DateTime d) => d.isBefore(DateTime.now().subtract(const Duration(days: 1)));

  int get _totalTasks => _standing.length + _adhoc.length;
  int get _doneTasks =>
      _standing.where((t) => t.isDone).length + _adhoc.where((t) => t.isDone).length;

  void _openUpdate(WorkTask task, bool sw) {
    if (_isPast(_selectedDate)) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => UpdateTaskSheet(
        task: task,
        token: widget.token,
        sw: sw,
        onSaved: () => _load(_selectedDate),
      ),
    );
  }

  Widget _taskRow(WorkTask task, bool sw, bool isPast) {
    Color statusColor;
    switch (task.status) {
      case 'in_progress': statusColor = Colors.amber; break;
      case 'done': statusColor = Colors.green; break;
      default: statusColor = Colors.grey;
    }
    return GestureDetector(
      onTap: isPast ? null : () => _openUpdate(task, sw),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 8, height: 8,
                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(task.title,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            if (isPast)
              Text(sw ? 'Imepita' : 'Past',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
            if (!isPast)
              const Icon(Icons.chevron_right_rounded, size: 16, color: _kSecondary),
          ]),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: task.progress / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(statusColor),
            minHeight: 3,
            borderRadius: BorderRadius.circular(2),
          ),
          const SizedBox(height: 4),
          Text('${task.progress}%',
              style: const TextStyle(fontSize: 11, color: _kSecondary)),
          if (task.lastComment != null && task.lastComment!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(task.lastComment!,
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sw = AppStringsScope.of(context)?.isSwahili ?? false;
    final isPast = _isPast(_selectedDate);
    final dayNames = sw
        ? ['Jtn', 'Jnn', 'Jto', 'Alh', 'Ijm', 'Jms', 'Jpl']
        : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    String dayLabel(DateTime d) => dayNames[d.weekday - 1];

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: const BackButton(color: _kPrimary),
        title: Text(sw ? 'Kazi Zangu' : 'My Tasks',
            style: const TextStyle(
                color: _kPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: Column(children: [
        Container(
          color: _kCard,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(children: [
            if (_totalTasks > 0) ...[
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                SizedBox(
                  width: 40, height: 40,
                  child: CircularProgressIndicator(
                    value: _doneTasks / _totalTasks,
                    strokeWidth: 4,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF1A1A1A)),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                    sw ? '$_doneTasks / $_totalTasks imekamilika'
                       : '$_doneTasks / $_totalTasks done',
                    style: const TextStyle(fontSize: 13, color: _kPrimary)),
              ]),
              const SizedBox(height: 8),
            ],

            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _days.length,
                itemBuilder: (_, i) {
                  final d = _days[i];
                  final sel = _isSelected(d);
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedDate = d);
                      _load(d);
                    },
                    child: Container(
                      width: 48,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                          color: sel ? _kPrimary : Colors.transparent,
                          borderRadius: BorderRadius.circular(10)),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(dayLabel(d),
                            style: TextStyle(
                                fontSize: 10,
                                color: sel ? Colors.white : _kSecondary)),
                        Text('${d.day}',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: sel ? Colors.white : _kPrimary)),
                        if (_isToday(d))
                          Container(
                              width: 4, height: 4,
                              decoration: BoxDecoration(
                                  color: sel ? Colors.white : _kPrimary,
                                  shape: BoxShape.circle)),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ]),
        ),

        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2))
              : _error != null
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.error_outline_rounded, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(sw ? 'Imeshindwa kupakia kazi.' : 'Failed to load tasks.',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => _load(_selectedDate),
                        style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white),
                        child: Text(sw ? 'Jaribu Tena' : 'Retry'),
                      ),
                    ]))
                  : _standing.isEmpty && _adhoc.isEmpty
                      ? Center(
                          child: Text(sw ? 'Hakuna kazi siku hii.' : 'No tasks for this day.',
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 14)))
                  : ListView(padding: const EdgeInsets.all(16), children: [
                      if (_standing.isNotEmpty) ...[
                        Text(sw ? 'Majukumu ya Kawaida' : 'Standing Duties',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600, color: _kSecondary)),
                        const SizedBox(height: 8),
                        ..._standing.map((t) => _taskRow(t, sw, isPast)),
                        const SizedBox(height: 12),
                      ],
                      if (_adhoc.isNotEmpty) ...[
                        Text(sw ? 'Kazi Zilizopewa' : 'Assigned Tasks',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600, color: _kSecondary)),
                        const SizedBox(height: 8),
                        ..._adhoc.map((t) => _taskRow(t, sw, isPast)),
                      ],
                    ]),
        ),
      ]),
    );
  }
}
