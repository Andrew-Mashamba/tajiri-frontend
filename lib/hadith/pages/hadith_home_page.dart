// lib/hadith/pages/hadith_home_page.dart
import 'package:flutter/material.dart';
import '../models/hadith_models.dart';
import '../services/hadith_service.dart';
import 'collection_detail_page.dart';
import 'hadith_detail_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
class HadithHomePage extends StatefulWidget {
  final int userId;
  const HadithHomePage({super.key, required this.userId});

  @override
  State<HadithHomePage> createState() => _HadithHomePageState();
}

class _HadithHomePageState extends State<HadithHomePage> {
  final _service = HadithService();
  Hadith? _dailyHadith;
  List<HadithCollection> _collections = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _service.getDailyHadith(),
      _service.getCollections(),
    ]);
    if (mounted) {
      final dailyResult = results[0] as SingleResult<Hadith>;
      final collectionsResult = results[1] as PaginatedResult<HadithCollection>;
      setState(() {
        _dailyHadith = dailyResult.data;
        _collections = collectionsResult.items;
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
                // Search action
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.search_rounded, color: _kPrimary),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Search coming soon / Utafutaji unakuja'),
                          backgroundColor: _kPrimary,
                        ),
                      );
                    },
                  ),
                ),
                    // ─── Daily Hadith ─────────────────────
                    if (_dailyHadith != null) ...[
                      const Text('Hadith ya Leo',
                          style: TextStyle(color: _kPrimary, fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      _buildDailyCard(_dailyHadith!),
                      const SizedBox(height: 24),
                    ],

                    // ─── Collections ──────────────────────
                    const Text('Makusanyo ya Hadith',
                        style: TextStyle(color: _kPrimary, fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    ..._collections.map(_buildCollectionTile),
                  ],
                ),
              );
  }

  Widget _buildDailyCard(Hadith h) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => HadithDetailPage(hadith: h))),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kPrimary, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              h.textArabic,
              style: const TextStyle(
                color: Colors.white, fontSize: 18, height: 1.8),
              textDirection: TextDirection.rtl,
              maxLines: 4, overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                h.translationSwahili ?? h.translationEnglish ?? '',
                style: const TextStyle(
                  color: Colors.white70, fontSize: 14, height: 1.5),
                maxLines: 3, overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _gradeBadge(h.grade),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Rawi: ${h.narrator}',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradeBadge(String grade) {
    Color color;
    switch (grade.toLowerCase()) {
      case 'sahih':
        color = Colors.green;
      case 'hasan':
        color = Colors.orange;
      default:
        color = Colors.red;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6)),
      child: Text(
        grade.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildCollectionTile(HadithCollection col) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => CollectionDetailPage(collection: col))),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200)),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.menu_book_rounded,
                  color: _kPrimary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(col.nameSwahili.isNotEmpty ? col.nameSwahili : col.name,
                      style: const TextStyle(color: _kPrimary, fontSize: 15,
                          fontWeight: FontWeight.w500),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('${col.hadithCount} hadith \u2022 ${col.bookCount} vitabu',
                      style: const TextStyle(color: _kSecondary, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: _kSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
