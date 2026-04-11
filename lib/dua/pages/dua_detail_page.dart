// lib/dua/pages/dua_detail_page.dart
import 'package:flutter/material.dart';
import '../models/dua_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class DuaDetailPage extends StatelessWidget {
  final Dua dua;
  const DuaDetailPage({super.key, required this.dua});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg, elevation: 0, scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context)),
        title: Text(
          dua.titleSwahili.isNotEmpty ? dua.titleSwahili : dua.titleEnglish,
          style: const TextStyle(color: _kPrimary, fontSize: 18,
              fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: Icon(dua.isFavorite
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
                color: _kPrimary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Favorite toggled / Imebadilishwa'),
                  backgroundColor: _kPrimary,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded, color: _kPrimary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Share coming soon / Kushiriki kunakuja'),
                  backgroundColor: _kPrimary,
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ─── Arabic Text ──────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200)),
              child: Column(
                children: [
                  Text(
                    dua.textArabic,
                    style: const TextStyle(
                      color: _kPrimary, fontSize: 24, height: 2.0,
                      fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                  ),
                  if (dua.repeatCount != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12)),
                      child: Text('Rudia mara ${dua.repeatCount}',
                          style: const TextStyle(color: _kSecondary,
                              fontSize: 12)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ─── Transliteration ──────────────────────────
            if (dua.transliteration != null) ...[
              const Text('Matamshi',
                  style: TextStyle(color: _kPrimary, fontSize: 14,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200)),
                child: Text(dua.transliteration!,
                    style: const TextStyle(color: _kSecondary, fontSize: 14,
                        height: 1.6, fontStyle: FontStyle.italic)),
              ),
              const SizedBox(height: 16),
            ],

            // ─── Swahili Translation ──────────────────────
            const Text('Tafsiri (Kiswahili)',
                style: TextStyle(color: _kPrimary, fontSize: 14,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200)),
              child: Text(dua.translationSwahili,
                  style: const TextStyle(color: _kPrimary, fontSize: 15,
                      height: 1.6)),
            ),
            const SizedBox(height: 16),

            // ─── Source ───────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.source_rounded,
                      color: _kSecondary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Chanzo: ${dua.source}'
                      '${dua.sourceRef != null ? ' (${dua.sourceRef})' : ''}',
                      style: const TextStyle(color: _kSecondary, fontSize: 13),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ─── Audio Button ─────────────────────────────
            if (dua.audioUrl != null)
              SizedBox(
                width: double.infinity, height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Audio playback coming soon / Sauti inakuja'),
                        backgroundColor: _kPrimary,
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_circle_rounded, size: 20),
                  label: const Text('Listen / Sikiliza'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kPrimary,
                    side: const BorderSide(color: _kPrimary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
