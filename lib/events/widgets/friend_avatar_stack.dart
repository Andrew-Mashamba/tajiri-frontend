import 'package:flutter/material.dart';
import '../models/event_rsvp.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

/// Overlapping circular avatars showing friends attending. Max [maxShow] shown,
/// remainder displayed as a "+N" circle.
class FriendAvatarStack extends StatelessWidget {
  final List<EventAttendee> attendees;
  final int maxShow;
  final double size;

  const FriendAvatarStack({
    super.key,
    required this.attendees,
    this.maxShow = 4,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    if (attendees.isEmpty) return const SizedBox.shrink();

    final show = attendees.take(maxShow).toList();
    final extra = attendees.length - show.length;
    final totalItems = show.length + (extra > 0 ? 1 : 0);
    final stackWidth = (size * 0.7) * totalItems + size * 0.3;

    return SizedBox(
      height: size,
      width: stackWidth,
      child: Stack(
        children: [
          ...show.asMap().entries.map((entry) => Positioned(
                left: entry.key * size * 0.7,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: size / 2 - 1,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: entry.value.avatarUrl != null
                        ? NetworkImage(entry.value.avatarUrl!)
                        : null,
                    child: entry.value.avatarUrl == null
                        ? Text(
                            entry.value.firstName.isNotEmpty
                                ? entry.value.firstName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: size * 0.4,
                              color: _kSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : null,
                  ),
                ),
              )),
          if (extra > 0)
            Positioned(
              left: show.length * size * 0.7,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: CircleAvatar(
                  radius: size / 2 - 1,
                  backgroundColor: _kPrimary,
                  child: Text(
                    '+$extra',
                    style: TextStyle(
                      fontSize: size * 0.35,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
