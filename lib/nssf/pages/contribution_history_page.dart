// lib/nssf/pages/contribution_history_page.dart
import 'package:flutter/material.dart';
import '../models/nssf_models.dart';
import '../services/nssf_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class ContributionHistoryPage extends StatefulWidget {
  const ContributionHistoryPage({super.key});
  @override
  State<ContributionHistoryPage> createState() => _ContributionHistoryPageState();
}

class _ContributionHistoryPageState extends State<ContributionHistoryPage> {
  List<Contribution> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await NssfService.getContributions();
    if (!mounted) return;
    setState(() { _loading = false; if (result.success) _items = result.items; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: _kBg,
      appBar: AppBar(title: const Text('Historia ya Michango',
          style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: _kPrimary)),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _items.isEmpty
              ? const Center(child: Text('Hakuna michango', style: TextStyle(color: _kSecondary)))
              : RefreshIndicator(onRefresh: _load, color: _kPrimary,
                  child: ListView.separated(padding: const EdgeInsets.all(16),
                    itemCount: _items.length, separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final c = _items[i];
                      final total = c.employeeAmount + c.employerAmount;
                      return Container(padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: Row(children: [
                          Container(width: 48, height: 48,
                            decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Text(c.month.substring(0, 3), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _kPrimary)),
                              Text('${c.year}', style: const TextStyle(fontSize: 10, color: _kSecondary)),
                            ])),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            if (c.employerName != null)
                              Text(c.employerName!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text('Mfanyakazi: TZS ${c.employeeAmount.toStringAsFixed(0)}  |  Mwajiri: TZS ${c.employerAmount.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 11, color: _kSecondary)),
                          ])),
                          Text('TZS ${total.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary)),
                        ]));
                    })),
    );
  }
}
