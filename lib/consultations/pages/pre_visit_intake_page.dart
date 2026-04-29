import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../models/consultation.dart';
import '../services/consultation_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBorder = Color(0xFFEEEEEE);

/// Spec line 727 — pre-visit intake form rendered per specialty.
/// Medical, legal, and business each get a tailored question set.
/// Submit marks pre_visit_intake_completed=true on the consultation.
class PreVisitIntakePage extends StatefulWidget {
  final int consultationId;
  final int userId;
  final ConsultationVertical vertical;

  const PreVisitIntakePage({
    super.key,
    required this.consultationId,
    required this.userId,
    required this.vertical,
  });

  @override
  State<PreVisitIntakePage> createState() => _PreVisitIntakePageState();
}

class _FieldDef {
  final String key;
  final String labelEn;
  final String labelSw;
  final String? hintEn;
  final String? hintSw;
  final bool multiline;

  const _FieldDef({
    required this.key,
    required this.labelEn,
    required this.labelSw,
    this.hintEn,
    this.hintSw,
    this.multiline = false,
  });
}

class _PreVisitIntakePageState extends State<PreVisitIntakePage> {
  final Map<String, TextEditingController> _ctrls = {};
  bool _submitting = false;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  List<_FieldDef> get _fields {
    switch (widget.vertical) {
      case ConsultationVertical.medical:
        return const [
          _FieldDef(
            key: 'current_medications',
            labelEn: 'Current medications',
            labelSw: 'Dawa unazotumia sasa',
            hintEn: 'List any medications you take regularly',
            hintSw: 'Orodhesha dawa unazotumia mara kwa mara',
          ),
          _FieldDef(
            key: 'allergies',
            labelEn: 'Known allergies',
            labelSw: 'Mzio unayojua',
            hintEn: 'Food, drug, or environmental allergies',
            hintSw: 'Chakula, dawa, au mazingira',
          ),
          _FieldDef(
            key: 'symptom_start',
            labelEn: 'When did symptoms start?',
            labelSw: 'Dalili zilianza lini?',
            hintEn: 'e.g. 3 days ago',
            hintSw: 'Mfano: siku 3 zilizopita',
          ),
          _FieldDef(
            key: 'pain_level',
            labelEn: 'Pain level (0-10)',
            labelSw: 'Kiwango cha maumivu (0-10)',
          ),
          _FieldDef(
            key: 'previous_treatment',
            labelEn: 'Any treatment tried so far?',
            labelSw: 'Matibabu yoyote uliyojaribu?',
            multiline: true,
          ),
        ];
      case ConsultationVertical.legal:
        return const [
          _FieldDef(
            key: 'case_summary',
            labelEn: 'Case summary',
            labelSw: 'Muhtasari wa kesi',
            multiline: true,
            hintEn: 'Briefly describe the legal issue',
            hintSw: 'Eleza kwa ufupi suala la kisheria',
          ),
          _FieldDef(
            key: 'desired_outcome',
            labelEn: 'Desired outcome',
            labelSw: 'Matokeo unayotaka',
            multiline: true,
          ),
          _FieldDef(
            key: 'opposing_party',
            labelEn: 'Opposing party (if any)',
            labelSw: 'Upande wa pingu (ikiwapo)',
          ),
          _FieldDef(
            key: 'documents_ready',
            labelEn: 'Documents ready?',
            labelSw: 'Nyarasa ziko tayari?',
            hintEn: 'Contracts, letters, court papers...',
            hintSw: 'Mikataba, barua, karatasi za mahakama...',
          ),
        ];
      case ConsultationVertical.business:
        return const [
          _FieldDef(
            key: 'business_name',
            labelEn: 'Business name',
            labelSw: 'Jina la biashara',
          ),
          _FieldDef(
            key: 'industry',
            labelEn: 'Industry / sector',
            labelSw: 'Sekta ya biashara',
          ),
          _FieldDef(
            key: 'challenge',
            labelEn: 'Main challenge',
            labelSw: 'Changamoto kuu',
            multiline: true,
          ),
          _FieldDef(
            key: 'annual_revenue',
            labelEn: 'Annual revenue (TZS, optional)',
            labelSw: 'Mapato ya mwaka (TZS, hiari)',
          ),
          _FieldDef(
            key: 'team_size',
            labelEn: 'Team size',
            labelSw: 'Idadi ya wafanyakazi',
          ),
        ];
    }
  }

  @override
  void initState() {
    super.initState();
    for (final f in _fields) {
      _ctrls[f.key] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  double get _progress {
    int filled = 0;
    for (final f in _fields) {
      if (_ctrls[f.key]?.text.trim().isNotEmpty ?? false) filled++;
    }
    return _fields.isEmpty ? 1.0 : filled / _fields.length;
  }

  Future<void> _submit() async {
    final answers = <String, dynamic>{};
    for (final f in _fields) {
      answers[f.key] = _ctrls[f.key]!.text.trim();
    }
    setState(() => _submitting = true);
    final res = await ConsultationService.submitPreVisitIntake(
      id: widget.consultationId,
      userId: widget.userId,
      answers: answers,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isSwahili ? 'Fomu imejaa' : 'Intake completed'),
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
    final progress = _progress;
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _kPrimary,
        title: Text(
          isSw ? 'Fomu ya awali' : 'Pre-visit intake',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          LinearProgressIndicator(
            value: progress,
            backgroundColor: _kBorder,
            color: _kPrimary,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 6),
          Text(
            isSw
                ? 'Umekamilisha ${(progress * 100).round()}%'
                : '${(progress * 100).round()}% complete',
            style: const TextStyle(fontSize: 11, color: _kSecondary),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 12),
          ..._fields.expand((f) => [
            _fieldCard(f, isSw),
            const SizedBox(height: 12),
          ]),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_rounded),
              label: Text(isSw ? 'Wasilisha' : 'Submit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldCard(_FieldDef f, bool isSw) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSw ? f.labelSw : f.labelEn,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _kPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _ctrls[f.key],
            maxLines: f.multiline ? 4 : 1,
            minLines: f.multiline ? 2 : 1,
            decoration: InputDecoration(
              hintText: isSw
                  ? (f.hintSw ?? '')
                  : (f.hintEn ?? ''),
              border: const OutlineInputBorder(),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }
}
