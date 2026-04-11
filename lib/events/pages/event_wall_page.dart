// lib/events/pages/event_wall_page.dart
import 'package:flutter/material.dart';
import '../models/event_strings.dart';
import '../models/event_wall.dart';
import '../services/event_wall_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class EventWallPage extends StatefulWidget {
  final int eventId;
  final bool isHost;

  const EventWallPage({super.key, required this.eventId, this.isHost = false});

  @override
  State<EventWallPage> createState() => _EventWallPageState();
}

class _EventWallPageState extends State<EventWallPage> {
  final _wallService = EventWallService();
  final _scrollController = ScrollController();
  final _inputController = TextEditingController();
  final _focusNode = FocusNode();

  List<EventWallPost> _pinnedPosts = [];
  List<EventWallPost> _posts = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _posting = false;
  int _currentPage = 1;
  int _lastPage = 1;
  @override
  void initState() {
    super.initState();
    _init();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await _loadPosts();
  }

  Future<void> _loadPosts({bool refresh = false}) async {
    if (refresh) {
      setState(() { _currentPage = 1; _loading = true; });
    }
    final result = await _wallService.getWallPosts(
      eventId: widget.eventId,
      page: _currentPage,
    );
    if (!mounted) return;
    if (result.success) {
      final all = result.items ?? [];
      setState(() {
        _lastPage = result.lastPage ?? 1;
        if (refresh || _currentPage == 1) {
          _pinnedPosts = all.where((p) => p.isPinned).toList();
          _posts = all.where((p) => !p.isPinned).toList();
        } else {
          _posts.addAll(all.where((p) => !p.isPinned));
        }
        _loading = false;
        _loadingMore = false;
      });
    } else {
      setState(() { _loading = false; _loadingMore = false; });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_loadingMore && _currentPage < _lastPage) {
      setState(() { _currentPage++; _loadingMore = true; });
      _loadPosts();
    }
  }

  Future<void> _submitPost() async {
    final content = _inputController.text.trim();
    if (content.isEmpty) return;
    setState(() => _posting = true);
    final result = await _wallService.createWallPost(
      eventId: widget.eventId,
      content: content,
    );
    if (!mounted) return;
    setState(() => _posting = false);
    if (result.success) {
      _inputController.clear();
      _focusNode.unfocus();
      await _loadPosts(refresh: true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? (Localizations.localeOf(context).languageCode == 'sw' ? 'Imeshindwa kutuma' : 'Failed to post')), backgroundColor: _kPrimary),
      );
    }
  }

  Future<void> _toggleLike(EventWallPost post) async {
    final wasLiked = post.isLiked;
    final result = wasLiked
        ? await _wallService.unlikeWallPost(postId: post.id)
        : await _wallService.likeWallPost(postId: post.id);
    if (result.success) await _loadPosts(refresh: true);
  }

  Future<void> _togglePin(EventWallPost post) async {
    await _wallService.pinWallPost(postId: post.id);
    await _loadPosts(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final strings = EventStrings(isSwahili: Localizations.localeOf(context).languageCode == 'sw');
    return Scaffold(
      backgroundColor: _kBg,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : RefreshIndicator(
              color: _kPrimary,
              onRefresh: () => _loadPosts(refresh: true),
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 80),
                children: [
                  if (_pinnedPosts.isNotEmpty) ...[
                    _SectionHeader(
                      label: strings.isSwahili ? 'Matangazo' : 'Announcements',
                      icon: Icons.push_pin_rounded,
                    ),
                    ..._pinnedPosts.map((p) => _WallPostCard(
                      post: p,
                      isHost: widget.isHost,
                      onLike: () => _toggleLike(p),
                      onPin: () => _togglePin(p),
                    )),
                    const Divider(height: 1),
                  ],
                  if (_posts.isEmpty && _pinnedPosts.isEmpty)
                    _EmptyState(label: strings.noComments)
                  else
                    ..._posts.map((p) => _WallPostCard(
                      post: p,
                      isHost: widget.isHost,
                      onLike: () => _toggleLike(p),
                      onPin: () => _togglePin(p),
                    )),
                  if (_loadingMore)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator(color: _kPrimary)),
                    ),
                ],
              ),
            ),
      bottomSheet: _BottomInput(
        controller: _inputController,
        focusNode: _focusNode,
        loading: _posting,
        hint: strings.writeSomething,
        onSubmit: _submitPost,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionHeader({required this.label, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(children: [
        Icon(icon, size: 16, color: _kSecondary),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kSecondary)),
      ]),
    );
  }
}

class _WallPostCard extends StatelessWidget {
  final EventWallPost post;
  final bool isHost;
  final VoidCallback onLike;
  final VoidCallback onPin;

  const _WallPostCard({
    required this.post,
    required this.isHost,
    required this.onLike,
    required this.onPin,
  });

  @override
  Widget build(BuildContext context) {
    final author = post.user;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFE0E0E0),
              backgroundImage: author?.avatarUrl != null ? NetworkImage(author!.avatarUrl!) : null,
              child: author?.avatarUrl == null
                  ? Text(author?.firstName.substring(0, 1) ?? '?',
                      style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.bold))
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                author?.fullName ?? 'Unknown',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: _kPrimary),
              ),
              Text(
                _formatTime(post.createdAt),
                style: const TextStyle(fontSize: 11, color: _kSecondary),
              ),
            ])),
            if (isHost)
              IconButton(
                onPressed: onPin,
                icon: Icon(
                  post.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                  size: 18,
                  color: post.isPinned ? _kPrimary : _kSecondary,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
          ]),
          if (post.content != null && post.content!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(post.content!, style: const TextStyle(fontSize: 14, color: _kPrimary, height: 1.4)),
          ],
          const SizedBox(height: 10),
          Row(children: [
            GestureDetector(
              onTap: onLike,
              child: Row(children: [
                Icon(
                  post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  size: 18,
                  color: post.isLiked ? _kPrimary : _kSecondary,
                ),
                const SizedBox(width: 4),
                Text('${post.likesCount}', style: const TextStyle(fontSize: 13, color: _kSecondary)),
              ]),
            ),
          ]),
        ]),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

class _BottomInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool loading;
  final String hint;
  final VoidCallback onSubmit;

  const _BottomInput({
    required this.controller,
    required this.focusNode,
    required this.loading,
    required this.hint,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE8E8E8))),
      ),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            maxLines: 3,
            minLines: 1,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(fontSize: 14, color: _kPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: _kSecondary, fontSize: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: _kPrimary),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 44,
          height: 44,
          child: loading
              ? const Padding(
                  padding: EdgeInsets.all(10),
                  child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
                )
              : IconButton(
                  onPressed: onSubmit,
                  icon: const Icon(Icons.send_rounded, color: _kPrimary),
                  tooltip: 'Send',
                ),
        ),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String label;
  const _EmptyState({required this.label});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.forum_outlined, size: 48, color: _kSecondary),
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(color: _kSecondary, fontSize: 14)),
      ]),
    );
  }
}
