// lib/passport/pages/visa_checker_page.dart
import 'package:flutter/material.dart';
import '../models/passport_models.dart';
import '../services/passport_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class VisaCheckerPage extends StatefulWidget {
  const VisaCheckerPage({super.key});
  @override
  State<VisaCheckerPage> createState() => _VisaCheckerPageState();
}

class _VisaCheckerPageState extends State<VisaCheckerPage> {
  List<VisaRequirement> _all = [];
  List<VisaRequirement> _filtered = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await PassportService.getVisaRequirements();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.success) { _all = result.items; _filtered = _all; }
    });
  }

  void _filter(String q) {
    setState(() {
      _filtered = q.isEmpty ? _all
          : _all.where((v) => v.countryName.toLowerCase().contains(q.toLowerCase())).toList();
    });
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'visaFree': return const Color(0xFF4CAF50);
      case 'visaOnArrival': return Colors.orange;
      default: return Colors.red;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'visaFree': return 'Bila Visa';
      case 'visaOnArrival': return 'Visa Uwanjani';
      default: return 'Visa Inahitajika';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Mahitaji ya Visa',
            style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white, elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: Column(children: [
        Container(color: Colors.white, padding: const EdgeInsets.all(16),
          child: TextField(controller: _searchCtrl, onChanged: _filter,
            decoration: InputDecoration(hintText: 'Tafuta nchi...',
              hintStyle: const TextStyle(fontSize: 13, color: _kSecondary),
              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: _kSecondary),
              filled: true, fillColor: _kBg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
            style: const TextStyle(fontSize: 14, color: _kPrimary))),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final v = _filtered[i];
                    return Container(padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        Container(width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: _statusColor(v.status).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10)),
                          child: Center(child: Text(v.countryCode.toUpperCase(),
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                                  color: _statusColor(v.status))))),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(v.countryName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          if (v.stayDuration != null)
                            Text('Siku ${v.stayDuration}', style: const TextStyle(fontSize: 11, color: _kSecondary)),
                        ])),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusColor(v.status).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6)),
                          child: Text(_statusLabel(v.status),
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                                  color: _statusColor(v.status))),
                        ),
                      ]));
                  }),
        ),
      ]),
    );
  }
}
