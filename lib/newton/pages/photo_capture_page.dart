// lib/newton/pages/photo_capture_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/newton_models.dart';
import '../services/newton_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class PhotoCapturePage extends StatefulWidget {
  final SubjectMode subject;
  final DifficultyLevel difficulty;
  final bool isSwahili;

  const PhotoCapturePage({
    super.key,
    this.subject = SubjectMode.general,
    this.difficulty = DifficultyLevel.form1_4,
    this.isSwahili = false,
  });

  @override
  State<PhotoCapturePage> createState() => _PhotoCapturePageState();
}

class _PhotoCapturePageState extends State<PhotoCapturePage> {
  final NewtonService _service = NewtonService();
  final _questionC = TextEditingController();
  final _imagePicker = ImagePicker();
  String? _imagePath;
  String? _response;
  bool _isSending = false;

  @override
  void dispose() {
    _questionC.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(source: source);
      if (picked == null || !mounted) return;
      setState(() {
        _imagePath = picked.path;
        _response = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isSwahili
              ? 'Imeshindwa kufungua kamera'
              : 'Failed to open camera'),
        ),
      );
    }
  }

  Future<void> _sendToNewton() async {
    if (_imagePath == null) return;
    setState(() => _isSending = true);

    final result = await _service.askWithImage(
      imagePath: _imagePath!,
      question: _questionC.text.trim().isEmpty
          ? null
          : _questionC.text.trim(),
      subject: widget.subject,
      difficulty: widget.difficulty,
      isSwahili: widget.isSwahili,
    );

    if (!mounted) return;
    setState(() {
      _isSending = false;
      if (result.success && result.data != null) {
        _response = result.data!.content;
      } else {
        _response = result.message ??
            (widget.isSwahili
                ? 'Imeshindwa kusoma picha.'
                : 'Failed to read the image.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sw = widget.isSwahili;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: Text(
          sw ? 'Tatua kwa picha' : 'Photo solver',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image preview or capture prompt
              if (_imagePath == null) ...[
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.grey.shade300,
                        style: BorderStyle.solid),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.camera_alt_rounded,
                          size: 48, color: _kSecondary),
                      const SizedBox(height: 12),
                      Text(
                        sw
                            ? 'Piga picha ya swali lako'
                            : 'Take a photo of your question',
                        style:
                            const TextStyle(fontSize: 14, color: _kSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_rounded,
                              size: 18),
                          label: Text(sw ? 'Kamera' : 'Camera'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kPrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_rounded,
                              size: 18),
                          label: Text(sw ? 'Picha' : 'Gallery'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _kPrimary,
                            side: const BorderSide(color: _kPrimary),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Show captured image
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(_imagePath!),
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => setState(() {
                      _imagePath = null;
                      _response = null;
                    }),
                    icon: const Icon(Icons.refresh_rounded,
                        size: 16, color: _kSecondary),
                    label: Text(sw ? 'Badilisha picha' : 'Change photo',
                        style: const TextStyle(
                            fontSize: 12, color: _kSecondary)),
                  ),
                ),
                const SizedBox(height: 8),

                // Optional question field
                TextField(
                  controller: _questionC,
                  decoration: InputDecoration(
                    hintText: sw
                        ? 'Swali la ziada (si lazima)...'
                        : 'Additional question (optional)...',
                    hintStyle:
                        const TextStyle(fontSize: 14, color: _kSecondary),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.all(14),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  style: const TextStyle(fontSize: 14),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Send button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isSending ? null : _sendToNewton,
                    icon: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.auto_awesome_rounded, size: 18),
                    label: Text(
                      _isSending
                          ? (sw ? 'Inachanganua...' : 'Analyzing...')
                          : (sw ? 'Uliza Newton' : 'Ask Newton'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],

              // Response
              if (_response != null) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded,
                              size: 16, color: Colors.amber.shade700),
                          const SizedBox(width: 8),
                          Text(
                            sw ? 'Jibu la Newton' : 'Newton\'s response',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.amber.shade700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SelectableText(
                        _response!,
                        style: const TextStyle(
                            fontSize: 14,
                            color: _kPrimary,
                            height: 1.5),
                      ),
                    ],
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
