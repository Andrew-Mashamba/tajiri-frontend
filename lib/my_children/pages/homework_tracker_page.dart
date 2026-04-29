// lib/my_children/pages/homework_tracker_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/my_children_models.dart';
import '../models/school_age_models.dart';
import '../services/children_notification_helper.dart';
import '../../calendar/services/calendar_service.dart';
import '../../calendar/models/calendar_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class HomeworkTrackerPage extends StatefulWidget {
  final Child child;
  final int userId;

  const HomeworkTrackerPage({
    super.key,
    required this.child,
    required this.userId,
  });

  @override
  State<HomeworkTrackerPage> createState() => _HomeworkTrackerPageState();
}

class _HomeworkTrackerPageState extends State<HomeworkTrackerPage> {
  bool _isLoading = true;
  List<HomeworkAssignment> _assignments = [];

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? true;

  String get _storageKey =>
      'homework_child_${widget.child.id}';

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_storageKey) ?? [];
      final items = raw.map((s) {
        final map = jsonDecode(s) as Map<String, dynamic>;
        return HomeworkAssignment.fromJson(map);
      }).toList();
      if (!mounted) return;
      setState(() {
        _assignments = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAssignments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw =
          _assignments.map((a) => jsonEncode(a.toJson())).toList();
      await prefs.setStringList(_storageKey, raw);
    } catch (_) {}
  }

  void _addAssignment(HomeworkAssignment assignment) {
    setState(() {
      _assignments.insert(0, assignment);
    });
    _saveAssignments();
    // Schedule homework reminder 1 day before due date
    if (assignment.dueDate.isAfter(DateTime.now())) {
      ChildrenNotificationHelper.scheduleHomeworkReminder(
        widget.child.id,
        widget.child.name,
        assignment.subject,
        assignment.dueDate,
        _sw,
      ).catchError((_) {});
    }
  }

  void _toggleComplete(int index) {
    setState(() {
      final a = _assignments[index];
      _assignments[index] = a.copyWith(
        isCompleted: !a.isCompleted,
        completedAt: !a.isCompleted ? DateTime.now() : null,
      );
    });
    _saveAssignments();
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;
    final now = DateTime.now();

    // Group assignments
    final overdue = <HomeworkAssignment>[];
    final dueToday = <HomeworkAssignment>[];
    final upcoming = <HomeworkAssignment>[];
    final completed = <HomeworkAssignment>[];

    for (final a in _assignments) {
      if (a.isCompleted) {
        completed.add(a);
      } else if (a.isOverdue) {
        overdue.add(a);
      } else if (a.isDueToday) {
        dueToday.add(a);
      } else {
        upcoming.add(a);
      }
    }

    // This week's completion rate
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final thisWeek = _assignments.where((a) {
      return a.dueDate.isAfter(weekStart);
    }).toList();
    final thisWeekDone = thisWeek.where((a) => a.isCompleted).length;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: Text(
          sw ? 'Kazi za Nyumbani' : 'Homework',
          style: const TextStyle(
              color: _kPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _kPrimary,
        onPressed: _showAddDialog,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: _kPrimary))
            : _assignments.isEmpty
                ? Center(
                    child: Text(
                      sw
                          ? 'Hakuna kazi bado. Ongeza kazi.'
                          : 'No assignments yet. Add one.',
                      style:
                          const TextStyle(fontSize: 15, color: _kSecondary),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Subject breakdown
                      _buildSubjectBreakdown(sw),
                      const SizedBox(height: 12),

                      // Completion rate card
                      if (thisWeek.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(14),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: _kCardBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  sw
                                      ? 'Kiwango cha kukamilisha wiki hii'
                                      : "This week's completion rate",
                                  style: const TextStyle(
                                      fontSize: 14, color: _kSecondary),
                                ),
                              ),
                              Text(
                                '${thisWeek.isNotEmpty ? (thisWeekDone * 100 ~/ thisWeek.length) : 0}%',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: _kPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (overdue.isNotEmpty) ...[
                        _sectionHeader(
                            sw ? 'Zilizochelewa' : 'Overdue', Colors.red),
                        ...overdue.asMap().entries.map((e) =>
                            _buildItem(e.value, _assignments.indexOf(e.value),
                                Colors.red.shade50)),
                        const SizedBox(height: 12),
                      ],
                      if (dueToday.isNotEmpty) ...[
                        _sectionHeader(
                            sw ? 'Leo' : 'Due Today', Colors.amber.shade700),
                        ...dueToday.asMap().entries.map((e) =>
                            _buildItem(e.value, _assignments.indexOf(e.value),
                                Colors.amber.shade50)),
                        const SizedBox(height: 12),
                      ],
                      if (upcoming.isNotEmpty) ...[
                        _sectionHeader(
                            sw ? 'Zijazo' : 'Upcoming', _kSecondary),
                        ...upcoming.asMap().entries.map((e) =>
                            _buildItem(e.value,
                                _assignments.indexOf(e.value), _kCardBg)),
                        const SizedBox(height: 12),
                      ],
                      if (completed.isNotEmpty) ...[
                        _sectionHeader(
                            sw ? 'Zilizokamilika' : 'Completed',
                            Colors.green),
                        ...completed.asMap().entries.map((e) =>
                            _buildItem(e.value,
                                _assignments.indexOf(e.value), _kCardBg)),
                      ],

                      // ─── Cross-module links ──────────────
                      const SizedBox(height: 20),
                      Text(
                        sw ? 'Viunganishi' : 'Related',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _kSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildCrossModuleLink(
                        icon: Icons.calendar_month_rounded,
                        label: sw
                            ? 'Weka tarehe za mwisho kwenye kalenda'
                            : 'Sync due dates to calendar',
                        onTap: () => _syncHomeworkToCalendar(),
                      ),
                      _buildCrossModuleLink(
                        icon: Icons.chat_rounded,
                        label: sw
                            ? 'Uliza Shangazi kuhusu msaada wa kazi za nyumbani'
                            : 'Ask Shangazi for homework help',
                        onTap: () => Navigator.pushNamed(context, '/chat/0'),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
      ),
    );
  }

  void _syncHomeworkToCalendar() {
    try {
      final calService = CalendarService();
      for (final a in _assignments) {
        if (a.isCompleted) continue;
        calService.createEvent(CalendarEvent(
          id: 0,
          userId: widget.userId,
          title: '${a.subject}: ${a.title} - ${widget.child.name}',
          date: a.dueDate,
          isAllDay: true,
          source: EventSource.family,
        ));
      }
      if (mounted) {
        final sw = AppStringsScope.of(context)?.isSwahili ?? false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(sw ? 'Imewekwa kwenye kalenda' : 'Synced to calendar')),
        );
      }
    } catch (_) {}
  }

  Widget _buildCrossModuleLink({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kPrimary.withValues(alpha: 0.08)),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: iconColor ?? const Color(0xFF666666)),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A)), maxLines: 1, overflow: TextOverflow.ellipsis)),
          const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF999999)),
        ]),
      ),
    );
  }

  Widget _buildSubjectBreakdown(bool sw) {
    if (_assignments.isEmpty) return const SizedBox.shrink();

    // Count assignments per subject
    final subjectCounts = <String, int>{};
    for (final a in _assignments) {
      subjectCounts[a.subject] = (subjectCounts[a.subject] ?? 0) + 1;
    }
    if (subjectCounts.isEmpty) return const SizedBox.shrink();

    // Sort by count descending
    final sorted = subjectCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sw ? 'Kazi kwa Somo' : 'By Subject',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _kPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: sorted.map((entry) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${entry.key}: ${entry.value}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildItem(HomeworkAssignment a, int index, Color bgColor) {
    final dateStr =
        '${a.dueDate.day}/${a.dueDate.month}/${a.dueDate.year}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => _toggleComplete(index),
        onLongPress: () => _confirmDeleteHomework(index, a.title),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                a.isCompleted
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                color: a.isCompleted ? Colors.green : _kSecondary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _kPrimary,
                        decoration: a.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${a.subject} - $dateStr',
                      style:
                          const TextStyle(fontSize: 12, color: _kSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteHomework(int index, String label) {
    final sw = _sw;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(sw ? 'Futa?' : 'Delete?'),
        content: Text(sw ? 'Futa "$label"?' : 'Delete "$label"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(sw ? 'Hapana' : 'Cancel',
                style: const TextStyle(color: Color(0xFF666666))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _assignments.removeAt(index);
              });
              _saveAssignments();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                    sw ? 'Kazi imefutwa' : 'Assignment deleted'),
              ));
            },
            child: Text(sw ? 'Futa' : 'Delete',
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showAddDialog() {
    final sw = _sw;
    final subjectCtrl = TextEditingController();
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime dueDate = DateTime.now().add(const Duration(days: 1));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
                16, 24, 16, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sw ? 'Ongeza Kazi' : 'Add Assignment',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: subjectCtrl,
                  decoration: InputDecoration(
                    labelText: sw ? 'Somo' : 'Subject',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: sw ? 'Maelezo' : 'Description',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: dueDate,
                      firstDate: DateTime.now(),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setSheetState(() => dueDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 18, color: _kSecondary),
                        const SizedBox(width: 8),
                        Text(
                          '${sw ? "Tarehe ya mwisho" : "Due date"}: '
                          '${dueDate.day}/${dueDate.month}/${dueDate.year}',
                          style: const TextStyle(
                              fontSize: 14, color: _kPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      if (subjectCtrl.text.trim().isEmpty) return;
                      final a = HomeworkAssignment(
                        id: DateTime.now().millisecondsSinceEpoch,
                        childId: widget.child.id,
                        subject: subjectCtrl.text.trim(),
                        title: titleCtrl.text.trim().isNotEmpty
                            ? titleCtrl.text.trim()
                            : subjectCtrl.text.trim(),
                        description: descCtrl.text.trim().isNotEmpty
                            ? descCtrl.text.trim()
                            : null,
                        dueDate: dueDate,
                      );
                      _addAssignment(a);
                      Navigator.of(ctx).pop();
                    },
                    child: Text(sw ? 'Hifadhi' : 'Save'),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }
}
