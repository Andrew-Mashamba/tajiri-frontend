// lib/rita/pages/rita_home_page.dart
import 'package:flutter/material.dart';
import '../models/rita_models.dart';
import '../services/rita_service.dart';
import 'track_application_page.dart';
import 'apply_certificate_page.dart';
import 'fee_calculator_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class RitaHomePage extends StatefulWidget {
  final int userId;
  const RitaHomePage({super.key, required this.userId});
  @override
  State<RitaHomePage> createState() => _RitaHomePageState();
}

class _RitaHomePageState extends State<RitaHomePage> {
  List<CertificateApplication> _recent = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await RitaService.getMyApplications();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.success) _recent = result.items;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
        onRefresh: _load,
        color: _kPrimary,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(12)),
              child: const Row(children: [
                Icon(Icons.description_rounded, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Vyeti vya Kuzaliwa, Kifo & Ndoa',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                  SizedBox(height: 2),
                  Text('Birth, Death & Marriage Certificates',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ])),
              ]),
            ),
            const SizedBox(height: 20),

            // Quick actions
            const Text('Vitendo vya Haraka', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary)),
            const SizedBox(height: 12),
            Row(children: [
              _ActionCard(icon: Icons.add_circle_outline_rounded, label: 'Omba\nCheti',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => ApplyCertificatePage(userId: widget.userId)))),
              const SizedBox(width: 10),
              _ActionCard(icon: Icons.track_changes_rounded, label: 'Fuatilia\nOmbi',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const TrackApplicationPage()))),
              const SizedBox(width: 10),
              _ActionCard(icon: Icons.calculate_rounded, label: 'Hesabu\nAda',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const FeeCalculatorPage()))),
            ]),
            const SizedBox(height: 24),

            // Recent applications
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary)),
              )
            else if (_recent.isNotEmpty) ...[
              const Text('Maombi ya Hivi Karibuni',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary)),
              const SizedBox(height: 10),
              ..._recent.take(5).map((a) => _AppCard(app: a)),
            ] else
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: const Column(children: [
                  Icon(Icons.description_rounded, size: 36, color: _kSecondary),
                  SizedBox(height: 8),
                  Text('Hakuna maombi bado', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                  SizedBox(height: 4),
                  Text('No applications yet', style: TextStyle(fontSize: 12, color: _kSecondary)),
                ]),
              ),
            const SizedBox(height: 32),
          ],
        ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap, borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.08), shape: BoxShape.circle),
                child: Icon(icon, size: 22, color: _kPrimary),
              ),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kPrimary),
                  textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
            ]),
          ),
        ),
      ),
    );
  }
}

class _AppCard extends StatelessWidget {
  final CertificateApplication app;
  const _AppCard({required this.app});

  @override
  Widget build(BuildContext context) {
    final stages = ['Imewasilishwa', 'Inashughulikiwa', 'Inachapishwa', 'Tayari', 'Imekusanywa'];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: _kPrimary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
          child: Icon(
            app.type == CertificateType.birth ? Icons.child_care_rounded
                : app.type == CertificateType.death ? Icons.sentiment_very_dissatisfied_rounded
                : Icons.favorite_rounded,
            size: 20, color: _kPrimary),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(app.typeLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(app.trackingNumber, style: const TextStyle(fontSize: 11, color: _kSecondary),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: app.stageIndex >= 3 ? const Color(0xFF4CAF50).withValues(alpha: 0.12) : _kPrimary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6)),
          child: Text(stages[app.stageIndex.clamp(0, 4)],
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                  color: app.stageIndex >= 3 ? const Color(0xFF4CAF50) : _kPrimary)),
        ),
      ]),
    );
  }
}
