import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class LivePhotoResult {
  final File stillImage;
  final File? videoComponent;
  final bool isLivePhoto;

  LivePhotoResult({
    required this.stillImage,
    this.videoComponent,
    this.isLivePhoto = false,
  });
}

class LivePhotoService {
  /// Check if a picked image is a Live Photo (iOS) or Motion Photo (Android)
  /// and extract the video component if present.
  static Future<LivePhotoResult> processPickedImage(XFile image) async {
    final file = File(image.path);
    final ext = image.path.toLowerCase();

    if (Platform.isIOS && (ext.endsWith('.heic') || ext.endsWith('.jpg') || ext.endsWith('.jpeg'))) {
      // On iOS, Live Photos are typically picked as HEIC.
      // The MOV companion file may be at the same path with .MOV extension.
      final movPath = image.path.replaceAll(
        RegExp(r'\.(heic|HEIC|jpg|JPG|jpeg|JPEG)$'),
        '.MOV',
      );
      final movFile = File(movPath);
      if (await movFile.exists()) {
        return LivePhotoResult(
          stillImage: file,
          videoComponent: movFile,
          isLivePhoto: true,
        );
      }
      // Also try lowercase .mov
      final movPathLower = image.path.replaceAll(
        RegExp(r'\.(heic|HEIC|jpg|JPG|jpeg|JPEG)$'),
        '.mov',
      );
      if (movPathLower != movPath) {
        final movFileLower = File(movPathLower);
        if (await movFileLower.exists()) {
          return LivePhotoResult(
            stillImage: file,
            videoComponent: movFileLower,
            isLivePhoto: true,
          );
        }
      }
    }

    if (Platform.isAndroid) {
      // Android Motion Photos embed MP4 data at the end of the JPEG.
      // Look for the MP4 header (ftyp box) in the file bytes.
      try {
        final bytes = await file.readAsBytes();
        final videoStart = _findMotionPhotoVideoOffset(bytes);
        if (videoStart != null && videoStart > 0) {
          final videoBytes = bytes.sublist(videoStart);
          final dir = await getTemporaryDirectory();
          final videoFile = File(
            '${dir.path}/motion_${DateTime.now().millisecondsSinceEpoch}.mp4',
          );
          await videoFile.writeAsBytes(videoBytes);

          return LivePhotoResult(
            stillImage: file,
            videoComponent: videoFile,
            isLivePhoto: true,
          );
        }
      } catch (_) {
        // Not a motion photo, return as regular image
      }
    }

    return LivePhotoResult(stillImage: file, isLivePhoto: false);
  }

  /// Find the offset of embedded MP4 video data in an Android Motion Photo.
  /// Looks for 'ftyp' MP4 box signature.
  static int? _findMotionPhotoVideoOffset(Uint8List bytes) {
    // Search for 'ftyp' signature which marks start of MP4 data.
    // The pattern is: 4 bytes (box size) + 'ftyp' (4 bytes).
    const ftyp = [0x66, 0x74, 0x79, 0x70]; // 'ftyp' in ASCII

    // Start searching from the middle of the file (video is at the end)
    final startSearch = bytes.length ~/ 2;

    for (int i = startSearch; i < bytes.length - 8; i++) {
      if (bytes[i + 4] == ftyp[0] &&
          bytes[i + 5] == ftyp[1] &&
          bytes[i + 6] == ftyp[2] &&
          bytes[i + 7] == ftyp[3]) {
        return i;
      }
    }
    return null;
  }
}
