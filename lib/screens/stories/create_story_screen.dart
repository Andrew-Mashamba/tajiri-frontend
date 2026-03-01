import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/story_service.dart';

class CreateStoryScreen extends StatefulWidget {
  final int userId;

  const CreateStoryScreen({super.key, required this.userId});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final StoryService _storyService = StoryService();
  final TextEditingController _captionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _selectedMedia;
  String _mediaType = 'text';
  Color _backgroundColor = Colors.blue;
  String _privacy = 'everyone';
  bool _allowReplies = true;
  bool _allowSharing = true;
  bool _isLoading = false;

  final List<Color> _backgroundColors = [
    Colors.blue,
    Colors.purple,
    Colors.pink,
    Colors.orange,
    Colors.green,
    Colors.teal,
    Colors.red,
    Colors.indigo,
  ];

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedMedia = File(image.path);
        _mediaType = 'image';
      });
    }
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 15),
    );
    if (video != null) {
      setState(() {
        _selectedMedia = File(video.path);
        _mediaType = 'video';
      });
    }
  }

  Future<void> _takePhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _selectedMedia = File(image.path);
        _mediaType = 'image';
      });
    }
  }

  Future<void> _takeVideo() async {
    final XFile? video = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(seconds: 15),
    );
    if (video != null) {
      setState(() {
        _selectedMedia = File(video.path);
        _mediaType = 'video';
      });
    }
  }

  void _clearMedia() {
    setState(() {
      _selectedMedia = null;
      _mediaType = 'text';
    });
  }

  Future<void> _createStory() async {
    if (_mediaType == 'text' && _captionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tafadhali andika kitu')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _storyService.createStory(
      userId: widget.userId,
      mediaType: _mediaType,
      media: _selectedMedia,
      caption: _captionController.text.isNotEmpty ? _captionController.text : null,
      backgroundColor:
          _mediaType == 'text' ? '#${_backgroundColor.value.toRadixString(16).substring(2)}' : null,
      privacy: _privacy,
      allowReplies: _allowReplies,
      allowSharing: _allowSharing,
    );

    setState(() => _isLoading = false);

    if (result.success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hadithi imechapishwa!')),
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Imeshindwa kuchapisha hadithi')),
        );
      }
    }
  }

  void _showPrivacyOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.public),
            title: const Text('Kila mtu'),
            subtitle: const Text('Wote wanaweza kuona'),
            trailing: _privacy == 'everyone' ? const Icon(Icons.check, color: Colors.green) : null,
            onTap: () {
              setState(() => _privacy = 'everyone');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Wafuasi'),
            subtitle: const Text('Wafuasi wako tu'),
            trailing: _privacy == 'followers' ? const Icon(Icons.check, color: Colors.green) : null,
            onTap: () {
              setState(() => _privacy = 'followers');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.star, color: Color(0xFFF59E0B)),
            title: const Text('Wasajili Pekee'),
            subtitle: const Text('Wasajili wako tu wanaweza kuona'),
            trailing: _privacy == 'subscribers' ? const Icon(Icons.check, color: Color(0xFFF59E0B)) : null,
            onTap: () {
              setState(() => _privacy = 'subscribers');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite),
            title: const Text('Marafiki wa Karibu'),
            subtitle: const Text('Orodha yako ya marafiki wa karibu'),
            trailing:
                _privacy == 'close_friends' ? const Icon(Icons.check, color: Colors.green) : null,
            onTap: () {
              setState(() => _privacy = 'close_friends');
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _mediaType == 'text' ? _backgroundColor : Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_selectedMedia != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _clearMedia,
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Content
          if (_selectedMedia != null && _mediaType == 'image')
            Image.file(_selectedMedia!, fit: BoxFit.contain)
          else if (_selectedMedia != null && _mediaType == 'video')
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.videocam, color: Colors.white54, size: 64),
                  const SizedBox(height: 8),
                  Text(
                    'Video imechaguliwa',
                    style: TextStyle(color: Colors.white.withOpacity(0.7)),
                  ),
                ],
              ),
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: TextField(
                  controller: _captionController,
                  maxLines: null,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Andika hadithi yako...',
                    hintStyle: TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
                top: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
              child: Column(
                children: [
                  // Color picker for text stories
                  if (_mediaType == 'text')
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _backgroundColors.length,
                        itemBuilder: (context, index) {
                          final color = _backgroundColors[index];
                          return GestureDetector(
                            onTap: () => setState(() => _backgroundColor = color),
                            child: Container(
                              width: 40,
                              height: 40,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: _backgroundColor == color
                                    ? Border.all(color: Colors.white, width: 3)
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Media controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _MediaButton(
                        icon: Icons.photo_library,
                        label: 'Picha',
                        onTap: _pickImage,
                      ),
                      _MediaButton(
                        icon: Icons.video_library,
                        label: 'Video',
                        onTap: _pickVideo,
                      ),
                      _MediaButton(
                        icon: Icons.camera_alt,
                        label: 'Piga',
                        onTap: _takePhoto,
                      ),
                      _MediaButton(
                        icon: Icons.videocam,
                        label: 'Rekodi',
                        onTap: _takeVideo,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Post button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createStory,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Chapisha Hadithi'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.lock),
                title: const Text('Faragha'),
                subtitle: Text(_privacyLabel),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  _showPrivacyOptions();
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.reply),
                title: const Text('Ruhusu Majibu'),
                value: _allowReplies,
                onChanged: (value) {
                  setModalState(() => _allowReplies = value);
                  setState(() => _allowReplies = value);
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.share),
                title: const Text('Ruhusu Kushiriki'),
                value: _allowSharing,
                onChanged: (value) {
                  setModalState(() => _allowSharing = value);
                  setState(() => _allowSharing = value);
                },
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  String get _privacyLabel {
    switch (_privacy) {
      case 'followers':
        return 'Wafuasi';
      case 'subscribers':
        return 'Wasajili Pekee';
      case 'close_friends':
        return 'Marafiki wa Karibu';
      default:
        return 'Kila mtu';
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }
}

class _MediaButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MediaButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
