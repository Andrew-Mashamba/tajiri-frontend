// lib/myvideos/pages/my_videos_page.dart
//
// Top-level entry for the lib/myvideos/ module. Wraps the existing
// VideoGalleryWidget in a Scaffold + AppBar.

import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../widgets/video_gallery_widget.dart';

class MyVideosPage extends StatelessWidget {
  final int userId;
  final bool isOwnProfile;
  final VoidCallback? onUploadComplete;

  const MyVideosPage({
    super.key,
    required this.userId,
    this.isOwnProfile = true,
    this.onUploadComplete,
  });

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(
          isSw ? 'Video Zangu' : 'My Videos',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
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
