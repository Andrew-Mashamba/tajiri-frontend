import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../l10n/app_strings.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/livestream_service.dart';
import 'backstage_screen.dart';
import 'live_broadcast_screen_advanced.dart';

class GoLiveScreen extends StatefulWidget {
  final int userId;

  const GoLiveScreen({super.key, required this.userId});

  @override
  State<GoLiveScreen> createState() => _GoLiveScreenState();
}

class _GoLiveScreenState extends State<GoLiveScreen> {
  final LiveStreamService _streamService = LiveStreamService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    print('[GoLiveScreen] Initialized with userId: ${widget.userId}');
  }

  File? _thumbnail;
  String? _category;
  List<String> _tags = [];
  String _privacy = 'public';
  bool _isRecorded = true;
  bool _allowComments = true;
  bool _allowGifts = true;
  bool _isLoading = false;
  bool _isScheduling = false;
  DateTime? _scheduledAt;

  static const List<String> _categoryIds = [
    'music', 'sports', 'education', 'talk',
    'entertainment', 'business', 'technology', 'other',
  ];

  Future<void> _pickThumbnail() async {
    print('[GoLiveScreen] Picking thumbnail image...');
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,  // Limit width to 1920px
        maxHeight: 1080, // Limit height to 1080px
        imageQuality: 85, // Compress to 85% quality
      );
      if (image != null) {
        final file = File(image.path);
        final fileSize = await file.length();
        print('[GoLiveScreen] Thumbnail selected: ${image.path}');
        print('[GoLiveScreen] Thumbnail size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');

        // Check if still too large (5MB = 5120KB limit)
        if (fileSize > 5 * 1024 * 1024) {
          print('[GoLiveScreen] WARNING: Thumbnail still too large after compression');
          // Try picking again with lower quality
          final compressedImage = await _picker.pickImage(
            source: ImageSource.gallery,
            maxWidth: 1280,
            maxHeight: 720,
            imageQuality: 70,
          );
          if (compressedImage != null) {
            final compressedFile = File(compressedImage.path);
            final compressedSize = await compressedFile.length();
            print('[GoLiveScreen] Recompressed thumbnail size: ${(compressedSize / 1024 / 1024).toStringAsFixed(2)} MB');
            setState(() => _thumbnail = compressedFile);
          }
        } else {
          setState(() => _thumbnail = file);
        }
      } else {
        print('[GoLiveScreen] No thumbnail selected');
      }
    } catch (e) {
      print('[GoLiveScreen] ERROR picking thumbnail: $e');
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() => _tags.add(tag));
      _tagController.clear();
    }
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  Future<void> _pickScheduleTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _scheduledAt = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _createStream() async {
    print('[GoLiveScreen] _createStream called');
    print('[GoLiveScreen] Title: ${_titleController.text}');
    print('[GoLiveScreen] IsScheduling: $_isScheduling');
    print('[GoLiveScreen] UserId: ${widget.userId}');

    final s = AppStringsScope.of(context);
    if (_titleController.text.isEmpty) {
      print('[GoLiveScreen] ERROR: Title is empty');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s?.pleaseEnterTitle ?? 'Please enter a title')),
      );
      return;
    }

    if (_isScheduling && _scheduledAt == null) {
      print('[GoLiveScreen] ERROR: Scheduling enabled but no time selected');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s?.pleaseSelectBroadcastTime ?? 'Please select broadcast time')),
      );
      return;
    }

    setState(() => _isLoading = true);
    print('[GoLiveScreen] Creating stream...');

    try {
      final result = await _streamService.createStream(
      userId: widget.userId,
      title: _titleController.text,
      description:
          _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
      thumbnail: _thumbnail,
      category: _category,
      tags: _tags.isNotEmpty ? _tags : null,
      privacy: _privacy,
      isRecorded: _isRecorded,
      allowComments: _allowComments,
      allowGifts: _allowGifts,
      scheduledAt: _isScheduling ? _scheduledAt : null,
      );

      print('[GoLiveScreen] Stream creation result - success: ${result.success}');
      if (result.success && result.stream != null) {
        print('[GoLiveScreen] Stream created successfully - ID: ${result.stream!.id}');
      } else {
        print('[GoLiveScreen] Stream creation failed - message: ${result.message}');
      }

      setState(() => _isLoading = false);

      if (result.success && result.stream != null) {
      if (mounted) {
        if (_isScheduling) {
          final ds = AppStringsScope.of(context);
          // Scheduled for later - Show success dialog with instructions
          print('[GoLiveScreen] Stream scheduled successfully for ${_scheduledAt}');
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 32),
                  const SizedBox(width: 12),
                  Text(ds?.broadcastScheduled ?? 'Broadcast scheduled!'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ds?.broadcastScheduledMessage(result.stream!.title) ?? 'Your broadcast has been scheduled.',
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ds?.followersWillGetNotification ?? 'Your followers will get a notification:',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        _buildStep('✓', ds?.stepBroadcastOnLiveTab ?? 'Broadcast will appear on Live tab'),
                        _buildStep('✓', ds?.stepViewersSeeCountdown ?? 'Viewers will see countdown'),
                        _buildStep('✓', ds?.stepNotificationBeforeTime ?? "You'll get a notification before the time"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ds?.toStartBroadcasting ?? 'To start broadcasting:',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        _buildStep('1', ds?.stepGoToProfileLiveScheduled ?? 'Go to Profile > Live > Scheduled'),
                        _buildStep('2', ds?.stepTapYourBroadcast ?? 'Tap your broadcast'),
                        _buildStep('3', ds?.stepTapStartNowWhenReady ?? 'Tap "Start now" when ready'),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: Text(ds?.ok ?? 'OK'),
                ),
              ],
            ),
          );
        } else {
          // Go live now - Navigate directly to backstage
          print('[GoLiveScreen] Going live now - navigating to backstage for stream ID: ${result.stream!.id}');
          Navigator.pop(context); // Close GoLiveScreen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (backstageContext) => BackstageScreen(
                stream: result.stream!,
                onGoLive: () async {
                  // This callback is called when user clicks "Enda Live" from backstage
                  print('[GoLiveScreen] User clicked Enda Live from backstage - starting stream ${result.stream!.id}');

                  // Safety check: Don't start if already live
                  if (result.stream!.status == 'live') {
                    print('[GoLiveScreen] ⚠️ Stream is already live, skipping startStream call');
                    if (backstageContext.mounted) {
                      final bs = AppStringsScope.of(backstageContext);
                      ScaffoldMessenger.of(backstageContext).showSnackBar(
                        SnackBar(
                          content: Text(bs?.broadcastAlreadyLive ?? 'Broadcast is already live!'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                    return;
                  }

                  // Call startStream API to transition from scheduled → pre_live → live
                  final startResult = await _streamService.startStream(result.stream!.id);

                  if (startResult.success && startResult.stream != null) {
                    print('[GoLiveScreen] Stream started successfully! Status: ${startResult.stream!.status}');

                    // Navigate to advanced live broadcast screen
                    if (backstageContext.mounted) {
                      Navigator.pushReplacement(
                        backstageContext,
                        MaterialPageRoute(
                          builder: (_) => LiveBroadcastScreenAdvanced(
                            stream: startResult.stream!,
                            currentUserId: widget.userId,
                          ),
                        ),
                      );
                    }
                  } else {
                    print('[GoLiveScreen] Failed to start stream: ${startResult.message}');
                    if (backstageContext.mounted) {
                      // Check if stream is already live
                      if (startResult.message?.toLowerCase().contains('live') ?? false) {
                        final bs = AppStringsScope.of(backstageContext);
                        showDialog(
                          context: backstageContext,
                          builder: (ctx) => AlertDialog(
                            title: Row(
                              children: [
                                const Icon(Icons.live_tv, color: Colors.green, size: 28),
                                const SizedBox(width: 12),
                                Expanded(child: Text(bs?.youAreAlreadyLive ?? "You're already live!")),
                              ],
                            ),
                            content: Text(
                              bs?.broadcastAlreadyLiveMessage ?? 'Your broadcast is already live. You cannot start it again.',
                              style: const TextStyle(fontSize: 14),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  Navigator.pop(backstageContext);
                                },
                                child: Text(bs?.ok ?? 'OK'),
                              ),
                            ],
                          ),
                        );
                      }
                      // Check if it's the status transition error
                      else if (startResult.message?.contains('scheduled') ?? false) {
                        final bs = AppStringsScope.of(backstageContext);
                        showDialog(
                          context: backstageContext,
                          builder: (ctx) => AlertDialog(
                            title: Row(
                              children: [
                                const Icon(Icons.info_outline, color: Colors.orange, size: 28),
                                const SizedBox(width: 12),
                                Expanded(child: Text(bs?.waitAMoment ?? 'Wait a moment')),
                              ],
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bs?.broadcastReadyBackendPreparing ?? 'Your broadcast is ready, but the backend is still preparing.',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  bs?.goToProfileLiveScheduledTapStart ?? 'Go to Profile > Live > Scheduled and tap "Start now".',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  Navigator.pop(backstageContext);
                                },
                                child: Text(bs?.ok ?? 'OK'),
                              ),
                            ],
                          ),
                        );
                      } else {
                        final bs = AppStringsScope.of(backstageContext);
                        ScaffoldMessenger.of(backstageContext).showSnackBar(
                          SnackBar(
                            content: Text(bs?.failedToStartStream(startResult.message) ?? 'Failed to start'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
                onCancel: () {
                  // User cancelled from backstage
                  print('[GoLiveScreen] User cancelled from backstage');
                  if (mounted) {
                    Navigator.pop(context);
                  }
                },
              ),
            ),
          );
        }
      }
    } else {
      if (mounted) {
        final es = AppStringsScope.of(context);
        print('[GoLiveScreen] Showing error message to user');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? (es?.failedToCreateBroadcast ?? 'Failed to create broadcast'))),
        );
      }
    }
    } catch (e, stackTrace) {
      print('[GoLiveScreen] EXCEPTION in _createStream: $e');
      print('[GoLiveScreen] Stack trace: $stackTrace');
      setState(() => _isLoading = false);
      if (mounted) {
        final es = AppStringsScope.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${es?.error ?? 'Error'}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(s?.goLive ?? 'Go live'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createStream,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _isScheduling ? (s?.scheduleShort ?? 'Schedule') : (s?.goLive ?? 'Go live'),
                    style: const TextStyle(color: Colors.red),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // When to go live - Prominent section
            Text(
              s?.goLiveWhen ?? 'When do you want to go live?',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTimeOptionCard(
                    icon: Icons.play_circle_fill,
                    label: s?.now ?? 'Now',
                    description: s?.goLiveNowDescription ?? 'Go live now',
                    isSelected: !_isScheduling,
                    onTap: () => setState(() => _isScheduling = false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTimeOptionCard(
                    icon: Icons.schedule,
                    label: s?.scheduleShort ?? 'Schedule',
                    description: s?.scheduleFollowersNotify ?? 'Followers will get a notification',
                    isSelected: _isScheduling,
                    onTap: () {
                      setState(() => _isScheduling = true);
                      if (_scheduledAt == null) {
                        _pickScheduleTime();
                      }
                    },
                  ),
                ),
              ],
            ),
            if (_isScheduling) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickScheduleTime,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s?.broadcastTime ?? 'Broadcast time',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _scheduledAt != null
                                  ? _formatDateTime(_scheduledAt!, s)
                                  : (s?.tapToChooseDateTime ?? 'Tap to choose date and time'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _scheduledAt != null
                                    ? Colors.black
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.blue.shade700),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Thumbnail
            GestureDetector(
              onTap: _pickThumbnail,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  image: _thumbnail != null
                      ? DecorationImage(
                          image: FileImage(_thumbnail!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _thumbnail == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate,
                              size: 48, color: Colors.grey[500]),
                          const SizedBox(height: 8),
                          Text(
                            s?.addCoverImage ?? 'Add cover image',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      )
                    : Stack(
                        children: [
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black45,
                              ),
                              onPressed: () => setState(() => _thumbnail = null),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: s?.broadcastTitle ?? 'Broadcast title',
                hintText: s?.enterTitleHint ?? 'Enter title...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: s?.description ?? 'Description',
                hintText: s?.broadcastDescriptionHint ?? 'Broadcast description...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Category
            DropdownButtonFormField<String>(
              value: _category,
              decoration: InputDecoration(
                labelText: s?.category ?? 'Category',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _categoryIds.map((id) {
                return DropdownMenuItem(
                  value: id,
                  child: Text(s?.goLiveCategory(id) ?? id),
                );
              }).toList(),
              onChanged: (value) => setState(() => _category = value),
            ),
            const SizedBox(height: 16),

            // Tags
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: InputDecoration(
                      labelText: s?.tagLabel ?? 'Tag',
                      hintText: s?.addTagHint ?? 'Add tag',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addTag,
                ),
              ],
            ),
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    onDeleted: () => _removeTag(tag),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 24),
            const Divider(),

            // Settings
            Text(
              s?.settings ?? 'Settings',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Privacy
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.lock),
              title: Text(s?.privacy ?? 'Privacy'),
              subtitle: Text(_privacyLabel(s)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showPrivacyOptions(s),
            ),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.save),
              title: Text(s?.recordBroadcast ?? 'Record broadcast'),
              subtitle: Text(s?.recordBroadcastSubtitle ?? 'Save broadcast for later'),
              value: _isRecorded,
              onChanged: (v) => setState(() => _isRecorded = v),
            ),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.comment),
              title: Text(s?.allowComments ?? 'Allow comments'),
              value: _allowComments,
              onChanged: (v) => setState(() => _allowComments = v),
            ),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.card_giftcard),
              title: Text(s?.allowGifts ?? 'Allow gifts'),
              subtitle: Text(s?.allowGiftsSubtitle ?? 'Viewers can send gifts'),
              value: _allowGifts,
              onChanged: (v) => setState(() => _allowGifts = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeOptionCard({
    required IconData icon,
    required String label,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue.shade700 : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? Colors.blue.shade700 : Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.blue.shade700 : Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _privacyLabel(AppStrings? s) {
    switch (_privacy) {
      case 'followers':
        return s?.privacyFollowersOnly ?? 'Followers only';
      case 'private':
        return s?.private ?? 'Private';
      default:
        return s?.privacyEveryone ?? 'Everyone';
    }
  }

  void _showPrivacyOptions(AppStrings? s) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.public),
            title: Text(s?.privacyEveryone ?? 'Everyone'),
            subtitle: Text(s?.everyoneCanWatch ?? 'Everyone can watch'),
            trailing:
                _privacy == 'public' ? const Icon(Icons.check, color: Colors.green) : null,
            onTap: () {
              setState(() => _privacy = 'public');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: Text(s?.followers ?? 'Followers'),
            subtitle: Text(s?.onlyYourFollowers ?? 'Only your followers'),
            trailing:
                _privacy == 'followers' ? const Icon(Icons.check, color: Colors.green) : null,
            onTap: () {
              setState(() => _privacy = 'followers');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: Text(s?.private ?? 'Private'),
            subtitle: Text(s?.privacyOnlyYou ?? 'Only you'),
            trailing:
                _privacy == 'private' ? const Icon(Icons.check, color: Colors.green) : null,
            onTap: () {
              setState(() => _privacy = 'private');
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime, AppStrings? s) {
    final month = s?.goLiveMonthShort(dateTime.month) ?? _defaultMonthShort(dateTime.month);
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.day} $month ${dateTime.year}, $hour:$minute';
  }

  static String _defaultMonthShort(int month) {
    const en = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (month < 1 || month > 12) return '';
    return en[month - 1];
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }
}
