import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/post_models.dart';
import '../models/message_models.dart';
import '../services/post_service.dart';
import '../services/message_service.dart';
import '../config/api_config.dart';
import '../l10n/app_strings_scope.dart';
import 'user_avatar.dart';
import 'cached_media_image.dart';

/// Shows the share post bottom sheet with three options:
/// 1. Share to your wall (repost with optional comment)
/// 2. Share to chat (pick a conversation)
/// 3. Share to social media (native OS share sheet with image)
void showSharePostBottomSheet(
  BuildContext context, {
  required Post post,
  required int userId,
  required PostService postService,
  void Function(Post? sharedPost)? onShared,
}) {
  final s = AppStringsScope.of(context);
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Post preview card
          _SharePostPreview(post: post),
          const Divider(height: 1),
          // 1. Share to wall (with optional comment input)
          ListTile(
            leading: const Icon(Icons.repeat_rounded, color: Color(0xFF1A1A1A)),
            title: Text(s?.shareToWall ?? 'Share to your wall'),
            onTap: () {
              Navigator.pop(ctx);
              _showShareToWallDialog(
                context,
                post: post,
                userId: userId,
                postService: postService,
                onShared: onShared,
              );
            },
          ),
          // 2. Share to chat
          ListTile(
            leading: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF1A1A1A)),
            title: Text(s?.shareToChat ?? 'Share to chat'),
            onTap: () {
              Navigator.pop(ctx);
              _showChatPicker(context, post: post, userId: userId);
            },
          ),
          // 3. Share to social media (native share with image)
          Builder(
            builder: (tileContext) => ListTile(
              leading: const Icon(Icons.share_outlined, color: Color(0xFF1A1A1A)),
              title: Text(s?.shareToSocial ?? 'Share to social media'),
              onTap: () async {
                // Capture position for iPad share popover before popping
                final box = tileContext.findRenderObject() as RenderBox?;
                final origin = box != null
                    ? box.localToGlobal(Offset.zero) & box.size
                    : null;
                Navigator.pop(ctx);
                await _shareToSocialMedia(context, post, origin: origin);
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

// ─── Post preview card shown at top of share sheet ──────────────────

class _SharePostPreview extends StatelessWidget {
  final Post post;
  const _SharePostPreview({required this.post});

  @override
  Widget build(BuildContext context) {
    final imageUrl = post.primaryImage?.fileUrl ?? post.coverImageUrl ?? post.thumbnailUrl;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          if (imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 56,
                height: 56,
                child: CachedMediaImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image, size: 24, color: Colors.grey),
                  ),
                ),
              ),
            ),
          if (imageUrl != null) const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.user != null)
                  Text(
                    post.user!.fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (post.content != null && post.content!.isNotEmpty)
                  Text(
                    post.content!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF666666),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Share to wall (with optional comment) ──────────────────────────

void _showShareToWallDialog(
  BuildContext context, {
  required Post post,
  required int userId,
  required PostService postService,
  void Function(Post? sharedPost)? onShared,
}) {
  final controller = TextEditingController();
  bool isSharing = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final s = AppStringsScope.of(context);
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Text(
                      s?.shareToWall ?? 'Share to your wall',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Optional comment input
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: s?.writeSomething ?? 'Write something...',
                    hintStyle: const TextStyle(color: Color(0xFF999999)),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  maxLines: 3,
                  minLines: 1,
                ),
                const SizedBox(height: 12),
                // Original post preview
                _SharePostPreview(post: post),
                const SizedBox(height: 12),
                // Share button
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isSharing
                        ? null
                        : () async {
                            setSheetState(() => isSharing = true);
                            final result = await postService.sharePost(
                              post.id,
                              userId,
                              content: controller.text.trim().isNotEmpty
                                  ? controller.text.trim()
                                  : null,
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (context.mounted) {
                              final s2 = AppStringsScope.of(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    result.success
                                        ? (s2?.postShared ?? 'Post shared')
                                        : (s2?.shareFailed ?? 'Failed to share'),
                                  ),
                                ),
                              );
                              if (result.success && result.post != null) {
                                onShared?.call(result.post);
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A1A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isSharing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(s?.share ?? 'Share'),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

// ─── Share to social media (with image) ─────────────────────────────

Future<void> _shareToSocialMedia(BuildContext context, Post post, {Rect? origin}) async {
  final postUrl = '${ApiConfig.baseUrl.replaceFirst(RegExp(r'/api$'), '')}/post/${post.id}';
  final userName = post.user?.fullName ?? 'TAJIRI';
  final postContent = post.content ?? '';

  // Build share text
  final shareText = StringBuffer();
  if (postContent.isNotEmpty) {
    shareText.writeln(postContent);
    shareText.writeln();
  }
  shareText.writeln('— $userName on TAJIRI');
  shareText.write(postUrl);

  // Collect media URLs — images directly, video thumbnails for videos
  final List<String> mediaUrls = [];
  if (post.hasMedia) {
    for (final media in post.media) {
      if (media.mediaType.isImage) {
        mediaUrls.add(media.fileUrl);
      } else if (media.mediaType.isVideo && media.thumbnailUrl != null) {
        mediaUrls.add(media.thumbnailUrl!);
      }
    }
  }
  if (mediaUrls.isEmpty) {
    final fallback = post.coverImageUrl ?? post.thumbnailUrl;
    if (fallback != null) mediaUrls.add(fallback);
  }

  // Download media to temp files for the OS share sheet
  if (mediaUrls.isNotEmpty) {
    final tempDir = await getTemporaryDirectory();
    final List<XFile> xFiles = [];
    final List<File> tempFiles = [];

    for (var i = 0; i < mediaUrls.length; i++) {
      try {
        final response = await http.get(Uri.parse(mediaUrls[i]));
        if (response.statusCode == 200) {
          final ext = mediaUrls[i].contains('.png') ? '.png' : '.jpg';
          final file = File('${tempDir.path}/tajiri_share_${post.id}_$i$ext');
          await file.writeAsBytes(response.bodyBytes);
          xFiles.add(XFile(file.path));
          tempFiles.add(file);
        }
      } catch (_) {
        // Skip failed downloads
      }
    }

    if (xFiles.isNotEmpty) {
      await SharePlus.instance.share(
        ShareParams(
          title: postContent.isNotEmpty ? postContent : 'TAJIRI',
          text: shareText.toString(),
          files: xFiles,
          sharePositionOrigin: origin,
        ),
      );
      for (final f in tempFiles) {
        try { await f.delete(); } catch (_) {}
      }
      return;
    }
  }

  // Fallback: share just the link (no text+uri conflict)
  await SharePlus.instance.share(
    ShareParams(
      uri: Uri.parse(postUrl),
      sharePositionOrigin: origin,
    ),
  );
}

// ─── Share to chat (conversation picker) ────────────────────────────

void _showChatPicker(
  BuildContext context, {
  required Post post,
  required int userId,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) => _ChatPickerContent(
        post: post,
        userId: userId,
        scrollController: scrollController,
      ),
    ),
  );
}

class _ChatPickerContent extends StatefulWidget {
  final Post post;
  final int userId;
  final ScrollController scrollController;

  const _ChatPickerContent({
    required this.post,
    required this.userId,
    required this.scrollController,
  });

  @override
  State<_ChatPickerContent> createState() => _ChatPickerContentState();
}

class _ChatPickerContentState extends State<_ChatPickerContent> {
  final MessageService _messageService = MessageService();
  final TextEditingController _searchController = TextEditingController();
  List<Conversation> _conversations = [];
  List<Conversation> _filtered = [];
  bool _isLoading = true;
  int? _sendingTo;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearch);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    final result = await _messageService.getConversations(
      userId: widget.userId,
      perPage: 50,
    );
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.success) {
        _conversations = result.conversations;
        _filtered = _conversations;
      }
    });
  }

  void _onSearch() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filtered = _conversations;
      } else {
        _filtered = _conversations.where((c) {
          final name = (c.displayName ?? c.name ?? '').toLowerCase();
          return name.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _sendToChat(Conversation conversation) async {
    setState(() => _sendingTo = conversation.id);

    final post = widget.post;

    // Build a shared_post JSON payload with everything needed
    // to render a rich post card in the chat UI.
    final mediaList = post.media.map((m) => {
      'media_type': m.mediaType.value,
      'file_url': m.fileUrl,
      if (m.thumbnailUrl != null) 'thumbnail_url': m.thumbnailUrl,
      if (m.width != null) 'width': m.width,
      if (m.height != null) 'height': m.height,
      if (m.duration != null) 'duration': m.duration,
    }).toList();

    final payload = jsonEncode({
      'post_id': post.id,
      'user_name': post.user?.fullName ?? '',
      'user_photo': post.user?.profilePhotoUrl,
      'content': post.content,
      'media': mediaList,
      'cover_image_url': post.coverImageUrl,
      'type': post.postType.value,
      'likes_count': post.likesCount,
      'comments_count': post.commentsCount,
    });

    final result = await _messageService.sendMessage(
      conversationId: conversation.id,
      userId: widget.userId,
      content: payload,
      messageType: 'shared_post',
    );

    if (!mounted) return;
    setState(() => _sendingTo = null);

    Navigator.pop(context);
    final s = AppStringsScope.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.success
              ? (s?.sentToChat ?? 'Sent to chat')
              : (s?.shareFailed ?? 'Failed to share'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    return Column(
      children: [
        // Drag handle
        Container(
          margin: const EdgeInsets.only(top: 8, bottom: 4),
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Post preview
        _SharePostPreview(post: widget.post),
        const Divider(height: 1),
        // Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            s?.selectChat ?? 'Select a chat',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ),
        // Search
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: s?.searchChats ?? 'Search chats...',
              hintStyle: const TextStyle(color: Color(0xFF999999)),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF999999)),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Conversation list
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                  ? Center(
                      child: Text(
                        s?.noChatsFound ?? 'No chats found',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      ),
                    )
                  : ListView.builder(
                      controller: widget.scrollController,
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final conv = _filtered[index];
                        final isSending = _sendingTo == conv.id;
                        return ListTile(
                          leading: UserAvatar(
                            photoUrl: conv.displayPhoto,
                            name: conv.displayName ?? conv.name,
                            radius: 22,
                          ),
                          title: Text(
                            conv.displayName ?? conv.name ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: Color(0xFF1A1A1A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: isSending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.send_rounded, size: 20, color: Color(0xFF1A1A1A)),
                          onTap: isSending || _sendingTo != null
                              ? null
                              : () => _sendToChat(conv),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
