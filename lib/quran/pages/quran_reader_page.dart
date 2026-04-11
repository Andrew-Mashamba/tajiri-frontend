// lib/quran/pages/quran_reader_page.dart
import 'package:flutter/material.dart';
import '../models/quran_models.dart';
import '../services/quran_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class QuranReaderPage extends StatefulWidget {
  final int surahNumber;
  final String surahName;

  const QuranReaderPage({
    super.key,
    required this.surahNumber,
    required this.surahName,
  });

  @override
  State<QuranReaderPage> createState() => _QuranReaderPageState();
}

class _QuranReaderPageState extends State<QuranReaderPage> {
  final _service = QuranService();
  List<Ayah> _ayahs = [];
  bool _loading = true;
  bool _showTranslation = true;
  double _fontSize = 22;

  @override
  void initState() {
    super.initState();
    _loadAyahs();
  }

  Future<void> _loadAyahs() async {
    setState(() => _loading = true);
    final result = await _service.getAyahs(
      surahNumber: widget.surahNumber,
      perPage: 300,
    );
    if (mounted) {
      setState(() {
        _ayahs = result.items;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.surahName,
          style: const TextStyle(
            color: _kPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showTranslation
                  ? Icons.translate_rounded
                  : Icons.text_fields_rounded,
              color: _kPrimary,
            ),
            onPressed: () =>
                setState(() => _showTranslation = !_showTranslation),
          ),
          PopupMenuButton<double>(
            icon: const Icon(Icons.text_increase_rounded, color: _kPrimary),
            onSelected: (v) => setState(() => _fontSize = v),
            itemBuilder: (_) => [18.0, 22.0, 26.0, 30.0]
                .map((s) => PopupMenuItem(
                      value: s,
                      child: Text('${s.toInt()}px'),
                    ))
                .toList(),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child:
                    CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
              )
            : _ayahs.isEmpty
                ? const Center(
                    child: Text(
                      'Hakuna aya za sura hii',
                      style: TextStyle(color: _kSecondary, fontSize: 14),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _ayahs.length,
                    itemBuilder: (context, i) {
                      final ayah = _ayahs[i];
                      return _buildAyahCard(ayah);
                    },
                  ),
      ),
    );
  }

  Widget _buildAyahCard(Ayah ayah) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Ayah number badge
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${ayah.ayahNumber}',
                  style: const TextStyle(
                    color: _kPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.play_circle_outline_rounded,
                    size: 20),
                color: _kSecondary,
                onPressed: () {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Audio playback coming soon / Sauti inakuja'),
                      backgroundColor: _kPrimary,
                    ),
                  );
                },
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              IconButton(
                icon: const Icon(Icons.bookmark_border_rounded, size: 20),
                color: _kSecondary,
                onPressed: () {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bookmark saved / Alama imehifadhiwa'),
                      backgroundColor: _kPrimary,
                    ),
                  );
                },
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Arabic text
          Text(
            ayah.textArabic,
            style: TextStyle(
              color: _kPrimary,
              fontSize: _fontSize,
              height: 2.0,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
          ),

          // Translation
          if (_showTranslation && ayah.translationSwahili != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Text(
              ayah.translationSwahili!,
              style: const TextStyle(
                color: _kSecondary,
                fontSize: 14,
                height: 1.6,
              ),
              maxLines: 10,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
