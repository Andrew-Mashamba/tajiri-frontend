// lib/assignments/pages/assignments_home_page.dart
import 'package:flutter/material.dart';
import '../models/assignments_models.dart';
import '../services/assignments_service.dart';
import 'create_assignment_page.dart';
import 'assignment_detail_page.dart';
import '../widgets/assignment_card.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class AssignmentsHomePage extends StatefulWidget {
  final int userId;
  const AssignmentsHomePage({super.key, required this.userId});
  @override
  State<AssignmentsHomePage> createState() => _AssignmentsHomePageState();
}

class _AssignmentsHomePageState extends State<AssignmentsHomePage> {
  final AssignmentsService _service = AssignmentsService();
  List<Assignment> _assignments = [];
  bool _isLoading = true;
  String _filter = 'all'; // all, upcoming, overdue, graded

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final result = await _service.getAssignments();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _assignments = result.items;
      });
    }
  }

  List<Assignment> get _filtered {
    switch (_filter) {
      case 'upcoming':
        return _assignments.where((a) => a.status == AssignmentStatus.notStarted || a.status == AssignmentStatus.inProgress).toList()
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
      case 'overdue':
        return _assignments.where((a) => a.isOverdue).toList();
      case 'graded':
        return _assignments.where((a) => a.status == AssignmentStatus.graded).toList();
      default:
        return _assignments..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
            : RefreshIndicator(
                onRefresh: _loadData,
                color: _kPrimary,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(16)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Row(children: [
                          Icon(Icons.assignment_rounded, color: Colors.white, size: 24),
                          SizedBox(width: 10),
                          Text('Kazi', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                        ]),
                        const SizedBox(height: 6),
                        Text(
                          'Assignments — ${_assignments.where((a) => a.isOverdue).length} zimechelewa',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    // Filter chips
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: ['all', 'upcoming', 'overdue', 'graded'].map((f) {
                          final labels = {'all': 'Zote', 'upcoming': 'Zijazo', 'overdue': 'Zimechelewa', 'graded': 'Zimesahihishwa'};
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(labels[f]!, style: TextStyle(fontSize: 12, color: _filter == f ? Colors.white : _kPrimary)),
                              selected: _filter == f,
                              selectedColor: _kPrimary,
                              backgroundColor: Colors.white,
                              onSelected: (_) => setState(() => _filter = f),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_filtered.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(48),
                        alignment: Alignment.center,
                        child: const Column(children: [
                          Icon(Icons.check_circle_outline_rounded, size: 48, color: _kSecondary),
                          SizedBox(height: 8),
                          Text('Hakuna kazi / No assignments', style: TextStyle(color: _kSecondary, fontSize: 14)),
                        ]),
                      )
                    else
                      ..._filtered.map((a) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: AssignmentCard(
                              assignment: a,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AssignmentDetailPage(assignment: a))),
                            ),
                          )),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _kPrimary,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateAssignmentPage(userId: widget.userId))).then((_) => _loadData()),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}
