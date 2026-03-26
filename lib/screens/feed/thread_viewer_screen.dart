import 'package:flutter/material.dart';
import '../../models/gossip_models.dart';
import '../../services/gossip_service.dart';
import '../../services/local_storage_service.dart';
import '../../services/event_tracking_service.dart';
import '../../widgets/post_card.dart';
import '../../l10n/app_strings_scope.dart';

/// Full-screen view of a gossip thread showing the seed post and related posts.
class ThreadViewerScreen extends StatefulWidget {
  final int threadId;
  final int currentUserId;

  const ThreadViewerScreen({
    super.key,
    required this.threadId,
    required this.currentUserId,
  });

  @override
  State<ThreadViewerScreen> createState() => _ThreadViewerScreenState();
}

class _ThreadViewerScreenState extends State<ThreadViewerScreen> {
  final GossipService _gossipService = GossipService();
  GossipThreadDetail? _detail;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadThread();
    _trackView();
  }

  Future<void> _trackView() async {
    final tracker = await EventTrackingService.getInstance();
    tracker.trackEvent(
      eventType: 'view',
      postId: 0,
      creatorId: 0,
      metadata: {'thread_id': widget.threadId},
    );
  }

  Future<void> _loadThread() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      if (token == null) {
        setState(() {
          _error = 'Not authenticated';
          _loading = false;
        });
        return;
      }
      final detail = await _gossipService.getThread(
        token: token,
        threadId: widget.threadId,
      );
      if (mounted) {
        setState(() {
          _detail = detail;
          _loading = false;
          if (detail == null) _error = 'Thread not found';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error: $e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStringsScope.of(context);
    final isSwahili = strings?.isSwahili ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: Text(
          _detail?.thread.title(isSwahili: isSwahili) ?? strings?.trendingNow ?? 'Trending Now',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF1A1A1A)),
              )
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error!,
                          style: const TextStyle(color: Color(0xFF666666)),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _loadThread,
                          child: Text(strings?.retry ?? 'Retry'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadThread,
                    color: const Color(0xFF1A1A1A),
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 32),
                      itemCount: (_detail?.posts.length ?? 0) + 1, // +1 for header
                      itemBuilder: (context, index) {
                        if (index == 0) return _buildHeader(strings, isSwahili);
                        final post = _detail!.posts[index - 1];
                        return PostCard(
                          post: post,
                          currentUserId: widget.currentUserId,
                          onTap: () {
                            Navigator.pushNamed(context, '/post/${post.id}');
                          },
                        );
                      },
                    ),
                  ),
      ),
    );
  }

  Widget _buildHeader(AppStrings? strings, bool isSwahili) {
    final thread = _detail!.thread;
    final postsLabel = strings?.threadPosts ?? 'Posts';
    final participantsLabel = strings?.threadParticipants ?? 'Participants';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category + velocity row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  thread.category.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.local_fire_department_rounded,
                size: 16,
                color: Color(0xFF666666),
              ),
              const SizedBox(width: 4),
              Text(
                thread.velocityScore.toStringAsFixed(0),
                style: const TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Stats row
          Row(
            children: [
              const Icon(Icons.article_outlined, size: 14, color: Color(0xFF999999)),
              const SizedBox(width: 4),
              Text(
                '${thread.postCount} $postsLabel',
                style: const TextStyle(color: Color(0xFF999999), fontSize: 13),
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.people_outline_rounded,
                size: 14,
                color: Color(0xFF999999),
              ),
              const SizedBox(width: 4),
              Text(
                '${thread.participantCount} $participantsLabel',
                style: const TextStyle(color: Color(0xFF999999), fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFFE0E0E0)),
        ],
      ),
    );
  }
}
