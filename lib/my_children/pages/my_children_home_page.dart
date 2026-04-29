// lib/my_children/pages/my_children_home_page.dart
import 'package:flutter/material.dart';
import '../../community/community_module.dart';
import '../../l10n/app_strings_scope.dart';
import '../../my_family/services/my_family_service.dart';
import '../../services/event_service.dart';
import '../../services/local_storage_service.dart';
import '../models/my_children_models.dart';
import '../services/children_notification_helper.dart';
import '../services/my_children_service.dart';
import 'child_dashboard_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class MyChildrenHomePage extends StatefulWidget {
  final int userId;
  const MyChildrenHomePage({super.key, required this.userId});
  @override
  State<MyChildrenHomePage> createState() => _MyChildrenHomePageState();
}

class _MyChildrenHomePageState extends State<MyChildrenHomePage> {
  final MyChildrenService _service = MyChildrenService();

  bool _isLoading = true;
  List<Child> _babies = [];
  String? _token;
  bool _hasSynced = false; // prevent duplicate sync on refresh

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
      final result = await _service.getMyBabies(_token!, widget.userId);
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (result.success) {
            _babies = result.items;
            if (!_hasSynced) {
              _hasSynced = true;
              _syncChildEvents(); // fire-and-forget calendar sync
              _syncChildrenToFamily(); // fire-and-forget family sync
              _scheduleChildNotifications(); // fire-and-forget notifications
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isSwahili
              ? 'Imeshindikana kupakia watoto'
              : 'Failed to load babies')),
        );
      }
    }
  }

  /// Fire-and-forget: sync child birthdays to the Tajiri calendar.
  Future<void> _syncChildEvents() async {
    try {
      final eventService = EventService();
      for (final child in _babies) {
        final nextBday = _nextBirthday(child.dateOfBirth);
        await eventService.createEvent(
          creatorId: widget.userId,
          name: '${child.name} Birthday',
          startDate: nextBday,
          isAllDay: true,
          privacy: 'private',
        );
      }
    } catch (_) {
      // Calendar sync is best-effort — never block the UI.
    }
  }

  /// Fire-and-forget: sync children to the Family module.
  Future<void> _syncChildrenToFamily() async {
    try {
      final familyService = MyFamilyService();
      for (final child in _babies) {
        await familyService.addMember(
          userId: widget.userId,
          name: child.name,
          relationship: 'child',
          gender: child.gender ?? 'unknown',
          dateOfBirth: '${child.dateOfBirth.year}-${child.dateOfBirth.month.toString().padLeft(2, '0')}-${child.dateOfBirth.day.toString().padLeft(2, '0')}',
          bloodType: child.bloodType,
        );
      }
    } catch (_) {
      // Family sync is best-effort — never block the UI.
    }
  }

  /// Fire-and-forget: schedule birthday reminders, daily summary, stage
  /// transition, profile completeness, and teen weekly prompts for every child.
  void _scheduleChildNotifications() {
    final sw = _isSwahili;
    for (final child in _babies) {
      ChildrenNotificationHelper.scheduleBirthdayReminder(
        child.id, child.name, child.dateOfBirth, sw,
      ).catchError((_) {});
      ChildrenNotificationHelper.scheduleDailySummary(
        child.id, child.name, sw,
      ).catchError((_) {});
      ChildrenNotificationHelper.scheduleStageTransition(
        child.id, child.name, child.dateOfBirth, sw,
      ).catchError((_) {});

      // Profile completeness check
      final missingFields = <String>[];
      if (child.gender == null || child.gender!.isEmpty) {
        missingFields.add(sw ? 'jinsia' : 'gender');
      }
      if (child.bloodType == null || child.bloodType!.isEmpty) {
        missingFields.add(sw ? 'kundi la damu' : 'blood type');
      }
      if (child.emergencyContacts.isEmpty) {
        missingFields.add(sw ? 'mawasiliano ya dharura' : 'emergency contacts');
      }
      if (missingFields.isNotEmpty) {
        ChildrenNotificationHelper.scheduleProfileIncomplete(
          child.id, child.name, missingFields, isSwahili: sw,
        ).catchError((_) {});
      }

      // Teen weekly prompts (age >= 12)
      final age = _computeAge(child.dateOfBirth);
      if (age >= 12) {
        ChildrenNotificationHelper.scheduleWeeklyCareerPrompt(
          child.id, child.name, isSwahili: sw,
        ).catchError((_) {});
        ChildrenNotificationHelper.scheduleWeeklyFinancialTip(
          child.id, child.name, isSwahili: sw,
        ).catchError((_) {});
        ChildrenNotificationHelper.scheduleWeeklyLifeSkillPrompt(
          child.id, child.name, isSwahili: sw,
        ).catchError((_) {});
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

  void _showChildOptionsSheet(Child baby) {
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
                  baby.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.edit_rounded, color: _kPrimary),
                  title: Text(sw ? 'Hariri Mtoto' : 'Edit Child',
                    style: const TextStyle(fontSize: 15, color: _kPrimary)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showEditChildSheet(baby);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_rounded, color: Colors.red),
                  title: Text(sw ? 'Ondoa Mtoto' : 'Delete Child',
                    style: const TextStyle(fontSize: 15, color: Colors.red)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmDeleteChild(baby);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditChildSheet(Child baby) {
    final nameCtrl = TextEditingController(text: baby.name);
    final allergiesCtrl = TextEditingController(text: baby.allergies.join(', '));
    final emergencyNameCtrl = TextEditingController(
      text: baby.emergencyContacts.isNotEmpty ? (baby.emergencyContacts.first['name'] ?? '') : '',
    );
    final emergencyPhoneCtrl = TextEditingController(
      text: baby.emergencyContacts.isNotEmpty ? (baby.emergencyContacts.first['phone'] ?? '') : '',
    );
    final schoolNameCtrl = TextEditingController(text: baby.schoolName ?? '');
    final gradeCtrl = TextEditingController(text: baby.grade ?? '');
    final birthWeightCtrl = TextEditingController(
      text: baby.birthWeightGrams != null ? baby.birthWeightGrams.toString() : '',
    );
    final birthLengthCtrl = TextEditingController(
      text: baby.birthLengthCm != null ? baby.birthLengthCm.toString() : '',
    );
    DateTime birthDate = baby.dateOfBirth;
    String? gender = baby.gender;
    String? bloodType = baby.bloodType;
    final sw = _isSwahili;
    bool isSaving = false;
    final showSchoolFields = baby.ageInYears >= 5;
    final showBirthMetrics = baby.ageInYears < 2;

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
              initialChildSize: 0.75,
              maxChildSize: 0.92,
              minChildSize: 0.4,
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
                        sw ? 'Hariri Mtoto' : 'Edit Child',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
                      ),
                      const SizedBox(height: 16),

                      // Name
                      TextField(
                        controller: nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: sw ? 'Jina la Mtoto' : "Child's Name",
                          labelStyle: const TextStyle(fontSize: 13, color: _kSecondary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Date of Birth
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: birthDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 6570)),
                            lastDate: DateTime.now(),
                            helpText: sw ? 'Tarehe ya kuzaliwa' : 'Date of Birth',
                          );
                          if (picked != null) setSheetState(() => birthDate = picked);
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
                          ]),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Gender
                      Row(children: [
                        Text(sw ? 'Jinsia:' : 'Gender:', style: const TextStyle(fontSize: 13, color: _kSecondary)),
                        const SizedBox(width: 12),
                        ChoiceChip(
                          label: Text(sw ? 'Mvulana' : 'Boy'),
                          selected: gender == 'male',
                          onSelected: (v) => setSheetState(() => gender = v ? 'male' : null),
                          selectedColor: _kPrimary.withValues(alpha: 0.15),
                          labelStyle: TextStyle(fontSize: 12, color: gender == 'male' ? _kPrimary : _kSecondary),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: Text(sw ? 'Msichana' : 'Girl'),
                          selected: gender == 'female',
                          onSelected: (v) => setSheetState(() => gender = v ? 'female' : null),
                          selectedColor: _kPrimary.withValues(alpha: 0.15),
                          labelStyle: TextStyle(fontSize: 12, color: gender == 'female' ? _kPrimary : _kSecondary),
                        ),
                      ]),
                      const SizedBox(height: 14),

                      // Blood Type
                      DropdownButtonFormField<String>(
                        value: bloodType,
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
                        onChanged: (v) => setSheetState(() => bloodType = v),
                      ),
                      const SizedBox(height: 14),

                      // Allergies
                      TextField(
                        controller: allergiesCtrl,
                        decoration: InputDecoration(
                          labelText: sw ? 'Mzio (tenganisha kwa koma)' : 'Allergies (comma-separated)',
                          hintText: sw ? 'Mfano: karanga, maziwa' : 'e.g. peanuts, milk',
                          labelStyle: const TextStyle(fontSize: 13, color: _kSecondary),
                          hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          prefixIcon: const Icon(Icons.warning_amber_rounded, size: 18, color: _kSecondary),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Emergency Contact
                      Text(
                        sw ? 'Mawasiliano ya Dharura' : 'Emergency Contact',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: emergencyNameCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: sw ? 'Jina' : 'Contact Name',
                          labelStyle: const TextStyle(fontSize: 13, color: _kSecondary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          prefixIcon: const Icon(Icons.person_rounded, size: 18, color: _kSecondary),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: emergencyPhoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: sw ? 'Simu' : 'Phone Number',
                          labelStyle: const TextStyle(fontSize: 13, color: _kSecondary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          prefixIcon: const Icon(Icons.phone_rounded, size: 18, color: _kSecondary),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // School Name + Grade (if age >= 5)
                      if (showSchoolFields) ...[
                        Text(
                          sw ? 'Taarifa za Shule' : 'School Information',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: schoolNameCtrl,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: sw ? 'Jina la Shule' : 'School Name',
                            labelStyle: const TextStyle(fontSize: 13, color: _kSecondary),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            prefixIcon: const Icon(Icons.school_rounded, size: 18, color: _kSecondary),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: gradeCtrl,
                          decoration: InputDecoration(
                            labelText: sw ? 'Darasa' : 'Grade',
                            hintText: sw ? 'Mfano: Darasa la 3' : 'e.g. Grade 3',
                            labelStyle: const TextStyle(fontSize: 13, color: _kSecondary),
                            hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            prefixIcon: const Icon(Icons.class_rounded, size: 18, color: _kSecondary),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Birth Weight + Birth Length (if age < 2)
                      if (showBirthMetrics) ...[
                        Text(
                          sw ? 'Vipimo vya Kuzaliwa' : 'Birth Metrics',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
                        ),
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(child: TextField(
                            controller: birthWeightCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: sw ? 'Uzito (g)' : 'Weight (g)',
                              labelStyle: const TextStyle(fontSize: 13, color: _kSecondary),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          )),
                          const SizedBox(width: 10),
                          Expanded(child: TextField(
                            controller: birthLengthCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: sw ? 'Urefu (cm)' : 'Length (cm)',
                              labelStyle: const TextStyle(fontSize: 13, color: _kSecondary),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          )),
                        ]),
                        const SizedBox(height: 14),
                      ],

                      const SizedBox(height: 6),

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
                              // Parse allergies
                              final allergiesList = allergiesCtrl.text.trim().isEmpty
                                  ? <String>[]
                                  : allergiesCtrl.text.split(',').map((a) => a.trim()).where((a) => a.isNotEmpty).toList();

                              // Parse emergency contacts
                              List<Map<String, String>>? contacts;
                              if (emergencyNameCtrl.text.trim().isNotEmpty || emergencyPhoneCtrl.text.trim().isNotEmpty) {
                                contacts = [{'name': emergencyNameCtrl.text.trim(), 'phone': emergencyPhoneCtrl.text.trim()}];
                              }

                              final result = await _service.updateBaby(
                                token: _token!,
                                babyId: baby.id,
                                name: nameCtrl.text.trim(),
                                gender: gender,
                                bloodType: bloodType,
                                allergies: allergiesList,
                                emergencyContacts: contacts,
                                schoolName: showSchoolFields && schoolNameCtrl.text.trim().isNotEmpty ? schoolNameCtrl.text.trim() : null,
                                grade: showSchoolFields && gradeCtrl.text.trim().isNotEmpty ? gradeCtrl.text.trim() : null,
                                birthWeightGrams: showBirthMetrics && birthWeightCtrl.text.trim().isNotEmpty
                                    ? int.tryParse(birthWeightCtrl.text.trim()) : null,
                                birthLengthCm: showBirthMetrics && birthLengthCtrl.text.trim().isNotEmpty
                                    ? double.tryParse(birthLengthCtrl.text.trim()) : null,
                              );
                              if (result.success) {
                                messenger.showSnackBar(SnackBar(
                                    content: Text(sw ? 'Mtoto ameboreshwa' : 'Child updated')));
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
    ).then((_) {
      nameCtrl.dispose();
      allergiesCtrl.dispose();
      emergencyNameCtrl.dispose();
      emergencyPhoneCtrl.dispose();
      schoolNameCtrl.dispose();
      gradeCtrl.dispose();
      birthWeightCtrl.dispose();
      birthLengthCtrl.dispose();
    });
  }

  void _confirmDeleteChild(Child baby) {
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
                sw ? 'Ondoa Mtoto' : 'Delete Child',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _kPrimary),
              ),
              content: Text(
                sw
                    ? 'Una uhakika unataka kuondoa ${baby.name}? Hatua hii haiwezi kutenduliwa.'
                    : 'Are you sure you want to delete ${baby.name}? This action cannot be undone.',
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
                      final result = await _service.deleteBaby(_token!, baby.id);
                      if (result.success) {
                        messenger.showSnackBar(SnackBar(
                            content: Text(sw ? '${baby.name} ameondolewa' : '${baby.name} deleted')));
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

  void _showRegisterChildDialog() {
    final nameCtrl = TextEditingController();
    DateTime birthDate = DateTime.now();
    String? gender;
    String? bloodType;
    final weightCtrl = TextEditingController();
    final lengthCtrl = TextEditingController();
    final schoolCtrl = TextEditingController();
    final gradeCtrl = TextEditingController();
    final allergiesCtrl = TextEditingController();
    final emergNameCtrl = TextEditingController();
    final emergPhoneCtrl = TextEditingController();
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
            final isInfant = age < 2;
            final isSchoolAge = age >= 5;

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
                        sw ? 'Sajili Mtoto' : 'Register Child',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sw ? 'Watoto wenye umri wa miaka 0-18' : 'Children aged 0-18 years',
                        style: const TextStyle(fontSize: 12, color: _kSecondary),
                      ),
                      const SizedBox(height: 16),

                      // ─── Required: Name ────────────────────────
                      TextField(
                        controller: nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: sw ? 'Jina la Mtoto' : "Child's Name",
                          labelStyle: const TextStyle(fontSize: 13, color: _kSecondary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ─── Required: Date of Birth ───────────────
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: birthDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 6570)), // ~18 years
                            lastDate: DateTime.now(),
                            helpText: sw ? 'Tarehe ya kuzaliwa' : 'Date of Birth',
                          );
                          if (picked != null) setSheetState(() => birthDate = picked);
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
                            if (age > 0)
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
                      ),
                      const SizedBox(height: 14),

                      // ─── Gender ────────────────────────────────
                      Row(children: [
                        Text(sw ? 'Jinsia:' : 'Gender:', style: const TextStyle(fontSize: 13, color: _kSecondary)),
                        const SizedBox(width: 12),
                        ChoiceChip(
                          label: Text(sw ? 'Mvulana' : 'Boy'),
                          selected: gender == 'male',
                          onSelected: (v) => setSheetState(() => gender = v ? 'male' : null),
                          selectedColor: _kPrimary.withValues(alpha: 0.15),
                          labelStyle: TextStyle(fontSize: 12, color: gender == 'male' ? _kPrimary : _kSecondary),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: Text(sw ? 'Msichana' : 'Girl'),
                          selected: gender == 'female',
                          onSelected: (v) => setSheetState(() => gender = v ? 'female' : null),
                          selectedColor: _kPrimary.withValues(alpha: 0.15),
                          labelStyle: TextStyle(fontSize: 12, color: gender == 'female' ? _kPrimary : _kSecondary),
                        ),
                      ]),
                      const SizedBox(height: 14),

                      // ─── Blood Type ────────────────────────────
                      DropdownButtonFormField<String>(
                        initialValue: bloodType,
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
                        onChanged: (v) => setSheetState(() => bloodType = v),
                      ),
                      const SizedBox(height: 14),

                      // ─── Infant-only: Birth measurements ──────
                      if (isInfant) ...[
                        Text(sw ? 'Vipimo vya Kuzaliwa' : 'Birth Measurements',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(child: TextField(
                            controller: weightCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: sw ? 'Uzito (g)' : 'Weight (g)',
                              labelStyle: const TextStyle(fontSize: 13, color: _kSecondary),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: TextField(
                            controller: lengthCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: sw ? 'Urefu (cm)' : 'Length (cm)',
                              labelStyle: const TextStyle(fontSize: 13, color: _kSecondary),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          )),
                        ]),
                        const SizedBox(height: 14),
                      ],

                      // ─── School-age+: School info ─────────────
                      if (isSchoolAge) ...[
                        Text(sw ? 'Taarifa za Shule' : 'School Information',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(flex: 2, child: TextField(
                            controller: schoolCtrl,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText: sw ? 'Jina la Shule' : 'School Name',
                              labelStyle: const TextStyle(fontSize: 13, color: _kSecondary),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: TextField(
                            controller: gradeCtrl,
                            decoration: InputDecoration(
                              labelText: sw ? 'Darasa' : 'Grade',
                              hintText: sw ? 'Mfano: 3' : 'e.g. 3',
                              labelStyle: const TextStyle(fontSize: 13, color: _kSecondary),
                              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          )),
                        ]),
                        const SizedBox(height: 14),
                      ],

                      // ─── All ages: Allergies ──────────────────
                      TextField(
                        controller: allergiesCtrl,
                        decoration: InputDecoration(
                          labelText: sw ? 'Mzio (tenganisha kwa koma)' : 'Allergies (comma-separated)',
                          hintText: sw ? 'Mfano: maziwa, karanga' : 'e.g. milk, peanuts',
                          labelStyle: const TextStyle(fontSize: 13, color: _kSecondary),
                          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ─── Emergency Contact ────────────────────
                      Text(sw ? 'Mawasiliano ya Dharura' : 'Emergency Contact',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: TextField(
                          controller: emergNameCtrl,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: sw ? 'Jina' : 'Name',
                            labelStyle: const TextStyle(fontSize: 13, color: _kSecondary),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(
                          controller: emergPhoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: sw ? 'Simu' : 'Phone',
                            hintText: '0712 345 678',
                            labelStyle: const TextStyle(fontSize: 13, color: _kSecondary),
                            hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        )),
                      ]),
                      const SizedBox(height: 20),

                      // ─── Submit ────────────────────────────────
                      SizedBox(
                        width: double.infinity, height: 48,
                        child: FilledButton(
                          onPressed: isRegistering ? null : () async {
                            if (nameCtrl.text.trim().isEmpty) return;
                            setSheetState(() => isRegistering = true);
                            Navigator.pop(ctx);
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              // Parse allergies
                              List<String>? allergies;
                              if (allergiesCtrl.text.trim().isNotEmpty) {
                                allergies = allergiesCtrl.text.split(',').map((a) => a.trim()).where((a) => a.isNotEmpty).toList();
                              }
                              // Parse emergency contact
                              List<Map<String, String>>? contacts;
                              if (emergNameCtrl.text.trim().isNotEmpty || emergPhoneCtrl.text.trim().isNotEmpty) {
                                contacts = [{'name': emergNameCtrl.text.trim(), 'phone': emergPhoneCtrl.text.trim()}];
                              }

                              final result = await _service.registerBaby(
                                token: _token!,
                                userId: widget.userId,
                                name: nameCtrl.text.trim(),
                                dateOfBirth: birthDate,
                                gender: gender,
                                birthWeightGrams: isInfant ? int.tryParse(weightCtrl.text.trim()) : null,
                                birthLengthCm: isInfant ? double.tryParse(lengthCtrl.text.trim()) : null,
                                bloodType: bloodType,
                                schoolName: isSchoolAge && schoolCtrl.text.trim().isNotEmpty ? schoolCtrl.text.trim() : null,
                                grade: isSchoolAge && gradeCtrl.text.trim().isNotEmpty ? gradeCtrl.text.trim() : null,
                                allergies: allergies,
                                emergencyContacts: contacts,
                              );
                              if (result.success) {
                                messenger.showSnackBar(SnackBar(
                                    content: Text(sw ? 'Mtoto amesajiliwa' : 'Child registered')));
                                _loadData();
                              } else {
                                messenger.showSnackBar(SnackBar(
                                    content: Text(result.message ?? (sw ? 'Imeshindwa kusajili mtoto' : 'Failed to register child'))));
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
    ).then((_) {
      nameCtrl.dispose();
      weightCtrl.dispose();
      lengthCtrl.dispose();
      schoolCtrl.dispose();
      gradeCtrl.dispose();
      allergiesCtrl.dispose();
      emergNameCtrl.dispose();
      emergPhoneCtrl.dispose();
    });
  }

  /// Feature 9: Parent Community card
  Widget _buildParentCommunityCard(bool sw) {
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
                    sw ? 'Jiunge na Vikundi vya Wazazi' : 'Join Parent Groups',
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
                        ? 'Shiriki uzoefu na wazazi wengine'
                        : 'Share experiences with other parents',
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
          // Baby list
          if (_babies.isNotEmpty) ...[
            Text(
              sw ? 'Watoto Wangu' : 'My Children',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary),
            ),
            const SizedBox(height: 12),
            ..._babies.map((baby) => _BabyCard(
                  baby: baby,
                  isSwahili: sw,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChildDashboardPage(
                        child: baby,
                        userId: widget.userId,
                      ),
                    ),
                  ).then((_) {
                    if (mounted) _loadData();
                  }),
                  onLongPress: () => _showChildOptionsSheet(baby),
                )),
            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                onPressed: _showRegisterChildDialog,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(sw
                    ? 'Ongeza Mtoto Mwingine'
                    : 'Add Another Child'),
                style: TextButton.styleFrom(foregroundColor: _kPrimary),
              ),
            ),
            const SizedBox(height: 16),
            // Parent Community section
            _buildParentCommunityCard(sw),
            const SizedBox(height: 32),
          ],

          // Empty state
          if (_babies.isEmpty) ...[
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
                    child: const Icon(Icons.child_friendly_rounded,
                        size: 56, color: _kPrimary),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    sw ? 'Watoto Wangu' : 'My Children',
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
                          ? 'Fuatilia chanjo, kulisha, na maendeleo ya mtoto wako.'
                          : "Track your baby's vaccinations, feeding, and development.",
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
                      onPressed: _showRegisterChildDialog,
                      style: FilledButton.styleFrom(
                        backgroundColor: _kPrimary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        sw ? 'Ongeza Mtoto' : 'Add Child',
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

// ─── Baby Card ────────────────────────────────────────────────

class _BabyCard extends StatelessWidget {
  final Child baby;
  final bool isSwahili;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _BabyCard({
    required this.baby,
    required this.isSwahili,
    required this.onTap,
    this.onLongPress,
  });

  int _daysUntilBirthday(DateTime dob) {
    final now = DateTime.now();
    var next = DateTime(now.year, dob.month, dob.day);
    if (next.isBefore(now)) next = DateTime(now.year + 1, dob.month, dob.day);
    return next.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final daysUntil = _daysUntilBirthday(baby.dateOfBirth);
    final birthdayLabel = daysUntil == 0
        ? (isSwahili ? 'Leo ni siku ya kuzaliwa!' : 'Birthday today!')
        : (isSwahili
            ? 'Siku $daysUntil hadi siku ya kuzaliwa'
            : '$daysUntil days until birthday');

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
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    baby.gender == 'male'
                        ? Icons.boy_rounded
                        : baby.gender == 'female'
                            ? Icons.girl_rounded
                            : Icons.child_care_rounded,
                    size: 24,
                    color: _kPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              baby.name,
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _kPrimary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              baby.stageLabel(isSwahili: isSwahili),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _kPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        baby.ageLabelLocalized(isSwahili: isSwahili),
                        style:
                            const TextStyle(fontSize: 12, color: _kSecondary),
                      ),
                      // Birthday countdown
                      if (daysUntil <= 30)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            birthdayLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: daysUntil == 0
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: daysUntil == 0
                                  ? _kPrimary
                                  : _kSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: _kSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
