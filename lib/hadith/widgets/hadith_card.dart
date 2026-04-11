// lib/hadith/widgets/hadith_card.dart
import 'package:flutter/material.dart';
import '../models/hadith_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class HadithCard extends StatelessWidget {
  final Hadith hadith;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final VoidCallback? onShare;

  const HadithCard({
    super.key,
    required this.hadith,
    this.onTap,
    this.onFavorite,
    this.onShare,
  });

  Color _gradeColor(String grade) {
    switch (grade.toLowerCase()) {
      case 'sahih': return Colors.green;
      case 'hasan': return Colors.orange;
      default: return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _gradeColor(hadith.grade).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6)),
                  child: Text(hadith.grade.toUpperCase(),
                      style: TextStyle(
                        color: _gradeColor(hadith.grade), fontSize: 10,
                        fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                Text('#${hadith.hadithNumber}',
                    style: const TextStyle(
                        color: _kSecondary, fontSize: 12)),
                const Spacer(),
                if (onFavorite != null)
                  IconButton(
                    icon: Icon(hadith.isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                        size: 18),
                    color: hadith.isFavorite ? Colors.red : _kSecondary,
                    onPressed: onFavorite,
                    constraints: const BoxConstraints(
                        minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                  ),
                if (onShare != null)
                  IconButton(
                    icon: const Icon(Icons.share_rounded, size: 18),
                    color: _kSecondary,
                    onPressed: onShare,
                    constraints: const BoxConstraints(
                        minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              hadith.textArabic,
              style: const TextStyle(
                  color: _kPrimary, fontSize: 16, height: 1.6),
              textDirection: TextDirection.rtl,
              maxLines: 3, overflow: TextOverflow.ellipsis,
            ),
            if (hadith.translationSwahili != null) ...[
              const SizedBox(height: 6),
              Text(hadith.translationSwahili!,
                  style: const TextStyle(
                      color: _kSecondary, fontSize: 13, height: 1.4),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 6),
            Text('Rawi: ${hadith.narrator}',
                style: const TextStyle(color: _kSecondary, fontSize: 11),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
