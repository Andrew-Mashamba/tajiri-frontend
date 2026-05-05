// lib/mymusic/pages/my_music_page.dart
//
// Top-level entry for the lib/mymusic/ module. Wraps the existing
// MusicGalleryWidget in a Scaffold + AppBar.

import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../widgets/music_gallery_widget.dart';

class MyMusicPage extends StatelessWidget {
  final int userId;
  final bool isOwnProfile;
  final VoidCallback? onUploadComplete;

  const MyMusicPage({
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
          isSw ? 'Muziki Wangu' : 'My Music',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: MusicGalleryWidget(
          userId: userId,
          isOwnProfile: isOwnProfile,
          onUploadComplete: onUploadComplete,
        ),
      ),
    );
  }
}
