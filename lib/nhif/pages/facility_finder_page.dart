// lib/nhif/pages/facility_finder_page.dart
import 'package:flutter/material.dart';
import '../models/nhif_models.dart';
import '../services/nhif_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class FacilityFinderPage extends StatefulWidget {
  const FacilityFinderPage({super.key});
  @override
  State<FacilityFinderPage> createState() => _FacilityFinderPageState();
}

class _FacilityFinderPageState extends State<FacilityFinderPage> {
  List<AccreditedFacility> _facilities = [];
  bool _loading = true;
  String? _filterType;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await NhifService.findFacilities(type: _filterType);
    if (!mounted) return;
    setState(() { _loading = false; if (result.success) _facilities = result.items; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: _kBg,
      appBar: AppBar(title: const Text('Tafuta Hospitali',
          style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: _kPrimary)),
      body: Column(children: [
        Container(color: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(scrollDirection: Axis.horizontal,
            child: Row(children: ['Zote', 'Hospital', 'Clinic', 'Pharmacy', 'Lab'].map((t) {
              final sel = (t == 'Zote' && _filterType == null) || _filterType == t.toLowerCase();
              return Padding(padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(label: Text(t, style: TextStyle(fontSize: 12,
                    color: sel ? Colors.white : _kPrimary)),
                  selected: sel, selectedColor: _kPrimary, backgroundColor: Colors.white,
                  onSelected: (_) { _filterType = t == 'Zote' ? null : t.toLowerCase(); _load(); }));
            }).toList()))),
        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
            : ListView.separated(padding: const EdgeInsets.all(16), itemCount: _facilities.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final f = _facilities[i];
                  return Container(padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      Container(width: 40, height: 40,
                        decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                        child: Icon(f.type == 'pharmacy' ? Icons.local_pharmacy_rounded : Icons.local_hospital_rounded,
                            size: 20, color: _kPrimary)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(f.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        if (f.address != null) Text(f.address!, style: const TextStyle(fontSize: 11, color: _kSecondary),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ])),
                      if (f.rating > 0) Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                        Text(f.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kPrimary)),
                      ]),
                    ]));
                })),
      ]),
    );
  }
}
