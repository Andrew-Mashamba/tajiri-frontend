import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../l10n/app_strings_scope.dart';
import '../../../models/friend_models.dart';

/// 64dp follower row. In bulk mode the avatar shrinks and a Checkbox
/// appears on the left. The right edge carries a single-slot status
/// badge with priority Muted > New > Mutual.
class FollowerRow extends StatelessWidget {
  final FollowUser follower;
  final bool inBulkMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final ValueChanged<bool?>? onCheckboxChanged;

  const FollowerRow({
    super.key,
    required this.follower,
    required this.inBulkMode,
    required this.isSelected,
    required this.onTap,
    this.onLongPress,
    this.onCheckboxChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    final avatarRadius = inBulkMode ? 16.0 : 20.0;

    final displayName = _displayName(follower);
    final handle = (follower.username ?? '').isNotEmpty ? '@${follower.username}' : '';
    final semanticLabel = handle.isEmpty ? displayName : '$displayName, $handle';

    return Semantics(
      container: true,
      button: true,
      label: semanticLabel,
      child: Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        onLongPress: inBulkMode ? null : onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (inBulkMode) ...[
                Checkbox(
                  value: isSelected,
                  onChanged: onCheckboxChanged,
                  activeColor: const Color(0xFF1A1A1A),
                ),
                const SizedBox(width: 4),
              ],
              _Avatar(follower: follower, radius: avatarRadius),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayName(follower),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle(follower, isSw),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ..._badge(follower, isSw),
            ],
          ),
        ),
      ),
    ),
    );
  }

  String _displayName(FollowUser f) {
    final n = f.fullName;
    return n.isEmpty ? (f.username ?? '') : n;
  }

  String _subtitle(FollowUser f, bool isSw) {
    final handle = (f.username ?? '').isNotEmpty ? '@${f.username}' : '';
    final last = f.lastInteractionAt;
    if (last == null) return handle;
    final diff = DateTime.now().difference(last);
    String ago;
    if (diff.inMinutes < 60) {
      ago = isSw ? 'sasa hivi' : 'just now';
    } else if (diff.inHours < 24) {
      ago = isSw ? 'saa ${diff.inHours} zilizopita' : '${diff.inHours}h ago';
    } else if (diff.inDays < 30) {
      ago = isSw ? 'siku ${diff.inDays} zilizopita' : '${diff.inDays}d ago';
    } else {
      final mo = (diff.inDays / 30).floor();
      ago = isSw ? 'miezi $mo iliyopita' : '${mo}mo ago';
    }
    return handle.isEmpty ? ago : '$handle · $ago';
  }

  List<Widget> _badge(FollowUser f, bool isSw) {
    if (f.isMuted) {
      return [_badgeBox(isSw ? 'Imenyamazishwa' : 'Muted', const Color(0xFF666666))];
    }
    final isNew = f.followedAt != null &&
        DateTime.now().difference(f.followedAt!).inDays < 7;
    if (isNew) {
      return [_badgeBox(isSw ? 'Mpya' : 'New', const Color(0xFF1A1A1A))];
    }
    if (f.isMutual) {
      return [_badgeBox(isSw ? 'Pande zote' : 'Mutual', const Color(0xFF1A1A1A))];
    }
    return const [];
  }

  Widget _badgeBox(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
        ),
      );
}

class _Avatar extends StatelessWidget {
  final FollowUser follower;
  final double radius;
  const _Avatar({required this.follower, required this.radius});

  @override
  Widget build(BuildContext context) {
    final url = follower.profilePhotoUrl;
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFFF0F0F0),
        backgroundImage: CachedNetworkImageProvider(url),
        onBackgroundImageError: (_, _) {},
      );
    }
    final n = follower.fullName.isNotEmpty
        ? follower.fullName[0]
        : (follower.username ?? '?');
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFE5E5E5),
      child: Text(
        n.isNotEmpty ? n[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: radius * 0.7,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1A1A1A),
        ),
      ),
    );
  }
}
