// lib/maulid/widgets/event_card.dart
import 'package:flutter/material.dart';
import '../models/maulid_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class MaulidEventCard extends StatelessWidget {
  final MaulidEvent event;
  final VoidCallback? onTap;

  const MaulidEventCard({super.key, required this.event, this.onTap});

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
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${event.startTime.day}',
                      style: const TextStyle(color: _kPrimary, fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  Text('${event.startTime.month}',
                      style: const TextStyle(
                          color: _kSecondary, fontSize: 10)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.titleSwahili.isNotEmpty
                        ? event.titleSwahili : event.title,
                    style: const TextStyle(color: _kPrimary, fontSize: 15,
                        fontWeight: FontWeight.w500),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  Text('${event.venue} \u2022 ${event.organizerName}',
                      style: const TextStyle(
                          color: _kSecondary, fontSize: 12),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (event.isLiveStreamable)
              const Icon(Icons.live_tv_rounded, color: Colors.red, size: 18),
          ],
        ),
      ),
    );
  }
}
