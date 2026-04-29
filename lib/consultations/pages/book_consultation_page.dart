import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../../tajirika/models/tajirika_models.dart';
import '../../tajirika/services/tajirika_service.dart';
import '../../tajirika/widgets/consultation_intake_form.dart';
import '../../tajirika/widgets/nda_acceptance_gate.dart';
import '../../tajirika/widgets/slot_picker.dart';
import '../models/consultation.dart';
import '../services/consultation_service.dart';
import '../widgets/symptom_chat_sheet.dart';
import 'consultation_status_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kMuted = Color(0xFF9E9E9E);

/// Generic consultation booking page that powers all three vertical-specific
/// entry pages (legal / medical / business). Verticals pass their own
/// [vertical], skill filter, and base fee per spec line 717 (TZS 5k text, 25k
/// video, 60k in_person — multiplied by mode tier and duration).
class BookConsultationPage extends StatefulWidget {
  final int userId;
  final ConsultationVertical vertical;
  final List<String> skillFilter;
  final int baseFeeTzs;
  final TajirikaPartner? preselectedPartner;

  const BookConsultationPage({
    super.key,
    required this.userId,
    required this.vertical,
    required this.skillFilter,
    required this.baseFeeTzs,
    this.preselectedPartner,
  });

  @override
  State<BookConsultationPage> createState() => _BookConsultationPageState();
}

class _BookConsultationPageState extends State<BookConsultationPage> {
  int _step = 0;

  TajirikaPartner? _partner;
  bool _loadingPartners = false;
  List<TajirikaPartner> _partners = const [];
  /// Spec line 718 — selected insurance hard-filter (medical only).
  String? _insuranceFilter;
  String? _partnerError;

  // NDA
  bool _ndaAccepted = false;
  final TextEditingController _signatureCtrl = TextEditingController();

  // Mode + duration
  ConsultationMode _mode = ConsultationMode.video;
  int _durationMin = 30;

  // Slot
  DateTime? _startsAt;

  // Intake
  final TextEditingController _intakeCtrl = TextEditingController();
  List<ConsultationAttachment> _attachments = const [];
  final TextEditingController _addressCtrl = TextEditingController();

  bool _submitting = false;
  String? _submitError;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;
  bool get _hasPreselected => widget.preselectedPartner != null;

  @override
  void initState() {
    super.initState();
    _partner = widget.preselectedPartner;
    final addr = LocalStorageService.instanceSync?.getUser()?.location?.displayAddress;
    if (addr != null && addr.isNotEmpty) _addressCtrl.text = addr;
  }

  @override
  void dispose() {
    _signatureCtrl.dispose();
    _intakeCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  int get _computedFee {
    return (widget.baseFeeTzs * _mode.baseMultiplier * (_durationMin / 30)).round();
  }

  String get _verticalTitle {
    switch (widget.vertical) {
      case ConsultationVertical.legal:
        return _isSwahili ? 'Hifadhi Ushauri wa Kisheria' : 'Book Legal Consultation';
      case ConsultationVertical.medical:
        return _isSwahili ? 'Hifadhi Ushauri wa Daktari' : 'Book Medical Consultation';
      case ConsultationVertical.business:
        return _isSwahili ? 'Hifadhi Ushauri wa Biashara' : 'Book Business Consultation';
    }
  }

  Future<void> _loadPartners() async {
    setState(() {
      _loadingPartners = true;
      _partnerError = null;
    });
    final token = LocalStorageService.instanceSync?.getAuthToken() ?? '';
    final partners = await TajirikaService.searchPartners(
      token,
      skills: widget.skillFilter,
    );
    if (!mounted) return;
    setState(() {
      _loadingPartners = false;
      _partners = partners;
      if (partners.isEmpty) {
        _partnerError = _isSwahili
            ? 'Hakuna washauri waliosajiliwa kwa eneo hili bado.'
            : 'No registered consultants for this skill yet.';
      }
    });
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickSlot() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (!mounted || date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (!mounted || time == null) return;
    final picked = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (picked.isBefore(DateTime.now())) {
      _toast(_isSwahili ? 'Chagua wakati wa baadaye' : 'Pick a future slot');
      return;
    }
    setState(() => _startsAt = picked);
  }

  Future<void> _submit() async {
    if (_partner == null) {
      _toast(_isSwahili ? 'Chagua mshauri kwanza' : 'Select a consultant first');
      return;
    }
    if (!_ndaAccepted || _signatureCtrl.text.trim().isEmpty) {
      _toast(_isSwahili ? 'Saini mkataba wa usiri' : 'Sign the confidentiality agreement');
      return;
    }
    if (_startsAt == null) {
      _toast(_isSwahili ? 'Chagua tarehe na muda' : 'Pick a date and time');
      return;
    }
    final intake = _intakeCtrl.text.trim();
    if (intake.length < 50) {
      _toast(_isSwahili
          ? 'Eleza tatizo lako (angalau herufi 50)'
          : 'Describe your case (50 chars minimum)');
      return;
    }
    if (_mode == ConsultationMode.inPerson && _addressCtrl.text.trim().isEmpty) {
      _toast(_isSwahili ? 'Andika anwani ya kukutania' : 'Enter the meeting address');
      return;
    }
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    final res = await ConsultationService.create(
      userId: widget.userId,
      targetPartnerUserId: _partner!.userId,
      targetPartnerId: _partner!.id,
      vertical: widget.vertical,
      skillCategory: widget.skillFilter.isNotEmpty ? widget.skillFilter.first : null,
      mode: _mode,
      durationMin: _durationMin,
      serviceTitle: _defaultServiceTitle(),
      feeTzs: _computedFee,
      intakeSummary: intake,
      attachments: _attachments,
      customerAddress: _mode == ConsultationMode.inPerson
          ? _addressCtrl.text.trim()
          : null,
      startsAt: _startsAt!,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res.success && res.consultation != null) {
      _toast(_isSwahili
          ? 'Mahojiano yamewekwa. ${_partner!.name} atayasoma.'
          : 'Booking placed. ${_partner!.name} will review.');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ConsultationStatusPage(
            userId: widget.userId,
            consultationId: res.consultation!.id,
          ),
        ),
      );
    } else {
      setState(() => _submitError = res.message ?? 'Failed');
    }
  }

  String _defaultServiceTitle() {
    final modeLabel = _isSwahili ? _mode.labelSwahili : _mode.label;
    return '$_durationMin-min $modeLabel ${widget.vertical.labelSwahili}';
  }

  Future<void> _runSymptomChecker() async {
    final t = await SymptomChatSheet.show(context);
    if (t == null || !mounted) return;
    final isSw = _isSwahili;
    final summary = isSw
        ? 'Daktari aliyependekezwa: ${t.specialty}. Hali: ${t.severity}. '
            '\nDalili: ${_intakeCtrl.text.trim()}'
        : 'Suggested specialty: ${t.specialty}. Severity: ${t.severity}. '
            '\nSymptom: ${_intakeCtrl.text.trim()}';
    setState(() {
      if (_intakeCtrl.text.trim().isEmpty) {
        _intakeCtrl.text = summary;
      }
    });
    if (t.severity == 'emergency' && mounted) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.warning_rounded,
              color: Color(0xFFB71C1C), size: 32),
          title: Text(isSw ? 'Tahadhari!' : 'Emergency!'),
          content: Text(
            isSw
                ? 'Hii inaonekana kama dharura. Nenda hospitalini sasa au piga 112.'
                : 'This looks like an emergency. Go to the ER now or call 112.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(isSw ? 'Sawa' : 'OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stepCount = _hasPreselected ? 5 : 6;
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _kPrimary,
        title: Text(
          _verticalTitle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: _isSwahili ? 'Tathmini ya AI' : 'AI triage',
            icon: const Icon(Icons.psychology_rounded),
            onPressed: _runSymptomChecker,
          ),
        ],
      ),
      body: Stepper(
        currentStep: _step,
        type: StepperType.vertical,
        controlsBuilder: (ctx, details) {
          final isLast = _step >= stepCount - 1;
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                if (_step > 0)
                  TextButton(
                    onPressed: _submitting ? null : details.onStepCancel,
                    child: Text(_isSwahili ? 'Rudi' : 'Back'),
                  ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _submitting
                      ? null
                      : (isLast ? _submit : details.onStepContinue),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(isLast
                      ? (_isSwahili ? 'Hifadhi' : 'Book')
                      : (_isSwahili ? 'Endelea' : 'Continue')),
                ),
              ],
            ),
          );
        },
        onStepContinue: () {
          if (_step < stepCount - 1) setState(() => _step++);
        },
        onStepCancel: () {
          if (_step > 0) setState(() => _step--);
        },
        steps: [
          if (!_hasPreselected) _stepPartner(),
          _stepNda(),
          _stepMode(),
          _stepSlot(),
          _stepIntake(),
          _stepReview(),
        ],
      ),
    );
  }

  Step _stepPartner() {
    if (_partners.isEmpty && !_loadingPartners && _partnerError == null) {
      _loadPartners();
    }
    return Step(
      title: Text(_isSwahili ? 'Chagua mshauri' : 'Choose a consultant'),
      isActive: _step >= 0,
      content: _loadingPartners
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          : _partnerError != null
              ? Text(_partnerError!, style: const TextStyle(color: Color(0xFFB71C1C)))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _insuranceFilterChips(),
                    const SizedBox(height: 8),
                    ..._partners.map((p) => RadioListTile<int>(
                          value: p.id,
                          groupValue: _partner?.id,
                          onChanged: (_) => setState(() => _partner = p),
                          title: Text(p.name),
                          subtitle: Text(
                            p.skills
                                .take(3)
                                .map((s) => s.label)
                                .join(', '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                const TextStyle(fontSize: 11, color: _kMuted),
                          ),
                          dense: true,
                        )),
                  ],
                ),
    );
  }

  /// Spec line 718 — NHIF/AAR/Jubilee as a hard filter at customer search.
  Widget _insuranceFilterChips() {
    final isSw = _isSwahili;
    if (widget.vertical != ConsultationVertical.medical) {
      return const SizedBox.shrink();
    }
    final options = ['NHIF', 'AAR', 'Jubilee'];
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        ChoiceChip(
          label: Text(isSw ? 'Yote' : 'All'),
          selected: _insuranceFilter == null,
          onSelected: (_) => setState(() => _insuranceFilter = null),
          selectedColor: _kPrimary,
          labelStyle: TextStyle(
            color: _insuranceFilter == null ? Colors.white : _kPrimary,
            fontSize: 11,
          ),
        ),
        ...options.map((o) {
          final selected = _insuranceFilter == o;
          return ChoiceChip(
            label: Text(o),
            selected: selected,
            onSelected: (_) => setState(() => _insuranceFilter = o),
            selectedColor: _kPrimary,
            labelStyle: TextStyle(
              color: selected ? Colors.white : _kPrimary,
              fontSize: 11,
            ),
          );
        }),
      ],
    );
  }

  Step _stepNda() {
    final name = _partner?.name ?? (_isSwahili ? 'mshauri' : 'the consultant');
    return Step(
      title: Text(_isSwahili ? 'Mkataba wa usiri' : 'Confidentiality'),
      isActive: _step >= 0,
      content: NdaAcceptanceGate(
        partnerDisplayName: name,
        accepted: _ndaAccepted,
        onChanged: (v) => setState(() => _ndaAccepted = v),
        signatureController: _signatureCtrl,
      ),
    );
  }

  Step _stepMode() {
    final modes = ConsultationMode.values;
    return Step(
      title: Text(_isSwahili ? 'Aina na muda' : 'Mode and duration'),
      isActive: _step >= 0,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isSwahili ? 'Aina ya mahojiano' : 'Consultation mode',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: modes.map((m) {
              final selected = _mode == m;
              return ChoiceChip(
                avatar: Icon(m.icon, size: 16, color: selected ? Colors.white : _kPrimary),
                label: Text(_isSwahili ? m.labelSwahili : m.label),
                selected: selected,
                onSelected: (_) => setState(() => _mode = m),
                selectedColor: _kPrimary,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : _kPrimary,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            _isSwahili ? 'Muda (dakika)' : 'Duration (minutes)',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: const [15, 30, 45, 60].map((d) {
              final selected = _durationMin == d;
              return ChoiceChip(
                label: Text('$d min'),
                selected: selected,
                onSelected: (_) => setState(() => _durationMin = d),
                selectedColor: _kPrimary,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : _kPrimary,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFEEEEEE)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.payments_rounded, size: 18, color: _kPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isSwahili ? 'Gharama inayopendekezwa' : 'Suggested fee',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                  ),
                ),
                Text(
                  'TZS ${NumberFormat('#,##0', 'en_US').format(_computedFee)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Step _stepSlot() {
    return Step(
      title: Text(_isSwahili ? 'Tarehe na wakati' : 'Date and time'),
      isActive: _step >= 0,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_partner != null)
            SlotPicker(
              partnerUserId: _partner!.userId,
              skillCategory: widget.skillFilter.isNotEmpty
                  ? widget.skillFilter.first
                  : null,
              selected: _startsAt,
              onSelected: (dt) => setState(() => _startsAt = dt),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickSlot,
            icon: const Icon(Icons.event_rounded, size: 18),
            label: Text(_startsAt == null
                ? (_isSwahili ? 'Au chagua wakati mwingine' : 'Or pick custom time')
                : DateFormat('EEE d MMM • HH:mm').format(_startsAt!)),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kPrimary,
              side: const BorderSide(color: Color(0xFFEEEEEE)),
            ),
          ),
          if (_startsAt != null) ...[
            const SizedBox(height: 8),
            Text(
              '${_isSwahili ? 'Itaisha' : 'Ends'}: ${DateFormat('HH:mm').format(_startsAt!.add(Duration(minutes: _durationMin)))}',
              style: const TextStyle(fontSize: 11, color: _kMuted),
            ),
          ],
        ],
      ),
    );
  }

  Step _stepIntake() {
    return Step(
      title: Text(_isSwahili ? 'Maelezo ya tatizo' : 'Case intake'),
      isActive: _step >= 0,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConsultationIntakeForm(
            intakeController: _intakeCtrl,
            attachments: _attachments,
            onAttachmentsChanged: (xs) => setState(() => _attachments = xs),
            userId: widget.userId,
          ),
          if (_mode == ConsultationMode.inPerson) ...[
            const SizedBox(height: 12),
            Text(
              _isSwahili ? 'Anwani ya kukutania' : 'Meeting address',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _addressCtrl,
              decoration: InputDecoration(
                hintText: _isSwahili ? 'Mfano: Mikocheni B, Dar es Salaam' : 'e.g. Mikocheni B, Dar es Salaam',
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Step _stepReview() {
    final fee = NumberFormat('#,##0', 'en_US').format(_computedFee);
    return Step(
      title: Text(_isSwahili ? 'Hakiki na thibitisha' : 'Review and confirm'),
      isActive: _step >= 0,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _kv(_isSwahili ? 'Mshauri' : 'Consultant', _partner?.name ?? '—'),
          _kv(_isSwahili ? 'Aina' : 'Mode', _isSwahili ? _mode.labelSwahili : _mode.label),
          _kv(_isSwahili ? 'Muda' : 'Duration', '$_durationMin min'),
          _kv(_isSwahili ? 'Tarehe' : 'Slot',
              _startsAt == null ? '—' : DateFormat('EEE d MMM • HH:mm').format(_startsAt!)),
          _kv(_isSwahili ? 'Gharama' : 'Fee', 'TZS $fee'),
          if (_attachments.isNotEmpty)
            _kv(_isSwahili ? 'Viambatanisho' : 'Attachments', '${_attachments.length}'),
          if (_mode == ConsultationMode.inPerson)
            _kv(_isSwahili ? 'Anwani' : 'Address', _addressCtrl.text),
          if (_submitError != null) ...[
            const SizedBox(height: 8),
            Text(_submitError!, style: const TextStyle(color: Color(0xFFB71C1C), fontSize: 12)),
          ],
          if (_submitting)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(k, style: const TextStyle(fontSize: 12, color: _kMuted)),
          ),
          Expanded(
            child: Text(
              v,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
