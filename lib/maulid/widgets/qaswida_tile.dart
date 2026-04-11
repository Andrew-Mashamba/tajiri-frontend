// lib/maulid/widgets/qaswida_tile.dart
import 'package:flutter/material.dart';
import '../models/maulid_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class QaswidaTile extends StatelessWidget {
  final QaswidaRecording recording;
  final VoidCallback? onPlay;

  const QaswidaTile({super.key, required this.recording, this.onPlay});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.play_circle_rounded, size: 36),
            color: _kPrimary,
            onPressed: onPlay,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(recording.title,
                    style: const TextStyle(color: _kPrimary, fontSize: 14,
                        fontWeight: FontWeight.w500),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(recording.groupName,
                    style: const TextStyle(
                        color: _kSecondary, fontSize: 12),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Text(recording.durationFormatted,
              style: const TextStyle(color: _kSecondary, fontSize: 12,
                  fontFeatures: [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }
}
