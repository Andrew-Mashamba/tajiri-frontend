import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../../services/wave_h_services.dart';

/// Spec F7 #56 — Auto-generated SOAP visit notes; partner reviews + approves.
class VisitNotesReviewPage extends StatefulWidget {
  final int partnerUserId;
  final int consultationId;
  const VisitNotesReviewPage({
    super.key,
    required this.partnerUserId,
    required this.consultationId,
  });

  @override
  State<VisitNotesReviewPage> createState() => _VisitNotesReviewPageState();
}

class _VisitNotesReviewPageState extends State<VisitNotesReviewPage> {
  final _transcript = TextEditingController();
  Map<String, dynamic>? _note;
  bool _generating = false;
  int? _noteId;

  @override
  void dispose() {
    _transcript.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (_transcript.text.trim().length < 30) return;
    setState(() => _generating = true);
    final res = await VisitNotesService.generate(
      partnerUserId: widget.partnerUserId,
      consultationId: widget.consultationId,
      transcript: _transcript.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _generating = false;
      _note = res?['soap'] is Map<String, dynamic>
          ? res!['soap'] as Map<String, dynamic>
          : null;
      _noteId = (res?['note_id'] as num?)?.toInt();
    });
  }

  Future<void> _approve() async {
    if (_noteId == null) return;
    await VisitNotesService.approve(_noteId!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Imekubaliwa')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(isSw ? 'Maelezo ya kliniki' : 'Visit notes'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            isSw
                ? 'Bandika maelezo ya simu/maongezi. AI itajenga muundo wa SOAP.'
                : 'Paste the call transcript. AI will draft SOAP notes.',
            style: const TextStyle(color: Color(0xFF666666)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _transcript,
            maxLines: 8,
            decoration: InputDecoration(
              labelText: isSw ? 'Maelezo' : 'Transcript',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A1A)),
              onPressed: _generating ? null : _generate,
              child: Text(_generating
                  ? (isSw ? 'AI inafikiria…' : 'AI thinking…')
                  : (isSw ? 'Tengeneza' : 'Generate')),
            ),
          ),
          const SizedBox(height: 16),
          if (_note != null) ...[
            _SoapSection(
                title: isSw ? 'Subjective' : 'Subjective',
                body: _note!['subjective']?.toString() ?? ''),
            _SoapSection(
                title: isSw ? 'Objective' : 'Objective',
                body: _note!['objective']?.toString() ?? ''),
            _SoapSection(
                title: isSw ? 'Assessment' : 'Assessment',
                body: _note!['assessment']?.toString() ?? ''),
            _SoapSection(
                title: isSw ? 'Plan' : 'Plan',
                body: _note!['plan']?.toString() ?? ''),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.check_rounded),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
              onPressed: _approve,
              label: Text(isSw ? 'Kubali' : 'Approve'),
            ),
          ],
        ],
      ),
    );
  }
}

class _SoapSection extends StatelessWidget {
  final String title;
  final String body;
  const _SoapSection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    if (body.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF666666)),
          ),
          const SizedBox(height: 6),
          Text(body,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A))),
        ],
      ),
    );
  }
}
