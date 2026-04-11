import 'package:flutter/material.dart';
import '../models/event_session.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class SessionCard extends StatelessWidget {
  final EventSession session;
  const SessionCard({super.key, required this.session});

  String _formatTime(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${_formatTime(session.startTime)} - ${_formatTime(session.endTime)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kSecondary)),
              if (session.track != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                  child: Text(session.track!, style: const TextStyle(fontSize: 11, color: _kSecondary)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(session.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary)),
          if (session.location != null) ...[
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.room_rounded, size: 14, color: _kSecondary),
              const SizedBox(width: 4),
              Text(session.location!, style: const TextStyle(fontSize: 12, color: _kSecondary)),
            ]),
          ],
          if (session.speakers.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: session.speakers.map((s) => Chip(
                avatar: CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: s.avatarUrl != null ? NetworkImage(s.avatarUrl!) : null,
                ),
                label: Text(s.name, style: const TextStyle(fontSize: 11)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                backgroundColor: Colors.grey.shade50,
                side: BorderSide.none,
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
