// lib/katiba/widgets/chapter_tile.dart
import 'package:flutter/material.dart';
import '../models/katiba_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class ChapterTile extends StatelessWidget {
  final Chapter chapter;
  final VoidCallback? onTap;

  const ChapterTile({super.key, required this.chapter, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _kPrimary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                '${chapter.number}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chapter.titleSw.isNotEmpty
                        ? chapter.titleSw
                        : chapter.titleEn,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _kPrimary,
                    ),
                  ),
                  if (chapter.articleCount > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Ibara ${chapter.articleCount}',
                      style: const TextStyle(fontSize: 12, color: _kSecondary),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _kSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
