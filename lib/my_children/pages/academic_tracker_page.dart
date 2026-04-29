// lib/my_children/pages/academic_tracker_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/my_children_models.dart';
import '../models/school_age_models.dart';
import '../services/children_notification_helper.dart';
import '../services/my_children_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class AcademicTrackerPage extends StatefulWidget {
  final Child child;
  final int userId;

  const AcademicTrackerPage({
    super.key,
    required this.child,
    required this.userId,
  });

  @override
  State<AcademicTrackerPage> createState() => _AcademicTrackerPageState();
}

class _AcademicTrackerPageState extends State<AcademicTrackerPage> {
  final MyChildrenService _service = MyChildrenService();

  bool _isLoading = true;
  List<AcademicRecord> _records = [];
  List<AcademicRecord> _previousTermRecords = [];
  String? _token;

  int _selectedYear = DateTime.now().year;
  int _selectedTerm = 1;

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? true;

  @override
  void initState() {
    super.initState();
    _token = LocalStorageService.instanceSync?.getAuthToken();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    if (_token == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await _service.getAcademicRecords(
        _token!,
        widget.child.id,
        year: _selectedYear,
        term: _selectedTerm,
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (result.success) _records = result.items;
      });
      // Fire-and-forget: load previous term and check for grade drops
      _loadPreviousTermAndCheckGrades();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              _sw ? 'Imeshindikana kupakia' : 'Failed to load'),
        ),
      );
    }
  }

  /// Fire-and-forget: load previous term records and alert on grade drops > 10 points.
  Future<void> _loadPreviousTermAndCheckGrades() async {
    if (_token == null || _records.isEmpty) return;
    try {
      // Determine previous term/year
      int prevTerm = _selectedTerm - 1;
      int prevYear = _selectedYear;
      if (prevTerm < 1) {
        prevTerm = 3;
        prevYear = _selectedYear - 1;
      }

      final prevResult = await _service.getAcademicRecords(
        _token!,
        widget.child.id,
        year: prevYear,
        term: prevTerm,
      );
      if (!mounted || !prevResult.success) return;
      _previousTermRecords = prevResult.items;

      // Compare each subject
      for (final current in _records) {
        if (current.score == null) continue;
        final prev = _previousTermRecords
            .where((r) => r.subject == current.subject && r.score != null)
            .toList();
        if (prev.isEmpty) continue;
        final oldScore = prev.first.score!;
        final newScore = current.score!;
        if (oldScore - newScore > 10) {
          ChildrenNotificationHelper.scheduleGradeAlert(
            widget.child.id,
            widget.child.name,
            current.subject,
            oldScore,
            newScore,
            isSwahili: _sw,
          ).catchError((_) {});
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: Text(
          sw ? 'Matokeo ya Shule' : 'Academic Record',
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
        child: Column(
          children: [
            _buildTermYearSelector(sw),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _kPrimary))
                  : RefreshIndicator(
                      color: _kPrimary,
                      onRefresh: _loadRecords,
                      child: _records.isEmpty
                          ? ListView(
                              children: [
                                const SizedBox(height: 120),
                                Center(
                                  child: Text(
                                    sw
                                        ? 'Hakuna matokeo bado'
                                        : 'No results yet',
                                    style: const TextStyle(
                                        color: _kSecondary, fontSize: 15),
                                  ),
                                ),
                              ],
                            )
                          : ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                                _buildAverageCard(sw),
                                const SizedBox(height: 16),
                                _buildTermTrend(sw),
                                const SizedBox(height: 16),
                                ..._records.map((r) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10),
                                      child: _buildSubjectCard(sw, r),
                                    )),

                                // ─── Cross-module links ──────────
                                const SizedBox(height: 16),
                                Text(
                                  sw ? 'Viunganishi' : 'Related',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _kSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Shop study guides for weak subjects
                                if (_weakSubjects.isNotEmpty)
                                  _buildCrossModuleLink(
                                    icon: Icons.shopping_cart_rounded,
                                    label: sw
                                        ? 'Nunua vitabu vya masomo kwa ${_weakSubjects.first}'
                                        : 'Shop study guides for ${_weakSubjects.first}',
                                    onTap: () => Navigator.pushNamed(context, '/home', arguments: {'tab': 'shop'}),
                                  ),
                                _buildCrossModuleLink(
                                  icon: Icons.chat_rounded,
                                  label: sw
                                      ? 'Uliza Shangazi vidokezo vya kusoma'
                                      : 'Ask Shangazi for study tips',
                                  onTap: () => Navigator.pushNamed(context, '/chat/0'),
                                ),
                                const SizedBox(height: 80),
                              ],
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermYearSelector(bool sw) {
    return Container(
      color: _kCardBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Term selector
          DropdownButton<int>(
            value: _selectedTerm,
            underline: const SizedBox.shrink(),
            style: const TextStyle(
                color: _kPrimary, fontSize: 14, fontWeight: FontWeight.w500),
            items: [1, 2, 3]
                .map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(
                          '${sw ? "Muhula" : "Term"} $t'),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                setState(() => _selectedTerm = v);
                _loadRecords();
              }
            },
          ),
          const SizedBox(width: 16),
          // Year selector
          DropdownButton<int>(
            value: _selectedYear,
            underline: const SizedBox.shrink(),
            style: const TextStyle(
                color: _kPrimary, fontSize: 14, fontWeight: FontWeight.w500),
            items: List.generate(5, (i) => DateTime.now().year - i)
                .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                setState(() => _selectedYear = v);
                _loadRecords();
              }
            },
          ),
        ],
      ),
    );
  }

  /// Build a compact term-over-term trend comparison.
  Widget _buildTermTrend(bool sw) {
    if (_previousTermRecords.isEmpty || _records.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentScored = _records.where((r) => r.score != null).toList();
    final prevScored = _previousTermRecords.where((r) => r.score != null).toList();
    if (currentScored.isEmpty || prevScored.isEmpty) return const SizedBox.shrink();

    final currentAvg = currentScored.map((r) => r.score!).reduce((a, b) => a + b) / currentScored.length;
    final prevAvg = prevScored.map((r) => r.score!).reduce((a, b) => a + b) / prevScored.length;
    final diff = currentAvg - prevAvg;
    final isUp = diff >= 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            color: isUp ? const Color(0xFF4CAF50) : Colors.red,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              sw
                  ? 'Muhula uliopita: ${prevAvg.toStringAsFixed(1)}% \u2192 Sasa: ${currentAvg.toStringAsFixed(1)}%'
                  : 'Previous term: ${prevAvg.toStringAsFixed(1)}% \u2192 Now: ${currentAvg.toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 13, color: _kSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isUp ? "+" : ""}${diff.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isUp ? const Color(0xFF4CAF50) : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAverageCard(bool sw) {
    final scored = _records.where((r) => r.score != null).toList();
    if (scored.isEmpty) return const SizedBox.shrink();
    final avg =
        scored.map((r) => r.score!).reduce((a, b) => a + b) / scored.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            sw ? 'Wastani wa Jumla' : 'Overall Average',
            style: const TextStyle(fontSize: 15, color: _kSecondary),
          ),
          const SizedBox(width: 16),
          Text(
            avg.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: _kPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(bool sw, AcademicRecord record) {
    return GestureDetector(
      onTap: () => _showEditDialog(record),
      onLongPress: () => _confirmDeleteRecord(record.id, record.subject),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.subject,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (record.teacherNotes != null &&
                      record.teacherNotes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      record.teacherNotes!,
                      style: const TextStyle(fontSize: 12, color: _kSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (record.grade != null)
                  Text(
                    record.grade!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary,
                    ),
                  ),
                if (record.score != null)
                  Text(
                    '${record.score!.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: record.grade != null ? 13 : 18,
                      fontWeight: FontWeight.w500,
                      color: record.grade != null ? _kSecondary : _kPrimary,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog() => _showRecordForm(null);

  void _showEditDialog(AcademicRecord record) => _showRecordForm(record);

  void _showRecordForm(AcademicRecord? existingRecord) {
    final sw = _sw;
    final existing = existingRecord;
    final isEdit = existing != null;
    final subjectCtrl = TextEditingController(text: existing?.subject ?? '');
    final gradeCtrl = TextEditingController(text: existing?.grade ?? '');
    final scoreCtrl = TextEditingController(
        text: existing?.score != null
            ? existing!.score!.toStringAsFixed(0)
            : '');
    final notesCtrl =
        TextEditingController(text: existing?.teacherNotes ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
              16, 24, 16, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit
                    ? (sw ? 'Hariri Matokeo' : 'Edit Result')
                    : (sw ? 'Ongeza Matokeo' : 'Add Result'),
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: subjectCtrl,
                enabled: !isEdit,
                decoration: InputDecoration(
                  labelText: sw ? 'Somo' : 'Subject',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: gradeCtrl,
                      decoration: InputDecoration(
                        labelText: sw ? 'Daraja' : 'Grade',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: scoreCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: sw ? 'Alama (%)' : 'Score (%)',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                decoration: InputDecoration(
                  labelText: sw ? 'Maoni ya Mwalimu' : 'Teacher Notes',
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
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
                    if (isEdit) {
                      _submitUpdateRecord(
                        ctx,
                        existing.id,
                        gradeCtrl.text.trim(),
                        scoreCtrl.text.trim(),
                        notesCtrl.text.trim(),
                      );
                    } else {
                      _submitRecord(
                        ctx,
                        subjectCtrl.text.trim(),
                        gradeCtrl.text.trim(),
                        scoreCtrl.text.trim(),
                        notesCtrl.text.trim(),
                      );
                    }
                  },
                  child: Text(isEdit
                      ? (sw ? 'Sasisha' : 'Update')
                      : (sw ? 'Hifadhi' : 'Save')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitRecord(BuildContext ctx, String subject, String grade,
      String scoreStr, String notes) async {
    if (subject.isEmpty || _token == null) return;

    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(ctx).pop();

    try {
      final result = await _service.addAcademicRecord(
        token: _token!,
        childId: widget.child.id,
        term: _selectedTerm,
        year: _selectedYear,
        subject: subject,
        grade: grade.isNotEmpty ? grade : null,
        score: double.tryParse(scoreStr),
        teacherNotes: notes.isNotEmpty ? notes : null,
      );
      if (!mounted) return;
      if (result.success) {
        _loadRecords();
        messenger.showSnackBar(
          SnackBar(
            content:
                Text(_sw ? 'Matokeo yamehifadhiwa' : 'Result saved'),
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(result.message ?? 'Error')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content:
              Text(_sw ? 'Imeshindikana kuhifadhi' : 'Failed to save'),
        ),
      );
    }
  }

  Future<void> _submitUpdateRecord(BuildContext ctx, int recordId,
      String grade, String scoreStr, String notes) async {
    if (_token == null) return;

    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(ctx).pop();

    try {
      final result = await _service.updateAcademicRecord(
        token: _token!,
        recordId: recordId,
        grade: grade.isNotEmpty ? grade : null,
        score: double.tryParse(scoreStr),
        teacherNotes: notes.isNotEmpty ? notes : null,
      );
      if (!mounted) return;
      if (result.success) {
        _loadRecords();
        messenger.showSnackBar(
          SnackBar(
            content:
                Text(_sw ? 'Matokeo yamesasishwa' : 'Result updated'),
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(result.message ?? 'Error')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content:
              Text(_sw ? 'Imeshindikana kusasisha' : 'Failed to update'),
        ),
      );
    }
  }

  void _confirmDeleteRecord(int id, String label) {
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
            onPressed: () async {
              Navigator.pop(ctx);
              if (_token == null) return;
              final messenger = ScaffoldMessenger.of(context);
              try {
                final result =
                    await _service.deleteAcademicRecord(_token!, id);
                if (!mounted) return;
                if (result.success) {
                  _loadRecords();
                  messenger.showSnackBar(SnackBar(
                    content: Text(
                        sw ? 'Matokeo yamefutwa' : 'Record deleted'),
                  ));
                } else {
                  messenger.showSnackBar(SnackBar(
                      content: Text(result.message ?? 'Error')));
                }
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(SnackBar(
                  content: Text(
                      sw ? 'Imeshindikana kufuta' : 'Failed to delete'),
                ));
              }
            },
            child: Text(sw ? 'Futa' : 'Delete',
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  /// Subjects with score below 50%
  List<String> get _weakSubjects =>
      _records
          .where((r) => r.score != null && r.score! < 50)
          .map((r) => r.subject)
          .toList();

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
          color: _kCardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kPrimary.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: iconColor ?? const Color(0xFF666666)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 13, color: _kPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: Color(0xFF999999)),
          ],
        ),
      ),
    );
  }
}
