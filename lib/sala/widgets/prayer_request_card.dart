// lib/sala/widgets/prayer_request_card.dart
import 'package:flutter/material.dart';
import '../models/sala_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class PrayerRequestCard extends StatelessWidget {
  final PrayerRequest request;
  final bool isOwn;
  final VoidCallback? onPray;
  final VoidCallback? onTap;

  const PrayerRequestCard({
    super.key,
    required this.request,
    this.isOwn = false,
    this.onPray,
    this.onTap,
  });

  Color get _urgencyColor {
    switch (request.urgency) {
      case PrayerUrgency.high:
        return const Color(0xFFE53935);
      case PrayerUrgency.medium:
        return const Color(0xFFFFA726);
      case PrayerUrgency.low:
        return _kSecondary;
    }
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
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _urgencyColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(request.title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(request.category.label.split(' / ').first,
                      style: const TextStyle(fontSize: 10, color: _kSecondary)),
                ),
              ],
            ),
            if (request.description != null && request.description!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(request.description!,
                  style: const TextStyle(fontSize: 13, color: _kSecondary, height: 1.4),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.people_rounded, size: 16, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text('${request.prayerCount} wanaomba / praying',
                    style: const TextStyle(fontSize: 12, color: _kSecondary)),
                if (request.scriptureRef != null) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.menu_book_rounded, size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text(request.scriptureRef!,
                      style: const TextStyle(fontSize: 12, color: _kSecondary, fontStyle: FontStyle.italic)),
                ],
                const Spacer(),
                if (!isOwn && onPray != null)
                  GestureDetector(
                    onTap: onPray,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _kPrimary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.favorite_rounded, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text('Naomba / Pray',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
