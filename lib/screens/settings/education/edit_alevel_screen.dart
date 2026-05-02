import 'package:flutter/material.dart';
import '../../../config/api_config.dart';
import '../../../l10n/app_strings_scope.dart';
import '../../../models/profile_models.dart';
import '../../../services/profile_service.dart';
import '../../../services/secondary_service.dart';
import '../../../services/user_service.dart';
import '../../../widgets/alevel_school_picker.dart';
import 'shared/edit_education_chrome.dart';

/// Edit a user's A-Level (Form 5-6). Uses `AlevelSchoolPicker`, which
/// owns the school cascade + combination grid + year fields. Saving
/// preserves `alevel_school_id`, `alevel_combination_code/name`, and
/// `alevel_subjects` (the array of subject names) — fields the previous
/// free-text screen would silently drop.
class EditAlevelScreen extends StatefulWidget {
  final int currentUserId;
  const EditAlevelScreen({super.key, required this.currentUserId});

  @override
  State<EditAlevelScreen> createState() => _EditAlevelScreenState();
}

class _EditAlevelScreenState extends State<EditAlevelScreen> {
  late final AlevelSchoolService _alevelService;
  final ProfileService _profileService = ProfileService();
  final UserService _userService = UserService();

  bool _loading = true;
  bool _saving = false;
  String? _phone;
  String? _loadError;
  ProfileEducation? _initial;
  AlevelSelection? _picked;

  @override
  void initState() {
    super.initState();
    final base = ApiConfig.baseUrl.replaceFirst(RegExp(r'/api$'), '');
    _alevelService = AlevelSchoolService(baseUrl: base);
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
        _initial = r.profile!.alevelEducation;
      } else {
        _loadError = r.message ??
            (AppStringsScope.of(context)?.failedToLoadProfile ?? 'Failed to load profile');
      }
    });
  }

  Future<void> _save() async {
    final s = AppStringsScope.of(context);
    final sel = _picked;
    if (sel == null || sel.school == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s?.pleaseSelectSchool ?? 'Please pick a school first')),
      );
      return;
    }
    if (sel.combination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s?.pleaseSelectCombination ?? 'Please pick a combination')),
      );
      return;
    }
    if (_phone == null) return;
    setState(() => _saving = true);
    final school = sel.school!;
    final combo = sel.combination!;
    final result = await _userService.updateProfileByPhone(_phone!, {
      'alevel_school_id': school.id,
      'alevel_school_name': school.name,
      'alevel_combination_code': combo.code,
      'alevel_combination_name': combo.name,
      'alevel_start_year': sel.startYear,
      'alevel_graduation_year': sel.graduationYear,
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
      'alevel_school_id': null,
      'alevel_school_name': null,
      'alevel_combination_code': null,
      'alevel_combination_name': null,
      'alevel_start_year': null,
      'alevel_graduation_year': null,
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
      title: s?.editAlevelTitle ?? 'Edit A-Level',
      loading: _loading,
      loadError: _loadError,
      onRetry: _loadProfile,
      saving: _saving,
      onSave: _save,
      hasExisting: (_initial?.schoolName ?? '').isNotEmpty,
      onClear: _clear,
      currentSummary: _summary(s),
      child: AlevelSchoolPicker(
        alevelService: _alevelService,
        onSelectionChanged: (sel) => setState(() => _picked = sel),
      ),
    );
  }

  String? _summary(dynamic s) {
    if (_initial == null || (_initial!.schoolName ?? '').isEmpty) return null;
    final parts = <String>[_initial!.schoolName!];
    final combo = _initial!.combinationName ?? _initial!.combinationCode;
    if (combo != null && combo.isNotEmpty) parts.add(combo);
    if (_initial!.graduationYear != null) {
      parts.add(s?.classOfYear(_initial!.graduationYear!) ?? 'Class of ${_initial!.graduationYear}');
    }
    return parts.join(' · ');
  }
}
