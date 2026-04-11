// lib/shule_ya_jumapili/pages/attendance_page.dart
import 'package:flutter/material.dart';
import '../models/shule_ya_jumapili_models.dart';
import '../services/shule_ya_jumapili_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});
  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  List<AttendanceRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final r = await ShuleYaJumapiliService.getAttendance();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (r.success) _records = r.items;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mahudhurio',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Text('Attendance',
                style: TextStyle(fontSize: 12, color: _kSecondary)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _kPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _records.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.checklist_rounded, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text('Hakuna rekodi / No records',
                          style: TextStyle(color: _kSecondary, fontSize: 14)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: _kPrimary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _records.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final rec = _records[i];
                      final percent = rec.totalChildren > 0
                          ? (rec.presentCount / rec.totalChildren * 100).round()
                          : 0;
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text('$percent%',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(rec.className,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                  Text(rec.date,
                                      style: const TextStyle(fontSize: 12, color: _kSecondary)),
                                ],
                              ),
                            ),
                            Text('${rec.presentCount}/${rec.totalChildren}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _kPrimary)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
