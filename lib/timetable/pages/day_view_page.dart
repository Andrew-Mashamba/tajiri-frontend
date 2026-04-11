// lib/timetable/pages/day_view_page.dart
import 'package:flutter/material.dart';
import '../models/timetable_models.dart';
import '../widgets/timetable_block.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kBg = Color(0xFFFAFAFA);
const Color _kSecondary = Color(0xFF666666);

class DayViewPage extends StatelessWidget {
  final List<TimetableEntry> entries;
  final SchoolDay day;
  const DayViewPage({super.key, required this.entries, required this.day});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: Text(day.displayName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: entries.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.event_available_rounded, size: 48, color: _kSecondary),
                const SizedBox(height: 8),
                const Text('Hakuna kipindi leo / No classes today', style: TextStyle(color: _kSecondary)),
              ]))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: entries.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 50,
                        child: Text(entries[i].startTime, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
                      ),
                      Container(width: 2, height: 80, color: _kPrimary.withValues(alpha: 0.2)),
                      const SizedBox(width: 12),
                      Expanded(child: TimetableBlock(entry: entries[i])),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
