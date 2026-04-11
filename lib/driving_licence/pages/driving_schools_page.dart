// lib/driving_licence/pages/driving_schools_page.dart
import 'package:flutter/material.dart';
import '../models/driving_licence_models.dart';
import '../services/driving_licence_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class DrivingSchoolsPage extends StatefulWidget {
  const DrivingSchoolsPage({super.key});
  @override
  State<DrivingSchoolsPage> createState() => _DrivingSchoolsPageState();
}

class _DrivingSchoolsPageState extends State<DrivingSchoolsPage> {
  List<DrivingSchool> _schools = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await DrivingLicenceService.getSchools();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.success) _schools = result.items;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Shule za Udereva',
            style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white, elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : RefreshIndicator(
              onRefresh: _load, color: _kPrimary,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _schools.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final s = _schools[i];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: _kPrimary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.directions_car_rounded, size: 20, color: _kPrimary)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(s.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          if (s.location != null)
                            Text(s.location!, style: const TextStyle(fontSize: 12, color: _kSecondary),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                        ])),
                        if (s.rating > 0)
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                            const SizedBox(width: 2),
                            Text(s.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary)),
                          ]),
                      ]),
                      const SizedBox(height: 8),
                      if (s.classesOffered.isNotEmpty)
                        Wrap(spacing: 6, children: s.classesOffered.map((c) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4)),
                          child: Text('Class $c', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _kPrimary)),
                        )).toList()),
                      if (s.priceRange != null) ...[
                        const SizedBox(height: 6),
                        Text(s.priceRange!, style: const TextStyle(fontSize: 12, color: _kSecondary)),
                      ],
                    ]),
                  );
                },
              ),
            ),
    );
  }
}
