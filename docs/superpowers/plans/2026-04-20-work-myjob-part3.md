# Work Management & My Job — Implementation Plan (Part 3: Employee UI + Wiring)

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans. Run after Parts 1 and 2 are complete.

**Goal:** Build employee-side My Job pages, wire all new pages into EmployeeDetailPage, update team.dart barrel, register navigation in profile_screen.dart, and add My Job tab to ProfileTabDefaults.

**Depends on:** Parts 1 + 2 complete.

---

## Task 11: My Job Page (Employee Home)

**Files:**
- Create: `lib/myjob/pages/my_job_page.dart`
- Create: `lib/myjob/models/myjob_models.dart` (re-exports for convenience)

- [ ] **Step 1: Create myjob_models.dart**

```dart
// lib/myjob/models/myjob_models.dart
// Re-export shared models so myjob pages only need to import from here.
export '../../team/models/work_models.dart';
export '../../team/models/task_models.dart';
```

- [ ] **Step 2: Create MyJobPage**

```dart
// lib/myjob/pages/my_job_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/myjob_models.dart';
import '../services/my_job_service.dart';
import '../../team/services/work_service.dart' show WorkResult, WorkListResult;
import 'my_job_description_page.dart';
import 'my_tasks_page.dart';
import 'my_kpis_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);
const Color _kCard = Color(0xFFFFFFFF);

class MyJobPage extends StatefulWidget {
  final String token;

  const MyJobPage({super.key, required this.token});

  @override
  State<MyJobPage> createState() => _MyJobPageState();
}

class _MyJobPageState extends State<MyJobPage> {
  JobDescription? _jd;
  List<WorkTask> _todayStanding = [];
  List<WorkTask> _todayAdhoc = [];
  List<Kpi> _kpis = [];
  Map<int, List<KpiEntry>> _kpiEntries = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        MyJobService.getMyJobDescription(widget.token),
        MyJobService.getMyTasks(widget.token),
        MyJobService.getMyKpis(widget.token),
      ]);
      if (!mounted) return;
      final jdRes = results[0] as WorkResult<JobDescription>;
      final tasksRes = results[1] as MyTasksResult;
      final kpiRes = results[2] as WorkListResult<Kpi>;
      setState(() {
        _loading = false;
        _jd = jdRes.data;
        _todayStanding = tasksRes.standingTasks;
        _todayAdhoc = tasksRes.adhocTasks;
        _kpis = kpiRes.data;
      });
      // Load latest entry per KPI for progress bar display (at most 3)
      for (final kpi in _kpis.take(3)) {
        if (kpi.id != null) _loadEntries(kpi.id!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _loadEntries(int kpiId) async {
    final res = await MyJobService.getMyKpiEntries(widget.token, kpiId);
    if (!mounted) return;
    setState(() => _kpiEntries[kpiId] = res.data);
  }

  int get _pendingCount =>
      _todayStanding.where((t) => !t.isDone).length +
      _todayAdhoc.where((t) => !t.isDone).length;

  int get _totalToday => _todayStanding.length + _todayAdhoc.length;

  int get _doneCount => _totalToday - _pendingCount;

  double get _completionPct => _totalToday == 0 ? 0 : _doneCount / _totalToday;

  @override
  Widget build(BuildContext context) {
    final sw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        title: Text(sw ? 'Kazi Yangu' : 'My Job',
            style: const TextStyle(
                color: _kPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2))
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_error!, style: TextStyle(color: Colors.grey.shade500)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                      onPressed: _load,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimary, foregroundColor: Colors.white),
                      child: Text(sw ? 'Jaribu Tena' : 'Retry')),
                ]))
              : _jd == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.work_outline_rounded,
                              size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                              sw ? 'Meneja wako hajaweka wasifu wako wa kazi bado.'
                                 : "Your manager hasn't set up your job profile yet.",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 15, color: Colors.grey.shade500)),
                        ]),
                      ),
                    )
                  : RefreshIndicator(
                      color: _kPrimary,
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // My Role card
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(
                                builder: (_) => MyJobDescriptionPage(
                                      token: widget.token,
                                      jd: _jd!,
                                    ))),
                            child: Card(
                              color: _kCard, elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Container(
                                    width: 44, height: 44,
                                    decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(10)),
                                    child: const Icon(Icons.badge_outlined,
                                        color: _kPrimary, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(sw ? 'Nafasi Yangu' : 'My Role',
                                          style: const TextStyle(
                                              fontSize: 14, fontWeight: FontWeight.w600,
                                              color: _kPrimary)),
                                      const SizedBox(height: 4),
                                      if (_jd!.roleSummary.isNotEmpty)
                                        Text(_jd!.roleSummary,
                                            style: const TextStyle(
                                                fontSize: 12, color: _kSecondary),
                                            maxLines: 2, overflow: TextOverflow.ellipsis),
                                      if (_jd!.reportingTo.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                            '${sw ? 'Anarip. kwa' : 'Reports to'}: ${_jd!.reportingTo}',
                                            style: const TextStyle(
                                                fontSize: 11, color: _kSecondary)),
                                      ],
                                    ],
                                  )),
                                  const Icon(Icons.chevron_right_rounded,
                                      color: _kSecondary, size: 18),
                                ]),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Today's Tasks card
                          _navCard(
                            icon: Icons.check_circle_outline_rounded,
                            title: sw ? 'Kazi za Leo' : "Today's Tasks",
                            subtitle: _totalToday == 0
                                ? (sw ? 'Hakuna kazi leo' : 'No tasks today')
                                : (sw
                                    ? 'Kazi $_doneCount kati ya $_totalToday zimekamilika leo'
                                    : '$_doneCount of $_totalToday tasks done today'),
                            trailing: _totalToday > 0
                                ? SizedBox(
                                    width: 36, height: 36,
                                    child: CircularProgressIndicator(
                                      value: _completionPct,
                                      strokeWidth: 3,
                                      backgroundColor: Colors.grey.shade200,
                                      valueColor: const AlwaysStoppedAnimation(Color(0xFF1A1A1A)),
                                    ),
                                  )
                                : null,
                            onTap: () => Navigator.push(context, MaterialPageRoute(
                                builder: (_) => MyTasksPage(token: widget.token))),
                          ),
                          const SizedBox(height: 12),

                          // My KPIs card
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(
                                builder: (_) => MyKpisPage(token: widget.token))),
                            child: Card(
                              color: _kCard, elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [
                                    Container(
                                      width: 44, height: 44,
                                      decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(10)),
                                      child: const Icon(Icons.bar_chart_rounded,
                                          color: _kPrimary, size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text(sw ? 'Viashiria Vyangu (KPI)' : 'My KPIs',
                                        style: const TextStyle(
                                            fontSize: 14, fontWeight: FontWeight.w600,
                                            color: _kPrimary))),
                                    if (_kpis.isNotEmpty) _chip('${_kpis.length}'),
                                    const Icon(Icons.chevron_right_rounded,
                                        color: _kSecondary, size: 18),
                                  ]),
                                  if (_kpis.isEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(sw ? 'Hakuna KPI bado' : 'No KPI targets yet',
                                        style: const TextStyle(fontSize: 12, color: _kSecondary)),
                                  ] else ...[
                                    const SizedBox(height: 12),
                                    ..._kpis.take(3).map((kpi) {
                                      final entries = _kpiEntries[kpi.id] ?? [];
                                      final last = entries.isNotEmpty ? entries.first : null;
                                      final progress = last != null
                                          ? (last.actualValue / kpi.targetValue).clamp(0.0, 1.0)
                                          : 0.0;
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                          Row(children: [
                                            Expanded(child: Text(kpi.name,
                                                style: const TextStyle(
                                                    fontSize: 12, color: _kPrimary),
                                                maxLines: 1, overflow: TextOverflow.ellipsis)),
                                            Text(kpi.reviewPeriod,
                                                style: const TextStyle(
                                                    fontSize: 10, color: _kSecondary)),
                                          ]),
                                          const SizedBox(height: 4),
                                          LinearProgressIndicator(
                                            value: progress,
                                            backgroundColor: Colors.grey.shade200,
                                            valueColor: AlwaysStoppedAnimation(
                                                progress >= 1.0 ? Colors.green : _kPrimary),
                                            minHeight: 3,
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ]),
                                      );
                                    }),
                                  ],
                                ]),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _navCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    int maxSubtitleLines = 2,
    Widget? trailing,
  }) {
    return Card(
      color: _kCard, elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
              color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: _kPrimary, size: 22),
        ),
        title: Text(title,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
        subtitle: Text(subtitle,
            style: const TextStyle(fontSize: 12, color: _kSecondary),
            maxLines: maxSubtitleLines, overflow: TextOverflow.ellipsis),
        trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: _kSecondary),
        onTap: onTap,
      ),
    );
  }

  Widget _chip(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
        child: Text(label, style: const TextStyle(fontSize: 12, color: _kPrimary)),
      );
}
```

- [ ] **Step 3: Analyze**

```bash
flutter analyze lib/myjob/pages/my_job_page.dart
```

---

## Task 12: MyJobDescriptionPage (Employee Read-Only)

**Files:**
- Create: `lib/myjob/pages/my_job_description_page.dart`

- [ ] **Step 1: Create the page**

```dart
// lib/myjob/pages/my_job_description_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/myjob_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);
const Color _kCard = Color(0xFFFFFFFF);

class MyJobDescriptionPage extends StatelessWidget {
  final String token;
  final JobDescription jd;

  const MyJobDescriptionPage({
    super.key,
    required this.token,
    required this.jd,
  });

  Widget _section(String title, Widget child) => Card(
        color: _kCard, elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: _kSecondary)),
            const SizedBox(height: 10),
            child,
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final sw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: const BackButton(color: _kPrimary),
        title: Text(sw ? 'Maelezo ya Kazi' : 'Job Description',
            style: const TextStyle(
                color: _kPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: jd.roleSummary.isEmpty && jd.responsibilities.isEmpty
          ? Center(
              child: Text(
                  sw ? 'Maelezo yako ya kazi hayajawekwa bado.'
                     : "Your job description hasn't been set yet.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade500)),
            )
          : ListView(padding: const EdgeInsets.all(16), children: [
              if (jd.roleSummary.isNotEmpty)
                _section(
                  sw ? 'Muhtasari wa Nafasi' : 'Role Summary',
                  Text(jd.roleSummary,
                      style: const TextStyle(fontSize: 14, color: _kPrimary)),
                ),

              if (jd.responsibilities.isNotEmpty)
                _section(
                  sw ? 'Majukumu' : 'Responsibilities',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(jd.responsibilities.length, (i) =>
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text('${i + 1}. ${jd.responsibilities[i]}',
                              style: const TextStyle(fontSize: 14, color: _kPrimary)),
                        )),
                  ),
                ),

              _section(
                sw ? 'Anaripoti Kwa' : 'Reporting To',
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(jd.reportingTo,
                      style: const TextStyle(fontSize: 13, color: _kPrimary)),
                ),
              ),

              if (jd.updatedAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 16),
                  child: Text(
                      '${sw ? 'Imesasishwa' : 'Last updated'}: ${DateFormat('dd MMM yyyy').format(jd.updatedAt!)}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                ),
            ]),
    );
  }
}
```

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/myjob/pages/my_job_description_page.dart
```

---

## Task 13: MyTasksPage + UpdateTaskSheet

**Files:**
- Create: `lib/myjob/pages/my_tasks_page.dart`
- Create: `lib/myjob/widgets/update_task_sheet.dart`

- [ ] **Step 1: Create UpdateTaskSheet**

```dart
// lib/myjob/widgets/update_task_sheet.dart
import 'package:flutter/material.dart';
import '../models/myjob_models.dart';
import '../services/my_job_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCard = Color(0xFFFFFFFF);

class UpdateTaskSheet extends StatefulWidget {
  final WorkTask task;
  final String token;
  final bool sw;
  final VoidCallback onSaved;

  const UpdateTaskSheet({
    super.key,
    required this.task,
    required this.token,
    required this.sw,
    required this.onSaved,
  });

  @override
  State<UpdateTaskSheet> createState() => _UpdateTaskSheetState();
}

class _UpdateTaskSheetState extends State<UpdateTaskSheet> {
  late String _status;
  late double _progress;
  final _commentCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _status = widget.task.status;
    _progress = widget.task.progress.toDouble();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    final body = {
      'status': _status,
      'progress': _progress.round(),
      if (_commentCtrl.text.trim().isNotEmpty) 'comment': _commentCtrl.text.trim(),
    };
    final res = await MyJobService.postTaskUpdate(widget.token, widget.task.id!, body);
    if (!mounted) return;
    setState(() => _saving = false);
    if (res.success) {
      if (_status == 'done') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.sw ? 'Kazi imekamilika! 🎉' : 'Task complete! 🎉')));
      }
      if (_commentCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(widget.sw
                ? 'Ongeza maelezo mara ijayo kuweka meneja wako ana habari.'
                : 'Add a comment next time to keep your manager informed.')));
      }
      Navigator.pop(context);
      widget.onSaved();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res.message ??
              (widget.sw ? 'Imeshindwa kuhifadhi. Jaribu tena.' : 'Failed to save update. Try again.')),
          backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = widget.sw;
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16, right: 16, top: 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(sw ? 'Sasisha Kazi' : 'Update Task',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: _kPrimary)),
        const SizedBox(height: 4),
        Text(widget.task.title,
            style: const TextStyle(fontSize: 13, color: _kSecondary),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 16),

        // Status
        Text(sw ? 'Hali' : 'Status',
            style: const TextStyle(fontSize: 12, color: _kSecondary)),
        const SizedBox(height: 6),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(
                value: 'pending', label: Text(sw ? 'Haijaanza' : 'Not Started',
                    style: const TextStyle(fontSize: 11))),
            ButtonSegment(
                value: 'in_progress', label: Text(sw ? 'Inaendelea' : 'In Progress',
                    style: const TextStyle(fontSize: 11))),
            ButtonSegment(
                value: 'done', label: Text(sw ? 'Imekamilika' : 'Done',
                    style: const TextStyle(fontSize: 11))),
          ],
          selected: {_status},
          onSelectionChanged: (s) {
            final newStatus = s.first;
            setState(() {
              _status = newStatus;
              if (newStatus == 'done') _progress = 100;
              if (newStatus == 'in_progress' && _progress < 1) _progress = 1;
            });
          },
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) =>
                states.contains(WidgetState.selected) ? _kPrimary : null),
            foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) =>
                states.contains(WidgetState.selected) ? Colors.white : _kPrimary),
          ),
        ),
        const SizedBox(height: 16),

        // Progress slider
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(sw ? 'Maendeleo' : 'Progress',
              style: const TextStyle(fontSize: 12, color: _kSecondary)),
          Text('${_progress.round()}%',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold, color: _kPrimary)),
        ]),
        Slider(
          value: _progress,
          min: 0, max: 100, divisions: 100,
          activeColor: _kPrimary,
          onChanged: (v) => setState(() => _progress = v),
        ),

        // Comment
        TextField(
          controller: _commentCtrl,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: sw ? 'Kuna nini kipya?' : "What's the update?",
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saving ? null : _submit,
            style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary, foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48)),
            child: _saving
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(sw ? 'Hifadhi' : 'Save'),
          ),
        ),
        const SizedBox(height: 16),
      ]),
    );
  }
}
```

- [ ] **Step 2: Create MyTasksPage**

```dart
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

  // Generate 14-day strip centred on today
  late final List<DateTime> _days;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _days = List.generate(
        30, (i) => today.subtract(Duration(days: 7)).add(Duration(days: i)));
    _load(_selectedDate);
  }

  Future<void> _load(DateTime date) async {
    setState(() => _loading = true);
    final res = await MyJobService.getMyTasks(widget.token, date: date);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _standing = res.standingTasks;
      _adhoc = res.adhocTasks;
    });
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
        ? ['Jum', 'Jum', 'Jum', 'Alh', 'Ijm', 'Jum', 'Jum']  // Sat–Fri Swahili abbrev
        : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    // weekday: 1=Mon … 7=Sun
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
        // Day completion ring + date strip
        Container(
          color: _kCard,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(children: [
            // Completion ring
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

            // Date strip
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

        // Task lists
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2))
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
```

- [ ] **Step 3: Analyze both**

```bash
flutter analyze lib/myjob/widgets/update_task_sheet.dart lib/myjob/pages/my_tasks_page.dart
```

---

## Task 14: MyKpisPage (Employee Read-Only)

**Files:**
- Create: `lib/myjob/pages/my_kpis_page.dart`

- [ ] **Step 1: Create the page**

```dart
// lib/myjob/pages/my_kpis_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../team/widgets/kpi_sparkline_chart.dart';
import '../models/myjob_models.dart';
import '../services/my_job_service.dart';
import '../../team/services/work_service.dart' show WorkListResult;

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);
const Color _kCard = Color(0xFFFFFFFF);

class MyKpisPage extends StatefulWidget {
  final String token;

  const MyKpisPage({super.key, required this.token});

  @override
  State<MyKpisPage> createState() => _MyKpisPageState();
}

class _MyKpisPageState extends State<MyKpisPage> {
  List<Kpi> _kpis = [];
  final Map<int, List<KpiEntry>> _entries = {};
  final Set<int> _expanded = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await MyJobService.getMyKpis(widget.token);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _kpis = res.data;
    });
    for (final kpi in _kpis) {
      if (kpi.id != null) _loadEntries(kpi.id!);
    }
  }

  Future<void> _loadEntries(int kpiId) async {
    final res = await MyJobService.getMyKpiEntries(widget.token, kpiId);
    if (!mounted) return;
    setState(() => _entries[kpiId] = res.data);
  }

  String _fmt(Kpi kpi, double v) {
    if (kpi.unit == 'TZS') {
      return 'TZS ${v.round()}';
    }
    return '${v == v.roundToDouble() ? v.round() : v.toStringAsFixed(1)} ${kpi.unit}';
  }

  String _trendLabel(List<KpiEntry> entries, double target) {
    if (entries.length < 2) return '→';
    final last3 = entries.take(3).map((e) => e.actualValue).toList();
    if (last3.length < 2) return '→';
    double sum = 0;
    for (int i = 0; i < last3.length - 1; i++) {
      sum += last3[i] - last3[i + 1];
    }
    if (sum > 0) return '↑';
    if (sum < 0) return '↓';
    return '→';
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
        title: Text(sw ? 'Viashiria Vyangu' : 'My KPIs',
            style: const TextStyle(
                color: _kPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2))
          : _kpis.isEmpty
              ? Center(
                  child: Text(
                      sw ? 'Hakuna malengo ya KPI bado. Meneja wako ataongeza.'
                         : 'No KPI targets set yet. Your manager will add them.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade400)),
                )
              : RefreshIndicator(
                  color: _kPrimary,
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _kpis.length,
                    itemBuilder: (_, i) {
                      final kpi = _kpis[i];
                      final entries = _entries[kpi.id] ?? [];
                      final isExpanded = _expanded.contains(kpi.id);
                      final lastEntry = entries.isNotEmpty ? entries.first : null;
                      final delta = entries.length >= 2
                          ? entries[0].actualValue - entries[1].actualValue
                          : null;
                      final trend = _trendLabel(entries, kpi.targetValue);

                      return Card(
                        color: _kCard, elevation: 0,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => setState(() {
                            isExpanded
                                ? _expanded.remove(kpi.id)
                                : _expanded.add(kpi.id!);
                          }),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Expanded(child: Text(kpi.name,
                                    style: const TextStyle(
                                        fontSize: 14, fontWeight: FontWeight.w600,
                                        color: _kPrimary),
                                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                                Text(trend, style: TextStyle(
                                    fontSize: 16,
                                    color: trend == '↑' ? Colors.green
                                        : trend == '↓' ? Colors.red
                                        : _kSecondary)),
                              ]),
                              const SizedBox(height: 4),
                              Wrap(spacing: 6, children: [
                                _chip('${sw ? 'Lengo' : 'Target'}: ${_fmt(kpi, kpi.targetValue)}'),
                                _chip(sw
                                    ? (kpi.reviewPeriod == 'monthly' ? 'Kila Mwezi'
                                        : kpi.reviewPeriod == 'quarterly' ? 'Kila Robo' : 'Kila Mwaka')
                                    : (kpi.reviewPeriod == 'monthly' ? 'Monthly'
                                        : kpi.reviewPeriod == 'quarterly' ? 'Quarterly' : 'Annual')),
                              ]),
                              if (lastEntry != null) ...[
                                const SizedBox(height: 8),
                                Row(children: [
                                  Expanded(child: LinearProgressIndicator(
                                    value: (lastEntry.actualValue / kpi.targetValue).clamp(0, 1),
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation(
                                        lastEntry.actualValue >= kpi.targetValue
                                            ? Colors.green : Colors.red),
                                    minHeight: 4,
                                    borderRadius: BorderRadius.circular(2),
                                  )),
                                  const SizedBox(width: 8),
                                  Text(_fmt(kpi, lastEntry.actualValue),
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: lastEntry.actualValue >= kpi.targetValue
                                              ? Colors.green : Colors.red,
                                          fontWeight: FontWeight.w600)),
                                  if (delta != null) ...[
                                    const SizedBox(width: 4),
                                    Text('${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)}',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: delta >= 0 ? Colors.green : Colors.red)),
                                  ],
                                ]),
                                Text(
                                    '${sw ? 'Imesasishwa mwisho' : 'Last updated'}: ${lastEntry.periodLabel}',
                                    style: const TextStyle(fontSize: 11, color: _kSecondary)),
                              ],

                              // Expanded history
                              if (isExpanded && entries.isNotEmpty) ...[
                                const Divider(height: 16),
                                SizedBox(
                                  height: 80,
                                  child: KpiSparklineChart(
                                      entries: entries.reversed.take(6).toList().reversed.toList(),
                                      target: kpi.targetValue),
                                ),
                                const SizedBox(height: 8),
                                ...entries.map((e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(children: [
                                    Expanded(child: Text(e.periodLabel,
                                        style: const TextStyle(fontSize: 12, color: _kPrimary))),
                                    Text(_fmt(kpi, e.actualValue),
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: e.actualValue >= kpi.targetValue
                                                ? Colors.green : Colors.red)),
                                  ]),
                                )),
                              ],

                              // Manager-only note
                              if (!isExpanded) ...[
                                const SizedBox(height: 4),
                                Text(
                                    sw ? 'Meneja wako anasasisha thamani za KPI.'
                                       : 'Your manager updates KPI values.',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                              ],
                            ]),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _chip(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
        child: Text(label, style: const TextStyle(fontSize: 11, color: _kPrimary)),
      );
}
```

**Note:** `KpiSparklineChart` was already extracted to `lib/team/widgets/kpi_sparkline_chart.dart` in Part 2 Task 7 Steps 2–4. The import at the top of this file already references it correctly.

- [ ] **Step 2: Confirm KpiSparklineChart widget file exists**

```bash
flutter analyze lib/team/widgets/kpi_sparkline_chart.dart
```

Expected: No issues. If the file is missing, complete Part 2 Task 7 Steps 2–4 first.

- [ ] **Step 3: Analyze**

```bash
flutter analyze lib/myjob/pages/my_kpis_page.dart
```

---

## Task 15: myjob.dart Barrel

**Files:**
- Create: `lib/myjob/myjob.dart`

- [ ] **Step 1: Create barrel**

```dart
// lib/myjob/myjob.dart
export 'models/myjob_models.dart';
export 'pages/my_job_page.dart' show MyJobPage;
export 'pages/my_job_description_page.dart' show MyJobDescriptionPage;
export 'pages/my_tasks_page.dart' show MyTasksPage;
export 'pages/my_kpis_page.dart' show MyKpisPage;
export 'services/my_job_service.dart' show MyJobService;
```

---

## Task 16: Update EmployeeDetailPage — Work Profile + Tasks Cards

**Files:**
- Modify: `lib/team/pages/employee_detail_page.dart`

- [ ] **Step 1: Add imports at top of file (after existing imports)**

Add to the import block:
```dart
import '../models/work_models.dart';
import '../models/task_models.dart';
import '../services/work_service.dart';
import 'job_description_page.dart';
import 'employee_tasks_page.dart';
```

- [ ] **Step 2: Add state fields to `_EmployeeDetailPageState`**

After `List<HrAction> _hrActions = [];`, add:
```dart
JobDescription? _jobDescription;
List<Kpi> _kpis = [];
Map<int, KpiEntry?> _latestKpiEntry = {}; // latest entry per KPI for on-track check
List<WorkTask> _recentTasks = [];
```

- [ ] **Step 3: Update `_load()` to also fetch work data**

Replace the existing `_load()` body with:
```dart
Future<void> _load() async {
  if (!mounted) return;
  setState(() { _loading = true; _error = null; });
  try {
    final results = await Future.wait([
      TeamService.getEmployee(widget.token, widget.employeeId),
      TeamService.getHrActions(widget.token, widget.employeeId),
      WorkService.getJobDescription(widget.token, widget.employeeId),
      WorkService.getKpis(widget.token, widget.employeeId),
      WorkService.getEmployeeTasks(widget.token, widget.employeeId),
    ]);
    if (!mounted) return;
    final empRes = results[0] as dynamic;
    final actRes = results[1] as dynamic;
    final jdRes = results[2] as WorkResult<JobDescription>;
    final kpiRes = results[3] as WorkListResult<Kpi>;
    final taskRes = results[4] as WorkListResult<WorkTask>;
    setState(() {
      _loading = false;
      if (empRes.success) _employee = empRes.data;
      else _error = empRes.message ?? 'Failed to load';
      if (actRes.success) _hrActions = actRes.data as List<HrAction>;
      _jobDescription = jdRes.data;
      _kpis = kpiRes.data;
      _recentTasks = taskRes.data.take(3).toList();
    });
    // Load latest entry per KPI for on-track/below-target display
    for (final kpi in _kpis) {
      if (kpi.id != null) _loadLatestEntry(kpi.id!);
    }
  } catch (e) {
    if (!mounted) return;
    setState(() { _loading = false; _error = e.toString(); });
  }
}

Future<void> _loadLatestEntry(int kpiId) async {
  final res = await WorkService.getKpiEntries(widget.token, kpiId);
  if (!mounted) return;
  setState(() => _latestKpiEntry[kpiId] = res.data.isNotEmpty ? res.data.first : null);
}
```

- [ ] **Step 4: Add `_workProfileCard` and `_tasksCard` helper methods**

Add these methods before `build()`:

```dart
Widget _workProfileCard(Employee emp, bool sw) {
  final hasJd = _jobDescription != null && _jobDescription!.roleSummary.isNotEmpty;
  // Compute on-track vs below-target counts from latest entries
  int onTrack = 0, belowTarget = 0;
  for (final kpi in _kpis) {
    if (kpi.id == null) continue;
    final entry = _latestKpiEntry[kpi.id];
    if (entry == null) continue;
    if (entry.actualValue >= kpi.targetValue) onTrack++;
    else belowTarget++;
  }
  return Card(
    color: _kCardBg,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel(sw ? 'Wasifu wa Kazi' : 'Work Profile'),
        const SizedBox(height: 8),
        if (hasJd) ...[
          Text(_jobDescription!.roleSummary,
              style: const TextStyle(fontSize: 13, color: _kPrimary),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
        ] else ...[
          Text(sw ? 'Haijawekwa' : 'Not set',
              style: const TextStyle(
                  fontSize: 13, color: _kSecondary, fontStyle: FontStyle.italic)),
          const SizedBox(height: 6),
        ],
        Row(children: [
          if (_kpis.isNotEmpty) ...[
            if (onTrack > 0)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12)),
                child: Text('$onTrack ${sw ? 'kwenye lengo' : 'on track'}',
                    style: TextStyle(fontSize: 11, color: Colors.green.shade700)),
              ),
            if (belowTarget > 0)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12)),
                child: Text('$belowTarget ${sw ? 'chini ya lengo' : 'below target'}',
                    style: TextStyle(fontSize: 11, color: Colors.red.shade700)),
              ),
            if (onTrack == 0 && belowTarget == 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12)),
                child: Text('${_kpis.length} KPI${_kpis.length == 1 ? '' : 's'}',
                    style: const TextStyle(fontSize: 11, color: _kPrimary)),
              ),
            const SizedBox(width: 4),
          ],
          const Spacer(),
          OutlinedButton(
            onPressed: () {
              if (emp.id == null) return;
              Navigator.push(context, MaterialPageRoute(
                  builder: (_) => JobDescriptionPage(
                        employeeId: emp.id!,
                        businessId: widget.businessId,
                        employeeName: emp.name,
                        ownerName: emp.name, // fallback; ideally pass owner name
                        token: widget.token,
                      ))).then((_) => _load());
            },
            style: OutlinedButton.styleFrom(
                foregroundColor: _kPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                textStyle: const TextStyle(fontSize: 12)),
            child: Text(sw ? 'Tazama / Hariri' : 'View / Edit'),
          ),
        ]),
      ]),
    ),
  );
}

Widget _tasksCard(Employee emp, bool sw) {
  final pending = _recentTasks.where((t) => t.status == 'pending').length;
  final inProg = _recentTasks.where((t) => t.status == 'in_progress').length;
  final done = _recentTasks.where((t) => t.status == 'done').length;
  return Card(
    color: _kCardBg,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: _sectionLabel(sw ? 'Kazi' : 'Tasks')),
          TextButton(
            onPressed: () {
              if (emp.id == null) return;
              Navigator.push(context, MaterialPageRoute(
                  builder: (_) => EmployeeTasksPage(
                        employeeId: emp.id!,
                        businessId: widget.businessId,
                        employeeName: emp.name,
                        token: widget.token,
                      ))).then((_) => _load());
            },
            style: TextButton.styleFrom(
                foregroundColor: _kPrimary,
                textStyle: const TextStyle(fontSize: 12)),
            child: Text(sw ? 'Tazama Zote / Gawanya' : 'See All / Assign'),
          ),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          _chip('${sw ? 'Inasubiri' : 'Pending'} ($pending)'),
          _chip('${sw ? 'Inaendelea' : 'In Progress'} ($inProg)'),
          _chip('${sw ? 'Imekamilika' : 'Done'} ($done)'),
        ]),
      ]),
    ),
  );
}
```

- [ ] **Step 5: Insert the two cards into the ListView in `build()`**

In the `ListView` children list, after the Compensation card (`const SizedBox(height: 12)` after compensation) and before the HR Actions card, add:
```dart
const SizedBox(height: 12),
_workProfileCard(emp, sw),
const SizedBox(height: 12),
_tasksCard(emp, sw),
```

- [ ] **Step 6: Analyze**

```bash
flutter analyze lib/team/pages/employee_detail_page.dart
```

---

## Task 17: Update team.dart Barrel

**Files:**
- Modify: `lib/team/team.dart`

- [ ] **Step 1: Add exports**

Replace the full file content with:
```dart
// lib/team/team.dart
export 'models/team_models.dart';
export 'models/work_models.dart';
export 'models/task_models.dart';
export 'pages/employee_detail_page.dart' show EmployeeDetailPage;
export 'pages/employees_page.dart' show EmployeesPage;
export 'pages/job_description_page.dart' show JobDescriptionPage;
export 'pages/kpi_detail_page.dart' show KpiDetailPage;
export 'pages/employee_tasks_page.dart' show EmployeeTasksPage;
export 'pages/task_detail_page.dart' show TaskDetailPage;
export 'pages/work_board_page.dart' show WorkBoardPage;
export 'services/compensation_service.dart' show CompensationService;
export 'services/team_service.dart' show TeamService, TeamResult, TeamListResult;
export 'services/work_service.dart' show WorkService, WorkResult, WorkListResult;
export 'widgets/add_work_task_sheet.dart' show AddWorkTaskSheet;
export 'widgets/kpi_sparkline_chart.dart' show KpiSparklineChart;
```

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/team/team.dart
```

---

## Task 18: Wire Navigation in profile_screen.dart + Add Tab Config

**Files:**
- Modify: `lib/screens/profile/profile_screen.dart`
- Modify: `lib/models/profile_tab_config.dart`

- [ ] **Step 1: Add imports to profile_screen.dart**

Find the existing imports block and add:
```dart
import '../../myjob/myjob.dart';
import '../../team/team.dart' show WorkBoardPage;
```

- [ ] **Step 2: Add `my_job` case to the tab switch**

In the large `switch` statement that handles tab IDs (near line 2210 where `biz_employees` is handled), add after the `biz_payroll` case:

```dart
case 'my_job':
  return FutureBuilder<String?>(
    future: LocalStorageService().getToken(),
    builder: (ctx, snap) {
      if (!snap.hasData || snap.data == null) return const SizedBox.shrink();
      return MyJobPage(token: snap.data!);
    },
  );
case 'biz_board':
  return BizTabWrapper(userId: userId, builder: (uid, all, first, fId) =>
      fId != null
          ? FutureBuilder<String?>(
              future: LocalStorageService().getToken(),
              builder: (ctx, snap) {
                if (!snap.hasData || snap.data == null) return const SizedBox.shrink();
                return WorkBoardPage(businessId: fId, token: snap.data!);
              },
            )
          : const SizedBox.shrink());
```

- [ ] **Step 3: Add `my_job` and `biz_board` to ProfileTabDefaults**

In `lib/models/profile_tab_config.dart`, in the `defaultTabs` list, add these entries:

In the **Commerce** section (after `tajirika`):
```dart
ProfileTabConfig(id: 'my_job', label: 'My Job', icon: 'work_outline', enabled: true, order: 12),
```

In the **Business** section (after `biz_accounting`):
```dart
ProfileTabConfig(id: 'biz_board', label: 'Work Board', icon: 'dashboard', enabled: true, order: 47),
```

In `categories`, add `'my_job'` to the `commerce` category tabIds list and `'biz_board'` to the `work` category tabIds list.

- [ ] **Step 4: Analyze**

```bash
flutter analyze lib/screens/profile/profile_screen.dart lib/models/profile_tab_config.dart
```

- [ ] **Step 5: Full project analyze**

```bash
flutter analyze
```

Fix any remaining issues. Common ones:
- Unused imports
- Missing `const` keywords
- Wrong type casts (use `as WorkListResult<WorkTask>` etc.)

- [ ] **Step 6: Final commit**

```bash
git add lib/myjob/ lib/team/team.dart lib/team/pages/employee_detail_page.dart \
        lib/screens/profile/profile_screen.dart lib/models/profile_tab_config.dart
git commit -m "feat(myjob): add employee My Job module and wire all navigation"
```

---

## Summary

After all three parts are complete:

| What | Where |
|---|---|
| Manager: Job description | Employee Detail → Work Profile → JobDescriptionPage |
| Manager: KPIs | JobDescriptionPage → KpiDetailPage |
| Manager: Task assignment | Employee Detail → Tasks card → EmployeeTasksPage + AddWorkTaskSheet |
| Manager: Work board | Profile → Business section → Work Board tab → WorkBoardPage |
| Employee: My Job home | Profile → Commerce → My Job tab → MyJobPage |
| Employee: Role view | MyJobPage → MyJobDescriptionPage |
| Employee: Daily tasks | MyJobPage → MyTasksPage → UpdateTaskSheet |
| Employee: KPI tracker | MyJobPage → MyKpisPage |
