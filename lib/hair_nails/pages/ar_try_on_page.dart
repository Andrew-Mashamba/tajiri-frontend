// Unified AR try-on page: camera + all 4 filter tiers (color grading,
// beauty smoothing, face overlays, background effects) driven by FilterEngine.

import 'dart:async';
import 'dart:io';
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
import '../models/ar_filter_models.dart';
import '../models/wig_asset.dart';
import '../services/filter_engine.dart';
import '../widgets/face_landmark_painter.dart';
import '../widgets/filter_carousel.dart';
import '../widgets/filter_intensity_slider.dart';
import '../widgets/hair_try_on_viewport.dart';
import '../widgets/wig_overlay_painter.dart';

/// Full-screen AR try-on page combining all 4 filter tiers on a live camera.
class ARTryOnPage extends StatefulWidget {
  final int userId;

  const ARTryOnPage({super.key, required this.userId});

  @override
  State<ARTryOnPage> createState() => _ARTryOnPageState();
}

class _ARTryOnPageState extends State<ARTryOnPage> {
  // ── Camera state ──────────────────────────────────────────────────
  CameraController? _camCtrl;
  bool _isInitializing = true;
  String? _initError;
  bool _isFrontCamera = true;
  int _frameTick = 0;
  bool _processing = false;

  // ── Face detection ────────────────────────────────────────────────
  late FaceDetector _faceDetector;
  Face? _detectedFace;
  Rect? _faceRect;
  Size _imageSize = Size.zero;

  // ── Filter engine ─────────────────────────────────────────────────
  final FilterEngine _engine = FilterEngine();

  // ── Wig image cache ───────────────────────────────────────────────
  final Map<String, ui.Image> _wigImageCache = {};

  // ── Capture ───────────────────────────────────────────────────────
  final GlobalKey _captureKey = GlobalKey();
  bool _isCapturing = false;

  // ── Helpers ───────────────────────────────────────────────────────
  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;
  Size get _previewSize => MediaQuery.of(context).size;

  // ── Lifecycle ─────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _faceDetector = GoogleMlKit.vision.faceDetector(
      FaceDetectorOptions(
        enableContours: true,
        enableLandmarks: true,
        performanceMode: FaceDetectorMode.fast,
        minFaceSize: 0.15,
      ),
    );
    _engine.addListener(_onEngineChanged);
    _initCamera();
  }

  @override
  void dispose() {
    _engine.removeListener(_onEngineChanged);
    _engine.dispose();
    _disposeCamera();
    _faceDetector.close();
    super.dispose();
  }

  // ── Engine change listener ────────────────────────────────────────

  void _onEngineChanged() {
    if (!mounted) return;
    setState(() {});
    final wig = _engine.activeWig;
    if (wig != null && !_wigImageCache.containsKey(wig.id)) {
      _loadWigImage(wig);
    }
  }

  // ── Wig image loading ─────────────────────────────────────────────

  Future<void> _loadWigImage(WigAsset wig) async {
    try {
      final data = await rootBundle.load(wig.assetPath);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
      );
      final frame = await codec.getNextFrame();
      if (!mounted) return;
      setState(() {
        _wigImageCache[wig.id] = frame.image;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('[ARTryOnPage] wig load error: $e');
    }
  }

  // ── Camera init ───────────────────────────────────────────────────

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
      final cameras = await availableCameras();
      final target = _isFrontCamera
          ? CameraLensDirection.front
          : CameraLensDirection.back;
      CameraDescription camera = cameras.first;
      for (final c in cameras) {
        if (c.lensDirection == target) {
          camera = c;
          break;
        }
      }

      final ctrl = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isIOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.nv21,
      );
      await ctrl.initialize();
      if (!mounted) return;
      setState(() {
        _camCtrl = ctrl;
        _isInitializing = false;
      });
      await ctrl.startImageStream(_onFrame);
    } catch (e) {
      if (kDebugMode) debugPrint('[ARTryOnPage] init error: $e');
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

  Future<void> _disposeCamera() async {
    final c = _camCtrl;
    if (c != null) {
      if (c.value.isStreamingImages) {
        await c.stopImageStream();
      }
      await c.dispose();
    }
    _camCtrl = null;
  }

  // ── Flip camera ───────────────────────────────────────────────────

  Future<void> _flipCamera() async {
    _isFrontCamera = !_isFrontCamera;
    setState(() {
      _detectedFace = null;
      _faceRect = null;
      _isInitializing = true;
    });
    await _disposeCamera();
    await _initCamera();
  }

  // ── Frame processing ──────────────────────────────────────────────

  Future<void> _onFrame(CameraImage image) async {
    final ctrl = _camCtrl;
    if (ctrl == null || !ctrl.value.isInitialized) return;

    _frameTick++;
    if (_frameTick % 6 != 0) return; // ~5 fps
    if (_processing) return;
    _processing = true;

    try {
      final input = _buildInputImage(image, ctrl);
      if (input == null) return;

      final faces = await _faceDetector.processImage(input);
      if (!mounted) return;

      _imageSize = Size(image.width.toDouble(), image.height.toDouble());

      if (faces.isEmpty) {
        if (mounted && _faceRect != null) {
          setState(() {
            _detectedFace = null;
            _faceRect = null;
          });
        }
        return;
      }

      final face = faces.first;
      final bbox = face.boundingBox;
      final isFront =
          ctrl.description.lensDirection == CameraLensDirection.front;
      final previewRect = _mapImageRectToPreview(
        bbox,
        _previewSize,
        _imageSize,
        isFront,
      );
      if (!mounted) return;
      if (_rectChanged(_faceRect, previewRect)) {
        setState(() {
          _detectedFace = face;
          _faceRect = previewRect;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[ARTryOnPage] process: $e');
    } finally {
      _processing = false;
    }
  }

  // ── Input image building ──────────────────────────────────────────

  InputImage? _buildInputImage(CameraImage image, CameraController ctrl) {
    final sensor = ctrl.description.sensorOrientation;
    final rotation = _rotationFromDegrees(sensor);

    final InputImageFormat mlFormat;
    final Uint8List bytes;
    final int bytesPerRow;

    if (Platform.isIOS) {
      // iOS delivers BGRA8888 in a single plane.
      mlFormat = InputImageFormat.bgra8888;
      bytes = image.planes[0].bytes;
      bytesPerRow = image.planes[0].bytesPerRow;
    } else {
      // Android: concat all planes into NV21 buffer.
      final wb = WriteBuffer();
      for (final p in image.planes) {
        wb.putUint8List(p.bytes);
      }
      bytes = wb.done().buffer.asUint8List();
      bytesPerRow = image.planes[0].bytesPerRow;
      mlFormat = InputImageFormat.nv21;
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

  // ── Coordinate mapping ────────────────────────────────────────────

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

    Size effectiveImageSize = imageSize;
    if ((imageSize.width > imageSize.height) !=
        (previewSize.width > previewSize.height)) {
      effectiveImageSize = Size(imageSize.height, imageSize.width);
    }

    final scale = _maxDouble(
      previewSize.width / effectiveImageSize.width,
      previewSize.height / effectiveImageSize.height,
    );
    final scaledW = effectiveImageSize.width * scale;
    final scaledH = effectiveImageSize.height * scale;
    final dx = (previewSize.width - scaledW) / 2;
    final dy = (previewSize.height - scaledH) / 2;

    Rect mappedRect;
    if (effectiveImageSize != imageSize) {
      mappedRect = Rect.fromLTRB(
        imageRect.top,
        imageRect.left,
        imageRect.bottom,
        imageRect.right,
      );
    } else {
      mappedRect = imageRect;
    }

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

  double _maxDouble(double a, double b) => a > b ? a : b;

  // ── Capture & share ───────────────────────────────────────────────

  Future<void> _capture() async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);

    try {
      final boundary = _captureKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final tempDir = await Directory.systemTemp.createTemp('ar_tryon_');
      final file = File('${tempDir.path}/ar_tryon.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(file.path)],
        text: _sw
            ? 'Jaribu mtindo mpya na TAJIRI!'
            : 'Try a new look with TAJIRI!',
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[ARTryOnPage] capture error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _sw ? 'Imeshindwa kuchukua picha' : 'Failed to capture',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isInitializing
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white54),
            )
          : _initError != null
              ? _buildErrorState()
              : _buildCamera(_sw),
    );
  }

  // ── Camera view ───────────────────────────────────────────────────

  Widget _buildCamera(bool sw) {
    final ctrl = _camCtrl;
    if (ctrl == null || !ctrl.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white54),
      );
    }

    // Build the camera preview with cover-fit.
    Widget preview = SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: ctrl.value.previewSize?.height ?? 1,
          height: ctrl.value.previewSize?.width ?? 1,
          child: CameraPreview(ctrl),
        ),
      ),
    );

    // Tier 1: Color grading via ColorFiltered wrapper.
    final colorFilter = _engine.composedColorFilter;
    if (colorFilter != null) {
      preview = ColorFiltered(
        colorFilter: colorFilter,
        child: preview,
      );
    }

    // Build the captured layer (RepaintBoundary).
    final bool showOverlays =
        _detectedFace != null && !_engine.showBeforeAfter;
    final double smoothSigma = _engine.isBeautyActive(FilterType.beautySmoothSkin)
        ? _engine.beautyIntensity(FilterType.beautySmoothSkin) * 2.5
        : 0.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Layer 0: captured content.
        RepaintBoundary(
          key: _captureKey,
          child: ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Camera preview (with optional color filter applied above).
                preview,

                // Tier 2: Beauty smooth skin via BackdropFilter.
                if (smoothSigma > 0 && !_engine.showBeforeAfter)
                  BackdropFilter(
                    filter: ui.ImageFilter.blur(
                      sigmaX: smoothSigma,
                      sigmaY: smoothSigma,
                    ),
                    child: const SizedBox.expand(),
                  ),

                // Tier 3a: Hair style overlay (only if no wig active).
                if (showOverlays &&
                    _engine.activeHairStyle != null &&
                    _engine.activeWig == null)
                  CustomPaint(
                    size: Size.infinite,
                    painter: HairTryOnPainter(
                      faceRect: _faceRect,
                      styleIndex: _engine.activeHairStyle!.styleIndex ?? 0,
                      tint: _engine.activeHairColor?.color ??
                          const Color(0xFF1A1A1A),
                      face: _detectedFace,
                      previewSize: _previewSize,
                      imageSize: _imageSize,
                      isFrontCamera: _isFrontCamera,
                    ),
                  ),

                // Tier 3b: Wig overlay.
                if (showOverlays && _engine.activeWig != null)
                  CustomPaint(
                    size: Size.infinite,
                    painter: WigOverlayPainter(
                      wigImage: _wigImageCache[_engine.activeWig!.id],
                      face: _detectedFace,
                      previewSize: _previewSize,
                      imageSize: _imageSize,
                      isFrontCamera: _isFrontCamera,
                    ),
                  ),

                // Tier 3c: Face effects (lips, accessories, blush, etc.).
                if (showOverlays && _engine.allActiveARFilters.isNotEmpty)
                  CustomPaint(
                    size: Size.infinite,
                    painter: FaceLandmarkPainter(
                      face: _detectedFace,
                      activeFilters: _engine.allActiveARFilters,
                      previewSize: _previewSize,
                      imageSize: _imageSize,
                      isFrontCamera: _isFrontCamera,
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Layer 1: UI controls (not captured).

        // Top bar.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  // Back button.
                  _circleButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  // Compare (long-press).
                  GestureDetector(
                    onLongPressStart: (_) =>
                        _engine.toggleBeforeAfter(true),
                    onLongPressEnd: (_) =>
                        _engine.toggleBeforeAfter(false),
                    child: _circleButton(
                      icon: Icons.compare_rounded,
                      onTap: () {},
                      tooltip: sw ? 'Shikilia kulinganisha' : 'Hold to compare',
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Flip camera.
                  _circleButton(
                    icon: Icons.flip_camera_ios_rounded,
                    onTap: _flipCamera,
                    tooltip: sw ? 'Geuza kamera' : 'Flip camera',
                  ),
                  // Clear all (shown only when filters active).
                  if (_engine.hasAnyFilter) ...[
                    const SizedBox(width: 8),
                    _circleButton(
                      icon: Icons.layers_clear_rounded,
                      onTap: () => _engine.clearAll(),
                      tooltip: sw ? 'Ondoa zote' : 'Clear all',
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // Face guide when no face detected.
        if (_faceRect == null && !_isInitializing)
          Center(
            child: Opacity(
              opacity: 0.3,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.face_rounded,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    sw
                        ? 'Elekeza uso wako hapa'
                        : 'Position your face here',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),

        // Before/After label.
        if (_engine.showBeforeAfter)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 56),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    sw ? 'KABLA' : 'BEFORE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),

        // Color intensity slider (right edge, 25% from top).
        if (_engine.hasColorFilter)
          Positioned(
            right: 8,
            top: _previewSize.height * 0.25,
            child: FilterIntensitySlider(
              value: _engine.colorIntensity,
              onChanged: (v) => _engine.setColorIntensity(v),
              label: sw ? 'Kiwango' : 'Intensity',
            ),
          ),

        // Bottom: capture row + filter carousel.
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Capture row.
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Gallery placeholder.
                    _circleButton(
                      icon: Icons.photo_library_rounded,
                      onTap: () {},
                      size: 44,
                    ),
                    // Capture button.
                    GestureDetector(
                      onTap: _isCapturing ? null : _capture,
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 3.5,
                          ),
                        ),
                        child: Center(
                          child: _isCapturing
                              ? const SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Container(
                                  width: 56,
                                  height: 56,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    // Share button.
                    _circleButton(
                      icon: Icons.share_rounded,
                      onTap: _isCapturing ? null : _capture,
                      size: 44,
                    ),
                  ],
                ),
              ),
              // Filter carousel.
              FilterCarousel(
                engine: _engine,
                isSwahili: sw,
                wigPreviews: _wigImageCache,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Circle button helper ──────────────────────────────────────────

  Widget _circleButton({
    required IconData icon,
    VoidCallback? onTap,
    String? tooltip,
    double size = 40,
  }) {
    final child = GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.45),
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.55),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip, child: child);
    }
    return child;
  }

  // ── Error state ───────────────────────────────────────────────────

  Widget _buildErrorState() {
    final sw = _sw;
    final isPermission = _initError == 'camera_permission';
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPermission
                  ? Icons.camera_alt_rounded
                  : Icons.error_outline_rounded,
              size: 48,
              color: Colors.white38,
            ),
            const SizedBox(height: 16),
            Text(
              isPermission
                  ? (sw
                      ? 'Ruhusa ya kamera inahitajika'
                      : 'Camera permission required')
                  : (sw
                      ? 'Kamera imeshindwa kuanza'
                      : 'Camera failed to start'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (isPermission) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: openAppSettings,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white38),
                ),
                child: Text(
                  sw ? 'Fungua Mipangilio' : 'Open Settings',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const SizedBox(height: 16),
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white54),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
