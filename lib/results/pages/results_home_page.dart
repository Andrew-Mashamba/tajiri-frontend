// lib/results/pages/results_home_page.dart
import 'package:flutter/material.dart';
import '../models/results_models.dart';
import '../services/results_service.dart';
import 'semester_view_page.dart';
import 'add_grade_page.dart';
import '../widgets/gpa_card.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class ResultsHomePage extends StatefulWidget {
  final int userId;
  const ResultsHomePage({super.key, required this.userId});
  @override
  State<ResultsHomePage> createState() => _ResultsHomePageState();
}

class _ResultsHomePageState extends State<ResultsHomePage> {
  final ResultsService _service = ResultsService();
  GpaSummary? _summary;
  List<SemesterResult> _semesters = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([_service.getGpaSummary(), _service.getSemesters()]);
    if (mounted) {
      setState(() {
        _isLoading = false;
        final sRes = results[0] as ResultsDataResult<GpaSummary>;
        final semRes = results[1] as ResultsListResult<SemesterResult>;
        if (sRes.success) _summary = sRes.data;
        if (semRes.success) _semesters = semRes.items;
      });
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
                child: ListView(padding: const EdgeInsets.all(16), children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(16)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Row(children: [
                        Icon(Icons.assessment_rounded, color: Colors.white, size: 24),
                        SizedBox(width: 10),
                        Text('Matokeo', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                      ]),
                      const SizedBox(height: 12),
                      if (_summary != null) ...[
                        Text('GPA: ${_summary!.cumulativeGpa.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('Masomo ${_summary!.totalCreditsEarned} / ${_summary!.totalCreditsRequired} credits', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
                        if (_summary!.isDeansList) ...[
                          const SizedBox(height: 6),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(6)),
                            child: const Text("Dean's List", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kPrimary)),
                          ),
                        ],
                      ],
                    ]),
                  ),
                  const SizedBox(height: 16),
                  if (_summary != null) GpaCard(summary: _summary!),
                  const SizedBox(height: 20),
                  const Text('Muhula', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
                  const Text('Semesters', style: TextStyle(fontSize: 12, color: _kSecondary)),
                  const SizedBox(height: 10),
                  if (_semesters.isEmpty)
                    Container(padding: const EdgeInsets.all(32), alignment: Alignment.center, child: const Text('Hakuna matokeo bado / No results yet', style: TextStyle(color: _kSecondary)))
                  else
                    ..._semesters.map((s) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        tileColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        title: Text('${s.semester} ${s.year}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('${s.totalCourses} masomo · ${s.totalCredits} credits', style: const TextStyle(fontSize: 12, color: _kSecondary)),
                        trailing: Text('GPA ${s.gpa.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary)),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SemesterViewPage(semester: s))),
                      ),
                    )),
                ]),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _kPrimary,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddGradePage(userId: widget.userId))).then((_) => _loadData()),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}
