import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/group_service.dart';
import '../../widgets/user_avatar.dart';

/// Screen to create a post in a group (text and optional photo).
/// Navigation: Home → Groups → Group detail → Posts tab → FAB / "Chapisha".
class CreateGroupPostScreen extends StatefulWidget {
  final int groupId;
  final int currentUserId;
  final String groupName;
  final String? userPhotoUrl;
  final String? userName;

  const CreateGroupPostScreen({
    super.key,
    required this.groupId,
    required this.currentUserId,
    required this.groupName,
    this.userPhotoUrl,
    this.userName,
  });

  @override
  State<CreateGroupPostScreen> createState() => _CreateGroupPostScreenState();
}

class _CreateGroupPostScreenState extends State<CreateGroupPostScreen> {
  final GroupService _groupService = GroupService();
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  List<File> _mediaFiles = [];
  bool _isPosting = false;

  static const Color _background = Color(0xFFFAFAFA);
  static const Color _primaryText = Color(0xFF1A1A1A);
  static const Color _secondaryText = Color(0xFF666666);
  static const int _maxContentLength = 5000;

  bool get _canPost =>
      (_contentController.text.trim().isNotEmpty || _mediaFiles.isNotEmpty) &&
      _contentController.text.length <= _maxContentLength;
  bool get _isOverLength => _contentController.text.length > _maxContentLength;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (image != null && mounted) {
      setState(() => _mediaFiles.add(File(image.path)));
    }
  }

  void _removeMedia(int index) {
    setState(() => _mediaFiles.removeAt(index));
  }

  Future<void> _submit() async {
    if (!_canPost) return;

    setState(() => _isPosting = true);

    try {
      final result = await _groupService.createGroupPost(
        groupId: widget.groupId,
        userId: widget.currentUserId,
        content: _contentController.text.trim().isEmpty
            ? null
            : _contentController.text.trim(),
        media: _mediaFiles.isEmpty ? null : _mediaFiles,
      );

      if (mounted) {
        setState(() => _isPosting = false);

        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chapisho limechapishwa')),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ?? 'Imeshindwa kuchapisha. Jaribu tena.'),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isPosting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imeshindwa kuchapisha. Jaribu tena.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        title: Text(
          'Chapisha kwenye ${widget.groupName}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _primaryText,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: _primaryText),
          onPressed: () => Navigator.pop(context),
          style: IconButton.styleFrom(
            minimumSize: const Size(48, 48),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UserAvatar(
                    photoUrl: widget.userPhotoUrl,
                    name: widget.userName,
                    radius: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _contentController,
                      maxLines: 6,
                      maxLength: _maxContentLength,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Andika machapisho...',
                        hintStyle: const TextStyle(color: _secondaryText),
                        border: InputBorder.none,
                        counterText: _isOverLength
                            ? '${_contentController.text.length}/$_maxContentLength'
                            : null,
                        counterStyle: TextStyle(
                          color: _isOverLength ? Colors.red : _secondaryText,
                          fontSize: 12,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        color: _primaryText,
                      ),
                    ),
                  ),
                ],
              ),
              if (_mediaFiles.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _mediaFiles.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _mediaFiles[index],
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Material(
                              color: Colors.black54,
                              shape: const CircleBorder(),
                              child: InkWell(
                                onTap: () => _removeMedia(index),
                                customBorder: const CircleBorder(),
                                child: const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Icon(Icons.close, color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      elevation: 2,
                      shadowColor: Colors.black.withOpacity(0.1),
                      child: InkWell(
                        onTap: _pickImage,
                        borderRadius: BorderRadius.circular(12),
                        child: const Icon(Icons.photo_library_outlined, color: _primaryText),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Material(
                      color: _primaryText,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: _isPosting || !_canPost ? null : _submit,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: _isPosting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  'Chapisha',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: _canPost ? Colors.white : Colors.white70,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
