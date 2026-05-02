import 'package:flutter/material.dart';
import '../../../l10n/app_strings_scope.dart';
import '../../../models/education_models.dart';
import '../../../models/profile_models.dart';
import '../../../services/profile_service.dart';
import '../../../services/user_service.dart';
import '../../../widgets/university_programme_picker.dart';
import 'shared/edit_education_chrome.dart';

/// Edit a user's University education. Uses `UniversityProgrammePicker`
/// from registration which manages the full hierarchy (university →
/// college → department → programme + start/grad year fields). The
/// picker's own "Continue" button is the save trigger here — the chrome
/// hides its outer Save accordingly.
class EditUniversityScreen extends StatefulWidget {
  final int currentUserId;
  const EditUniversityScreen({super.key, required this.currentUserId});

  @override
  State<EditUniversityScreen> createState() => _EditUniversityScreenState();
}

class _EditUniversityScreenState extends State<EditUniversityScreen> {
  final ProfileService _profileService = ProfileService();
  final UserService _userService = UserService();

  bool _loading = true;
  bool _saving = false;
  String? _phone;
  String? _loadError;
  ProfileUniversityEducation? _initial;

  @override
  void initState() {
    super.initState();
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
        _initial = r.profile!.universityEducation;
      } else {
        _loadError = r.message ??
            (AppStringsScope.of(context)?.failedToLoadProfile ?? 'Failed to load profile');
      }
    });
  }

  Future<void> _onPickerComplete(
    UniversityDetailed? university,
    UniversityProgramme? programme,
    int? graduationYear,
    int? startYear,
  ) async {
    final s = AppStringsScope.of(context);
    if (university == null || programme == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s?.pleaseSelectUniversity ?? 'Please pick a university and programme')),
      );
      return;
    }
    if (graduationYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s?.graduationYearRequired ??
            'Set a graduation year or toggle "Currently studying"')),
      );
      return;
    }
    if (_phone == null) return;
    setState(() => _saving = true);
    final result = await _userService.updateProfileByPhone(_phone!, {
      'university_id': university.id,
      'university_name': university.name,
      'programme_id': programme.id,
      'programme_name': programme.name,
      'degree_level': programme.levelCode,
      'university_start_year': startYear,
      'university_graduation_year': graduationYear,
      'is_current_student': false,
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
      'university_id': null,
      'university_name': null,
      'programme_id': null,
      'programme_name': null,
      'degree_level': null,
      'university_start_year': null,
      'university_graduation_year': null,
      'is_current_student': false,
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
      title: s?.editUniversityTitle ?? 'Edit University',
      loading: _loading,
      loadError: _loadError,
      onRetry: _loadProfile,
      saving: _saving,
      hideSaveButton: true,
      hasExisting: (_initial?.universityName ?? '').isNotEmpty,
      onClear: _clear,
      currentSummary: _summary(s),
      child: UniversityProgrammePicker(
        onComplete: _onPickerComplete,
        onSkip: () => Navigator.pop(context, false),
      ),
    );
  }

  String? _summary(dynamic s) {
    final u = _initial;
    if (u == null || (u.universityName ?? '').isEmpty) return null;
    final parts = <String>[u.universityName!];
    if (u.programmeName != null && u.programmeName!.isNotEmpty) parts.add(u.programmeName!);
    if (u.isCurrentStudent) {
      parts.add(s?.currentlyStudying ?? 'Currently studying');
    } else if (u.graduationYear != null) {
      parts.add(s?.classOfYear(u.graduationYear!) ?? 'Class of ${u.graduationYear}');
    }
    return parts.join(' · ');
  }
}
