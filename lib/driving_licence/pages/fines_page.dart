// lib/driving_licence/pages/fines_page.dart
import 'package:flutter/material.dart';
import '../models/driving_licence_models.dart';
import '../services/driving_licence_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class FinesPage extends StatefulWidget {
  const FinesPage({super.key});
  @override
  State<FinesPage> createState() => _FinesPageState();
}

class _FinesPageState extends State<FinesPage> {
  List<TrafficFine> _fines = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await DrivingLicenceService.getFines();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.success) _fines = result.items;
    });
  }

  Future<void> _payFine(TrafficFine fine) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) =>
        AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Lipa Faini', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          content: Text('Lipa TZS ${fine.amount.toStringAsFixed(0)} kwa ${fine.violation}?',
              style: const TextStyle(fontSize: 13, color: _kSecondary)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Ghairi', style: TextStyle(color: _kSecondary))),
            TextButton(onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Lipa', style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w600))),
          ],
        ));
    if (confirm != true) return;
    final result = await DrivingLicenceService.payFine(fine.id, {'method': 'mpesa'});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.success ? 'Faini imelipwa' : (result.message ?? 'Imeshindwa'))));
    if (result.success) _load();
  }

  @override
  Widget build(BuildContext context) {
    final outstanding = _fines.where((f) => !f.isPaid).toList();
    final paid = _fines.where((f) => f.isPaid).toList();

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Faini Zangu',
            style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white, elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _fines.isEmpty
              ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check_circle_rounded, size: 48, color: Color(0xFF4CAF50)),
                  SizedBox(height: 12),
                  Text('Hakuna faini', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
                  Text('No fines - drive safely!', style: TextStyle(fontSize: 13, color: _kSecondary)),
                ]))
              : ListView(padding: const EdgeInsets.all(16), children: [
                  if (outstanding.isNotEmpty) ...[
                    const Text('Faini Ambazo Hazijalipwa',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary)),
                    const SizedBox(height: 10),
                    ...outstanding.map((f) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        Container(width: 4, height: 48,
                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(f.violation, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('${f.date.day}/${f.date.month}/${f.date.year}${f.location != null ? " - ${f.location}" : ""}',
                              style: const TextStyle(fontSize: 11, color: _kSecondary),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ])),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text('TZS ${f.amount.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.red)),
                          GestureDetector(
                            onTap: () => _payFine(f),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(6)),
                              child: const Text('Lipa', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ]),
                      ]),
                    )),
                  ],
                  if (paid.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Faini Zilizolipwa',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary)),
                    const SizedBox(height: 10),
                    ...paid.map((f) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF4CAF50)),
                        const SizedBox(width: 12),
                        Expanded(child: Text(f.violation, style: const TextStyle(fontSize: 13, color: _kSecondary),
                            maxLines: 1, overflow: TextOverflow.ellipsis)),
                        Text('TZS ${f.amount.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 12, color: _kSecondary)),
                      ]),
                    )),
                  ],
                ]),
    );
  }
}
