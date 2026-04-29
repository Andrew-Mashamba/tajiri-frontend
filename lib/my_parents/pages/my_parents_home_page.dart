// lib/my_parents/pages/my_parents_home_page.dart
import 'package:flutter/material.dart';
import '../../community/community_module.dart';
import '../../l10n/app_strings_scope.dart';
import '../../my_family/services/my_family_service.dart';
import '../../services/event_service.dart';
import '../../services/local_storage_service.dart';
import '../models/my_parents_models.dart';
import '../services/my_parents_service.dart';
import '../services/parents_notification_helper.dart';
import 'parent_dashboard_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class MyParentsHomePage extends StatefulWidget {
  final int userId;
  const MyParentsHomePage({super.key, required this.userId});
  @override
  State<MyParentsHomePage> createState() => _MyParentsHomePageState();
}

class _MyParentsHomePageState extends State<MyParentsHomePage> {
  final MyParentsService _service = MyParentsService();

  bool _isLoading = true;
  List<Parent> _parents = [];
  String? _token;
  bool _hasSynced = false;

  bool get _isSwahili =>
      AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    _token = LocalStorageService.instanceSync?.getAuthToken();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_token == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await _service.getMyParents(_token!, widget.userId);
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (result.success) {
            _parents = result.items;
            if (!_hasSynced) {
              _hasSynced = true;
              _syncParentsToFamily();
              _scheduleBirthdayReminders();
              _scheduleNhifRenewalReminders();
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isSwahili
              ? 'Imeshindikana kupakia wazazi'
              : 'Failed to load parents')),
        );
      }
    }
  }

  /// Fire-and-forget: sync parents to the Family module.
  Future<void> _syncParentsToFamily() async {
    try {
      final familyService = MyFamilyService();
      for (final parent in _parents) {
        await familyService.addMember(
          userId: widget.userId,
          name: parent.name,
          relationship: parent.relationship,
          gender: parent.gender ?? 'unknown',
          dateOfBirth: '${parent.dateOfBirth.year}-${parent.dateOfBirth.month.toString().padLeft(2, '0')}-${parent.dateOfBirth.day.toString().padLeft(2, '0')}',
          bloodType: parent.bloodType,
          chronicConditions: parent.chronicConditions.isNotEmpty ? parent.chronicConditions : null,
          allergies: parent.allergies.isNotEmpty ? parent.allergies : null,
          nhifNumber: parent.nhifNumber,
        );
      }
    } catch (_) {
      // Family sync is best-effort — never block the UI.
    }
  }

  /// Fire-and-forget: schedule birthday reminders for parents.
  Future<void> _scheduleBirthdayReminders() async {
    try {
      final eventService = EventService();
      for (final parent in _parents) {
        final nextBday = _nextBirthday(parent.dateOfBirth);
        await eventService.createEvent(
          creatorId: widget.userId,
          name: '${parent.name} Birthday',
          startDate: nextBday,
          isAllDay: true,
          privacy: 'private',
        );
      }
    } catch (_) {
      // Calendar sync is best-effort — never block the UI.
    }
  }

  /// Fire-and-forget: schedule NHIF renewal reminders for parents with NHIF.
  void _scheduleNhifRenewalReminders() {
    final sw = _isSwahili;
    for (final parent in _parents) {
      if (parent.nhifNumber != null && parent.nhifNumber!.isNotEmpty) {
        try {
          // NHIF is annual. Since we don't have the actual expiry date in the model,
          // schedule for 11 months from now as a fallback.
          final expiryFallback = DateTime.now().add(const Duration(days: 335));
          ParentsNotificationHelper.scheduleNhifRenewalReminder(
            parent.id,
            parent.name,
            expiryFallback,
            sw,
          );
        } catch (_) {}
      }
    }
  }

  DateTime _nextBirthday(DateTime dob) {
    final now = DateTime.now();
    var next = DateTime(now.year, dob.month, dob.day);
    if (next.isBefore(now)) next = DateTime(now.year + 1, dob.month, dob.day);
    return next;
  }

  int _computeAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) age--;
    return age < 0 ? 0 : age;
  }

  // ─── Options bottom sheet (long-press) ────────────────────────

  void _showParentOptionsSheet(Parent parent) {
    final sw = _isSwahili;
    showModalBottomSheet(
      context: context,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Text(
                  parent.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.edit_rounded, color: _kPrimary),
                  title: Text(sw ? 'Hariri Mzazi' : 'Edit Parent',
                    style: const TextStyle(fontSize: 15, color: _kPrimary)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showEditParentSheet(parent);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_rounded, color: Colors.red),
                  title: Text(sw ? 'Ondoa Mzazi' : 'Delete Parent',
                    style: const TextStyle(fontSize: 15, color: Colors.red)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmDeleteParent(parent);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Delete confirmation ──────────────────────────────────────

  void _confirmDeleteParent(Parent parent) {
    final sw = _isSwahili;
    showDialog(
      context: context,
      builder: (ctx) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Text(
                sw ? 'Ondoa Mzazi' : 'Delete Parent',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _kPrimary),
              ),
              content: Text(
                sw
                    ? 'Una uhakika unataka kuondoa ${parent.name}? Hatua hii haiwezi kutenduliwa.'
                    : 'Are you sure you want to delete ${parent.name}? This action cannot be undone.',
                style: const TextStyle(fontSize: 14, color: _kSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.pop(ctx),
                  child: Text(sw ? 'Ghairi' : 'Cancel',
                    style: const TextStyle(color: _kSecondary)),
                ),
                TextButton(
                  onPressed: isDeleting ? null : () async {
                    setDialogState(() => isDeleting = true);
                    Navigator.pop(ctx);
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      final result = await _service.deleteParent(
                        token: _token!,
                        parentId: parent.id,
                      );
                      if (result.success) {
                        messenger.showSnackBar(SnackBar(
                            content: Text(sw ? '${parent.name} ameondolewa' : '${parent.name} deleted')));
                        _loadData();
                      } else {
                        messenger.showSnackBar(SnackBar(
                            content: Text(result.message ?? (sw ? 'Imeshindwa kuondoa' : 'Failed to delete'))));
                      }
                    } catch (e) {
                      messenger.showSnackBar(SnackBar(
                          content: Text(sw ? 'Hitilafu imetokea' : 'An error occurred')));
                    }
                  },
                  child: isDeleting
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(sw ? 'Ondoa' : 'Delete',
                          style: const TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─── Edit parent sheet ────────────────────────────────────────

  void _showEditParentSheet(Parent parent) {
    final nameCtrl = TextEditingController(text: parent.name);
    final phoneCtrl = TextEditingController(text: parent.phone ?? '');
    final locationCtrl = TextEditingController(text: parent.locationName ?? '');
    final conditionsCtrl = TextEditingController(text: parent.chronicConditions.join(', '));
    final allergiesCtrl = TextEditingController(text: parent.allergies.join(', '));
    final nhifCtrl = TextEditingController(text: parent.nhifNumber ?? '');
    final emergNameCtrl = TextEditingController(
      text: parent.emergencyContacts.isNotEmpty ? (parent.emergencyContacts.first['name'] ?? '') : '',
    );
    final emergPhoneCtrl = TextEditingController(
      text: parent.emergencyContacts.isNotEmpty ? (parent.emergencyContacts.first['phone'] ?? '') : '',
    );
    DateTime birthDate = parent.dateOfBirth;
    String? gender = parent.gender;
    String relationship = parent.relationship;
    bool hasWhatsApp = parent.whatsappAvailable;
    String? livingSituation = parent.livingSituation;
    String? bloodType = parent.bloodType;
    String? mobilityStatus = parent.mobilityStatus;
    String? cognitiveStatus = parent.cognitiveStatus;
    final sw = _isSwahili;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              maxChildSize: 0.95,
              minChildSize: 0.5,
              expand: false,
              builder: (ctx, scrollCtrl) {
                return SingleChildScrollView(
                  controller: scrollCtrl,
                  padding: EdgeInsets.only(
                    left: 20, right: 20, top: 20,
                    bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: Container(width: 40, height: 4,
                        decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                      const SizedBox(height: 16),
                      Text(
                        sw ? 'Hariri Mzazi' : 'Edit Parent',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
                      ),
                      const SizedBox(height: 16),

                      // Name
                      _buildTextField(nameCtrl, sw ? 'Jina' : 'Name'),
                      const SizedBox(height: 14),

                      // Date of Birth
                      _buildDatePicker(
                        ctx: ctx,
                        sw: sw,
                        birthDate: birthDate,
                        onPicked: (d) => setSheetState(() => birthDate = d),
                      ),
                      const SizedBox(height: 14),

                      // Gender
                      _buildGenderChips(sw, gender, (v) => setSheetState(() => gender = v)),
                      const SizedBox(height: 14),

                      // Relationship
                      _buildRelationshipDropdown(sw, relationship, (v) => setSheetState(() => relationship = v!)),
                      const SizedBox(height: 14),

                      // Phone + WhatsApp
                      _buildTextField(phoneCtrl, sw ? 'Namba ya Simu' : 'Phone Number',
                          keyboardType: TextInputType.phone),
                      const SizedBox(height: 8),
                      Row(children: [
                        Checkbox(
                          value: hasWhatsApp,
                          onChanged: (v) => setSheetState(() => hasWhatsApp = v ?? false),
                          activeColor: _kPrimary,
                        ),
                        Text(sw ? 'Ana WhatsApp' : 'Has WhatsApp',
                          style: const TextStyle(fontSize: 13, color: _kSecondary)),
                      ]),
                      const SizedBox(height: 10),

                      // Location
                      _buildTextField(locationCtrl, sw ? 'Mahali (Mkoa, Wilaya, Kata)' : 'Location (Region, District, Ward)'),
                      const SizedBox(height: 14),

                      // Living Situation
                      _buildLivingSituationDropdown(sw, livingSituation, (v) => setSheetState(() => livingSituation = v)),
                      const SizedBox(height: 14),

                      // Blood Type
                      _buildBloodTypeDropdown(sw, bloodType, (v) => setSheetState(() => bloodType = v)),
                      const SizedBox(height: 14),

                      // Mobility Status
                      _buildMobilityDropdown(sw, mobilityStatus, (v) => setSheetState(() => mobilityStatus = v)),
                      const SizedBox(height: 14),

                      // Cognitive Status
                      _buildCognitiveDropdown(sw, cognitiveStatus, (v) => setSheetState(() => cognitiveStatus = v)),
                      const SizedBox(height: 14),

                      // Chronic Conditions
                      _buildTextField(conditionsCtrl,
                          sw ? 'Magonjwa ya Muda Mrefu (tenganisha kwa koma)' : 'Chronic Conditions (comma-separated)',
                          hint: sw ? 'Mfano: kisukari, shinikizo la damu' : 'e.g. diabetes, hypertension'),
                      const SizedBox(height: 14),

                      // Allergies
                      _buildTextField(allergiesCtrl,
                          sw ? 'Mzio (tenganisha kwa koma)' : 'Allergies (comma-separated)',
                          hint: sw ? 'Mfano: penicillin' : 'e.g. penicillin'),
                      const SizedBox(height: 14),

                      // NHIF
                      _buildTextField(nhifCtrl, sw ? 'Namba ya NHIF' : 'NHIF Number'),
                      const SizedBox(height: 14),

                      // Emergency Contact
                      Text(
                        sw ? 'Mawasiliano ya Dharura' : 'Emergency Contact',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
                      ),
                      const SizedBox(height: 8),
                      _buildTextField(emergNameCtrl, sw ? 'Jina' : 'Contact Name',
                          icon: Icons.person_rounded),
                      const SizedBox(height: 10),
                      _buildTextField(emergPhoneCtrl, sw ? 'Simu' : 'Phone Number',
                          keyboardType: TextInputType.phone, icon: Icons.phone_rounded),
                      const SizedBox(height: 20),

                      // Save
                      SizedBox(
                        width: double.infinity, height: 48,
                        child: FilledButton(
                          onPressed: isSaving ? null : () async {
                            if (nameCtrl.text.trim().isEmpty) return;
                            setSheetState(() => isSaving = true);
                            Navigator.pop(ctx);
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              final conditionsList = conditionsCtrl.text.trim().isEmpty
                                  ? <String>[]
                                  : conditionsCtrl.text.split(',').map((a) => a.trim()).where((a) => a.isNotEmpty).toList();
                              final allergiesList = allergiesCtrl.text.trim().isEmpty
                                  ? <String>[]
                                  : allergiesCtrl.text.split(',').map((a) => a.trim()).where((a) => a.isNotEmpty).toList();
                              List<Map<String, String>>? contacts;
                              if (emergNameCtrl.text.trim().isNotEmpty || emergPhoneCtrl.text.trim().isNotEmpty) {
                                contacts = [{'name': emergNameCtrl.text.trim(), 'phone': emergPhoneCtrl.text.trim()}];
                              }

                              final result = await _service.updateParent(
                                token: _token!,
                                parentId: parent.id,
                                name: nameCtrl.text.trim(),
                                gender: gender,
                                phone: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
                                whatsappAvailable: hasWhatsApp,
                                locationName: locationCtrl.text.trim().isNotEmpty ? locationCtrl.text.trim() : null,
                                livingSituation: livingSituation,
                                bloodType: bloodType,
                                mobilityStatus: mobilityStatus,
                                cognitiveStatus: cognitiveStatus,
                                chronicConditions: conditionsList,
                                allergies: allergiesList,
                                nhifNumber: nhifCtrl.text.trim().isNotEmpty ? nhifCtrl.text.trim() : null,
                                emergencyContacts: contacts,
                              );
                              if (result.success) {
                                messenger.showSnackBar(SnackBar(
                                    content: Text(sw ? 'Mzazi ameboreshwa' : 'Parent updated')));
                                _loadData();
                              } else {
                                messenger.showSnackBar(SnackBar(
                                    content: Text(result.message ?? (sw ? 'Imeshindwa kuboresha' : 'Failed to update'))));
                              }
                            } catch (e) {
                              messenger.showSnackBar(SnackBar(
                                  content: Text(sw ? 'Hitilafu imetokea' : 'An error occurred')));
                            }
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: _kPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: isSaving
                              ? const SizedBox(width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text(sw ? 'Hifadhi' : 'Save', style: const TextStyle(fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ─── Register parent sheet ────────────────────────────────────

  void _showRegisterParentSheet() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final conditionsCtrl = TextEditingController();
    final allergiesCtrl = TextEditingController();
    final nhifCtrl = TextEditingController();
    final emergNameCtrl = TextEditingController();
    final emergPhoneCtrl = TextEditingController();
    DateTime birthDate = DateTime(DateTime.now().year - 60);
    String? gender;
    String relationship = 'mother';
    bool hasWhatsApp = false;
    String? livingSituation;
    String? bloodType;
    String? mobilityStatus;
    String? cognitiveStatus;
    final sw = _isSwahili;
    bool isRegistering = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final age = _computeAge(birthDate);

            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              maxChildSize: 0.95,
              minChildSize: 0.5,
              expand: false,
              builder: (ctx, scrollCtrl) {
                return SingleChildScrollView(
                  controller: scrollCtrl,
                  padding: EdgeInsets.only(
                    left: 20, right: 20, top: 20,
                    bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag handle
                      Center(child: Container(width: 40, height: 4,
                        decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                      const SizedBox(height: 16),
                      Text(
                        sw ? 'Sajili Mzazi' : 'Register Parent',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sw ? 'Ongeza mzazi au mlezi wako' : 'Add your parent or guardian',
                        style: const TextStyle(fontSize: 12, color: _kSecondary),
                      ),
                      const SizedBox(height: 16),

                      // Name (required)
                      _buildTextField(nameCtrl, sw ? 'Jina la Mzazi *' : "Parent's Name *"),
                      const SizedBox(height: 14),

                      // Date of Birth
                      _buildDatePicker(
                        ctx: ctx,
                        sw: sw,
                        birthDate: birthDate,
                        onPicked: (d) => setSheetState(() => birthDate = d),
                        showAgeBadge: true,
                        age: age,
                        firstDate: DateTime.now().subtract(const Duration(days: 43800)), // ~120 years
                      ),
                      const SizedBox(height: 14),

                      // Gender
                      _buildGenderChips(sw, gender, (v) => setSheetState(() => gender = v),
                          maleLabel: sw ? 'Mwanaume' : 'Male',
                          femaleLabel: sw ? 'Mwanamke' : 'Female'),
                      const SizedBox(height: 14),

                      // Relationship
                      _buildRelationshipDropdown(sw, relationship, (v) => setSheetState(() => relationship = v!)),
                      const SizedBox(height: 14),

                      // Phone + WhatsApp
                      _buildTextField(phoneCtrl, sw ? 'Namba ya Simu' : 'Phone Number',
                          keyboardType: TextInputType.phone),
                      const SizedBox(height: 8),
                      Row(children: [
                        Checkbox(
                          value: hasWhatsApp,
                          onChanged: (v) => setSheetState(() => hasWhatsApp = v ?? false),
                          activeColor: _kPrimary,
                        ),
                        Text(sw ? 'Ana WhatsApp' : 'Has WhatsApp',
                          style: const TextStyle(fontSize: 13, color: _kSecondary)),
                      ]),
                      const SizedBox(height: 10),

                      // Location
                      _buildTextField(locationCtrl, sw ? 'Mahali (Mkoa, Wilaya, Kata)' : 'Location (Region, District, Ward)'),
                      const SizedBox(height: 14),

                      // Living Situation
                      _buildLivingSituationDropdown(sw, livingSituation, (v) => setSheetState(() => livingSituation = v)),
                      const SizedBox(height: 14),

                      // Blood Type
                      _buildBloodTypeDropdown(sw, bloodType, (v) => setSheetState(() => bloodType = v)),
                      const SizedBox(height: 14),

                      // Mobility Status
                      _buildMobilityDropdown(sw, mobilityStatus, (v) => setSheetState(() => mobilityStatus = v)),
                      const SizedBox(height: 14),

                      // Cognitive Status
                      _buildCognitiveDropdown(sw, cognitiveStatus, (v) => setSheetState(() => cognitiveStatus = v)),
                      const SizedBox(height: 14),

                      // Chronic Conditions
                      _buildTextField(conditionsCtrl,
                          sw ? 'Magonjwa ya Muda Mrefu (tenganisha kwa koma)' : 'Chronic Conditions (comma-separated)',
                          hint: sw ? 'Mfano: kisukari, shinikizo la damu' : 'e.g. diabetes, hypertension'),
                      const SizedBox(height: 14),

                      // Allergies
                      _buildTextField(allergiesCtrl,
                          sw ? 'Mzio (tenganisha kwa koma)' : 'Allergies (comma-separated)',
                          hint: sw ? 'Mfano: penicillin' : 'e.g. penicillin'),
                      const SizedBox(height: 14),

                      // NHIF
                      _buildTextField(nhifCtrl, sw ? 'Namba ya NHIF' : 'NHIF Number'),
                      const SizedBox(height: 14),

                      // Emergency Contact
                      Text(
                        sw ? 'Mawasiliano ya Dharura' : 'Emergency Contact',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                      ),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: _buildTextField(emergNameCtrl, sw ? 'Jina' : 'Name')),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTextField(emergPhoneCtrl, sw ? 'Simu' : 'Phone',
                            keyboardType: TextInputType.phone,
                            hint: '0712 345 678')),
                      ]),
                      const SizedBox(height: 20),

                      // Register
                      SizedBox(
                        width: double.infinity, height: 48,
                        child: FilledButton(
                          onPressed: isRegistering ? null : () async {
                            if (nameCtrl.text.trim().isEmpty) return;
                            setSheetState(() => isRegistering = true);
                            Navigator.pop(ctx);
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              List<String>? conditions;
                              if (conditionsCtrl.text.trim().isNotEmpty) {
                                conditions = conditionsCtrl.text.split(',').map((a) => a.trim()).where((a) => a.isNotEmpty).toList();
                              }
                              List<String>? allergies;
                              if (allergiesCtrl.text.trim().isNotEmpty) {
                                allergies = allergiesCtrl.text.split(',').map((a) => a.trim()).where((a) => a.isNotEmpty).toList();
                              }
                              List<Map<String, String>>? contacts;
                              if (emergNameCtrl.text.trim().isNotEmpty || emergPhoneCtrl.text.trim().isNotEmpty) {
                                contacts = [{'name': emergNameCtrl.text.trim(), 'phone': emergPhoneCtrl.text.trim()}];
                              }

                              final result = await _service.registerParent(
                                token: _token!,
                                userId: widget.userId,
                                name: nameCtrl.text.trim(),
                                dateOfBirth: birthDate,
                                relationship: relationship,
                                gender: gender,
                                phone: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
                                whatsappAvailable: hasWhatsApp,
                                locationName: locationCtrl.text.trim().isNotEmpty ? locationCtrl.text.trim() : null,
                                livingSituation: livingSituation,
                                bloodType: bloodType,
                                mobilityStatus: mobilityStatus,
                                cognitiveStatus: cognitiveStatus,
                                chronicConditions: conditions,
                                allergies: allergies,
                                nhifNumber: nhifCtrl.text.trim().isNotEmpty ? nhifCtrl.text.trim() : null,
                                emergencyContacts: contacts,
                              );
                              if (result.success) {
                                messenger.showSnackBar(SnackBar(
                                    content: Text(sw ? 'Mzazi amesajiliwa' : 'Parent registered')));
                                _loadData();
                              } else {
                                messenger.showSnackBar(SnackBar(
                                    content: Text(result.message ?? (sw ? 'Imeshindwa kusajili' : 'Failed to register'))));
                              }
                            } catch (e) {
                              messenger.showSnackBar(SnackBar(
                                  content: Text(sw ? 'Hitilafu imetokea' : 'An error occurred')));
                            }
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: _kPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: isRegistering
                              ? const SizedBox(width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text(sw ? 'Sajili' : 'Register', style: const TextStyle(fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ─── Caregiver community card ─────────────────────────────────

  Widget _buildCaregiverCommunityCard(bool sw) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CommunityModule(userId: widget.userId),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kPrimary.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.groups_rounded, color: _kPrimary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sw ? 'Jiunge na Vikundi vya Walezi' : 'Join Caregiver Support Groups',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sw
                        ? 'Shiriki uzoefu na walezi wengine'
                        : 'Share experiences with other caregivers',
                    style: const TextStyle(fontSize: 12, color: _kSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _kSecondary),
          ],
        ),
      ),
    );
  }

  // ─── Shared form helpers ──────────────────────────────────────

  Widget _buildTextField(TextEditingController ctrl, String label, {
    TextInputType? keyboardType,
    String? hint,
    IconData? icon,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      textCapitalization: keyboardType == TextInputType.phone
          ? TextCapitalization.none : TextCapitalization.words,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(fontSize: 13, color: _kSecondary),
        hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        prefixIcon: icon != null ? Icon(icon, size: 18, color: _kSecondary) : null,
      ),
    );
  }

  Widget _buildDatePicker({
    required BuildContext ctx,
    required bool sw,
    required DateTime birthDate,
    required ValueChanged<DateTime> onPicked,
    bool showAgeBadge = false,
    int? age,
    DateTime? firstDate,
  }) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: ctx,
          initialDate: birthDate,
          firstDate: firstDate ?? DateTime.now().subtract(const Duration(days: 43800)),
          lastDate: DateTime.now(),
          helpText: sw ? 'Tarehe ya kuzaliwa' : 'Date of Birth',
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          const Icon(Icons.calendar_today_rounded, size: 18, color: _kSecondary),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(sw ? 'Tarehe ya Kuzaliwa' : 'Date of Birth',
              style: const TextStyle(fontSize: 11, color: _kSecondary)),
            Text(
              '${birthDate.day}/${birthDate.month}/${birthDate.year}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary),
            ),
          ]),
          const Spacer(),
          if (showAgeBadge && age != null && age > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                sw ? 'Miaka $age' : '$age years',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kPrimary),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _buildGenderChips(bool sw, String? gender, ValueChanged<String?> onChanged, {
    String? maleLabel,
    String? femaleLabel,
  }) {
    return Row(children: [
      Text(sw ? 'Jinsia:' : 'Gender:', style: const TextStyle(fontSize: 13, color: _kSecondary)),
      const SizedBox(width: 12),
      ChoiceChip(
        label: Text(maleLabel ?? (sw ? 'Mwanaume' : 'Male')),
        selected: gender == 'male',
        onSelected: (v) => onChanged(v ? 'male' : null),
        selectedColor: _kPrimary.withValues(alpha: 0.15),
        labelStyle: TextStyle(fontSize: 12, color: gender == 'male' ? _kPrimary : _kSecondary),
      ),
      const SizedBox(width: 8),
      ChoiceChip(
        label: Text(femaleLabel ?? (sw ? 'Mwanamke' : 'Female')),
        selected: gender == 'female',
        onSelected: (v) => onChanged(v ? 'female' : null),
        selectedColor: _kPrimary.withValues(alpha: 0.15),
        labelStyle: TextStyle(fontSize: 12, color: gender == 'female' ? _kPrimary : _kSecondary),
      ),
    ]);
  }

  Widget _buildRelationshipDropdown(bool sw, String value, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: sw ? 'Uhusiano' : 'Relationship',
        labelStyle: const TextStyle(fontSize: 13, color: _kSecondary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      items: [
        DropdownMenuItem(value: 'mother', child: Text(sw ? 'Mama' : 'Mother')),
        DropdownMenuItem(value: 'father', child: Text(sw ? 'Baba' : 'Father')),
        DropdownMenuItem(value: 'guardian', child: Text(sw ? 'Mlezi' : 'Guardian')),
        DropdownMenuItem(value: 'in_law', child: Text(sw ? 'Mkwe' : 'In-law')),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildLivingSituationDropdown(bool sw, String? value, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: sw ? 'Hali ya Kuishi' : 'Living Situation',
        labelStyle: const TextStyle(fontSize: 13, color: _kSecondary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      items: [
        DropdownMenuItem(value: 'alone', child: Text(sw ? 'Peke yake' : 'Alone')),
        DropdownMenuItem(value: 'with_spouse', child: Text(sw ? 'Na Mwenzi' : 'With Spouse')),
        DropdownMenuItem(value: 'with_family', child: Text(sw ? 'Na Familia' : 'With Family')),
        DropdownMenuItem(value: 'care_facility', child: Text(sw ? 'Nyumba ya Wazee' : 'Care Facility')),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildBloodTypeDropdown(bool sw, String? value, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: sw ? 'Kundi la Damu' : 'Blood Type',
        labelStyle: const TextStyle(fontSize: 13, color: _kSecondary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      items: const [
        DropdownMenuItem(value: 'A+', child: Text('A+')),
        DropdownMenuItem(value: 'A-', child: Text('A-')),
        DropdownMenuItem(value: 'B+', child: Text('B+')),
        DropdownMenuItem(value: 'B-', child: Text('B-')),
        DropdownMenuItem(value: 'AB+', child: Text('AB+')),
        DropdownMenuItem(value: 'AB-', child: Text('AB-')),
        DropdownMenuItem(value: 'O+', child: Text('O+')),
        DropdownMenuItem(value: 'O-', child: Text('O-')),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildMobilityDropdown(bool sw, String? value, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: sw ? 'Uwezo wa Kutembea' : 'Mobility Status',
        labelStyle: const TextStyle(fontSize: 13, color: _kSecondary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      items: [
        DropdownMenuItem(value: 'independent', child: Text(sw ? 'Anajitegemea' : 'Independent')),
        DropdownMenuItem(value: 'uses_aid', child: Text(sw ? 'Anatumia msaada' : 'Uses aid')),
        DropdownMenuItem(value: 'wheelchair', child: Text(sw ? 'Kiti cha magurudumu' : 'Wheelchair')),
        DropdownMenuItem(value: 'bedridden', child: Text(sw ? 'Kitandani' : 'Bedridden')),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildCognitiveDropdown(bool sw, String? value, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: sw ? 'Hali ya Akili' : 'Cognitive Status',
        labelStyle: const TextStyle(fontSize: 13, color: _kSecondary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      items: [
        DropdownMenuItem(value: 'sharp', child: Text(sw ? 'Makini' : 'Sharp')),
        DropdownMenuItem(value: 'mild_forgetfulness', child: Text(sw ? 'Usahaulifu mdogo' : 'Mild forgetfulness')),
        DropdownMenuItem(value: 'needs_supervision', child: Text(sw ? 'Anahitaji usimamizi' : 'Needs supervision')),
      ],
      onChanged: onChanged,
    );
  }

  // ─── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sw = _isSwahili;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: _kPrimary,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Parent list
          if (_parents.isNotEmpty) ...[
            Text(
              sw ? 'Wazazi Wangu' : 'My Parents',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary),
            ),
            const SizedBox(height: 12),
            ..._parents.map((parent) => _ParentCard(
                  parent: parent,
                  isSwahili: sw,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ParentDashboardPage(
                        parent: parent,
                        userId: widget.userId,
                      ),
                    ),
                  ).then((_) {
                    if (mounted) _loadData();
                  }),
                  onLongPress: () => _showParentOptionsSheet(parent),
                )),
            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                onPressed: _showRegisterParentSheet,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(sw
                    ? 'Ongeza Mzazi Mwingine'
                    : 'Add Another Parent'),
                style: TextButton.styleFrom(foregroundColor: _kPrimary),
              ),
            ),
            const SizedBox(height: 16),
            _buildCaregiverCommunityCard(sw),
            const SizedBox(height: 32),
          ],

          // Empty state
          if (_parents.isEmpty) ...[
            const SizedBox(height: 60),
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _kPrimary.withValues(alpha: 0.06),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.elderly_rounded,
                        size: 56, color: _kPrimary),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    sw ? 'Wazazi Wangu' : 'My Parents',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      sw
                          ? 'Tunza afya, dawa, na mahitaji ya wazazi wako.'
                          : 'Track your parents\' health, medications, and care needs.',
                      style:
                          const TextStyle(fontSize: 14, color: _kSecondary),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: 220,
                    height: 48,
                    child: FilledButton(
                      onPressed: _showRegisterParentSheet,
                      style: FilledButton.styleFrom(
                        backgroundColor: _kPrimary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        sw ? 'Ongeza Mzazi' : 'Add Parent',
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),
          ],
        ],
      ),
    );
  }
}

// ─── Parent Card ─────────────────────────────────────────────────

class _ParentCard extends StatelessWidget {
  final Parent parent;
  final bool isSwahili;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _ParentCard({
    required this.parent,
    required this.isSwahili,
    required this.onTap,
    this.onLongPress,
  });

  String _relationshipLabel(String r, bool sw) {
    switch (r) {
      case 'mother': return sw ? 'Mama' : 'Mother';
      case 'father': return sw ? 'Baba' : 'Father';
      case 'guardian': return sw ? 'Mlezi' : 'Guardian';
      case 'in_law': return sw ? 'Mkwe' : 'In-law';
      default: return r;
    }
  }

  String _healthSummary(bool sw) {
    final conditions = parent.chronicConditions;
    if (conditions.isEmpty) {
      return sw ? 'Hakuna magonjwa yaliyosajiliwa' : 'No conditions registered';
    }
    if (conditions.length <= 2) return conditions.join(', ');
    return '${conditions.take(2).join(', ')} +${conditions.length - 2}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: parent.photoUrl != null
                      ? ClipOval(
                          child: Image.network(parent.photoUrl!,
                              width: 48, height: 48, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.elderly_rounded, size: 24, color: _kPrimary)))
                      : Icon(
                          parent.gender == 'female'
                              ? Icons.elderly_woman_rounded
                              : Icons.elderly_rounded,
                          size: 24,
                          color: _kPrimary,
                        ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              parent.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: _kPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _kPrimary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _relationshipLabel(parent.relationship, isSwahili),
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _kPrimary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${parent.ageLabel(isSwahili: isSwahili)}  •  ${_healthSummary(isSwahili)}',
                        style: const TextStyle(fontSize: 12, color: _kSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 20, color: _kSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
