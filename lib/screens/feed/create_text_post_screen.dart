import 'package:flutter/material.dart';
import '../../models/post_models.dart';
import '../../models/draft_models.dart';
import '../../services/post_service.dart';
import '../../services/draft_service.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/mention_text_field.dart';
import '../../widgets/schedule_post_widget.dart';
import 'schedulepostwidget_screen.dart';

/// Text-only post creation screen with background color support
class CreateTextPostScreen extends StatefulWidget {
  final int currentUserId;
  final String? userName;
  final String? userPhotoUrl;
  final PostDraft? draft;

  const CreateTextPostScreen({
    super.key,
    required this.currentUserId,
    this.userName,
    this.userPhotoUrl,
    this.draft,
  });

  @override
  State<CreateTextPostScreen> createState() => _CreateTextPostScreenState();
}

class _CreateTextPostScreenState extends State<CreateTextPostScreen> {
  final PostService _postService = PostService();
  final DraftService _draftService = DraftService();
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _contentFocusNode = FocusNode();

  PostPrivacy _privacy = PostPrivacy.public;
  bool _isPosting = false;
  bool _isSavingDraft = false;
  String? _backgroundColor;
  int _selectedColorIndex = -1;
  DateTime? _scheduledAt;
  int? _draftId;
  bool _allowComments = true;

  // Background color options
  static const List<String> _backgroundColors = [
    '#FF5733', '#FFC300', '#28B463', '#3498DB', '#9B59B6', '#E91E63',
    '#00BCD4', '#FF9800', '#795548', '#607D8B', '#1A1A2E', '#000000',
  ];

  @override
  void initState() {
    super.initState();
    _initializeFromDraft();
  }

  void _initializeFromDraft() {
    if (widget.draft != null) {
      _contentController.text = widget.draft!.content ?? '';
      _backgroundColor = widget.draft!.backgroundColor;
      _selectedColorIndex = _backgroundColor != null
          ? _backgroundColors.indexOf(_backgroundColor!)
          : -1;
      _privacy = PostPrivacy.values.firstWhere(
        (p) => p.value == widget.draft!.privacy,
        orElse: () => PostPrivacy.public,
      );
      _scheduledAt = widget.draft!.scheduledAt;
      _draftId = widget.draft!.id;
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _contentFocusNode.dispose();
    _draftService.dispose();
    super.dispose();
  }

  static const int _maxContentLength = 5000;

  bool get _canPost =>
      _contentController.text.trim().isNotEmpty &&
      _contentController.text.length <= _maxContentLength;
  bool get _hasChanges =>
      _contentController.text.trim().isNotEmpty || _backgroundColor != null;
  bool get _isOverLength => _contentController.text.length > _maxContentLength;

  Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  bool _isLightColor(String hex) {
    final color = _hexToColor(hex);
    final luminance = (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255;
    return luminance > 0.5;
  }

  Future<void> _createPost() async {
    if (!_canPost) return;

    setState(() => _isPosting = true);

    try {
      final result = await _postService.createPost(
        userId: widget.currentUserId,
        content: _contentController.text.trim(),
        privacy: _privacy.value,
        postType: 'text',
        backgroundColor: _backgroundColor,
        allowComments: _allowComments,
      );

      if (mounted) {
        setState(() => _isPosting = false);

        if (result.success) {
          // Delete draft if it exists
          if (_draftId != null) {
            await _draftService.deleteDraft(_draftId!);
          }
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post created successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ?? 'Failed to create post'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPosting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _schedulePost() async {
    if (!_canPost || _scheduledAt == null) return;

    setState(() => _isPosting = true);

    try {
      // Save as draft with scheduled time, then publish
      final result = await _draftService.saveDraft(
        userId: widget.currentUserId,
        draftId: _draftId,
        postType: DraftPostType.text,
        content: _contentController.text.trim(),
        backgroundColor: _backgroundColor,
        privacy: _privacy.value,
        scheduledAt: _scheduledAt,
      );

      if (result.success && result.draft?.id != null) {
        // Publish the draft (which will schedule it)
        final publishResult = await _draftService.publishDraft(result.draft!.id!);

        if (mounted) {
          setState(() => _isPosting = false);

          if (publishResult.success) {
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(publishResult.message ?? 'Post scheduled')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(publishResult.message ?? 'Failed to schedule'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPosting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveDraft() async {
    if (!_hasChanges) return;

    setState(() => _isSavingDraft = true);

    try {
      final result = await _draftService.saveDraft(
        userId: widget.currentUserId,
        draftId: _draftId,
        postType: DraftPostType.text,
        content: _contentController.text.trim(),
        backgroundColor: _backgroundColor,
        privacy: _privacy.value,
        scheduledAt: _scheduledAt,
      );

      if (mounted) {
        setState(() {
          _isSavingDraft = false;
          if (result.success && result.draft != null) {
            _draftId = result.draft!.id;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.success ? 'Draft saved' : (result.message ?? 'Failed to save draft')),
            backgroundColor: result.success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSavingDraft = false);
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Draft?'),
        content: const Text('You have unsaved changes. Would you like to save them as a draft?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'discard'),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'save'),
            child: const Text('Save Draft'),
          ),
        ],
      ),
    );

    if (result == 'save') {
      await _saveDraft();
      return true;
    } else if (result == 'discard') {
      return true;
    }
    return false;
  }

  void _showPrivacyPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Who can see this post?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            _buildPrivacyOption(Icons.public, 'Public', 'Everyone can see', PostPrivacy.public),
            _buildPrivacyOption(Icons.group, 'Friends', 'Only friends can see', PostPrivacy.friends),
            _buildPrivacyOption(Icons.star, 'Subscribers Only', 'Only your subscribers can see', PostPrivacy.subscribers),
            _buildPrivacyOption(Icons.lock, 'Private', 'Only you can see', PostPrivacy.private),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyOption(IconData icon, String title, String subtitle, PostPrivacy privacy) {
    final isSelected = _privacy == privacy;
    const accentColor = Color(0xFF1A1A1A);
    const secondaryColor = Color(0xFF666666);
    return ListTile(
      minLeadingWidth: 0,
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? accentColor : const Color(0xFF999999).withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : secondaryColor,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 15,
        ),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
      trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF1A1A1A)) : null,
      onTap: () {
        setState(() => _privacy = privacy);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasBackground = _backgroundColor != null;
    final textColor = hasBackground && !_isLightColor(_backgroundColor!) ? Colors.white : Colors.black;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final allowPop = await _onWillPop();
        if (allowPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1A1A1A),
          title: const Text('Text Post'),
          actions: [
            // Save draft button
            if (_hasChanges)
              TextButton.icon(
                onPressed: _isSavingDraft ? null : _saveDraft,
                icon: _isSavingDraft
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_outlined, size: 20),
                label: const Text('Save'),
              ),
            // Post button
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton(
                onPressed: _canPost && !_isPosting
                    ? (_scheduledAt != null ? _schedulePost : _createPost)
                    : null,
                child: _isPosting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_scheduledAt != null ? 'Schedule' : 'Post'),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User info and privacy
                    Row(
                      children: [
                        UserAvatar(photoUrl: widget.userPhotoUrl, name: widget.userName, radius: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.userName ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              _buildPrivacyButton(),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Preview card with background color
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 200),
                      decoration: BoxDecoration(
                        color: hasBackground ? _hexToColor(_backgroundColor!) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: hasBackground ? null : Border.all(color: Colors.grey.shade300),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: MentionTextField(
                          controller: _contentController,
                          currentUserId: widget.currentUserId,
                          focusNode: _contentFocusNode,
                          maxLines: null,
                          minLines: 5,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: hasBackground ? 24 : 18,
                            fontWeight: hasBackground ? FontWeight.bold : FontWeight.normal,
                            color: textColor,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Write your thoughts... @ #',
                            hintStyle: TextStyle(
                              color: hasBackground ? textColor.withOpacity(0.5) : Colors.grey.shade500,
                              fontSize: hasBackground ? 24 : 18,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            counterText: '',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Character count
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${_contentController.text.length} / $_maxContentLength',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isOverLength
                              ? Colors.red
                              : const Color(0xFF666666),
                        ),
                      ),
                    ),
                    if (_isOverLength)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Reduce text to $_maxContentLength characters to post.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Background color section
                    const Text('Background Color', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('Choose a color for your post', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(height: 12),

                    // Color picker
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        Semantics(
                          button: true,
                          label: 'No background color',
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _backgroundColor = null;
                              _selectedColorIndex = -1;
                            }),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _selectedColorIndex == -1
                                      ? const Color(0xFF1A1A1A)
                                      : Colors.grey.shade300,
                                  width: _selectedColorIndex == -1 ? 3 : 1,
                                ),
                              ),
                              child: Icon(
                                Icons.format_color_reset,
                                color: const Color(0xFF666666),
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                        ...List.generate(
                          _backgroundColors.length,
                          (index) => Semantics(
                            button: true,
                            label: 'Background color ${index + 1}',
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _backgroundColor = _backgroundColors[index];
                                _selectedColorIndex = index;
                              }),
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: _hexToColor(_backgroundColors[index]),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _selectedColorIndex == index
                                        ? Colors.white
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                  boxShadow: _selectedColorIndex == index
                                      ? [
                                          BoxShadow(
                                            color: _hexToColor(_backgroundColors[index])
                                                .withOpacity(0.5),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: _selectedColorIndex == index
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 24,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Allow comments
                    SwitchListTile(
                      value: _allowComments,
                      onChanged: (v) => setState(() => _allowComments = v),
                      title: const Text(
                        'Ruhusu maoni',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A)),
                      ),
                      subtitle: const Text(
                        'Watumiaji wanaweza kutoa maoni kwenye chapisho hili',
                        style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
                      ),
                      activeColor: const Color(0xFF1A1A1A),
                      contentPadding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 24),

                    // Schedule section (Story 85: Schedule toggle → Date/time)
                    SchedulePostWidget(
                      initialScheduledAt: _scheduledAt,
                      onScheduleChanged: (date) => setState(() => _scheduledAt = date),
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      button: true,
                      label: 'Open full screen date and time picker',
                      child: InkWell(
                        onTap: () async {
                          final picked = await SchedulePostWidgetScreen.navigate(
                            context,
                            initialScheduledAt: _scheduledAt,
                          );
                          if (mounted && picked != null) {
                            setState(() => _scheduledAt = picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 48),
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 4,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.open_in_full,
                                size: 20,
                                color: const Color(0xFF666666),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Set date & time',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: const Color(0xFF666666),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

              // Bottom toolbar
              Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.tag),
                        iconSize: 24,
                        style: IconButton.styleFrom(
                          minimumSize: const Size(48, 48),
                        ),
                        onPressed: () {
                          final text = _contentController.text;
                          final selection = _contentController.selection;
                          final newText = '${text.substring(0, selection.baseOffset)}#${text.substring(selection.extentOffset)}';
                          _contentController.text = newText;
                          _contentController.selection = TextSelection.collapsed(offset: selection.baseOffset + 1);
                          _contentFocusNode.requestFocus();
                        },
                        tooltip: 'Add hashtag',
                      ),
                      IconButton(
                        icon: const Icon(Icons.alternate_email),
                        iconSize: 24,
                        style: IconButton.styleFrom(
                          minimumSize: const Size(48, 48),
                        ),
                        onPressed: () {
                          final text = _contentController.text;
                          final selection = _contentController.selection;
                          final newText = '${text.substring(0, selection.baseOffset)}@${text.substring(selection.extentOffset)}';
                          _contentController.text = newText;
                          _contentController.selection = TextSelection.collapsed(offset: selection.baseOffset + 1);
                          _contentFocusNode.requestFocus();
                        },
                        tooltip: 'Mention someone',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyButton() {
    final privacyColor = _getPrivacyColor(_privacy);
    return InkWell(
      onTap: _showPrivacyPicker,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: privacyColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: privacyColor.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_getPrivacyIcon(_privacy), size: 14, color: privacyColor),
            const SizedBox(width: 4),
            Text(_getPrivacyLabel(_privacy), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: privacyColor)),
            Icon(Icons.arrow_drop_down, size: 18, color: privacyColor),
          ],
        ),
      ),
    );
  }

  IconData _getPrivacyIcon(PostPrivacy privacy) {
    switch (privacy) {
      case PostPrivacy.public: return Icons.public;
      case PostPrivacy.friends: return Icons.group;
      case PostPrivacy.subscribers: return Icons.star;
      case PostPrivacy.private: return Icons.lock;
    }
  }

  String _getPrivacyLabel(PostPrivacy privacy) {
    switch (privacy) {
      case PostPrivacy.public: return 'Public';
      case PostPrivacy.friends: return 'Friends';
      case PostPrivacy.subscribers: return 'Subscribers';
      case PostPrivacy.private: return 'Private';
    }
  }

  Color _getPrivacyColor(PostPrivacy privacy) {
    switch (privacy) {
      case PostPrivacy.public:
        return const Color(0xFF1A1A1A);
      case PostPrivacy.friends:
        return const Color(0xFF666666);
      case PostPrivacy.subscribers:
        return const Color(0xFFF59E0B); // Amber color for subscribers
      case PostPrivacy.private:
        return const Color(0xFF999999);
    }
  }
}
