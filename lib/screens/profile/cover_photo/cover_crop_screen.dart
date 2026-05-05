// CoverCropScreen — thin wrapper over `image_cropper` for cover-photo crops.
// Spec: docs/superpowers/specs/2026-05-02-cover-photo-upload-design.md §4.1
//
// Locks the aspect ratio to 16:9, hides aspect-ratio toggle, ships the
// TAJIRI monochrome theme into the native uCrop / TOCropViewController UI.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

import '../../../l10n/app_strings_scope.dart';

/// Open the native cropper. Returns the cropped File on success, or null
/// if the user cancels.
Future<File?> cropForCover(BuildContext context, File source) async {
  final s = AppStringsScope.of(context);
  final isSw = s?.isSwahili ?? false;
  final title = isSw ? 'Hariri picha ya jalada' : 'Edit cover photo';
  const primary = Color(0xFF1A1A1A);
  const surface = Color(0xFFFAFAFA);

  final result = await ImageCropper().cropImage(
    sourcePath: source.path,
    aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 9),
    compressFormat: ImageCompressFormat.jpg,
    compressQuality: 92, // first pass; final compression handled separately
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: title,
        toolbarColor: primary,
        statusBarLight: false, // dark toolbar → use light status bar text
        toolbarWidgetColor: surface,
        backgroundColor: surface,
        activeControlsWidgetColor: primary,
        cropFrameColor: surface,
        cropGridColor: surface,
        lockAspectRatio: true,
        hideBottomControls: false,
        initAspectRatio: CropAspectRatioPreset.ratio16x9,
        aspectRatioPresets: const [CropAspectRatioPreset.ratio16x9],
      ),
      IOSUiSettings(
        title: title,
        // Aspect locked to 16:9 via the parent CropAspectRatio. Don't pass
        // rectX/rectY/rectWidth/rectHeight here — those are in source-pixel
        // space, so e.g. `rectWidth: 16` means a 16-pixel-wide crop frame
        // and forces an enormous zoom to fill the screen.
        aspectRatioLockEnabled: true,
        aspectRatioPickerButtonHidden: true,
        resetAspectRatioEnabled: false,
        rotateButtonsHidden: false,
        rotateClockwiseButtonHidden: false,
      ),
    ],
  );

  if (result == null) return null;
  return File(result.path);
}
