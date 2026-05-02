import 'package:flutter/material.dart';
import '../../../config/api_config.dart';
import '../../../l10n/app_strings_scope.dart';
import '../../../models/profile_models.dart';
import '../../../services/profile_service.dart';
import '../../../services/secondary_service.dart';
import '../../../services/user_service.dart';
import '../../../widgets/secondary_school_picker.dart';
import 'shared/edit_education_chrome.dart';

/// Edit a user's O-Level (Secondary) school. Reuses
/// `SecondarySchoolPicker` from registration so the saved record carries
/// `secondary_school_id` / `_code` / `_type` instead of plain text.
class EditSecondarySchoolScreen extends StatefulWidget {
  final int currentUserId;
  const EditSecondarySchoolScreen({super.key, required this.currentUserId});

  @override
  State<EditSecondarySchoolScreen> createState() => _EditSecondarySchoolScreenState();
}

class _EditSecondarySchoolScreenState extends State<EditSecondarySchoolScreen> {
  late final SecondarySchoolService _secondaryService;
  final ProfileService _profileService = ProfileService();
  final UserService _userService = UserService();

  bool _loading = true;
  bool _saving = false;
  String? _phone;
  String? _loadError;
  ProfileEducation? _initial;
  SecondarySchoolSelection? _picked;
  int? _startYear;
  int? _gradYear;

  @override
  void initState() {
    super.initState();
    final base = ApiConfig.baseUrl.replaceFirst(RegExp(r'/api$'), '');
    _secondaryService = SecondarySchoolService(baseUrl: base);
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
        _initial = r.profile!.secondarySchool;
        _gradYear = _initial?.graduationYear;
      } else {
        _loadError = r.message ??
            (AppStringsScope.of(context)?.failedToLoadProfile ?? 'Failed to load profile');
      }
    });
  }

  Future<void> _save() async {
    final s = AppStringsScope.of(context);
    if (_picked == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s?.pleaseSelectSchool ?? 'Please pick a school first')),
      );
      return;
    }
    if (_phone == null) return;
    setState(() => _saving = true);
    final school = _picked!.school;
    final result = await _userService.updateProfileByPhone(_phone!, {
      'secondary_school_id': school.id,
      'secondary_school_name': school.name,
      'secondary_start_year': _startYear,
      'secondary_graduation_year': _gradYear,
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
      'secondary_school_id': null,
      'secondary_school_name': null,
      'secondary_start_year': null,
      'secondary_graduation_year': null,
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
      title: s?.editSecondarySchoolTitle ?? 'Edit O-Level',
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
          SecondarySchoolPicker(
            secondaryService: _secondaryService,
            onSelectionChanged: (sel) => setState(() => _picked = sel),
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
