// lib/brela/pages/brela_home_page.dart
import 'package:flutter/material.dart';
import '../models/brela_models.dart';
import '../services/brela_service.dart';
import 'name_search_page.dart';
import 'my_businesses_page.dart';
import 'compliance_calendar_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class BrelaHomePage extends StatefulWidget {
  final int userId;
  const BrelaHomePage({super.key, required this.userId});
  @override
  State<BrelaHomePage> createState() => _BrelaHomePageState();
}

class _BrelaHomePageState extends State<BrelaHomePage> {
  List<Business> _businesses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await BrelaService.getMyBusinesses();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.success) _businesses = result.items;
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
                Icon(Icons.business_rounded, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Usajili wa Biashara', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                  SizedBox(height: 2),
                  Text('Business Registration & Licensing', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ])),
              ]),
            ),
            const SizedBox(height: 20),

            Row(children: [
              _Act(icon: Icons.search_rounded, label: 'Tafuta\nJina', onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const NameSearchPage()))),
              const SizedBox(width: 10),
              _Act(icon: Icons.store_rounded, label: 'Biashara\nZangu', onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MyBusinessesPage()))),
              const SizedBox(width: 10),
              _Act(icon: Icons.calendar_month_rounded, label: 'Kalenda\nCompliance', onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ComplianceCalendarPage()))),
            ]),
            const SizedBox(height: 24),

            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary)))
            else if (_businesses.isNotEmpty) ...[
              const Text('Biashara Zangu', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary)),
              const SizedBox(height: 10),
              ..._businesses.take(3).map((b) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Container(width: 40, height: 40,
                    decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.store_rounded, size: 20, color: _kPrimary)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(b.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(b.typeLabel, style: const TextStyle(fontSize: 11, color: _kSecondary)),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: b.isActive ? const Color(0xFF4CAF50).withValues(alpha: 0.12) : Colors.red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6)),
                    child: Text(b.isActive ? 'Active' : b.status,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                            color: b.isActive ? const Color(0xFF4CAF50) : Colors.red)),
                  ),
                ]),
              )),
            ] else
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: const Column(children: [
                  Icon(Icons.business_rounded, size: 36, color: _kSecondary),
                  SizedBox(height: 8),
                  Text('Hakuna biashara iliyosajiliwa', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                  Text('No registered businesses yet', style: TextStyle(fontSize: 12, color: _kSecondary)),
                ]),
              ),
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
  Widget build(BuildContext context) {
    return Expanded(child: Material(color: Colors.white, borderRadius: BorderRadius.circular(12),
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
}
