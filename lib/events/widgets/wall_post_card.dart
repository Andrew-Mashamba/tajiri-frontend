import 'package:flutter/material.dart';
import '../models/event_wall.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class WallPostCard extends StatelessWidget {
  final EventWallPost post;
  final VoidCallback? onLike;
  final VoidCallback? onPin;
  final bool showPin;
  const WallPostCard({super.key, required this.post, this.onLike, this.onPin, this.showPin = false});

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
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: post.user?.avatarUrl != null ? NetworkImage(post.user!.avatarUrl!) : null,
                child: post.user?.avatarUrl == null ? Text(post.user?.firstName.isNotEmpty == true ? post.user!.firstName[0] : '?', style: const TextStyle(color: _kSecondary)) : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.user?.fullName ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                    Text(_timeAgo(post.createdAt), style: const TextStyle(fontSize: 11, color: _kSecondary)),
                  ],
                ),
              ),
              if (post.isPinned) const Icon(Icons.push_pin_rounded, size: 16, color: _kSecondary),
              if (post.isAnnouncement) Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(4)),
                child: const Text('📢', style: TextStyle(fontSize: 10)),
              ),
            ],
          ),
          if (post.content != null && post.content!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(post.content!, style: const TextStyle(fontSize: 14, color: _kPrimary, height: 1.5)),
          ],
          if (post.mediaUrls.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(post.mediaUrls.first, height: 180, width: double.infinity, fit: BoxFit.cover),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              GestureDetector(
                onTap: onLike,
                child: Row(children: [
                  Icon(post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 18, color: post.isLiked ? Colors.red : _kSecondary),
                  const SizedBox(width: 4),
                  Text('${post.likesCount}', style: const TextStyle(fontSize: 12, color: _kSecondary)),
                ]),
              ),
              const SizedBox(width: 16),
              Row(children: [
                const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: _kSecondary),
                const SizedBox(width: 4),
                Text('${post.commentsCount}', style: const TextStyle(fontSize: 12, color: _kSecondary)),
              ]),
              const Spacer(),
              if (showPin)
                GestureDetector(onTap: onPin, child: Icon(Icons.push_pin_outlined, size: 18, color: _kSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'now';
  }
}
