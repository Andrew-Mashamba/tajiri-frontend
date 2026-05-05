// CoverPhotoOrchestrator — drives the cover-photo flow end to end.
// Spec: docs/superpowers/specs/2026-05-02-cover-photo-upload-design.md §3
//
// Flow:
//   1. Show CoverPhotoActionsSheet (Gallery / Camera / Remove).
//   2. For pick/capture: image_picker → cropForCover() → CoverPreviewScreen.
//   3. From preview the user can Save (compress + upload) or Crop again
//      (re-open cropper with the same source).
//   4. Compression: flutter_image_compress to 2048-wide JPEG q82, EXIF stripped.
//   5. Upload: ProfileService.updateCoverPhoto() with onProgress + CancelToken.
//      State callbacks let the caller render CoverUploadOverlay inline on
//      the cover canvas instead of using SnackBars.
//   6. Remove: ProfileService.removeCoverPhoto().
//
// The orchestrator is a pure-logic driver — no widgets of its own. The
// caller (profile_screen.dart) wires UI state via the provided callbacks.

import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../services/profile_service.dart';
import 'cover_crop_screen.dart';
import 'cover_photo_actions_sheet.dart';
import 'cover_preview_screen.dart';

/// Outcome of the orchestrator run.
class CoverPhotoOutcome {
  final bool success;
  final String? newCoverUrl; // null after a successful Remove
  final bool removed;
  final String? errorMessage; // user-facing, already localized
  final bool cancelled; // user dismissed before any change

  const CoverPhotoOutcome._({
    required this.success,
    required this.newCoverUrl,
    required this.removed,
    required this.errorMessage,
    required this.cancelled,
  });

  factory CoverPhotoOutcome.cancelled() => const CoverPhotoOutcome._(
        success: false,
        newCoverUrl: null,
        removed: false,
        errorMessage: null,
        cancelled: true,
      );

  factory CoverPhotoOutcome.uploaded(String url) => CoverPhotoOutcome._(
        success: true,
        newCoverUrl: url,
        removed: false,
        errorMessage: null,
        cancelled: false,
      );

  factory CoverPhotoOutcome.removed() => const CoverPhotoOutcome._(
        success: true,
        newCoverUrl: null,
        removed: true,
        errorMessage: null,
        cancelled: false,
      );

  factory CoverPhotoOutcome.failed(String message) => CoverPhotoOutcome._(
        success: false,
        newCoverUrl: null,
        removed: false,
        errorMessage: message,
        cancelled: false,
      );
}

/// Lives for one user-initiated cover-photo flow. Construct, call [run],
/// observe the [stateListenable] / [progressListenable] from the calling
/// widget to drive the inline overlay, and dispose when done.
class CoverPhotoOrchestrator {
  final ProfileService profileService;

  /// 0.0..1.0 upload fraction. Updated by Dio onSendProgress.
  final ValueNotifier<double> progressListenable = ValueNotifier(0);

  /// "uploading" while a request is in flight, "idle" otherwise. The
  /// caller may wrap this in their own state for "error".
  final ValueNotifier<CoverUploadPhase> phaseListenable =
      ValueNotifier(CoverUploadPhase.idle);

  CancelToken? _cancelToken;
  bool _disposed = false;

  CoverPhotoOrchestrator({required this.profileService});

  void cancel() {
    _cancelToken?.cancel('user_cancelled');
  }

  void dispose() {
    _disposed = true;
    progressListenable.dispose();
    phaseListenable.dispose();
  }

  /// Drive the full flow. Returns when the user has either committed
  /// (success) or cancelled (cancelled), or after a non-recoverable error.
  Future<CoverPhotoOutcome> run({
    required BuildContext context,
    required int userId,
    required String? currentCoverUrl,
    required String? avatarUrl,
    required String? avatarInitials,
    required String? fullName,
    required String? username,
  }) async {
    final action = await CoverPhotoActionsSheet.show(
      context,
      hasExistingCover: currentCoverUrl != null && currentCoverUrl.isNotEmpty,
    );
    if (!context.mounted) return CoverPhotoOutcome.cancelled();
    if (action == null) return CoverPhotoOutcome.cancelled();

    if (action == CoverPhotoAction.remove) {
      return _remove(userId);
    }

    final source = action == CoverPhotoAction.camera
        ? ImageSource.camera
        : ImageSource.gallery;
    final picker = ImagePicker();
    final XFile? raw = await picker.pickImage(
      source: source,
      preferredCameraDevice: CameraDevice.rear,
      // No maxWidth/maxHeight — cropper sees the full source for best quality.
    );
    if (!context.mounted) return CoverPhotoOutcome.cancelled();
    if (raw == null) return CoverPhotoOutcome.cancelled();

    final originalFile = File(raw.path);
    return _enterCropPreviewLoop(
      context: context,
      userId: userId,
      original: originalFile,
      avatarUrl: avatarUrl,
      avatarInitials: avatarInitials,
      fullName: fullName,
      username: username,
    );
  }

  Future<CoverPhotoOutcome> _enterCropPreviewLoop({
    required BuildContext context,
    required int userId,
    required File original,
    required String? avatarUrl,
    required String? avatarInitials,
    required String? fullName,
    required String? username,
  }) async {
    while (true) {
      final cropped = await cropForCover(context, original);
      if (!context.mounted) return CoverPhotoOutcome.cancelled();
      if (cropped == null) return CoverPhotoOutcome.cancelled();

      // Custom 220ms fade transition feels lighter than the default
      // platform slide for a brief preview-then-confirm flow.
      final saveDecision = await Navigator.of(context).push<bool?>(
        PageRouteBuilder<bool?>(
          transitionDuration: const Duration(milliseconds: 220),
          reverseTransitionDuration: const Duration(milliseconds: 180),
          opaque: true,
          pageBuilder: (_, _, _) => CoverPreviewScreen(
            croppedImage: cropped,
            avatarUrl: avatarUrl,
            avatarInitials: avatarInitials,
            fullName: fullName,
            username: username,
          ),
          transitionsBuilder: (_, animation, _, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        ),
      );
      if (!context.mounted) return CoverPhotoOutcome.cancelled();

      if (saveDecision == null) return CoverPhotoOutcome.cancelled();
      if (saveDecision == false) {
        // "Crop again" — back to the cropper with the same source.
        continue;
      }
      // Save tapped.
      return _compressAndUpload(userId: userId, cropped: cropped);
    }
  }

  /// Last successfully-compressed file. Exposed so the host widget can
  /// reuse it on retry (avoiding re-crop/re-compress).
  File? lastCompressedFile;

  Future<CoverPhotoOutcome> _compressAndUpload({
    required int userId,
    required File cropped,
  }) async {
    final compressed = await _compress(cropped);
    if (compressed == null) {
      return CoverPhotoOutcome.failed('Failed to compress image');
    }
    lastCompressedFile = compressed;
    return _upload(userId: userId, file: compressed);
  }

  Future<File?> _compress(File source) async {
    try {
      final dir = await getTemporaryDirectory();
      final target =
          '${dir.path}/cover_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final result = await FlutterImageCompress.compressAndGetFile(
        source.path,
        target,
        format: CompressFormat.jpeg,
        quality: 82,
        minWidth: 2048,
        minHeight: 1152,
        autoCorrectionAngle: true,
        keepExif: false,
      );
      if (result == null) return null;
      return File(result.path);
    } catch (_) {
      return null;
    }
  }

  /// Public so the caller can re-trigger upload from the inline retry button
  /// without forcing the user to re-crop.
  Future<CoverPhotoOutcome> retryUpload({
    required int userId,
    required File compressedFile,
  }) {
    return _upload(userId: userId, file: compressedFile);
  }

  Future<CoverPhotoOutcome> _upload({
    required int userId,
    required File file,
  }) async {
    if (_disposed) return CoverPhotoOutcome.cancelled();
    progressListenable.value = 0;
    phaseListenable.value = CoverUploadPhase.uploading;
    _cancelToken = CancelToken();

    final result = await profileService.updateCoverPhoto(
      userId: userId,
      photo: file,
      cancelToken: _cancelToken,
      onProgress: (p) {
        if (!_disposed) progressListenable.value = p;
      },
    );

    if (_disposed) return CoverPhotoOutcome.cancelled();
    phaseListenable.value = CoverUploadPhase.idle;

    if (result.success) {
      return CoverPhotoOutcome.uploaded(result.photoUrl ?? '');
    }
    if (result.message == 'cancelled') {
      return CoverPhotoOutcome.cancelled();
    }
    return CoverPhotoOutcome.failed(result.message ?? 'Upload failed');
  }

  Future<CoverPhotoOutcome> _remove(int userId) async {
    final result = await profileService.removeCoverPhoto(userId: userId);
    if (result.success) return CoverPhotoOutcome.removed();
    return CoverPhotoOutcome.failed(result.message ?? 'Failed to remove cover photo');
  }
}

/// Public phase for [CoverPhotoOrchestrator.phaseListenable] consumers.
enum CoverUploadPhase { idle, uploading }
