// lib/tra/pages/tra_home_page.dart
import 'package:flutter/material.dart';
import '../models/tra_models.dart';
import '../services/tra_service.dart';
import 'tax_calculator_page.dart';
import 'payment_history_page.dart';
import 'deadline_calendar_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class TraHomePage extends StatefulWidget {
  final int userId;
  const TraHomePage({super.key, required this.userId});
  @override
  State<TraHomePage> createState() => _TraHomePageState();
}

class _TraHomePageState extends State<TraHomePage> {
  TaxProfile? _profile;
  List<TaxDeadline> _deadlines = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      TraService.getCompliance(),
      TraService.getDeadlines(),
    ]);
    if (!mounted) return;
    setState(() {
      _loading = false;
      final profileR = results[0] as SingleResult<TaxProfile>;
      if (profileR.success) _profile = profileR.data;
      final dlR = results[1] as PaginatedResult<TaxDeadline>;
      if (dlR.success) _deadlines = dlR.items;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
        onRefresh: _load, color: _kPrimary,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // TIN Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Icon(Icons.receipt_long_rounded, color: Colors.white, size: 24),
                  SizedBox(width: 8),
                  Text('Mamlaka ya Mapato Tanzania',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 12),
                if (_profile != null) ...[
                  Text('TIN: ${_profile!.tin}',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 2)),
                  if (_profile!.ownerName != null)
                    Text(_profile!.ownerName!,
                        style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _profile!.isCompliant ? const Color(0xFF4CAF50) : Colors.orange,
                      borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      _profile!.isCompliant ? 'Compliant' : 'Pending',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ] else
                  const Text('TIN: ---',
                      style: TextStyle(color: Colors.white54, fontSize: 16)),
              ]),
            ),
            const SizedBox(height: 20),

            // Quick actions
            Row(children: [
              _ActionTile(icon: Icons.calculate_rounded, label: 'Hesabu\nKodi',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const TaxCalculatorPage()))),
              const SizedBox(width: 10),
              _ActionTile(icon: Icons.history_rounded, label: 'Historia ya\nMalipo',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const PaymentHistoryPage()))),
              const SizedBox(width: 10),
              _ActionTile(icon: Icons.calendar_month_rounded, label: 'Tarehe za\nMwisho',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const DeadlineCalendarPage()))),
            ]),
            const SizedBox(height: 24),

            // Upcoming deadlines
            if (_deadlines.isNotEmpty) ...[
              const Text('Tarehe za Mwisho Zinazokuja',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary)),
              const SizedBox(height: 10),
              ..._deadlines.take(3).map((d) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: d.isOverdue ? Colors.red.withValues(alpha: 0.1)
                          : _kPrimary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.event_rounded, size: 20,
                        color: d.isOverdue ? Colors.red : _kPrimary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(d.taxType, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(d.period, style: const TextStyle(fontSize: 11, color: _kSecondary)),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('${d.dueDate.day}/${d.dueDate.month}/${d.dueDate.year}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary)),
                    Text(d.isOverdue ? 'Imechelewa' : '${d.daysUntilDue} siku',
                        style: TextStyle(fontSize: 11,
                            color: d.isOverdue ? Colors.red : _kSecondary)),
                  ]),
                ]),
              )),
            ],
            if (_loading)
              const Padding(padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))),
            const SizedBox(height: 32),
          ],
        ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Material(
      color: Colors.white, borderRadius: BorderRadius.circular(12),
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(children: [
            Container(padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: Icon(icon, size: 22, color: _kPrimary)),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kPrimary),
                textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
          ]),
        ),
      ),
    ));
  }
}
