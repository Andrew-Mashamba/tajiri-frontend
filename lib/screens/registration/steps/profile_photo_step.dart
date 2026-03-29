import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../l10n/app_strings_scope.dart';
import '../../../models/registration_models.dart';
import '../../../utils/face_validator.dart';

class ProfilePhotoStep extends StatefulWidget {
  final RegistrationState state;
  final VoidCallback onNext;
  final VoidCallback? onBack;

  const ProfilePhotoStep({
    super.key,
    required this.state,
    required this.onNext,
    this.onBack,
  });

  @override
  State<ProfilePhotoStep> createState() => _ProfilePhotoStepState();
}

class _ProfilePhotoStepState extends State<ProfilePhotoStep> {
  static const Color _primary = Color(0xFF1A1A1A);
  static const Color _secondaryText = Color(0xFF666666);
  static const Color _successGreen = Color(0xFF4CAF50);

  final ImagePicker _picker = ImagePicker();

  File? _selectedPhoto;
  bool _isValidating = false;
  bool _faceDetected = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.state.profilePhotoPath != null) {
      final file = File(widget.state.profilePhotoPath!);
      if (file.existsSync()) {
        _selectedPhoto = file;
        _faceDetected = true;
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
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
        final s = AppStringsScope.of(context);
        setState(() {
          _selectedPhoto = file;
          _faceDetected = false;
          _isValidating = false;
          _errorMessage = result.errorKey == 'no_face'
              ? (s?.faceNotDetected ?? 'No face detected')
              : (s?.multipleFacesDetected ?? 'Multiple faces detected');
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isValidating = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  void _validateAndProceed() {
    if (_faceDetected && _selectedPhoto != null) {
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          Text(
            s?.takeYourPhoto ?? 'Take your photo',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            s?.takeYourPhotoDesc ?? 'We need a photo that clearly shows your face',
            style: const TextStyle(fontSize: 14, color: _secondaryText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[200],
                  border: Border.all(
                    color: _faceDetected ? _successGreen : Colors.grey[300]!,
                    width: _faceDetected ? 3 : 1,
                  ),
                  image: _selectedPhoto != null
                      ? DecorationImage(
                          image: FileImage(_selectedPhoto!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _selectedPhoto == null
                    ? const Icon(Icons.person_rounded, size: 80, color: Colors.grey)
                    : null,
              ),
              if (_isValidating)
                const CircularProgressIndicator(),
              if (_faceDetected)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: _successGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 20),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_faceDetected)
            Text(
              s?.faceDetected ?? 'Face detected!',
              style: const TextStyle(color: _successGreen, fontWeight: FontWeight.w600),
            ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _isValidating ? null : () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt_rounded),
              label: Text(s?.takePhotoBtn ?? 'Take Photo'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: const BorderSide(color: _primary),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _isValidating ? null : () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_rounded),
              label: Text(s?.chooseFromGallery ?? 'Choose from Gallery'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _secondaryText,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: Colors.grey[400]!),
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _faceDetected ? _validateAndProceed : null,
              style: FilledButton.styleFrom(
                backgroundColor: _primary,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                s?.continueBtn ?? 'Continue',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
