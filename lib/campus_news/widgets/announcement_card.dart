// lib/campus_news/widgets/announcement_card.dart
import 'package:flutter/material.dart';
import '../models/campus_news_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class AnnouncementCard extends StatelessWidget {
  final CampusAnnouncement announcement;
  final VoidCallback? onTap;
  const AnnouncementCard({super.key, required this.announcement, this.onTap});

  String _timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return 'dak ${diff.inMinutes}';
    if (diff.inHours < 24) return 'saa ${diff.inHours}';
    if (diff.inDays < 7) return 'siku ${diff.inDays}';
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: announcement.isEmergency ? Colors.red.shade200 : Colors.grey.shade200),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(4)),
              child: Text(announcement.category.displayName, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _kPrimary)),
            ),
            if (announcement.isVerified) ...[const SizedBox(width: 6), Icon(Icons.verified_rounded, size: 14, color: Colors.blue.shade600)],
            if (announcement.isEmergency) ...[const SizedBox(width: 6), const Icon(Icons.warning_rounded, size: 14, color: Colors.red)],
            const Spacer(),
            Text(_timeAgo(announcement.publishedAt), style: const TextStyle(fontSize: 11, color: _kSecondary)),
          ]),
          const SizedBox(height: 8),
          Text(announcement.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(announcement.body, style: const TextStyle(fontSize: 13, color: _kSecondary, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Row(children: [
            Text(announcement.source, style: const TextStyle(fontSize: 12, color: _kSecondary)),
            const Spacer(),
            const Icon(Icons.comment_rounded, size: 14, color: _kSecondary),
            const SizedBox(width: 4),
            Text('${announcement.commentCount}', style: const TextStyle(fontSize: 12, color: _kSecondary)),
          ]),
        ]),
      ),
    );
  }
}
