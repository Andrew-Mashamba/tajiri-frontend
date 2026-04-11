// lib/katiba/pages/katiba_home_page.dart
import 'package:flutter/material.dart';
import '../models/katiba_models.dart';
import '../widgets/article_card.dart';
import '../widgets/chapter_tile.dart';
import 'article_reader_page.dart';
import 'search_results_page.dart';
import 'quiz_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class KatibaHomePage extends StatefulWidget {
  final int userId;
  final List<Chapter> chapters;
  final Article? dailyArticle;

  const KatibaHomePage({
    super.key,
    required this.userId,
    this.chapters = const [],
    this.dailyArticle,
  });

  @override
  State<KatibaHomePage> createState() => _KatibaHomePageState();
}

class _KatibaHomePageState extends State<KatibaHomePage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SearchResultsPage(query: query)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Search bar ──
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchCtrl,
              onSubmitted: (_) => _onSearch(),
              decoration: InputDecoration(
                hintText: 'Tafuta ibara...',
                hintStyle: const TextStyle(color: _kSecondary, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: _kSecondary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Daily article ──
          if (widget.dailyArticle != null) ...[
            const Text(
              'Ibara ya Leo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _kPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ArticleCard(
              article: widget.dailyArticle!,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ArticleReaderPage(article: widget.dailyArticle!),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // ── Chapters ──
          const Text(
            'Sura',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _kPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ...widget.chapters.map(
            (ch) => ChapterTile(
              chapter: ch,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${ch.titleSw} - inakuja / coming soon')),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // ── Quick links ──
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _LinkChip(
                icon: Icons.gavel_rounded,
                label: 'Haki za Binadamu',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Haki za Binadamu / Human Rights - coming soon')),
                  );
                },
              ),
              _LinkChip(
                icon: Icons.quiz_rounded,
                label: 'Mtihani',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QuizPage()),
                ),
              ),
              _LinkChip(
                icon: Icons.bookmark_rounded,
                label: 'Alama',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Alama / Bookmarks - coming soon')),
                  );
                },
              ),
              _LinkChip(
                icon: Icons.menu_book_rounded,
                label: 'Kamusi',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kamusi / Glossary - coming soon')),
                  );
                },
              ),
            ],
          ),
        ],
    );
  }
}

class _LinkChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _LinkChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = (MediaQuery.of(context).size.width - 44) / 2;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: w,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: _kPrimary, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _kPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
