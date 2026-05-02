import 'package:flutter/material.dart';
import '../../../config/api_config.dart';
import '../../../l10n/app_strings_scope.dart';
import '../../../models/profile_models.dart';
import '../../../models/school_models.dart';
import '../../../services/profile_service.dart';
import '../../../services/school_service.dart';
import '../../../services/user_service.dart';
import '../../../widgets/school_picker.dart';
import 'shared/edit_education_chrome.dart';

/// Edit a user's Primary school. Reuses the registration `SchoolPicker`
/// so the saved record carries `primary_school_id`, `primary_school_code`,
/// and `primary_school_type` (not just a free-text name).
class EditPrimarySchoolScreen extends StatefulWidget {
  final int currentUserId;
  const EditPrimarySchoolScreen({super.key, required this.currentUserId});

  @override
  State<EditPrimarySchoolScreen> createState() => _EditPrimarySchoolScreenState();
}

class _EditPrimarySchoolScreenState extends State<EditPrimarySchoolScreen> {
  late final SchoolService _schoolService;
  final ProfileService _profileService = ProfileService();
  final UserService _userService = UserService();

  bool _loading = true;
  bool _saving = false;
  String? _phone;
  String? _loadError;
  ProfileEducation? _initial;
  SelectedSchool? _picked;
  int? _startYear;
  int? _gradYear;

  @override
  void initState() {
    super.initState();
    final base = ApiConfig.baseUrl.replaceFirst(RegExp(r'/api$'), '');
    _schoolService = SchoolService(baseUrl: base);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    final r = await _profileService.getProfile(
      userId: widget.currentUserId,
      currentUserId: widget.currentUserId,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r.success && r.profile != null) {
        _phone = r.profile!.phoneNumber;
        _initial = r.profile!.primarySchool;
        _gradYear = _initial?.graduationYear;
      } else {
        _loadError = r.message ??
            (AppStringsScope.of(context)?.failedToLoadProfile ?? 'Failed to load profile');
      }
    });
  }

  Future<void> _save() async {
    final s = AppStringsScope.of(context);
    if (_picked == null || _picked!.school == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s?.pleaseSelectSchool ?? 'Please pick a school first')),
      );
      return;
    }
    if (_phone == null) return;
    setState(() => _saving = true);
    final school = _picked!.school!;
    final result = await _userService.updateProfileByPhone(_phone!, {
      'primary_school_id': school.id,
      'primary_school_name': school.name,
      'primary_school_code': school.code,
      'primary_start_year': _startYear,
      'primary_graduation_year': _gradYear,
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (result.success) {
      ProfileService.invalidate(widget.currentUserId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s?.profileSaved ?? 'Profile saved')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? (s?.saveFailed ?? 'Failed to save'))),
      );
    }
  }

  Future<void> _clear() async {
    final s = AppStringsScope.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(s?.clearSectionConfirm ?? 'Remove all data for this level?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s?.cancel ?? 'Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s?.delete ?? 'Delete', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted || _phone == null) return;
    setState(() => _saving = true);
    final result = await _userService.updateProfileByPhone(_phone!, {
      'primary_school_id': null,
      'primary_school_name': null,
      'primary_school_code': null,
      'primary_start_year': null,
      'primary_graduation_year': null,
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (result.success) {
      ProfileService.invalidate(widget.currentUserId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s?.cleared ?? 'Cleared')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? (s?.saveFailed ?? 'Failed to save'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    return EditEducationChrome(
      title: s?.editPrimarySchoolTitle ?? 'Edit Primary school',
      loading: _loading,
      loadError: _loadError,
      onRetry: _loadProfile,
      saving: _saving,
      onSave: _save,
      hasExisting: (_initial?.schoolName ?? '').isNotEmpty,
      onClear: _clear,
      currentSummary: _summary(s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SchoolPicker(
            schoolService: _schoolService,
            onSchoolChanged: (sel) => setState(() => _picked = sel),
          ),
          const SizedBox(height: 16),
          YearRow(
            startYear: _startYear,
            gradYear: _gradYear,
            onStartChanged: (v) => setState(() => _startYear = v),
            onGradChanged: (v) => setState(() => _gradYear = v),
          ),
        ],
      ),
    );
  }

  String? _summary(dynamic s) {
    if (_initial == null || (_initial!.schoolName ?? '').isEmpty) return null;
    final year = _initial!.graduationYear != null
        ? ' · ${s?.classOfYear(_initial!.graduationYear!) ?? "Class of ${_initial!.graduationYear}"}'
        : '';
    return '${_initial!.schoolName}$year';
  }
}
