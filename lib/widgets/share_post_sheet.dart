import 'package:flutter/material.dart';
import '../models/post_models.dart';
import '../services/post_service.dart';

/// Shows the share post bottom sheet (Share to wall, Share with comment, Copy link).
/// DESIGN: Touch targets min 48dp; ListTile provides 56dp.
/// [onShared] is called when a share succeeds with the created shared post (for feed insertion).
void showSharePostBottomSheet(
  BuildContext context, {
  required Post post,
  required int userId,
  required PostService postService,
  void Function(Post? sharedPost)? onShared,
}) {
  showModalBottomSheet(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Share to wall - min 48dp; ListTile default height is 56dp
          ListTile(
            leading: const Icon(Icons.repeat),
            title: const Text('Shiriki kwenye ukuta wako'),
            onTap: () async {
              Navigator.pop(context);
              final result = await postService.sharePost(post.id, userId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result.success ? 'Umeshiriki chapisho' : 'Imeshindwa kushiriki',
                    ),
                  ),
                );
                if (result.success && result.post != null) {
                  onShared?.call(result.post);
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Shiriki na maoni'),
            onTap: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => ShareWithCommentDialog(
                  post: post,
                  userId: userId,
                  postService: postService,
                  onShared: onShared,
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('Nakili kiungo'),
            onTap: () {
              Navigator.pop(context);
              // Copy link placeholder
            },
          ),
        ],
      ),
    ),
  );
}

/// Dialog to share a post with an optional comment. Calls [onShared] with the
/// created post when share succeeds (so feed can display the shared post).
class ShareWithCommentDialog extends StatefulWidget {
  final Post post;
  final int userId;
  final PostService postService;
  final void Function(Post? sharedPost)? onShared;

  const ShareWithCommentDialog({
    super.key,
    required this.post,
    required this.userId,
    required this.postService,
    this.onShared,
  });

  @override
  State<ShareWithCommentDialog> createState() => _ShareWithCommentDialogState();
}

class _ShareWithCommentDialogState extends State<ShareWithCommentDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isSharing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    setState(() => _isSharing = true);

    final result = await widget.postService.sharePost(
      widget.post.id,
      widget.userId,
      content: _controller.text.isNotEmpty ? _controller.text : null,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.success ? 'Umeshiriki chapisho' : 'Imeshindwa kushiriki',
          ),
        ),
      );
      if (result.success && result.post != null) {
        widget.onShared?.call(result.post);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Shiriki na maoni'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          hintText: 'Andika maoni...',
          border: OutlineInputBorder(),
        ),
        maxLines: 3,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Ghairi'),
        ),
        ElevatedButton(
          onPressed: _isSharing ? null : _share,
          child: _isSharing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Shiriki'),
        ),
      ],
    );
  }
}
