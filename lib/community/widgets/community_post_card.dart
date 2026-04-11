// lib/community/widgets/community_post_card.dart
import 'package:flutter/material.dart';
import '../models/community_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class CommunityPostCard extends StatelessWidget {
  final CommunityPost post;
  final VoidCallback? onTap;
  final VoidCallback? onLike;

  const CommunityPostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onLike,
  });

  Color get _typeBadgeColor {
    switch (post.type) {
      case CommunityPostType.alert:
        return Colors.red.shade100;
      case CommunityPostType.question:
        return Colors.blue.shade100;
      case CommunityPostType.recommendation:
        return Colors.green.shade100;
      case CommunityPostType.event:
        return Colors.orange.shade100;
      case CommunityPostType.general:
        return Colors.grey.shade100;
    }
  }

  Color get _typeTextColor {
    switch (post.type) {
      case CommunityPostType.alert:
        return Colors.red.shade700;
      case CommunityPostType.question:
        return Colors.blue.shade700;
      case CommunityPostType.recommendation:
        return Colors.green.shade700;
      case CommunityPostType.event:
        return Colors.orange.shade700;
      case CommunityPostType.general:
        return Colors.grey.shade700;
    }
  }

  IconData get _typeIcon {
    switch (post.type) {
      case CommunityPostType.alert:
        return Icons.warning_amber_rounded;
      case CommunityPostType.question:
        return Icons.help_outline_rounded;
      case CommunityPostType.recommendation:
        return Icons.thumb_up_alt_rounded;
      case CommunityPostType.event:
        return Icons.event_rounded;
      case CommunityPostType.general:
        return Icons.chat_bubble_outline_rounded;
    }
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'sasa hivi';
    if (diff.inMinutes < 60) return 'dak ${diff.inMinutes}';
    if (diff.inHours < 24) return 'saa ${diff.inHours}';
    if (diff.inDays < 7) return 'siku ${diff.inDays}';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: user + type badge
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: post.userAvatar != null
                      ? NetworkImage(post.userAvatar!)
                      : null,
                  child: post.userAvatar == null
                      ? Text(
                          post.userName.isNotEmpty
                              ? post.userName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _kPrimary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.userName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _timeAgo(post.createdAt),
                        style:
                            const TextStyle(fontSize: 12, color: _kSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _typeBadgeColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_typeIcon, size: 14, color: _typeTextColor),
                      const SizedBox(width: 4),
                      Text(
                        post.type.displayName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _typeTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Content
            Text(
              post.content,
              style: const TextStyle(fontSize: 14, color: _kPrimary, height: 1.4),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            if (post.location != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: _kSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      post.location!,
                      style: const TextStyle(fontSize: 12, color: _kSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            // Actions
            Row(
              children: [
                GestureDetector(
                  onTap: onLike,
                  child: Row(
                    children: [
                      Icon(
                        post.isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 18,
                        color: post.isLiked ? Colors.red : _kSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${post.likesCount}',
                        style:
                            const TextStyle(fontSize: 13, color: _kSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline_rounded,
                        size: 18, color: _kSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${post.commentsCount}',
                      style: const TextStyle(fontSize: 13, color: _kSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
