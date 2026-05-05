// ProfilePhotoCropScreen — image_cropper wrapper for avatar (1:1 + circle).
// Spec: docs/superpowers/specs/2026-05-02-profile-photo-upload-design.md §4.1
//
// Output is a square JPEG; the UI shows a circular preview overlay so
// the user sees how the avatar will be displayed in profile chrome.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

import '../../../l10n/app_strings_scope.dart';

/// Open the native cropper for an avatar. Returns the cropped File on
/// success, or null if the user cancels.
Future<File?> cropForAvatar(BuildContext context, File source) async {
  final s = AppStringsScope.of(context);
  final isSw = s?.isSwahili ?? false;
  final title = isSw ? 'Hariri picha ya profaili' : 'Edit profile photo';
  const primary = Color(0xFF1A1A1A);
  const surface = Color(0xFFFAFAFA);

  final result = await ImageCropper().cropImage(
    sourcePath: source.path,
    aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
    compressFormat: ImageCompressFormat.jpg,
    compressQuality: 92, // first pass; final compression handled separately
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: title,
        toolbarColor: primary,
        statusBarLight: false,
        toolbarWidgetColor: surface,
        backgroundColor: surface,
        activeControlsWidgetColor: primary,
        cropFrameColor: surface,
        cropGridColor: surface,
        // Circular preview while cropping; output is still square.
        cropStyle: CropStyle.circle,
        lockAspectRatio: true,
        hideBottomControls: false,
        initAspectRatio: CropAspectRatioPreset.square,
        aspectRatioPresets: const [CropAspectRatioPreset.square],
      ),
      IOSUiSettings(
        title: title,
        // Circular preview overlay; aspect locked at 1:1.
        aspectRatioLockEnabled: true,
        aspectRatioPickerButtonHidden: true,
        resetAspectRatioEnabled: false,
        rotateButtonsHidden: false,
        rotateClockwiseButtonHidden: false,
        cropStyle: CropStyle.circle,
      ),
    ],
  );

  if (result == null) return null;
  return File(result.path);
}
