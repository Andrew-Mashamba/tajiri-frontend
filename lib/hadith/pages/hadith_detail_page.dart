// lib/hadith/pages/hadith_detail_page.dart
import 'package:flutter/material.dart';
import '../models/hadith_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class HadithDetailPage extends StatelessWidget {
  final Hadith hadith;
  const HadithDetailPage({super.key, required this.hadith});

  Color _gradeColor(String grade) {
    switch (grade.toLowerCase()) {
      case 'sahih': return Colors.green;
      case 'hasan': return Colors.orange;
      default: return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg, elevation: 0, scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context)),
        title: Text('Hadith #${hadith.hadithNumber}',
            style: const TextStyle(color: _kPrimary, fontSize: 18,
                fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(hadith.isFavorite
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
            // ─── Grade Badge ──────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _gradeColor(hadith.grade).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _gradeColor(hadith.grade).withValues(alpha: 0.3))),
                  child: Text(hadith.grade.toUpperCase(),
                      style: TextStyle(
                        color: _gradeColor(hadith.grade), fontSize: 12,
                        fontWeight: FontWeight.w600)),
                ),
                if (hadith.gradeScholar != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('(${hadith.gradeScholar})',
                        style: const TextStyle(
                            color: _kSecondary, fontSize: 12),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // ─── Arabic Text ──────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200)),
              child: Text(
                hadith.textArabic,
                style: const TextStyle(
                  color: _kPrimary, fontSize: 20, height: 2.0,
                  fontWeight: FontWeight.w500),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(height: 16),

            // ─── Swahili Translation ──────────────────────
            if (hadith.translationSwahili != null) ...[
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
                child: Text(hadith.translationSwahili!,
                    style: const TextStyle(
                        color: _kPrimary, fontSize: 15, height: 1.6)),
              ),
              const SizedBox(height: 16),
            ],

            // ─── Narrator ─────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.person_rounded,
                      color: _kSecondary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Rawi: ${hadith.narrator}',
                        style: const TextStyle(
                            color: _kSecondary, fontSize: 13),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ─── Isnad ────────────────────────────────────
            if (hadith.isnad != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mlolongo wa Wapokezi (Isnad)',
                        style: TextStyle(color: _kPrimary, fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(hadith.isnad!,
                        style: const TextStyle(
                            color: _kSecondary, fontSize: 13, height: 1.5),
                        maxLines: 10, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
