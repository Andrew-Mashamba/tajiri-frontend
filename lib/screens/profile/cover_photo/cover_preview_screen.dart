// CoverPreviewScreen — live profile-chrome preview of the cropped cover.
// Spec: docs/superpowers/specs/2026-05-02-cover-photo-upload-design.md §3 (step 3)
//
// Renders the actual profile chrome (avatar circle, name + @username, the
// gradient overlay, the camera-button overlay) on top of the cropped image
// at the real 280dp canvas size, so the user sees the result before
// committing the upload.
//
// Returns:
//   true  → user tapped Save     (orchestrator should compress + upload)
//   false → user tapped Crop again (orchestrator should re-open cropper
//                                    with the original source)
//   null  → user tapped Cancel / popped (abort the whole flow)

import 'dart:io';

import 'package:flutter/material.dart';

import '../../../l10n/app_strings_scope.dart';
import 'cover_canvas.dart';

/// Hero tag used for the cropped image so it animates smoothly between the
/// orchestrator-host context (e.g. preview canvas) and any consumer.
const String kCoverPreviewHeroTag = 'cover_preview_image';

class CoverPreviewScreen extends StatelessWidget {
  final File croppedImage;
  final String? avatarUrl;
  final String? avatarInitials;
  final String? fullName;
  final String? username;

  const CoverPreviewScreen({
    super.key,
    required this.croppedImage,
    required this.avatarUrl,
    required this.avatarInitials,
    required this.fullName,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final isSw = s?.isSwahili ?? false;
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(
          isSw ? 'Hakiki' : 'Preview',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(null),
          tooltip: isSw ? 'Ghairi' : 'Cancel',
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                isSw
                    ? 'Hivi ndivyo picha ya jalada itakavyoonekana kwenye profile yako.'
                    : "Here's how your cover photo will look on your profile.",
                style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),
            // The profile chrome simulation. Hero allows smooth transition
            // back to the actual cover canvas after Save. Uses the same
            // CoverCanvas widget the profile screen renders, so the framing
            // / aspect / chrome match exactly.
            Hero(
              tag: kCoverPreviewHeroTag,
              child: AspectRatio(
                // Match the live cover exactly: full screen width × 9/16.
                // The cropper produced a 16:9 source, so this renders the
                // user's crop 1:1 with no edge cropping.
                aspectRatio: 16 / 9,
                child: CoverCanvas(
                  cover: CoverImageSource.file(croppedImage),
                  avatarUrl: avatarUrl,
                  avatarInitials: avatarInitials,
                  fullName: fullName,
                  username: username,
                  showStaticCameraIcon: true,
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1A1A1A),
                        foregroundColor: const Color(0xFFFAFAFA),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isSw ? 'Hifadhi' : 'Save',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1A1A1A),
                        side: const BorderSide(color: Color(0xFFE5E5E5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isSw ? 'Hariri tena' : 'Crop again',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

