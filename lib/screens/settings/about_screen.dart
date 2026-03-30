import 'dart:io';

import 'package:flutter/material.dart';

import '../../config/api_config.dart';
import '../../models/registration_models.dart';
import '../../services/local_storage_service.dart';
import '../../services/profile_service.dart';
import '../../services/user_service.dart';
import '../../widgets/tajiri_app_bar.dart';
import '../onboarding/steps/education_level_step.dart';
import '../onboarding/steps/employer_step.dart';
import '../onboarding/steps/location_step.dart';
import '../onboarding/steps/name_step.dart';
import '../onboarding/steps/photo_step.dart';
import '../onboarding/steps/school_step.dart';
import '../onboarding/steps/university_step.dart';

/// Displays all user profile information collected during registration
/// and allows editing each section by re-opening the onboarding step widgets.
///
/// Navigation: Settings → About (Kuhusu)
class AboutScreen extends StatefulWidget {
  final int currentUserId;

  const AboutScreen({super.key, required this.currentUserId});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  static const Color _primary = Color(0xFF1A1A1A);
  static const Color _secondary = Color(0xFF666666);
  static const Color _bg = Color(0xFFFAFAFA);
  static const Color _cardBg = Colors.white;
  static const Color _border = Color(0xFFE8E8E8);

  RegistrationState? _state;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final storage = await LocalStorageService.getInstance();
    final user = storage.getUser();
    if (mounted) {
      setState(() {
        _state = user ?? RegistrationState();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAndSync() async {
    if (_state == null) return;
    setState(() => _isSaving = true);

    final storage = await LocalStorageService.getInstance();
    await storage.updateUser(_state!);

    // Sync to backend
    final phone = _state!.phoneNumber;
    if (phone != null && phone.isNotEmpty) {
      final payload = _state!.toJson();
      await UserService().updateProfileByPhone(phone, payload);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Taarifa zimehifadhiwa')),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Edit helpers — open onboarding step as a full-screen dialog
  // ---------------------------------------------------------------------------

  Future<void> _editSection(Widget Function(VoidCallback onDone) builder) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _StepEditorWrapper(
          stepBuilder: builder,
        ),
      ),
    );
    if (result == true && mounted) {
      setState(() {}); // Refresh display
      _saveAndSync();
    }
  }

  void _editPhoto() {
    _editSection((onDone) => PhotoStep(
          state: _state!,
          onNext: () async {
            // Upload photo to backend
            if (_state!.profilePhotoPath != null) {
              final file = File(_state!.profilePhotoPath!);
              if (file.existsSync() && _state!.userId != null) {
                final result = await ProfileService().updateProfilePhoto(
                  userId: _state!.userId!,
                  photo: file,
                  faceBbox: _state!.faceBbox,
                );
                if (result.success && result.photoUrl != null) {
                  _state!.profilePhotoUrl = result.photoUrl;
                }
              }
            }
            onDone();
          },
        ));
  }

  void _editPersonalInfo() {
    _editSection((onDone) => NameStep(
          state: _state!,
          onNext: onDone,
        ));
  }

  void _editLocation() {
    _editSection((onDone) => LocationStep(
          state: _state!,
          onNext: onDone,
          onSkip: onDone,
        ));
  }

  void _editEducationLevel() {
    _editSection((onDone) {
      return EducationLevelStep(
        state: _state!,
        onNext: () {
          // Rebuild steps list after education path change
          setState(() {});
          onDone();
        },
      );
    });
  }

  void _editPrimarySchool() {
    final dobYear = _state!.dateOfBirth?.year ?? (DateTime.now().year - 18);
    _editSection((onDone) => SchoolStep(
          schoolType: 'primary',
          question: 'Ulisoma shule gani ya msingi?',
          skipText: 'Ruka',
          defaultGradYear: dobYear + 13,
          state: _state!,
          onNext: onDone,
          onSkip: onDone,
        ));
  }

  void _editSecondarySchool() {
    final dobYear = _state!.dateOfBirth?.year ?? (DateTime.now().year - 18);
    _editSection((onDone) => SchoolStep(
          schoolType: 'secondary',
          question: 'Ulisoma sekondari gani? (O-Level)',
          skipText: 'Ruka',
          defaultGradYear: dobYear + 17,
          state: _state!,
          onNext: onDone,
          onSkip: onDone,
        ));
  }

  void _editAlevelSchool() {
    final dobYear = _state!.dateOfBirth?.year ?? (DateTime.now().year - 18);
    _editSection((onDone) => SchoolStep(
          schoolType: 'alevel',
          question: 'Kidato cha 5-6 ulisoma wapi?',
          skipText: 'Ruka',
          defaultGradYear: dobYear + 19,
          showCombination: true,
          state: _state!,
          onNext: onDone,
          onSkip: onDone,
        ));
  }

  void _editPostsecondary() {
    final dobYear = _state!.dateOfBirth?.year ?? (DateTime.now().year - 18);
    _editSection((onDone) => SchoolStep(
          schoolType: 'postsecondary',
          question: 'Ulisoma chuo gani cha ufundi/ualimu/afya?',
          skipText: 'Ruka',
          defaultGradYear: dobYear + 19,
          state: _state!,
          onNext: onDone,
          onSkip: onDone,
        ));
  }

  void _editUniversity() {
    final dobYear = _state!.dateOfBirth?.year ?? (DateTime.now().year - 18);
    _editSection((onDone) => UniversityStep(
          state: _state!,
          onNext: onDone,
          onSkip: onDone,
          defaultGradYear: dobYear + 22,
        ));
  }

  void _editEmployer() {
    _editSection((onDone) => EmployerStep(
          state: _state!,
          onNext: onDone,
          onSkip: onDone,
        ));
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: const TajiriAppBar(title: 'Kuhusu'),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _state == null
                ? const Center(child: Text('Hakuna taarifa'))
                : Stack(
                    children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPhotoSection(),
                            const SizedBox(height: 12),
                            _buildPersonalSection(),
                            const SizedBox(height: 12),
                            _buildLocationSection(),
                            const SizedBox(height: 12),
                            _buildEducationSection(),
                            const SizedBox(height: 12),
                            _buildEmployerSection(),
                          ],
                        ),
                      ),
                      if (_isSaving)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black26,
                            child: const Center(
                              child: CircularProgressIndicator(color: _primary),
                            ),
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sections
  // ---------------------------------------------------------------------------

  Widget _buildPhotoSection() {
    final photoUrl = _state!.profilePhotoUrl;
    final photoPath = _state!.profilePhotoPath;

    ImageProvider? image;
    if (photoPath != null && File(photoPath).existsSync()) {
      image = FileImage(File(photoPath));
    } else if (photoUrl != null && photoUrl.isNotEmpty) {
      final resolved = photoUrl.startsWith('http')
          ? photoUrl
          : '${ApiConfig.storageUrl}/$photoUrl';
      image = NetworkImage(resolved);
    }

    return GestureDetector(
      onTap: _editPhoto,
      child: Center(
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: _border,
                  backgroundImage: image,
                  child: image == null
                      ? const Icon(Icons.person_rounded, size: 48, color: _secondary)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: _primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _state!.fullName.isNotEmpty ? _state!.fullName : 'Picha ya Wasifu',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalSection() {
    final s = _state!;
    return _buildCard(
      title: 'Taarifa Binafsi',
      icon: Icons.person_rounded,
      onEdit: _editPersonalInfo,
      children: [
        _buildRow('Jina', s.fullName.isNotEmpty ? s.fullName : '—'),
        _buildRow('Tarehe ya kuzaliwa',
            s.dateOfBirth != null ? _formatDate(s.dateOfBirth!) : '—'),
        _buildRow('Jinsia', s.gender?.fullLabel ?? '—'),
        _buildRow('Simu', s.phoneNumber ?? '—'),
      ],
    );
  }

  Widget _buildLocationSection() {
    final loc = _state!.location;
    return _buildCard(
      title: 'Mahali',
      icon: Icons.location_on_rounded,
      onEdit: _editLocation,
      children: [
        _buildRow('Mkoa', loc?.regionName ?? '—'),
        _buildRow('Wilaya', loc?.districtName ?? '—'),
        _buildRow('Kata', loc?.wardName ?? '—'),
        _buildRow('Mtaa', loc?.streetName ?? '—'),
      ],
    );
  }

  Widget _buildEducationSection() {
    final s = _state!;
    return _buildCard(
      title: 'Elimu',
      icon: Icons.school_rounded,
      onEdit: _editEducationLevel,
      children: [
        _buildRow('Kiwango', _educationPathLabel(s.educationPath)),
        const Divider(height: 24, color: _border),

        // Primary
        _buildSubSection(
          'Shule ya Msingi',
          s.primarySchool?.schoolName,
          s.primarySchool?.graduationYear?.toString(),
          _editPrimarySchool,
        ),

        // Secondary
        if (s.educationPath != null &&
            s.educationPath != EducationPath.primary) ...[
          const Divider(height: 24, color: _border),
          _buildSubSection(
            'Sekondari (O-Level)',
            s.secondarySchool?.schoolName,
            s.secondarySchool?.graduationYear?.toString(),
            _editSecondarySchool,
          ),
        ],

        // A-Level
        if (s.educationPath == EducationPath.alevel ||
            s.educationPath == EducationPath.university) ...[
          const Divider(height: 24, color: _border),
          _buildSubSection(
            'A-Level (Kidato 5-6)',
            s.alevelEducation?.schoolName,
            s.alevelEducation?.graduationYear?.toString(),
            _editAlevelSchool,
            extra: s.alevelEducation?.combinationCode,
          ),
        ],

        // Post-secondary
        if (s.educationPath == EducationPath.postSecondary) ...[
          const Divider(height: 24, color: _border),
          _buildSubSection(
            'Chuo cha Ufundi/Ualimu/Afya',
            s.postsecondaryEducation?.schoolName,
            s.postsecondaryEducation?.graduationYear?.toString(),
            _editPostsecondary,
            extra: s.postsecondaryEducation?.programmeName,
          ),
        ],

        // University
        if (s.educationPath == EducationPath.university) ...[
          const Divider(height: 24, color: _border),
          _buildSubSection(
            'Chuo Kikuu',
            s.universityEducation?.universityName,
            s.universityEducation?.graduationYear?.toString(),
            _editUniversity,
            extra: s.universityEducation?.programmeName,
          ),
        ],
      ],
    );
  }

  Widget _buildEmployerSection() {
    final emp = _state!.currentEmployer;
    return _buildCard(
      title: 'Kazi',
      icon: Icons.work_rounded,
      onEdit: _editEmployer,
      children: [
        _buildRow('Mwajiri', emp?.employerName ?? '—'),
        if (emp?.sector != null) _buildRow('Sekta', emp!.sector!),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Sub-builders
  // ---------------------------------------------------------------------------

  Widget _buildCard({
    required String title,
    required IconData icon,
    required VoidCallback onEdit,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: _primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _primary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.edit_rounded,
                    size: 18,
                    color: _secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: _secondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _primary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubSection(
    String title,
    String? name,
    String? year,
    VoidCallback onEdit, {
    String? extra,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _secondary,
                ),
              ),
            ),
            GestureDetector(
              onTap: onEdit,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.edit_rounded, size: 14, color: _secondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          name ?? '— Haijajazwa',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: name != null ? _primary : _secondary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (extra != null) ...[
          const SizedBox(height: 2),
          Text(
            extra,
            style: const TextStyle(fontSize: 12, color: _secondary),
          ),
        ],
        if (year != null) ...[
          const SizedBox(height: 2),
          Text(
            'Mwaka: $year',
            style: const TextStyle(fontSize: 12, color: _secondary),
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _educationPathLabel(EducationPath? path) {
    if (path == null) return '—';
    switch (path) {
      case EducationPath.primary:
        return 'Shule ya Msingi';
      case EducationPath.secondary:
        return 'Sekondari O-Level';
      case EducationPath.alevel:
        return 'Sekondari A-Level';
      case EducationPath.postSecondary:
        return 'Chuo cha Ufundi/Ualimu/Afya';
      case EducationPath.university:
        return 'Chuo Kikuu';
    }
  }
}

// ---------------------------------------------------------------------------
// Wrapper that presents a single onboarding step as a standalone edit screen
// ---------------------------------------------------------------------------

class _StepEditorWrapper extends StatelessWidget {
  final Widget Function(VoidCallback onDone) stepBuilder;

  const _StepEditorWrapper({required this.stepBuilder});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: const Text(
          'Hariri',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: stepBuilder(() {
          Navigator.of(context).pop(true);
        }),
      ),
    );
  }
}
