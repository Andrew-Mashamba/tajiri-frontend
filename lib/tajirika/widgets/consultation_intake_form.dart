import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../consultations/models/consultation.dart';
import '../../consultations/services/consultation_service.dart';
import '../../l10n/app_strings_scope.dart';

/// Encrypted-at-rest intake summary + optional attachments per spec §7.4.5–7.4.6
/// (lines 663–664). Field-level encryption is deferred to the data-protection
/// foundational work; intake_summary travels over HTTPS and lands in a TEXT
/// column gated to (customer_user_id ∪ partner_user_id) on read.
class ConsultationIntakeForm extends StatefulWidget {
  final TextEditingController intakeController;
  final List<ConsultationAttachment> attachments;
  final ValueChanged<List<ConsultationAttachment>> onAttachmentsChanged;
  final int userId;

  const ConsultationIntakeForm({
    super.key,
    required this.intakeController,
    required this.attachments,
    required this.onAttachmentsChanged,
    required this.userId,
  });

  @override
  State<ConsultationIntakeForm> createState() => _ConsultationIntakeFormState();
}

class _ConsultationIntakeFormState extends State<ConsultationIntakeForm> {
  bool _uploading = false;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  Future<void> _pickFiles() async {
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: false,
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (picked == null || picked.files.isEmpty) return;
    if (!mounted) return;
    setState(() => _uploading = true);
    final added = <ConsultationAttachment>[];
    for (final f in picked.files) {
      if (f.path == null) continue;
      final res = await ConsultationService.uploadAttachment(
        userId: widget.userId,
        file: File(f.path!),
      );
      if (res.success && res.attachment != null) {
        added.add(res.attachment!);
      }
    }
    if (!mounted) return;
    setState(() => _uploading = false);
    if (added.isNotEmpty) {
      widget.onAttachmentsChanged([...widget.attachments, ...added]);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isSwahili
              ? 'Kupakia faili kumeshindikana'
              : 'File upload failed'),
        ),
      );
    }
  }

  void _removeAttachment(int index) {
    final next = [...widget.attachments]..removeAt(index);
    widget.onAttachmentsChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isSwahili ? 'Eleza tatizo' : 'Describe your case',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _isSwahili
              ? 'Andika maelezo wazi (herufi 50–2000). Maelezo haya ni ya siri.'
              : 'Provide a clear summary (50–2000 characters). This intake is confidential.',
          style: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: widget.intakeController,
          minLines: 5,
          maxLines: 12,
          maxLength: 2000,
          decoration: InputDecoration(
            hintText: _isSwahili
                ? 'Mfano: Mgonjwa anaumwa kichwa kwa siku tatu...'
                : 'e.g. Patient reports headache for 3 days...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
            ),
          ),
          style: const TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                _isSwahili
                    ? 'Viambatanisho (picha, PDF) — hiari'
                    : 'Attachments (photos, PDF) — optional',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _uploading ? null : _pickFiles,
              icon: _uploading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.attach_file_rounded, size: 18),
              label: Text(_isSwahili ? 'Pakia' : 'Add'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1A1A1A),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        if (widget.attachments.isNotEmpty) ...[
          const SizedBox(height: 4),
          ...widget.attachments.asMap().entries.map((e) => _attachmentRow(e.key, e.value)),
        ] else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              _isSwahili
                  ? 'Hakuna viambatanisho bado'
                  : 'No attachments yet',
              style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
            ),
          ),
      ],
    );
  }

  Widget _attachmentRow(int index, ConsultationAttachment att) {
    final isPdf = (att.mime ?? '').contains('pdf') ||
        (att.name ?? '').toLowerCase().endsWith('.pdf');
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(
            isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
            size: 18,
            color: const Color(0xFF1A1A1A),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              att.name ?? att.url,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Color(0xFF1A1A1A)),
            ),
          ),
          IconButton(
            onPressed: () => _removeAttachment(index),
            icon: const Icon(Icons.close_rounded, size: 16),
            tooltip: _isSwahili ? 'Ondoa' : 'Remove',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
        ],
      ),
    );
  }
}
