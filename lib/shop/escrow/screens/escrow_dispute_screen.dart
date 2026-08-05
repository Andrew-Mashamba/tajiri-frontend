import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../../config/api_config.dart';
import '../../../services/local_storage_service.dart';
import '../services/escrow_service.dart';

const Color _kBackground = Color(0xFFFAFAFA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kPrimaryText = Color(0xFF1A1A1A);
const Color _kSecondaryText = Color(0xFF666666);
const Color _kDivider = Color(0xFFE0E0E0);

class _ReasonOption {
  final String value;
  final String label;
  const _ReasonOption(this.value, this.label);
}

const _kReasons = [
  _ReasonOption('not_received', 'Item not received'),
  _ReasonOption('not_as_described', 'Item not as described'),
  _ReasonOption('damaged', 'Item arrived damaged'),
  _ReasonOption('other', 'Other'),
];

/// Screen for the buyer to raise an escrow dispute.
class EscrowDisputeScreen extends StatefulWidget {
  final int orderId;
  final String token;

  const EscrowDisputeScreen({
    super.key,
    required this.orderId,
    required this.token,
  });

  @override
  State<EscrowDisputeScreen> createState() => _EscrowDisputeScreenState();
}

class _EscrowDisputeScreenState extends State<EscrowDisputeScreen> {
  String _selectedReason = 'not_received';
  final TextEditingController _descController = TextEditingController();
  bool _submitting = false;
  bool _uploadingEvidence = false;
  String? _validationError;
  final List<File> _evidenceFiles = [];
  final ImagePicker _picker = ImagePicker();

  static const int _maxEvidence = 4;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  bool get _requiresDescription => _selectedReason == 'other';

  Future<String?> _uploadFile(File file) async {
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken() ?? '';
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/media/upload');
      final req = http.MultipartRequest('POST', uri)
        ..headers.addAll(ApiConfig.authHeaders(token))
        ..files.add(await http.MultipartFile.fromPath('file', file.path));
      final res = await req.send();
      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = jsonDecode(await res.stream.bytesToString());
        return body['data']?['url'] as String?;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _submit() async {
    if (_requiresDescription && _descController.text.trim().isEmpty) {
      setState(() => _validationError = 'Please describe the issue.');
      return;
    }
    setState(() {
      _submitting = true;
      _validationError = null;
    });

    setState(() => _uploadingEvidence = true);
    final uploadedUrls = <String>[];
    for (final file in _evidenceFiles) {
      final url = await _uploadFile(file);
      if (url != null) uploadedUrls.add(url);
    }
    setState(() => _uploadingEvidence = false);

    final success = await EscrowService.raiseDispute(
      widget.orderId,
      widget.token,
      reason: _selectedReason,
      description: _descController.text.trim().isNotEmpty
          ? _descController.text.trim()
          : null,
      evidenceUrls: uploadedUrls,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Dispute raised. Our team will review within 24 hours.'),
          duration: Duration(seconds: 4),
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to raise dispute. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        title: const Text(
          'Raise a Dispute',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: _kPrimaryText),
        ),
        backgroundColor: _kSurface,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimaryText),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildInfoBanner(),
            const SizedBox(height: 20),
            _buildReasonSection(),
            const SizedBox(height: 20),
            _buildDescriptionSection(),
            const SizedBox(height: 20),
            _buildEvidenceSection(),
            const SizedBox(height: 32),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFECB3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFFF57F17)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'A dispute will pause the escrow auto-release. Our team reviews all disputes within 24 hours.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF5D4037),
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What is the issue?',
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimaryText),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kDivider),
          ),
          child: Column(
            children: _kReasons.asMap().entries.map((entry) {
              final i = entry.key;
              final option = entry.value;
              final selected = _selectedReason == option.value;
              return Column(
                children: [
                  if (i > 0)
                    const Divider(height: 1, color: _kDivider, indent: 52),
                  InkWell(
                    onTap: () => setState(() => _selectedReason = option.value),
                    borderRadius: BorderRadius.only(
                      topLeft: i == 0 ? const Radius.circular(12) : Radius.zero,
                      topRight:
                          i == 0 ? const Radius.circular(12) : Radius.zero,
                      bottomLeft: i == _kReasons.length - 1
                          ? const Radius.circular(12)
                          : Radius.zero,
                      bottomRight: i == _kReasons.length - 1
                          ? const Radius.circular(12)
                          : Radius.zero,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected
                                    ? _kPrimaryText
                                    : _kDivider,
                                width: selected ? 6 : 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              option.label,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: _kPrimaryText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Description',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kPrimaryText),
            ),
            const SizedBox(width: 6),
            Text(
              _requiresDescription ? '(required)' : '(optional)',
              style: const TextStyle(fontSize: 12, color: _kSecondaryText),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _descController,
          maxLines: 4,
          minLines: 3,
          onChanged: (_) {
            if (_validationError != null) {
              setState(() => _validationError = null);
            }
          },
          decoration: InputDecoration(
            hintText: 'Describe what happened...',
            hintStyle:
                const TextStyle(fontSize: 13, color: Color(0xFF999999)),
            filled: true,
            fillColor: _kSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kDivider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kDivider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kPrimaryText),
            ),
            errorText: _validationError,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Future<void> _pickEvidence() async {
    if (_evidenceFiles.length >= _maxEvidence) return;
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1280,
      );
      if (picked == null) return;
      if (!mounted) return;
      setState(() => _evidenceFiles.add(File(picked.path)));
    } catch (_) {}
  }

  Widget _buildEvidenceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Evidence Photos',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kPrimaryText),
            ),
            const SizedBox(width: 6),
            Text(
              '(optional, up to $_maxEvidence)',
              style: const TextStyle(fontSize: 12, color: _kSecondaryText),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 80,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ..._evidenceFiles.asMap().entries.map((entry) {
                final i = entry.key;
                final file = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          file,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _evidenceFiles.removeAt(i)),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: Color(0xFFDC2626),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (_evidenceFiles.length < _maxEvidence)
                GestureDetector(
                  onTap: _pickEvidence,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _kSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _kDivider),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_rounded,
                            size: 26, color: _kSecondaryText),
                        SizedBox(height: 4),
                        Text(
                          'Add Photo',
                          style: TextStyle(
                              fontSize: 10, color: _kSecondaryText),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final busy = _submitting || _uploadingEvidence;
    final label = _uploadingEvidence
        ? 'Uploading evidence…'
        : 'Submit Dispute';
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: busy ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kPrimaryText,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF888888),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Text(
                label,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}
