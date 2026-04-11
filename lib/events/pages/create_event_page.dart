// lib/events/pages/create_event_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/event_enums.dart';
import '../models/event_strings.dart';
import '../models/event_template.dart';
import '../services/event_service.dart';
import '../widgets/event_type_selector.dart';
import '../widgets/person_picker_sheet.dart';
import 'emergency_create_page.dart';
import '../../services/local_storage_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

// ── Step key constants — must match EventTemplate.createSteps strings ──
const _kStepType = 'type_select'; // Step 0 — always present, not in template
const _kStepBasics = 'basics';
const _kStepDateTime = 'datetime';
const _kStepLocation = 'location';
const _kStepDetails = 'details';
const _kStepTickets = 'tickets';
const _kStepReview = 'review';
const _kStepKamati = 'kamati';
const _kStepMichango = 'michango';
const _kStepBajeti = 'bajeti';
const _kStepWageni = 'wageni';
const _kStepLinked = 'linked';


class CreateEventPage extends StatefulWidget {
  final int userId;
  const CreateEventPage({super.key, required this.userId});
  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final EventService _service = EventService();
  final PageController _pageController = PageController();
  late EventStrings _strings;

  // ── Step 0: template selection ──
  EventTemplateType? _selectedType;

  // Derived template — computed whenever _selectedType changes.
  EventTemplate? get _template =>
      _selectedType != null ? EventTemplateRegistry.getTemplate(_selectedType!) : null;

  // The ordered list of step keys for the current wizard.
  // Step 0 (type_select) is always index 0. Template steps follow.
  List<String> get _activeSteps {
    if (_selectedType == null) return [_kStepType];
    final templateSteps = _template!.createSteps;
    // Emergency templates go directly to EmergencyCreatePage — but if somehow
    // we land back here we still show a minimal review.
    return [_kStepType, ...templateSteps];
  }

  int _currentStep = 0;
  bool _isSubmitting = false;

  // ── Step basics ──
  final _nameController = TextEditingController();
  EventCategory _category = EventCategory.social;
  EventType _type = EventType.inPerson;
  String? _coverPhotoPath;

  // ── Step datetime ──
  DateTime _startDate = DateTime.now().add(const Duration(days: 7));
  DateTime? _endDate;
  TimeOfDay _startTime = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay? _endTime;
  bool _isAllDay = false;

  // ── Step location ──
  final _locationNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _onlineLinkController = TextEditingController();
  String? _onlinePlatform;

  // ── Step details ──
  final _descriptionController = TextEditingController();
  EventPrivacy _privacy = EventPrivacy.public;
  final _tagsController = TextEditingController();

  // ── Step tickets ──
  bool _isFree = true;
  final String _ticketCurrency = 'TZS';
  final List<_TierData> _tiers = [];
  bool _hasWaitlist = false;
  RefundPolicy _refundPolicy = RefundPolicy.noRefund;

  // ── Step kamati ──
  final List<String> _selectedSubCommittees = [];
  PickedPerson? _mwenyekiti;
  PickedPerson? _katibu;
  PickedPerson? _mhazini;
  final List<PickedPerson> _additionalMembers = [];

  // ── Step michango ──
  bool _enableMichango = true;
  final _michangoGoalController = TextEditingController();
  final List<String> _selectedContributorCategories = [];

  // ── Step bajeti ──
  bool _enableBajeti = true;
  final _totalBudgetController = TextEditingController();
  final Map<String, TextEditingController> _budgetCategoryControllers = {};

  // ── Step wageni ──
  bool _enableGuestCategories = true;
  bool _enableCardTracking = true;
  int _estimatedGuests = 100;

  // ── Step linked ──
  final List<Map<String, dynamic>> _linkedEvents = [];

  @override
  void initState() {
    super.initState();
    final lang = LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw';
    _strings = EventStrings(isSwahili: lang == 'sw');
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _locationNameController.dispose();
    _addressController.dispose();
    _onlineLinkController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    for (final tier in _tiers) {
      tier.nameController.dispose();
      tier.priceController.dispose();
      tier.quantityController.dispose();
    }
    _michangoGoalController.dispose();
    _totalBudgetController.dispose();
    for (final c in _budgetCategoryControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Helpers ──

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  int get _totalSteps => _activeSteps.length;

  String get _currentStepKey =>
      _currentStep < _activeSteps.length ? _activeSteps[_currentStep] : _kStepReview;

  bool get _isLastStep => _currentStep == _totalSteps - 1;

  // ── Navigation ──

  void _nextStep() {
    // Step 0 validation — must have selected a type.
    if (_currentStepKey == _kStepType) {
      if (_selectedType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _strings.isSwahili ? 'Chagua aina ya tukio' : 'Please select an event type',
            ),
          ),
        );
        return;
      }
      // Msiba: redirect to emergency flow.
      if (_selectedType == EventTemplateType.msiba) {
        _launchEmergencyFlow();
        return;
      }
    }

    // Basics validation: name required.
    if (_currentStepKey == _kStepBasics && _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_strings.isSwahili ? 'Jina linahitajika' : 'Name is required')),
      );
      return;
    }

    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _launchEmergencyFlow() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EmergencyCreatePage(userId: widget.userId),
      ),
    );
    if (mounted && result != null) {
      // EmergencyCreatePage already popped with the created event; we just close.
      Navigator.pop(context, result);
    }
    // If user came back without creating (tapped back), reset type selection.
    if (mounted && result == null) {
      setState(() => _selectedType = null);
    }
  }

  // ── Type selection handler ──
  void _onTypeSelected(EventTemplateType type) {
    setState(() {
      _selectedType = type;
      // Reset to step 0 so the PageView rebuilds with correct step count.
      _currentStep = 0;
    });

    if (type == EventTemplateType.msiba) {
      // Brief visual feedback, then launch emergency flow.
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _launchEmergencyFlow();
      });
    }
  }

  // ── Cover photo ──

  Future<void> _pickCover() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      imageQuality: 85,
    );
    if (file != null) setState(() => _coverPhotoPath = file.path);
  }

  // ── Date / Time pickers ──

  Future<void> _pickDate({bool isEnd = false}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isEnd ? (_endDate ?? _startDate) : _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) {
      setState(() {
        if (isEnd) {
          _endDate = picked;
        } else {
          _startDate = picked;
        }
      });
    }
  }

  Future<void> _pickTime({bool isEnd = false}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isEnd ? (_endTime ?? _startTime) : _startTime,
    );
    if (picked != null) {
      setState(() {
        if (isEnd) {
          _endTime = picked;
        } else {
          _startTime = picked;
        }
      });
    }
  }

  // ── Ticket tier management ──

  void _addTier() {
    setState(() {
      _tiers.add(_TierData(
        nameController: TextEditingController(),
        priceController: TextEditingController(),
        quantityController: TextEditingController(),
      ));
    });
  }

  void _removeTier(int index) {
    final tier = _tiers[index];
    tier.nameController.dispose();
    tier.priceController.dispose();
    tier.quantityController.dispose();
    setState(() => _tiers.removeAt(index));
  }

  // ── Submit ──

  Future<void> _submit({bool asDraft = false}) async {
    setState(() => _isSubmitting = true);
    final tags = _tagsController.text.trim().isNotEmpty
        ? _tagsController.text
            .trim()
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList()
        : <String>[];

    final result = await _service.createEvent(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _category,
      type: _type,
      startDate: _formatDate(_startDate),
      endDate: _endDate != null ? _formatDate(_endDate!) : null,
      startTime: _isAllDay ? null : _formatTime(_startTime),
      endTime: _isAllDay ? null : (_endTime != null ? _formatTime(_endTime!) : null),
      isAllDay: _isAllDay,
      privacy: _privacy,
      locationName: _locationNameController.text.trim().isNotEmpty
          ? _locationNameController.text.trim()
          : null,
      locationAddress: _addressController.text.trim().isNotEmpty
          ? _addressController.text.trim()
          : null,
      isOnline: _type == EventType.virtual || _type == EventType.hybrid,
      onlineLink: _onlineLinkController.text.trim().isNotEmpty
          ? _onlineLinkController.text.trim()
          : null,
      onlinePlatform: _onlinePlatform,
      isFree: _isFree,
      ticketCurrency: _ticketCurrency,
      hasWaitlist: _hasWaitlist,
      refundPolicy: _refundPolicy.apiValue,
      tags: tags,
      coverPhotoPath: _coverPhotoPath,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (result.success) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        messenger.showSnackBar(SnackBar(content: Text(_strings.eventCreated)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Error')),
        );
      }
    }
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final steps = _activeSteps;
    final stepNumber = _currentStep + 1;
    final totalDisplay = _totalSteps;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _kPrimary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _strings.createEvent,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Text(
              '${_strings.isSwahili ? "Hatua" : "Step"} $stepNumber / $totalDisplay',
              style: const TextStyle(fontSize: 12, color: _kSecondary),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Progress bar — adapts to dynamic step count ──
          LinearProgressIndicator(
            value: stepNumber / totalDisplay,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(_kPrimary),
            minHeight: 3,
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: steps.map((key) => _buildStepPage(key)).toList(),
            ),
          ),
          // ── Bottom navigation ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: _prevStep,
                      child: Text(
                        _strings.back,
                        style: const TextStyle(color: _kPrimary),
                      ),
                    ),
                  const Spacer(),
                  // Step 0 shows "Next" only after selection, otherwise "Choose"
                  if (_currentStepKey == _kStepType) ...[
                    ElevatedButton(
                      onPressed: _selectedType != null ? _nextStep : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        _strings.isSwahili ? 'Endelea' : 'Continue',
                      ),
                    ),
                  ] else if (!_isLastStep) ...[
                    ElevatedButton(
                      onPressed: _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(_strings.next),
                    ),
                  ] else ...[
                    TextButton(
                      onPressed: _isSubmitting ? null : () => _submit(asDraft: true),
                      child: Text(
                        _strings.saveAsDraft,
                        style: const TextStyle(color: _kSecondary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_strings.publishNow),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step dispatcher ──

  Widget _buildStepPage(String key) {
    switch (key) {
      case _kStepType:
        return _buildStep0TypeSelect();
      case _kStepBasics:
        return _buildStep1Basics();
      case _kStepDateTime:
        return _buildStep2DateTime();
      case _kStepLocation:
        return _buildStep3Location();
      case _kStepDetails:
        return _buildStep4Details();
      case _kStepTickets:
        return _buildStep5Ticketing();
      case _kStepReview:
        return _buildStep6Review();
      case _kStepKamati:
        return _buildStepKamati();
      case _kStepMichango:
        return _buildStepMichango();
      case _kStepBajeti:
        return _buildStepBajeti();
      case _kStepWageni:
        return _buildStepWageni();
      case _kStepLinked:
        return _buildStepLinked();
      default:
        return _buildStepPlaceholder(key);
    }
  }

  // ── Step 0: Event Type Selection ──

  Widget _buildStep0TypeSelect() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      children: [
        Text(
          _strings.isSwahili ? 'Aina gani ya tukio?' : 'What kind of event?',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _strings.isSwahili
              ? 'Chagua aina ili mfumo uendane na mahitaji yako.'
              : 'Choose a type so the wizard adapts to your needs.',
          style: const TextStyle(fontSize: 14, color: _kSecondary, height: 1.4),
        ),
        const SizedBox(height: 20),
        EventTypeSelector(
          selected: _selectedType,
          onSelected: _onTypeSelected,
        ),
      ],
    );
  }

  // ── Step: Kamati (Committee Setup) ──

  Widget _buildStepKamati() {
    final config = _template?.kamatiConfig ?? KamatiConfig.disabled;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          _strings.isSwahili ? 'Kamati ya Tukio' : 'Event Committee',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          _strings.isSwahili
              ? 'Teua viongozi na kamati ndogo'
              : 'Assign leaders and sub-committees',
          style: const TextStyle(fontSize: 13, color: _kSecondary),
        ),
        const SizedBox(height: 20),

        // Core roles — person picker
        Text(_strings.isSwahili ? 'Viongozi Wakuu' : 'Core Leaders',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
        const SizedBox(height: 10),
        _buildRolePickerTile(
          role: _strings.isSwahili ? 'Mwenyekiti' : 'Chairperson',
          subtitle: 'Chairperson',
          icon: Icons.star_rounded,
          person: _mwenyekiti,
          onPick: () => _pickPersonForRole('mwenyekiti'),
          onClear: () => setState(() => _mwenyekiti = null),
        ),
        const SizedBox(height: 8),
        _buildRolePickerTile(
          role: _strings.isSwahili ? 'Katibu' : 'Secretary',
          subtitle: 'Secretary',
          icon: Icons.edit_note_rounded,
          person: _katibu,
          onPick: () => _pickPersonForRole('katibu'),
          onClear: () => setState(() => _katibu = null),
        ),
        const SizedBox(height: 8),
        _buildRolePickerTile(
          role: _strings.isSwahili ? 'Mhazini' : 'Treasurer',
          subtitle: 'Treasurer',
          icon: Icons.account_balance_wallet_rounded,
          person: _mhazini,
          onPick: () => _pickPersonForRole('mhazini'),
          onClear: () => setState(() => _mhazini = null),
        ),

        // Additional members
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_strings.isSwahili ? 'Wajumbe Wengine' : 'Other Members',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
            TextButton.icon(
              onPressed: _pickAdditionalMember,
              icon: const Icon(Icons.person_add_rounded, size: 18),
              label: Text(_strings.isSwahili ? 'Ongeza' : 'Add'),
              style: TextButton.styleFrom(foregroundColor: _kPrimary),
            ),
          ],
        ),
        if (_additionalMembers.isNotEmpty) ...[
          const SizedBox(height: 4),
          ..._additionalMembers.asMap().entries.map((entry) => _buildMemberChip(entry.value, entry.key)),
        ],
        if (_additionalMembers.isEmpty)
          Text(
            _strings.isSwahili ? 'Bado hakuna wajumbe wengine' : 'No additional members yet',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          ),

        // Sub-committees
        if (config.hasSubCommittees && config.defaultSubCommittees.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(_strings.isSwahili ? 'Kamati Ndogo' : 'Sub-Committees',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 4),
          Text(
            _strings.isSwahili ? 'Chagua kamati ndogo zinazohitajika' : 'Select the sub-committees needed',
            style: const TextStyle(fontSize: 12, color: _kSecondary),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: config.defaultSubCommittees.map((name) {
              final isSelected = _selectedSubCommittees.contains(name);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedSubCommittees.remove(name);
                    } else {
                      _selectedSubCommittees.add(name);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? _kPrimary : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? _kPrimary : Colors.grey.shade300),
                  ),
                  child: Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : _kPrimary)),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  // ── Person picker helpers ──

  Future<void> _pickPersonForRole(String role) async {
    final picked = await showPersonPickerSheet(
      context,
      title: _strings.isSwahili ? 'Chagua $role' : 'Select $role',
      allowExternal: true,
    );
    if (picked != null && mounted) {
      setState(() {
        switch (role) {
          case 'mwenyekiti': _mwenyekiti = picked; break;
          case 'katibu': _katibu = picked; break;
          case 'mhazini': _mhazini = picked; break;
        }
      });
    }
  }

  Future<void> _pickAdditionalMember() async {
    final picked = await showPersonPickerSheet(
      context,
      title: _strings.isSwahili ? 'Ongeza Mjumbe' : 'Add Member',
      allowExternal: true,
    );
    if (picked != null && mounted) {
      // Avoid duplicates
      final isDuplicate = _additionalMembers.any((m) =>
          (m.userId != null && m.userId == picked.userId) ||
          (m.phone != null && m.phone == picked.phone && m.name == picked.name));
      if (!isDuplicate) {
        setState(() => _additionalMembers.add(picked));
      }
    }
  }

  Widget _buildRolePickerTile({
    required String role,
    required String subtitle,
    required IconData icon,
    required PickedPerson? person,
    required VoidCallback onPick,
    required VoidCallback onClear,
  }) {
    return GestureDetector(
      onTap: onPick,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: person != null ? _kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: person != null ? _kPrimary : Colors.grey.shade300),
        ),
        child: Row(
          children: [
            // Avatar or icon
            if (person?.avatarUrl != null)
              CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(person!.avatarUrl!),
              )
            else
              CircleAvatar(
                radius: 18,
                backgroundColor: person != null ? Colors.white.withValues(alpha: 0.2) : Colors.grey.shade100,
                child: person != null
                    ? Text(person.name.isNotEmpty ? person.name[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))
                    : Icon(icon, size: 18, color: _kSecondary),
              ),
            const SizedBox(width: 12),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person?.name ?? role,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: person != null ? Colors.white : _kPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    person != null
                        ? (person.isTajiriUser
                            ? '$subtitle · TAJIRI'
                            : '$subtitle · ${person.phone ?? (_strings.isSwahili ? "Nje ya TAJIRI" : "External")}')
                        : (_strings.isSwahili ? 'Bonyeza kuchagua' : 'Tap to select'),
                    style: TextStyle(
                      fontSize: 11,
                      color: person != null ? Colors.white70 : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),

            // Clear or select icon
            if (person != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close_rounded, size: 18, color: Colors.white70),
              )
            else
              Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberChip(PickedPerson person, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: person.avatarUrl != null ? NetworkImage(person.avatarUrl!) : null,
            child: person.avatarUrl == null
                ? Text(person.name.isNotEmpty ? person.name[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 12, color: _kSecondary))
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(person.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  person.isTajiriUser ? 'TAJIRI' : (person.phone ?? (_strings.isSwahili ? 'Nje ya TAJIRI' : 'External')),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _additionalMembers.removeAt(index)),
            child: Icon(Icons.close_rounded, size: 18, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  // ── Step: Michango (Contributions Setup) ──

  Widget _buildStepMichango() {
    final config = _template?.michangoConfig ?? MichangoConfig.disabled;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          _strings.isSwahili ? 'Michango' : 'Contributions',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          _strings.isSwahili
              ? 'Sanidi ukusanyaji wa michango'
              : 'Set up contribution collection',
          style: const TextStyle(fontSize: 13, color: _kSecondary),
        ),
        const SizedBox(height: 20),

        // Enable toggle
        SwitchListTile(
          title: Text(_strings.isSwahili ? 'Washa Michango' : 'Enable Contributions',
              style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w600)),
          subtitle: Text(config.collectionLabel, style: const TextStyle(fontSize: 12, color: _kSecondary)),
          value: _enableMichango,
          onChanged: (v) => setState(() => _enableMichango = v),
          activeColor: _kPrimary,
          contentPadding: EdgeInsets.zero,
        ),

        if (_enableMichango) ...[
          // Goal amount
          if (config.hasGoal) ...[
            const SizedBox(height: 12),
            _buildTextField(_michangoGoalController, _strings.isSwahili ? 'Lengo la Fedha (TZS)' : 'Fundraising Goal (TZS)', keyboard: TextInputType.number),
          ],

          // Contributor categories
          if (config.hasCategories && config.defaultCategories.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(_strings.isSwahili ? 'Makundi ya Wachanga' : 'Contributor Categories',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
            const SizedBox(height: 4),
            Text(
              _strings.isSwahili ? 'Chagua makundi yanayohusika' : 'Select applicable groups',
              style: const TextStyle(fontSize: 12, color: _kSecondary),
            ),
            const SizedBox(height: 10),
            ...config.defaultCategories.map((cat) {
              final isSelected = _selectedContributorCategories.contains(cat);
              return CheckboxListTile(
                title: Text(cat, style: const TextStyle(fontSize: 14, color: _kPrimary)),
                value: isSelected,
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _selectedContributorCategories.add(cat);
                    } else {
                      _selectedContributorCategories.remove(cat);
                    }
                  });
                },
                activeColor: _kPrimary,
                contentPadding: EdgeInsets.zero,
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
              );
            }),
          ],

          // Follow-up
          if (config.hasFollowUp) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_rounded, size: 20, color: _kSecondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _strings.isSwahili
                          ? 'Vikumbusho vya kiotomatiki vitatumwa kwa waliodhairi kulipa.'
                          : 'Automatic reminders will be sent for unpaid pledges.',
                      style: const TextStyle(fontSize: 12, color: _kSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // M-Pesa info
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.phone_android_rounded, size: 20, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _strings.isSwahili
                        ? 'M-Pesa, Tigo Pesa, na Airtel Money zitawashwa kiotomatiki.'
                        : 'M-Pesa, Tigo Pesa, and Airtel Money will be enabled automatically.',
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── Step: Bajeti (Budget Setup) ──

  Widget _buildStepBajeti() {
    final config = _template?.bajetiConfig ?? BajetiConfig.disabled;
    // Initialize category controllers if needed
    for (final cat in config.defaultCategories) {
      _budgetCategoryControllers.putIfAbsent(cat, () => TextEditingController());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          _strings.isSwahili ? 'Bajeti' : 'Budget',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          _strings.isSwahili ? 'Weka bajeti ya tukio' : 'Set your event budget',
          style: const TextStyle(fontSize: 13, color: _kSecondary),
        ),
        const SizedBox(height: 20),

        // Total budget
        _buildTextField(_totalBudgetController, _strings.isSwahili ? 'Bajeti Jumla (TZS)' : 'Total Budget (TZS)', keyboard: TextInputType.number),
        const SizedBox(height: 20),

        // Categories
        if (config.defaultCategories.isNotEmpty) ...[
          Text(_strings.isSwahili ? 'Mgawanyo wa Bajeti' : 'Budget Breakdown',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 4),
          Text(
            _strings.isSwahili ? 'Ingiza kiasi kwa kila kategoria' : 'Enter amount per category',
            style: const TextStyle(fontSize: 12, color: _kSecondary),
          ),
          const SizedBox(height: 12),
          ...config.defaultCategories.map((cat) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 120,
                  child: Text(cat, style: const TextStyle(fontSize: 13, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _budgetCategoryControllers[cat],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'TZS',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kPrimary)),
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],

        // Receipt capture info
        if (config.hasReceiptCapture) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_rounded, size: 20, color: _kSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _strings.isSwahili
                        ? 'Piga picha za risiti wakati wa kurekodi matumizi.'
                        : 'Capture receipt photos when logging expenses.',
                    style: const TextStyle(fontSize: 12, color: _kSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── Step: Wageni (Guest Setup) ──

  Widget _buildStepWageni() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          _strings.isSwahili ? 'Wageni' : 'Guests',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          _strings.isSwahili ? 'Sanidi usimamizi wa wageni' : 'Configure guest management',
          style: const TextStyle(fontSize: 13, color: _kSecondary),
        ),
        const SizedBox(height: 20),

        // Guest categories
        SwitchListTile(
          title: Text(_strings.isSwahili ? 'Makundi ya Wageni' : 'Guest Categories',
              style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w600)),
          subtitle: Text(
            _strings.isSwahili ? 'VIP, Ndugu, Wageni wa Kawaida' : 'VIP, Family, Regular',
            style: const TextStyle(fontSize: 12, color: _kSecondary),
          ),
          value: _enableGuestCategories,
          onChanged: (v) => setState(() => _enableGuestCategories = v),
          activeColor: _kPrimary,
          contentPadding: EdgeInsets.zero,
        ),

        // Invitation card tracking
        SwitchListTile(
          title: Text(_strings.isSwahili ? 'Ufuatiliaji wa Kadi' : 'Card Tracking',
              style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w600)),
          subtitle: Text(
            _strings.isSwahili
                ? 'Fuatilia kadi zilizochapishwa, kusambazwa, kupokelewa'
                : 'Track cards printed, delivered, confirmed',
            style: const TextStyle(fontSize: 12, color: _kSecondary),
          ),
          value: _enableCardTracking,
          onChanged: (v) => setState(() => _enableCardTracking = v),
          activeColor: _kPrimary,
          contentPadding: EdgeInsets.zero,
        ),

        const SizedBox(height: 16),

        // Estimated guest count
        Text(_strings.isSwahili ? 'Wageni Wanaotarajiwa' : 'Expected Guests',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _estimatedGuests.toDouble(),
                min: 10,
                max: 2000,
                divisions: 199,
                activeColor: _kPrimary,
                inactiveColor: Colors.grey.shade200,
                onChanged: (v) => setState(() => _estimatedGuests = v.round()),
              ),
            ),
            Container(
              width: 60,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(8)),
              child: Text('$_estimatedGuests', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _strings.isSwahili
              ? 'Chakula kitaandaliwa kwa wageni ${(_estimatedGuests * 1.3).round()} (buffer ya 30%)'
              : 'Food will be prepared for ${(_estimatedGuests * 1.3).round()} guests (30% buffer)',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
        ),

        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              const Icon(Icons.group_add_rounded, size: 20, color: _kSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _strings.isSwahili
                      ? 'Utaweza kuongeza wageni kutoka marafiki, watu, na anwani za simu baada ya kuunda.'
                      : 'You can add guests from friends, people search, and phone contacts after creating.',
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Step: Linked Events ──

  Widget _buildStepLinked() {
    // Determine defaults based on template type
    final defaults = _selectedType == EventTemplateType.harusi
        ? [
            {'name': 'Kitchen Party', 'sub_type': 'kitchen_party'},
            {'name': 'Send-off', 'sub_type': 'send_off'},
            {'name': 'Kupamba', 'sub_type': 'kupamba'},
            {'name': 'Kesha', 'sub_type': 'kesha'},
          ]
        : <Map<String, String>>[];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          _strings.isSwahili ? 'Matukio Yanayohusiana' : 'Linked Events',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          _strings.isSwahili
              ? 'Ongeza matukio yanayohusiana (mfano: Kitchen Party, Kupamba)'
              : 'Add related events (e.g., Kitchen Party, Kupamba)',
          style: const TextStyle(fontSize: 13, color: _kSecondary),
        ),
        const SizedBox(height: 20),

        // Suggested linked events
        if (defaults.isNotEmpty) ...[
          Text(_strings.isSwahili ? 'Mapendekezo' : 'Suggestions',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 10),
          ...defaults.map((d) {
            final isAdded = _linkedEvents.any((e) => e['sub_type'] == d['sub_type']);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isAdded ? _kPrimary : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isAdded ? _kPrimary : Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(
                    isAdded ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                    size: 22,
                    color: isAdded ? Colors.white : _kSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d['name']!, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isAdded ? Colors.white : _kPrimary)),
                        Text(
                          d['sub_type']!.replaceAll('_', ' '),
                          style: TextStyle(fontSize: 12, color: isAdded ? Colors.white70 : _kSecondary),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isAdded) {
                          _linkedEvents.removeWhere((e) => e['sub_type'] == d['sub_type']);
                        } else {
                          _linkedEvents.add({'name': d['name']!, 'sub_type': d['sub_type']!});
                        }
                      });
                    },
                    child: Text(
                      isAdded
                          ? (_strings.isSwahili ? 'Ondoa' : 'Remove')
                          : (_strings.isSwahili ? 'Ongeza' : 'Add'),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isAdded ? Colors.white : _kPrimary),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],

        // Info
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 20, color: _kSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _strings.isSwahili
                      ? 'Matukio yanayohusiana yatashiriki kamati na orodha ya wageni.'
                      : 'Linked events will share committee and guest list.',
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Step placeholder (template step without a dedicated screen) ──

  Widget _buildStepPlaceholder(String key) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.build_circle_rounded, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              key.replaceAll('_', ' ').toUpperCase(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _kSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _strings.isSwahili
                  ? 'Hatua hii itakamilika hivi karibuni.'
                  : 'This step will be available soon.',
              style: const TextStyle(fontSize: 13, color: _kSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 1: Basics ──

  Widget _buildStep1Basics() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Cover photo picker
        GestureDetector(
          onTap: _pickCover,
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              image: _coverPhotoPath != null
                  ? DecorationImage(
                      image: FileImage(File(_coverPhotoPath!)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _coverPhotoPath == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_rounded,
                          size: 40, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        _strings.coverPhoto,
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      ),
                    ],
                  )
                : null,
          ),
        ),
        const SizedBox(height: 16),
        _buildTextField(_nameController, _strings.eventName, required: true),
        const SizedBox(height: 16),
        Text(
          _strings.category,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: EventCategory.values.take(12).map((cat) {
            final isSelected = cat == _category;
            return GestureDetector(
              onTap: () => setState(() => _category = cat),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? _kPrimary : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(cat.icon, size: 16, color: isSelected ? Colors.white : _kSecondary),
                    const SizedBox(width: 6),
                    Text(
                      cat.displayName,
                      style: TextStyle(
                        fontSize: 13,
                        color: isSelected ? Colors.white : _kSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Text(
          _strings.isSwahili ? 'Aina ya Tukio' : 'Event Type',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
        ),
        const SizedBox(height: 8),
        Row(
          children: EventType.values.map((t) {
            final isSelected = t == _type;
            final isLast = t == EventType.hybrid;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: isLast ? 0 : 8),
                child: GestureDetector(
                  onTap: () => setState(() => _type = t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? _kPrimary : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(t.icon, size: 22, color: isSelected ? Colors.white : _kSecondary),
                        const SizedBox(height: 4),
                        Text(
                          t.displayName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : _kSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Step 2: Date & Time ──

  Widget _buildStep2DateTime() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildDatePicker(_strings.startDate, _startDate, () => _pickDate()),
        const SizedBox(height: 12),
        if (!_isAllDay) ...[
          _buildTimePicker(_strings.startTime, _startTime, () => _pickTime()),
          const SizedBox(height: 12),
        ],
        _buildDatePicker(
          _strings.endDate,
          _endDate,
          () => _pickDate(isEnd: true),
          optional: true,
        ),
        const SizedBox(height: 12),
        if (!_isAllDay && _endDate != null) ...[
          _buildTimePicker(
            _strings.endTime,
            _endTime,
            () => _pickTime(isEnd: true),
            optional: true,
          ),
          const SizedBox(height: 12),
        ],
        SwitchListTile(
          title: Text(_strings.allDay, style: const TextStyle(color: _kPrimary)),
          value: _isAllDay,
          onChanged: (v) => setState(() => _isAllDay = v),
          activeColor: _kPrimary,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  // ── Step 3: Location ──

  Widget _buildStep3Location() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_type == EventType.inPerson || _type == EventType.hybrid) ...[
          _buildTextField(_locationNameController, _strings.location),
          const SizedBox(height: 12),
          _buildTextField(_addressController, _strings.address),
          const SizedBox(height: 16),
        ],
        if (_type == EventType.virtual || _type == EventType.hybrid) ...[
          Text(
            _strings.onlineLink,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
          ),
          const SizedBox(height: 8),
          _buildTextField(_onlineLinkController, 'https://...'),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _onlinePlatform,
            decoration: _inputDecoration(_strings.isSwahili ? 'Jukwaa' : 'Platform'),
            items: ['zoom', 'google_meet', 'tajiri_live', 'other']
                .map((p) => DropdownMenuItem(
                      value: p,
                      child: Text(p.replaceAll('_', ' ').toUpperCase()),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _onlinePlatform = v),
          ),
        ],
      ],
    );
  }

  // ── Step 4: Details ──

  Widget _buildStep4Details() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextFormField(
          controller: _descriptionController,
          maxLines: 6,
          decoration: _inputDecoration(_strings.description),
        ),
        const SizedBox(height: 16),
        Text(
          _strings.privacy,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
        ),
        const SizedBox(height: 8),
        ...EventPrivacy.values.map((p) => RadioListTile<EventPrivacy>(
              title: Text(p.displayName, style: const TextStyle(fontSize: 14)),
              subtitle: Text(p.subtitle, style: const TextStyle(fontSize: 12, color: _kSecondary)),
              value: p,
              groupValue: _privacy,
              onChanged: (v) => setState(() => _privacy = v!),
              activeColor: _kPrimary,
              contentPadding: EdgeInsets.zero,
              dense: true,
            )),
        const SizedBox(height: 12),
        _buildTextField(
          _tagsController,
          _strings.isSwahili ? 'Tagi (tenganisha kwa comma)' : 'Tags (comma separated)',
        ),
      ],
    );
  }

  // ── Step 5: Ticketing ──

  Widget _buildStep5Ticketing() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          title: Text(
            _strings.freeEvent,
            style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w600),
          ),
          value: _isFree,
          onChanged: (v) => setState(() => _isFree = v),
          activeColor: _kPrimary,
          contentPadding: EdgeInsets.zero,
        ),
        if (!_isFree) ...[
          const SizedBox(height: 12),
          ..._tiers.asMap().entries.map((entry) => _buildTierCard(entry.key, entry.value)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _addTier,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(_strings.addTicketTier),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kPrimary,
              side: const BorderSide(color: _kPrimary),
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(
              _strings.isSwahili ? 'Orodha ya Kusubiri' : 'Waitlist',
              style: const TextStyle(color: _kPrimary),
            ),
            value: _hasWaitlist,
            onChanged: (v) => setState(() => _hasWaitlist = v),
            activeColor: _kPrimary,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<RefundPolicy>(
            value: _refundPolicy,
            decoration: _inputDecoration(
              _strings.isSwahili ? 'Sera ya Kurudisha' : 'Refund Policy',
            ),
            items: RefundPolicy.values
                .map((p) => DropdownMenuItem(
                      value: p,
                      child: Text('${p.displayName} / ${p.subtitle}'),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _refundPolicy = v!),
          ),
        ],
      ],
    );
  }

  Widget _buildTierCard(int index, _TierData tier) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '${_strings.isSwahili ? "Aina" : "Tier"} ${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.w600, color: _kPrimary),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () => _removeTier(index),
              ),
            ],
          ),
          _buildTextField(tier.nameController, _strings.tierName),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  tier.priceController,
                  _strings.price,
                  keyboard: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTextField(
                  tier.quantityController,
                  _strings.totalTickets,
                  keyboard: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Step 6: Review ──

  Widget _buildStep6Review() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_coverPhotoPath != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(_coverPhotoPath!),
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        const SizedBox(height: 16),
        Text(
          _nameController.text,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _kPrimary),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        if (_selectedType != null)
          _reviewRow(
            _strings.isSwahili ? 'Aina ya Tukio' : 'Event Type',
            _selectedType!.displayName,
          ),
        _reviewRow(_strings.category, _category.displayName),
        _reviewRow(_strings.isSwahili ? 'Aina' : 'Type', _type.displayName),
        _reviewRow(_strings.startDate, _strings.formatDate(_startDate)),
        if (!_isAllDay) _reviewRow(_strings.startTime, _formatTime(_startTime)),
        if (_locationNameController.text.isNotEmpty)
          _reviewRow(_strings.location, _locationNameController.text),
        _reviewRow(_strings.privacy, _privacy.displayName),
        _reviewRow(
          _strings.isSwahili ? 'Bei' : 'Price',
          _isFree
              ? _strings.free
              : '${_tiers.length} ${_strings.isSwahili ? "aina" : "tiers"}',
        ),
        // Pillar summaries
        if (_mwenyekiti != null)
          _reviewRow('Mwenyekiti', _mwenyekiti!.name),
        if (_katibu != null)
          _reviewRow('Katibu', _katibu!.name),
        if (_mhazini != null)
          _reviewRow('Mhazini', _mhazini!.name),
        if (_additionalMembers.isNotEmpty)
          _reviewRow(
            _strings.isSwahili ? 'Wajumbe' : 'Members',
            '${_additionalMembers.length + (_mwenyekiti != null ? 1 : 0) + (_katibu != null ? 1 : 0) + (_mhazini != null ? 1 : 0)} ${_strings.isSwahili ? "watu" : "people"}',
          ),
        if (_selectedSubCommittees.isNotEmpty)
          _reviewRow(
            _strings.isSwahili ? 'Kamati Ndogo' : 'Sub-Committees',
            '${_selectedSubCommittees.length} ${_strings.isSwahili ? "kamati" : "committees"}',
          ),
        if (_enableMichango && _michangoGoalController.text.isNotEmpty)
          _reviewRow(
            _strings.isSwahili ? 'Lengo la Michango' : 'Contribution Goal',
            'TZS ${_michangoGoalController.text}',
          ),
        if (_enableBajeti && _totalBudgetController.text.isNotEmpty)
          _reviewRow(
            _strings.isSwahili ? 'Bajeti' : 'Budget',
            'TZS ${_totalBudgetController.text}',
          ),
        if (_estimatedGuests > 0 && _template?.hasGuestCategories == true)
          _reviewRow(
            _strings.isSwahili ? 'Wageni Wanaotarajiwa' : 'Expected Guests',
            '$_estimatedGuests',
          ),
        if (_linkedEvents.isNotEmpty)
          _reviewRow(
            _strings.isSwahili ? 'Matukio Yanayohusiana' : 'Linked Events',
            _linkedEvents.map((e) => e['name']).join(', '),
          ),
        const SizedBox(height: 16),
        if (_descriptionController.text.isNotEmpty) ...[
          Text(
            _strings.description,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            _descriptionController.text,
            style: const TextStyle(fontSize: 13, color: _kSecondary, height: 1.5),
          ),
        ],
      ],
    );
  }

  // ── Shared Widgets ──

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 13, color: _kSecondary)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool required = false,
    TextInputType? keyboard,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      decoration: _inputDecoration('$label${required ? " *" : ""}'),
    );
  }

  Widget _buildDatePicker(
    String label,
    DateTime? date,
    VoidCallback onTap, {
    bool optional = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, size: 18, color: _kSecondary),
            const SizedBox(width: 10),
            Text(
              date != null
                  ? _strings.formatDateShort(date)
                  : '$label${optional ? " (${_strings.isSwahili ? "hiari" : "optional"})" : ""}',
              style: TextStyle(color: date != null ? _kPrimary : Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(
    String label,
    TimeOfDay? time,
    VoidCallback onTap, {
    bool optional = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time_rounded, size: 18, color: _kSecondary),
            const SizedBox(width: 10),
            Text(
              time != null
                  ? _formatTime(time)
                  : '$label${optional ? " (${_strings.isSwahili ? "hiari" : "optional"})" : ""}',
              style: TextStyle(color: time != null ? _kPrimary : Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _kSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kPrimary),
      ),
    );
  }
}

class _TierData {
  final TextEditingController nameController;
  final TextEditingController priceController;
  final TextEditingController quantityController;

  _TierData({
    required this.nameController,
    required this.priceController,
    required this.quantityController,
  });
}
