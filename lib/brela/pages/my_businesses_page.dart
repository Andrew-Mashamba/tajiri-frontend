// lib/brela/pages/my_businesses_page.dart
import 'package:flutter/material.dart';
import '../models/brela_models.dart';
import '../services/brela_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class MyBusinessesPage extends StatefulWidget {
  const MyBusinessesPage({super.key});
  @override
  State<MyBusinessesPage> createState() => _MyBusinessesPageState();
}

class _MyBusinessesPageState extends State<MyBusinessesPage> {
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
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Biashara Zangu',
            style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white, elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _businesses.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.store_rounded, size: 48, color: _kSecondary),
                  const SizedBox(height: 12),
                  const Text('Hakuna biashara', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
                  const Text('No businesses registered', style: TextStyle(fontSize: 13, color: _kSecondary)),
                ]))
              : RefreshIndicator(
                  onRefresh: _load, color: _kPrimary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _businesses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final b = _businesses[i];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Text(b.name,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary),
                                maxLines: 1, overflow: TextOverflow.ellipsis)),
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
                          const SizedBox(height: 6),
                          Text(b.typeLabel, style: const TextStyle(fontSize: 12, color: _kSecondary)),
                          if (b.registrationNumber != null)
                            Text('Reg: ${b.registrationNumber}', style: const TextStyle(fontSize: 12, color: _kSecondary)),
                          if (b.annualReturnsDue != null) ...[
                            const SizedBox(height: 4),
                            Row(children: [
                              const Icon(Icons.warning_rounded, size: 14, color: Colors.orange),
                              const SizedBox(width: 4),
                              Text('Annual returns due: ${b.annualReturnsDue}',
                                  style: const TextStyle(fontSize: 11, color: Colors.orange)),
                            ]),
                          ],
                        ]),
                      );
                    },
                  ),
                ),
    );
  }
}
