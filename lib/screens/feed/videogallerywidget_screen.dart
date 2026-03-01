import 'package:flutter/material.dart';
import '../../widgets/gallery/video_gallery_widget.dart';

/// Profile Video Gallery screen (Story 77).
/// Navigation: Home → Profile → Tab [Video] → VideoGalleryWidget (this screen).
/// Shows a grid of clip thumbnails; tap to play fullscreen.
class VideoGalleryWidgetScreen extends StatelessWidget {
  final int userId;
  final bool isOwnProfile;
  final VoidCallback? onUploadComplete;

  const VideoGalleryWidgetScreen({
    super.key,
    required this.userId,
    this.isOwnProfile = false,
    this.onUploadComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: VideoGalleryWidget(
          userId: userId,
          isOwnProfile: isOwnProfile,
          onUploadComplete: onUploadComplete,
        ),
      ),
    );
  }
}
