// lib/tanesco/pages/my_meters_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/tanesco_models.dart';
import '../services/tanesco_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class MyMetersPage extends StatefulWidget {
  const MyMetersPage({super.key});
  @override
  State<MyMetersPage> createState() => _MyMetersPageState();
}

class _MyMetersPageState extends State<MyMetersPage> {
  List<Meter> _meters = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await TanescoService.getMyMeters();
    if (!mounted) return;
    setState(() { _loading = false; if (result.success) _meters = result.items; });
  }

  void _showAddDialog() {
    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
    final mCtrl = TextEditingController();
    final aCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(isSwahili ? 'Ongeza Mita' : 'Add Meter', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: mCtrl, decoration: InputDecoration(hintText: isSwahili ? 'Nambari ya mita' : 'Meter number'),
            style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 8),
        TextField(controller: aCtrl, decoration: InputDecoration(hintText: isSwahili ? 'Jina (hiari)' : 'Name (optional)'),
            style: const TextStyle(fontSize: 14)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx),
            child: Text(isSwahili ? 'Ghairi' : 'Cancel', style: const TextStyle(color: _kSecondary))),
        TextButton(onPressed: () async {
          if (mCtrl.text.trim().isEmpty) return;
          Navigator.pop(ctx);
          final messenger = ScaffoldMessenger.of(context);
          final result = await TanescoService.addMeter(mCtrl.text.trim(), aCtrl.text.trim().isEmpty ? null : aCtrl.text.trim());
          if (!mounted) return;
          if (result.success) {
            _load();
          } else {
            messenger.showSnackBar(SnackBar(
              content: Text(result.message ?? (isSwahili ? 'Imeshindwa kuongeza mita' : 'Failed to add meter'))));
          }
        }, child: Text(isSwahili ? 'Ongeza' : 'Add', style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w600))),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
    return Scaffold(backgroundColor: _kBg,
      appBar: AppBar(title: Text(isSwahili ? 'Mita Zangu' : 'My Meters',
          style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: _kPrimary),
        actions: [IconButton(icon: const Icon(Icons.add_rounded), onPressed: _showAddDialog)]),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : RefreshIndicator(onRefresh: _load, color: _kPrimary,
              child: ListView.separated(padding: const EdgeInsets.all(16),
                itemCount: _meters.length, separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final m = _meters[i];
                  return Container(padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      Container(width: 44, height: 44,
                        decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.speed_rounded, size: 22, color: _kPrimary)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(m.alias ?? m.meterNumber, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(m.meterNumber, style: const TextStyle(fontSize: 12, color: _kSecondary)),
                        Text(m.type == 'prepaid' ? 'LUKU' : 'Postpaid',
                            style: const TextStyle(fontSize: 11, color: _kSecondary)),
                      ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(m.type == 'prepaid' ? '${m.balance.toStringAsFixed(1)} kWh' : 'TZS ${m.balance.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary)),
                      ]),
                    ]));
                })),
    );
  }
}
