// ProfilePhotoPreviewScreen — live profile-chrome preview for the new avatar.
// Spec: docs/superpowers/specs/2026-05-02-profile-photo-upload-design.md §3
//
// Shows the user's current cover with the *new* avatar overlaid via the
// shared CoverCanvas widget — the same code path the live profile uses,
// so the preview is pixel-identical to the post-upload result.
// Adds a soft inline face-validation hint (never blocks; FaceValidator
// is optional and best-effort).

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_strings_scope.dart';
import '../../../utils/face_validator.dart';
import '../cover_photo/cover_canvas.dart';

/// Hero tag for the avatar so it animates smoothly between cropper and
/// preview, and back to the live profile.
const String kProfilePhotoPreviewHeroTag = 'profile_photo_preview_avatar';

class ProfilePhotoPreviewScreen extends StatefulWidget {
  final File croppedAvatar;
  final String? currentCoverUrl;
  final String? avatarInitials;
  final String? fullName;
  final String? username;

  const ProfilePhotoPreviewScreen({
    super.key,
    required this.croppedAvatar,
    required this.currentCoverUrl,
    required this.avatarInitials,
    required this.fullName,
    required this.username,
  });

  @override
  State<ProfilePhotoPreviewScreen> createState() =>
      _ProfilePhotoPreviewScreenState();
}

class _ProfilePhotoPreviewScreenState extends State<ProfilePhotoPreviewScreen> {
  /// null = check still running, true = exactly 1 face, false = 0 or >1.
  bool? _hasSingleFace;

  /// Bbox of the largest detected face — surfaced so the orchestrator can
  /// pop it back via the navigator result and forward to the backend.
  Rect? _faceBounds;

  /// Guard against double-pop: when the user taps Save / Crop again /
  /// Cancel rapidly, only the first call should reach Navigator.pop.
  /// The Navigator is briefly locked during transitions and a second pop
  /// trips the `!_debugLocked` assertion.
  bool _decisionTaken = false;

  void _decide(String action) {
    if (_decisionTaken) return;
    _decisionTaken = true;
    Navigator.of(context).pop(
      ProfilePhotoPreviewDecision(action: action, faceBounds: _faceBounds),
    );
  }

  @override
  void initState() {
    super.initState();
    _runFaceCheck();
  }

  Future<void> _runFaceCheck() async {
    try {
      final result = await FaceValidator.validate(widget.croppedAvatar);
      if (!mounted) return;
      setState(() {
        _hasSingleFace = result.isValid;
        _faceBounds = result.faceBounds;
      });
    } catch (e, st) {
      if (kDebugMode) debugPrint('[ProfilePhotoPreview] face check failed: $e\n$st');
      if (!mounted) return;
      // Best-effort only — never block. Treat as "no signal".
      setState(() => _hasSingleFace = null);
    }
  }

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
          onPressed: () => _decide('cancel'),
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
                    ? 'Hivi ndivyo picha ya profaili itakavyoonekana.'
                    : "Here's how your profile photo will look.",
                style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),
            // Same widget the live profile uses — guarantees pixel parity.
            Hero(
              tag: kProfilePhotoPreviewHeroTag,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: CoverCanvas(
                  cover: (widget.currentCoverUrl != null && widget.currentCoverUrl!.isNotEmpty)
                      ? CoverImageSource.url(widget.currentCoverUrl!)
                      : const CoverImageSource.empty(),
                  avatarFile: widget.croppedAvatar,
                  avatarUrl: null,
                  avatarInitials: widget.avatarInitials,
                  fullName: widget.fullName,
                  username: widget.username,
                  showStaticCameraIcon: true,
                ),
              ),
            ),
            if (_hasSingleFace == false)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _SoftFaceHint(isSw: isSw),
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
                      onPressed: () => _decide('save'),
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
                      onPressed: () => _decide('crop_again'),
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

/// Result returned from the preview screen. Carries the optional face
/// bounds so the orchestrator can forward them to the backend without
/// re-running FaceValidator on the same file.
class ProfilePhotoPreviewDecision {
  /// 'save' | 'crop_again' | 'cancel'
  final String action;
  final Rect? faceBounds;

  const ProfilePhotoPreviewDecision({
    required this.action,
    this.faceBounds,
  });
}

/// Soft inline note — never blocks, only suggests. Matches the existing
/// non-blocking face-validation philosophy in the codebase.
class _SoftFaceHint extends StatelessWidget {
  final bool isSw;
  const _SoftFaceHint({required this.isSw});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        border: Border.all(color: const Color(0xFFFFE082)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            size: 16,
            color: Color(0xFF7A5800),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isSw
                  ? 'Picha yenye uso mmoja wazi inafanya vyema.'
                  : 'A clear single-face photo reads best.',
              style: const TextStyle(fontSize: 12, color: Color(0xFF7A5800)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
