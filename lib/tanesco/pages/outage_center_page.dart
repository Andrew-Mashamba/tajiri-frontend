// lib/tanesco/pages/outage_center_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/tanesco_models.dart';
import '../services/tanesco_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class OutageCenterPage extends StatefulWidget {
  const OutageCenterPage({super.key});
  @override
  State<OutageCenterPage> createState() => _OutageCenterPageState();
}

class _OutageCenterPageState extends State<OutageCenterPage> {
  List<Outage> _outages = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await TanescoService.getOutages();
    if (!mounted) return;
    setState(() { _loading = false; if (result.success) _outages = result.items; });
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'fixed': return const Color(0xFF4CAF50);
      case 'crewDispatched': return Colors.orange;
      case 'acknowledged': return Colors.blue;
      default: return Colors.red;
    }
  }

  void _showReportOutageDialog() {
    final locationCtrl = TextEditingController();
    final areaCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            const Text('Ripoti Kukatika / Report Outage',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
            const SizedBox(height: 16),
            TextField(
              controller: locationCtrl,
              decoration: InputDecoration(
                labelText: 'Eneo / Location',
                hintText: 'Mfano: Mikocheni B, Dar es Salaam',
                hintStyle: const TextStyle(color: _kSecondary, fontSize: 13),
                labelStyle: const TextStyle(fontSize: 13, color: _kSecondary),
                filled: true, fillColor: _kBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              style: const TextStyle(fontSize: 14, color: _kPrimary),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: areaCtrl,
              decoration: InputDecoration(
                labelText: 'Eneo lililoathirika (hiari) / Affected area (optional)',
                hintText: 'Mfano: Mtaa 3 nyumba, Barabara kuu',
                hintStyle: const TextStyle(color: _kSecondary, fontSize: 13),
                labelStyle: const TextStyle(fontSize: 12, color: _kSecondary),
                filled: true, fillColor: _kBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              style: const TextStyle(fontSize: 14, color: _kPrimary),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Maelezo / Description',
                hintText: 'Eleza tatizo...',
                hintStyle: const TextStyle(color: _kSecondary, fontSize: 13),
                labelStyle: const TextStyle(fontSize: 13, color: _kSecondary),
                filled: true, fillColor: _kBg,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              style: const TextStyle(fontSize: 14, color: _kPrimary),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48, width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (locationCtrl.text.trim().isEmpty) return;
                  Navigator.pop(ctx);
                  final messenger = ScaffoldMessenger.of(context);
                  final result = await TanescoService.reportOutage({
                    'location': locationCtrl.text.trim(),
                    if (areaCtrl.text.trim().isNotEmpty) 'affected_area': areaCtrl.text.trim(),
                    if (descCtrl.text.trim().isNotEmpty) 'description': descCtrl.text.trim(),
                  });
                  if (result.success) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Ripoti imetumwa / Outage reported')));
                    _load();
                  } else {
                    messenger.showSnackBar(
                      SnackBar(content: Text(result.message ?? 'Imeshindwa kutuma ripoti')));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Ripoti / Report', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String s, bool isSwahili) {
    switch (s) {
      case 'fixed': return isSwahili ? 'Imetengenezwa' : 'Fixed';
      case 'crewDispatched': return isSwahili ? 'Wafanyakazi wametumwa' : 'Crew dispatched';
      case 'acknowledged': return isSwahili ? 'Imethibitishwa' : 'Acknowledged';
      default: return isSwahili ? 'Imeripotiwa' : 'Reported';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
    return Scaffold(backgroundColor: _kBg,
      appBar: AppBar(title: Text(isSwahili ? 'Kukatika kwa Umeme' : 'Power Outages',
          style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: _kPrimary),
        actions: [IconButton(icon: const Icon(Icons.add_rounded), onPressed: _showReportOutageDialog)]),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _outages.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.electric_bolt_rounded, size: 48, color: Color(0xFF4CAF50)),
                  const SizedBox(height: 12),
                  Text(isSwahili ? 'Hakuna taarifa za kukatika' : 'No outages reported',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                ]))
              : RefreshIndicator(onRefresh: _load, color: _kPrimary,
                  child: ListView.separated(padding: const EdgeInsets.all(16),
                    itemCount: _outages.length, separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final o = _outages[i];
                      return Container(padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: Row(children: [
                          Container(width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: _statusColor(o.status).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10)),
                            child: Icon(Icons.flash_off_rounded, size: 20, color: _statusColor(o.status))),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(o.location ?? (isSwahili ? 'Eneo halijulikani' : 'Unknown area'),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(_statusLabel(o.status, isSwahili), style: TextStyle(fontSize: 11, color: _statusColor(o.status))),
                          ])),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text('${o.reportedAt.hour}:${o.reportedAt.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary)),
                            Text('${o.reporterCount} ${isSwahili ? 'watu' : 'reports'}', style: const TextStyle(fontSize: 10, color: _kSecondary)),
                          ]),
                        ]));
                    })),
    );
  }
}
