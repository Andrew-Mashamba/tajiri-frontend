import 'dart:io';
import 'package:image/image.dart' as img;

/// Spec §H.6 — auto-watermarked portfolio cross-post.
///
/// Adds a subtle "TAJIRI" text watermark to partner-uploaded photos
/// before they are sent to the server. The watermark is placed at the
/// bottom-right corner with 30% opacity.
class PhotoWatermarkService {
  static Future<File> addWatermark(File source) async {
    final bytes = await source.readAsBytes();
    var image = img.decodeImage(bytes);
    if (image == null) return source;

    // Scale down very large images for faster processing.
    const maxDimension = 1600;
    if (image.width > maxDimension || image.height > maxDimension) {
      image = img.copyResize(image,
          width: image.width > image.height ? maxDimension : null,
          height: image.height >= image.width ? maxDimension : null);
    }

    final watermarkText = 'TAJIRI';
    final fontSize = (image.width * 0.035).round().clamp(12, 48);

    // Draw a semi-transparent dark strip at the bottom-right.
    final stripW = (fontSize * watermarkText.length * 0.65).round();
    final stripH = fontSize + 8;
    final pad = (image.width * 0.025).round().clamp(8, 24);
    final x = image.width - stripW - pad;
    final y = image.height - stripH - pad;

    // Dark rounded rect background.
    img.fillRect(image,
        x1: x, y1: y,
        x2: x + stripW, y2: y + stripH,
        color: img.ColorRgba8(0, 0, 0, 90));

    // White text.
    img.drawString(image, watermarkText,
        font: img.arial14,
        x: x + (stripW ~/ 2) - ((watermarkText.length * fontSize ~/ 3)),
        y: y + 4,
        color: img.ColorRgba8(255, 255, 255, 200));

    final output = File(source.path.replaceAll(RegExp(r'\.[^.]+$'), '_wm.jpg'));
    await output.writeAsBytes(img.encodeJpg(image, quality: 88));
    return output;
  }
}
