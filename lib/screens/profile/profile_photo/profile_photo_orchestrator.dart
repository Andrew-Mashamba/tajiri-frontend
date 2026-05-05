// ProfilePhotoOrchestrator — drives the avatar upload flow end to end.
// Spec: docs/superpowers/specs/2026-05-02-profile-photo-upload-design.md §3
//
// Mirror of CoverPhotoOrchestrator with avatar-specific tweaks:
//   • Square (1:1) crop with circular preview UI.
//   • Compress to 1024×1024 JPEG q88 (smaller target than cover).
//   • Forwards FaceValidator bbox to the backend's face-embedding pipeline.
//   • Uploads via ProfileService.updateProfilePhoto().
//   • Inline progress is rendered ON THE AVATAR CIRCLE inside CoverCanvas
//     (via isUploadingAvatar = true), not as a full-screen overlay.

import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../services/profile_service.dart';
import 'profile_photo_actions_sheet.dart';
import 'profile_photo_crop_screen.dart';
import 'profile_photo_preview_screen.dart';

/// Outcome of the orchestrator run.
class ProfilePhotoOutcome {
  final bool success;
  final String? newPhotoUrl;
  final bool removed;
  final String? errorMessage;
  final bool cancelled;

  const ProfilePhotoOutcome._({
    required this.success,
    required this.newPhotoUrl,
    required this.removed,
    required this.errorMessage,
    required this.cancelled,
  });

  factory ProfilePhotoOutcome.cancelled() => const ProfilePhotoOutcome._(
        success: false,
        newPhotoUrl: null,
        removed: false,
        errorMessage: null,
        cancelled: true,
      );

  factory ProfilePhotoOutcome.uploaded(String url) => ProfilePhotoOutcome._(
        success: true,
        newPhotoUrl: url,
        removed: false,
        errorMessage: null,
        cancelled: false,
      );

  factory ProfilePhotoOutcome.removed() => const ProfilePhotoOutcome._(
        success: true,
        newPhotoUrl: null,
        removed: true,
        errorMessage: null,
        cancelled: false,
      );

  factory ProfilePhotoOutcome.failed(String message) => ProfilePhotoOutcome._(
        success: false,
        newPhotoUrl: null,
        removed: false,
        errorMessage: message,
        cancelled: false,
      );
}

enum ProfilePhotoUploadPhase { idle, uploading }

class ProfilePhotoOrchestrator {
  final ProfileService profileService;

  final ValueNotifier<double> progressListenable = ValueNotifier(0);
  final ValueNotifier<ProfilePhotoUploadPhase> phaseListenable =
      ValueNotifier(ProfilePhotoUploadPhase.idle);

  /// Last successfully-compressed file. Exposed so the host widget can
  /// retry without re-cropping.
  File? lastCompressedFile;

  CancelToken? _cancelToken;
  bool _disposed = false;

  ProfilePhotoOrchestrator({required this.profileService});

  void cancel() {
    _cancelToken?.cancel('user_cancelled');
  }

  void dispose() {
    _disposed = true;
    progressListenable.dispose();
    phaseListenable.dispose();
  }

  Future<ProfilePhotoOutcome> run({
    required BuildContext context,
    required int userId,
    required String? currentPhotoUrl,
    required String? currentCoverUrl,
    required String? avatarInitials,
    required String? fullName,
    required String? username,
  }) async {
    final action = await ProfilePhotoActionsSheet.show(
      context,
      hasExistingPhoto: currentPhotoUrl != null && currentPhotoUrl.isNotEmpty,
    );
    if (!context.mounted) return ProfilePhotoOutcome.cancelled();
    if (action == null) return ProfilePhotoOutcome.cancelled();

    if (action == ProfilePhotoAction.remove) {
      return _remove(userId);
    }

    final source = action == ProfilePhotoAction.camera
        ? ImageSource.camera
        : ImageSource.gallery;
    final picker = ImagePicker();
    final XFile? raw = await picker.pickImage(
      source: source,
      // Avatars are usually selfies — front camera by default for capture.
      preferredCameraDevice: CameraDevice.front,
    );
    if (!context.mounted) return ProfilePhotoOutcome.cancelled();
    if (raw == null) return ProfilePhotoOutcome.cancelled();

    final originalFile = File(raw.path);
    return _enterCropPreviewLoop(
      context: context,
      userId: userId,
      original: originalFile,
      currentCoverUrl: currentCoverUrl,
      avatarInitials: avatarInitials,
      fullName: fullName,
      username: username,
    );
  }

  Future<ProfilePhotoOutcome> _enterCropPreviewLoop({
    required BuildContext context,
    required int userId,
    required File original,
    required String? currentCoverUrl,
    required String? avatarInitials,
    required String? fullName,
    required String? username,
  }) async {
    while (true) {
      final cropped = await cropForAvatar(context, original);
      if (!context.mounted) return ProfilePhotoOutcome.cancelled();
      if (cropped == null) return ProfilePhotoOutcome.cancelled();

      final decision = await Navigator.of(context).push<ProfilePhotoPreviewDecision?>(
        PageRouteBuilder<ProfilePhotoPreviewDecision?>(
          transitionDuration: const Duration(milliseconds: 220),
          reverseTransitionDuration: const Duration(milliseconds: 180),
          opaque: true,
          pageBuilder: (_, _, _) => ProfilePhotoPreviewScreen(
            croppedAvatar: cropped,
            currentCoverUrl: currentCoverUrl,
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
      if (!context.mounted) return ProfilePhotoOutcome.cancelled();
      if (decision == null || decision.action == 'cancel') {
        return ProfilePhotoOutcome.cancelled();
      }
      if (decision.action == 'crop_again') {
        continue;
      }
      // Save tapped — extract face bbox if FaceValidator found one.
      Map<String, int>? faceBbox;
      final bounds = decision.faceBounds;
      if (bounds != null) {
        faceBbox = {
          'x': bounds.left.round(),
          'y': bounds.top.round(),
          'width': bounds.width.round(),
          'height': bounds.height.round(),
        };
      }
      return _compressAndUpload(
        userId: userId,
        cropped: cropped,
        faceBbox: faceBbox,
      );
    }
  }

  Future<ProfilePhotoOutcome> _compressAndUpload({
    required int userId,
    required File cropped,
    Map<String, int>? faceBbox,
  }) async {
    final compressed = await _compress(cropped);
    if (compressed == null) {
      return ProfilePhotoOutcome.failed('Failed to compress image');
    }
    lastCompressedFile = compressed;
    return _upload(userId: userId, file: compressed, faceBbox: faceBbox);
  }

  Future<File?> _compress(File source) async {
    try {
      final dir = await getTemporaryDirectory();
      final target =
          '${dir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final result = await FlutterImageCompress.compressAndGetFile(
        source.path,
        target,
        format: CompressFormat.jpeg,
        quality: 88,
        minWidth: 1024,
        minHeight: 1024,
        autoCorrectionAngle: true,
        keepExif: false,
      );
      if (result == null) return null;
      return File(result.path);
    } catch (_) {
      return null;
    }
  }

  Future<ProfilePhotoOutcome> retryUpload({
    required int userId,
    required File compressedFile,
    Map<String, int>? faceBbox,
  }) {
    return _upload(userId: userId, file: compressedFile, faceBbox: faceBbox);
  }

  Future<ProfilePhotoOutcome> _upload({
    required int userId,
    required File file,
    Map<String, int>? faceBbox,
  }) async {
    if (_disposed) return ProfilePhotoOutcome.cancelled();
    progressListenable.value = 0;
    phaseListenable.value = ProfilePhotoUploadPhase.uploading;
    _cancelToken = CancelToken();

    final result = await profileService.updateProfilePhoto(
      userId: userId,
      photo: file,
      faceBbox: faceBbox,
      cancelToken: _cancelToken,
      onProgress: (p) {
        if (!_disposed) progressListenable.value = p;
      },
    );

    if (_disposed) return ProfilePhotoOutcome.cancelled();
    phaseListenable.value = ProfilePhotoUploadPhase.idle;

    if (result.success) {
      return ProfilePhotoOutcome.uploaded(result.photoUrl ?? '');
    }
    if (result.message == 'cancelled') {
      return ProfilePhotoOutcome.cancelled();
    }
    return ProfilePhotoOutcome.failed(result.message ?? 'Upload failed');
  }

  Future<ProfilePhotoOutcome> _remove(int userId) async {
    final result = await profileService.removeProfilePhoto(userId: userId);
    if (result.success) return ProfilePhotoOutcome.removed();
    return ProfilePhotoOutcome.failed(result.message ?? 'Failed to remove profile photo');
  }
}
