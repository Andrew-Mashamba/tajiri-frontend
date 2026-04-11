// lib/fitness/pages/my_memberships_page.dart
import 'package:flutter/material.dart';
import '../models/fitness_models.dart';
import '../services/fitness_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class MyMembershipsPage extends StatefulWidget {
  final int userId;
  const MyMembershipsPage({super.key, required this.userId});
  @override
  State<MyMembershipsPage> createState() => _MyMembershipsPageState();
}

class _MyMembershipsPageState extends State<MyMembershipsPage> {
  final FitnessService _service = FitnessService();
  List<GymMembership> _memberships = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final result = await _service.getMyMemberships(widget.userId);
    if (mounted) setState(() { _isLoading = false; if (result.success) _memberships = result.items; });
  }

  String _fmt(double amount) {
    final parts = amount.toStringAsFixed(0).split('');
    final buffer = StringBuffer();
    for (int i = 0; i < parts.length; i++) { if (i > 0 && (parts.length - i) % 3 == 0) buffer.write(','); buffer.write(parts[i]); }
    return buffer.toString();
  }

  String _fmtDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';

  Future<void> _cancel(GymMembership m) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Ghairi Usajili'),
      content: Text('Una uhakika unataka kughairi usajili wa ${m.gymName}?'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hapana')), FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('Ndiyo'))],
    ));
    if (confirm == true) {
      final result = await _service.cancelMembership(m.id);
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.success ? 'Imeghairiwa' : (result.message ?? 'Imeshindwa')))); if (result.success) _load(); }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(backgroundColor: _kCardBg, elevation: 0, scrolledUnderElevation: 1, title: const Text('Usajili Wangu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _memberships.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.card_membership_rounded, size: 64, color: Colors.grey.shade300), const SizedBox(height: 16),
                  Text('Huna usajili wa gym', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                ]))
              : RefreshIndicator(
                  onRefresh: _load, color: _kPrimary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16), itemCount: _memberships.length,
                    itemBuilder: (context, i) {
                      final m = _memberships[i];
                      final statusColor = m.isActive ? const Color(0xFF4CAF50) : Colors.grey;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(14), border: m.isActive ? Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.3)) : null),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Container(width: 44, height: 44, decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.fitness_center_rounded, size: 22, color: statusColor)),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(m.gymName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary)),
                              Text('TZS ${_fmt(m.amount)}/${m.frequency == 'monthly' ? 'mwezi' : 'mwaka'}', style: const TextStyle(fontSize: 12, color: _kSecondary)),
                            ])),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                              child: Text(m.isActive ? 'Hai' : 'Imeisha', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor)),
                            ),
                          ]),
                          const SizedBox(height: 10),
                          Row(children: [
                            Text('${_fmtDate(m.startDate)} — ${_fmtDate(m.endDate)}', style: const TextStyle(fontSize: 12, color: _kSecondary)),
                            if (m.isActive && m.daysRemaining <= 30) ...[
                              const Spacer(),
                              Text('Siku ${m.daysRemaining} zimebaki', style: TextStyle(fontSize: 11, color: Colors.orange.shade700)),
                            ],
                          ]),
                          if (m.isActive) ...[
                            const SizedBox(height: 10),
                            Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => _cancel(m), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Ghairi Usajili', style: TextStyle(fontSize: 12)))),
                          ],
                        ]),
                      );
                    },
                  ),
                ),
    );
  }
}
