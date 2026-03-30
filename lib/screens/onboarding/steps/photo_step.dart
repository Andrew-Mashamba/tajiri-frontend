import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../l10n/app_strings_scope.dart';
import '../../../models/registration_models.dart';
import '../../../utils/face_validator.dart';

/// Chapter 1, Screen 2 — Profile photo with ML Kit face detection.
///
/// Swahili-first UI. Detects exactly 1 face before enabling "Endelea".
class PhotoStep extends StatefulWidget {
  final RegistrationState state;
  final VoidCallback onNext;
  final VoidCallback? onBack;

  const PhotoStep({
    super.key,
    required this.state,
    required this.onNext,
    this.onBack,
  });

  @override
  State<PhotoStep> createState() => _PhotoStepState();
}

class _PhotoStepState extends State<PhotoStep> {
  static const Color _primary = Color(0xFF1A1A1A);
  static const Color _bg = Color(0xFFFAFAFA);
  static const Color _secondaryText = Color(0xFF666666);
  static const Color _successGreen = Color(0xFF4CAF50);
  static const Color _errorRed = Color(0xFFE53935);

  final ImagePicker _picker = ImagePicker();

  File? _selectedPhoto;
  bool _isValidating = false;
  bool _faceDetected = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Restore previously picked photo if present
    if (widget.state.profilePhotoPath != null) {
      final file = File(widget.state.profilePhotoPath!);
      if (file.existsSync()) {
        _selectedPhoto = file;
        _faceDetected = true;
      }
    }
  }

  // ── Camera permission ──────────────────────────────────────────────────────

  Future<bool> _ensureCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) {
      _showCameraPermissionDenied();
      return false;
    }
    final result = await Permission.camera.request();
    if (result.isGranted) return true;
    if (result.isPermanentlyDenied) {
      _showCameraPermissionDenied();
    }
    return false;
  }

  void _showCameraPermissionDenied() {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Ruhusa ya Kamera',
          style: TextStyle(color: _primary, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Tunahitaji ruhusa ya kamera. Fungua Mipangilio.',
          style: TextStyle(color: _secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Sawa', style: TextStyle(color: _secondaryText)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              openAppSettings();
            },
            style: FilledButton.styleFrom(
              backgroundColor: _primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Fungua Mipangilio'),
          ),
        ],
      ),
    );
  }

  // ── Image picking + face validation ───────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      final hasPermission = await _ensureCameraPermission();
      if (!hasPermission) return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );
      if (image == null) return;

      setState(() {
        _isValidating = true;
        _errorMessage = null;
        _faceDetected = false;
      });

      final file = File(image.path);
      final result = await FaceValidator.validate(file);

      if (!mounted) return;

      if (result.isValid) {
        setState(() {
          _selectedPhoto = file;
          _faceDetected = true;
          _isValidating = false;
          _errorMessage = null;
        });

        widget.state.profilePhotoPath = file.path;
        if (result.faceBounds != null) {
          widget.state.faceBbox = {
            'x': result.faceBounds!.left.round(),
            'y': result.faceBounds!.top.round(),
            'width': result.faceBounds!.width.round(),
            'height': result.faceBounds!.height.round(),
          };
        }
      } else {
        setState(() {
          _selectedPhoto = file;
          _faceDetected = false;
          _isValidating = false;
          _errorMessage = result.errorKey == 'no_face'
              ? 'Hatuwezi kuona uso wako vizuri. Jaribu tena na mwanga mzuri!'
              : 'Picha ina watu wengi. Picha inapaswa kuwa yako peke yako.';
        });

        // Clear previously stored valid photo data
        widget.state.profilePhotoPath = null;
        widget.state.faceBbox = null;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isValidating = false;
        _errorMessage = 'Hitilafu imetokea. Jaribu tena.';
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable — kept for future string expansion
    final s = AppStringsScope.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Headline ──
            const Text(
              'Tupige picha!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: _primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Picha yako husaidia marafiki kukutambua',
              style: TextStyle(fontSize: 15, color: _secondaryText),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // ── Photo preview ──
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFE8E8E8),
                    border: Border.all(
                      color: _faceDetected
                          ? _successGreen
                          : (_errorMessage != null
                              ? _errorRed
                              : const Color(0xFFCCCCCC)),
                      width: _faceDetected || _errorMessage != null ? 3 : 1.5,
                    ),
                    image: _selectedPhoto != null
                        ? DecorationImage(
                            image: FileImage(_selectedPhoto!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _selectedPhoto == null
                      ? const Icon(
                          Icons.person_rounded,
                          size: 80,
                          color: Color(0xFFAAAAAA),
                        )
                      : null,
                ),

                // Spinner during ML Kit processing
                if (_isValidating)
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.35),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3,
                      ),
                    ),
                  ),

                // Success badge
                if (_faceDetected && !_isValidating)
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: _successGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Face feedback text ──
            if (_faceDetected && !_isValidating)
              const Text(
                'Poa! Uso unaonekana vizuri',
                style: TextStyle(
                  color: _successGreen,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),

            if (_errorMessage != null && !_isValidating)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: _errorRed, fontSize: 13),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            const SizedBox(height: 32),

            // ── Camera button ──
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _isValidating
                    ? null
                    : () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text('Piga Picha'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: _primary),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Gallery button ──
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _isValidating
                    ? null
                    : () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_rounded),
                label: const Text('Chagua kutoka Galeri'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _secondaryText,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: Color(0xFFAAAAAA)),
                  textStyle: const TextStyle(fontSize: 15),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── Continue button ──
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _faceDetected && !_isValidating
                    ? widget.onNext
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: _primary,
                  disabledBackgroundColor: const Color(0xFFCCCCCC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Endelea \u2192',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
