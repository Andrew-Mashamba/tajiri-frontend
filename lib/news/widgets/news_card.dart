// lib/news/widgets/news_card.dart
import 'package:flutter/material.dart';
import '../models/news_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class NewsCard extends StatelessWidget {
  final NewsArticle article;
  final VoidCallback? onTap;
  final VoidCallback? onSave;

  const NewsCard({super.key, required this.article, this.onTap, this.onSave});

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'sasa hivi';
    if (diff.inMinutes < 60) return 'dak ${diff.inMinutes}';
    if (diff.inHours < 24) return 'saa ${diff.inHours}';
    if (diff.inDays < 7) return 'siku ${diff.inDays}';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                image: article.imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(article.imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: article.imageUrl == null
                  ? Center(child: Icon(article.category.icon, size: 28, color: _kSecondary))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category + time
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _kPrimary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          article.category.displayName,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _kPrimary),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _timeAgo(article.publishedAt),
                        style: const TextStyle(fontSize: 11, color: _kSecondary),
                      ),
                      const Spacer(),
                      if (onSave != null)
                        GestureDetector(
                          onTap: onSave,
                          child: Icon(
                            article.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                            size: 18,
                            color: _kSecondary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Title
                  Text(
                    article.title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary, height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Source + read time
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          article.source,
                          style: const TextStyle(fontSize: 12, color: _kSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${article.readTimeMinutes} dak kusoma',
                        style: const TextStyle(fontSize: 11, color: _kSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
