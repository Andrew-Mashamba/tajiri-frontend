// lib/tra/pages/deadline_calendar_page.dart
import 'package:flutter/material.dart';
import '../models/tra_models.dart';
import '../services/tra_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class DeadlineCalendarPage extends StatefulWidget {
  const DeadlineCalendarPage({super.key});
  @override
  State<DeadlineCalendarPage> createState() => _DeadlineCalendarPageState();
}

class _DeadlineCalendarPageState extends State<DeadlineCalendarPage> {
  List<TaxDeadline> _deadlines = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await TraService.getDeadlines();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.success) _deadlines = result.items;
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'overdue': return Colors.red;
      case 'due': return Colors.orange;
      case 'filed': return const Color(0xFF4CAF50);
      default: return _kSecondary;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'overdue': return 'Imechelewa';
      case 'due': return 'Imefikia';
      case 'filed': return 'Imewasilishwa';
      default: return 'Inakuja';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Tarehe za Mwisho',
            style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white, elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : RefreshIndicator(
              onRefresh: _load, color: _kPrimary,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _deadlines.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final d = _deadlines[i];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: _statusColor(d.status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10)),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${d.dueDate.day}',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                                    color: _statusColor(d.status))),
                            Text(_monthAbbrev(d.dueDate.month),
                                style: TextStyle(fontSize: 10, color: _statusColor(d.status))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(d.taxType, style: const TextStyle(fontSize: 14,
                            fontWeight: FontWeight.w600, color: _kPrimary),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(d.period, style: const TextStyle(fontSize: 12, color: _kSecondary)),
                      ])),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(d.status).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6)),
                        child: Text(_statusLabel(d.status),
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                                color: _statusColor(d.status))),
                      ),
                    ]),
                  );
                },
              ),
            ),
    );
  }

  String _monthAbbrev(int m) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[(m - 1).clamp(0, 11)];
  }
}
