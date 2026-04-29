import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/app_strings_scope.dart';
import '../services/consultation_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBorder = Color(0xFFEEEEEE);

/// Spec line 729 — K-Health-style derm photo intake.
/// 3-step guided capture: full face, close-up, side.
/// Photos upload to consultations.derm_intake_photos.
class DermIntakePage extends StatefulWidget {
  final int consultationId;
  final int userId;

  const DermIntakePage({
    super.key,
    required this.consultationId,
    required this.userId,
  });

  @override
  State<DermIntakePage> createState() => _DermIntakePageState();
}

class _DermStep {
  final String promptSw;
  final String promptEn;
  final String id;
  File? file;

  _DermStep({
    required this.promptSw,
    required this.promptEn,
    required this.id,
  });
}

class _DermIntakePageState extends State<DermIntakePage> {
  late final List<_DermStep> _steps;
  int _currentStep = 0;
  bool _uploading = false;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _steps = [
      _DermStep(
        id: 'full_face',
        promptSw: 'Piga picha ya uso wote',
        promptEn: 'Photo of full face',
      ),
      _DermStep(
        id: 'close_up',
        promptSw: 'Piga picha karibu',
        promptEn: 'Close-up photo',
      ),
      _DermStep(
        id: 'side',
        promptSw: 'Piga picha ya pande',
        promptEn: 'Side photo',
      ),
    ];
  }

  Future<void> _capture() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _steps[_currentStep].file = File(picked.path);
    });
  }

  Future<void> _submit() async {
    final photos = <Map<String, dynamic>>[];
    for (final s in _steps) {
      if (s.file == null) continue;
      // Upload file first
      final uploadRes = await ConsultationService.uploadAttachment(
        userId: widget.userId,
        file: s.file!,
      );
      if (uploadRes.success && uploadRes.attachment != null) {
        photos.add({
          'url': uploadRes.attachment!.url,
          'prompt': s.id,
        });
      }
    }
    if (photos.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isSwahili ? 'Hakuna picha zilizochukuliwa' : 'No photos captured'),
      ));
      return;
    }
    setState(() => _uploading = true);
    final res = await ConsultationService.submitDermIntakePhotos(
      id: widget.consultationId,
      userId: widget.userId,
      photos: photos,
    );
    if (!mounted) return;
    setState(() => _uploading = false);
    if (res.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isSwahili ? 'Picha zimewekwa' : 'Photos uploaded'),
      ));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.message ?? (_isSwahili ? 'Imeshindikana' : 'Failed')),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSw = _isSwahili;
    final step = _steps[_currentStep];
    final allDone = _steps.every((s) => s.file != null);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _kPrimary,
        title: Text(
          isSw ? 'Picha za ngozi' : 'Derm photo intake',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _steps.length; i++) ...[
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: i == _currentStep
                            ? _kPrimary
                            : (_steps[i].file != null
                                ? const Color(0xFF1B5E20)
                                : _kBorder),
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (i < _steps.length - 1)
                      Container(
                        width: 32,
                        height: 2,
                        color: _kBorder,
                      ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              Text(
                isSw ? step.promptSw : step.promptEn,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _kPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                isSw ? 'Hatua ${_currentStep + 1} ya ${_steps.length}' : 'Step ${_currentStep + 1} of ${_steps.length}',
                style: const TextStyle(fontSize: 12, color: _kSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GestureDetector(
                  onTap: _capture,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: _kBorder),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: step.file != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              step.file!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt_rounded,
                                size: 56,
                                color: _kPrimary.withValues(alpha: 0.15),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                isSw ? 'Gusa kupiga picha' : 'Tap to capture',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _kSecondary.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _currentStep--),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kPrimary,
                          side: const BorderSide(color: _kBorder),
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: Text(isSw ? 'Rudi' : 'Back'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentStep < _steps.length - 1) {
                          setState(() => _currentStep++);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: Text(
                        _currentStep < _steps.length - 1
                            ? (isSw ? 'Endelea' : 'Next')
                            : (isSw ? 'Maliza' : 'Finish'),
                      ),
                    ),
                  ),
                ],
              ),
              if (allDone) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _uploading ? null : _submit,
                    icon: _uploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.cloud_upload_rounded),
                    label: Text(isSw ? 'Weka picha' : 'Upload photos'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
