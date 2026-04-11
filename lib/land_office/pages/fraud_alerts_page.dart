// lib/land_office/pages/fraud_alerts_page.dart
import 'package:flutter/material.dart';
import '../models/land_office_models.dart';
import '../services/land_office_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class FraudAlertsPage extends StatefulWidget {
  const FraudAlertsPage({super.key});
  @override
  State<FraudAlertsPage> createState() => _FraudAlertsPageState();
}

class _FraudAlertsPageState extends State<FraudAlertsPage> {
  List<FraudAlert> _alerts = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await LandOfficeService.getFraudAlerts();
    if (!mounted) return;
    setState(() { _loading = false; if (result.success) _alerts = result.items; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(title: const Text('Tahadhari za Udanganyifu',
          style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: _kPrimary)),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _alerts.isEmpty
              ? const Center(child: Text('Hakuna tahadhari', style: TextStyle(color: _kSecondary)))
              : RefreshIndicator(onRefresh: _load, color: _kPrimary,
                  child: ListView.separated(padding: const EdgeInsets.all(16),
                    itemCount: _alerts.length, separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final a = _alerts[i];
                      return Container(padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.2))),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            const Icon(Icons.warning_rounded, size: 20, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Kiwanja #${a.plotNumber}',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary),
                                maxLines: 1, overflow: TextOverflow.ellipsis)),
                            Text('${a.reportedAt.day}/${a.reportedAt.month}/${a.reportedAt.year}',
                                style: const TextStyle(fontSize: 11, color: _kSecondary)),
                          ]),
                          const SizedBox(height: 6),
                          if (a.location != null)
                            Text('Eneo: ${a.location}', style: const TextStyle(fontSize: 12, color: _kSecondary)),
                          Text(a.description, style: const TextStyle(fontSize: 13, color: _kPrimary),
                              maxLines: 3, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                            child: Text(a.alertType, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.red))),
                        ]));
                    })),
    );
  }
}
