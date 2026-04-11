// lib/kanisa_langu/widgets/announcement_card.dart
import 'package:flutter/material.dart';
import '../models/kanisa_langu_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class AnnouncementCard extends StatelessWidget {
  final ChurchAnnouncement announcement;
  final VoidCallback? onTap;

  const AnnouncementCard({super.key, required this.announcement, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: announcement.isPinned
                ? _kPrimary.withValues(alpha: 0.3)
                : Colors.grey.shade200,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (announcement.isPinned) ...[
                  const Icon(Icons.push_pin_rounded, size: 14, color: _kPrimary),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(announcement.title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(announcement.content,
                style: const TextStyle(fontSize: 13, color: _kSecondary, height: 1.4),
                maxLines: 3, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(
              children: [
                if (announcement.authorName != null)
                  Text(announcement.authorName!,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _kPrimary)),
                const Spacer(),
                Text(announcement.createdAt,
                    style: const TextStyle(fontSize: 11, color: _kSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
