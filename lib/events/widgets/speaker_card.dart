import 'package:flutter/material.dart';
import '../models/event_session.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class SpeakerCard extends StatelessWidget {
  final EventSpeaker speaker;
  const SpeakerCard({super.key, required this.speaker});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: speaker.avatarUrl != null ? NetworkImage(speaker.avatarUrl!) : null,
            child: speaker.avatarUrl == null ? const Icon(Icons.person_rounded, color: _kSecondary) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(speaker.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary)),
                if (speaker.title != null) Text(speaker.title!, style: const TextStyle(fontSize: 13, color: _kSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
