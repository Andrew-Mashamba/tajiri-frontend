// lib/passport/pages/passport_home_page.dart
import 'package:flutter/material.dart';
import '../models/passport_models.dart';
import '../services/passport_service.dart';
import 'track_application_page.dart';
import 'visa_checker_page.dart';
import 'fee_calculator_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class PassportHomePage extends StatefulWidget {
  final int userId;
  const PassportHomePage({super.key, required this.userId});
  @override
  State<PassportHomePage> createState() => _PassportHomePageState();
}

class _PassportHomePageState extends State<PassportHomePage> {
  List<PassportInfo> _passports = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await PassportService.getFamilyPassports();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.success) _passports = result.items;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
        onRefresh: _load, color: _kPrimary,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(12)),
              child: const Row(children: [
                Icon(Icons.flight_rounded, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Huduma za Pasipoti', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                  SizedBox(height: 2),
                  Text('Immigration Department Services', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ])),
              ]),
            ),
            const SizedBox(height: 20),

            Row(children: [
              _Act(icon: Icons.track_changes_rounded, label: 'Fuatilia\nOmbi',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const PassportTrackPage()))),
              const SizedBox(width: 10),
              _Act(icon: Icons.public_rounded, label: 'Mahitaji\nya Visa',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const VisaCheckerPage()))),
              const SizedBox(width: 10),
              _Act(icon: Icons.calculate_rounded, label: 'Hesabu\nAda',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const PassportFeeCalcPage()))),
            ]),
            const SizedBox(height: 24),

            // Family passports
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary)))
            else if (_passports.isNotEmpty) ...[
              const Text('Pasipoti za Familia', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary)),
              const SizedBox(height: 10),
              ..._passports.map((p) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Container(width: 40, height: 40,
                    decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.menu_book_rounded, size: 20, color: _kPrimary)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.holderName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(p.passportNumber, style: const TextStyle(fontSize: 11, color: _kSecondary)),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(p.isExpired ? 'Imeisha' : '${p.daysUntilExpiry} siku',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                            color: p.isExpired ? Colors.red : p.isExpiring ? Colors.orange : _kPrimary)),
                    Text('muda', style: TextStyle(fontSize: 10, color: p.isExpiring ? Colors.orange : _kSecondary)),
                  ]),
                ]),
              )),
            ] else ...[
              // Application guide
              _InfoTile(icon: Icons.list_alt_rounded, title: 'Mwongozo wa Maombi',
                  subtitle: 'Application guide for first-time & renewal', onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mwongozo / Guide - coming soon')));
                  }),
              const SizedBox(height: 8),
              _InfoTile(icon: Icons.checklist_rounded, title: 'Nyaraka Zinazohitajika',
                  subtitle: 'Document checklist for passport application', onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nyaraka / Checklist - coming soon')));
                  }),
              const SizedBox(height: 8),
              _InfoTile(icon: Icons.camera_alt_rounded, title: 'Picha ya Pasipoti',
                  subtitle: 'Photo requirements guide', onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Picha / Photo guide - coming soon')));
                  }),
            ],
            const SizedBox(height: 32),
          ],
        ),
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

class _InfoTile extends StatelessWidget {
  final IconData icon; final String title; final String subtitle; final VoidCallback onTap;
  const _InfoTile({required this.icon, required this.title, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(color: Colors.white, borderRadius: BorderRadius.circular(12),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12),
      child: Padding(padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(width: 48, height: 48,
            decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 22, color: _kPrimary)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: _kSecondary),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          const Icon(Icons.chevron_right_rounded, size: 20, color: _kSecondary),
        ]))));
}
