// lib/myphotos/pages/my_photos_page.dart
//
// Top-level entry for the lib/myphotos/ module. Wraps the existing
// staggered photo gallery in a Scaffold + AppBar with creator-side
// chrome (uploads, albums, earnings link).
//
// Per docs/CREATOR_REVENUE_TAXONOMY.md §2 — "My Photos" is a
// first-class content type with its own engagement primitives
// (views, reactions, comments, shares, saves, view-time, tips).
// Earnings will be itemized in this module once backend v2 ships
// the per-media-type breakdown.

import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../widgets/photo_gallery_widget.dart';

class MyPhotosPage extends StatelessWidget {
  final int userId;
  final bool isOwnProfile;

  const MyPhotosPage({
    super.key,
    required this.userId,
    this.isOwnProfile = true,
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
          isSw ? 'Picha Zangu' : 'My Photos',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: PhotoGalleryWidget(
          userId: userId,
          isOwnProfile: isOwnProfile,
          heroTagPrefix: 'my_photos',
        ),
      ),
    );
  }
}
