// Phase-1 virtual hair try-on: front camera + ML Kit face bbox + drawable "hair cap" overlays.
// Shared by Hair & Nails home (embedded) and full-screen try-on page.
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/app_strings_scope.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

/// Number of drawable hair styles (silhouettes above face bbox).
const int kHairTryOnStyleCount = 8;

/// English hair style names.
const List<String> kHairStyleNames = [
  'Short Afro',
  'Long Braids',
  'Bob Cut',
  'High Bun',
  'Cornrows',
  'Locs',
  'Bantu Knots',
  'Twist Out',
];

/// Swahili hair style names.
const List<String> kHairStyleNamesSw = [
  'Afro Fupi',
  'Misuko Mirefu',
  'Bob',
  'Bun ya Juu',
  'Cornrows',
  'Locs/Dread',
  'Bantu Knots',
  'Twist Out',
];

enum HairTryOnViewportMode { embedded, fullscreen }

/// Camera + face bbox + hair overlay. [embeddedHeight] applies when [mode] is [embedded].
class HairTryOnViewport extends StatefulWidget {
  final int userId;
  final HairTryOnViewportMode mode;
  final double embeddedHeight;

  const HairTryOnViewport({
    super.key,
    required this.userId,
    this.mode = HairTryOnViewportMode.fullscreen,
    this.embeddedHeight = 420,
  });

  @override
  State<HairTryOnViewport> createState() => _HairTryOnViewportState();
}

class _HairTryOnViewportState extends State<HairTryOnViewport>
    with SingleTickerProviderStateMixin {
  CameraController? _controller;
  FaceDetector? _faceDetector;
  List<CameraDescription>? _cameras;

  Face? _detectedFace;
  Rect? _faceRectInPreview;
  Size _imageSize = Size.zero;
  Size _previewLayoutSize = Size.zero;
  bool _isInitializing = true;
  String? _initError;
  int _frameTick = 0;
  bool _processing = false;
  bool _isCapturing = false;

  int _styleIndex = 0;
  int _colorIndex = 0;

  /// Whether a face was just detected (for green check animation).
  bool _faceJustDetected = false;
  Timer? _faceDetectedTimer;

  final GlobalKey _captureKey = GlobalKey();

  late AnimationController _faceCheckAnimCtrl;
  late Animation<double> _faceCheckAnim;

  static const List<Color> _hairColorChoices = [
    Color(0xFF0A0A0A), // Jet Black
    Color(0xFF3E2723), // Dark Brown
    Color(0xFF5D4037), // Medium Brown
    Color(0xFF8D6E63), // Light Brown
    Color(0xFF8B4513), // Auburn/Red
    Color(0xFFC8A951), // Blonde
    Color(0xFF800020), // Burgundy
    Color(0xFF9E9E9E), // Grey
  ];

  @override
  void initState() {
    super.initState();
    _faceCheckAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _faceCheckAnim = CurvedAnimation(
      parent: _faceCheckAnimCtrl,
      curve: Curves.easeOut,
    );
    _faceDetector = GoogleMlKit.vision.faceDetector(
      FaceDetectorOptions(
        enableLandmarks: true,
        enableContours: true,
        enableClassification: true,
        performanceMode: FaceDetectorMode.fast,
        minFaceSize: 0.15,
      ),
    );
    _initCamera();
  }

  Future<void> _initCamera() async {
    final ok = await _ensureCameraPermission();
    if (!ok) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _initError = 'camera_permission';
        });
      }
      return;
    }
    try {
      _cameras = await availableCameras();
      CameraDescription front = _cameras!.first;
      for (final c in _cameras!) {
        if (c.lensDirection == CameraLensDirection.front) {
          front = c;
          break;
        }
      }

      final ctrl = CameraController(
        front,
        ResolutionPreset.low, // Low res reduces memory pressure from ML Kit face detection
        enableAudio: false,
        imageFormatGroup: Platform.isIOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.nv21,
      );
      await ctrl.initialize();
      if (!mounted) return;
      setState(() {
        _controller = ctrl;
        _isInitializing = false;
      });
      await ctrl.startImageStream(_onCameraImage);
    } catch (e) {
      if (kDebugMode) debugPrint('[HairTryOnViewport] init error: $e');
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _initError = e.toString();
        });
      }
    }
  }

  Future<bool> _ensureCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) return false;
    final result = await Permission.camera.request();
    return result.isGranted;
  }

  InputImage? _buildInputImage(CameraImage image, CameraController ctrl) {
    final sensor = ctrl.description.sensorOrientation;
    final rotation = _rotationFromDegrees(sensor);

    // On Android, the actual image format may differ from what was requested.
    // ML Kit on Android works best with NV21 (single plane) format.
    // Detect real format from plane count and raw format code.
    final InputImageFormat mlFormat;
    final Uint8List bytes;
    final int bytesPerRow;

    if (Platform.isIOS) {
      // iOS always gives BGRA8888 when requested
      mlFormat = InputImageFormat.bgra8888;
      bytes = image.planes[0].bytes;
      bytesPerRow = image.planes[0].bytesPerRow;
    } else {
      // Android: try NV21 first (most compatible with ML Kit)
      if (image.planes.length == 1) {
        // Single plane = NV21 or similar packed format
        mlFormat = InputImageFormat.nv21;
        bytes = image.planes[0].bytes;
        bytesPerRow = image.planes[0].bytesPerRow;
      } else if (image.planes.length == 2) {
        // 2 planes: Y + interleaved UV (NV21/NV12 style)
        // Concatenate planes for NV21 format
        final wb = WriteBuffer();
        for (final p in image.planes) {
          wb.putUint8List(p.bytes);
        }
        bytes = wb.done().buffer.asUint8List();
        bytesPerRow = image.planes[0].bytesPerRow;
        mlFormat = InputImageFormat.nv21;
      } else {
        // 3 planes: Y + U + V (YUV420 planar)
        // Concatenate into NV21 layout: Y plane + interleaved VU
        final yPlane = image.planes[0];
        final uPlane = image.planes[1];
        final vPlane = image.planes[2];
        final ySize = yPlane.bytes.length;
        final uvSize = uPlane.bytes.length + vPlane.bytes.length;
        final nv21 = Uint8List(ySize + uvSize);
        // Copy Y plane
        nv21.setRange(0, ySize, yPlane.bytes);
        // Interleave V and U (NV21 = VUVU...)
        int offset = ySize;
        final uvLen = math.min(vPlane.bytes.length, uPlane.bytes.length);
        for (int i = 0; i < uvLen; i++) {
          nv21[offset++] = vPlane.bytes[i];
          nv21[offset++] = uPlane.bytes[i];
        }
        bytes = nv21;
        bytesPerRow = yPlane.bytesPerRow;
        mlFormat = InputImageFormat.nv21;
      }
    }

    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: mlFormat,
      bytesPerRow: bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  InputImageRotation _rotationFromDegrees(int degrees) {
    final d = degrees % 360;
    if (d <= 45 || d > 315) return InputImageRotation.rotation0deg;
    if (d <= 135) return InputImageRotation.rotation90deg;
    if (d <= 225) return InputImageRotation.rotation180deg;
    return InputImageRotation.rotation270deg;
  }

  Future<void> _onCameraImage(CameraImage image) async {
    final ctrl = _controller;
    final detector = _faceDetector;
    if (ctrl == null || !ctrl.value.isInitialized || detector == null) return;

    _frameTick++;
    if (_frameTick % 10 != 0) return; // Process every 10th frame (~3fps) to reduce CPU/memory pressure
    if (_processing) return;
    _processing = true;

    try {
      final input = _buildInputImage(image, ctrl);
      if (input == null) return;

      final faces = await detector.processImage(input);
      if (!mounted) return;

      _imageSize = Size(image.width.toDouble(), image.height.toDouble());

      if (faces.isEmpty) {
        if (mounted && _faceRectInPreview != null) {
          setState(() {
            _detectedFace = null;
            _faceRectInPreview = null;
            _faceJustDetected = false;
          });
        }
        return;
      }

      final face = faces.first;
      final bbox = face.boundingBox;
      final isFront = ctrl.description.lensDirection == CameraLensDirection.front;
      final previewRect = _mapImageRectToPreview(
        bbox,
        _previewLayoutSize,
        _imageSize,
        isFront,
      );
      if (!mounted) return;
      final wasNull = _faceRectInPreview == null;
      if (_rectChanged(_faceRectInPreview, previewRect)) {
        setState(() {
          _detectedFace = face;
          _faceRectInPreview = previewRect;
        });
      }
      // Brief green check animation on first detection.
      if (wasNull && _faceRectInPreview != null && !_faceJustDetected) {
        setState(() => _faceJustDetected = true);
        _faceCheckAnimCtrl.forward(from: 0);
        _faceDetectedTimer?.cancel();
        _faceDetectedTimer = Timer(const Duration(milliseconds: 1200), () {
          if (mounted) setState(() => _faceJustDetected = false);
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[HairTryOnViewport] process: $e');
    } finally {
      _processing = false;
    }
  }

  bool _rectChanged(Rect? a, Rect b) {
    if (a == null) return true;
    return (a.center - b.center).distance > 6 ||
        (a.width - b.width).abs() > 8 ||
        (a.height - b.height).abs() > 8;
  }

  Rect _mapImageRectToPreview(
      Rect imageRect, Size previewSize, Size imageSize, bool mirror) {
    if (previewSize.width <= 0 ||
        previewSize.height <= 0 ||
        imageSize.width <= 0 ||
        imageSize.height <= 0) {
      return imageRect;
    }

    // Camera sensor is typically landscape; if the image is wider than tall
    // but the preview is portrait, swap the image dimensions to match the
    // rotated preview that FittedBox displays.
    Size effectiveImageSize = imageSize;
    if ((imageSize.width > imageSize.height) != (previewSize.width > previewSize.height)) {
      effectiveImageSize = Size(imageSize.height, imageSize.width);
    }

    // Cover-fit scale (same as FittedBox.cover)
    final scale = math.max(
      previewSize.width / effectiveImageSize.width,
      previewSize.height / effectiveImageSize.height,
    );
    final scaledW = effectiveImageSize.width * scale;
    final scaledH = effectiveImageSize.height * scale;
    final dx = (previewSize.width - scaledW) / 2;
    final dy = (previewSize.height - scaledH) / 2;

    // Map face rect through the same transformation
    // If we swapped dimensions, we also need to swap the rect coordinates
    Rect mappedRect;
    if (effectiveImageSize != imageSize) {
      // Rotated: swap x/y of the rect relative to the original image
      mappedRect = Rect.fromLTRB(
        imageRect.top, imageRect.left,
        imageRect.bottom, imageRect.right,
      );
    } else {
      mappedRect = imageRect;
    }

    // Scale factor relative to the effective (possibly swapped) image size
    final sx = scaledW / effectiveImageSize.width;
    final sy = scaledH / effectiveImageSize.height;

    var left = mappedRect.left * sx + dx;
    var top = mappedRect.top * sy + dy;
    var right = mappedRect.right * sx + dx;
    var bottom = mappedRect.bottom * sy + dy;

    if (mirror) {
      final w = right - left;
      left = previewSize.width - right;
      right = left + w;
    }

    return Rect.fromLTRB(left, top, right, bottom);
  }

  Future<void> _disposeCamera() async {
    final c = _controller;
    if (c != null) {
      if (c.value.isStreamingImages) {
        await c.stopImageStream();
      }
      await c.dispose();
    }
    _controller = null;
  }

  @override
  void dispose() {
    _faceDetectedTimer?.cancel();
    _faceCheckAnimCtrl.dispose();
    _disposeCamera();
    _faceDetector?.close();
    _faceDetector = null;
    super.dispose();
  }

  void _cycleStyle(int delta) {
    setState(() {
      var n = (_styleIndex + delta) % kHairTryOnStyleCount;
      if (n < 0) n += kHairTryOnStyleCount;
      _styleIndex = n;
    });
  }

  Future<void> _shareLook() async {
    final s = AppStringsScope.of(context)!;
    await SharePlus.instance.share(
      ShareParams(
        text: s.hairNailsSendLookBody,
        subject: s.hairNailsVirtualTryOnTitle,
      ),
    );
  }

  Future<void> _captureAndShare() async {
    final s = AppStringsScope.of(context)!;
    if (_isCapturing) return;
    setState(() => _isCapturing = true);

    try {
      final boundary = _captureKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s.hairNailsCaptureError)),
          );
        }
        return;
      }

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s.hairNailsCaptureError)),
          );
        }
        return;
      }

      final pngBytes = byteData.buffer.asUint8List();

      // Write to temp file for sharing.
      final tempDir = Directory.systemTemp;
      final file = File(
          '${tempDir.path}/tajiri_hair_tryon_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);

      if (!mounted) return;

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: s.hairNailsSendLookBody,
          subject: s.hairNailsVirtualTryOnTitle,
        ),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[HairTryOnViewport] capture error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.hairNailsCaptureError)),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  String _styleName(AppStrings s, int index) {
    final names = s.isSwahili ? kHairStyleNamesSw : kHairStyleNames;
    if (index >= 0 && index < names.length) return names[index];
    return '${index + 1}';
  }

  Widget _buildCameraStack(AppStrings s) {
    if (_isInitializing) {
      return const Center(
          child:
              CircularProgressIndicator(strokeWidth: 2, color: Colors.white));
    }
    if (_initError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _initError == 'camera_permission'
                ? s.hairNailsVirtualTryOnNoCamera
                : s.hairNailsVirtualTryOnInitError,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }
    if (_controller == null) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        _previewLayoutSize = constraints.biggest;
        return RepaintBoundary(
          key: _captureKey,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Preserve camera aspect ratio — cover the frame without squashing
              SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: _controller!.value.previewSize?.height ?? constraints.maxWidth,
                    height: _controller!.value.previewSize?.width ?? constraints.maxHeight,
                    child: CameraPreview(_controller!),
                  ),
                ),
              ),
              CustomPaint(
                painter: HairTryOnPainter(
                  faceRect: _faceRectInPreview,
                  styleIndex: _styleIndex,
                  tint: _hairColorChoices[
                      _colorIndex % _hairColorChoices.length],
                  face: _detectedFace,
                  previewSize: _previewLayoutSize,
                  imageSize: _imageSize,
                  isFrontCamera: _controller?.description.lensDirection ==
                      CameraLensDirection.front,
                ),
              ),
              // Face guide oval when no face detected.
              if (_faceRectInPreview == null)
                Center(
                  child: CustomPaint(
                    painter: _FaceGuidePainter(),
                    size: Size(
                      constraints.maxWidth * 0.45,
                      constraints.maxHeight * 0.55,
                    ),
                  ),
                ),
              // "Position your face" text when no face.
              if (_faceRectInPreview == null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: widget.mode == HairTryOnViewportMode.embedded
                      ? 56
                      : 72,
                  child: Text(
                    s.hairNailsVirtualTryOnSeekFace,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                      shadows: const [
                        Shadow(blurRadius: 8, color: Colors.black54)
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              // Green check animation on face detection.
              if (_faceJustDetected)
                Center(
                  child: FadeTransition(
                    opacity: _faceCheckAnim,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 32),
                    ),
                  ),
                ),
              // Left arrow.
              Positioned(
                left: 4,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Material(
                    color: Colors.black38,
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(Icons.chevron_left_rounded,
                          color: Colors.white, size: 32),
                      onPressed: () => _cycleStyle(-1),
                      tooltip: s.hairNailsVirtualTryOnSwipeStyles,
                    ),
                  ),
                ),
              ),
              // Right arrow.
              Positioned(
                right: 4,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Material(
                    color: Colors.black38,
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(Icons.chevron_right_rounded,
                          color: Colors.white, size: 32),
                      onPressed: () => _cycleStyle(1),
                      tooltip: s.hairNailsVirtualTryOnSwipeStyles,
                    ),
                  ),
                ),
              ),
              // Bottom buttons row: Share text + Capture image.
              Positioned(
                left: 0,
                right: 0,
                bottom: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: _shareLook,
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: Text(s.hairNailsSendLook,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      style: FilledButton.styleFrom(
                        backgroundColor: _kPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                        minimumSize: const Size(48, 48),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _isCapturing ? null : _captureAndShare,
                      icon: _isCapturing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.camera_alt_rounded, size: 16),
                      label: Text(
                          _isCapturing
                              ? (s.hairNailsCaptureSaving)
                              : s.hairNailsCaptureSave,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white24,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                        minimumSize: const Size(48, 48),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _colorChips({required bool compact}) {
    final pad = compact
        ? const EdgeInsets.only(top: 8)
        : const EdgeInsets.symmetric(horizontal: 16);
    return Padding(
      padding: pad,
      child: Wrap(
        spacing: compact ? 6 : 8,
        runSpacing: compact ? 6 : 8,
        alignment: WrapAlignment.center,
        children: List.generate(_hairColorChoices.length, (i) {
          final c = _hairColorChoices[i];
          final on = i == _colorIndex % _hairColorChoices.length;
          final size = compact ? 32.0 : 40.0;
          return GestureDetector(
            onTap: () => setState(() => _colorIndex = i),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(
                    color: on ? Colors.white : Colors.transparent, width: 2.5),
                boxShadow: on
                    ? [
                        BoxShadow(
                            color: c.withValues(alpha: 0.4),
                            blurRadius: 6,
                            spreadRadius: 1)
                      ]
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _styleNumberRow(AppStrings s) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: kHairTryOnStyleCount,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final selected = i == _styleIndex;
          return Material(
            color: selected
                ? _kPrimary.withValues(alpha: 0.12)
                : _kCardBg,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => setState(() => _styleIndex = i),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Text(
                  _styleName(s, i),
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: _kPrimary,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context)!;

    final cameraFrame = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: ColoredBox(
        color: Colors.black,
        child: widget.mode == HairTryOnViewportMode.embedded
            ? SizedBox(
                height: widget.embeddedHeight, child: _buildCameraStack(s))
            : _buildCameraStack(s),
      ),
    );

    if (widget.mode == HairTryOnViewportMode.embedded) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          cameraFrame,
          _colorChips(compact: true),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: cameraFrame)),
        const SizedBox(height: 12),
        Text(
          s.hairNailsVirtualTryOnSwipeStyles,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: _kSecondary),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        _styleNumberRow(s),
        const SizedBox(height: 8),
        _colorChips(compact: false),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Face guide painter — subtle oval outline when no face detected.
// ---------------------------------------------------------------------------
class _FaceGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawOval(rect, paint);

    // Small crosshair at center.
    final cx = size.width / 2;
    final cy = size.height / 2;
    final cross = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(cx - 10, cy), Offset(cx + 10, cy), cross);
    canvas.drawLine(Offset(cx, cy - 10), Offset(cx, cy + 10), cross);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Hair overlay painter — realistic silhouette paths.
// ---------------------------------------------------------------------------

/// Draws a semi-transparent "hair" silhouette above [faceRect].
class HairTryOnPainter extends CustomPainter {
  HairTryOnPainter({
    required this.faceRect,
    required this.styleIndex,
    required this.tint,
    this.face,
    this.previewSize = Size.zero,
    this.imageSize = Size.zero,
    this.isFrontCamera = true,
  });

  final Rect? faceRect;
  final int styleIndex;
  final Color tint;

  /// Full ML Kit Face object with landmarks/contours (for future landmark painter).
  final Face? face;

  /// Current preview widget size (for coordinate mapping).
  final Size previewSize;

  /// Camera image size (for coordinate mapping).
  final Size imageSize;

  /// Whether the active camera is front-facing (for mirroring).
  final bool isFrontCamera;

  @override
  void paint(Canvas canvas, Size size) {
    final face = faceRect;
    if (face == null) return;

    // Shrink the face rect to just the hair zone (top 40% of face, slightly wider)
    // This prevents hair overlays from covering the entire face
    final hairZone = Rect.fromLTWH(
      face.left - face.width * 0.05,  // slightly wider than face
      face.top - face.height * 0.15,   // start above forehead
      face.width * 1.1,
      face.height * 0.45,              // only top portion
    );

    final path = _hairPathForStyle(styleIndex, hairZone);

    // Shadow layer.
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(path.shift(const Offset(0, 3)), shadowPaint);

    // Gradient fill for realistic depth.
    final bounds = path.getBounds();
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        tint.withValues(alpha: 0.35),
        tint.withValues(alpha: 0.50),
        tint.withValues(alpha: 0.35),
      ],
      stops: const [0.0, 0.4, 1.0],
    );

    final fillPaint = Paint()
      ..shader = gradient.createShader(bounds)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawPath(path, fillPaint);

    // Edge highlight for depth.
    final edgePaint = Paint()
      ..color = tint.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..isAntiAlias = true;
    canvas.drawPath(path, edgePaint);
  }

  Path _hairPathForStyle(int style, Rect face) {
    switch (style % kHairTryOnStyleCount) {
      case 0:
        return _shortAfro(face);
      case 1:
        return _longBraids(face);
      case 2:
        return _bobCut(face);
      case 3:
        return _highBun(face);
      case 4:
        return _cornrows(face);
      case 5:
        return _locs(face);
      case 6:
        return _bantuKnots(face);
      case 7:
        return _twistOut(face);
      default:
        return _shortAfro(face);
    }
  }

  // ---- Style 0: Short Afro ----
  // Round, full shape wider than face with textured bumpy edge.
  Path _shortAfro(Rect face) {
    final cx = face.center.dx;
    final cy = face.top;
    final w = face.width * 0.75;
    final h = face.height * 0.65;

    final path = Path();
    const segments = 32;
    final rng = math.Random(42); // Deterministic bumps.

    for (var i = 0; i <= segments; i++) {
      // Full circle — afro surrounds the top of the head.
      final fullAngle = -math.pi / 2 + (2 * math.pi * i / segments);
      final bump = 1.0 + (rng.nextDouble() * 0.08 - 0.02); // Small texture bumps.
      final rx = w * bump;
      final ry = h * bump;
      final x = cx + rx * math.cos(fullAngle);
      final y = (cy - h * 0.15) + ry * math.sin(fullAngle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  // ---- Style 1: Long Braids ----
  // Multiple braid strands falling from the scalp down both sides.
  Path _longBraids(Rect face) {
    final path = Path();
    final cx = face.center.dx;
    final topY = face.top - face.height * 0.25;
    final w = face.width;

    // Scalp cap (top of head).
    path.addArc(
      Rect.fromCenter(
          center: Offset(cx, topY), width: w * 1.1, height: face.height * 0.5),
      math.pi,
      math.pi,
    );

    // Individual braids — 8 strands.
    const braidCount = 8;
    final braidWidth = w * 0.07;
    final bottomExtend = face.height * 1.1; // Braids extend below face.

    for (var i = 0; i < braidCount; i++) {
      final t = i / (braidCount - 1); // 0..1
      final startX = cx - w * 0.5 + w * t;
      // Braids spread outward as they go down.
      final spread = (t - 0.5) * w * 0.4;
      final endX = startX + spread;
      final startY = topY + face.height * 0.1;
      final endY = face.bottom + bottomExtend * (0.6 + t * 0.3);

      final braid = Path();
      braid.moveTo(startX - braidWidth, startY);

      // Wavy braid shape with slight zigzag.
      final midY1 = startY + (endY - startY) * 0.33;
      final midY2 = startY + (endY - startY) * 0.66;
      final wave = braidWidth * 1.5;

      braid.cubicTo(
        startX - braidWidth + wave, midY1,
        endX - braidWidth - wave, midY2,
        endX - braidWidth, endY,
      );
      // Rounded tip.
      braid.quadraticBezierTo(
          endX, endY + braidWidth * 2, endX + braidWidth, endY);
      braid.cubicTo(
        endX + braidWidth + wave, midY2,
        startX + braidWidth - wave, midY1,
        startX + braidWidth, startY,
      );
      braid.close();
      path.addPath(braid, Offset.zero);
    }

    return path;
  }

  // ---- Style 2: Bob Cut ----
  // Chin-length, angled, smooth curves framing the face.
  Path _bobCut(Rect face) {
    final cx = face.center.dx;
    final w = face.width * 0.72;
    final topY = face.top - face.height * 0.35;
    final bottomY = face.bottom + face.height * 0.05; // Just past chin.

    final path = Path();
    // Start at top center.
    path.moveTo(cx, topY);

    // Right side: smooth curve from top to chin.
    path.cubicTo(
      cx + w * 0.8, topY - face.height * 0.05, // Control 1: flares out.
      cx + w * 0.95, face.top + face.height * 0.2, // Control 2.
      cx + w * 0.7, bottomY, // End: right chin area (angled shorter).
    );

    // Bottom right to bottom center curve (slight inward tuck).
    path.quadraticBezierTo(
      cx + w * 0.2, bottomY + face.height * 0.04,
      cx, bottomY - face.height * 0.02,
    );

    // Bottom center to bottom left.
    path.quadraticBezierTo(
      cx - w * 0.2, bottomY + face.height * 0.06,
      cx - w * 0.75, bottomY + face.height * 0.03, // Left side slightly longer.
    );

    // Left side: smooth curve back up to top.
    path.cubicTo(
      cx - w * 0.98, face.top + face.height * 0.15,
      cx - w * 0.85, topY - face.height * 0.08,
      cx, topY,
    );

    path.close();
    return path;
  }

  // ---- Style 3: High Bun ----
  // Large circular bun on top of head with a connecting base.
  Path _highBun(Rect face) {
    final cx = face.center.dx;
    final topY = face.top - face.height * 0.3;
    final bunRadius = face.width * 0.32;
    final bunCenterY = topY - bunRadius * 1.1;

    final path = Path();

    // Bun circle.
    path.addOval(Rect.fromCenter(
      center: Offset(cx, bunCenterY),
      width: bunRadius * 2,
      height: bunRadius * 2.1,
    ));

    // Base / hair wrap connecting bun to scalp.
    final basePath = Path();
    basePath.moveTo(cx - bunRadius * 0.7, bunCenterY + bunRadius * 0.6);
    basePath.quadraticBezierTo(
        cx - face.width * 0.35, topY + face.height * 0.05,
        cx - face.width * 0.4, topY + face.height * 0.15);
    basePath.lineTo(cx + face.width * 0.4, topY + face.height * 0.15);
    basePath.quadraticBezierTo(
        cx + face.width * 0.35, topY + face.height * 0.05,
        cx + bunRadius * 0.7, bunCenterY + bunRadius * 0.6);
    basePath.close();

    path.addPath(basePath, Offset.zero);

    // Flat cap on top of head.
    path.addArc(
      Rect.fromCenter(
          center: Offset(cx, topY + face.height * 0.05),
          width: face.width * 0.9,
          height: face.height * 0.25),
      math.pi,
      math.pi,
    );

    return path;
  }

  // ---- Style 4: Cornrows ----
  // Parallel curved lines running from forehead to back.
  Path _cornrows(Rect face) {
    final path = Path();
    final cx = face.center.dx;
    final w = face.width;
    final topY = face.top - face.height * 0.3;
    final backY = face.top + face.height * 0.05; // Rows end at top of head.

    // Scalp base shape.
    path.addArc(
      Rect.fromCenter(
          center: Offset(cx, topY + face.height * 0.15),
          width: w * 1.15,
          height: face.height * 0.55),
      math.pi,
      math.pi,
    );

    // 7 cornrow lines.
    const rowCount = 7;
    final rowWidth = w * 0.08;

    for (var i = 0; i < rowCount; i++) {
      final t = (i + 1) / (rowCount + 1);
      final startX = cx - w * 0.5 + w * t;
      final endX = startX + (startX - cx) * 0.15; // Slight convergence to back.

      final row = Path();
      row.moveTo(startX - rowWidth / 2, topY);

      // Each row is a slightly curved stripe.
      row.quadraticBezierTo(
        startX - rowWidth / 2 + (endX - startX) * 0.5,
        topY + (backY - topY) * 0.5,
        endX - rowWidth / 2,
        backY,
      );
      row.lineTo(endX + rowWidth / 2, backY);
      row.quadraticBezierTo(
        startX + rowWidth / 2 + (endX - startX) * 0.5,
        topY + (backY - topY) * 0.5,
        startX + rowWidth / 2,
        topY,
      );
      row.close();
      path.addPath(row, Offset.zero);
    }

    return path;
  }

  // ---- Style 5: Locs/Dreads ----
  // Thick organic strands falling around the face, longer than braids.
  Path _locs(Rect face) {
    final path = Path();
    final cx = face.center.dx;
    final w = face.width;
    final topY = face.top - face.height * 0.25;

    // Scalp cap.
    path.addArc(
      Rect.fromCenter(
          center: Offset(cx, topY), width: w * 1.1, height: face.height * 0.45),
      math.pi,
      math.pi,
    );

    // Locs — thicker and more organic than braids, 7 strands.
    const locCount = 7;
    final locWidth = w * 0.1;
    final rng = math.Random(7);

    for (var i = 0; i < locCount; i++) {
      final t = i / (locCount - 1);
      final startX = cx - w * 0.48 + w * 0.96 * t;
      final spread = (t - 0.5) * w * 0.5;
      final endX = startX + spread;
      final startY = topY + face.height * 0.08;
      // Locs hang longer.
      final endY =
          face.bottom + face.height * (0.8 + rng.nextDouble() * 0.5);

      final loc = Path();
      // Organic wavy shape — each loc slightly different.
      final wave1 = locWidth * (0.8 + rng.nextDouble() * 0.8);
      final wave2 = locWidth * (0.6 + rng.nextDouble() * 0.6);
      final midY1 = startY + (endY - startY) * 0.3;
      final midY2 = startY + (endY - startY) * 0.65;

      loc.moveTo(startX - locWidth, startY);
      loc.cubicTo(
        startX - locWidth + wave1, midY1,
        endX - locWidth - wave2, midY2,
        endX - locWidth * 0.5, endY,
      );
      // Rounded blunt tip.
      loc.arcToPoint(
        Offset(endX + locWidth * 0.5, endY),
        radius: Radius.circular(locWidth * 0.6),
      );
      loc.cubicTo(
        endX + locWidth + wave2, midY2,
        startX + locWidth - wave1, midY1,
        startX + locWidth, startY,
      );
      loc.close();
      path.addPath(loc, Offset.zero);
    }

    return path;
  }

  // ---- Style 6: Bantu Knots ----
  // 5 small circular bumps arranged on top of the head.
  Path _bantuKnots(Rect face) {
    final path = Path();
    final cx = face.center.dx;
    final topY = face.top - face.height * 0.2;
    final knotRadius = face.width * 0.13;

    // Flat scalp base.
    path.addArc(
      Rect.fromCenter(
          center: Offset(cx, topY + face.height * 0.08),
          width: face.width * 1.05,
          height: face.height * 0.32),
      math.pi,
      math.pi,
    );

    // 5 knots arranged in two rows:
    // Top row: 3 knots, bottom row: 2 knots.
    final knots = <Offset>[
      // Top row.
      Offset(cx - face.width * 0.28, topY - knotRadius * 0.7),
      Offset(cx, topY - knotRadius * 1.1),
      Offset(cx + face.width * 0.28, topY - knotRadius * 0.7),
      // Bottom row (between top knots).
      Offset(cx - face.width * 0.14, topY + knotRadius * 0.2),
      Offset(cx + face.width * 0.14, topY + knotRadius * 0.2),
    ];

    for (final center in knots) {
      // Each knot: coiled circle with slight spiral appearance.
      path.addOval(Rect.fromCenter(
        center: center,
        width: knotRadius * 2,
        height: knotRadius * 2.1,
      ));
      // Inner spiral ring for texture.
      path.addOval(Rect.fromCenter(
        center: Offset(center.dx + knotRadius * 0.1, center.dy - knotRadius * 0.1),
        width: knotRadius * 1.0,
        height: knotRadius * 1.1,
      ));
    }

    return path;
  }

  // ---- Style 7: Flat Twist Out ----
  // Wide, voluminous shape expanding outward, textured edges.
  Path _twistOut(Rect face) {
    final cx = face.center.dx;
    final topY = face.top - face.height * 0.45;
    final w = face.width * 0.95; // Very wide.
    final h = face.height * 0.75;

    final path = Path();
    const segments = 40;
    final rng = math.Random(99);

    for (var i = 0; i <= segments; i++) {
      final angle = -math.pi / 2 + (2 * math.pi * i / segments);
      // Bigger bumps than afro — twist texture.
      final bump = 1.0 + (rng.nextDouble() * 0.14 - 0.04);
      final rx = w * bump;
      final ry = h * bump;
      final x = cx + rx * math.cos(angle);
      final y = (topY + h * 0.5) + ry * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        // Alternate between smooth and jagged for twist texture.
        if (i % 3 == 0) {
          final prevAngle = -math.pi / 2 + (2 * math.pi * (i - 1) / segments);
          final ctrlBump = 1.0 + rng.nextDouble() * 0.1;
          final ctrlX = cx + w * ctrlBump * math.cos(prevAngle + 0.05);
          final ctrlY =
              (topY + h * 0.5) + h * ctrlBump * math.sin(prevAngle + 0.05);
          path.quadraticBezierTo(ctrlX, ctrlY, x, y);
        } else {
          path.lineTo(x, y);
        }
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant HairTryOnPainter oldDelegate) =>
      oldDelegate.faceRect != faceRect ||
      oldDelegate.styleIndex != styleIndex ||
      oldDelegate.tint != tint ||
      oldDelegate.face != face ||
      oldDelegate.previewSize != previewSize ||
      oldDelegate.imageSize != imageSize ||
      oldDelegate.isFrontCamera != isFrontCamera;
}
