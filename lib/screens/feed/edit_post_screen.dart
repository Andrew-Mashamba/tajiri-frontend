import 'package:flutter/material.dart';
import '../../models/post_models.dart';
import '../../services/post_service.dart';
import '../../widgets/user_avatar.dart';
import '../../l10n/app_strings_scope.dart';

class EditPostScreen extends StatefulWidget {
  final Post post;

  const EditPostScreen({
    super.key,
    required this.post,
  });

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final PostService _postService = PostService();
  late TextEditingController _contentController;
  late PostPrivacy _privacy;
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.post.content ?? '');
    _privacy = widget.post.privacy;
    _contentController.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    _contentController.removeListener(_onContentChanged);
    _contentController.dispose();
    super.dispose();
  }

  void _onContentChanged() {
    final contentChanged = _contentController.text != (widget.post.content ?? '');
    final privacyChanged = _privacy != widget.post.privacy;
    setState(() {
      _hasChanges = contentChanged || privacyChanged;
    });
  }

  bool get _canSave =>
      _hasChanges &&
      (_contentController.text.trim().isNotEmpty || widget.post.hasMedia);

  Future<void> _saveChanges() async {
    if (!_canSave) return;

    setState(() => _isSaving = true);

    final result = await _postService.updatePost(
      widget.post.id,
      content: _contentController.text.trim().isNotEmpty
          ? _contentController.text.trim()
          : null,
      privacy: _privacy.value,
    );

    if (mounted) {
      setState(() => _isSaving = false);

      if (result.success) {
        Navigator.pop(context, result.post);
        final s = AppStringsScope.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s?.postUpdated ?? 'Post updated')),
        );
      } else {
        final s = AppStringsScope.of(context);
        final msg = result.message ?? (s?.postUpdateFailed ?? 'Failed to update post');
        final isTimeLimitError = msg.toLowerCase().contains('muda') ||
            msg.toLowerCase().contains('time') ||
            msg.toLowerCase().contains('limit') ||
            msg.toLowerCase().contains('expired') ||
            msg.toLowerCase().contains('umekwisha');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isTimeLimitError ? (s?.editTimeExpired ?? 'Time to edit this post has expired.') : msg,
            ),
          ),
        );
      }
    }
  }

  void _showDiscardDialog() {
    if (!_hasChanges) {
      Navigator.pop(context);
      return;
    }

    final s = AppStringsScope.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s?.discardChangesTitle ?? 'Discard changes?'),
        content: Text(s?.discardChangesMessage ?? 'Are you sure you want to leave without saving changes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s?.no ?? 'No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close edit screen
            },
            child: Text(s?.yes ?? 'Yes', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPicker() {
    final s = AppStringsScope.of(context);
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                s?.whoCanSee ?? 'Change who can see',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.public),
              title: Text(s?.public ?? 'Public'),
              subtitle: Text(s?.publicSubtitle ?? 'Everyone can see'),
              trailing: _privacy == PostPrivacy.public
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                setState(() => _privacy = PostPrivacy.public);
                _onContentChanged();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.group),
              title: Text(s?.friendsFeed ?? 'Friends'),
              subtitle: Text(s?.friendsSubtitle ?? 'Only your friends can see'),
              trailing: _privacy == PostPrivacy.friends
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                setState(() => _privacy = PostPrivacy.friends);
                _onContentChanged();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.star, color: Color(0xFFF59E0B)),
              title: Text(s?.privacySubscribersOnly ?? 'Subscribers Only'),
              subtitle: Text(s?.privacySubscribersOnlyDesc ?? 'Only your subscribers can see'),
              trailing: _privacy == PostPrivacy.subscribers
                  ? const Icon(Icons.check, color: Color(0xFFF59E0B))
                  : null,
              onTap: () {
                setState(() => _privacy = PostPrivacy.subscribers);
                _onContentChanged();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock),
              title: Text(s?.private ?? 'Only me'),
              subtitle: Text(s?.privateSubtitle ?? 'Only you can see'),
              trailing: _privacy == PostPrivacy.private
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                setState(() => _privacy = PostPrivacy.private);
                _onContentChanged();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showDiscardDialog();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1A1A1A),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _showDiscardDialog,
            style: IconButton.styleFrom(
              minimumSize: const Size(48, 48),
            ),
          ),
          title: Text(
            AppStringsScope.of(context)?.editPostTitle ?? 'Edit post',
            style: TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: _canSave && !_isSaving ? _saveChanges : null,
                style: TextButton.styleFrom(
                  minimumSize: const Size(64, 48),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        AppStringsScope.of(context)?.save ?? 'Save',
                        style: TextStyle(
                          color: _canSave
                              ? const Color(0xFF1A1A1A)
                              : const Color(0xFF999999),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User info and privacy
                Row(
                children: [
                  UserAvatar(
                    photoUrl: widget.post.user?.profilePhotoUrl,
                    name: widget.post.user?.fullName,
                    radius: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.post.user?.fullName ?? (AppStringsScope.of(context)?.userLabel ?? 'User'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _showPrivacyPicker,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              constraints: const BoxConstraints(minHeight: 48),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF0F0F0),
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getPrivacyIcon(_privacy),
                                    size: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _getPrivacyLabel(_privacy),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const Icon(Icons.arrow_drop_down, size: 18),
                                ],
                              ),
                            ),
                          ),
                        )],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Content input
              TextField(
                controller: _contentController,
                decoration: InputDecoration(
                  hintText: AppStringsScope.of(context)?.writeSomething ?? 'Write something...',
                  border: InputBorder.none,
                ),
                maxLines: null,
                minLines: 5,
                textCapitalization: TextCapitalization.sentences,
              ),

              // Display existing media (non-editable)
              if (widget.post.hasMedia) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.photo_library, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${widget.post.media.length} ${widget.post.media.length == 1 ? (AppStringsScope.of(context)?.fileAttached ?? 'file attached') : (AppStringsScope.of(context)?.filesAttached ?? 'files attached')}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                      Text(
                        AppStringsScope.of(context)?.cannotBeChanged ?? 'Cannot be changed',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _buildMediaPreview(),
              ],

              // Edit history note (edited indicator shown on post)
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: const Color(0xFF666666),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppStringsScope.of(context)?.editHistoryNote ?? 'Edit history will be shown on the post (Edited).',
                        style: const TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildMediaPreview() {
    if (widget.post.media.isEmpty) return const SizedBox.shrink();

    if (widget.post.media.length == 1) {
      final media = widget.post.media.first;
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                media.thumbnailUrl ?? media.fileUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.image, size: 40),
                ),
              ),
              if (media.mediaType == MediaType.video)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.post.media.length,
        itemBuilder: (context, index) {
          final media = widget.post.media[index];
          return Padding(
            padding: EdgeInsets.only(right: index < widget.post.media.length - 1 ? 8 : 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      media.thumbnailUrl ?? media.fileUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.image),
                      ),
                    ),
                    if (media.mediaType == MediaType.video)
                      const Center(
                        child: Icon(Icons.play_circle_fill, color: Colors.white, size: 32),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getPrivacyIcon(PostPrivacy privacy) {
    switch (privacy) {
      case PostPrivacy.public:
        return Icons.public;
      case PostPrivacy.friends:
        return Icons.group;
      case PostPrivacy.subscribers:
        return Icons.star;
      case PostPrivacy.private:
        return Icons.lock;
    }
  }

  String _getPrivacyLabel(PostPrivacy privacy) {
    switch (privacy) {
      case PostPrivacy.public:
        return AppStringsScope.of(context)?.public ?? 'Public';
      case PostPrivacy.friends:
        return AppStringsScope.of(context)?.friendsFeed ?? 'Friends';
      case PostPrivacy.subscribers:
        return AppStringsScope.of(context)?.privacySubscribersOnly ?? 'Subscribers Only';
      case PostPrivacy.private:
        return AppStringsScope.of(context)?.private ?? 'Only me';
    }
  }
}
