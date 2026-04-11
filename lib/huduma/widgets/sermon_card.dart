// lib/huduma/widgets/sermon_card.dart
import 'package:flutter/material.dart';
import '../models/huduma_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class SermonCard extends StatelessWidget {
  final Sermon sermon;
  final VoidCallback? onTap;

  const SermonCard({super.key, required this.sermon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _kPrimary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                sermon.videoUrl != null
                    ? Icons.videocam_rounded
                    : Icons.headphones_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sermon.title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(sermon.speakerName,
                      style: const TextStyle(fontSize: 12, color: _kSecondary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(sermon.durationFormatted,
                          style: const TextStyle(fontSize: 11, color: _kSecondary)),
                      const SizedBox(width: 10),
                      Text(sermon.date,
                          style: const TextStyle(fontSize: 11, color: _kSecondary)),
                      if (sermon.topic != null) ...[
                        const SizedBox(width: 10),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(sermon.topic!,
                                style: const TextStyle(fontSize: 10, color: _kSecondary),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.play_circle_rounded, size: 28, color: _kPrimary),
          ],
        ),
      ),
    );
  }
}
