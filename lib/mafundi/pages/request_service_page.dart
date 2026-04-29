import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../../config/api_config.dart';
import '../../tajirika/models/tajirika_models.dart' show SkillCategory, TajirikaPartner;
import '../../tajirika/services/tajirika_service.dart';
import '../models/service_request.dart';
import '../services/service_request_service.dart';

class RequestServicePage extends StatefulWidget {
  final int userId;
  final SkillCategory? preselectedSkill;

  const RequestServicePage({
    super.key,
    required this.userId,
    this.preselectedSkill,
  });

  @override
  State<RequestServicePage> createState() => _RequestServicePageState();
}

class _RequestServicePageState extends State<RequestServicePage> {
  static const int _maxPhotos = 4;
  static const int _minSummary = 20;
  static const int _maxSummary = 500;
  static const List<SkillCategory> _allowedSkills = [
    SkillCategory.plumbing,
    SkillCategory.electrical,
    SkillCategory.painting,
    SkillCategory.roofing,
    SkillCategory.solarInstallation,
  ];

  int _step = 0;
  SkillCategory? _skill;
  final _summaryCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final List<String> _uploadedPhotos = [];
  bool _uploading = false;
  ServiceRequestWindow _window = ServiceRequestWindow.todayPm;
  bool _submitting = false;
  String? _addressError;
  String? _summaryError;

  /// Spec line 401 — direct request to a specific fundi (Step 6). When null,
  /// the request goes to the open marketplace.
  TajirikaPartner? _targetPartner;
  bool _loadingPartners = false;
  List<TajirikaPartner> _partners = const [];

  bool get _isSwahili =>
      AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _skill = widget.preselectedSkill;
    _prefillAddress();
  }

  Future<void> _prefillAddress() async {
    try {
      final storage = await LocalStorageService.getInstance();
      final user = storage.getUser();
      final addr = user?.location?.displayAddress ?? '';
      if (addr.trim().isNotEmpty && mounted) {
        setState(() => _addressCtrl.text = addr);
      }
    } catch (_) {
      // Best-effort prefill; user can type manually.
    }
  }

  @override
  void dispose() {
    _summaryCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _addPhoto() async {
    if (_uploadedPhotos.length >= _maxPhotos) {
      _toast(_isSwahili
          ? 'Picha zaidi ya $_maxPhotos haziruhusiwi'
          : 'Maximum $_maxPhotos photos');
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
      final res = await ServiceRequestService.uploadPhoto(
        userId: widget.userId,
        file: File(picked.path),
      );
      if (!mounted) return;
      setState(() => _uploading = false);
      if (res.success && (res.photoUrl ?? '').isNotEmpty) {
        setState(() => _uploadedPhotos.add(res.photoUrl!));
      } else {
        _toast(res.message ??
            (_isSwahili ? 'Picha imeshindikana' : 'Upload failed'));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      _toast(_isSwahili ? 'Kosa: $e' : 'Error: $e');
    }
  }

  void _removePhoto(int i) {
    setState(() => _uploadedPhotos.removeAt(i));
  }

  bool _validateStep(int step) {
    switch (step) {
      case 0:
        return _skill != null;
      case 1:
        final t = _summaryCtrl.text.trim();
        if (t.length < _minSummary) {
          setState(() => _summaryError = _isSwahili
              ? 'Andika angalau herufi $_minSummary'
              : 'At least $_minSummary characters');
          return false;
        }
        if (t.length > _maxSummary) {
          setState(() => _summaryError = _isSwahili
              ? 'Punguza hadi herufi $_maxSummary'
              : 'Maximum $_maxSummary characters');
          return false;
        }
        setState(() => _summaryError = null);
        return true;
      case 2:
        return true; // photos optional
      case 3:
        if (_addressCtrl.text.trim().isEmpty) {
          setState(() => _addressError = _isSwahili
              ? 'Andika anwani ya kufanyia kazi'
              : 'Enter the work address');
          return false;
        }
        setState(() => _addressError = null);
        return true;
      case 4:
        return true;
      case 5:
        return true;
    }
    return true;
  }

  Future<void> _submit() async {
    for (var i = 0; i <= 5; i++) {
      if (!_validateStep(i)) {
        setState(() => _step = i);
        return;
      }
    }
    setState(() => _submitting = true);
    final res = await ServiceRequestService.create(
      userId: widget.userId,
      skillCategory: _skill!.name,
      problemSummary: _summaryCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      preferredWindow: _window,
      photos: List<String>.from(_uploadedPhotos),
      targetPartnerUserId: _targetPartner?.userId,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res.success && res.request != null) {
      _toast(_isSwahili
          ? 'Ombi limewekwa. Mafundi watajibu hivi karibuni.'
          : 'Request posted. Pros will respond shortly.');
      Navigator.of(context).pop(res.request);
    } else {
      _toast(res.message ??
          (_isSwahili ? 'Imeshindikana kutuma' : 'Failed to submit'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSw = _isSwahili;
    return Scaffold(
      appBar: AppBar(
        title: Text(isSw ? 'Ita Fundi' : 'Request a Pro'),
      ),
      body: SafeArea(
        child: Stepper(
          type: StepperType.vertical,
          currentStep: _step,
          onStepTapped: (i) => setState(() => _step = i),
          onStepContinue: () {
            if (!_validateStep(_step)) return;
            if (_step < 6) {
              setState(() => _step += 1);
            } else {
              _submit();
            }
          },
          onStepCancel: () {
            if (_step > 0) setState(() => _step -= 1);
          },
          controlsBuilder: (context, details) {
            final isLast = _step == 6;
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  FilledButton(
                    onPressed: _submitting ? null : details.onStepContinue,
                    child: _submitting && isLast
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(isLast
                            ? (isSw ? 'Tuma Ombi' : 'Send Request')
                            : (isSw ? 'Endelea' : 'Continue')),
                  ),
                  const SizedBox(width: 12),
                  if (_step > 0)
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: Text(isSw ? 'Rudi' : 'Back'),
                    ),
                ],
              ),
            );
          },
          steps: [
            _stepSkill(isSw),
            _stepSummary(isSw),
            _stepPhotos(isSw),
            _stepAddress(isSw),
            _stepWindow(isSw),
            _stepPartnerPick(isSw),
            _stepReview(isSw),
          ],
        ),
      ),
    );
  }

  Step _stepSkill(bool isSw) {
    return Step(
      title: Text(isSw ? 'Aina ya kazi' : 'Service type'),
      isActive: _step >= 0,
      state: _skill != null && _step > 0
          ? StepState.complete
          : StepState.indexed,
      content: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _allowedSkills.map((s) {
          final selected = _skill == s;
          return ChoiceChip(
            label: Text(isSw ? s.labelSwahili : s.label),
            avatar: Icon(s.icon, size: 18),
            selected: selected,
            onSelected: (_) => setState(() => _skill = s),
          );
        }).toList(),
      ),
    );
  }

  Step _stepSummary(bool isSw) {
    return Step(
      title: Text(isSw ? 'Eleza tatizo' : 'Describe the problem'),
      isActive: _step >= 1,
      state: _summaryCtrl.text.trim().length >= _minSummary && _step > 1
          ? StepState.complete
          : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _summaryCtrl,
            maxLines: 5,
            maxLength: _maxSummary,
            onChanged: (_) {
              if (_summaryError != null) {
                setState(() => _summaryError = null);
              }
            },
            decoration: InputDecoration(
              hintText: isSw
                  ? 'Mfano: Bomba inavuja chini ya sinki jikoni…'
                  : 'e.g. Pipe leaking under kitchen sink…',
              errorText: _summaryError,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Step _stepPhotos(bool isSw) {
    return Step(
      title: Text(isSw
          ? 'Picha za tatizo (zinazohitajika)'
          : 'Problem photos (recommended)'),
      isActive: _step >= 2,
      state: _step > 2 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isSw
                ? 'Picha zinasaidia mafundi kutoa bei sahihi. Hadi $_maxPhotos.'
                : 'Photos help pros quote accurately. Up to $_maxPhotos.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._uploadedPhotos.asMap().entries.map((e) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        e.value,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 80,
                          height: 80,
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          child: const Icon(Icons.broken_image_rounded),
                        ),
                      ),
                    ),
                    Positioned(
                      top: -4,
                      right: -4,
                      child: IconButton(
                        icon: const Icon(Icons.cancel_rounded, size: 20),
                        onPressed: () => _removePhoto(e.key),
                      ),
                    ),
                  ],
                );
              }),
              if (_uploadedPhotos.length < _maxPhotos)
                InkWell(
                  onTap: _uploading ? null : _addPhoto,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                      ),
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
  }

  Step _stepAddress(bool isSw) {
    return Step(
      title: Text(isSw ? 'Anwani' : 'Address'),
      isActive: _step >= 3,
      state: _addressCtrl.text.trim().isNotEmpty && _step > 3
          ? StepState.complete
          : StepState.indexed,
      content: TextField(
        controller: _addressCtrl,
        onChanged: (_) {
          if (_addressError != null) {
            setState(() => _addressError = null);
          }
        },
        decoration: InputDecoration(
          hintText: isSw
              ? 'Mfano: Mikocheni B, mtaa wa Senga'
              : 'e.g. Mikocheni B, Senga street',
          errorText: _addressError,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.location_on_rounded),
        ),
      ),
    );
  }

  Step _stepWindow(bool isSw) {
    return Step(
      title: Text(isSw ? 'Muda unaopendekeza' : 'Preferred window'),
      isActive: _step >= 4,
      state: _step > 4 ? StepState.complete : StepState.indexed,
      content: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: ServiceRequestWindow.values.map((w) {
          final selected = _window == w;
          return ChoiceChip(
            label: Text(isSw ? w.labelSwahili : w.label),
            selected: selected,
            onSelected: (_) => setState(() => _window = w),
          );
        }).toList(),
      ),
    );
  }

  /// Spec line 401 — Step 6: pick a specific fundi or send to open marketplace.
  Step _stepPartnerPick(bool isSw) {
    return Step(
      title: Text(isSw ? 'Tuma kwa nani?' : 'Send to whom?'),
      isActive: _step >= 5,
      state: _step > 5 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              _targetPartner == null ? Icons.radio_button_checked : Icons.radio_button_off,
              color: _targetPartner == null ? const Color(0xFF1A1A1A) : null,
            ),
            title: Text(isSw ? 'Soko huru (mafundi wengi)' : 'Open marketplace'),
            subtitle: Text(
              isSw
                  ? 'Mafundi wengi wataona ombi na watatuma bei zao.'
                  : 'Multiple pros see the request and send quotes.',
              style: const TextStyle(fontSize: 11),
            ),
            onTap: () => setState(() => _targetPartner = null),
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              _targetPartner != null ? Icons.radio_button_checked : Icons.radio_button_off,
              color: _targetPartner != null ? const Color(0xFF1A1A1A) : null,
            ),
            title: Text(isSw ? 'Mfundi maalum' : 'Specific partner'),
            subtitle: Text(
              _targetPartner == null
                  ? (isSw ? 'Tafuta na chagua' : 'Search and pick')
                  : _targetPartner!.name,
              style: const TextStyle(fontSize: 11),
            ),
            trailing: const Icon(Icons.search_rounded),
            onTap: _pickSpecificPartner,
          ),
        ],
      ),
    );
  }

  Future<void> _pickSpecificPartner() async {
    if (_skill == null) return;
    if (_partners.isEmpty && !_loadingPartners) {
      setState(() => _loadingPartners = true);
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken() ?? '';
      final list = await TajirikaService.searchPartners(token, skills: [_skill!.name]);
      if (!mounted) return;
      setState(() {
        _partners = list;
        _loadingPartners = false;
      });
    }
    if (!mounted) return;
    final picked = await showModalBottomSheet<TajirikaPartner?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (_, scrollCtrl) => Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                _isSwahili ? 'Chagua fundi' : 'Pick a partner',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (_partners.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _isSwahili
                        ? 'Hakuna mafundi waliosajiliwa kwa ujuzi huu bado.'
                        : 'No partners registered for this skill yet.',
                    textAlign: TextAlign.center,
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  itemCount: _partners.length,
                  itemBuilder: (_, i) {
                    final p = _partners[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: p.photoUrl.isNotEmpty
                            ? NetworkImage(ApiConfig.sanitizeUrl(p.photoUrl) ?? p.photoUrl)
                            : null,
                        child: p.photoUrl.isEmpty ? const Icon(Icons.person_rounded) : null,
                      ),
                      title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        '${p.aggregateRating.toStringAsFixed(1)}★ • ${p.jobsCompleted} ${_isSwahili ? "kazi" : "jobs"}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => Navigator.pop(context, p),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null && mounted) {
      setState(() => _targetPartner = picked);
    }
  }

  Step _stepReview(bool isSw) {
    final skillLabel = _skill == null
        ? '—'
        : (isSw ? _skill!.labelSwahili : _skill!.label);
    return Step(
      title: Text(isSw ? 'Hakiki na tuma' : 'Review and send'),
      isActive: _step >= 5,
      state: StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _reviewRow(isSw ? 'Aina' : 'Service', skillLabel),
          _reviewRow(
            isSw ? 'Tatizo' : 'Problem',
            _summaryCtrl.text.trim(),
            multiline: true,
          ),
          _reviewRow(
            isSw ? 'Picha' : 'Photos',
            '${_uploadedPhotos.length}',
          ),
          _reviewRow(isSw ? 'Anwani' : 'Address', _addressCtrl.text.trim()),
          _reviewRow(
            isSw ? 'Muda' : 'Window',
            isSw ? _window.labelSwahili : _window.label,
          ),
          const SizedBox(height: 8),
          Text(
            isSw
                ? 'Ombi litaonekana kwa mafundi karibu nawe. Watawasilisha bei zao.'
                : 'Your request will be visible to nearby pros. They will send their quotes.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _reviewRow(String label, String value, {bool multiline = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              maxLines: multiline ? 4 : 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
