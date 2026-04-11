// lib/owners_club/pages/community_feed_page.dart
import 'package:flutter/material.dart';
import '../models/owners_club_models.dart';
import '../services/owners_club_service.dart';
import 'vehicle_showcase_page.dart';
import 'community_events_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class CommunityFeedPage extends StatefulWidget {
  final Community community;
  const CommunityFeedPage({super.key, required this.community});
  @override
  State<CommunityFeedPage> createState() => _CommunityFeedPageState();
}

class _CommunityFeedPageState extends State<CommunityFeedPage> {
  final OwnersClubService _service = OwnersClubService();
  List<KnowledgePost> _posts = [];
  bool _isLoading = true;

  Community get c => widget.community;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final result = await _service.getCommunityFeed(c.id);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _posts = result.items;
      });
    }
  }

  void _nav(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(c.name,
            style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w600, fontSize: 16),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.directions_car_rounded),
            tooltip: 'Showcases',
            onPressed: () => _nav(VehicleShowcasePage(community: c)),
          ),
          IconButton(
            icon: const Icon(Icons.event_rounded),
            tooltip: 'Events',
            onPressed: () => _nav(CommunityEventsPage(community: c)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : RefreshIndicator(
              onRefresh: _load,
              color: _kPrimary,
              child: _posts.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 100),
                        const Center(
                          child: Column(
                            children: [
                              Icon(Icons.forum_rounded, size: 48, color: _kSecondary),
                              SizedBox(height: 12),
                              Text('No posts yet', style: TextStyle(color: _kSecondary, fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _posts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final post = _posts[i];
                        return Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: const Color(0xFFE8E8E8),
                                      backgroundImage: post.authorAvatar != null
                                          ? NetworkImage(post.authorAvatar!)
                                          : null,
                                      child: post.authorAvatar == null
                                          ? Text(
                                              (post.authorName ?? '?')[0].toUpperCase(),
                                              style: const TextStyle(
                                                  fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(post.authorName ?? 'Member',
                                              style: const TextStyle(
                                                  fontSize: 13, fontWeight: FontWeight.w500, color: _kPrimary),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis),
                                          if (post.createdAt != null)
                                            Text(
                                              '${post.createdAt!.day}/${post.createdAt!.month}/${post.createdAt!.year}',
                                              style: const TextStyle(fontSize: 11, color: _kSecondary),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (post.isPinned)
                                      const Icon(Icons.push_pin_rounded, size: 16, color: _kSecondary),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(post.title,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                                if (post.content.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(post.content,
                                      style: const TextStyle(fontSize: 13, color: _kSecondary),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis),
                                ],
                                if (post.tags.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    children: post.tags
                                        .take(3)
                                        .map((t) => Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF0F0F0),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(t,
                                                  style: const TextStyle(fontSize: 11, color: _kSecondary)),
                                            ))
                                        .toList(),
                                  ),
                                ],
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(Icons.thumb_up_alt_rounded, size: 16, color: _kSecondary),
                                    const SizedBox(width: 4),
                                    Text('${post.upvotes}', style: const TextStyle(fontSize: 12, color: _kSecondary)),
                                    const SizedBox(width: 16),
                                    const Icon(Icons.comment_rounded, size: 16, color: _kSecondary),
                                    const SizedBox(width: 4),
                                    Text('${post.replyCount}', style: const TextStyle(fontSize: 12, color: _kSecondary)),
                                    if (post.solutionMarked) ...[
                                      const Spacer(),
                                      const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF2E7D32)),
                                      const SizedBox(width: 4),
                                      const Text('Solved',
                                          style: TextStyle(fontSize: 11, color: Color(0xFF2E7D32), fontWeight: FontWeight.w500)),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
