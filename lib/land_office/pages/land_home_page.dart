// lib/land_office/pages/land_home_page.dart
import 'package:flutter/material.dart';
import '../models/land_office_models.dart';
import '../services/land_office_service.dart';
import 'plot_search_page.dart';
import 'title_verification_page.dart';
import 'fraud_alerts_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class LandHomePage extends StatefulWidget {
  final int userId;
  const LandHomePage({super.key, required this.userId});
  @override
  State<LandHomePage> createState() => _LandHomePageState();
}

class _LandHomePageState extends State<LandHomePage> {
  List<FraudAlert> _alerts = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await LandOfficeService.getFraudAlerts();
    if (!mounted) return;
    setState(() { _loading = false; if (result.success) _alerts = result.items; });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(onRefresh: _load, color: _kPrimary,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Container(padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(12)),
            child: const Row(children: [
              Icon(Icons.landscape_rounded, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Huduma za Ardhi', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                SizedBox(height: 2),
                Text('Land & Property Services', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ])),
            ])),
          const SizedBox(height: 20),
          Row(children: [
            _Act(icon: Icons.search_rounded, label: 'Tafuta\nKiwanja', onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PlotSearchPage()))),
            const SizedBox(width: 10),
            _Act(icon: Icons.verified_rounded, label: 'Thibitisha\nHati', onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const TitleVerificationPage()))),
            const SizedBox(width: 10),
            _Act(icon: Icons.warning_rounded, label: 'Tahadhari\nza Udanganyifu', onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const FraudAlertsPage()))),
          ]),
          const SizedBox(height: 24),
          // Info cards
          _Info(icon: Icons.checklist_rounded, title: 'Mwongozo wa Kununua Ardhi',
              subtitle: 'Land purchase safety checklist', onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mwongozo / Guide - coming soon')));
              }),
          const SizedBox(height: 8),
          _Info(icon: Icons.woman_rounded, title: 'Haki za Ardhi za Wanawake',
              subtitle: "Women's land rights information", onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Haki za Ardhi / Women's land rights - coming soon")));
              }),
          const SizedBox(height: 8),
          _Info(icon: Icons.gavel_rounded, title: 'Usuluhishi wa Migogoro',
              subtitle: 'Land dispute resolution guide', onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Usuluhishi / Dispute resolution - coming soon')));
              }),
          const SizedBox(height: 8),
          _Info(icon: Icons.calculate_rounded, title: 'Hesabu Ada',
              subtitle: 'Stamp duty & registration fees calculator', onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Hesabu Ada / Fee calculator - coming soon')));
              }),
          if (_alerts.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('Tahadhari za Hivi Karibuni', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary)),
            const SizedBox(height: 10),
            ..._alerts.take(3).map((a) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.warning_rounded, size: 18, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Kiwanja ${a.plotNumber}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(a.description, style: const TextStyle(fontSize: 11, color: _kSecondary),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                ])),
              ])),
            ),
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

class _Info extends StatelessWidget {
  final IconData icon; final String title; final String subtitle; final VoidCallback onTap;
  const _Info({required this.icon, required this.title, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(color: Colors.white, borderRadius: BorderRadius.circular(12),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12),
      child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
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
