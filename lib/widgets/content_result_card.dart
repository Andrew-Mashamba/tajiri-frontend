import 'package:flutter/material.dart';
import '../models/content_engine_models.dart';
import '../models/post_models.dart';
import '../l10n/app_strings_scope.dart';
import 'post_card.dart';

/// Router widget that renders the correct card per content sourceType.
/// For post/clip -> PostCard. For gossip_thread -> generic card.
/// For other types -> compact preview card.
class ContentResultCard extends StatelessWidget {
  final ContentDocumentResult result;
  final int currentUserId;
  final Function(Post)? onPostTap;
  final Function(String)? onHashtagTap;
  final Function(String)? onMentionTap;
  final Function(int)? onUserTap;
  final VoidCallback? onTap;

  const ContentResultCard({
    super.key,
    required this.result,
    required this.currentUserId,
    this.onPostTap,
    this.onHashtagTap,
    this.onMentionTap,
    this.onUserTap,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Show context reason label if non-empty
    final reason = result.context.reasonLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (reason.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
            child: Row(
              children: [
                Icon(
                  _reasonIcon(result.context.reason),
                  size: 14,
                  color: Colors.black54,
                ),
                const SizedBox(width: 4),
                Text(
                  reason,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        _buildCard(context),
      ],
    );
  }

  Widget _buildCard(BuildContext context) {
    // Post or Clip -> delegate to PostCard
    if ((result.isPost || result.isClip) && result.post != null) {
      return PostCard(
        post: result.post!,
        currentUserId: currentUserId,
        onTap: onPostTap != null ? () => onPostTap!(result.post!) : null,
        onHashtagTap: onHashtagTap,
        onMentionTap: onMentionTap,
        onUserTap: onUserTap != null ? () => onUserTap!(result.post!.userId) : null,
      );
    }

    // Gossip Thread -> generic card
    if (result.isGossipThread && result.sourceJson != null) {
      return _buildGenericCard(
        context,
        icon: Icons.forum_rounded,
        typeLabel: 'Mada',
      );
    }

    // Music
    if (result.isMusic) {
      return _buildMusicCard(context);
    }

    // Event
    if (result.isEvent) {
      return _buildEventCard(context);
    }

    // Campaign (Michango)
    if (result.isCampaign) {
      return _buildCampaignCard(context);
    }

    // Group
    if (result.isGroup) {
      return _buildGroupCard(context);
    }

    // Product
    if (result.isProduct) {
      return _buildProductCard(context);
    }

    // User Profile
    if (result.isUserProfile) {
      return _buildUserCard(context);
    }

    // Stream
    if (result.isStream) {
      return _buildGenericCard(context, icon: Icons.live_tv_rounded, typeLabel: 'Live');
    }

    // Page
    if (result.isPage) {
      return _buildGenericCard(context, icon: Icons.flag_rounded, typeLabel: 'Ukurasa');
    }

    // Fallback
    return _buildGenericCard(context, icon: Icons.article_rounded, typeLabel: result.sourceType);
  }

  Widget _buildMusicCard(BuildContext context) {
    final src = result.sourceJson ?? {};
    final title = src['title']?.toString() ?? result.title ?? '';
    final artist = src['artist_name']?.toString() ?? src['artist']?.toString() ?? '';
    final albumArt = src['cover_url']?.toString() ?? src['album_art']?.toString();
    final duration = src['duration']?.toString() ?? '';

    return _tappableCard(
      context,
      child: Row(
        children: [
          // Album art
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 56,
              height: 56,
              color: Colors.grey[200],
              child: albumArt != null
                  ? Image.network(albumArt, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.music_note_rounded, color: Colors.black38))
                  : const Icon(Icons.music_note_rounded, color: Colors.black38),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                if (artist.isNotEmpty)
                  Text(artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black54, fontSize: 13)),
                if (duration.isNotEmpty)
                  Text(duration,
                      style: const TextStyle(color: Colors.black38, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.play_circle_filled_rounded,
                size: 36, color: Color(0xFF1A1A1A)),
            onPressed: onTap,
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(BuildContext context) {
    final strings = AppStringsScope.of(context) ?? AppStrings('en');
    final src = result.sourceJson ?? {};
    final name = src['name']?.toString() ?? src['title']?.toString() ?? result.title ?? '';
    final date = src['event_date']?.toString() ?? src['start_date']?.toString() ?? '';
    final location = src['location']?.toString() ?? '';
    final rsvpCount = src['rsvp_count'] ?? src['attendees_count'] ?? 0;

    return _tappableCard(
      context,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.event_rounded, color: Colors.black54),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                if (date.isNotEmpty)
                  Text(date,
                      style: const TextStyle(color: Colors.black54, fontSize: 12)),
                if (location.isNotEmpty)
                  Text(location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black38, fontSize: 12)),
                if (rsvpCount > 0)
                  Text('$rsvpCount ${strings.nGoingCount}',
                      style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignCard(BuildContext context) {
    final strings = AppStringsScope.of(context) ?? AppStrings('en');
    final src = result.sourceJson ?? {};
    final title = src['title']?.toString() ?? result.title ?? '';
    final raised = src['amount_raised'] ?? src['raised'] ?? 0;
    final goal = src['goal_amount'] ?? src['goal'] ?? 1;
    final pct = goal > 0 ? ((raised / goal) * 100).clamp(0, 100).toInt() : 0;
    final daysLeft = src['days_remaining'] ?? src['days_left'] ?? 0;

    return _tappableCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100,
              backgroundColor: Colors.grey[200],
              color: const Color(0xFF1A1A1A),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$pct% ${strings.funded}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              if (daysLeft > 0)
                Text('$daysLeft ${strings.ceDaysRemaining}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(BuildContext context) {
    final strings = AppStringsScope.of(context) ?? AppStrings('en');
    final src = result.sourceJson ?? {};
    final name = src['name']?.toString() ?? result.title ?? '';
    final memberCount = src['member_count'] ?? src['members_count'] ?? 0;
    final privacy = src['privacy']?.toString() ?? 'public';

    return _tappableCard(
      context,
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey[200],
            child: const Icon(Icons.group_rounded, color: Colors.black54),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(
                    '$memberCount ${strings.ceMembersCount} · ${privacy[0].toUpperCase()}${privacy.substring(1)}',
                    style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1A1A1A),
              side: const BorderSide(color: Color(0xFF1A1A1A)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              minimumSize: const Size(0, 36),
            ),
            child: Text(strings.joinGroup),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context) {
    final src = result.sourceJson ?? {};
    final name = src['name']?.toString() ?? src['title']?.toString() ?? result.title ?? '';
    final price = src['price'] ?? src['amount'] ?? 0;
    final seller = src['seller_name']?.toString() ?? src['shop_name']?.toString() ?? '';
    final imageUrl = src['image_url']?.toString() ?? src['thumbnail']?.toString();

    return _tappableCard(
      context,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 80,
              height: 80,
              color: Colors.grey[200],
              child: imageUrl != null
                  ? Image.network(imageUrl, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.shopping_bag_rounded, color: Colors.black38))
                  : const Icon(Icons.shopping_bag_rounded, color: Colors.black38),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 4),
                Text('TZS ${_formatNumber(price)}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                if (seller.isNotEmpty)
                  Text(seller,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(BuildContext context) {
    final strings = AppStringsScope.of(context) ?? AppStrings('en');
    final src = result.sourceJson ?? {};
    final name = src['name']?.toString() ?? src['display_name']?.toString() ?? result.title ?? '';
    final username = src['username']?.toString() ?? '';
    final avatarUrl = src['avatar_url']?.toString() ?? src['profile_photo']?.toString();
    final followers = src['followers_count'] ?? 0;

    return _tappableCard(
      context,
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey[200],
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? const Icon(Icons.person_rounded, color: Colors.black54)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                if (username.isNotEmpty)
                  Text('@$username',
                      style: const TextStyle(color: Colors.black54, fontSize: 12)),
                Text('$followers ${strings.followersCount}',
                    style: const TextStyle(color: Colors.black38, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenericCard(BuildContext context,
      {required IconData icon, required String typeLabel}) {
    return _tappableCard(
      context,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.black54),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.title ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text(typeLabel,
                    style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tappableCard(BuildContext context, {required Widget child}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: child,
      ),
    );
  }

  IconData _reasonIcon(String reason) {
    switch (reason) {
      case 'trending':
        return Icons.trending_up_rounded;
      case 'social':
        return Icons.people_rounded;
      case 'personalized':
        return Icons.auto_awesome_rounded;
      case 'exploration':
        return Icons.explore_rounded;
      case 'sponsored':
        return Icons.campaign_rounded;
      case 'similar':
        return Icons.recommend_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  static String _formatNumber(dynamic n) {
    final value =
        n is int ? n : (n is double ? n.toInt() : int.tryParse(n.toString()) ?? 0);
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)},${(value % 1000).toString().padLeft(3, '0')}';
    }
    return value.toString();
  }
}
