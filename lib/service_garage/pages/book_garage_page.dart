import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/api_config.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../../tajirika/models/tajirika_models.dart';
import '../../tajirika/services/tajirika_service.dart';
import '../models/garage_booking.dart';
import '../services/garage_booking_service.dart';

class BookGaragePage extends StatefulWidget {
  final int userId;
  final AutoSkill? preselectedSkill;
  final TajirikaPartner? preselectedPartner;
  /// Optional prefill from `SymptomWizardPage` (spec F5 line 532+).
  final String? prefillFaultSummary;
  final String? prefillVin;
  final String? prefillPlate;
  final String? prefillMake;
  final String? prefillModel;
  final int? prefillYear;

  const BookGaragePage({
    super.key,
    required this.userId,
    this.preselectedSkill,
    this.preselectedPartner,
    this.prefillFaultSummary,
    this.prefillVin,
    this.prefillPlate,
    this.prefillMake,
    this.prefillModel,
    this.prefillYear,
  });

  @override
  State<BookGaragePage> createState() => _BookGaragePageState();
}

class _BookGaragePageState extends State<BookGaragePage> {
  static const int _maxPhotos = 4;
  static const int _minSummary = 20;

  int _step = 0;
  AutoSkill? _skill;
  String? _dropOffMode;
  final _makeCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _summaryCtrl = TextEditingController();
  final _capCtrl = TextEditingController();
  final List<String> _uploadedPhotos = [];
  bool _uploading = false;
  final List<String> _obd2Photos = [];
  bool _interpreting = false;
  String? _obd2Interpretation;

  DateTime? _dropOffAt;

  TajirikaPartner? _partner;
  bool _loadingPartners = false;
  List<TajirikaPartner> _partners = const [];
  String? _partnerSearchError;

  bool _submitting = false;
  String? _summaryError;
  String? _plateError;
  String? _dropOffModeError;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  // String? _vin;

  @override
  void initState() {
    super.initState();
    _skill = widget.preselectedSkill;
    _partner = widget.preselectedPartner;
    if (widget.prefillFaultSummary != null) _summaryCtrl.text = widget.prefillFaultSummary!;
    if (widget.prefillPlate != null) _plateCtrl.text = widget.prefillPlate!;
    if (widget.prefillMake != null) _makeCtrl.text = widget.prefillMake!;
    if (widget.prefillModel != null) _modelCtrl.text = widget.prefillModel!;
    if (widget.prefillYear != null) _yearCtrl.text = widget.prefillYear.toString();
    // _vin = widget.prefillVin;
  }

  @override
  void dispose() {
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _plateCtrl.dispose();
    _yearCtrl.dispose();
    _summaryCtrl.dispose();
    _capCtrl.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _addPhoto() async {
    if (_uploadedPhotos.length >= _maxPhotos) {
      _toast(_isSwahili ? 'Picha zaidi ya $_maxPhotos haziruhusiwi' : 'Maximum $_maxPhotos photos');
      return;
    }
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 82,
      );
      if (picked == null || !mounted) return;
      setState(() => _uploading = true);
      final res = await GarageBookingService.uploadPhoto(
        userId: widget.userId,
        file: File(picked.path),
      );
      if (!mounted) return;
      setState(() => _uploading = false);
      if (res.success && (res.photoUrl ?? '').isNotEmpty) {
        setState(() => _uploadedPhotos.add(res.photoUrl!));
      } else {
        _toast(res.message ?? (_isSwahili ? 'Picha imeshindikana' : 'Upload failed'));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      _toast(_isSwahili ? 'Kosa: $e' : 'Error: $e');
    }
  }

  Future<void> _pickDropOff() async {
    final now = DateTime.now();
    final initialDate = _dropOffAt ?? now.add(const Duration(days: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(now) ? now : initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialDate.hour, minute: 0),
    );
    if (time == null || !mounted) return;
    setState(() {
      _dropOffAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _loadPartners() async {
    if (_skill == null) return;
    setState(() {
      _loadingPartners = true;
      _partnerSearchError = null;
    });
    final token = LocalStorageService.instanceSync?.getAuthToken() ?? '';
    final partners = await TajirikaService.searchPartners(
      token,
      skills: [_skill!.apiValue],
      dropOffMode: _dropOffMode,
    );
    if (!mounted) return;
    setState(() {
      _loadingPartners = false;
      _partners = partners;
      if (partners.isEmpty) {
        _partnerSearchError = _isSwahili
            ? 'Hakuna mafundi waliosajiliwa kwa kazi hii bado.'
            : 'No partners registered for this skill yet.';
      }
    });
  }

  bool _validateStep(int step) {
    switch (step) {
      case 0:
        return _skill != null;
      case 1:
        if (_dropOffMode == null) {
          setState(() => _dropOffModeError = _isSwahili
              ? 'Chagua mahali pa kufanya kazi'
              : 'Choose where the work happens');
          return false;
        }
        setState(() => _dropOffModeError = null);
        return true;
      case 2:
        if (_makeCtrl.text.trim().isEmpty || _modelCtrl.text.trim().isEmpty) {
          _toast(_isSwahili ? 'Andika make na model' : 'Enter make and model');
          return false;
        }
        if (!isValidTzPlate(_plateCtrl.text)) {
          setState(() => _plateError = _isSwahili
              ? 'Namba mbaya. Mfano: T123ABC'
              : 'Invalid plate. Example: T123ABC');
          return false;
        }
        setState(() => _plateError = null);
        return true;
      case 3:
        final t = _summaryCtrl.text.trim();
        if (t.length < _minSummary) {
          setState(() => _summaryError = _isSwahili
              ? 'Eleza tatizo, angalau herufi $_minSummary'
              : 'At least $_minSummary characters');
          return false;
        }
        setState(() => _summaryError = null);
        return true;
      case 4:
      case 5:
        return true;
      case 6:
        if (_dropOffAt == null) {
          _toast(_isSwahili ? 'Chagua siku ya kupeleka gari' : 'Pick a drop-off slot');
          return false;
        }
        return true;
      case 7:
        if (_partner == null) {
          _toast(_isSwahili ? 'Chagua fundi wa gari' : 'Pick a garage partner');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  Future<void> _submit() async {
    for (var i = 0; i <= 5; i++) {
      if (!_validateStep(i)) {
        setState(() => _step = i);
        return;
      }
    }
    setState(() => _submitting = true);
    final res = await GarageBookingService.create(
      userId: widget.userId,
      targetPartnerUserId: _partner!.userId,
      skill: _skill!,
      vehicleMake: _makeCtrl.text.trim(),
      vehicleModel: _modelCtrl.text.trim(),
      vehiclePlate: _plateCtrl.text.trim().toUpperCase(),
      vehicleYear: int.tryParse(_yearCtrl.text.trim()),
      faultSummary: _summaryCtrl.text.trim(),
      dropOffAt: _dropOffAt!,
      costCapTzs: int.tryParse(_capCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')),
      photos: List<String>.from(_uploadedPhotos),
      dropOffMode: _dropOffMode,
      obd2Photos: List<String>.from(_obd2Photos),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res.success && res.booking != null) {
      _toast(_isSwahili
          ? 'Ombi limewekwa. Subiri fundi athibitishe.'
          : 'Booking sent. Awaiting partner confirmation.');
      Navigator.of(context).pop(res.booking);
    } else {
      _toast(res.message ?? (_isSwahili ? 'Imeshindikana kutuma' : 'Failed to submit'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSw = _isSwahili;
    return Scaffold(
      appBar: AppBar(title: Text(isSw ? 'Peleka Gari' : 'Drop Off Car')),
      body: SafeArea(
        child: Stepper(
          type: StepperType.vertical,
          currentStep: _step,
          onStepTapped: (i) => setState(() => _step = i),
          onStepContinue: () async {
            if (!_validateStep(_step)) return;
            // After picking drop-off mode, prefetch partners.
            if (_step == 1 && _partners.isEmpty) {
              await _loadPartners();
            }
            if (_step < 8) {
              setState(() => _step += 1);
            } else {
              _submit();
            }
          },
          onStepCancel: () {
            if (_step > 0) setState(() => _step -= 1);
          },
          controlsBuilder: (context, details) {
            final isLast = _step == 8;
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(children: [
                FilledButton(
                  onPressed: _submitting ? null : details.onStepContinue,
                  child: _submitting && isLast
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(isLast
                          ? (isSw ? 'Tuma Ombi' : 'Send Booking')
                          : (isSw ? 'Endelea' : 'Continue')),
                ),
                const SizedBox(width: 12),
                if (_step > 0)
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: Text(isSw ? 'Rudi' : 'Back'),
                  ),
              ]),
            );
          },
          steps: [
            _stepSkill(isSw),
            _stepDropOffMode(isSw),
            _stepVehicle(isSw),
            _stepFault(isSw),
            _stepObd2(isSw),
            _stepPhotos(isSw),
            _stepDropOff(isSw),
            _stepPartner(isSw),
            _stepReview(isSw),
          ],
        ),
      ),
    );
  }

  Step _stepSkill(bool isSw) => Step(
        title: Text(isSw ? 'Aina ya kazi' : 'Service type'),
        isActive: _step >= 0,
        state: _skill != null && _step > 0 ? StepState.complete : StepState.indexed,
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AutoSkill.values.map((s) {
            final selected = _skill == s;
            return ChoiceChip(
              label: Text(isSw ? s.labelSwahili : s.label),
              avatar: Icon(s.icon, size: 18),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  _skill = s;
                  _partner = null;
                  _partners = const [];
                });
              },
            );
          }).toList(),
        ),
      );

  Step _stepDropOffMode(bool isSw) => Step(
        title: Text(isSw ? 'Wapi?' : 'Where?'),
        isActive: _step >= 1,
        state: _dropOffMode != null && _step > 1 ? StepState.complete : StepState.indexed,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSw
                  ? 'Chagua mahali unapotaka kazi ifanyike:'
                  : 'Choose where you want the work done:',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _dropOffModeChip('driveway', isSw ? 'Njiya ya kuingia' : 'Driveway', Icons.home_rounded, isSw),
                _dropOffModeChip('office', isSw ? 'Ofisi' : 'Office', Icons.business_rounded, isSw),
                _dropOffModeChip('shop', isSw ? 'Duka' : 'Shop', Icons.store_rounded, isSw),
              ],
            ),
            if (_dropOffModeError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _dropOffModeError!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      );

  Widget _dropOffModeChip(String mode, String label, IconData icon, bool isSw) {
    final selected = _dropOffMode == mode;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _dropOffMode = mode;
          _partner = null;
          _partners = const [];
          _dropOffModeError = null;
        });
      },
    );
  }

  Step _stepObd2(bool isSw) => Step(
        title: Text(isSw ? 'Dashboard / OBD2' : 'Dashboard / OBD2'),
        isActive: _step >= 4,
        state: _step > 4 ? StepState.complete : StepState.indexed,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isSw
                  ? 'Piga picha ya dashboard au taa za onyo. Hadi 2.'
                  : 'Photograph the dashboard or warning lights. Up to 2.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._obd2Photos.asMap().entries.map((e) => Stack(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          ApiConfig.sanitizeUrl(e.value) ?? e.value,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 80,
                            height: 80,
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.broken_image_rounded),
                          ),
                        ),
                      ),
                      Positioned(
                        top: -4,
                        right: -4,
                        child: IconButton(
                          icon: const Icon(Icons.cancel_rounded, size: 20),
                          onPressed: () => setState(() => _obd2Photos.removeAt(e.key)),
                        ),
                      ),
                    ])),
                if (_obd2Photos.length < 2)
                  InkWell(
                    onTap: _interpreting ? null : _addObd2Photo,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _interpreting
                          ? const Center(child: CircularProgressIndicator())
                          : const Icon(Icons.add_a_photo_rounded),
                    ),
                  ),
              ],
            ),
            if (_obd2Interpretation != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  border: Border.all(color: const Color(0xFF0D47A1).withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.tips_and_updates_rounded,
                        size: 18, color: Color(0xFF0D47A1)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _obd2Interpretation!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF0D47A1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );

  Future<void> _addObd2Photo() async {
    if (_obd2Photos.length >= 2) {
      _toast(_isSwahili ? 'Picha zaidi ya 2 haziruhusiwi' : 'Maximum 2 photos');
      return;
    }
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        imageQuality: 82,
      );
      if (picked == null || !mounted) return;
      setState(() => _interpreting = true);
      final res = await GarageBookingService.uploadPhoto(
        userId: widget.userId,
        file: File(picked.path),
      );
      if (!mounted) return;
      setState(() => _interpreting = false);
      if (res.success && (res.photoUrl ?? '').isNotEmpty) {
        setState(() => _obd2Photos.add(res.photoUrl!));
        final interpretation = await GarageBookingService.interpretObd2Photo(
          photoUrl: res.photoUrl!,
          isSwahili: _isSwahili,
        );
        if (!mounted) return;
        setState(() => _obd2Interpretation = interpretation);
      } else {
        _toast(res.message ?? (_isSwahili ? 'Picha imeshindikana' : 'Upload failed'));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _interpreting = false);
      _toast(_isSwahili ? 'Kosa: $e' : 'Error: $e');
    }
  }

  Step _stepVehicle(bool isSw) => Step(
        title: Text(isSw ? 'Gari' : 'Vehicle'),
        isActive: _step >= 2,
        state: _step > 2 ? StepState.complete : StepState.indexed,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _makeCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: isSw ? 'Aina (make)' : 'Make',
                    hintText: 'Toyota',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _modelCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Model',
                    hintText: 'Vitz',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _plateCtrl,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                    LengthLimitingTextInputFormatter(7),
                  ],
                  onChanged: (_) {
                    if (_plateError != null) setState(() => _plateError = null);
                  },
                  decoration: InputDecoration(
                    labelText: isSw ? 'Namba ya gari' : 'Plate',
                    hintText: 'T123ABC',
                    errorText: _plateError,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _yearCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: InputDecoration(
                    labelText: isSw ? 'Mwaka (hiari)' : 'Year (optional)',
                    hintText: '2018',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ]),
          ],
        ),
      );

  Step _stepFault(bool isSw) => Step(
        title: Text(isSw ? 'Eleza tatizo' : 'Describe the fault'),
        isActive: _step >= 3,
        state: _step > 3 ? StepState.complete : StepState.indexed,
        content: TextField(
          controller: _summaryCtrl,
          maxLines: 5,
          maxLength: 1000,
          onChanged: (_) {
            if (_summaryError != null) setState(() => _summaryError = null);
          },
          decoration: InputDecoration(
            hintText: isSw
                ? 'Mfano: Inalia injini ikianza, hasa baridi asubuhi…'
                : 'e.g. Engine knocks at start, especially cold mornings…',
            errorText: _summaryError,
            border: const OutlineInputBorder(),
          ),
        ),
      );

  Step _stepPhotos(bool isSw) => Step(
        title: Text(isSw ? 'Picha za tatizo' : 'Fault photos'),
        isActive: _step >= 5,
        state: _step > 5 ? StepState.complete : StepState.indexed,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isSw
                  ? 'Picha za sehemu yenye tatizo, dashboard, au taa za onyo. Hadi $_maxPhotos.'
                  : 'Photos of the fault, dashboard, or warning lights. Up to $_maxPhotos.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._uploadedPhotos.asMap().entries.map((e) => Stack(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          ApiConfig.sanitizeUrl(e.value) ?? e.value,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 80,
                            height: 80,
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.broken_image_rounded),
                          ),
                        ),
                      ),
                      Positioned(
                        top: -4,
                        right: -4,
                        child: IconButton(
                          icon: const Icon(Icons.cancel_rounded, size: 20),
                          onPressed: () => setState(() => _uploadedPhotos.removeAt(e.key)),
                        ),
                      ),
                    ])),
                if (_uploadedPhotos.length < _maxPhotos)
                  InkWell(
                    onTap: _uploading ? null : _addPhoto,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _uploading
                          ? const Center(child: CircularProgressIndicator())
                          : const Icon(Icons.add_a_photo_rounded),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );

  Step _stepDropOff(bool isSw) => Step(
        title: Text(isSw ? 'Muda wa kupeleka' : 'Drop-off slot'),
        isActive: _step >= 6,
        state: _step > 6 ? StepState.complete : StepState.indexed,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OutlinedButton.icon(
              onPressed: _pickDropOff,
              icon: const Icon(Icons.calendar_today_rounded),
              label: Text(_dropOffAt == null
                  ? (isSw ? 'Chagua siku na saa' : 'Pick date and time')
                  : _formatDateTime(_dropOffAt!)),
            ),
            if (_dropOffAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  isSw
                      ? 'Fundi atathibitisha au atapendekeza muda mwingine.'
                      : 'The partner will confirm or suggest another time.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      );

  Step _stepPartner(bool isSw) => Step(
        title: Text(isSw ? 'Chagua fundi' : 'Pick partner'),
        isActive: _step >= 7,
        state: _partner != null && _step > 7 ? StepState.complete : StepState.indexed,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_loadingPartners) const Center(child: Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            )),
            if (_partnerSearchError != null) Text(
              _partnerSearchError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            if (!_loadingPartners && _partners.isNotEmpty) ...[
              if (_partner != null)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.check_circle_rounded, color: Colors.green),
                    title: Text(_partner!.name),
                    subtitle: Text(isSw ? 'Imechaguliwa' : 'Selected'),
                    trailing: TextButton(
                      onPressed: () => setState(() => _partner = null),
                      child: Text(isSw ? 'Badili' : 'Change'),
                    ),
                  ),
                ),
              if (_partner == null)
                ..._partners.take(8).map((p) => ListTile(
                      leading: CircleAvatar(
                        backgroundImage: p.photoUrl.isNotEmpty
                            ? NetworkImage(ApiConfig.sanitizeUrl(p.photoUrl) ?? p.photoUrl)
                            : null,
                        child: p.photoUrl.isEmpty ? const Icon(Icons.person_rounded) : null,
                      ),
                      title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        '${p.aggregateRating.toStringAsFixed(1)}★ • ${p.jobsCompleted} ${isSw ? "kazi" : "jobs"}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => setState(() => _partner = p),
                    )),
            ],
            if (!_loadingPartners && _partners.isEmpty)
              TextButton.icon(
                onPressed: _loadPartners,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(isSw ? 'Tafuta tena' : 'Reload'),
              ),
          ],
        ),
      );

  Step _stepReview(bool isSw) => Step(
        title: Text(isSw ? 'Hakiki na thibitisha' : 'Review and confirm'),
        isActive: _step >= 8,
        state: _step >= 8 ? StepState.editing : StepState.indexed,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _row(isSw ? 'Kazi:' : 'Service', _skill == null ? '—' : (isSw ? _skill!.labelSwahili : _skill!.label)),
            _row(isSw ? 'Mahali:' : 'Location', _dropOffMode == null ? '—' : _dropOffMode!),
            _row(isSw ? 'Gari:' : 'Vehicle',
                '${_makeCtrl.text.trim()} ${_modelCtrl.text.trim()}'.trim()),
            _row(isSw ? 'Namba:' : 'Plate', _plateCtrl.text.trim().toUpperCase()),
            if (_yearCtrl.text.trim().isNotEmpty)
              _row(isSw ? 'Mwaka:' : 'Year', _yearCtrl.text.trim()),
            _row(isSw ? 'Tatizo:' : 'Fault', _summaryCtrl.text.trim()),
            if (_obd2Photos.isNotEmpty)
              _row(isSw ? 'OBD2:' : 'OBD2', '${_obd2Photos.length} ${isSw ? "picha" : "photos"}'),
            _row(isSw ? 'Muda:' : 'Drop-off',
                _dropOffAt == null ? '—' : _formatDateTime(_dropOffAt!)),
            _row(isSw ? 'Fundi:' : 'Partner', _partner?.name ?? '—'),
            const SizedBox(height: 12),
            TextField(
              controller: _capCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: isSw
                    ? 'Kiwango cha juu cha gharama (TZS, hiari)'
                    : 'Cost cap (TZS, optional)',
                helperText: isSw
                    ? 'Sitaki kuzidi hii bila kuniuliza'
                    : "Don't exceed without asking",
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      );

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 90,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value)),
        ]),
      );

  String _formatDateTime(DateTime dt) {
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '${dt.year}-$mm-$dd $hh:$mi';
  }
}
