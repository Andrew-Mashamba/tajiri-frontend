// lib/results/pages/semester_view_page.dart
import 'package:flutter/material.dart';
import '../models/results_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class SemesterViewPage extends StatelessWidget {
  final SemesterResult semester;
  const SemesterViewPage({super.key, required this.semester});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(backgroundColor: _kBg, foregroundColor: _kPrimary, elevation: 0,
        title: Text('${semester.semester} ${semester.year}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _stat('GPA', semester.gpa.toStringAsFixed(2)),
              _stat('Masomo', '${semester.totalCourses}'),
              _stat('Credits', '${semester.totalCredits}'),
            ]),
          ),
          const SizedBox(height: 16),
          // Course grades table
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.04), borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
                child: const Row(children: [
                  Expanded(flex: 3, child: Text('Somo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary))),
                  Expanded(child: Text('Alama', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary), textAlign: TextAlign.center)),
                  Expanded(child: Text('Credit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary), textAlign: TextAlign.center)),
                ]),
              ),
              ...semester.courses.map((c) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
                child: Row(children: [
                  Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(c.courseName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(c.courseCode, style: const TextStyle(fontSize: 11, color: _kSecondary)),
                  ])),
                  Expanded(child: Text(c.grade, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary), textAlign: TextAlign.center)),
                  Expanded(child: Text('${c.creditHours}', style: const TextStyle(fontSize: 13, color: _kSecondary), textAlign: TextAlign.center)),
                ]),
              )),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(children: [
      Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7))),
    ]);
  }
}
