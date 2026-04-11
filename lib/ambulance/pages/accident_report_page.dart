// lib/ambulance/pages/accident_report_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/local_storage_service.dart';
import '../services/ambulance_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);
const Color _kRed = Color(0xFFCC0000);

class AccidentReportPage extends StatefulWidget {
  const AccidentReportPage({super.key});
  @override
  State<AccidentReportPage> createState() => _AccidentReportPageState();
}

class _AccidentReportPageState extends State<AccidentReportPage> {
  final AmbulanceService _service = AmbulanceService();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _locationCtrl = TextEditingController();
  String _severity = 'moderate';
  final List<String> _photoPaths = [];
  bool _isSubmitting = false;
  late final bool _isSwahili;

  // Default GPS (Dar es Salaam), production should use geolocator
  final double _latitude = -6.7924;
  final double _longitude = 39.2083;

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
    _locationCtrl.text = 'Dar es Salaam'; // Auto-filled placeholder
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final img =
          await _picker.pickImage(source: ImageSource.camera, maxWidth: 1200);
      if (img != null && mounted) {
        setState(() => _photoPaths.add(img.path));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final img = await _picker.pickImage(
          source: ImageSource.gallery, maxWidth: 1200);
      if (img != null && mounted) {
        setState(() => _photoPaths.add(img.path));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Future<void> _submit() async {
    final desc = _descCtrl.text.trim();
    if (desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_isSwahili
                ? 'Maelezo yanahitajika'
                : 'Description is required')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final result = await _service.reportAccident(
        latitude: _latitude,
        longitude: _longitude,
        address: _locationCtrl.text.trim().isNotEmpty
            ? _locationCtrl.text.trim()
            : null,
        description: desc,
        severity: _severity,
        photoPaths: _photoPaths,
      );
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      final messenger = ScaffoldMessenger.of(context);
      if (result.success) {
        messenger.showSnackBar(
          SnackBar(
              content: Text(_isSwahili
                  ? 'Ripoti imetumwa'
                  : 'Report submitted successfully'),
              backgroundColor: _kPrimary),
        );
        Navigator.pop(context);
      } else {
        messenger.showSnackBar(
          SnackBar(
              content: Text(result.message ??
                  (_isSwahili ? 'Imeshindwa' : 'Failed'))),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final severities = [
      ('minor', _isSwahili ? 'Ndogo' : 'Minor', const Color(0xFF4CAF50)),
      (
        'moderate',
        _isSwahili ? 'Wastani' : 'Moderate',
        const Color(0xFFFF9800)
      ),
      ('severe', _isSwahili ? 'Kubwa' : 'Severe', const Color(0xFFE65100)),
      (
        'critical',
        _isSwahili ? 'Hatari Sana' : 'Critical',
        _kRed,
      ),
    ];

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(
          _isSwahili ? 'Ripoti ya Ajali' : 'Report Accident',
          style:
              const TextStyle(color: _kPrimary, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location
            Text(
              _isSwahili ? 'Mahali' : 'Location',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _locationCtrl,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                prefixIcon:
                    const Icon(Icons.place_rounded, color: _kSecondary),
                hintText: _isSwahili
                    ? 'Mahali pa ajali'
                    : 'Accident location',
                hintStyle:
                    const TextStyle(fontSize: 13, color: _kSecondary),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // Severity
            Text(
              _isSwahili ? 'Ukali' : 'Severity',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: severities.map((s) {
                final selected = _severity == s.$1;
                return ChoiceChip(
                  label: Text(s.$2,
                      style: TextStyle(
                          color: selected ? Colors.white : s.$3,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                  selected: selected,
                  onSelected: (_) => setState(() => _severity = s.$1),
                  selectedColor: s.$3,
                  backgroundColor: s.$3.withValues(alpha: 0.1),
                  side: BorderSide(
                      color: selected ? s.$3 : s.$3.withValues(alpha: 0.3)),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Description
            Text(
              _isSwahili ? 'Maelezo' : 'Description',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              maxLines: 5,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: _isSwahili
                    ? 'Eleza kilichotokea...'
                    : 'Describe what happened...',
                hintStyle:
                    const TextStyle(fontSize: 13, color: _kSecondary),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.all(14),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // Photos
            Text(
              _isSwahili ? 'Picha' : 'Photos',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // Add photo buttons
                  GestureDetector(
                    onTap: _pickPhoto,
                    child: Container(
                      width: 90,
                      height: 90,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.camera_alt_rounded,
                              color: _kSecondary, size: 28),
                          const SizedBox(height: 4),
                          Text(
                            _isSwahili ? 'Kamera' : 'Camera',
                            style: const TextStyle(
                                fontSize: 11, color: _kSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _pickFromGallery,
                    child: Container(
                      width: 90,
                      height: 90,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.photo_library_rounded,
                              color: _kSecondary, size: 28),
                          const SizedBox(height: 4),
                          Text(
                            _isSwahili ? 'Picha' : 'Gallery',
                            style: const TextStyle(
                                fontSize: 11, color: _kSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Photo previews
                  ..._photoPaths.asMap().entries.map((entry) {
                    return Stack(
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            image: DecorationImage(
                              image: FileImage(File(entry.value)),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 12,
                          child: GestureDetector(
                            onTap: () => setState(
                                () => _photoPaths.removeAt(entry.key)),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: _kRed,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: _kRed,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(
                        _isSwahili ? 'Tuma Ripoti' : 'Submit Report',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
