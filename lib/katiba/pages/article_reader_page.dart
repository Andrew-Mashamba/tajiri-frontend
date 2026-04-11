// lib/katiba/pages/article_reader_page.dart
import 'package:flutter/material.dart';
import '../models/katiba_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class ArticleReaderPage extends StatefulWidget {
  final Article article;
  const ArticleReaderPage({super.key, required this.article});

  @override
  State<ArticleReaderPage> createState() => _ArticleReaderPageState();
}

class _ArticleReaderPageState extends State<ArticleReaderPage> {
  bool _showSwahili = true;
  double _fontSize = 16;
  bool _bookmarked = false;

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
    final text = _showSwahili ? article.textSw : article.textEn;
    final summary = _showSwahili ? article.summarySw : article.summaryEn;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: const BackButton(color: _kPrimary),
        title: Text('Ibara ${article.number}',
            style: const TextStyle(color: _kPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(
              _bookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: _kPrimary,
            ),
            onPressed: () => setState(() => _bookmarked = !_bookmarked),
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded, color: _kPrimary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Kushiriki / Share - coming soon')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Language toggle ──
          Row(
            children: [
              _LangToggle(label: 'Kiswahili', active: _showSwahili,
                  onTap: () => setState(() => _showSwahili = true)),
              const SizedBox(width: 8),
              _LangToggle(label: 'English', active: !_showSwahili,
                  onTap: () => setState(() => _showSwahili = false)),
              const Spacer(),
              // Font size controls
              IconButton(
                icon: const Icon(Icons.text_decrease_rounded, size: 20, color: _kSecondary),
                onPressed: () => setState(() => _fontSize = (_fontSize - 2).clamp(12, 24)),
              ),
              IconButton(
                icon: const Icon(Icons.text_increase_rounded, size: 20, color: _kSecondary),
                onPressed: () => setState(() => _fontSize = (_fontSize + 2).clamp(12, 24)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Summary ──
          if (summary.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _kPrimary.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _showSwahili ? 'Maelezo Rahisi' : 'Plain Summary',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
                  ),
                  const SizedBox(height: 6),
                  Text(summary, style: TextStyle(fontSize: _fontSize - 2, color: _kSecondary, height: 1.5)),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ── Full text ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SelectableText(
              text,
              style: TextStyle(fontSize: _fontSize, color: _kPrimary, height: 1.7),
            ),
          ),

          // ── Audio play ──
          if (article.audioUrl.isNotEmpty) ...[
            const SizedBox(height: 16),
            InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sikiliza / Listen - coming soon')),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_circle_rounded, color: _kPrimary, size: 24),
                    SizedBox(width: 8),
                    Text('Sikiliza / Listen', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _kPrimary)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LangToggle extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _LangToggle({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? _kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500,
              color: active ? Colors.white : _kSecondary,
            )),
      ),
    );
  }
}
