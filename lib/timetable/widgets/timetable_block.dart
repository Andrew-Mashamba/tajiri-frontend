// lib/timetable/widgets/timetable_block.dart
import 'package:flutter/material.dart';
import '../models/timetable_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class TimetableBlock extends StatelessWidget {
  final TimetableEntry entry;
  final VoidCallback? onTap;

  const TimetableBlock({super.key, required this.entry, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 50,
              decoration: BoxDecoration(
                color: Color(entry.colorValue != 0 ? entry.colorValue : 0xFF1A1A1A),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(entry.subject, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('${entry.courseCode} · ${entry.lecturer}', style: const TextStyle(fontSize: 12, color: _kSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.access_time_rounded, size: 13, color: _kSecondary),
                  const SizedBox(width: 4),
                  Text('${entry.startTime} - ${entry.endTime}', style: const TextStyle(fontSize: 12, color: _kSecondary)),
                  const SizedBox(width: 12),
                  const Icon(Icons.room_rounded, size: 13, color: _kSecondary),
                  const SizedBox(width: 4),
                  Expanded(child: Text(entry.room, style: const TextStyle(fontSize: 12, color: _kSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
              ]),
            ),
            if (entry.isExam) Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
              child: const Text('MTIHANI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}
