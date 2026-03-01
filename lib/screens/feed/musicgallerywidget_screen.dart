import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../../widgets/gallery/music_gallery_widget.dart';

/// Profile music gallery screen (Story 78).
/// Navigation: Home → Profile → Tab [Muziki] → MusicGalleryWidget.
/// This screen wraps [MusicGalleryWidget] for direct routes (e.g. /profile/:id/music).
/// Design: DOCS/DESIGN.md (SafeArea, touch targets 48dp min, #FAFAFA).
class MusicGalleryWidgetScreen extends StatefulWidget {
  /// Profile user whose music is shown.
  final int userId;
  /// Current logged-in user; if null, resolved from [LocalStorageService].
  final int? currentUserId;

  const MusicGalleryWidgetScreen({
    super.key,
    required this.userId,
    this.currentUserId,
  });

  @override
  State<MusicGalleryWidgetScreen> createState() =>
      _MusicGalleryWidgetScreenState();
}

class _MusicGalleryWidgetScreenState extends State<MusicGalleryWidgetScreen> {
  int? _currentUserId;
  bool _resolvingUser = true;

  @override
  void initState() {
    super.initState();
    if (widget.currentUserId != null) {
      _currentUserId = widget.currentUserId;
      _resolvingUser = false;
    } else {
      _loadCurrentUser();
    }
  }

  Future<void> _loadCurrentUser() async {
    final storage = await LocalStorageService.getInstance();
    final user = storage.getUser();
    if (mounted) {
      setState(() {
        _currentUserId = user?.userId;
        _resolvingUser = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text(
          'Muziki',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        scrolledUnderElevation: 2,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A), size: 24),
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Rudi',
          style: IconButton.styleFrom(
            minimumSize: const Size(48, 48),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ),
      body: SafeArea(
        child: _resolvingUser
            ? const Center(child: CircularProgressIndicator())
            : MusicGalleryWidget(
                userId: widget.userId,
                isOwnProfile: _currentUserId != null &&
                    widget.userId == _currentUserId,
                onUploadComplete: () {
                  // Optional: refresh if needed when returning from upload
                },
              ),
      ),
    );
  }
}
