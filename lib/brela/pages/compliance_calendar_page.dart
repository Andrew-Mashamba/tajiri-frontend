// lib/brela/pages/compliance_calendar_page.dart
import 'package:flutter/material.dart';
import '../models/brela_models.dart';
import '../services/brela_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class ComplianceCalendarPage extends StatefulWidget {
  const ComplianceCalendarPage({super.key});
  @override
  State<ComplianceCalendarPage> createState() => _ComplianceCalendarPageState();
}

class _ComplianceCalendarPageState extends State<ComplianceCalendarPage> {
  List<ComplianceItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final biz = await BrelaService.getMyBusinesses();
    if (!mounted) return;
    if (biz.success && biz.items.isNotEmpty) {
      final comp = await BrelaService.getComplianceItems(biz.items.first.id);
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (comp.success) _items = comp.items;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'overdue': return Colors.red;
      case 'due': return Colors.orange;
      case 'completed': return const Color(0xFF4CAF50);
      default: return _kSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Kalenda ya Compliance',
            style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white, elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _items.isEmpty
              ? const Center(child: Text('Hakuna vipengele vya compliance',
                  style: TextStyle(color: _kSecondary)))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final c = _items[i];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        Container(width: 4, height: 40,
                          decoration: BoxDecoration(color: _statusColor(c.status), borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(c.type, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('${c.dueDate.day}/${c.dueDate.month}/${c.dueDate.year}',
                              style: const TextStyle(fontSize: 12, color: _kSecondary)),
                        ])),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusColor(c.status).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6)),
                          child: Text(c.status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                              color: _statusColor(c.status))),
                        ),
                      ]),
                    );
                  },
                ),
    );
  }
}
