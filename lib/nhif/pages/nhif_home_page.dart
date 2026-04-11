// lib/nhif/pages/nhif_home_page.dart
import 'package:flutter/material.dart';
import '../models/nhif_models.dart';
import '../services/nhif_service.dart';
import 'facility_finder_page.dart';
import 'claims_history_page.dart';
import 'pay_premium_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class NhifHomePage extends StatefulWidget {
  final int userId;
  const NhifHomePage({super.key, required this.userId});
  @override
  State<NhifHomePage> createState() => _NhifHomePageState();
}

class _NhifHomePageState extends State<NhifHomePage> {
  NhifMembership? _membership;
  List<Dependent> _dependents = [];
  bool _loading = true;
  final _memberCtrl = TextEditingController();

  @override
  void dispose() { _memberCtrl.dispose(); super.dispose(); }

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final depR = await NhifService.getDependents();
    if (!mounted) return;
    setState(() { _loading = false; if (depR.success) _dependents = depR.items; });
  }

  Future<void> _verify() async {
    final q = _memberCtrl.text.trim();
    if (q.isEmpty) return;
    setState(() => _loading = true);
    final result = await NhifService.verifyMembership(q);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.success) _membership = result.data;
      else ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message ?? 'Imeshindwa')));
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(onRefresh: _load, color: _kPrimary,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          // Member card or verify
          if (_membership != null)
            Container(padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('NHIF MEMBER CARD', style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 2)),
                ]),
                const SizedBox(height: 12),
                Text(_membership!.memberNumber, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 2)),
                if (_membership!.plan != null) Text(_membership!.plan!, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 8),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _membership!.isActive ? const Color(0xFF4CAF50) : Colors.red, borderRadius: BorderRadius.circular(6)),
                  child: Text(_membership!.isActive ? 'Active' : 'Inactive',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600))),
              ]))
          else ...[
            Container(padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(12)),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Bima ya Afya ya Taifa', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                    SizedBox(height: 2),
                    Text('National Health Insurance Fund', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ])),
                ]),
              ])),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextField(controller: _memberCtrl,
                decoration: InputDecoration(hintText: 'Nambari ya mwanachama / NIDA',
                  hintStyle: const TextStyle(fontSize: 13, color: _kSecondary), filled: true, fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                style: const TextStyle(fontSize: 14, color: _kPrimary))),
              const SizedBox(width: 8),
              SizedBox(height: 48, child: ElevatedButton(onPressed: _verify,
                style: ElevatedButton.styleFrom(backgroundColor: _kPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Thibitisha', style: TextStyle(color: Colors.white)))),
            ]),
          ],
          const SizedBox(height: 20),

          Row(children: [
            _Act(icon: Icons.local_hospital_rounded, label: 'Tafuta\nHospitali', onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const FacilityFinderPage()))),
            const SizedBox(width: 10),
            _Act(icon: Icons.history_rounded, label: 'Historia ya\nMadai', onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ClaimsHistoryPage()))),
            const SizedBox(width: 10),
            _Act(icon: Icons.payment_rounded, label: 'Lipa\nMichango', onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PayPremiumPage()))),
          ]),
          const SizedBox(height: 24),

          if (_dependents.isNotEmpty) ...[
            const Text('Wategemezi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary)),
            const SizedBox(height: 10),
            ..._dependents.map((dep) => Container(
              margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.person_rounded, size: 20, color: _kPrimary),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(dep.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(dep.relationship, style: const TextStyle(fontSize: 11, color: _kSecondary)),
                ])),
              ]))),
          ],
          if (_loading) const Padding(padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))),
          const SizedBox(height: 32),
        ]));
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
