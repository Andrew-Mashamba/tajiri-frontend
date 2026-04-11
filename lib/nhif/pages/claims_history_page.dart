// lib/nhif/pages/claims_history_page.dart
import 'package:flutter/material.dart';
import '../models/nhif_models.dart';
import '../services/nhif_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class ClaimsHistoryPage extends StatefulWidget {
  const ClaimsHistoryPage({super.key});
  @override
  State<ClaimsHistoryPage> createState() => _ClaimsHistoryPageState();
}

class _ClaimsHistoryPageState extends State<ClaimsHistoryPage> {
  List<Claim> _claims = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await NhifService.getClaimsHistory();
    if (!mounted) return;
    setState(() { _loading = false; if (result.success) _claims = result.items; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: _kBg,
      appBar: AppBar(title: const Text('Historia ya Madai',
          style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: _kPrimary)),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _claims.isEmpty
              ? const Center(child: Text('Hakuna madai', style: TextStyle(color: _kSecondary)))
              : RefreshIndicator(onRefresh: _load, color: _kPrimary,
                  child: ListView.separated(padding: const EdgeInsets.all(16), itemCount: _claims.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final c = _claims[i];
                      return Container(padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: Row(children: [
                          Container(width: 40, height: 40,
                            decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.receipt_rounded, size: 20, color: _kPrimary)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(c.facilityName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text('${c.serviceDate.day}/${c.serviceDate.month}/${c.serviceDate.year}',
                                style: const TextStyle(fontSize: 11, color: _kSecondary)),
                          ])),
                          Text('TZS ${c.amount.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary)),
                        ]));
                    })),
    );
  }
}
