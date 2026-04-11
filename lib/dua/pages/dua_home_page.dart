// lib/dua/pages/dua_home_page.dart
import 'package:flutter/material.dart';
import '../models/dua_models.dart';
import '../services/dua_service.dart';
import 'dua_category_page.dart';
import 'adhkar_page.dart';


const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
class DuaHomePage extends StatefulWidget {
  final int userId;
  const DuaHomePage({super.key, required this.userId});

  @override
  State<DuaHomePage> createState() => _DuaHomePageState();
}

class _DuaHomePageState extends State<DuaHomePage> {
  final _service = DuaService();
  List<DuaCategory> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await _service.getCategories();
    if (mounted) {
      setState(() {
        _categories = result.items;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator(
            strokeWidth: 2, color: _kPrimary))
        : RefreshIndicator(
            color: _kPrimary,
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Favorites action
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.favorite_border_rounded, color: _kPrimary),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Favorites coming soon / Unazozipenda zinakuja'),
                          backgroundColor: _kPrimary,
                        ),
                      );
                    },
                  ),
                ),
                    // ─── Adhkar Buttons ───────────────────
                    Row(
                      children: [
                        Expanded(child: _adhkarButton(
                          'Adhkari za Asubuhi',
                          Icons.wb_sunny_rounded,
                          () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => const AdhkarPage(type: 'morning'),
                          )),
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _adhkarButton(
                          'Adhkari za Jioni',
                          Icons.nightlight_round,
                          () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => const AdhkarPage(type: 'evening'),
                          )),
                        )),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ─── Categories ───────────────────────
                    const Text('Makundi ya Dua',
                        style: TextStyle(color: _kPrimary, fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),

                    if (_categories.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Hakuna makundi bado',
                            style: TextStyle(color: _kSecondary, fontSize: 14),
                            textAlign: TextAlign.center),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.5,
                        ),
                        itemCount: _categories.length,
                        itemBuilder: (context, i) {
                          final cat = _categories[i];
                          return _categoryCard(cat);
                        },
                      ),
                  ],
                ),
              );
  }

  Widget _adhkarButton(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kPrimary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 13,
                    fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _categoryCard(DuaCategory cat) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => DuaCategoryPage(category: cat),
      )),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome_rounded,
                color: _kPrimary, size: 24),
            const SizedBox(height: 8),
            Text(
              cat.nameSwahili.isNotEmpty ? cat.nameSwahili : cat.name,
              style: const TextStyle(color: _kPrimary, fontSize: 14,
                  fontWeight: FontWeight.w500),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
            Text('${cat.duaCount} dua',
                style: const TextStyle(color: _kSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
