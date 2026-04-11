// lib/quran/pages/quran_home_page.dart
import 'package:flutter/material.dart';
import 'surah_list_page.dart';
import 'quran_reader_page.dart';
const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class QuranHomePage extends StatefulWidget {
  final int userId;
  const QuranHomePage({super.key, required this.userId});

  @override
  State<QuranHomePage> createState() => _QuranHomePageState();
}

class _QuranHomePageState extends State<QuranHomePage> {
  @override
  Widget build(BuildContext context) {
    return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ─── Last Read Card ───────────────────────────
            _buildLastReadCard(),
            const SizedBox(height: 16),

            // ─── Quick Access ─────────────────────────────
            Row(
              children: [
                Expanded(child: _quickCard(
                  icon: Icons.menu_book_rounded,
                  label: 'Sura Zote',
                  sublabel: '114 Sura',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SurahListPage(userId: widget.userId),
                    ),
                  ),
                )),
                const SizedBox(width: 12),
                Expanded(child: _quickCard(
                  icon: Icons.bookmark_rounded,
                  label: 'Alama',
                  sublabel: 'Bookmarks / Zilizohifadhiwa',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Bookmarks coming soon / Alama zinakuja hivi karibuni'),
                        backgroundColor: _kPrimary,
                      ),
                    );
                  },
                )),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _quickCard(
                  icon: Icons.view_list_rounded,
                  label: 'Juz',
                  sublabel: 'Parts / Sehemu 30',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Juz browser coming soon / Inaendelezwa'),
                        backgroundColor: _kPrimary,
                      ),
                    );
                  },
                )),
                const SizedBox(width: 12),
                Expanded(child: _quickCard(
                  icon: Icons.headphones_rounded,
                  label: 'Wasomaji',
                  sublabel: 'Listen / Sikiliza',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reciters coming soon / Wasomaji wanakuja'),
                        backgroundColor: _kPrimary,
                      ),
                    );
                  },
                )),
              ],
            ),
            const SizedBox(height: 24),

            // ─── Daily Ayah ───────────────────────────────
            const Text(
              'Aya ya Leo',
              style: TextStyle(
                color: _kPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildDailyAyahCard(),
          ],
    );
  }

  Widget _buildLastReadCard() {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuranReaderPage(
            surahNumber: 2,
            surahName: 'Al-Baqarah',
          ),
        ),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _kPrimary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.auto_stories_rounded, color: Colors.white70, size: 40),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Endelea Kusoma',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Surat Al-Baqarah',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Aya 45 / 286',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white54, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _quickCard({
    required IconData icon,
    required String label,
    required String sublabel,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: _kPrimary, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: _kPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              sublabel,
              style: const TextStyle(color: _kSecondary, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyAyahCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            '\u0628\u0650\u0633\u0652\u0645\u0650 \u0627\u0644\u0644\u0651\u064E\u0647\u0650 '
            '\u0627\u0644\u0631\u0651\u064E\u062D\u0652\u0645\u064E\u0646\u0650 '
            '\u0627\u0644\u0631\u0651\u064E\u062D\u0650\u064A\u0645\u0650',
            style: TextStyle(
              fontSize: 22,
              color: _kPrimary,
              fontWeight: FontWeight.w500,
              height: 2,
            ),
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Kwa jina la Mwenyezi Mungu, Mwingi wa Rehema, Mwenye kurehemu.',
              style: TextStyle(
                color: _kSecondary,
                fontSize: 14,
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '- Al-Fatihah 1:1',
              style: TextStyle(color: _kSecondary, fontSize: 12),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.share_rounded, size: 20),
                color: _kSecondary,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Share coming soon / Kushiriki kunakuja'),
                      backgroundColor: _kPrimary,
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.bookmark_border_rounded, size: 20),
                color: _kSecondary,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bookmark saved / Alama imehifadhiwa'),
                      backgroundColor: _kPrimary,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
