// lib/driving_licence/pages/licence_home_page.dart
import 'package:flutter/material.dart';
import '../models/driving_licence_models.dart';
import '../services/driving_licence_service.dart';
import 'theory_prep_page.dart';
import 'fines_page.dart';
import 'driving_schools_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class LicenceHomePage extends StatefulWidget {
  final int userId;
  const LicenceHomePage({super.key, required this.userId});
  @override
  State<LicenceHomePage> createState() => _LicenceHomePageState();
}

class _LicenceHomePageState extends State<LicenceHomePage> {
  DrivingLicence? _licence;
  List<TrafficFine> _fines = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      DrivingLicenceService.getMyLicence(),
      DrivingLicenceService.getFines(),
    ]);
    if (!mounted) return;
    setState(() {
      _loading = false;
      final licR = results[0] as SingleResult<DrivingLicence>;
      if (licR.success) _licence = licR.data;
      final fineR = results[1] as PaginatedResult<TrafficFine>;
      if (fineR.success) _fines = fineR.items.where((f) => !f.isPaid).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
        onRefresh: _load, color: _kPrimary,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          // Licence card
          if (_licence != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Icon(Icons.credit_card_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('LESENI YA UDEREVA', style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 2)),
                ]),
                const SizedBox(height: 12),
                Text(_licence!.licenceNumber,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 2)),
                const SizedBox(height: 8),
                Wrap(spacing: 6, children: _licence!.classes.map((c) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)),
                  child: Text('${c.code} (${c.type})',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                )).toList()),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Exp: ${_licence!.expiryDate.day}/${_licence!.expiryDate.month}/${_licence!.expiryDate.year}',
                      style: TextStyle(color: _licence!.isExpiring ? Colors.orange : Colors.white54, fontSize: 11)),
                  Text('Points: ${_licence!.points}',
                      style: TextStyle(color: _licence!.points > 0 ? Colors.orange : Colors.white54, fontSize: 11)),
                ]),
              ]),
            )
          else if (!_loading)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: const Column(children: [
                Icon(Icons.credit_card_rounded, size: 36, color: _kSecondary),
                SizedBox(height: 8),
                Text('Hakuna leseni iliyounganishwa', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                Text('No licence linked yet', style: TextStyle(fontSize: 12, color: _kSecondary)),
              ]),
            ),
          const SizedBox(height: 20),

          // Fine alert
          if (_fines.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.warning_rounded, size: 20, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(child: Text('Una faini ${_fines.length} ambayo haijalipwa',
                    style: const TextStyle(fontSize: 13, color: Colors.red, fontWeight: FontWeight.w600))),
              ]),
            ),
            const SizedBox(height: 16),
          ],

          // Quick actions
          Row(children: [
            _Act(icon: Icons.school_rounded, label: 'Maandalizi\nya Nadharia', onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const TheoryPrepPage()))),
            const SizedBox(width: 10),
            _Act(icon: Icons.gavel_rounded, label: 'Faini\nZangu', onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const FinesPage()))),
            const SizedBox(width: 10),
            _Act(icon: Icons.directions_car_rounded, label: 'Shule za\nUdereva', onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const DrivingSchoolsPage()))),
          ]),

          if (_loading)
            const Padding(padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))),
          const SizedBox(height: 32),
        ]),
    );
  }
}

class _Act extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _Act({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(child: Material(color: Colors.white, borderRadius: BorderRadius.circular(12),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12),
      child: Padding(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(children: [
          Container(padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.08), shape: BoxShape.circle),
            child: Icon(icon, size: 22, color: _kPrimary)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kPrimary),
              textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
        ])))));
}
