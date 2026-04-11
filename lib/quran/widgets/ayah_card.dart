// lib/quran/widgets/ayah_card.dart
import 'package:flutter/material.dart';
import '../models/quran_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class AyahCard extends StatelessWidget {
  final Ayah ayah;
  final bool showTranslation;
  final VoidCallback? onBookmark;
  final VoidCallback? onPlay;
  final VoidCallback? onShare;

  const AyahCard({
    super.key,
    required this.ayah,
    this.showTranslation = true,
    this.onBookmark,
    this.onPlay,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${ayah.surahNumber}:${ayah.ayahNumber}',
                  style: const TextStyle(
                    color: _kPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              if (onPlay != null)
                IconButton(
                  icon: const Icon(Icons.play_circle_outline_rounded, size: 20),
                  color: _kSecondary,
                  onPressed: onPlay,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
              if (onBookmark != null)
                IconButton(
                  icon: const Icon(Icons.bookmark_border_rounded, size: 20),
                  color: _kSecondary,
                  onPressed: onBookmark,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
              if (onShare != null)
                IconButton(
                  icon: const Icon(Icons.share_rounded, size: 20),
                  color: _kSecondary,
                  onPressed: onShare,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            ayah.textArabic,
            style: const TextStyle(
              color: _kPrimary,
              fontSize: 22,
              height: 2.0,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
          ),
          if (showTranslation && ayah.translationSwahili != null) ...[
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
