import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/post_models.dart';
import '../../models/draft_models.dart';
import '../../services/post_service.dart';
import '../../services/draft_service.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/mention_text_field.dart';
import '../../widgets/schedule_post_widget.dart';
import 'schedulepostwidget_screen.dart';
import 'photo_editor_screen.dart';

/// Image post creation screen with editing, filters, drafts and scheduling
class CreateImagePostScreen extends StatefulWidget {
  final int currentUserId;
  final String? userName;
  final String? userPhotoUrl;
  final PostDraft? draft;

  const CreateImagePostScreen({
    super.key,
    required this.currentUserId,
    this.userName,
    this.userPhotoUrl,
    this.draft,
  });

  @override
  State<CreateImagePostScreen> createState() => _CreateImagePostScreenState();
}

class _CreateImagePostScreenState extends State<CreateImagePostScreen> {
  final PostService _postService = PostService();
  final DraftService _draftService = DraftService();
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _contentFocusNode = FocusNode();
  final ImagePicker _picker = ImagePicker();

  static const int _maxImages = 10;

  List<File> _selectedImages = [];
  PostPrivacy _privacy = PostPrivacy.public;
  bool _isPosting = false;
  bool _isSavingDraft = false;
  String _selectedFilter = 'normal';
  DateTime? _scheduledAt;
  int? _draftId;

  static const List<Map<String, dynamic>> _filters = [
    {'name': 'normal', 'label': 'Normal', 'matrix': null},
    {'name': 'vivid', 'label': 'Vivid', 'saturation': 1.3},
    {'name': 'warm', 'label': 'Warm', 'hue': 15.0},
    {'name': 'cool', 'label': 'Cool', 'hue': -15.0},
    {'name': 'black_white', 'label': 'B&W', 'saturation': 0.0},
    {'name': 'vintage', 'label': 'Vintage', 'sepia': true},
    {'name': 'fade', 'label': 'Fade', 'opacity': 0.8},
    {'name': 'chrome', 'label': 'Chrome', 'contrast': 1.2},
    {'name': 'dramatic', 'label': 'Dramatic', 'contrast': 1.4},
    {'name': 'mono', 'label': 'Mono', 'saturation': 0.0, 'contrast': 1.2},
    {'name': 'silvertone', 'label': 'Silver', 'saturation': 0.1},
    {'name': 'noir', 'label': 'Noir', 'saturation': 0.0, 'contrast': 1.5},
  ];

  @override
  void initState() {
    super.initState();
    _initializeFromDraft();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedImages.isEmpty && widget.draft == null) {
        _showMediaOptions();
      }
    });
  }

  void _initializeFromDraft() {
    if (widget.draft != null) {
      _contentController.text = widget.draft!.content ?? '';
      _privacy = PostPrivacy.values.firstWhere(
        (p) => p.value == widget.draft!.privacy,
        orElse: () => PostPrivacy.public,
      );
      _selectedFilter = widget.draft!.videoFilter ?? 'normal';
      _scheduledAt = widget.draft!.scheduledAt;
      _draftId = widget.draft!.id;
      // Note: Draft media files would need to be loaded from paths
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _contentFocusNode.dispose();
    _draftService.dispose();
    super.dispose();
  }

  bool get _canPost => _selectedImages.isNotEmpty;
  bool get _hasChanges => _selectedImages.isNotEmpty || _contentController.text.trim().isNotEmpty;

  Future<void> _pickImages() async {
    if (_selectedImages.length >= _maxImages) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You can add up to $_maxImages photos. Remove some to add more.')),
        );
      }
      return;
    }
    final images = await _picker.pickMultiImage(maxWidth: 1920, maxHeight: 1080, imageQuality: 85);
    if (images.isNotEmpty) {
      final remaining = _maxImages - _selectedImages.length;
      final toAdd = images.take(remaining).map((x) => File(x.path)).toList();
      setState(() => _selectedImages.addAll(toAdd));
      if (images.length > remaining && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Only $_maxImages photos allowed. Added ${toAdd.length}.')),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    if (_selectedImages.length >= _maxImages) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You can add up to $_maxImages photos. Remove some to add more.')),
        );
      }
      return;
    }
    final image = await _picker.pickImage(source: ImageSource.camera, maxWidth: 1920, maxHeight: 1080, imageQuality: 85);
    if (image != null) {
      setState(() => _selectedImages.add(File(image.path)));
    }
  }

  void _removeImage(int index) => setState(() => _selectedImages.removeAt(index));

  Future<void> _editImage(int index) async {
    final result = await PhotoEditorScreen.edit(
      context,
      _selectedImages[index],
      initialFilter: _selectedFilter,
    );
    if (result != null && mounted) {
      setState(() {
        _selectedImages[index] = result.editedFile;
        // Update filter if changed in editor
        if (result.filter != _selectedFilter) {
          _selectedFilter = result.filter;
        }
      });
    }
  }

  void _reorderImages(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _selectedImages.removeAt(oldIndex);
      _selectedImages.insert(newIndex, item);
    });
  }

  Future<void> _createPost() async {
    if (!_canPost) return;
    setState(() => _isPosting = true);

    try {
      final result = await _postService.createPost(
        userId: widget.currentUserId,
        content: _contentController.text.trim().isNotEmpty ? _contentController.text.trim() : null,
        privacy: _privacy.value,
        postType: 'photo',
        media: _selectedImages,
        videoFilter: _selectedFilter != 'normal' ? _selectedFilter : null,
      );

      if (mounted) {
        setState(() => _isPosting = false);
        if (result.success) {
          if (_draftId != null) await _draftService.deleteDraft(_draftId!);
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post created successfully')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message ?? 'Failed to create post'), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPosting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _schedulePost() async {
    if (!_canPost || _scheduledAt == null) return;
    setState(() => _isPosting = true);

    try {
      final result = await _draftService.saveDraft(
        userId: widget.currentUserId,
        draftId: _draftId,
        postType: DraftPostType.photo,
        content: _contentController.text.trim().isNotEmpty ? _contentController.text.trim() : null,
        privacy: _privacy.value,
        scheduledAt: _scheduledAt,
        videoFilter: _selectedFilter != 'normal' ? _selectedFilter : null,
        mediaFiles: _selectedImages,
      );

      if (result.success && result.draft?.id != null) {
        final publishResult = await _draftService.publishDraft(result.draft!.id!);
        if (mounted) {
          setState(() => _isPosting = false);
          if (publishResult.success) {
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(publishResult.message ?? 'Post scheduled')));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(publishResult.message ?? 'Failed to schedule'), backgroundColor: Colors.red));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPosting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
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
        postType: DraftPostType.photo,
        content: _contentController.text.trim().isNotEmpty ? _contentController.text.trim() : null,
        privacy: _privacy.value,
        scheduledAt: _scheduledAt,
        videoFilter: _selectedFilter != 'normal' ? _selectedFilter : null,
        mediaFiles: _selectedImages,
      );

      if (mounted) {
        setState(() {
          _isSavingDraft = false;
          if (result.success && result.draft != null) _draftId = result.draft!.id;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result.success ? 'Draft saved' : (result.message ?? 'Failed to save')),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ));
      }
    } catch (e) {
      if (mounted) setState(() => _isSavingDraft = false);
    }
  }

  Future<void> _onPopInvoked(bool didPop, dynamic result) async {
    if (didPop || !_hasChanges) return;
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Draft?'),
        content: const Text('You have unsaved changes. Would you like to save them as a draft?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, 'discard'), child: const Text('Discard')),
          TextButton(onPressed: () => Navigator.pop(context, 'cancel'), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, 'save'), child: const Text('Save Draft')),
        ],
      ),
    );
    if (choice == 'save') {
      await _saveDraft();
      if (mounted) Navigator.pop(context, false);
    } else if (choice == 'discard' && mounted) {
      Navigator.pop(context, false);
    }
  }

  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const Padding(padding: EdgeInsets.all(16), child: Text('Select Photos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
            ListTile(
              leading: Container(width: 48, height: 48, decoration: const BoxDecoration(color: Color(0xFF1A1A1A), shape: BoxShape.circle), child: const Icon(Icons.photo_library, color: Colors.white, size: 24)),
              title: const Text('Choose from Gallery'),
              subtitle: const Text('Select up to $_maxImages photos'),
              onTap: () { Navigator.pop(context); _pickImages(); },
            ),
            ListTile(
              leading: Container(width: 48, height: 48, decoration: const BoxDecoration(color: Color(0xFF1A1A1A), shape: BoxShape.circle), child: const Icon(Icons.camera_alt, color: Colors.white, size: 24)),
              title: const Text('Take Photo'),
              subtitle: const Text('Use camera to capture'),
              onTap: () { Navigator.pop(context); _takePhoto(); },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showPrivacyPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const Padding(padding: EdgeInsets.all(16), child: Text('Who can see this?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
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
    const accent = Color(0xFF999999);
    const primary = Color(0xFF1A1A1A);
    return ListTile(
      leading: Container(width: 48, height: 48, decoration: BoxDecoration(color: isSelected ? primary : Colors.grey.shade100, shape: BoxShape.circle), child: Icon(icon, color: isSelected ? Colors.white : Colors.grey.shade600, size: 24)),
      title: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: primary)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
      trailing: isSelected ? const Icon(Icons.check_circle, color: accent) : null,
      onTap: () { setState(() => _privacy = privacy); Navigator.pop(context); },
    );
  }

  ColorFilter? _getFilterMatrix(String filterName) {
    switch (filterName) {
      case 'black_white':
      case 'mono':
        return const ColorFilter.matrix(<double>[0.2126, 0.7152, 0.0722, 0, 0, 0.2126, 0.7152, 0.0722, 0, 0, 0.2126, 0.7152, 0.0722, 0, 0, 0, 0, 0, 1, 0]);
      case 'vintage':
        return const ColorFilter.matrix(<double>[0.393, 0.769, 0.189, 0, 0, 0.349, 0.686, 0.168, 0, 0, 0.272, 0.534, 0.131, 0, 0, 0, 0, 0, 1, 0]);
      case 'cool':
        return const ColorFilter.matrix(<double>[0.9, 0, 0, 0, 0, 0, 0.9, 0, 0, 0, 0, 0, 1.1, 0, 20, 0, 0, 0, 1, 0]);
      case 'warm':
        return const ColorFilter.matrix(<double>[1.1, 0, 0, 0, 10, 0, 1.0, 0, 0, 0, 0, 0, 0.9, 0, 0, 0, 0, 0, 1, 0]);
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: _onPopInvoked,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1A1A1A),
          title: const Text('Photo Post'),
          actions: [
            if (_hasChanges)
              TextButton.icon(
                onPressed: _isSavingDraft ? null : _saveDraft,
                icon: _isSavingDraft ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined, size: 20),
                label: const Text('Save'),
              ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton(
                onPressed: _canPost && !_isPosting ? (_scheduledAt != null ? _schedulePost : _createPost) : null,
                child: _isPosting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(_scheduledAt != null ? 'Schedule' : 'Post'),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_selectedImages.isNotEmpty) ...[
                        _buildImagePreview(),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _filters.length,
                          itemBuilder: (context, index) {
                            final filter = _filters[index];
                            final isSelected = _selectedFilter == filter['name'];
                            return GestureDetector(
                              onTap: () => setState(() => _selectedFilter = filter['name']),
                              child: Container(
                                width: 72,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 64, height: 64,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: isSelected ? const Color(0xFF1A1A1A) : Colors.grey.shade300, width: isSelected ? 3 : 1),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: ColorFiltered(
                                          colorFilter: _getFilterMatrix(filter['name']) ?? const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                                          child: Image.file(_selectedImages.first, fit: BoxFit.cover),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(filter['label'], style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? const Color(0xFF1A1A1A) : Colors.grey.shade700), textAlign: TextAlign.center),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        ),
                      ] else ...[
                        Container(
                          height: 300,
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
                          child: InkWell(
                            onTap: _showMediaOptions,
                            borderRadius: BorderRadius.circular(16),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_photo_alternate, size: 64, color: Colors.grey.shade400),
                                  const SizedBox(height: 12),
                                  Text('Tap to add photos', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],

                      // Caption input
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                UserAvatar(photoUrl: widget.userPhotoUrl, name: widget.userName, radius: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(widget.userName ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      _buildPrivacyButton(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            MentionTextField(
                              controller: _contentController,
                              currentUserId: widget.currentUserId,
                              focusNode: _contentFocusNode,
                              maxLines: null,
                              minLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Write a caption... @ # (optional)',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 16),
                            SchedulePostWidget(initialScheduledAt: _scheduledAt, onScheduleChanged: (date) => setState(() => _scheduledAt = date)),
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
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                                  child: Row(
                                    children: [
                                      Icon(Icons.open_in_full, size: 20, color: const Color(0xFF666666)),
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
                    ],
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(icon: const Icon(Icons.add_photo_alternate), color: const Color(0xFF1A1A1A), onPressed: _showMediaOptions, tooltip: 'Add photos'),
                      if (_selectedImages.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.edit),
                          color: const Color(0xFF1A1A1A),
                          onPressed: () => _editImage(0),
                          tooltip: 'Edit photo',
                        ),
                      IconButton(
                        icon: const Icon(Icons.tag),
                        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
                        onPressed: () {
                          final text = _contentController.text;
                          final selection = _contentController.selection;
                          _contentController.text = '${text.substring(0, selection.baseOffset)}#${text.substring(selection.extentOffset)}';
                          _contentController.selection = TextSelection.collapsed(offset: selection.baseOffset + 1);
                          _contentFocusNode.requestFocus();
                        },
                        tooltip: 'Hashtag',
                      ),
                      IconButton(
                        icon: const Icon(Icons.alternate_email),
                        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
                        onPressed: () {
                          final text = _contentController.text;
                          final selection = _contentController.selection;
                          _contentController.text = '${text.substring(0, selection.baseOffset)}@${text.substring(selection.extentOffset)}';
                          _contentController.selection = TextSelection.collapsed(offset: selection.baseOffset + 1);
                          _contentFocusNode.requestFocus();
                        },
                        tooltip: 'Mention',
                      ),
                      const Spacer(),
                      if (_selectedImages.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
                          child: Text('${_selectedImages.length} photo${_selectedImages.length > 1 ? 's' : ''}', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    final filter = _getFilterMatrix(_selectedFilter);
    if (_selectedImages.length == 1) {
      return Stack(
        children: [
          GestureDetector(
            onTap: () => _editImage(0),
            child: Container(
              width: double.infinity, height: 350, margin: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ColorFiltered(colorFilter: filter ?? const ColorFilter.mode(Colors.transparent, BlendMode.multiply), child: Image.file(_selectedImages.first, fit: BoxFit.cover)),
              ),
            ),
          ),
          Positioned(top: 24, right: 24, child: _buildRemoveButton(0)),
          // Edit button
          Positioned(
            top: 24,
            left: 24,
            child: _buildEditButton(0),
          ),
          // Tap to edit hint
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.touch_app, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text('Tap to edit', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }
    return Container(
      height: 200, margin: const EdgeInsets.only(top: 16),
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _selectedImages.length,
        onReorder: _reorderImages,
        itemBuilder: (context, index) => Container(
          key: ValueKey(_selectedImages[index].path),
          width: 160, margin: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => _editImage(index),
            child: Stack(
              children: [
                ClipRRect(borderRadius: BorderRadius.circular(12), child: ColorFiltered(colorFilter: filter ?? const ColorFilter.mode(Colors.transparent, BlendMode.multiply), child: Image.file(_selectedImages[index], width: 160, height: 200, fit: BoxFit.cover))),
                Positioned(top: 8, right: 8, child: _buildRemoveButton(index)),
                Positioned(top: 8, left: 8, child: _buildEditButton(index)),
                Positioned(bottom: 8, left: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)), child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 12)))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRemoveButton(int index) => GestureDetector(onTap: () => _removeImage(index), child: Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 18)));

  Widget _buildEditButton(int index) => GestureDetector(
    onTap: () => _editImage(index),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.edit, color: Colors.white, size: 14),
          SizedBox(width: 4),
          Text('Edit', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    ),
  );

  Widget _buildPrivacyButton() {
    final color = _getPrivacyColor(_privacy);
    return InkWell(
      onTap: _showPrivacyPicker,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.5))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(_getPrivacyIcon(_privacy), size: 14, color: color),
          const SizedBox(width: 4),
          Text(_getPrivacyLabel(_privacy), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color)),
          Icon(Icons.arrow_drop_down, size: 18, color: color),
        ]),
      ),
    );
  }

  IconData _getPrivacyIcon(PostPrivacy p) {
    switch (p) {
      case PostPrivacy.public: return Icons.public;
      case PostPrivacy.friends: return Icons.group;
      case PostPrivacy.subscribers: return Icons.star;
      case PostPrivacy.private: return Icons.lock;
    }
  }

  String _getPrivacyLabel(PostPrivacy p) {
    switch (p) {
      case PostPrivacy.public: return 'Public';
      case PostPrivacy.friends: return 'Friends';
      case PostPrivacy.subscribers: return 'Subscribers';
      case PostPrivacy.private: return 'Private';
    }
  }

  Color _getPrivacyColor(PostPrivacy p) {
    switch (p) {
      case PostPrivacy.subscribers: return const Color(0xFFF59E0B);
      default: return const Color(0xFF1A1A1A);
    }
  }
}
